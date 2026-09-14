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
public class AffairsService {
  private final Db db;
  private final Access access;
  private final Crypto crypto;
  private final AuditService audit;
  private final FileService files;

  public AffairsService(
      Db db, Access access, Crypto crypto, AuditService audit, FileService files) {
    this.db = db;
    this.access = access;
    this.crypto = crypto;
    this.audit = audit;
    this.files = files;
  }

  public Object classes() {
    access.require("affairs:write");
    return db.list(
        "SELECT c.*,(SELECT COUNT(*) FROM `user` u WHERE u.class_id=c.id AND u.user_status=1) AS"
            + " student_count FROM school_class c WHERE EXISTS(SELECT 1 FROM counselor_class cc"
            + " WHERE cc.class_id=c.id AND cc.counselor_id=? AND cc.start_time<=? AND (cc.end_time"
            + " IS NULL OR cc.end_time>?)) ORDER BY c.id",
        access.uid(),
        now(),
        now());
  }

  @Transactional
  public Object record(Map<String, Object> b) {
    long student = id(b, "student_id");
    access.person(student, "affairs:write");
    int type = integer(b, "record_type", 0);
    range(type, 1, 2, "record_type");
    long id =
        db.insert(
            "student_record",
            map(
                "student_id",
                student,
                "record_type",
                type,
                "record_title",
                text(b, "record_title", 128),
                "record_level",
                optional(b, "record_level", 32),
                "description",
                text(b, "description", 20000),
                "record_date",
                date(b.get("record_date")),
                "operator_id",
                access.uid()));
    audit.log("STUDENT_RECORD", "student_record", id, map("student_id", student, "type", type));
    return db.get("student_record", id);
  }

  @Transactional
  public Object dorm(Map<String, Object> b) {
    long student = id(b, "student_id");
    access.person(student, "affairs:write");
    int result = integer(b, "check_result", 1);
    range(result, 1, 4, "check_result");
    var checkTime = time(b.get("check_time"));
    check(
        b.get("return_time") == null || !time(b.get("return_time")).isBefore(checkTime),
        400,
        "返寝时间不得早于检查时间");
    long id =
        db.insert(
            "dorm_check",
            map(
                "student_id",
                student,
                "dorm_location",
                text(b, "dorm_location", 128),
                "check_time",
                checkTime,
                "check_result",
                result,
                "return_time",
                b.get("return_time") == null ? null : time(b.get("return_time")),
                "handle_note",
                optional(b, "handle_note", 255),
                "checker_id",
                access.uid()));
    audit.log("DORM_CHECK", "dorm_check", id, map("student_id", student));
    return db.get("dorm_check", id);
  }

  @Transactional
  public Object focus(Map<String, Object> b) {
    long student = id(b, "student_id");
    access.person(student, "focus:write");
    long id =
        db.insert(
            "student_focus",
            map(
                "student_id",
                student,
                "focus_type",
                text(b, "focus_type", 32),
                "focus_content",
                crypto.encrypt(text(b, "focus_content", 20000)),
                "follow_up",
                crypto.encrypt(optional(b, "follow_up", 20000)),
                "owner_id",
                access.uid()));
    audit.log("FOCUS_CREATE", "student_focus", id, map("student_id", student));
    return map("id", id, "focus_status", 1);
  }

  public Object focusDetail(long id) {
    var f = db.get("student_focus", id);
    access.person(num(f.get("student_id")), "focus:read");
    audit.log("FOCUS_READ", "student_focus", id, map());
    f.put("focus_content", crypto.decrypt(str(f, "focus_content")));
    if (f.get("follow_up") != null) f.put("follow_up", crypto.decrypt(str(f, "follow_up")));
    return f;
  }

