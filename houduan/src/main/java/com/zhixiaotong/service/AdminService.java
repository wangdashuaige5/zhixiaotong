package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import java.math.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminService {
  private final Db db;
  private final Access access;
  private final AuditService audit;
  private final ScheduleValidator schedule;

  public AdminService(Db db, Access access, AuditService audit, ScheduleValidator schedule) {
    this.db = db;
    this.access = access;
    this.audit = audit;
    this.schedule = schedule;
  }

  private long root() {
    var r = db.one("SELECT id FROM org_unit WHERE parent_id IS NULL ORDER BY id LIMIT 1");
    check(r != null, 409, "请先初始化学校根组织");
    return num(r.get("id"));
  }

  private void configLock() {
    db.lock("org_unit", root());
  }

  private void global(String permission) {
    access.org(root(), permission);
  }

  public Object orgs() {
    access.require("admin:read");
    return db.list("SELECT * FROM org_unit ORDER BY sort_order,id").stream()
        .filter(r -> access.canOrg(access.uid(), num(r.get("id")), "admin:read"))
        .toList();
  }

  @Transactional
  public Object org(Map<String, Object> b) {
    access.require("admin:write");
    access.confirmed(b);
    configLock();
    Long id = b.get("id") == null ? null : id(b, "id");
    int type = integer(b, "org_type", 0);
    range(type, 1, 4, "org_type");
    Long parent = b.get("parent_id") == null ? null : id(b, "parent_id");
    if (id != null) access.org(id, "admin:write");
    if (parent != null) {
      access.org(parent, "admin:write");
      var p = db.get("org_unit", parent);
      check(integer(p, "org_type", 0) == type - 1, 400, "组织父子类型必须依次为学校、院系、专业、年级");
      check(id == null || !access.desc(parent, id), 400, "组织不能形成环");
    } else {
      global("admin:write");
      check(type == 1 && (id != null && id == root()), 400, "单校模式只能保留一个学校根节点");
    }
    var v =
        map(
            "parent_id",
            parent,
            "org_code",
            text(b, "org_code", 32),
            "org_name",
            text(b, "org_name", 64),
            "org_type",
            type,
            "sort_order",
            integer(b, "sort_order", 0),
            "is_enabled",
            integer(b, "is_enabled", 1));
    long key = id == null ? db.insert("org_unit", v) : id;
    if (id != null) db.update("org_unit", id, v);
    audit.logAs(access.uid(), "ORG_SAVE", "org_unit", key, map("type", type), true);
    return db.get("org_unit", key);
  }

  public Object users(Map<String, Object> q) {
    access.require("admin:read");
    String keyword = "%" + str(q, "keywords") + "%";
    var all =
        db
            .list(
                "SELECT"
                    + " id,user_name,real_name,user_no,gender,email,org_id,class_id,user_status,create_time"
                    + " FROM `user` WHERE (user_name LIKE ? OR real_name LIKE ?) ORDER BY id",
                keyword,
                keyword)
            .stream()
            .filter(r -> access.canOrg(access.uid(), num(r.get("org_id")), "admin:read"))
            .filter(
                r -> !q.containsKey("org_id") || access.desc(num(r.get("org_id")), id(q, "org_id")))
            .toList();
    return page(all, q);
  }

  private Object page(List<Map<String, Object>> l, Map<String, Object> q) {
    int p = integer(q, "page_no", 1), s = integer(q, "page_size", 20);
    range(p, 1, 100000, "page_no");
    range(s, 1, 100, "page_size");
    return new com.zhixiaotong.dto.PageDto(
        l.subList(Math.min(l.size(), (p - 1) * s), Math.min(l.size(), p * s)), l.size(), p, s);
  }

  private void validateClass(long org, Object cls) {
    if (cls != null) {
      var c = db.get("school_class", num(cls));
      check(
          access.desc(num(c.get("grade_id")), org) || access.desc(org, num(c.get("grade_id"))),
          400,
          "班级和组织归属不一致");
    }
  }

  public void validateNewUser(Map<String, Object> b) {
    long org = id(b, "org_id");
    access.org(org, "admin:write");
    text(b, "user_name", 64);
    text(b, "real_name", 32);
    String password = text(b, "password", 128);
    check(
        password.length() >= 10
            && password.matches(".*[A-Za-z].*")
            && password.matches(".*[0-9].*"),
        400,
        "初始密码至少10位且包含字母和数字");
    validateClass(org, b.get("class_id"));
    check(
        db.count("SELECT COUNT(*) FROM `user` WHERE user_name=?", str(b, "user_name")) == 0,
        409,
        "账号已存在");
  }

  @Transactional
  public Object createUser(Map<String, Object> b) {
    access.confirmed(b);
    validateNewUser(b);
    var v =
        map(
            "user_name",
            text(b, "user_name", 64),
            "password_hash",
            Crypto.password(text(b, "password", 128)),
            "real_name",
            text(b, "real_name", 32),
            "user_no",
            optional(b, "user_no", 32),
            "gender",
            integer(b, "gender", 0),
            "email",
            optional(b, "email", 128),
            "org_id",
            id(b, "org_id"),
            "class_id",
            b.get("class_id") == null ? null : id(b, "class_id"));
    long id = db.insert("user", v);
    audit.logAs(access.uid(), "USER_CREATE", "user", id, map(), true);
    return pick(db.get("user", id), "id", "user_name", "real_name", "org_id", "class_id");
  }

  @Transactional
  public Object updateUser(long id, Map<String, Object> b) {
    access.confirmed(b);
    var u = db.lock("user", id);
    access.org(num(u.get("org_id")), "admin:write");
    keys(
        b,
        "confirmed",
        "real_name",
        "user_no",
        "gender",
        "email",
        "org_id",
        "class_id",
        "user_status",
        "password");
    var v = pick(b, "real_name", "user_no", "gender", "email", "org_id", "class_id", "user_status");
    if (b.containsKey("real_name")) v.put("real_name", text(b, "real_name", 32));
    if (b.containsKey("email")) v.put("email", optional(b, "email", 128));
    long org = b.containsKey("org_id") ? id(b, "org_id") : num(u.get("org_id"));
    access.org(org, "admin:write");
    Object cls = b.containsKey("class_id") ? b.get("class_id") : u.get("class_id");
    validateClass(org, cls);
    if (b.containsKey("user_status")) {
      range(integer(b, "user_status", 1), 0, 2, "user_status");
      check(id != access.uid() || integer(b, "user_status", 1) == 1, 409, "不可停用当前操作账号");
    }
    if (b.containsKey("password")) {
      String p = text(b, "password", 128);
      check(p.length() >= 10, 400, "密码至少10位");
      v.put("password_hash", Crypto.password(p));
    }
    v.put("token_version", integer(u, "token_version", 0) + 1);
    db.update("user", id, v);
    db.exec(
        "UPDATE continuation SET task_status=4,reclaim_time=?,update_time=? WHERE user_id=? AND"
            + " task_status IN(0,1)",
        now(),
        now(),
        id);
    audit.logAs(access.uid(), "USER_UPDATE", "user", id, map("fields", v.keySet()), true);
    return pick(
        db.get("user", id), "id", "user_name", "real_name", "org_id", "class_id", "user_status");
  }

  @Transactional
  public Object grantUser(long uid, Map<String, Object> b) {
    access.confirmed(b);
    var u = db.lock("user", uid);
    access.org(num(u.get("org_id")), "admin:grant");
    List<Long> roleIds = ids(b, "role_ids");
    check(!roleIds.isEmpty(), 400, "至少分配一个角色");
    for (long id : roleIds) {
      var r = db.get("role", id);
      check(integer(r, "is_enabled", 0) == 1, 400, "角色未启用");
      for (var p :
          db.list(
              "SELECT p.permission_code FROM permission p JOIN role_permission rp ON"
                  + " rp.permission_id=p.id WHERE rp.role_id=?",
              id)) check(access.has(str(p, "permission_code")), 403, "不能委派本人没有的权限");
      check(
          integer(r, "scope_type", 0) != 5
              || access.roles(access.uid(), "admin:grant").stream()
                  .anyMatch(x -> integer(x, "scope_type", 0) == 5),
          403,
          "不能委派全校范围");
      if (str(r, "role_code").equals("STUDENT")) check(u.get("class_id") != null, 400, "学生必须关联班级");
    }
    db.exec(
        "DELETE FROM user_scope WHERE user_role_id IN(SELECT id FROM user_role WHERE user_id=?)",
        uid);
    db.exec("DELETE FROM user_role WHERE user_id=?", uid);
    for (long role : roleIds) {
      long ur = db.insert("user_role", map("user_id", uid, "role_id", role));
      var r = db.get("role", role);
      if (integer(r, "scope_type", 0) == 4) {
        check(b.get("org_id") != null, 400, "自定义角色必须指定org_id");
        long org = id(b, "org_id");
        access.org(org, "admin:grant");
        db.insert("user_scope", map("user_role_id", ur, "org_id", org, "include_children", 1));
      }
    }
    db.exec("UPDATE `user` SET token_version=token_version+1,update_time=? WHERE id=?", now(), uid);
    audit.logAs(access.uid(), "ROLE_GRANT", "user", uid, map("role_ids", roleIds), true);
    return map("user_id", uid, "role_ids", roleIds);
  }

  @Transactional
  public Object role(long id, Map<String, Object> b) {
    access.confirmed(b);
    global("admin:grant");
    db.lock("role", id);
    var permissions = ids(b, "permission_ids");
    for (long p : permissions)
      check(access.has(str(db.get("permission", p), "permission_code")), 403, "不能授予本人未持有的权限");
    int scope = integer(b, "scope_type", 1);
    range(scope, 1, 5, "scope_type");
    if (scope == 5)
      check(
          access.roles(access.uid(), "admin:grant").stream()
              .anyMatch(r -> integer(r, "scope_type", 0) == 5),
          403,
          "不能授予全校范围");
    db.exec("DELETE FROM role_permission WHERE role_id=?", id);
    for (long p : permissions) db.insert("role_permission", map("role_id", id, "permission_id", p));
    db.update(
        "role",
        id,
        map(
            "role_name",
            text(b, "role_name", 32),
            "scope_type",
            scope,
            "is_enabled",
            integer(b, "is_enabled", 1)));
    db.exec(
        "UPDATE `user` SET token_version=token_version+1,update_time=? WHERE id IN(SELECT user_id"
            + " FROM user_role WHERE role_id=?)",
        now(),
        id);
    audit.logAs(
        access.uid(),
        "ROLE_UPDATE",
        "role",
        id,
        map("permission_ids", permissions, "scope_type", scope),
        true);
    return db.get("role", id);
  }

  @Transactional
  public Object semester(Map<String, Object> b) {
    access.confirmed(b);
    global("admin:write");
    configLock();
    var start = date(b.get("start_date"));
    var end = date(b.get("end_date"));
    check(end.isAfter(start), 400, "学期起止日期不合法");
    int weeks = integer(b, "week_count", 0);
    range(weeks, 1, 53, "week_count");
    int current = integer(b, "is_current", 0);
    range(current, 0, 1, "is_current");
    if (current == 1) db.exec("UPDATE semester SET is_current=0,update_time=?", now());
    var v =
        map(
            "semester_code",
            text(b, "semester_code", 32),
            "semester_name",
            text(b, "semester_name", 64),
            "start_date",
            start,
            "end_date",
            end,
            "week_count",
            weeks,
            "is_current",
            current,
            "is_locked",
            integer(b, "is_locked", 0));
    long id = b.get("id") == null ? db.insert("semester", v) : id(b, "id");
    if (b.get("id") != null) {
      var old = db.get("semester", id);
      check(
          integer(old, "is_locked", 0) == 0 || integer(b, "is_locked", 0) == 1,
          409,
          "已锁定学期不能由此接口解锁");
      db.update("semester", id, v);
    }
    audit.logAs(access.uid(), "SEMESTER_SAVE", "semester", id, map(), true);
    return db.get("semester", id);
  }

  @Transactional
  public Object teachingClass(Map<String, Object> b) {
    access.confirmed(b);
    configLock();
    var c = db.get("course", id(b, "course_id"));
    access.org(num(c.get("org_id")), "admin:write");
    var sem = db.get("semester", id(b, "semester_id"));
    check(integer(sem, "is_locked", 0) == 0, 409, "学期已锁定");
    long teacher = id(b, "teacher_id");
    check(
        db.count(
                "SELECT COUNT(*) FROM user_role ur JOIN `role` r ON r.id=ur.role_id JOIN `user` u"
                    + " ON u.id=ur.user_id WHERE ur.user_id=? AND r.role_code='TEACHER' AND"
                    + " u.user_status=1 AND r.is_enabled=1",
                teacher)
            > 0,
        400,
        "授课人必须是有效教师");
    var uw = dec(b, "usual_weight");
    var fw = dec(b, "final_weight");
    check(
        uw.signum() >= 0 && fw.signum() >= 0 && uw.add(fw).compareTo(BigDecimal.ONE) == 0,
        400,
        "平时与期末权重之和应为1");
    int cap = integer(b, "capacity", 0);
    range(cap, 1, 10000, "capacity");
    var v =
        map(
            "class_code",
            text(b, "class_code", 32),
            "class_name",
            text(b, "class_name", 64),
            "course_id",
            c.get("id"),
            "semester_id",
            sem.get("id"),
            "teacher_id",
            teacher,
            "capacity",
            cap,
            "usual_weight",
            uw,
            "final_weight",
            fw,
            "class_status",
            integer(b, "class_status", 1));
    long id = b.get("id") == null ? db.insert("teaching_class", v) : id(b, "id");
    if (b.get("id") != null) {
      var old = db.lock("teaching_class", id);
      access.org(num(db.get("course", num(old.get("course_id"))).get("org_id")), "admin:write");
      check(
          eq(old.get("course_id"), c.get("id")) && eq(old.get("semester_id"), sem.get("id")),
          409,
          "已有教学班不能改课程或学期");
      check(cap >= integer(old, "enrolled_count", 0), 409, "容量不能小于已选人数");
      check(
          db.count(
                  "SELECT COUNT(*) FROM grade_review WHERE teaching_class_id=? AND review_status"
                      + " IN(0,1)",
                  id)
              == 0,
          409,
          "已提交或发布成绩的教学班不能更改评分配置");
      v.put("version", integer(old, "version", 0) + 1);
      db.update("teaching_class", id, v);
    }
    audit.logAs(access.uid(), "TEACHING_CLASS_SAVE", "teaching_class", id, map(), true);
    return db.get("teaching_class", id);
  }

  @Transactional
  public Object timetable(Map<String, Object> b) {
    access.confirmed(b);
    configLock();
    var tc = db.get("teaching_class", id(b, "teaching_class_id"));
    access.org(num(db.get("course", num(tc.get("course_id"))).get("org_id")), "admin:write");
    var v =
        pick(
            b,
            "teaching_class_id",
            "classroom_id",
            "start_week",
            "end_week",
            "week_mode",
            "week_day",
            "start_period",
            "end_period");
    v.put("start_time", clock(b.get("start_time")));
    v.put("end_time", clock(b.get("end_time")));
    Long id = b.get("id") == null ? null : id(b, "id");
    if (id != null) {
      var old = db.get("timetable", id);
      check(eq(old.get("teaching_class_id"), tc.get("id")), 400, "不能把已有排课移动到其他教学班");
    }
    schedule.validate(v, id);
    long key = id == null ? db.insert("timetable", v) : id;
    if (id != null) db.update("timetable", id, v);
    audit.logAs(access.uid(), "TIMETABLE_SAVE", "timetable", key, map(), true);
    audit.event(
        "teaching_class",
        num(tc.get("id")),
        "课程安排已更新",
        db
            .list(
                "SELECT student_id FROM enrollment WHERE teaching_class_id=? AND enroll_status=1",
                tc.get("id"))
            .stream()
            .map(r -> num(r.get("student_id")))
            .toList());
    return db.get("timetable", key);
  }

  @Transactional
  public Object batch(Map<String, Object> b) {
    access.confirmed(b);
    global("admin:write");
    configLock();
    var sem = db.get("semester", id(b, "semester_id"));
    check(integer(sem, "is_locked", 0) == 0, 409, "学期已锁定");
    var start = time(b.get("start_time"));
    var end = time(b.get("end_time"));
    check(end.isAfter(start), 400, "批次起止时间错误");
    var drop = b.get("drop_deadline") == null ? null : time(b.get("drop_deadline"));
    check(drop == null || (!drop.isBefore(start) && !drop.isAfter(end)), 400, "退选截止须位于批次时间内");
    int stage = integer(b, "batch_stage", 1);
    range(stage, 1, 3, "batch_stage");
    var courses = rows(b, "courses");
    check(!courses.isEmpty(), 400, "批次至少包含一个教学班");
    long id =
        db.insert(
            "selection_batch",
            map(
                "batch_code",
                text(b, "batch_code", 32),
                "batch_name",
                text(b, "batch_name", 64),
                "semester_id",
                sem.get("id"),
                "batch_stage",
                stage,
                "start_time",
                start,
                "end_time",
                end,
                "drop_deadline",
                drop,
                "max_courses",
                integer(b, "max_courses", 0),
                "max_credits",
                b.getOrDefault("max_credits", BigDecimal.ZERO),
                "announcement",
                optional(b, "announcement", 20000),
                "batch_status",
                integer(b, "batch_status", 1)));
    for (var item : courses) {
      var tc = db.get("teaching_class", id(item, "teaching_class_id"));
      check(eq(tc.get("semester_id"), sem.get("id")), 400, "批次教学班学期不一致");
      int admission = integer(item, "admission_type", 1);
      range(admission, 1, 3, "admission_type");
      if (admission == 3) {
        check(item.get("priority_rule") instanceof Map, 400, "优先级录取须配置priority_rule");
        var rule = (Map<?, ?>) item.get("priority_rule");
        check(
            Set.of("student_id", "enroll_time").contains(rule.get("order_by")),
            400,
            "优先级仅支持student_id或enroll_time");
      }
      long bc =
          db.insert(
              "batch_course",
              map(
                  "batch_id",
                  id,
                  "teaching_class_id",
                  tc.get("id"),
                  "admission_type",
                  admission,
                  "priority_rule",
                  item.get("priority_rule") == null
                      ? null
                      : Json.write(item.get("priority_rule"))));
      var scopes = rows(item, "scopes");
      check(!scopes.isEmpty(), 400, "选课范围不能为空");
      for (var s : scopes) {
        check(
            (s.get("org_id") == null) != (s.get("class_id") == null), 400, "org_id和class_id恰好填写一个");
        if (s.get("org_id") != null) access.org(id(s, "org_id"), "admin:write");
        else
          access.org(num(db.get("school_class", id(s, "class_id")).get("grade_id")), "admin:write");
        db.insert(
            "selection_scope",
            map(
                "batch_course_id",
                bc,
                "org_id",
                s.get("org_id"),
                "class_id",
                s.get("class_id"),
                "include_children",
                integer(s, "include_children", 1)));
      }
    }
    audit.logAs(
        access.uid(),
        "BATCH_CREATE",
        "selection_batch",
        id,
        map("course_count", courses.size()),
        true);
    return db.get("selection_batch", id);
  }

  public Object audit(Map<String, Object> q) {
    access.require("audit:read");
    var rows =
        db.list("SELECT * FROM audit_log ORDER BY id DESC").stream()
            .filter(
                r ->
                    !q.containsKey("operator_id") || eq(r.get("operator_id"), q.get("operator_id")))
            .filter(r -> !q.containsKey("biz_type") || eq(r.get("biz_type"), q.get("biz_type")))
            .filter(
                r ->
                    !q.containsKey("start_time")
                        || !time(r.get("operate_time")).isBefore(time(q.get("start_time"))))
            .filter(
                r ->
                    !q.containsKey("end_time")
                        || time(r.get("operate_time")).isBefore(time(q.get("end_time"))))
            .filter(
                r ->
                    r.get("operator_id") == null
                        ? access.canOrg(access.uid(), root(), "audit:read")
                        : access.canStudent(access.uid(), num(r.get("operator_id")), "audit:read"))
            .filter(
                r ->
                    !q.containsKey("action_type") || eq(r.get("action_type"), q.get("action_type")))
            .toList();
    return page(rows, q);
  }

  private static final Map<String, String> RESOURCES =
      Map.ofEntries(
          Map.entry("courses", "course"),
          Map.entry("classes", "school_class"),
          Map.entry("classrooms", "classroom"),
          Map.entry("counselors", "counselor_class"),
          Map.entry("prerequisites", "course_prereq"),
          Map.entry("aid-batches", "aid_batch"),
          Map.entry("books", "book"),
          Map.entry("book-copies", "book_copy"),
          Map.entry("configs", "system_config"),
          Map.entry("exams", "exam_plan"),
          Map.entry("roles", "role"),
          Map.entry("permissions", "permission"),
          Map.entry("semesters", "semester"),
          Map.entry("teaching-classes", "teaching_class"),
          Map.entry("selection-batches", "selection_batch"));

  public Object catalog(String resource, Map<String, Object> q) {
    access.require("admin:read");
    String t = RESOURCES.get(resource);
    check(t != null, 404, "资源不存在");
    global("admin:read");
    return db.page("SELECT * FROM `" + t + "` ORDER BY id", q);
  }

  @Transactional
  public Object base(String resource, Map<String, Object> b) {
    access.confirmed(b);
    global("admin:write");
    configLock();
    String t = RESOURCES.get(resource);
    check(t != null, 404, "资源不存在");
    Map<String, Object> v;
    switch (resource) {
      case "courses" -> {
        long org = id(b, "org_id");
        access.org(org, "admin:write");
        v =
            map(
                "course_code",
                text(b, "course_code", 32),
                "course_name",
                text(b, "course_name", 128),
                "org_id",
                org,
                "course_type",
                text(b, "course_type", 32),
                "credit",
                dec(b, "credit"),
                "total_hours",
                integer(b, "total_hours", 0),
                "syllabus",
                optional(b, "syllabus", 30000),
                "is_enabled",
                integer(b, "is_enabled", 1));
        check(dec(v, "credit").signum() > 0 && integer(v, "total_hours", 0) > 0, 400, "学分和学时必须为正");
      }
      case "classes" -> {
        var grade = db.get("org_unit", id(b, "grade_id"));
        check(integer(grade, "org_type", 0) == 4, 400, "grade_id必须指向年级");
        v =
            map(
                "class_code",
                text(b, "class_code", 32),
                "class_name",
                text(b, "class_name", 64),
                "grade_id",
                grade.get("id"),
                "entry_year",
                integer(b, "entry_year", 0),
                "school_years",
                integer(b, "school_years", 3),
                "class_status",
                integer(b, "class_status", 1));
      }
      case "classrooms" -> {
        v =
            map(
                "room_code",
                text(b, "room_code", 32),
                "room_name",
                text(b, "room_name", 64),
                "campus_name",
                text(b, "campus_name", 64),
                "building_name",
                text(b, "building_name", 64),
                "capacity",
                integer(b, "capacity", 0),
                "is_enabled",
                integer(b, "is_enabled", 1));
        check(integer(v, "capacity", 0) > 0, 400, "教室容量必须为正");
      }
      case "counselors" -> {
        long counselor = id(b, "counselor_id");
        check(
            db.count(
                    "SELECT COUNT(*) FROM user_role ur JOIN `role` r ON r.id=ur.role_id WHERE"
                        + " ur.user_id=? AND r.role_code='COUNSELOR' AND r.is_enabled=1",
                    counselor)
                > 0,
            400,
            "人员没有辅导员角色");
        var start = time(b.get("start_time"));
        var end = b.get("end_time") == null ? null : time(b.get("end_time"));
        check(end == null || end.isAfter(start), 400, "任职时段错误");
        v =
            map(
                "counselor_id",
                counselor,
                "class_id",
                id(b, "class_id"),
                "start_time",
                start,
                "end_time",
                end);
      }
      case "prerequisites" -> {
        long course = id(b, "course_id"), pre = id(b, "prereq_id");
        check(
            course != pre && !prerequisiteReaches(pre, course, new HashSet<>()), 400, "先修关系不能形成环");
        v =
            map(
                "course_id",
                course,
                "prereq_id",
                pre,
                "min_score",
                b.getOrDefault("min_score", new BigDecimal("60")));
      }
      case "aid-batches" -> {
        var start = time(b.get("start_time"));
        var end = time(b.get("end_time"));
        check(end.isAfter(start), 400, "批次时段错误");
        v =
            map(
                "batch_name",
                text(b, "batch_name", 128),
                "aid_type",
                text(b, "aid_type", 32),
                "org_id",
                id(b, "org_id"),
                "semester_id",
                id(b, "semester_id"),
                "start_time",
                start,
                "end_time",
                end,
                "quota",
                integer(b, "quota", 0),
                "aid_amount",
                dec(b, "aid_amount"),
                "requirements",
                text(b, "requirements", 20000),
                "batch_status",
                integer(b, "batch_status", 1));
        check(integer(v, "quota", 0) > 0 && dec(v, "aid_amount").signum() > 0, 400, "资助名额和金额必须为正");
      }
      case "books" ->
          v =
              map(
                  "book_code",
                  text(b, "book_code", 32),
                  "isbn",
                  optional(b, "isbn", 20),
                  "book_name",
                  text(b, "book_name", 128),
                  "author",
                  text(b, "author", 128),
                  "publisher",
                  optional(b, "publisher", 128),
                  "category_code",
                  text(b, "category_code", 32),
                  "summary",
                  optional(b, "summary", 20000));
      case "book-copies" -> {
        v =
            map(
                "book_id",
                id(b, "book_id"),
                "copy_no",
                text(b, "copy_no", 32),
                "location",
                text(b, "location", 128),
                "copy_status",
                integer(b, "copy_status", 0));
        check(Set.of(0, 3).contains(integer(v, "copy_status", 0)), 400, "仅能在管理端设置可借或停用");
      }
      case "configs" -> {
        String key = text(b, "config_key", 64);
        String configValue = text(b, "config_value", 20000);
        if (key.equals("file.allowed_extensions"))
          for (String ext : configValue.split(","))
            check(
                Set.of("pdf", "png", "jpg", "jpeg", "txt", "csv", "docx", "xlsx", "pptx")
                    .contains(ext.trim()),
                400,
                "只能启用服务端已支持的安全文件类型");
        if (key.equals("file.max_mb")) range(Integer.parseInt(configValue), 1, 100, "文件大小MB");
        check(
            !key.toLowerCase().matches(".*(password|secret|token|private|credential).*"),
            400,
            "密钥通过环境变量配置");
        v =
            map(
                "config_group",
                text(b, "config_group", 64),
                "config_key",
                key,
                "config_name",
                text(b, "config_name", 64),
                "config_value",
                text(b, "config_value", 20000),
                "value_type",
                text(b, "value_type", 16),
                "updater_id",
                access.uid(),
                "is_enabled",
                integer(b, "is_enabled", 1));
      }
      case "exams" -> {
        long tc = id(b, "teaching_class_id");
        var teaching = db.get("teaching_class", tc);
        check(
            integer(db.get("semester", num(teaching.get("semester_id"))), "is_locked", 0) == 0,
            409,
            "学期已锁定");
        var start = time(b.get("start_time"));
        var end = time(b.get("end_time"));
        check(end.isAfter(start), 400, "考试时段错误");
        long room = id(b, "classroom_id"), inv = id(b, "invigilator_id");
        Long assistant = b.get("assistant_id") == null ? null : id(b, "assistant_id");
        var r = db.get("classroom", room);
        check(
            integer(r, "is_enabled", 0) == 1
                && integer(r, "capacity", 0) >= integer(teaching, "enrolled_count", 0),
            400,
            "考试教室不可用或容量不足");
        for (var x :
            db.list(
                "SELECT * FROM exam_plan WHERE plan_status<>2 AND start_time<? AND end_time>?",
                end,
                start))
          if (!eq(x.get("id"), b.get("id")))
            check(
                !eq(x.get("classroom_id"), room)
                    && !eq(x.get("invigilator_id"), inv)
                    && !eq(x.get("assistant_id"), inv)
                    && (assistant == null
                        || (!eq(x.get("invigilator_id"), assistant)
                            && !eq(x.get("assistant_id"), assistant))),
                409,
                "教室或监考安排冲突");
        v =
            map(
                "teaching_class_id",
                tc,
                "classroom_id",
                room,
                "exam_name",
                text(b, "exam_name", 64),
                "start_time",
                start,
                "end_time",
                end,
                "invigilator_id",
                inv,
                "assistant_id",
                assistant,
                "plan_status",
                integer(b, "plan_status", 1));
      }
      default -> throw new BizException(400, "请使用该资源的专用业务接口");
    }
    Long id = b.get("id") == null ? null : id(b, "id");
    if (id != null) {
      var old = db.lock(t, id);
      if (t.equals("book_copy"))
        check(Set.of(0, 3).contains(integer(old, "copy_status", 0)), 409, "借出或预约中的副本不可直接改状态");
      db.update(t, id, v);
    } else id = db.insert(t, v);
    audit.logAs(access.uid(), "BASE_SAVE", t, id, map("resource", resource), true);
    return db.get(t, id);
  }

  private boolean prerequisiteReaches(long from, long target, Set<Long> seen) {
    if (from == target) return true;
    if (!seen.add(from)) return false;
    for (var r : db.list("SELECT prereq_id FROM course_prereq WHERE course_id=?", from))
      if (prerequisiteReaches(num(r.get("prereq_id")), target, seen)) return true;
    return false;
  }

  public Object summary() {
    access.require("report:export");
    global("report:export");
    return map(
        "users",
        db.count("SELECT COUNT(*) FROM `user` WHERE user_status=1"),
        "successful_enrollments",
        db.count("SELECT COUNT(*) FROM enrollment WHERE enroll_status=1"),
        "pending_leaves",
        db.count("SELECT COUNT(*) FROM leave_request WHERE leave_status IN(1,2)"),
        "pending_reviews",
        db.count("SELECT COUNT(*) FROM grade_review WHERE review_status=0"),
        "outbox_failures",
        db.count("SELECT COUNT(*) FROM outbox_event WHERE send_status=3"));
  }
}
