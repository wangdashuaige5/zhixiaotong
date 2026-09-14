package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import java.util.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class ReportService {
  private final Db db;
  private final Access access;
  private final FileService files;
  private final AdminService admin;
  private final GradeService grades;
  private final AuditService audit;
  private final TransactionTemplate tx;

  public ReportService(
      Db db,
      Access access,
      FileService files,
      AdminService admin,
      GradeService grades,
      AuditService audit,
      TransactionTemplate tx) {
    this.db = db;
    this.access = access;
    this.files = files;
    this.admin = admin;
    this.grades = grades;
    this.audit = audit;
    this.tx = tx;
  }

  @Transactional
  public Object create(Map<String, Object> b) {
    access.require("report:export");
    String type = text(b, "task_type", 32);
    check(
        Set.of("USER_EXPORT", "ENROLLMENT_EXPORT", "AUDIT_EXPORT", "USER_IMPORT", "GRADE_IMPORT")
            .contains(type),
        400,
        "支持USER_EXPORT、ENROLLMENT_EXPORT、AUDIT_EXPORT、USER_IMPORT、GRADE_IMPORT");
    check(b.get("task_params") instanceof Map, 400, "task_params必须为对象");
    @SuppressWarnings("unchecked")
    var input = (Map<String, Object>) b.get("task_params");
    keys(input, "org_id", "course_id", "teaching_class_id");
    var p = new LinkedHashMap<>(input);
    if (type.equals("GRADE_IMPORT")) {
      access.courseClass(id(p, "course_id"), p, true);
      access.require("grade:write");
    } else access.org(id(p, "org_id"), "report:export");
    if (type.equals("AUDIT_EXPORT")) access.org(id(p, "org_id"), "audit:read");
    p.put("creator_version", integer(access.user(), "token_version", 0));
    p.put("phase", type.endsWith("IMPORT") ? "validate" : "export");
    Long file = b.get("input_file_id") == null ? null : id(b, "input_file_id");
    if (type.endsWith("IMPORT")) {
      check(file != null, 400, "导入必须提供input_file_id");
      var f = db.get("file_upload", file);
      check(str(f, "original_name").toLowerCase().endsWith(".csv"), 400, "批量导入接受UTF-8 CSV文件");
      files.ownInput(file);
      p.put("input_hash", f.get("file_hash"));
    }
    long id =
        db.insert(
            "async_task",
            map(
                "task_no",
                UUID.randomUUID().toString(),
                "task_type",
                type,
                "creator_id",
                access.uid(),
                "task_params",
                Json.write(p),
                "input_file_id",
                file));
    if (file != null) files.bind(List.of(file), "async_task", id);
    audit.log("TASK_CREATE", "async_task", id, map("type", type));
    return task(id);
  }

  public Object task(long id) {
    var t = db.get("async_task", id);
    check(eq(t.get("creator_id"), access.uid()), 403, "仅可查询本人批量任务");
    access.require("report:export");
    return t;
  }

  @Transactional
  public Object confirm(long id, Map<String, Object> b) {
    access.confirmed(b);
    task(id);
    var t = db.lock("async_task", id);
    var p = Json.object(t.get("task_params"));
    check(
        integer(t, "task_status", 0) == 2
            && str(p, "phase").equals("validated")
            && integer(p, "error_count", -1) == 0,
        409,
        "任务必须先通过全部校验");
    p.put("phase", "import");
    p.put("creator_version", integer(access.user(), "token_version", 0));
    db.update(
        "async_task",
        id,
        map(
            "task_params",
            Json.write(p),
            "task_status",
            0,
            "progress",
            0,
            "start_time",
            null,
            "finish_time",
            null));
    audit.logAs(access.uid(), "IMPORT_CONFIRM", "async_task", id, map(), true);
    return task(id);
  }

  public void process(long id) {
    if (db.exec(
            "UPDATE async_task SET task_status=1,start_time=?,update_time=? WHERE id=? AND"
                + " (task_status=0 OR (task_status=1 AND update_time<?))",
            now(),
            now(),
            id,
            now().minusMinutes(10))
        != 1) return;
    var prior = SecurityContextHolder.getContext().getAuthentication();
    try {
      var task = db.get("async_task", id);
      long uid = num(task.get("creator_id"));
      var user = db.get("user", uid);
      var p = Json.object(task.get("task_params"));
      check(
          integer(user, "user_status", 0) == 1
              && integer(user, "token_version", 0) == integer(p, "creator_version", -1),
          403,
          "发起人授权已变化，请重新建立任务");
      SecurityContextHolder.getContext()
          .setAuthentication(
              new UsernamePasswordAuthenticationToken(
                  new LoginUser(uid, "job", "job"), null, List.of()));
      access.require("report:export");
      tx.executeWithoutResult(s -> execute(id));
    } catch (Exception e) {
      Throwable cause = e;
      while (cause.getCause() != null) cause = cause.getCause();
      org.slf4j.LoggerFactory.getLogger(getClass())
          .error(
              "批量任务 {} 失败：{}，位置 {}",
              id,
              cause.getClass().getSimpleName(),
              java.util.Arrays.stream(cause.getStackTrace()).limit(5).toList());
      db.update(
          "async_task",
          id,
          map(
              "task_status",
              3,
              "error_message",
              e instanceof BizException ? e.getMessage() : "批量处理失败，数据未提交",
              "finish_time",
              now()));
    } finally {
      SecurityContextHolder.getContext().setAuthentication(prior);
    }
  }

  private void execute(long id) {
    var task = db.lock("async_task", id);
    var p = Json.object(task.get("task_params"));
    String type = str(task, "task_type"), phase = str(p, "phase");
    List<Map<String, Object>> result;
    List<String> headers;
    if (type.endsWith("EXPORT")) {
      long org = id(p, "org_id");
      access.org(org, "report:export");
      if (type.equals("USER_EXPORT")) {
        headers =
            List.of("id", "user_name", "real_name", "user_no", "org_id", "class_id", "user_status");
        result =
            db
                .list(
                    "SELECT id,user_name,real_name,user_no,org_id,class_id,user_status FROM `user`"
                        + " ORDER BY id")
                .stream()
                .filter(u -> access.desc(num(u.get("org_id")), org))
                .toList();
      } else if (type.equals("AUDIT_EXPORT")) {
        access.org(org, "audit:read");
        headers =
            List.of(
                "id",
                "operator_id",
                "action_type",
                "biz_type",
                "biz_id",
                "request_id",
                "result_status",
                "confirmed",
                "operate_time");
        result =
            db
                .list(
                    "SELECT"
                        + " id,operator_id,action_type,biz_type,biz_id,request_id,result_status,confirmed,operate_time"
                        + " FROM audit_log ORDER BY id")
                .stream()
                .filter(
                    r ->
                        r.get("operator_id") == null
                            ? integer(db.get("org_unit", org), "org_type", 0) == 1
                            : access.desc(
                                    num(db.get("user", num(r.get("operator_id"))).get("org_id")),
                                    org)
                                && access.canStudent(
                                    access.uid(), num(r.get("operator_id")), "audit:read"))
                .toList();
      } else {
        headers =
            List.of(
                "id", "student_id", "course_name", "class_name", "enroll_status", "enroll_time");
        result =
            db
                .list(
                    "SELECT"
                        + " e.id,e.student_id,c.course_name,tc.class_name,e.enroll_status,e.enroll_time,u.org_id"
                        + " FROM enrollment e JOIN teaching_class tc ON tc.id=e.teaching_class_id"
                        + " JOIN course c ON c.id=tc.course_id JOIN `user` u ON u.id=e.student_id"
                        + " ORDER BY e.id")
                .stream()
                .filter(u -> access.desc(num(u.get("org_id")), org))
                .toList();
      }
    } else {
      var file = db.get("file_upload", num(task.get("input_file_id")));
      check(eq(file.get("file_hash"), p.get("input_hash")), 409, "输入文件已变化");
      var rows =
          Csv.parse(
              new String(
                  files.ownInput(num(task.get("input_file_id"))),
                  java.nio.charset.StandardCharsets.UTF_8));
      check(!rows.isEmpty(), 400, "导入没有数据行");
      result = new ArrayList<>();
      Set<String> names = new HashSet<>(), numbers = new HashSet<>();
      Set<Long> enrollmentIds = new HashSet<>();
      int line = 1;
      List<Map<String, Object>> gradeItems = new ArrayList<>();
      for (var row : rows) {
        line++;
        String error = "";
        try {
          if (type.equals("USER_IMPORT")) {
            keys(
                row,
                "user_name",
                "real_name",
                "user_no",
                "password",
                "org_id",
                "class_id",
                "gender",
                "email");
            access.org(id(p, "org_id"), "report:export");
            check(access.desc(id(row, "org_id"), id(p, "org_id")), 403, "导入组织超出任务范围");
            check(names.add(str(row, "user_name")), 400, "文件内重复账号");
            if (row.get("user_no") != null) check(numbers.add(str(row, "user_no")), 400, "文件内重复学号");
            admin.validateNewUser(row);
          } else {
            keys(row, "enrollment_id", "usual_score", "final_score", "exam_flag", "version");
            var tc = access.courseClass(id(p, "course_id"), p, true);
            var en = db.get("enrollment", id(row, "enrollment_id"));
            check(
                eq(en.get("teaching_class_id"), tc.get("id"))
                    && integer(en, "enroll_status", 0) == 1,
                400,
                "选课不属于本教学班有效选课");
            check(enrollmentIds.add(num(en.get("id"))), 400, "文件内重复成绩");
            check(
                integer(db.get("semester", num(tc.get("semester_id"))), "is_locked", 0) == 0,
                409,
                "学期已锁定");
            var existing = db.one("SELECT * FROM grade WHERE enrollment_id=?", en.get("id"));
            if (existing != null) {
              check(
                  Set.of(0, 2).contains(integer(existing, "grade_status", 0)), 409, "待审或发布成绩不可导入");
              check(integer(existing, "version", 0) == integer(row, "version", -1), 409, "成绩版本已变化");
            }
            GradeService.calculate(row, tc, false);
            gradeItems.add(row);
          }
        } catch (BizException e) {
          error = e.getMessage();
        }
        result.add(map("row_no", line, "result", error.isEmpty() ? "校验通过" : "失败", "error", error));
      }
      long errors = result.stream().filter(r -> !str(r, "error").isEmpty()).count();
      if (phase.equals("import")) {
        check(errors == 0, 409, "重新校验未通过，未写入数据");
        if (type.equals("USER_IMPORT"))
          for (var row : rows) {
            row.put("confirmed", true);
            admin.createUser(row);
          }
        else
          grades.save(
              id(p, "course_id"),
              map("teaching_class_id", id(p, "teaching_class_id"), "items", gradeItems));
        p.put("phase", "imported");
      } else p.put("phase", "validated");
      p.put("error_count", errors);
      headers = List.of("row_no", "result", "error");
    }
    check(result.size() <= 20000, 409, "导出范围超过20000行，请缩小组织范围或分批导出");
    byte[] bytes = Csv.encode(headers, result);
    long file =
        files.saveGenerated(
            "批量任务结果-" + id + ".csv", "text/csv", bytes, "async_task", id, access.uid());
    db.update(
        "async_task",
        id,
        map(
            "task_status",
            2,
            "progress",
            100,
            "result_file_id",
            file,
            "task_params",
            Json.write(p),
            "finish_time",
            now(),
            "error_message",
            null));
    audit.log(
        "TASK_COMPLETE", "async_task", id, map("phase", p.get("phase"), "rows", result.size()));
  }
}
