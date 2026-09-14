package com.zhixiaotong.service;

import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import java.util.*;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

@Service
public class AuditService {
  private final Db db;
  private final Access access;

  public AuditService(Db db, Access access) {
    this.db = db;
    this.access = access;
  }

  public void log(String action, String type, Long id, Map<String, Object> safeSummary) {
    Long uid = null;
    try {
      uid = access.uid();
    } catch (BizException ignored) {
    }
    logAs(uid, action, type, id, safeSummary, false);
  }

  public void logAs(
      Long actor,
      String action,
      String type,
      Long id,
      Map<String, Object> safeSummary,
      boolean confirmed) {
    db.insert(
        "audit_log",
        map(
            "operator_id",
            actor,
            "action_type",
            action,
            "biz_type",
            type,
            "biz_id",
            id,
            "request_id",
            MDC.get("request_id") == null ? UUID.randomUUID().toString() : MDC.get("request_id"),
            "change_data",
            Json.write(safeSummary),
            "result_status",
            action.endsWith("FAILED") ? 0 : 1,
            "confirmed",
            confirmed ? 1 : 0,
            "operate_time",
            now()));
  }

  public void event(String type, long id, String title, List<Long> receivers) {
    db.insert(
        "outbox_event",
        map(
            "event_key",
            UUID.randomUUID().toString(),
            "event_type",
            "BUSINESS",
            "payload",
            Json.write(
                map("biz_type", type, "biz_id", id, "title", title, "receivers", receivers))));
  }
}
