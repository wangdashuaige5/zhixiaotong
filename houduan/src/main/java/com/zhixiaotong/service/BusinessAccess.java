package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Access;
import java.util.*;
import org.springframework.stereotype.Service;

/** 文件、消息和接续读取时重新检查原业务，旧推送不携带永久授权。 */
@Service
public class BusinessAccess {
  private final Db db;
  private final Access access;

  public BusinessAccess(Db db, Access access) {
    this.db = db;
    this.access = access;
  }

  public boolean noticeVisible(Map<String, Object> n, long uid) {
    if (integer(n, "publish_status", 0) != 1
        || time(n.get("start_time")).isAfter(now())
        || (n.get("expire_time") != null && !time(n.get("expire_time")).isAfter(now())))
      return false;
    var u = db.get("user", uid);
    for (var s : db.list("SELECT * FROM notice_scope WHERE notice_id=?", n.get("id"))) {
      int type = integer(s, "scope_type", 0);
      if (type == 1) return true;
      if (type == 2
          && (eq(s.get("org_id"), u.get("org_id"))
              || (integer(s, "include_children", 0) == 1
                  && access.desc(num(u.get("org_id")), num(s.get("org_id")))))) return true;
      if (type == 3 && eq(s.get("class_id"), u.get("class_id"))) return true;
      if (type == 4
          && (db.count(
                      "SELECT COUNT(*) FROM enrollment WHERE student_id=? AND teaching_class_id=?"
                          + " AND enroll_status=1",
                      uid,
                      s.get("teaching_class_id"))
                  > 0
              || db.count(
                      "SELECT COUNT(*) FROM teaching_class WHERE id=? AND teacher_id=?",
                      s.get("teaching_class_id"),
                      uid)
                  > 0)) return true;
    }
    return false;
  }

  public void checkRead(String type, long id) {
    switch (type) {
      case "avatar" -> check(id == access.uid(), 403, "无权读取头像附件");
      case "teaching_class" -> access.teaching(id, false);
      case "course_resource" -> {
        var r = db.get(type, id);
        var tc = access.teaching(num(r.get("teaching_class_id")), false);
        check(
            integer(r, "publish_status", 0) == 1
                && (integer(r, "visible_scope", 1) == 1
                    || eq(tc.get("teacher_id"), access.uid())
                    || access.has("admin:read")),
            403,
            "资料不可见");
      }
      case "assignment" -> {
        var a = db.get(type, id);
        var tc = access.teaching(num(a.get("teaching_class_id")), false);
        check(
            integer(a, "publish_status", 0) == 1 || eq(tc.get("teacher_id"), access.uid()),
            403,
            "作业尚未发布");
      }
      case "submission" -> {
        var sub = db.get(type, id);
        if (!eq(sub.get("student_id"), access.uid())) {
          var a = db.get("assignment", num(sub.get("assignment_id")));
          access.teaching(num(a.get("teaching_class_id")), true);
        }
      }
      case "leave_request" -> {
        var l = db.get(type, id);
        check(
            eq(l.get("student_id"), access.uid())
                || access.canStudent(access.uid(), num(l.get("student_id")), "leave:counselor")
                || access.canStudent(access.uid(), num(l.get("student_id")), "leave:dean"),
            403,
            "无权读取请假材料");
      }
      case "aid_application" -> {
        var a = db.get(type, id);
        check(
            eq(a.get("student_id"), access.uid())
                || access.canStudent(access.uid(), num(a.get("student_id")), "aid:review"),
            403,
            "无权读取资助材料");
      }
      case "service_application" -> {
        var a = db.get(type, id);
        check(
            eq(a.get("student_id"), access.uid())
                || access.canStudent(access.uid(), num(a.get("student_id")), "affairs:handle"),
            403,
            "无权读取办事材料");
      }
      case "notice" -> check(noticeVisible(db.get(type, id), access.uid()), 403, "通知已失效或超出范围");
      case "async_task" -> {
        var t = db.get(type, id);
        check(eq(t.get("creator_id"), access.uid()), 403, "仅任务发起人可下载");
        access.require("report:export");
        var p = Json.object(t.get("task_params"));
        if (p.containsKey("org_id")) access.org(id(p, "org_id"), "report:export");
        if (str(t, "task_type").equals("AUDIT_EXPORT")) access.org(id(p, "org_id"), "audit:read");
        if (str(t, "task_type").equals("GRADE_IMPORT")) {
          access.courseClass(id(p, "course_id"), p, true);
          access.require("grade:write");
        }
      }
      case "grade" -> {
        var g = db.get(type, id);
        var e = db.get("enrollment", num(g.get("enrollment_id")));
        check(
            integer(g, "grade_status", 0) == 3 && eq(e.get("student_id"), access.uid()),
            403,
            "无权读取成绩");
      }
      case "enrollment" ->
          check(eq(db.get(type, id).get("student_id"), access.uid()), 403, "无权读取选课");
      case "attendance_task" -> {
        var a = db.get(type, id);
        var t = db.get("timetable", num(a.get("timetable_id")));
        access.teaching(num(t.get("teaching_class_id")), false);
      }
      case "recharge_order" -> {
        var r = db.get(type, id);
        check(
            eq(db.get("card_account", num(r.get("account_id"))).get("user_id"), access.uid()),
            403,
            "无权读取充值订单");
      }
      case "book_reservation" ->
          check(eq(db.get(type, id).get("reader_id"), access.uid()), 403, "无权读取预约信息");
      default -> throw new BizException(403, "不支持的业务授权类型");
    }
  }
}
