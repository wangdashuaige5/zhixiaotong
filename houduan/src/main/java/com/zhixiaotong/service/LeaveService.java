package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Access;
import java.math.*;
import java.time.Duration;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LeaveService {
  private final Db db;
  private final Access access;
  private final AuditService audit;
  private final FileService files;
  private final ScheduleValidator schedule;

  public LeaveService(
      Db db, Access access, AuditService audit, FileService files, ScheduleValidator schedule) {
    this.db = db;
    this.access = access;
    this.audit = audit;
    this.files = files;
    this.schedule = schedule;
  }

  public static BigDecimal days(Object start, Object end) {
    long seconds = Duration.between(time(start), time(end)).getSeconds();
    check(seconds > 0, 400, "结束时间必须晚于开始时间");
    return BigDecimal.valueOf(seconds).divide(BigDecimal.valueOf(86400), 2, RoundingMode.CEILING);
  }

  private Map<String, Object> values(Map<String, Object> b) {
    var start = time(b.get("start_time"));
    var end = time(b.get("end_time"));
    BigDecimal n = days(start, end);
    check(n.compareTo(new BigDecimal("365")) <= 0, 400, "请假不能超过365天");
    return map(
        "leave_type",
        text(b, "leave_type", 32),
        "start_time",
        start,
        "end_time",
        end,
        "leave_days",
        n,
        "leave_reason",
        text(b, "leave_reason", 10000));
  }

  private void node(long leave, int round, int order, int type, long actor) {
    db.insert(
        "leave_approval",
        map(
            "leave_id",
            leave,
            "apply_round",
            round,
            "node_order",
            order,
            "node_type",
            type,
            "approver_id",
            actor));
  }

  private void submitNodes(long leave, int round, BigDecimal duration) {
    long counselor = access.approver(access.uid(), "leave:counselor");
    if (duration.compareTo(new BigDecimal("3")) > 0) access.approver(access.uid(), "leave:dean");
    node(leave, round, 1, 1, counselor);
    audit.event("leave_request", leave, "有新的请假审批待办", List.of(counselor));
  }

  @Transactional
  public Map<String, Object> create(Map<String, Object> b) {
    access.student();
    access.require("leave:write");
    check(access.user().get("class_id") != null, 409, "学生尚未关联班级");
    var v = values(b);
    boolean submit = !str(b, "action").equals("draft");
    v.putAll(
        map(
            "student_id",
            access.uid(),
            "leave_status",
            submit ? 1 : 0,
            "submit_time",
            submit ? now() : null));
    long id = db.insert("leave_request", v);
    if (submit) submitNodes(id, 1, dec(v, "leave_days"));
    files.bind(ids(b, "file_ids"), "leave_request", id);
    audit.log("LEAVE_CREATE", "leave_request", id, map("status", submit ? 1 : 0));
    if (submit) notifyTeachers(db.get("leave_request", id));
    return detail(id);
  }

  @Transactional
  public Map<String, Object> edit(long id, Map<String, Object> b) {
    access.student();
    access.require("leave:write");
    var l = db.lock("leave_request", id);
    check(eq(l.get("student_id"), access.uid()), 403, "仅可修改本人申请");
    int state = integer(l, "leave_status", 0);
    check(state == 0 || state == 5, 409, "当前状态不可修改");
    var v = values(b);
    boolean submit = !str(b, "action").equals("draft");
    int round = integer(l, "apply_round", 1) + (state == 5 && submit ? 1 : 0);
    v.putAll(
        map(
            "leave_status",
            submit ? 1 : state,
            "apply_round",
            round,
            "submit_time",
            submit ? now() : l.get("submit_time")));
    if (submit) submitNodes(id, round, dec(v, "leave_days"));
    db.update("leave_request", id, v);
    files.bind(ids(b, "file_ids"), "leave_request", id);
    audit.log("LEAVE_RESUBMIT", "leave_request", id, map("round", round));
    if (submit) notifyTeachers(db.get("leave_request", id));
    return detail(id);
  }

  public Map<String, Object> detail(long id) {
    var l = db.get("leave_request", id);
    boolean owner = eq(l.get("student_id"), access.uid());
    boolean reviewer =
        access.canStudent(access.uid(), num(l.get("student_id")), "leave:counselor")
            || access.canStudent(access.uid(), num(l.get("student_id")), "leave:dean");
    check(owner || reviewer, 403, "无权访问请假单");
    l.put(
        "approvals",
        db.list(
            "SELECT * FROM leave_approval WHERE leave_id=? ORDER BY apply_round,node_order", id));
    return l;
  }

  public Object mine(Map<String, Object> q) {
    access.student();
    return db.page(
        "SELECT * FROM leave_request WHERE student_id=? ORDER BY id DESC", q, access.uid());
  }

  public Object pending(Map<String, Object> q) {
    check(access.has("leave:counselor") || access.has("leave:dean"), 403, "没有审批权限");
    var rows =
        db
            .list(
                "SELECT l.*,a.node_order,u.real_name,u.user_no FROM leave_request l"
                    + " JOIN `user` u ON u.id=l.student_id JOIN leave_approval a ON"
                    + " a.leave_id=l.id AND a.apply_round=l.apply_round WHERE a.approver_id=? AND"
                    + " a.decision=0 AND l.leave_status IN (1,2) ORDER BY l.submit_time",
                access.uid())
            .stream()
            .filter(
                l ->
                    access.canStudent(
                        access.uid(),
                        num(l.get("student_id")),
                        integer(l, "leave_status", 0) == 1 ? "leave:counselor" : "leave:dean"))
            .toList();
    return rows;
  }

  @Transactional
  public Map<String, Object> approve(long id, Map<String, Object> b) {
    var l = db.lock("leave_request", id);
    int status = integer(l, "leave_status", 0);
    check(status == 1 || status == 2, 409, "请假单不在审批中");
    String perm = status == 1 ? "leave:counselor" : "leave:dean";
    access.person(num(l.get("student_id")), perm);
    int round = integer(b, "apply_round", 0), order = integer(b, "node_order", 0);
    check(
        round == integer(l, "apply_round", 0) && order == (status == 1 ? 1 : 2), 409, "审批轮次或节点已变化");
    var a =
        db.one(
            "SELECT * FROM leave_approval WHERE leave_id=? AND apply_round=? AND node_order=? FOR"
                + " UPDATE",
            id,
            round,
            order);
    check(a != null && eq(a.get("approver_id"), access.uid()), 403, "不是当前审批人");
    check(integer(a, "decision", 0) == 0, 409, "该节点已处理");
    int decision = integer(b, "decision", 0);
    range(decision, 1, 3, "decision");
    String opinion = decision == 1 ? optional(b, "opinion", 255) : text(b, "opinion", 255);
    db.update(
        "leave_approval",
        num(a.get("id")),
        map("decision", decision, "opinion", opinion, "approve_time", now()));
    int target = decision == 2 ? 4 : decision == 3 ? 5 : 3;
    if (decision == 1 && status == 1 && dec(l, "leave_days").compareTo(new BigDecimal("3")) > 0) {
      target = 2;
      long dean = access.approver(num(l.get("student_id")), "leave:dean");
      node(id, round, 2, 2, dean);
      audit.event("leave_request", id, "有新的院系请假审批", List.of(dean));
    }
    db.update("leave_request", id, map("leave_status", target));
    audit.log(
        "LEAVE_APPROVE", "leave_request", id, map("round", round, "from", status, "to", target));
    audit.event("leave_request", id, "请假状态已更新", List.of(num(l.get("student_id"))));
    notifyTeachers(l);
    return detail(id);
  }

  private void notifyTeachers(Map<String, Object> leave) {
    for (var r :
        db.list(
            "SELECT DISTINCT tc.id,tc.teacher_id FROM teaching_class tc JOIN enrollment e ON"
                + " e.teaching_class_id=tc.id WHERE"
                + " e.student_id=? AND e.enroll_status=1",
            leave.get("student_id")))
      if (schedule.affected(num(r.get("id")), leave))
        audit.event(
            "teaching_class", num(r.get("id")), "授课班级请假出勤信息已更新", List.of(num(r.get("teacher_id"))));
  }

  @Transactional
  public Map<String, Object> withdraw(long id) {
    access.require("leave:write");
    var l = db.lock("leave_request", id);
    check(eq(l.get("student_id"), access.uid()), 403, "仅可撤回本人申请");
    if (integer(l, "leave_status", 0) == 6) return l;
    check(Set.of(1, 2).contains(integer(l, "leave_status", 0)), 409, "当前状态不可撤回");
    db.update("leave_request", id, map("leave_status", 6));
    db.exec(
        "UPDATE leave_approval SET decision=4,approve_time=?,update_time=? WHERE leave_id=? AND"
            + " apply_round=? AND decision=0",
        now(),
        now(),
        id,
        l.get("apply_round"));
    audit.log("LEAVE_WITHDRAW", "leave_request", id, map());
    return db.get("leave_request", id);
  }

  @Transactional
  public Map<String, Object> close(long id) {
    access.require("leave:write");
    var l = db.lock("leave_request", id);
    check(eq(l.get("student_id"), access.uid()), 403, "只能销本人请假");
    if (integer(l, "leave_status", 0) == 7) return l;
    check(integer(l, "leave_status", 0) == 3, 409, "仅已通过的请假可以销假");
    db.update(
        "leave_request",
        id,
        map("leave_status", 7, "close_type", 1, "closer_id", access.uid(), "close_time", now()));
    audit.log("LEAVE_CLOSE", "leave_request", id, map());
    return db.get("leave_request", id);
  }

  @Transactional
  public void autoClose(long id) {
    var l = db.lock("leave_request", id);
    if (integer(l, "leave_status", 0) == 3 && !time(l.get("end_time")).isAfter(now())) {
      db.update(
          "leave_request",
          id,
          map("leave_status", 7, "close_type", 2, "closer_id", null, "close_time", now()));
      audit.logAs(null, "AUTO_CLOSE", "leave_request", id, map(), false);
    }
  }
}
