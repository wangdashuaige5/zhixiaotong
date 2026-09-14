package com.zhixiaotong.service.impl;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Access;
import com.zhixiaotong.service.*;
import java.math.BigDecimal;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

/** 锁顺序：学生user -> 教学班teaching_class -> 选课记录。 */
@Service
public class EnrollmentServiceImpl implements IEnrollmentService {
  public Object batches() {
    access.student();
    access.require("enrollment:write");
    var user = access.user();
    return db.list("SELECT * FROM selection_batch ORDER BY start_time DESC").stream()
        .filter(
            b ->
                db.list("SELECT id FROM batch_course WHERE batch_id=?", b.get("id")).stream()
                    .anyMatch(c -> inScope(user, num(c.get("id")))))
        .toList();
  }

  private final Db db;
  private final Access access;
  private final AuditService audit;
  private final ScheduleValidator schedule;
  private final TransactionTemplate tx;

  public EnrollmentServiceImpl(
      Db db,
      Access access,
      AuditService audit,
      ScheduleValidator schedule,
      TransactionTemplate tx) {
    this.db = db;
    this.access = access;
    this.audit = audit;
    this.schedule = schedule;
    this.tx = tx;
  }

  private boolean inScope(Map<String, Object> user, long bc) {
    for (var s : db.list("SELECT * FROM selection_scope WHERE batch_course_id=?", bc)) {
      if (s.get("class_id") != null && eq(s.get("class_id"), user.get("class_id"))) return true;
      if (s.get("org_id") != null
          && (eq(s.get("org_id"), user.get("org_id"))
              || (integer(s, "include_children", 0) == 1
                  && access.desc(num(user.get("org_id")), num(s.get("org_id")))))) return true;
    }
    return false;
  }

  public Object options(Map<String, Object> q) {
    access.require("enrollment:write");
    access.student();
    long batch = id(q, "batch_id");
    var b = db.get("selection_batch", batch);
    open(b);
    var user = access.user();
    var all =
        db.list(
            "SELECT"
                + " bc.*,tc.class_name,tc.capacity,tc.enrolled_count,c.course_name,c.credit,u.real_name"
                + " AS teacher_name FROM batch_course bc JOIN teaching_class tc ON"
                + " tc.id=bc.teaching_class_id JOIN course c ON c.id=tc.course_id JOIN `user` u ON"
                + " u.id=tc.teacher_id WHERE bc.batch_id=? AND tc.class_status=1 AND c.is_enabled=1"
                + " ORDER BY bc.id",
            batch);
    var visible =
        all.stream()
            .filter(r -> inScope(user, num(r.get("id"))))
            .filter(
                r ->
                    !q.containsKey("keywords")
                        || str(r, "course_name").contains(str(q, "keywords")))
            .toList();
    return slice(visible, q);
  }

  private Object slice(List<Map<String, Object>> l, Map<String, Object> q) {
    int p = integer(q, "page_no", 1), s = integer(q, "page_size", 20);
    range(p, 1, 100000, "page_no");
    range(s, 1, 100, "page_size");
    return new com.zhixiaotong.dto.PageDto(
        l.subList(Math.min(l.size(), (p - 1) * s), Math.min(l.size(), p * s)), l.size(), p, s);
  }

  private void open(Map<String, Object> b) {
    check(
        integer(b, "batch_status", 0) == 1
            && !now().isBefore(time(b.get("start_time")))
            && now().isBefore(time(b.get("end_time"))),
        409,
        "选课批次不在开放时间");
    check(
        integer(db.get("semester", num(b.get("semester_id"))), "is_locked", 0) == 0, 409, "学期已锁定");
  }

