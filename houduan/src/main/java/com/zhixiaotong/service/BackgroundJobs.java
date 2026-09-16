package com.zhixiaotong.service;

import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "campus.jobs-enabled", havingValue = "true")
public class BackgroundJobs {
  private final Db db;
  private final NoticeService notices;
  private final OutboxPublisher outbox;
  private final LeaveService leaves;
  private final LifeService life;
  private final FileService files;
  private final ReportService reports;
  private final IEnrollmentService enrollments;
  private final boolean autoClose;
  private final String integration;

  public BackgroundJobs(
      Db db,
      NoticeService notices,
      OutboxPublisher outbox,
      LeaveService leaves,
      LifeService life,
      FileService files,
      ReportService reports,
      IEnrollmentService enrollments,
      @Value("${campus.auto-close-leave}") boolean autoClose,
      @Value("${campus.integration-mode}") String integration) {
    this.db = db;
    this.notices = notices;
    this.outbox = outbox;
    this.leaves = leaves;
    this.life = life;
    this.files = files;
    this.reports = reports;
    this.enrollments = enrollments;
    this.autoClose = autoClose;
    this.integration = integration;
  }

  private void safe(Runnable job) {
    try {
      job.run();
    } catch (Exception e) {
      LoggerFactory.getLogger(getClass()).warn("后台任务未完成：{}", e.getClass().getSimpleName());
    }
  }

  @Scheduled(fixedDelay = 5000, initialDelay = 15000)
  public void fast() {
    safe(
        () -> {
          for (var n :
              db.list(
                  "SELECT id FROM notice WHERE publish_status=1 AND publish_time IS NULL AND"
                      + " start_time<=? LIMIT 30",
                  now())) safe(() -> notices.publishDue(num(n.get("id"))));
          outbox.publish();
          for (var t :
              db.list(
                  "SELECT id FROM async_task WHERE task_status=0 OR (task_status=1 AND"
                      + " update_time<?) ORDER BY id LIMIT 5",
                  now().minusMinutes(10))) safe(() -> reports.process(num(t.get("id"))));
        });
  }

  @Scheduled(fixedDelay = 60000, initialDelay = 30000)
  public void maintenance() {
    safe(
        () -> {
          db.exec(
              "UPDATE continuation SET task_status=3,reclaim_time=?,update_time=? WHERE"
                  + " task_status=0 AND expire_time<?",
              now(),
              now(),
              now());
          // 课堂签到由教师显式结束；课程安排时间不再触发自动关闭。
          if (autoClose)
            for (var l :
                db.list(
                    "SELECT id FROM leave_request WHERE leave_status=3 AND end_time<? LIMIT 100",
                    now())) safe(() -> leaves.autoClose(num(l.get("id"))));
          if (integration.equals("mock")) {
            for (var book :
                db.list(
                    "SELECT DISTINCT r.book_id FROM book_reservation r JOIN book_copy c ON"
                        + " c.book_id=r.book_id WHERE r.reserve_status=0 AND c.copy_status=0 LIMIT"
                        + " 30")) safe(() -> life.allocate(num(book.get("book_id"))));
            for (var r : db.list("SELECT id FROM recharge_order WHERE order_status=1 LIMIT 30"))
              safe(() -> life.post(num(r.get("id"))));
            for (var r :
                db.list(
                    "SELECT id FROM recharge_order WHERE order_status=0 AND expire_time<? LIMIT 30",
                    now())) safe(() -> life.expireOrder(num(r.get("id"))));
            for (var r :
                db.list(
                    "SELECT id FROM book_reservation WHERE reserve_status=1 AND expire_time<? LIMIT"
                        + " 30",
                    now())) safe(() -> life.expireReservation(num(r.get("id"))));
          }
          for (var f :
              db.list(
                  "SELECT id FROM file_upload WHERE file_status=0 AND create_time<? LIMIT 30",
                  now().minusHours(24))) safe(() -> files.cleanup(num(f.get("id"))));
          for (var b :
              db.list(
                  "SELECT bc.id FROM batch_course bc JOIN selection_batch b ON b.id=bc.batch_id"
                      + " WHERE bc.admission_type IN(2,3) AND bc.process_status<>2 AND"
                      + " b.end_time<=? LIMIT 10",
                  now())) safe(() -> enrollments.settle(num(b.get("id"))));
        });
  }
}
