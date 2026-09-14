package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Access;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TeachingService {
  private final Db db;
  private final Access access;
  private final FileService files;
  private final AuditService audit;
  private final ScheduleValidator schedule;

  public TeachingService(
      Db db, Access access, FileService files, AuditService audit, ScheduleValidator schedule) {
    this.db = db;
    this.access = access;
    this.files = files;
    this.audit = audit;
    this.schedule = schedule;
  }

  public Object timetables(Map<String, Object> q) {
    access.require("teaching:read");
    var sem =
        q.containsKey("semester_id")
            ? db.get("semester", id(q, "semester_id"))
            : db.one("SELECT * FROM semester WHERE is_current=1");
    check(sem != null, 409, "尚未配置当前学期");
    int week = integer(q, "week_no", schedule.week(sem, now().toLocalDate()));
    range(week, 1, integer(sem, "week_count", 0), "week_no");
    return db
        .list(
            "SELECT t.*,tc.class_name,tc.course_id,c.course_name,r.room_name,u.real_name AS"
                + " teacher_name FROM timetable t JOIN teaching_class tc ON"
                + " tc.id=t.teaching_class_id JOIN course c ON c.id=tc.course_id JOIN classroom r"
                + " ON r.id=t.classroom_id JOIN `user` u ON u.id=tc.teacher_id WHERE"
                + " tc.semester_id=? AND (tc.teacher_id=? OR EXISTS(SELECT 1 FROM enrollment e"
                + " WHERE e.teaching_class_id=tc.id AND e.student_id=? AND e.enroll_status=1))"
                + " ORDER BY t.week_day,t.start_time",
            sem.get("id"),
            access.uid(),
            access.uid())
        .stream()
        .filter(t -> ScheduleValidator.active(t, week, integer(t, "week_day", 1)))
        .toList();
  }

  /** 教师仅查看影响本教学班的出勤摘要，不提供请假原因、病情或证明材料。 */
  public Object leaves(long course, Map<String, Object> q) {
    var tc = access.courseClass(course, q, true);
    long id = num(tc.get("id"));
    return db
        .list(
            "SELECT l.id,l.student_id,u.real_name,l.start_time,l.end_time,l.leave_status FROM"
                + " leave_request l JOIN `user` u ON u.id=l.student_id JOIN enrollment e ON"
                + " e.student_id=l.student_id WHERE e.teaching_class_id=? AND e.enroll_status=1 AND"
                + " l.leave_status IN (1,2,3,7) ORDER BY l.id DESC",
            id)
        .stream()
        .filter(l -> schedule.affected(id, l))
        .toList();
  }

  public Object course(long id, Map<String, Object> q) {
    access.require("teaching:read");
    var c = db.get("course", id);
    check(integer(c, "is_enabled", 0) == 1, 404, "课程未开放");
    if (q.containsKey("teaching_class_id")) {
      var tc = access.courseClass(id, q, false);
      c.put("teaching_class", tc);
      c.put(
          "timetables",
          db.list(
              "SELECT t.*,r.room_name FROM timetable t JOIN classroom r ON r.id=t.classroom_id"
                  + " WHERE t.teaching_class_id=?",
              tc.get("id")));
    }
    return c;
  }

  public Object exams(Map<String, Object> q) {
    access.require("teaching:read");
    String sql =
        "SELECT x.*,c.course_name,r.room_name FROM exam_plan x JOIN teaching_class tc ON"
            + " tc.id=x.teaching_class_id JOIN course c ON c.id=tc.course_id JOIN classroom r ON"
            + " r.id=x.classroom_id WHERE x.plan_status=1 AND (x.invigilator_id=? OR"
            + " x.assistant_id=? OR EXISTS(SELECT 1 FROM enrollment e WHERE"
            + " e.teaching_class_id=tc.id AND e.student_id=? AND e.enroll_status=1))";
    return db.page(
        sql
            + (q.containsKey("semester_id") ? " AND tc.semester_id=?" : "")
            + " ORDER BY x.start_time",
        q,
        q.containsKey("semester_id")
            ? new Object[] {access.uid(), access.uid(), access.uid(), id(q, "semester_id")}
            : new Object[] {access.uid(), access.uid(), access.uid()});
  }

  @Transactional
  public Object evaluation(long enrollment, Map<String, Object> b) {
    access.student();
    access.require("teaching:read");
    var e = db.lock("enrollment", enrollment);
    check(
        eq(e.get("student_id"), access.uid()) && integer(e, "enroll_status", 0) == 1,
        403,
        "只有本人有效选课可以评价");
    var tc = db.get("teaching_class", num(e.get("teaching_class_id")));
    var sem = db.get("semester", num(tc.get("semester_id")));
    var end = date(sem.get("end_date"));
    check(
        !now().toLocalDate().isBefore(end.minusDays(14))
            && !now().toLocalDate().isAfter(end.plusDays(14)),
        409,
        "当前不在学期末评价窗口");
    var score = dec(b, "total_score");
    check(
        score.signum() >= 0 && score.compareTo(new java.math.BigDecimal("100")) <= 0,
        400,
        "评价分数应为0至100");
    check(b.get("item_scores") instanceof Map<?, ?>, 400, "item_scores必须是对象");
    long id =
        db.insert(
            "teaching_evaluation",
            map(
                "enrollment_id",
                enrollment,
                "total_score",
                score,
                "item_scores",
                Json.write(b.get("item_scores")),
                "comment",
                optional(b, "comment", 4000),
                "is_anonymous",
                1,
                "submit_time",
                now()));
    audit.log("EVALUATE", "teaching_evaluation", id, map());
    return map("id", id);
  }

  public Object resources(long course, Map<String, Object> q) {
    var tc = access.courseClass(course, q, false);
    return db.list(
        "SELECT * FROM course_resource WHERE teaching_class_id=? AND publish_status=1 AND"
            + " (visible_scope=1 OR uploader_id=?) ORDER BY sort_order,id",
        tc.get("id"),
        access.uid());
  }

  @Transactional
  public Object resource(long course, Map<String, Object> b) {
    var tc = access.courseClass(course, b, true);
    long file = id(b, "file_id");
    var v =
        map(
            "teaching_class_id",
            tc.get("id"),
            "resource_title",
            text(b, "resource_title", 128),
            "file_id",
            file,
            "uploader_id",
            access.uid(),
            "visible_scope",
            integer(b, "visible_scope", 1),
            "publish_status",
            1);
    range(integer(v, "visible_scope", 1), 1, 2, "visible_scope");
    long id = db.insert("course_resource", v);
    files.bind(List.of(file), "course_resource", id);
    audit.log("RESOURCE_CREATE", "course_resource", id, map());
    return db.get("course_resource", id);
  }

  @Transactional
  public Object assignment(long course, Map<String, Object> b) {
    var tc = access.courseClass(course, b, true);
    var deadline = time(b.get("deadline"));
    check(deadline.isAfter(now()), 400, "截止时间必须在当前时间之后");
    var max = b.containsKey("max_score") ? dec(b, "max_score") : new java.math.BigDecimal("100");
    check(max.signum() > 0 && max.compareTo(new java.math.BigDecimal("9999")) <= 0, 400, "作业满分不合法");
    int state = integer(b, "publish_status", 1);
    range(state, 0, 1, "publish_status");
    long id =
        db.insert(
            "assignment",
            map(
                "teaching_class_id",
                tc.get("id"),
                "teacher_id",
                access.uid(),
                "assignment_title",
                text(b, "assignment_title", 128),
                "content",
                text(b, "content", 30000),
                "grading_rule",
                optional(b, "grading_rule", 10000),
                "max_score",
                max,
                "deadline",
                deadline,
                "allow_late",
                integer(b, "allow_late", 0),
                "publish_status",
                state));
    files.bind(ids(b, "file_ids"), "assignment", id);
    audit.log("ASSIGNMENT_CREATE", "assignment", id, map());
    return db.get("assignment", id);
  }

  public Object assignments(long course, Map<String, Object> q) {
    var tc = access.courseClass(course, q, false);
    return db.list(
        "SELECT a.* FROM assignment a WHERE a.teaching_class_id=? AND (a.publish_status=1 OR"
            + " a.teacher_id=?) ORDER BY a.id DESC",
        tc.get("id"),
        access.uid());
  }

  @Transactional
  public Object submit(long assignment, Map<String, Object> b) {
    access.student();
    var a = db.lock("assignment", assignment);
    access.teaching(num(a.get("teaching_class_id")), false);
    check(integer(a, "publish_status", 0) == 1, 409, "作业未发布或已关闭");
    check(
        integer(a, "allow_late", 0) == 1 || !now().isAfter(time(a.get("deadline"))),
        409,
        "已过作业截止时间");
    String content = optional(b, "content", 30000);
    List<Long> fs = ids(b, "file_ids");
    check(content != null || !fs.isEmpty(), 400, "文本和附件至少提供一项");
    var previous =
        db.one(
            "SELECT * FROM submission WHERE assignment_id=? AND student_id=? ORDER BY submit_round"
                + " DESC LIMIT 1",
            assignment,
            access.uid());
    check(previous == null || integer(previous, "submit_status", 0) == 1, 409, "已提交作业；退回后才可新增提交轮次");
    int round = previous == null ? 1 : integer(previous, "submit_round", 1) + 1;
    long id =
        db.insert(
            "submission",
            map(
                "assignment_id",
                assignment,
                "student_id",
                access.uid(),
                "submit_round",
                round,
                "content",
                content,
                "submit_time",
                now()));
    files.bind(fs, "submission", id);
    audit.log("ASSIGNMENT_SUBMIT", "submission", id, map("round", round));
    return db.get("submission", id);
  }

  @Transactional
  public Object grade(long id, Map<String, Object> b) {
    var sub = db.get("submission", id);
    var a = db.get("assignment", num(sub.get("assignment_id")));
    access.teaching(num(a.get("teaching_class_id")), true);
    sub = db.lock("submission", id);
    String action = text(b, "action", 16);
    int current = integer(sub, "submit_status", 0);
    var v =
        map(
            "feedback",
            optional(b, "feedback", 10000),
            "grader_id",
            access.uid(),
            "grade_time",
            now());
    switch (action) {
      case "return" -> {
        check(current == 0 || current == 2, 409, "当前提交不可退回");
        v.put("submit_status", 1);
        v.put("feedback", text(b, "feedback", 10000));
      }
      case "grade" -> {
        check(current == 0 || current == 2, 409, "当前提交不可评分");
        var score = dec(b, "score");
        check(score.signum() >= 0 && score.compareTo(dec(a, "max_score")) <= 0, 400, "得分超出作业满分");
        v.put("score", score);
        v.put("submit_status", 2);
      }
      case "publish" -> {
        check(current == 2 && sub.get("score") != null, 409, "先批改再发布");
        v.put("submit_status", 3);
      }
      default -> throw new BizException(400, "action应为grade、return或publish");
    }
    db.update("submission", id, v);
    audit.log(
        "SUBMISSION_" + action.toUpperCase(),
        "submission",
        id,
        map("status", v.get("submit_status")));
    audit.event("submission", id, "作业处理状态已更新", List.of(num(sub.get("student_id"))));
    return db.get("submission", id);
  }

  public Object submissions(long assignment) {
    var a = db.get("assignment", assignment);
    var tc = access.teaching(num(a.get("teaching_class_id")), false);
    boolean teacher = eq(tc.get("teacher_id"), access.uid()) || access.has("admin:read");
    if (teacher) access.teaching(num(tc.get("id")), true);
    var list =
        db.list(
            "SELECT * FROM submission WHERE assignment_id=?"
                + (teacher ? "" : " AND student_id=?")
                + " ORDER BY student_id,submit_round DESC",
            teacher ? new Object[] {assignment} : new Object[] {assignment, access.uid()});
    if (!teacher)
      for (var row : list)
        if (integer(row, "submit_status", 0) != 3) {
          row.remove("score");
          row.remove("grade_time");
        }
    return list;
  }
}