  private void rules(
      Map<String, Object> u,
      Map<String, Object> bc,
      Map<String, Object> tc,
      Map<String, Object> batch) {
    long student = num(u.get("id")), classId = num(tc.get("id"));
    check(inScope(u, num(bc.get("id"))), 403, "不在选课开放范围");
    check(integer(tc, "class_status", 0) == 1, 409, "教学班尚未开放");
    check(
        integer(db.get("semester", num(tc.get("semester_id"))), "is_locked", 0) == 0, 409, "学期已锁定");
    check(eq(tc.get("semester_id"), batch.get("semester_id")), 400, "批次与教学班学期不一致");
    check(
        db.count(
                "SELECT COUNT(*) FROM enrollment e JOIN teaching_class t ON"
                    + " e.teaching_class_id=t.id WHERE e.student_id=? AND e.enroll_status=1 AND"
                    + " t.semester_id=? AND t.course_id=? AND t.id<>?",
                student,
                tc.get("semester_id"),
                tc.get("course_id"),
                classId)
            == 0,
        409,
        "本学期已经选择该课程");
    for (var pre : db.list("SELECT * FROM course_prereq WHERE course_id=?", tc.get("course_id")))
      check(
          db.count(
                  "SELECT COUNT(*) FROM grade g JOIN enrollment e ON g.enrollment_id=e.id JOIN"
                      + " teaching_class t ON t.id=e.teaching_class_id WHERE e.student_id=? AND"
                      + " t.course_id=? AND g.grade_status=3 AND g.total_score>=?",
                  student,
                  pre.get("prereq_id"),
                  pre.get("min_score"))
              > 0,
          409,
          "未满足先修课程条件");
    var amounts =
        db.one(
            "SELECT COUNT(*) AS course_count,COALESCE(SUM(c.credit),0) AS credits FROM enrollment e"
                + " JOIN teaching_class tc ON tc.id=e.teaching_class_id JOIN course c ON"
                + " c.id=tc.course_id WHERE e.student_id=? AND e.enroll_status=1 AND"
                + " tc.semester_id=? AND tc.id<>?",
            student,
            tc.get("semester_id"),
            classId);
    int max = integer(batch, "max_courses", 0);
    check(max == 0 || num(amounts.get("course_count")) < max, 409, "超过课程数上限");
    BigDecimal credit = dec(db.get("course", num(tc.get("course_id"))), "credit"),
        cap = dec(batch, "max_credits");
    check(
        cap.signum() == 0 || decimal(amounts.get("credits")).add(credit).compareTo(cap) <= 0,
        409,
        "超过学分上限");
    schedule.studentConflict(student, classId);
  }

