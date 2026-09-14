package com.zhixiaotong.service;

import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MessageDispatcher {
  private final Db db;

  public MessageDispatcher(Db db) {
    this.db = db;
  }

  @Transactional
  public void consume(long eventId) {
    var event = db.lock("outbox_event", eventId);
    String key = str(event, "event_key");
    if (db.count("SELECT COUNT(*) FROM message WHERE event_key=?", key) > 0) return;
    var p = Json.object(event.get("payload"));
    if (p.get("notice_id") != null) {
      var n = db.get("notice", num(p.get("notice_id")));
      if (integer(n, "publish_status", 0) != 1
          || (n.get("expire_time") != null && !time(n.get("expire_time")).isAfter(now()))) return;
    }
    long id =
        db.insert(
            "message",
            map(
                "message_title",
                text(p, "title", 128),
                "content",
                "业务状态有更新，请进入对应业务查看详情。",
                "notice_id",
                p.get("notice_id"),
                "biz_type",
                p.get("biz_type"),
                "biz_id",
                p.get("biz_id"),
                "event_key",
                key,
                "need_ack",
                integer(p, "need_ack", 0),
                "expire_time",
                p.get("expire_time") == null ? null : time(p.get("expire_time"))));
    if (p.get("receivers") instanceof List<?> receivers)
      for (long uid : receivers.stream().map(Data::num).distinct().toList()) {
        if (db.count("SELECT COUNT(*) FROM `user` WHERE id=? AND user_status=1", uid) == 0)
          continue;
        db.insert(
            "message_receipt",
            map(
                "message_id",
                id,
                "receiver_id",
                uid,
                "delivery_status",
                1,
                "delivered_time",
                now()));
      }
  }
}
