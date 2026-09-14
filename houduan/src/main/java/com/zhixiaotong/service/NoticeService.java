package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Access;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NoticeService {
  private final Db db;
  private final Access access;
  private final BusinessAccess business;
  private final AuditService audit;
  private final FileService files;

  public NoticeService(
      Db db, Access access, BusinessAccess business, AuditService audit, FileService files) {
    this.db = db;
    this.access = access;
    this.business = business;
    this.audit = audit;
    this.files = files;
  }

  public Object list(Map<String, Object> q) {
    access.require("notice:read");
    return pageVisible(
        db.list("SELECT * FROM notice ORDER BY is_pinned DESC,id DESC").stream()
            .filter(n -> business.noticeVisible(n, access.uid()))
            .map(
                n ->
                    pick(
                        n,
                        "id",
                        "notice_title",
                        "publisher_id",
                        "urgency_level",
                        "is_pinned",
                        "need_ack",
                        "start_time",
                        "expire_time",
                        "publish_time"))
            .toList(),
        q);
  }

  private Object pageVisible(List<Map<String, Object>> l, Map<String, Object> q) {
    int p = integer(q, "page_no", 1), s = integer(q, "page_size", 20);
    range(p, 1, 100000, "page_no");
    range(s, 1, 100, "page_size");
    return new com.zhixiaotong.dto.PageDto(
        l.subList(Math.min(l.size(), (p - 1) * s), Math.min(l.size(), p * s)), l.size(), p, s);
  }

  @Transactional
  public Object create(Map<String, Object> b) {
    access.require("notice:publish");
    var scopes = rows(b, "scopes");
    check(!scopes.isEmpty(), 400, "至少选择一个接收范围");
    int urgency = integer(b, "urgency_level", 0), state = integer(b, "publish_status", 1);
    range(urgency, 0, 2, "urgency_level");
    range(state, 0, 1, "publish_status");
    var start = b.get("start_time") == null ? now() : time(b.get("start_time"));
    var end = b.get("expire_time") == null ? null : time(b.get("expire_time"));
    check(end == null || end.isAfter(start), 400, "通知失效时间应晚于生效时间");
    long id =
        db.insert(
            "notice",
            map(
                "notice_title",
                text(b, "notice_title", 128),
                "content",
                text(b, "content", 30000),
                "publisher_id",
                access.uid(),
                "urgency_level",
                urgency,
                "is_pinned",
                integer(b, "is_pinned", 0),
                "need_ack",
                urgency == 2 ? 1 : integer(b, "need_ack", 0),
                "start_time",
                start,
                "expire_time",
                end,
                "publish_status",
                state));
    for (var s : scopes) {
      int type = integer(s, "scope_type", 0);
      range(type, 1, 4, "scope_type");
      var v =
          map(
              "notice_id",
              id,
              "scope_type",
              type,
              "include_children",
              integer(s, "include_children", 1));
      switch (type) {
        case 1 -> {
          check(
              access.roles(access.uid(), "notice:publish").stream()
                  .anyMatch(r -> integer(r, "scope_type", 0) == 5),
              403,
              "无权发布全校通知");
          keys(s, "scope_type", "include_children");
        }
        case 2 -> {
          keys(s, "scope_type", "org_id", "include_children");
          long org = id(s, "org_id");
          access.org(org, "notice:publish");
          v.put("org_id", org);
        }
        case 3 -> {
          keys(s, "scope_type", "class_id", "include_children");
          long cls = id(s, "class_id");
          var cl = db.get("school_class", cls);
          boolean ok =
              access.canOrg(access.uid(), num(cl.get("grade_id")), "notice:publish")
                  || db.count(
                          "SELECT COUNT(*) FROM counselor_class WHERE counselor_id=? AND class_id=?"
                              + " AND start_time<=? AND (end_time IS NULL OR end_time>?)",
                          access.uid(),
                          cls,
                          now(),
                          now())
                      > 0;
          check(ok, 403, "无权向该班发布");
          v.put("class_id", cls);
        }
        case 4 -> {
          keys(s, "scope_type", "teaching_class_id", "include_children");
          long tc = id(s, "teaching_class_id");
          access.teaching(tc, true);
          v.put("teaching_class_id", tc);
        }
      }
      db.insert("notice_scope", v);
    }
    files.bind(ids(b, "file_ids"), "notice", id);
    publishDue(id);
    audit.log("NOTICE_CREATE", "notice", id, map("state", state, "scope_count", scopes.size()));
    return db.get("notice", id);
  }

  @Transactional
  public void publishDue(long id) {
    var n = db.lock("notice", id);
    if (integer(n, "publish_status", 0) != 1
        || n.get("publish_time") != null
        || time(n.get("start_time")).isAfter(now())
        || (n.get("expire_time") != null && !time(n.get("expire_time")).isAfter(now()))) return;
    var ids = new ArrayList<Long>();
    for (var u : db.list("SELECT id FROM `user` WHERE user_status=1 ORDER BY id")) {
      long uid = num(u.get("id"));
      if (business.noticeVisible(n, uid)) ids.add(uid);
    }
    db.insert(
        "outbox_event",
        map(
            "event_key",
            "notice-" + id,
            "event_type",
            "NOTICE",
            "payload",
            Json.write(
                map(
                    "biz_type",
                    "notice",
                    "biz_id",
                    id,
                    "notice_id",
                    id,
                    "title",
                    n.get("notice_title"),
                    "receivers",
                    ids,
                    "need_ack",
                    n.get("need_ack"),
                    "expire_time",
                    n.get("expire_time")))));
    db.update("notice", id, map("publish_time", now()));
  }

  @Transactional
  public Object detail(long id) {
    access.require("notice:read");
    var n = db.get("notice", id);
    check(business.noticeVisible(n, access.uid()), 404, "通知不可见或已失效");
    db.exec(
        "UPDATE message_receipt SET read_time=COALESCE(read_time,?),update_time=? WHERE"
            + " receiver_id=? AND message_id IN (SELECT id FROM message WHERE notice_id=?)",
        now(),
        now(),
        access.uid(),
        id);
    n.put(
        "file_ids",
        db.list(
            "SELECT id FROM file_upload WHERE biz_type='notice' AND biz_id=? AND file_status=1",
            id));
    return n;
  }

  @Transactional
  public Object ack(long id) {
    detail(id);
    var m = db.one("SELECT * FROM message WHERE notice_id=?", id);
    check(m != null, 409, "通知正在分发，请稍后确认");
    check(
        db.count(
                "SELECT COUNT(*) FROM message_receipt WHERE message_id=? AND receiver_id=?",
                m.get("id"),
                access.uid())
            > 0,
        403,
        "不是本次通知接收人");
    db.exec(
        "UPDATE message_receipt SET"
            + " ack_time=COALESCE(ack_time,?),read_time=COALESCE(read_time,?),update_time=? WHERE"
            + " message_id=? AND receiver_id=?",
        now(),
        now(),
        now(),
        m.get("id"),
        access.uid());
    return map("acknowledged", true);
  }

  @Transactional
  public void withdraw(long id) {
    access.require("notice:publish");
    var n = db.lock("notice", id);
    check(eq(n.get("publisher_id"), access.uid()), 403, "仅发布人可撤回");
    db.update("notice", id, map("publish_status", 2));
    audit.log("NOTICE_WITHDRAW", "notice", id, map());
  }

  private boolean visibleMessage(Map<String, Object> m) {
    try {
      if (m.get("expire_time") != null && !time(m.get("expire_time")).isAfter(now())) return false;
      business.checkRead(str(m, "biz_type"), num(m.get("biz_id")));
      return true;
    } catch (BizException e) {
      return false;
    }
  }

  public Object messages(Map<String, Object> q) {
    access.require("notice:read");
    var rows =
        db
            .list(
                "SELECT m.*,r.delivery_status,r.read_time,r.ack_time FROM message m JOIN"
                    + " message_receipt r ON r.message_id=m.id WHERE r.receiver_id=? ORDER BY m.id"
                    + " DESC",
                access.uid())
            .stream()
            .filter(this::visibleMessage)
            .toList();
    return pageVisible(rows, q);
  }

  @Transactional
  public void read(long id) {
    access.require("notice:read");
    var m = db.get("message", id);
    check(visibleMessage(m), 404, "消息对应业务不可见");
    check(
        db.count(
                "SELECT COUNT(*) FROM message_receipt WHERE message_id=? AND receiver_id=?",
                id,
                access.uid())
            > 0,
        403,
        "非消息接收人");
    db.exec(
        "UPDATE message_receipt SET read_time=COALESCE(read_time,?),update_time=? WHERE"
            + " message_id=? AND receiver_id=?",
        now(),
        now(),
        id,
        access.uid());
  }
}