  @Transactional
  public Map<String, Object> submit(Map<String, Object> b) {
    access.student();
    access.require("enrollment:write");
    String key = text(b, "request_key", 64);
    long bcId = id(b, "batch_course_id");
    var u = db.lock("user", access.uid());
    var bc = db.get("batch_course", bcId);
    String eventKey = com.zhixiaotong.security.Crypto.hash("enrollment-request:" + key);
    var history = db.one("SELECT payload FROM outbox_event WHERE event_key=?", eventKey);
    if (history != null) {
      var p = Json.object(history.get("payload"));
      check(
          eq(p.get("student_id"), access.uid()) && eq(p.get("batch_course_id"), bcId),
          409,
          "请求键已用于其他选课");
      return db.get("enrollment", num(p.get("biz_id")));
    }
    var previous = db.one("SELECT * FROM enrollment WHERE request_key=?", key);
    if (previous != null) {
      check(
          eq(previous.get("student_id"), access.uid()) && eq(previous.get("batch_course_id"), bcId),
          409,
          "请求键已用于其他选课");
      return previous;
    }
    var tc = db.lock("teaching_class", num(bc.get("teaching_class_id")));
    var batch = db.get("selection_batch", num(bc.get("batch_id")));
    open(batch);
    rules(u, bc, tc, batch);
    long tid = num(tc.get("id"));
    var old =
        db.one(
            "SELECT * FROM enrollment WHERE student_id=? AND teaching_class_id=? FOR UPDATE",
            access.uid(),
            tid);
    check(
        old == null || Set.of(2, 3).contains(integer(old, "enroll_status", 0)),
        409,
        "已存在有效申请，请沿用原请求键");
    int status = integer(bc, "admission_type", 1) == 1 ? 1 : 0;
    if (status == 1)
      check(
          db.exec(
                  "UPDATE teaching_class SET"
                      + " enrolled_count=enrolled_count+1,version=version+1,update_time=? WHERE"
                      + " id=? AND enrolled_count<capacity AND version=?",
                  now(),
                  tid,
                  tc.get("version"))
              == 1,
          409,
          "课程名额不足");
    var v =
        map(
            "student_id",
            access.uid(),
            "teaching_class_id",
            tid,
            "batch_course_id",
            bcId,
            "request_key",
            key,
            "enroll_status",
            status,
            "selection_rank",
            null,
            "enroll_time",
            now(),
            "drop_time",
            null,
            "result_note",
            status == 1 ? "选课成功" : "等待批次筛选",
            "version",
            old == null ? 0 : integer(old, "version", 0) + 1);
    long id = old == null ? db.insert("enrollment", v) : num(old.get("id"));
    if (old != null) db.update("enrollment", id, v);
    audit.log("ENROLL", "enrollment", id, map("status", status));
    db.insert(
        "outbox_event",
        map(
            "event_key",
            eventKey,
            "event_type",
            "BUSINESS",
            "payload",
            Json.write(
                map(
                    "biz_type",
                    "enrollment",
                    "biz_id",
                    id,
                    "title",
                    "选课申请状态已更新",
                    "receivers",
                    List.of(access.uid()),
                    "student_id",
                    access.uid(),
                    "batch_course_id",
                    bcId))));
    return db.get("enrollment", id);
  }

  @Transactional
  public Map<String, Object> drop(long id) {
    access.student();
    access.require("enrollment:write");
    db.lock("user", access.uid());
    var e = db.get("enrollment", id);
    check(eq(e.get("student_id"), access.uid()), 403, "只能退选本人课程");
    var tc = db.lock("teaching_class", num(e.get("teaching_class_id")));
    e = db.lock("enrollment", id);
    if (integer(e, "enroll_status", 0) == 3) return e;
    check(integer(e, "enroll_status", 0) == 1, 409, "只有成功选课可退选");
    check(
        integer(db.get("semester", num(tc.get("semester_id"))), "is_locked", 0) == 0, 409, "学期已锁定");
    check(
        db.count(
                "SELECT COUNT(*) FROM selection_batch b JOIN batch_course bc ON bc.batch_id=b.id"
                    + " WHERE bc.teaching_class_id=? AND b.batch_stage=3 AND b.batch_status=1 AND"
                    + " b.start_time<=? AND b.end_time>? AND b.drop_deadline>=?",
                tc.get("id"),
                now(),
                now(),
                now())
            > 0,
        409,
        "不在补退选时间");
    check(
        db.exec(
                "UPDATE teaching_class SET"
                    + " enrolled_count=enrolled_count-1,version=version+1,update_time=? WHERE id=?"
                    + " AND enrolled_count>0",
                now(),
                tc.get("id"))
            == 1,
        409,
        "人数数据不一致");
    db.update(
        "enrollment",
        id,
        map(
            "enroll_status",
            3,
            "drop_time",
            now(),
            "version",
            integer(e, "version", 0) + 1,
            "result_note",
            "已退选"));
    audit.log("DROP", "enrollment", id, map("status", 3));
    audit.event("enrollment", id, "退选已完成", List.of(access.uid()));
    return db.get("enrollment", id);
  }

