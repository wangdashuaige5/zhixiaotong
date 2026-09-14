package com.zhixiaotong.service;

import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import java.util.concurrent.TimeUnit;
import org.springframework.amqp.rabbit.connection.CorrelationData;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class OutboxPublisher {
  private final Db db;
  private final MessageDispatcher dispatcher;
  private final ObjectProvider<RabbitTemplate> rabbit;
  private final String mode;

  public OutboxPublisher(
      Db db,
      MessageDispatcher dispatcher,
      ObjectProvider<RabbitTemplate> rabbit,
      @Value("${campus.message-mode}") String mode) {
    this.db = db;
    this.dispatcher = dispatcher;
    this.rabbit = rabbit;
    this.mode = mode;
  }

  public void publish() {
    for (var e :
        db.list(
            "SELECT id FROM outbox_event WHERE send_status<>2 AND retry_count<6 AND"
                + " (next_retry_time IS NULL OR next_retry_time<=?) AND (lock_until IS NULL OR"
                + " lock_until<?) ORDER BY id LIMIT 50",
            now(),
            now())) {
      long id = num(e.get("id"));
      if (db.exec(
              "UPDATE outbox_event SET send_status=1,lock_until=?,update_time=? WHERE id=? AND"
                  + " send_status<>2 AND (lock_until IS NULL OR lock_until<?)",
              now().plusSeconds(45),
              now(),
              id,
              now())
          != 1) continue;
      try {
        if (mode.equals("local")) dispatcher.consume(id);
        else {
          var template = rabbit.getObject();
          template.setMandatory(true);
          var correlation = new CorrelationData(Long.toString(id));
          template.convertAndSend("campus.events", "notify", Long.toString(id), correlation);
          var confirm = correlation.getFuture().get(5, TimeUnit.SECONDS);
          if (!confirm.isAck() || correlation.getReturned() != null)
            throw new IllegalStateException("消息投递未确认");
        }
        db.update(
            "outbox_event",
            id,
            map(
                "send_status",
                2,
                "confirmed_time",
                now(),
                "lock_until",
                null,
                "error_message",
                null));
      } catch (Exception ex) {
        var current = db.get("outbox_event", id);
        int retries = integer(current, "retry_count", 0) + 1;
        db.update(
            "outbox_event",
            id,
            map(
                "send_status",
                3,
                "retry_count",
                retries,
                "next_retry_time",
                now().plusSeconds(Math.min(300, 1L << retries)),
                "lock_until",
                null,
                "error_message",
                "消息投递失败，等待重试或人工处理"));
      }
    }
  }
}