  @Transactional
  public Object followUp(long id, Map<String, Object> b) {
    var f = db.lock("student_focus", id);
    access.person(num(f.get("student_id")), "focus:write");
    check(integer(f, "focus_status", 1) == 1, 409, "关注已结案");
    String prev = f.get("follow_up") == null ? "" : crypto.decrypt(str(f, "follow_up"));
    String next = prev + "\n" + now() + " " + text(b, "follow_up", 5000);
    check(next.length() <= 60000, 400, "跟进记录过长");
    int status = integer(b, "focus_status", 1);
    range(status, 1, 2, "focus_status");
    db.update(
        "student_focus",
        id,
        map(
            "follow_up",
            crypto.encrypt(next),
            "focus_status",
            status,
            "close_time",
            status == 2 ? now() : null));
    audit.log("FOCUS_FOLLOWUP", "student_focus", id, map("status", status));
    return map("id", id, "focus_status", status);
  }

  @Transactional
  public void revokeRecord(long id, Map<String, Object> b) {
    var r = db.lock("student_record", id);
    access.person(num(r.get("student_id")), "affairs:write");
    check(integer(r, "record_status", 1) == 1, 409, "记录已撤销");
    db.update(
        "student_record",
        id,
        map("record_status", 2, "revoke_reason", text(b, "revoke_reason", 255)));
    audit.log("RECORD_REVOKE", "student_record", id, map());
  }

  @Transactional
  public Object applyAid(Map<String, Object> b) {
    access.student();
    access.require("affairs:apply");
    db.lock("user", access.uid());
    long batchId = id(b, "batch_id");
    var batch = db.lock("aid_batch", batchId);
    check(
        integer(batch, "batch_status", 0) == 1
            && !now().isBefore(time(batch.get("start_time")))
            && now().isBefore(time(batch.get("end_time"))),
        409,
        "资助批次不在开放时间");
    check(access.desc(num(access.user().get("org_id")), num(batch.get("org_id"))), 403, "不在资助组织范围");
    var amount = dec(b, "apply_amount");
    check(
        amount.signum() > 0
            && amount.scale() <= 2
            && amount.compareTo(dec(batch, "aid_amount")) <= 0,
        400,
        "申请金额超过批次额度");
    var old =
        db.one(
            "SELECT * FROM aid_application WHERE batch_id=? AND student_id=? FOR UPDATE",
            batchId,
            access.uid());
    check(old == null || integer(old, "apply_status", 0) == 4, 409, "已有有效资助申请");
    int round = old == null ? 1 : integer(old, "apply_round", 1) + 1;
    var v =
        map(
            "batch_id",
            batchId,
            "student_id",
            access.uid(),
            "apply_reason",
            text(b, "apply_reason", 20000),
            "apply_amount",
            amount,
            "apply_status",
            1,
            "apply_round",
            round,
            "submit_time",
            now());
    long id = old == null ? db.insert("aid_application", v) : num(old.get("id"));
    if (old != null) db.update("aid_application", id, v);
    long reviewer = access.approver(access.uid(), "aid:review");
    db.insert(
        "aid_review",
        map("application_id", id, "apply_round", round, "node_order", 1, "reviewer_id", reviewer));
    files.bind(ids(b, "file_ids"), "aid_application", id);
    audit.log("AID_APPLY", "aid_application", id, map("round", round));
    return db.get("aid_application", id);
  }