  public Object mine(Map<String, Object> q) {
    access.student();
    String sql =
        "SELECT e.*,c.course_name,tc.class_name,tc.semester_id FROM enrollment e JOIN"
            + " teaching_class tc ON tc.id=e.teaching_class_id JOIN course c ON c.id=tc.course_id"
            + " WHERE e.student_id=?";
    var a = new ArrayList<Object>();
    a.add(access.uid());
    if (q.containsKey("semester_id")) {
      sql += " AND tc.semester_id=?";
      a.add(id(q, "semester_id"));
    }
    if (q.containsKey("enroll_status")) {
      sql += " AND e.enroll_status=?";
      a.add(integer(q, "enroll_status", 0));
    }
    return db.page(sql + " ORDER BY e.id DESC", q, a.toArray());
  }

  /** 排名先独立提交，重启不重新抽签；每名学生单独事务，失败不影响其他已完成结果。 */
  public void settle(long bcId) {
    tx.executeWithoutResult(
        s -> {
          var bc = db.lock("batch_course", bcId);
          var batch = db.get("selection_batch", num(bc.get("batch_id")));
          check(!now().isBefore(time(batch.get("end_time"))), 409, "批次尚未结束");
          if (integer(bc, "process_status", 0) == 2) return;
          var rows =
              new ArrayList<>(
                  db.list(
                      "SELECT * FROM enrollment WHERE batch_course_id=? AND enroll_status=0 ORDER"
                          + " BY student_id",
                      bcId));
          if (rows.stream().allMatch(r -> r.get("selection_rank") == null)) {
            if (integer(bc, "admission_type", 1) == 2)
              Collections.shuffle(rows, new java.security.SecureRandom());
            else if (integer(bc, "admission_type", 1) == 3) {
              var rule =
                  bc.get("priority_rule") == null
                      ? Map.<String, Object>of()
                      : Json.object(bc.get("priority_rule"));
              check(
                  Set.of("enroll_time", "student_id").contains(str(rule, "order_by")),
                  400,
                  "优先级规则仅支持enroll_time或student_id");
              rows.sort(
                  str(rule, "order_by").equals("student_id")
                      ? Comparator.comparingLong(r -> num(r.get("student_id")))
                      : Comparator.comparing(r -> time(r.get("enroll_time"))));
            }
            int n = 1;
            for (var e : rows)
              db.update("enrollment", num(e.get("id")), map("selection_rank", n++));
          }
          db.update("batch_course", bcId, map("process_status", 1));
        });
    for (var candidate :
        db.list(
            "SELECT id,student_id FROM enrollment WHERE batch_course_id=? AND enroll_status=0 ORDER"
                + " BY selection_rank,id",
            bcId))
      tx.executeWithoutResult(
          s -> {
            var u = db.lock("user", num(candidate.get("student_id")));
            var bc = db.get("batch_course", bcId);
            var tc = db.lock("teaching_class", num(bc.get("teaching_class_id")));
            var e = db.lock("enrollment", num(candidate.get("id")));
            if (integer(e, "enroll_status", 0) != 0) return;
            int status = 1;
            String note = "筛选录取";
            try {
              rules(u, bc, tc, db.get("selection_batch", num(bc.get("batch_id"))));
              check(integer(tc, "enrolled_count", 0) < integer(tc, "capacity", 0), 409, "名额不足");
            } catch (BizException ex) {
              status = 2;
              note = ex.getMessage();
            }
            if (status == 1)
              db.exec(
                  "UPDATE teaching_class SET"
                      + " enrolled_count=enrolled_count+1,version=version+1,update_time=? WHERE"
                      + " id=?",
                  now(),
                  tc.get("id"));
            db.update(
                "enrollment",
                num(e.get("id")),
                map(
                    "enroll_status",
                    status,
                    "result_note",
                    note,
                    "version",
                    integer(e, "version", 0) + 1));
            audit.log("SETTLE", "enrollment", num(e.get("id")), map("status", status));
            audit.event("enrollment", num(e.get("id")), "选课筛选已完成", List.of(num(u.get("id"))));
          });
    tx.executeWithoutResult(
        s -> db.update("batch_course", bcId, map("process_status", 2, "process_time", now())));
  }
}
