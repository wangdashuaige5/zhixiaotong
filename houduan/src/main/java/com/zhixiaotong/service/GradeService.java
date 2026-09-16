package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Access;
import java.math.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GradeService {
  private final Db db;
  private final Access access;
  private final AuditService audit;

  public GradeService(Db db, Access access, AuditService audit) {
    this.db = db;
    this.access = access;
    this.audit = audit;
  }

  public static Map<String, Object> calculate(
      Map<String, Object> item, Map<String, Object> tc, boolean publishing) {
    int flag = integer(item, "exam_flag", 0);
    range(flag, 0, 3, "exam_flag");
    BigDecimal u = item.get("usual_score") == null ? null : dec(item, "usual_score"),
        f = item.get("final_score") == null ? null : dec(item, "final_score");
    for (BigDecimal n : Arrays.asList(u, f))
      if (n != null)
        check(n.signum() >= 0 && n.compareTo(new BigDecimal("100")) <= 0, 400, "成绩范围为0至100");
    BigDecimal uw = dec(tc, "usual_weight"), fw = dec(tc, "final_weight");
    check(uw.add(fw).compareTo(BigDecimal.ONE) == 0, 409, "成绩权重之和必须为1");
    if (publishing) {
      check(flag != 2 && flag != 3, 409, "缓考或免修需学校专项规则，当前不能直接发布");
      check(u != null && (flag == 1 || f != null), 400, "正常成绩分项不完整");
    }
    if (flag == 1) f = BigDecimal.ZERO;
    BigDecimal total =
        u == null || f == null
            ? null
            : u.multiply(uw).add(f.multiply(fw)).setScale(2, RoundingMode.HALF_UP);
    BigDecimal point =
        total == null
            ? null
            : total.compareTo(new BigDecimal("60")) < 0
                ? BigDecimal.ZERO
                : total
                    .subtract(new BigDecimal("50"))
                    .divide(BigDecimal.TEN, 2, RoundingMode.HALF_UP)
                    .min(new BigDecimal("4.00"));
    return map(
        "usual_score",
        u,
        "final_score",
        f,
        "total_score",
        total,
        "grade_point",
        point,
        "exam_flag",
        flag);
  }

  private void unlocked(Map<String, Object> tc) {
    check(
        integer(db.get("semester", num(tc.get("semester_id"))), "is_locked", 0) == 0, 409, "学期已锁定");
  }

  @Transactional
  public Object save(long course, Map<String, Object> b) {
    var tc = access.courseClass(course, b, true);
    access.require("grade:write");
    db.lock("teaching_class", num(tc.get("id")));
    unlocked(tc);
    List<Map<String, Object>> items = rows(b, "items");
    check(!items.isEmpty(), 400, "成绩列表不能为空");
    Set<Long> seen = new HashSet<>();
    List<Object> out = new ArrayList<>();
    for (var item : items) {
      long en = id(item, "enrollment_id");
      check(seen.add(en), 400, "成绩列表存在重复学生");
      var e = db.get("enrollment", en);
      check(
          eq(e.get("teaching_class_id"), tc.get("id")) && integer(e, "enroll_status", 0) == 1,
          400,
          "学生不属于该教学班有效选课");
      var g = db.one("SELECT * FROM grade WHERE enrollment_id=? FOR UPDATE", en);
      if (g != null) {
        check(Set.of(0, 2).contains(integer(g, "grade_status", 0)), 409, "待审或已发布成绩不可直接编辑");
        check(integer(item, "version", -1) == integer(g, "version", 0), 409, "成绩版本已变化");
      }
      var v = calculate(item, tc, false);
      v.putAll(
          map(
              "enrollment_id",
              en,
              "operator_id",
              access.uid(),
              "grade_status",
              0,
              "version",
              g == null ? 0 : integer(g, "version", 0) + 1));
      long id = g == null ? db.insert("grade", v) : num(g.get("id"));
      if (g != null) db.update("grade", id, v);
      out.add(db.get("grade", id));
    }
    audit.log("GRADE_SAVE", "teaching_class", num(tc.get("id")), map("count", items.size()));
    return out;
  }

  @Transactional
  public Object submit(long course, Map<String, Object> b) {
    var tc = access.courseClass(course, b, true);
    access.require("grade:write");
    long tid = num(tc.get("id"));
    db.lock("teaching_class", tid);
    unlocked(tc);
    check(
        db.count(
                "SELECT COUNT(*) FROM grade_review WHERE teaching_class_id=? AND review_status=0",
                tid)
            == 0,
        409,
        "存在待审核批次");
    var grades =
        db.list(
            "SELECT g.* FROM grade g JOIN enrollment e ON g.enrollment_id=e.id WHERE"
                + " e.teaching_class_id=? AND e.enroll_status=1 AND g.grade_status IN (0,2) ORDER"
                + " BY g.id",
            tid);
    check(!grades.isEmpty(), 400, "没有待提交成绩");
    for (var g : grades) calculate(g, tc, true);
    int round =
        (int)
                db.count(
                    "SELECT COALESCE(MAX(review_round),0) FROM grade_review WHERE"
                        + " teaching_class_id=?",
                    tid)
            + 1;
    List<Map<String, Object>> snapshot = new ArrayList<>();
    for (var g : grades) {
      db.update(
          "grade",
          num(g.get("id")),
          map("grade_status", 1, "version", integer(g, "version", 0) + 1));
      snapshot.add(
          pick(
              db.get("grade", num(g.get("id"))),
              "id",
              "version",
              "usual_score",
              "final_score",
              "total_score",
              "exam_flag"));
    }
    long id =
        db.insert(
            "grade_review",
            map(
                "teaching_class_id",
                tid,
                "review_round",
                round,
                "submitter_id",
                access.uid(),
                "submit_time",
                now(),
                "grade_snapshot",
                Json.write(snapshot),
                "warning_note",
                distribution(grades)));
    for (var g : grades) db.update("grade", num(g.get("id")), map("review_id", id));
    audit.log("GRADE_SUBMIT", "grade_review", id, map("count", grades.size()));
    return db.get("grade_review", id);
  }

  private String distribution(List<Map<String, Object>> g) {
    long fail =
        g.stream()
            .filter(
                x ->
                    x.get("total_score") != null
                        && dec(x, "total_score").compareTo(new BigDecimal("60")) < 0)
            .count();
    return fail * 2 > g.size() ? "不及格比例超过50%，请审核分布与评分规则" : "未发现不及格比例异常";
  }

  private Map<String, Object> reviewScope(long tid) {
    var tc = db.get("teaching_class", tid);
    var c = db.get("course", num(tc.get("course_id")));
    access.org(num(c.get("org_id")), "grade:review");
    return tc;
  }

  @Transactional
  public Object review(long id, Map<String, Object> b) {
    var initial = db.get("grade_review", id);
    long tid = num(initial.get("teaching_class_id"));
    var tc = reviewScope(tid);
    db.lock("teaching_class", tid);
    unlocked(tc);
    var r = db.lock("grade_review", id);
    check(!eq(r.get("submitter_id"), access.uid()), 403, "不能审核本人提交的成绩");
    check(integer(r, "review_status", 0) == 0, 409, "审核已处理");
    int d = integer(b, "decision", 0);
    range(d, 1, 2, "decision");
    String comment = d == 1 ? optional(b, "review_comment", 255) : text(b, "review_comment", 255);
    var snapshot = Json.list(r.get("grade_snapshot"));
    for (var item : snapshot) {
      var g = db.lock("grade", id(item, "id"));
      check(
          integer(g, "grade_status", 0) == 1
              && eq(g.get("review_id"), id)
              && integer(g, "version", 0) == integer(item, "version", -1),
          409,
          "审核快照已失效");
      for (String field : List.of("usual_score", "final_score", "total_score"))
        check(
            Objects.equals(g.get(field), null) == Objects.equals(item.get(field), null)
                && (g.get(field) == null
                    || decimal(g.get(field)).compareTo(decimal(item.get(field))) == 0),
            409,
            "成绩内容与快照不一致");
      db.update(
          "grade",
          num(g.get("id")),
          map(
              "grade_status",
              d == 1 ? 3 : 2,
              "publish_time",
              d == 1 ? now() : null,
              "version",
              integer(g, "version", 0) + 1));
      var e = db.get("enrollment", num(g.get("enrollment_id")));
      audit.event("grade", num(g.get("id")), "成绩审核结果已更新", List.of(num(e.get("student_id"))));
    }
    db.update(
        "grade_review",
        id,
        map(
            "reviewer_id",
            access.uid(),
            "review_status",
            d,
            "review_comment",
            comment,
            "review_time",
            now()));
    audit.log("GRADE_REVIEW", "grade_review", id, map("decision", d));
    return db.get("grade_review", id);
  }

  public Object mine(Map<String, Object> q) {
    access.student();
    return db.page(
        "SELECT"
            + " g.id,g.enrollment_id,g.usual_score,g.final_score,g.total_score,g.grade_point,g.exam_flag,g.publish_time,c.course_name,c.credit,tc.semester_id"
            + " FROM grade g JOIN enrollment e ON e.id=g.enrollment_id JOIN teaching_class tc ON"
            + " tc.id=e.teaching_class_id JOIN course c ON c.id=tc.course_id WHERE e.student_id=?"
            + " AND g.grade_status=3"
            + (q.containsKey("semester_id") ? " AND tc.semester_id=?" : "")
            + " ORDER BY g.id DESC",
        q,
        q.containsKey("semester_id")
            ? new Object[] {access.uid(), id(q, "semester_id")}
            : new Object[] {access.uid()});
  }

  @Transactional
  public Object change(long id, Map<String, Object> b) {
    var g = db.get("grade", id);
    var e = db.get("enrollment", num(g.get("enrollment_id")));
    var tc = access.teaching(num(e.get("teaching_class_id")), true);
    access.require("grade:write");
    db.lock("teaching_class", num(tc.get("id")));
    g = db.lock("grade", id);
    check(
        integer(g, "grade_status", 0) == 3 && integer(g, "version", 0) == integer(b, "version", -1),
        409,
        "成绩尚未发布或版本已变化");
    check(
        db.count("SELECT COUNT(*) FROM grade_change WHERE grade_id=? AND review_status=0", id) == 0,
        409,
        "已有待审更正");
    var after = calculate(b, tc, true);
    long change =
        db.insert(
            "grade_change",
            map(
                "grade_id",
                id,
                "applicant_id",
                access.uid(),
                "before_value",
                Json.write(
                    pick(
                        g,
                        "version",
                        "usual_score",
                        "final_score",
                        "total_score",
                        "grade_point",
                        "exam_flag")),
                "after_value",
                Json.write(after),
                "change_reason",
                text(b, "change_reason", 255)));
    audit.log("GRADE_CHANGE_APPLY", "grade_change", change, map("grade_id", id));
    return db.get("grade_change", change);
  }

  @Transactional
  public Object decideChange(long id, Map<String, Object> b) {
    var ch = db.get("grade_change", id);
    var g = db.get("grade", num(ch.get("grade_id")));
    var e = db.get("enrollment", num(g.get("enrollment_id")));
    long tid = num(e.get("teaching_class_id"));
    reviewScope(tid);
    db.lock("teaching_class", tid);
    g = db.lock("grade", num(g.get("id")));
    ch = db.lock("grade_change", id);
    check(!eq(ch.get("applicant_id"), access.uid()), 403, "不能审核本人更正");
    check(integer(ch, "review_status", 0) == 0, 409, "申请已处理");
    int decision = integer(b, "decision", 0);
    range(decision, 1, 2, "decision");
    String comment =
        decision == 1 ? optional(b, "review_comment", 255) : text(b, "review_comment", 255);
    if (decision == 1) {
      var before = Json.object(ch.get("before_value"));
      check(integer(g, "version", 0) == integer(before, "version", -1), 409, "原成绩已变化，需要重新申请");
      var after = Json.object(ch.get("after_value"));
      after.put("version", integer(g, "version", 0) + 1);
      after.put("publish_time", now());
      db.update("grade", num(g.get("id")), after);
      audit.event("grade", num(g.get("id")), "成绩更正已生效", List.of(num(e.get("student_id"))));
    }
    db.update(
        "grade_change",
        id,
        map(
            "reviewer_id",
            access.uid(),
            "review_status",
            decision,
            "review_comment",
            comment,
            "review_time",
            now(),
            "apply_time",
            decision == 1 ? now() : null));
    audit.log("GRADE_CHANGE_REVIEW", "grade_change", id, map("decision", decision));
    return db.get("grade_change", id);
  }

  public Object pending() {
    access.require("grade:review");
    return db
        .list(
            "SELECT r.*,c.org_id,c.course_name,tc.class_name,u.real_name AS submitter_name"
                + " FROM grade_review r JOIN teaching_class tc ON"
                + " tc.id=r.teaching_class_id JOIN course c ON c.id=tc.course_id"
                + " JOIN `user` u ON u.id=r.submitter_id WHERE"
                + " r.review_status=0 AND r.submitter_id<>? ORDER BY r.id", access.uid())
        .stream()
        .filter(r -> access.canOrg(access.uid(), num(r.get("org_id")), "grade:review"))
        .map(r -> {
          // 仅为已通过院系范围校验的审核快照补学生姓名，不改变原快照值或审核版本。
          var snapshot = Json.list(r.get("grade_snapshot"));
          for (var item : snapshot) {
            var student = db.one(
                "SELECT u.real_name,u.user_no FROM grade g JOIN enrollment e ON"
                    + " e.id=g.enrollment_id JOIN `user` u ON u.id=e.student_id"
                    + " WHERE g.id=? AND e.teaching_class_id=?",
                item.get("id"), r.get("teaching_class_id"));
            if (student != null) item.putAll(student);
          }
          r.put("grade_snapshot", snapshot);
          return r;
        })
        .toList();
  }

  private static final String CHANGE_SELECT =
      "SELECT ch.*,e.id AS enrollment_id,e.student_id,e.teaching_class_id,tc.class_name,"
          + "tc.course_id,c.course_name,c.org_id,u.real_name AS student_name,u.user_no,"
          + "applicant.real_name AS applicant_name FROM grade_change ch JOIN grade g ON"
          + " g.id=ch.grade_id JOIN enrollment e ON e.id=g.enrollment_id JOIN teaching_class tc"
          + " ON tc.id=e.teaching_class_id JOIN course c ON c.id=tc.course_id JOIN `user` u ON"
          + " u.id=e.student_id JOIN `user` applicant ON applicant.id=ch.applicant_id";

  /** 独立的更正待办，不改变原成绩批次审核列表的结构和含义。 */
  public Object pendingChanges() {
    access.require("grade:review");
    return db.list(CHANGE_SELECT + " WHERE ch.review_status=0 AND ch.applicant_id<>? ORDER BY ch.id",
            access.uid())
        .stream()
        .filter(ch -> access.canOrg(access.uid(), num(ch.get("org_id")), "grade:review"))
        .toList();
  }

  /** 更正内容只对仍有成绩写权限的申请者本人、以及该院系授权审核人可见。 */
  public Object changeDetail(long id) {
    access.current();
    var ch = db.one(CHANGE_SELECT + " WHERE ch.id=?", id);
    check(ch != null, 404, "更正申请不存在");
    check((eq(ch.get("applicant_id"), access.uid()) && access.has("grade:write"))
            || access.canOrg(access.uid(), num(ch.get("org_id")), "grade:review"),
        403, "无权查看此成绩更正");
    return ch;
  }

  public Object classGrades(long course, Map<String, Object> q) {
    var tc = access.courseClass(course, q, true);
    access.require("grade:write");
    return db.list(
        // 显式列出成绩字段，避免空的 g.enrollment_id 与名册 e.id 同名导致首次录入丢失ID。
        "SELECT e.id AS enrollment_id,u.real_name,u.user_no,g.id,g.review_id,g.usual_score,"
            + "g.final_score,g.total_score,g.grade_point,g.exam_flag,g.grade_status,g.operator_id,"
            + "g.publish_time,g.version,g.create_time,g.update_time FROM enrollment e JOIN `user` u ON"
            + " u.id=e.student_id LEFT JOIN grade g ON g.enrollment_id=e.id WHERE"
            + " e.teaching_class_id=? AND e.enroll_status=1 ORDER BY e.id",
        tc.get("id"));
  }
}