  @Transactional
  public Object reviewAid(long id, Map<String, Object> b) {
    var initial = db.get("aid_review", id);
    var app = db.get("aid_application", num(initial.get("application_id")));
    access.person(num(app.get("student_id")), "aid:review");
    var batch = db.lock("aid_batch", num(app.get("batch_id")));
    app = db.lock("aid_application", num(app.get("id")));
    var r = db.lock("aid_review", id);
    check(eq(r.get("reviewer_id"), access.uid()), 403, "非当前资助审核人");
    check(
        integer(r, "decision", 0) == 0
            && integer(app, "apply_status", 0) == 1
            && eq(r.get("apply_round"), app.get("apply_round")),
        409,
        "申请轮次已变化或已处理");
    int d = integer(b, "decision", 0);
    range(d, 1, 3, "decision");
    if (d == 1) {
      long used =
          db.count(
              "SELECT COUNT(*) FROM aid_application WHERE batch_id=? AND apply_status=2",
              batch.get("id"));
      check(used < integer(batch, "quota", 0), 409, "资助名额已用完");
      var sum =
          db.one(
              "SELECT COALESCE(SUM(apply_amount),0) AS total FROM aid_application WHERE batch_id=?"
                  + " AND apply_status=2",
              batch.get("id"));
      check(
          dec(sum, "total")
                  .add(dec(app, "apply_amount"))
                  .compareTo(
                      dec(batch, "aid_amount")
                          .multiply(BigDecimal.valueOf(integer(batch, "quota", 0))))
              <= 0,
          409,
          "资助总额度不足");
    }
    BigDecimal score = b.get("review_score") == null ? null : dec(b, "review_score");
    check(
        score == null || (score.signum() >= 0 && score.compareTo(new BigDecimal("100")) <= 0),
        400,
        "评审分数范围为0至100");
    db.update(
        "aid_review",
        id,
        map(
            "decision",
            d,
            "review_score",
            score,
            "opinion",
            d == 1 ? optional(b, "opinion", 255) : text(b, "opinion", 255),
            "review_time",
            now()));
    db.update(
        "aid_application", num(app.get("id")), map("apply_status", d == 1 ? 2 : d == 2 ? 3 : 4));
    audit.log("AID_REVIEW", "aid_application", num(app.get("id")), map("decision", d));
    audit.event(
        "aid_application", num(app.get("id")), "资助申请状态已更新", List.of(num(app.get("student_id"))));
    return db.get("aid_application", num(app.get("id")));
  }

  @Transactional
  public Object applyService(Map<String, Object> b) {
    access.student();
    access.require("affairs:apply");
    int type = integer(b, "service_type", 0);
    range(type, 1, 2, "service_type");
    check(b.get("apply_data") instanceof Map, 400, "apply_data必须为对象");
    @SuppressWarnings("unchecked")
    var input = (Map<String, Object>) b.get("apply_data");
    keys(input, "purpose", "remarks", "contact_email");
    input
        .values()
        .forEach(
            v ->
                check(
                    v instanceof String && v.toString().length() <= 2000, 400, "事项字段必须是2000字以内文本"));
    long handler = access.approver(access.uid(), "affairs:handle");
    long id =
        db.insert(
            "service_application",
            map(
                "student_id",
                access.uid(),
                "service_type",
                type,
                "service_name",
                text(b, "service_name", 128),
                "apply_data",
                Json.write(input),
                "service_status",
                1,
                "submit_time",
                now()));
    var u = db.get("user", handler);
    db.insert(
        "service_step",
        map(
            "application_id",
            id,
            "step_order",
            1,
            "step_name",
            type == 1 ? "学生证明审核" : "离校信息审核",
            "org_id",
            u.get("org_id"),
            "handler_id",
            handler));
    if (type == 2) {
      long dean = access.approver(access.uid(), "leave:dean");
      db.insert(
          "service_step",
          map(
              "application_id",
              id,
              "step_order",
              2,
              "step_name",
              "院系离校确认",
              "org_id",
              db.get("user", dean).get("org_id"),
              "handler_id",
              dean));
    }
    files.bind(ids(b, "file_ids"), "service_application", id);
    audit.log("SERVICE_APPLY", "service_application", id, map("type", type));
    return db.get("service_application", id);
  }

