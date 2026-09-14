package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class HarmonyService {
  private final Db db;
  private final Access access;
  private final BusinessAccess business;
  private final AuditService audit;
  private final TeachingService teaching;
  private final ScheduleValidator schedules;

  public HarmonyService(
      Db db,
      Access access,
      BusinessAccess business,
      AuditService audit,
      TeachingService teaching,
      ScheduleValidator schedules) {
    this.db = db;
    this.access = access;
    this.business = business;
    this.audit = audit;
    this.teaching = teaching;
    this.schedules = schedules;
  }

  @Transactional
  public Object register(Map<String, Object> b) {
    access.require("device:write");
    String code = text(b, "device_code", 128);
    check(code.equals(access.current().deviceCode()), 403, "设备标识须与本次登录会话一致");
    check(
        Crypto.passwordMatches(text(b, "password", 128), str(access.user(), "password_hash")),
        403,
        "设备信任验证失败");
    db.lock("user", access.uid());
    var existing =
        db.one("SELECT * FROM device WHERE user_id=? AND device_code=?", access.uid(), code);
    var v =
        map(
            "user_id",
            access.uid(),
            "device_code",
            code,
            "device_name",
            text(b, "device_name", 64),
            "device_type",
            text(b, "device_type", 32),
            "trust_status",
            1,
            "last_seen_time",
            now());
    long id = existing == null ? db.insert("device", v) : num(existing.get("id"));
    if (existing != null) db.update("device", id, v);
    audit.log("DEVICE_TRUST", "device", id, map());
    return pick(
        db.get("device", id),
        "id",
        "device_code",
        "device_name",
        "device_type",
        "trust_status",
        "last_seen_time");
  }

  private Map<String, Object> ownDevice(long id, boolean current) {
    var d = db.get("device", id);
    check(
        eq(d.get("user_id"), access.uid()) && integer(d, "trust_status", 0) == 1,
        403,
        "设备不属于本人或不可信");
    if (current)
      check(str(d, "device_code").equals(access.current().deviceCode()), 403, "当前会话不属于此设备");
    return d;
  }

  @Transactional
  public Object continuation(Map<String, Object> b) {
    access.require("device:write");
    long source = id(b, "source_device_id"), target = id(b, "target_device_id");
    check(source != target, 400, "源设备和目标设备不能相同");
    ownDevice(source, true);
    ownDevice(target, false);
    String type = text(b, "biz_type", 32);
    check(Set.of("teaching_class", "attendance_task").contains(type), 400, "接续支持课程详情或课堂签到");
    long biz = id(b, "biz_id");
    business.checkRead(type, biz);
    String token = Crypto.random();
    var scope =
        map(
            "page",
            type.equals("teaching_class") ? "course_detail" : "attendance",
            "actions",
            type.equals("teaching_class") ? List.of("read") : List.of("read", "sign"));
    long id =
        db.insert(
            "continuation",
            map(
                "user_id",
                access.uid(),
                "source_device_id",
                source,
                "target_device_id",
                target,
                "biz_type",
                type,
                "biz_id",
                biz,
                "scope_data",
                Json.write(scope),
                "token_hash",
                Crypto.hash(token),
                "expire_time",
                now().plusMinutes(5)));
    audit.log("CONTINUATION_CREATE", "continuation", id, map("source", source, "target", target));
    return map(
        "id",
        id,
        "continuation_token",
        token,
        "expire_time",
        now().plusMinutes(5),
        "scope_data",
        scope);
  }

  @Transactional
  public Object accept(long id, Map<String, Object> b) {
    access.require("device:write");
    var task = db.lock("continuation", id);
    check(eq(task.get("user_id"), access.uid()), 403, "接续不属于本人");
    ownDevice(num(task.get("source_device_id")), false);
    ownDevice(num(task.get("target_device_id")), true);
    check(integer(task, "task_status", 0) == 0, 409, "接续凭证已消费或任务已结束");
    check(time(task.get("expire_time")).isAfter(now()), 409, "接续已过期");
    check(
        Crypto.same(str(task, "token_hash"), Crypto.hash(text(b, "continuation_token", 128))),
        403,
        "接续凭证无效");
    business.checkRead(str(task, "biz_type"), num(task.get("biz_id")));
    db.update("continuation", id, map("task_status", 1, "accept_time", now()));
    audit.log("CONTINUATION_ACCEPT", "continuation", id, map());
    return map(
        "id",
        id,
        "biz_type",
        task.get("biz_type"),
        "biz_id",
        task.get("biz_id"),
        "scope_data",
        Json.read(task.get("scope_data")),
        "task_status",
        1);
  }

  @Transactional
  public Object finish(long id, Map<String, Object> b) {
    access.require("device:write");
    var task = db.lock("continuation", id);
    check(eq(task.get("user_id"), access.uid()), 403, "非本人接续任务");
    String action = text(b, "action", 16);
    int status = integer(task, "task_status", 0);
    if (action.equals("complete")) {
      ownDevice(num(task.get("target_device_id")), true);
      check(status == 1, 409, "只有已接收任务可完成");
      status = 2;
    } else {
      check(action.equals("revoke") && (status == 0 || status == 1), 409, "当前任务不可撤销");
      status = 4;
    }
    db.update("continuation", id, map("task_status", status, "reclaim_time", now()));
    audit.log("CONTINUATION_END", "continuation", id, map("status", status));
    return map("id", id, "task_status", status);
  }

  @Transactional
  public void revokeDevice(long id) {
    var d = ownDevice(id, true);
    db.lock("user", access.uid());
    db.update("device", id, map("trust_status", 2));
    db.exec(
        "UPDATE continuation SET task_status=4,reclaim_time=?,update_time=? WHERE user_id=? AND"
            + " task_status IN (0,1) AND (source_device_id=? OR target_device_id=?)",
        now(),
        now(),
        access.uid(),
        id,
        id);
    db.exec(
        "UPDATE `user` SET token_version=token_version+1,update_time=? WHERE id=?",
        now(),
        access.uid());
    audit.log("DEVICE_REVOKE", "device", id, map());
  }

  @Transactional
  public Object attendance(Map<String, Object> b) {
    long timetable = id(b, "timetable_id");
    var t = db.lock("timetable", timetable);
    var tc = access.teaching(num(t.get("teaching_class_id")), true);
    access.require("attendance:write");
    var date = date(b.get("class_date"));
    var sem = db.get("semester", num(tc.get("semester_id")));
    int week = schedules.week(sem, date);
    check(ScheduleValidator.active(t, week, date.getDayOfWeek().getValue()), 400, "该日期不属于此排课");
    var start = time(b.get("start_time"));
    var end = time(b.get("end_time"));
    check(
        start.toLocalDate().equals(date)
            && end.toLocalDate().equals(date)
            && end.isAfter(start)
            && java.time.Duration.between(start, end).toHours() < 4,
        400,
        "签到时间窗不合法");
    String code = String.format("%06d", new java.security.SecureRandom().nextInt(1000000));
    long id =
        db.insert(
            "attendance_task",
            map(
                "timetable_id",
                timetable,
                "creator_id",
                access.uid(),
                "class_date",
                date,
                "start_time",
                start,
                "end_time",
                end,
                "code_hash",
                Crypto.hash(code),
                "task_status",
                1));
    audit.log("ATTENDANCE_CREATE", "attendance_task", id, map());
    return map("id", id, "sign_code", code, "start_time", start, "end_time", end);
  }

  @Transactional
  public Object sign(long id, Map<String, Object> b) {
    access.student();
    access.require("attendance:sign");
    var task = db.lock("attendance_task", id);
    var t = db.get("timetable", num(task.get("timetable_id")));
    access.teaching(num(t.get("teaching_class_id")), false);
    var prior =
        db.one(
            "SELECT * FROM attendance_record WHERE task_id=? AND student_id=?", id, access.uid());
    if (prior != null) return prior;
    check(
        integer(task, "task_status", 0) == 1
            && !now().isBefore(time(task.get("start_time")))
            && now().isBefore(time(task.get("end_time"))),
        409,
        "签到不在有效时间");
    long device = id(b, "device_id");
    ownDevice(device, true);
    check(Crypto.same(Crypto.hash(text(b, "sign_code", 32)), str(task, "code_hash")), 400, "签到码错误");
    int status = now().isAfter(time(task.get("start_time")).plusMinutes(10)) ? 2 : 1;
    long record =
        db.insert(
            "attendance_record",
            map(
                "task_id",
                id,
                "student_id",
                access.uid(),
                "sign_status",
                status,
                "sign_time",
                now(),
                "device_id",
                device));
    audit.log("ATTENDANCE_SIGN", "attendance_record", record, map("status", status));
    return db.get("attendance_record", record);
  }

  public Object records(long id) {
    var task = db.get("attendance_task", id);
    var t = db.get("timetable", num(task.get("timetable_id")));
    var tc = access.teaching(num(t.get("teaching_class_id")), false);
    boolean teacher = eq(tc.get("teacher_id"), access.uid()) && access.has("attendance:write");
    return db.list(
        "SELECT * FROM attendance_record WHERE task_id=?"
            + (teacher ? "" : " AND student_id=?")
            + " ORDER BY student_id",
        teacher ? new Object[] {id} : new Object[] {id, access.uid()});
  }

  public Object today() {
    @SuppressWarnings("unchecked")
    var list = (List<Map<String, Object>>) teaching.timetables(map());
    return map(
        "timetables",
        list.stream()
            .filter(t -> integer(t, "week_day", 0) == now().getDayOfWeek().getValue())
            .toList(),
        "pending_leaves",
        db.count(
            "SELECT COUNT(*) FROM leave_approval a JOIN leave_request l ON a.leave_id=l.id WHERE"
                + " a.approver_id=? AND a.decision=0 AND a.apply_round=l.apply_round AND"
                + " l.leave_status IN (1,2)",
            access.uid()),
        "unread_messages",
        db.count(
            "SELECT COUNT(*) FROM message_receipt WHERE receiver_id=? AND read_time IS NULL",
            access.uid()),
        "update_time",
        now());
  }
}
