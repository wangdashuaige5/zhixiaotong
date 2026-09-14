package com.zhixiaotong;

import static com.zhixiaotong.common.Data.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.dto.PageDto;
import com.zhixiaotong.security.*;
import com.zhixiaotong.service.*;
import java.math.*;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles({"demo", "test"})
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class CampusIntegrationTest {
  @Autowired Db db;
  @Autowired IEnrollmentService enrollment;
  @Autowired LeaveService leave;
  @Autowired GradeService grades;
  @Autowired LifeService life;
  @Autowired MockMvc mvc;
  @Autowired IUserService users;
  @Autowired TokenService tokens;
  @Autowired FileService files;
  @Autowired NoticeService notices;
  @Autowired MessageDispatcher dispatcher;
  @Autowired HarmonyService harmony;
  @Autowired ReportService reports;
  @Autowired AffairsService affairs;
  @Autowired AdminService admin;
  @Autowired TeachingService teaching;
  static long enrollmentId, gradeId;
  @Autowired ScheduleValidator schedule;

  void as(long id) {
    SecurityContextHolder.getContext()
        .setAuthentication(
            new UsernamePasswordAuthenticationToken(
                new LoginUser(id, "test-session", "test-device"), null, List.of()));
  }

  @AfterEach
  void clear() {
    SecurityContextHolder.clearContext();
  }

  @Test
  @Order(1)
  void contextAndSchema() {
    assertEquals(8, db.count("SELECT COUNT(*) FROM `user`"));
    assertEquals(
        57,
        db.count(
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND"
                + " table_type='BASE TABLE'"));
  }

  @Test
  @Order(2)
  void authenticationAndRefreshReplay() throws Exception {
    mvc.perform(get("/api/users/me")).andExpect(status().isUnauthorized());
    var result =
        users.login(
            map("user_name", "student_demo", "password", "Demo@123456", "device_code", "phone"));
    var token = str(result, "access_token");
    assertEquals(1, tokens.verify(token, false).id());
    mvc.perform(get("/api/users/me").header("Authorization", "Bearer " + token))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.id").value("1"))
        .andExpect(jsonPath("$.data.password_hash").doesNotExist());
    String refresh = str(result, "refresh_token");
    var pair = tokens.refresh(refresh);
    assertNotEquals(refresh, pair.get("refresh_token"));
    assertThrows(BizException.class, () -> tokens.refresh(refresh));
    assertThrows(BizException.class, () -> tokens.verify(str(pair, "access_token"), false));
  }

  @Test
  @Order(3)
  void enrollmentIdempotencyAndOwnership() {
    as(1);
    var e = enrollment.submit(map("batch_course_id", 1, "request_key", "enroll-test-1"));
    enrollmentId = num(e.get("id"));
    assertEquals(1, integer(e, "enroll_status", -1));
    assertEquals(
        enrollmentId,
        num(
            enrollment
                .submit(map("batch_course_id", 1, "request_key", "enroll-test-1"))
                .get("id")));
    assertEquals(1, integer(db.get("teaching_class", 1), "enrolled_count", 0));
    as(7);
    assertEquals(403, assertThrows(BizException.class, () -> enrollment.drop(enrollmentId)).status);
  }

  @Test
  @Order(4)
  void gradeSnapshotReviewAndCorrection() {
    as(2);
    grades.save(
        1,
        map(
            "teaching_class_id",
            1,
            "items",
            List.of(map("enrollment_id", enrollmentId, "usual_score", 80, "final_score", 90))));
    gradeId = num(db.one("SELECT id FROM grade WHERE enrollment_id=?", enrollmentId).get("id"));
    as(1);
    assertEquals(0, ((PageDto) grades.mine(map())).total());
    as(2);
    var review = (Map<String, Object>) grades.submit(1, map("teaching_class_id", 1));
    assertThrows(
        BizException.class, () -> grades.review(num(review.get("id")), map("decision", 1)));
    as(5);
    grades.review(num(review.get("id")), map("decision", 1));
    as(1);
    assertEquals(1, ((PageDto) grades.mine(map())).total());
    assertEquals(
        0, new BigDecimal("86.00").compareTo(dec(db.get("grade", gradeId), "total_score")));
    as(2);
    var change =
        (Map<String, Object>)
            grades.change(
                gradeId,
                map(
                    "version",
                    2,
                    "usual_score",
                    90,
                    "final_score",
                    90,
                    "change_reason",
                    "原平时成绩录入错误"));
    as(5);
    grades.decideChange(num(change.get("id")), map("decision", 1));
    assertEquals(
        0, new BigDecimal("90.00").compareTo(dec(db.get("grade", gradeId), "total_score")));
  }

  @Test
  @Order(5)
  void leaveThreeDaysAndLongRoute() {
    as(1);
    var start = now().plusDays(1);
    var l =
        leave.create(
            map(
                "leave_type",
                "事假",
                "start_time",
                start,
                "end_time",
                start.plusDays(3),
                "leave_reason",
                "演示事由"));
    long id = num(l.get("id"));
    as(3);
    assertEquals(
        3,
        integer(
            leave.approve(id, map("apply_round", 1, "node_order", 1, "decision", 1)),
            "leave_status",
            -1));
    as(1);
    assertEquals(7, integer(leave.close(id), "leave_status", -1));
    var longLeave =
        leave.create(
            map(
                "leave_type",
                "病假",
                "start_time",
                start,
                "end_time",
                start.plusDays(4),
                "leave_reason",
                "演示事由"));
    long lid = num(longLeave.get("id"));
    as(3);
    assertEquals(
        2,
        integer(
            leave.approve(lid, map("apply_round", 1, "node_order", 1, "decision", 1)),
            "leave_status",
            -1));
    assertThrows(
        BizException.class,
        () -> leave.approve(lid, map("apply_round", 1, "node_order", 1, "decision", 1)));
    as(6);
    assertEquals(
        3,
        integer(
            leave.approve(lid, map("apply_round", 1, "node_order", 2, "decision", 1)),
            "leave_status",
            -1));
  }

  @Test
  @Order(6)
  void rechargeCallbackPostsOnlyOnce() {
    as(1);
    var r =
        (Map<String, Object>)
            life.recharge(
                map("amount", "20.00", "pay_channel", "MOCK_PAY", "request_key", "recharge-test"));
    long id = num(r.get("id"));
    var body =
        map(
            "order_no",
            r.get("order_no"),
            "pay_trade_no",
            "MOCK-TEST-TRADE",
            "pay_channel",
            "MOCK_PAY",
            "amount",
            "20.00");
    life.callback(body);
    life.callback(body);
    life.post(id);
    life.post(id);
    assertEquals(1, db.count("SELECT COUNT(*) FROM card_transaction WHERE recharge_id=?", id));
    assertEquals(0, new BigDecimal("120.00").compareTo(dec(db.get("card_account", 1), "balance")));
    assertThrows(
        BizException.class,
        () ->
            life.callback(
                map(
                    "order_no",
                    r.get("order_no"),
                    "pay_trade_no",
                    "OTHER",
                    "pay_channel",
                    "MOCK_PAY",
                    "amount",
                    21)));
    assertThrows(
        BizException.class,
        () ->
            life.verifySignature(
                "{}", Long.toString(System.currentTimeMillis() / 1000), "invalid"));
  }

  @Test
  @Order(7)
  void libraryRenewAndReservation() {
    as(1);
    life.renew(1);
    life.renew(1);
    assertEquals(1, integer(db.get("book_loan", 1), "renew_count", 0));
    var r = (Map<String, Object>) life.reserve(map("book_id", 1, "request_key", "reserve-test"));
    assertEquals(1, integer(r, "reserve_status", -1));
    long id = num(r.get("id"));
    assertEquals(
        id,
        num(
            ((Map<String, Object>) life.reserve(map("book_id", 1, "request_key", "reserve-test")))
                .get("id")));
    as(7);
    assertThrows(BizException.class, () -> life.cancel(id));
    as(1);
    life.cancel(id);
    assertEquals(0, integer(db.get("book_copy", 1), "copy_status", -1));
  }

  @Test
  @Order(8)
  void leaveReturnCreatesNewRound() {
    as(1);
    var start = now().plusDays(2);
    var body =
        map(
            "leave_type",
            "事假",
            "start_time",
            start,
            "end_time",
            start.plusDays(1),
            "leave_reason",
            "初次申请");
    var r = leave.create(body);
    long id = num(r.get("id"));
    as(3);
    leave.approve(id, map("apply_round", 1, "node_order", 1, "decision", 3, "opinion", "请补充"));
    as(1);
    leave.edit(id, body);
    assertEquals(2, integer(db.get("leave_request", id), "apply_round", 0));
    as(3);
    assertThrows(
        BizException.class,
        () -> leave.approve(id, map("apply_round", 1, "node_order", 1, "decision", 1)));
    leave.approve(id, map("apply_round", 2, "node_order", 1, "decision", 1));
    assertEquals(2, db.count("SELECT COUNT(*) FROM leave_approval WHERE leave_id=?", id));
  }

  @Test
  @Order(9)
  void attachmentContentAndOwnership() throws Exception {
    as(1);
    var f =
        (Map<String, Object>)
            files.upload(
                new org.springframework.mock.web.MockMultipartFile(
                    "file",
                    "说明.txt",
                    "text/plain",
                    "演示附件".getBytes(java.nio.charset.StandardCharsets.UTF_8)));
    long id = num(f.get("id"));
    assertThrows(
        BizException.class,
        () ->
            files.upload(
                new org.springframework.mock.web.MockMultipartFile(
                    "file", "伪装.png", "image/png", "not a png".getBytes())));
    as(7);
    assertEquals(403, assertThrows(BizException.class, () -> files.status(id)).status);
    var before = db.count("SELECT COUNT(*) FROM leave_request");
    var start = now().plusDays(1);
    assertThrows(
        BizException.class,
        () ->
            leave.create(
                map(
                    "leave_type",
                    "事假",
                    "start_time",
                    start,
                    "end_time",
                    start.plusDays(1),
                    "leave_reason",
                    "错误附件",
                    "file_ids",
                    List.of(id))));
    assertEquals(before, db.count("SELECT COUNT(*) FROM leave_request"));
  }

  @Test
  @Order(10)
  void noticeDeliveryDeduplicatesReadAndAck() {
    as(3);
    var n =
        (Map<String, Object>)
            notices.create(
                map(
                    "notice_title",
                    "班级紧急通知",
                    "content",
                    "演示信息",
                    "urgency_level",
                    2,
                    "expire_time",
                    now().plusDays(1),
                    "scopes",
                    List.of(map("scope_type", 3, "class_id", 1))));
    long id = num(n.get("id"));
    long event =
        num(db.one("SELECT id FROM outbox_event WHERE event_key=?", "notice-" + id).get("id"));
    dispatcher.consume(event);
    dispatcher.consume(event);
    assertEquals(1, db.count("SELECT COUNT(*) FROM message WHERE notice_id=?", id));
    as(8);
    assertThrows(BizException.class, () -> notices.detail(id));
    as(1);
    notices.detail(id);
    var receipt =
        db.one(
            "SELECT r.* FROM message_receipt r JOIN message m ON m.id=r.message_id WHERE"
                + " m.notice_id=? AND r.receiver_id=1",
            id);
    assertNotNull(receipt.get("read_time"));
    assertNull(receipt.get("ack_time"));
    notices.ack(id);
    notices.ack(id);
    assertNotNull(db.get("message_receipt", num(receipt.get("id"))).get("ack_time"));
    as(3);
    notices.withdraw(id);
    as(1);
    assertThrows(BizException.class, () -> notices.detail(id));
  }

  void deviceAs(long user, String device) {
    SecurityContextHolder.getContext()
        .setAuthentication(
            new UsernamePasswordAuthenticationToken(
                new LoginUser(user, "test", device), null, List.of()));
  }

  @Test
  @Order(11)
  void trustedContinuationIsSingleUse() {
    deviceAs(1, "phone");
    var source =
        (Map<String, Object>)
            harmony.register(
                map(
                    "device_code",
                    "phone",
                    "device_name",
                    "手机",
                    "device_type",
                    "phone",
                    "password",
                    "Demo@123456"));
    deviceAs(1, "tablet");
    var target =
        (Map<String, Object>)
            harmony.register(
                map(
                    "device_code",
                    "tablet",
                    "device_name",
                    "平板",
                    "device_type",
                    "tablet",
                    "password",
                    "Demo@123456"));
    deviceAs(1, "phone");
    var c =
        (Map<String, Object>)
            harmony.continuation(
                map(
                    "source_device_id",
                    source.get("id"),
                    "target_device_id",
                    target.get("id"),
                    "biz_type",
                    "teaching_class",
                    "biz_id",
                    1));
    long id = num(c.get("id"));
    var body = map("continuation_token", c.get("continuation_token"));
    deviceAs(7, "tablet");
    assertThrows(BizException.class, () -> harmony.accept(id, body));
    deviceAs(1, "tablet");
    harmony.accept(id, body);
    assertThrows(BizException.class, () -> harmony.accept(id, body));
    assertNotEquals(c.get("continuation_token"), db.get("continuation", id).get("token_hash"));
    harmony.finish(id, map("action", "complete"));
  }

  @Test
  @Order(12)
  void asyncExportAndValidatedImport() throws Exception {
    as(4);
    var task =
        (Map<String, Object>)
            reports.create(map("task_type", "USER_EXPORT", "task_params", map("org_id", 2)));
    long tid = num(task.get("id"));
    reports.process(tid);
    var done = db.get("async_task", tid);
    assertEquals(2, integer(done, "task_status", -1), str(done, "error_message"));
    assertNotNull(done.get("result_file_id"));
    String csv =
        "user_name,real_name,password,org_id,class_id\nimport_student,导入测试,Demo@123456,4,1\n";
    var input =
        (Map<String, Object>)
            files.upload(
                new org.springframework.mock.web.MockMultipartFile(
                    "file",
                    "用户.csv",
                    "text/csv",
                    csv.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
    task =
        (Map<String, Object>)
            reports.create(
                map(
                    "task_type",
                    "USER_IMPORT",
                    "input_file_id",
                    input.get("id"),
                    "task_params",
                    map("org_id", 2)));
    tid = num(task.get("id"));
    reports.process(tid);
    assertEquals(0, db.count("SELECT COUNT(*) FROM `user` WHERE user_name='import_student'"));
    done = db.get("async_task", tid);
    assertEquals(2, integer(done, "task_status", -1), str(done, "error_message"));
    assertEquals(0, integer(Json.object(done.get("task_params")), "error_count", -1));
    reports.confirm(tid, map("confirmed", true));
    reports.process(tid);
    assertEquals(1, db.count("SELECT COUNT(*) FROM `user` WHERE user_name='import_student'"));
  }

  @Test
  @Order(13)
  void sensitiveStudentRecordsAreScoped() {
    as(3);
    var focus =
        (Map<String, Object>)
            affairs.focus(map("student_id", 1, "focus_type", "学业关注", "focus_content", "虚构的学业跟进内容"));
    long id = num(focus.get("id"));
    assertNotEquals("虚构的学业跟进内容", db.get("student_focus", id).get("focus_content"));
    as(4);
    assertThrows(BizException.class, () -> affairs.focusDetail(id));
    as(3);
    assertThrows(
        BizException.class,
        () -> affairs.focus(map("student_id", 8, "focus_type", "学业关注", "focus_content", "不可访问")));
    assertEquals("虚构的学业跟进内容", ((Map<String, Object>) affairs.focusDetail(id)).get("focus_content"));
  }

  @Test
  @Order(14)
  void hundredConcurrentSelectionsNeverOversell() throws Exception {
    db.update("teaching_class", 3, map("capacity", 5));
    List<Long> ids = new ArrayList<>();
    String hash = str(db.get("user", 1), "password_hash");
    for (int i = 0; i < 100; i++) {
      long uid =
          db.insert(
              "user",
              map(
                  "user_name",
                  "parallel_" + i,
                  "real_name",
                  "并发测试",
                  "password_hash",
                  hash,
                  "org_id",
                  4,
                  "class_id",
                  1));
      db.insert("user_role", map("user_id", uid, "role_id", 1));
      ids.add(uid);
    }
    var pool = java.util.concurrent.Executors.newFixedThreadPool(100);
    var gate = new java.util.concurrent.CountDownLatch(1);
    List<java.util.concurrent.Future<Integer>> results = new ArrayList<>();
    try {
      for (long uid : ids)
        results.add(
            pool.submit(
                () -> {
                  gate.await();
                  as(uid);
                  try {
                    enrollment.submit(map("batch_course_id", 3, "request_key", "parallel-" + uid));
                    return 1;
                  } catch (BizException e) {
                    assertEquals(409, e.status);
                    return 0;
                  } finally {
                    clear();
                  }
                }));
      gate.countDown();
      int won = 0;
      for (var f : results) won += f.get(60, java.util.concurrent.TimeUnit.SECONDS);
      assertEquals(5, won);
      assertEquals(5, integer(db.get("teaching_class", 3), "enrolled_count", -1));
      assertEquals(
          5,
          db.count(
              "SELECT COUNT(*) FROM enrollment WHERE teaching_class_id=3 AND enroll_status=1"));
    } finally {
      pool.shutdownNow();
    }
  }

  @Test
  @Order(15)
  void httpQueriesAndOpenApi() throws Exception {
    var login =
        users.login(
            map(
                "user_name",
                "student_demo",
                "password",
                "Demo@123456",
                "device_code",
                "http-smoke"));
    String token = str(login, "access_token");
    for (String uri :
        List.of(
            "/api/users/me",
            "/api/timetables",
            "/api/enrollments/me",
            "/api/enrollments/options?batch_id=1",
            "/api/courses/1?teaching_class_id=1",
            "/api/courses/1/resources?teaching_class_id=1",
            "/api/grades/me",
            "/api/leaves/me",
            "/api/cards/balance",
            "/api/cards/transactions",
            "/api/library/books",
            "/api/notices",
            "/api/messages",
            "/api/harmony/cards/today",
            "/api/student-affairs/me"))
      mvc.perform(get(uri).header("Authorization", "Bearer " + token)).andExpect(status().isOk());
    var result = mvc.perform(get("/v3/api-docs")).andExpect(status().isOk()).andReturn();
    java.nio.file.Files.writeString(
        java.nio.file.Path.of("target/openapi.json"),
        result.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8));
  }

  @Test
  @Order(16)
  void aidQuotaPreventsSecondApproval() {
    as(1);
    var a =
        (Map<String, Object>)
            affairs.applyAid(
                map("batch_id", 1, "apply_amount", "1000.00", "apply_reason", "虚构的演示申请"));
    as(7);
    var b =
        (Map<String, Object>)
            affairs.applyAid(
                map("batch_id", 1, "apply_amount", "1000.00", "apply_reason", "另一份演示申请"));
    long
        ar = num(db.one("SELECT id FROM aid_review WHERE application_id=?", a.get("id")).get("id")),
        br = num(db.one("SELECT id FROM aid_review WHERE application_id=?", b.get("id")).get("id"));
    as(3);
    affairs.reviewAid(ar, map("decision", 1));
    assertEquals(
        409,
        assertThrows(BizException.class, () -> affairs.reviewAid(br, map("decision", 1))).status);
    assertEquals(1, db.count("SELECT COUNT(*) FROM aid_application WHERE apply_status=2"));
  }

  @Test
  @Order(17)
  void assignmentGradeOnlyVisibleAfterPublish() {
    as(2);
    var a =
        (Map<String, Object>)
            teaching.assignment(
                1,
                map(
                    "teaching_class_id",
                    1,
                    "assignment_title",
                    "Java作业",
                    "content",
                    "编写一个类",
                    "deadline",
                    now().plusDays(3)));
    long aid = num(a.get("id"));
    as(1);
    var s = (Map<String, Object>) teaching.submit(aid, map("content", "演示作业答案"));
    long sid = num(s.get("id"));
    as(2);
    teaching.grade(sid, map("action", "grade", "score", 90, "feedback", "结构清晰"));
    as(1);
    var own = (List<Map<String, Object>>) teaching.submissions(aid);
    assertFalse(own.get(0).containsKey("score"));
    as(2);
    teaching.grade(sid, map("action", "publish"));
    as(1);
    own = (List<Map<String, Object>>) teaching.submissions(aid);
    assertEquals(0, new BigDecimal("90").compareTo(dec(own.get(0), "score")));
  }

  @Test
  @Order(18)
  void attendanceRequiresEnrollmentTrustedDeviceAndValidCode() {
    // 以当前日期建立测试排课，不依赖测试运行在星期几。
    long table =
        db.insert(
            "timetable",
            map(
                "teaching_class_id",
                1,
                "classroom_id",
                1,
                "start_week",
                1,
                "end_week",
                20,
                "week_day",
                now().getDayOfWeek().getValue(),
                "start_period",
                3,
                "end_period",
                4,
                "start_time",
                java.time.LocalTime.of(14, 0),
                "end_time",
                java.time.LocalTime.of(15, 0)));
    as(2);
    var task =
        (Map<String, Object>)
            harmony.attendance(
                map(
                    "timetable_id",
                    table,
                    "class_date",
                    now().toLocalDate(),
                    "start_time",
                    now().minusMinutes(1),
                    "end_time",
                    now().plusMinutes(5)));
    long id = num(task.get("id"));
    deviceAs(1, "tablet");
    long device =
        num(db.one("SELECT id FROM device WHERE user_id=1 AND device_code='tablet'").get("id"));
    assertThrows(
        BizException.class,
        () -> harmony.sign(id, map("device_id", device, "sign_code", "invalid")));
    harmony.sign(id, map("device_id", device, "sign_code", task.get("sign_code")));
    harmony.sign(id, map("device_id", device, "sign_code", task.get("sign_code")));
    assertEquals(1, db.count("SELECT COUNT(*) FROM attendance_record WHERE task_id=?", id));
  }

  @Test
  @Order(19)
  void adminConfirmationAndDelegationBoundary() {
    as(4);
    assertThrows(BizException.class, () -> admin.createUser(map("user_name", "unauthorized")));
    assertThrows(
        BizException.class,
        () -> admin.grantUser(7, map("role_ids", List.of(3), "confirmed", true)));
    admin.grantUser(8, map("role_ids", List.of(1), "confirmed", true));
    as(1);
    assertThrows(BizException.class, () -> admin.users(map()));
  }

  @Test
  @Order(20)
  void enrollmentConflictsDropAndClosedBatch() {
    as(1);
    var clash = db.get("timetable", 2);
    db.update("timetable", 2, map("week_day", 1));
    assertThrows(
        BizException.class,
        () -> enrollment.submit(map("batch_course_id", 2, "request_key", "conflict")));
    db.update("timetable", 2, map("week_day", clash.get("week_day")));
    var e = enrollment.submit(map("batch_course_id", 2, "request_key", "drop-test"));
    long id = num(e.get("id"));
    enrollment.drop(id);
    enrollment.drop(id);
    assertEquals(0, integer(db.get("teaching_class", 2), "enrolled_count", -1));
    var batch = db.get("selection_batch", 1);
    db.update("selection_batch", 1, map("batch_status", 2));
    assertThrows(
        BizException.class,
        () -> enrollment.submit(map("batch_course_id", 2, "request_key", "closed-test")));
    db.update("selection_batch", 1, map("batch_status", batch.get("batch_status")));
    enrollment.submit(map("batch_course_id", 2, "request_key", "reselect-new-key"));
    enrollment.drop(id);
    assertEquals(
        3,
        integer(
            enrollment.submit(map("batch_course_id", 2, "request_key", "drop-test")),
            "enroll_status",
            -1));
    assertEquals(0, integer(db.get("teaching_class", 2), "enrolled_count", -1));
  }

  @Test
  @Order(21)
  void everyDetailedDesignEndpointIsRegistered() throws Exception {
    var json =
        new com.fasterxml.jackson.databind.ObjectMapper()
            .readTree(java.nio.file.Files.readString(java.nio.file.Path.of("target/openapi.json")));
    var paths = json.get("paths");
    try (var in = getClass().getResourceAsStream("/design-endpoints.txt")) {
      var lines =
          new String(in.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8).lines().toList();
      assertEquals(82, lines.size());
      for (String line : lines) {
        String[] pair = line.split(" ", 2);
        assertTrue(paths.has(pair[1]), line);
        assertTrue(paths.get(pair[1]).has(pair[0].toLowerCase()), line);
      }
    }
  }

  @Test
  @Order(22)
  void realHttpPaymentCallbackRejectsBadSignature() throws Exception {
    as(1);
    var order =
        (Map<String, Object>)
            life.recharge(
                map(
                    "amount",
                    "1.00",
                    "pay_channel",
                    "MOCK_PAY",
                    "request_key",
                    "http-payment-test"));
    String body =
        Json.write(
            map(
                "order_no",
                order.get("order_no"),
                "pay_trade_no",
                "MOCK-HTTP-TRADE",
                "pay_channel",
                "MOCK_PAY",
                "amount",
                "1.00"));
    String stamp = Long.toString(System.currentTimeMillis() / 1000);
    mvc.perform(
            post("/api/integrations/payments/callback")
                .contentType("application/json")
                .content(body)
                .header("X-Payment-Timestamp", stamp)
                .header("X-Payment-Signature", "wrong"))
        .andExpect(status().isUnauthorized());
    String sig = Crypto.hmac("demo-only-payment-callback-secret", stamp + "\n" + body);
    for (int i = 0; i < 2; i++)
      mvc.perform(
              post("/api/integrations/payments/callback")
                  .contentType("application/json")
                  .content(body)
                  .header("X-Payment-Timestamp", stamp)
                  .header("X-Payment-Signature", sig))
          .andExpect(status().isOk());
    assertEquals(
        1, db.count("SELECT COUNT(*) FROM card_transaction WHERE recharge_id=?", order.get("id")));
  }

  @Test
  @Order(23)
  void libraryWaitingQueueGetsReleasedCopy() {
    as(1);
    var first = (Map<String, Object>) life.reserve(map("book_id", 1, "request_key", "queue-first"));
    as(7);
    var second =
        (Map<String, Object>) life.reserve(map("book_id", 1, "request_key", "queue-second"));
    long secondId = num(second.get("id"));
    assertEquals(0, integer(second, "reserve_status", -1));
    as(1);
    life.cancel(num(first.get("id")));
    assertEquals(1, integer(db.get("book_reservation", secondId), "reserve_status", -1));
    assertEquals(2, integer(db.get("book_copy", 1), "copy_status", -1));
    as(7);
    life.cancel(secondId);
    assertEquals(0, integer(db.get("book_copy", 1), "copy_status", -1));
  }
}