  @Transactional
  public Object decideStep(long id, Map<String, Object> b) {
    var initial = db.get("service_step", id);
    var app = db.lock("service_application", num(initial.get("application_id")));
    var step = db.lock("service_step", id);
    access.person(num(app.get("student_id")), "affairs:handle");
    check(eq(step.get("handler_id"), access.uid()), 403, "非当前办理人");
    check(
        integer(app, "service_status", 0) == 1 && integer(step, "decision", 0) == 0,
        409,
        "事项已处理或不在办理中");
    check(
        db.count(
                "SELECT COUNT(*) FROM service_step WHERE application_id=? AND step_order<? AND"
                    + " decision<>1",
                app.get("id"),
                step.get("step_order"))
            == 0,
        409,
        "前置步骤尚未通过");
    int d = integer(b, "decision", 0);
    range(d, 1, 2, "decision");
    db.update(
        "service_step",
        id,
        map(
            "decision",
            d,
            "opinion",
            d == 1 ? optional(b, "opinion", 255) : text(b, "opinion", 255),
            "handle_time",
            now()));
    if (d == 2) db.update("service_application", num(app.get("id")), map("service_status", 3));
    else if (db.count(
            "SELECT COUNT(*) FROM service_step WHERE application_id=? AND decision<>1",
            app.get("id"))
        == 0) {
      var student = db.get("user", num(app.get("student_id")));
      String content =
          "智校通事项办理结果\n申请编号："
              + app.get("id")
              + "\n事项："
              + app.get("service_name")
              + "\n姓名："
              + student.get("real_name")
              + "\n学号："
              + student.get("user_no")
              + "\n办理状态：已完成\n完成时间："
              + now()
              + "\n本文件为系统办理回执；正式证明模板和签章由学校提供。\n";
      long file =
          files.saveGenerated(
              "事项办理回执-" + app.get("id") + ".txt",
              "text/plain",
              content.getBytes(java.nio.charset.StandardCharsets.UTF_8),
              "service_application",
              num(app.get("id")),
              num(app.get("student_id")));
      db.update(
          "service_application",
          num(app.get("id")),
          map("service_status", 2, "result_file_id", file, "finish_time", now()));
    }
    audit.log("SERVICE_STEP", "service_step", id, map("decision", d));
    audit.event(
        "service_application",
        num(app.get("id")),
        "事项办理状态已更新",
        List.of(num(app.get("student_id"))));
    return db.get("service_application", num(app.get("id")));
  }

  public Object mine() {
    access.student();
    return map(
        "records",
        db.list("SELECT * FROM student_record WHERE student_id=? ORDER BY id DESC", access.uid()),
        "aid_applications",
        db.list("SELECT * FROM aid_application WHERE student_id=? ORDER BY id DESC", access.uid()),
        "service_applications",
        db.list(
            "SELECT * FROM service_application WHERE student_id=? ORDER BY id DESC", access.uid()));
  }

  public Object pending() {
    check(access.has("aid:review") || access.has("affairs:handle"), 403, "无事务审核权限");
    return map(
        "aid",
        db
            .list(
                "SELECT r.*,a.student_id FROM aid_review r JOIN aid_application a ON"
                    + " a.id=r.application_id WHERE r.reviewer_id=? AND r.decision=0 AND"
                    + " r.apply_round=a.apply_round AND a.apply_status=1",
                access.uid())
            .stream()
            .filter(a -> access.canStudent(access.uid(), num(a.get("student_id")), "aid:review"))
            .toList(),
        "steps",
        db
            .list(
                "SELECT s.*,a.student_id FROM service_step s JOIN service_application a ON"
                    + " a.id=s.application_id WHERE s.handler_id=? AND s.decision=0 AND"
                    + " a.service_status=1 AND NOT EXISTS(SELECT 1 FROM service_step prev WHERE"
                    + " prev.application_id=s.application_id AND prev.step_order<s.step_order AND"
                    + " prev.decision<>1)",
                access.uid())
            .stream()
            .filter(
                a -> access.canStudent(access.uid(), num(a.get("student_id")), "affairs:handle"))
            .toList());
  }

  public Object batches() {
    access.student();
    return db
        .list(
            "SELECT * FROM aid_batch WHERE batch_status=1 AND start_time<=? AND end_time>? ORDER BY"
                + " id",
            now(),
            now())
        .stream()
        .filter(b -> access.desc(num(access.user().get("org_id")), num(b.get("org_id"))))
        .toList();
  }
}
