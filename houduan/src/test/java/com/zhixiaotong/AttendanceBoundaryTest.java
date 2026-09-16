package com.zhixiaotong;

import static com.zhixiaotong.common.Data.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.zhixiaotong.common.BizException;
import com.zhixiaotong.common.Db;
import com.zhixiaotong.security.LoginUser;
import com.zhixiaotong.service.HarmonyService;
import com.zhixiaotong.service.IEnrollmentService;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/**
 * 签到业务正常行为边界测试：拒绝无权/失效请求，允许正确排课的有效签到。
 *
 * <p>本类断言检查正常业务行为，保留签到排课、选课、设备与时间窗的安全边界。
 * 只使用专用 H2 内存数据库 attendance_boundary_audit_20260915 和虚构 demo 数据。
 * 测试只把内存库演示学期起点向前移动一周，让“昨天”始终属于该学期，不修改系统时钟。
 * 每项测试事务自动回滚，后台任务关闭，不访问本机 MySQL，不操作相机/相册 SDK。
 */
@SpringBootTest(
    properties = {
      "spring.datasource.url=jdbc:h2:mem:attendance_boundary_audit_20260915;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1;NON_KEYWORDS=USER;LOCK_TIMEOUT=15000",
      "spring.datasource.username=sa",
      "spring.datasource.password=",
      "spring.datasource.driver-class-name=org.h2.Driver",
      "spring.flyway.enabled=false",
      "campus.jobs-enabled=false",
      "campus.storage-path=./target/attendance-boundary-audit-files"
    })
@ActiveProfiles({"demo", "test"})
@Transactional
class AttendanceBoundaryTest {
  @Autowired Db db;
  @Autowired IEnrollmentService enrollment;
  @Autowired HarmonyService harmony;

  private static final String STUDENT_DEVICE = "attendance-audit-student-device";
  private static final String OTHER_DEVICE = "attendance-audit-other-device";
  private long studentId;
  private long teacherId;
  private long ownDeviceId;
  private LocalDate fixtureDate;

  private long userId(String username) {
    return num(db.one("SELECT id FROM `user` WHERE user_name=?", username).get("id"));
  }

  private void as(long id, String deviceCode) {
    SecurityContextHolder.getContext()
        .setAuthentication(
            new UsernamePasswordAuthenticationToken(
                new LoginUser(id, "attendance-audit-session-" + id, deviceCode), null, List.of()));
  }

  private void asEnrolledStudent() {
    as(studentId, STUDENT_DEVICE);
  }

  @BeforeEach
  void prepareIsolatedStudentAndTrustedDevice() {
    studentId = userId("student_demo");
    teacherId = userId("teacher_demo");
    fixtureDate = now().toLocalDate();
    var semester = db.get("semester", 1);
    db.update(
        "semester",
        1,
        map("start_date", date(semester.get("start_date")).with(DayOfWeek.MONDAY).minusWeeks(1)));

    // 走真实选课业务，确保成功学生的课表关系来自有效 enrollment，而非手工伪造身份。
    asEnrolledStudent();
    var selected =
        enrollment.submit(
            map("batch_course_id", 1, "request_key", "attendance-audit-" + UUID.randomUUID()));
    assertEquals(1, integer(selected, "enroll_status", -1));
    ownDeviceId = registerTrustedDevice(studentId, STUDENT_DEVICE);
  }

  @AfterEach
  void clearAuthentication() {
    SecurityContextHolder.clearContext();
  }

  @SuppressWarnings("unchecked")
  private long registerTrustedDevice(long ownerId, String deviceCode) {
    as(ownerId, deviceCode);
    var device =
        (Map<String, Object>)
            harmony.register(
                map(
                    "device_code", deviceCode,
                    "password", "Demo@123456",
                    "device_name", "内存库签到边界测试设备",
                    "device_type", "TEST"));
    assertEquals(1, integer(device, "trust_status", -1));
    return num(device.get("id"));
  }

  private long timetableFor(long teachingClassId, LocalDate date) {
    // 与既有集成测试相同：直接准备独立排课 fixture，随后通过真实签到业务创建任务。
    // 每个任务使用新排课，避免 timetable_id+class_date 唯一键互相干扰。
    return db.insert(
        "timetable",
        map(
            "teaching_class_id", teachingClassId,
            "classroom_id", 1,
            "start_week", 1,
            "end_week", 20,
            "week_day", date.getDayOfWeek().getValue(),
            "start_period", 3,
            "end_period", 4,
            "start_time", LocalTime.of(14, 0),
            "end_time", LocalTime.of(15, 0)));
  }

  @SuppressWarnings("unchecked")
  private Map<String, Object> createTask(
      long teachingClassId, LocalDate date, LocalDateTime start, LocalDateTime end) {
    long timetableId = timetableFor(teachingClassId, date);
    as(teacherId, "attendance-audit-teacher-device");
    var task =
        (Map<String, Object>)
            harmony.attendance(
                map(
                    "timetable_id", timetableId,
                    "class_date", date,
                    "start_time", start,
                    "end_time", end));
    assertEquals(
        timetableId, num(db.get("attendance_task", num(task.get("id"))).get("timetable_id")));
    asEnrolledStudent();
    return task;
  }

  private Map<String, Object> createCurrentlyValidTask(long teachingClassId) {
    var instant = now();
    LocalDate day = instant.toLocalDate();
    LocalDateTime start = instant.minusMinutes(1);
    if (!start.toLocalDate().equals(day)) start = day.atStartOfDay();
    LocalDateTime lastWholeSecond = day.atTime(23, 59, 59);
    LocalDateTime end = instant.plusMinutes(10);
    if (end.isAfter(lastWholeSecond)) end = lastWholeSecond;
    // 服务要求同日窗口；只在午夜前不足 5 秒这一真实边界跳过时间敏感测试，避免跨日竞态。
    // 不延长有效期、不篡改时钟，也不将跳过伪称通过；常规时间所有测试均应执行。
    assumeTrue(end.isAfter(instant.plusSeconds(5)), "距午夜不足5秒，当前同日签到窗不够完成断言");
    return createTask(teachingClassId, day, start, end);
  }

  private Map<String, Object> signBody(Map<String, Object> task, long deviceId) {
    return map("device_id", deviceId, "sign_code", task.get("sign_code"));
  }

  private void assertNoAttendanceRecord(Map<String, Object> task) {
    assertEquals(
        0,
        db.count("SELECT COUNT(*) FROM attendance_record WHERE task_id=?", task.get("id")),
        "拒绝签到后不得写入考勤记录");
  }

  @Test
  void rejectsStudentWhoHasNotEnrolledEvenWithOwnTrustedDeviceAndCorrectCode() {
    var task = createCurrentlyValidTask(1);
    long outsiderId = userId("student_other");
    long outsiderDevice = registerTrustedDevice(outsiderId, OTHER_DEVICE);
    assertEquals(
        0,
        db.count(
            "SELECT COUNT(*) FROM enrollment WHERE student_id=? AND teaching_class_id=1 AND enroll_status=1",
            outsiderId));
    var rejected =
        assertThrows(
            BizException.class,
            () -> harmony.sign(num(task.get("id")), signBody(task, outsiderDevice)));
    assertEquals(403, rejected.status);
    assertNoAttendanceRecord(task);
  }

  @Test
  void rejectsCorrectlyEnrolledStudentUsingAnotherPersonsTrustedDevice() {
    var task = createCurrentlyValidTask(1);
    long otherDevice = registerTrustedDevice(userId("student_two"), OTHER_DEVICE);
    asEnrolledStudent();
    var rejected =
        assertThrows(
            BizException.class, () -> harmony.sign(num(task.get("id")), signBody(task, otherDevice)));
    assertEquals(403, rejected.status);
    assertNoAttendanceRecord(task);
  }

  @Test
  void rejectsUntrustedOwnDevice() {
    var task = createCurrentlyValidTask(1);
    db.update("device", ownDeviceId, map("trust_status", 0));
    var rejected =
        assertThrows(
            BizException.class, () -> harmony.sign(num(task.get("id")), signBody(task, ownDeviceId)));
    assertEquals(403, rejected.status);
    assertNoAttendanceRecord(task);
  }

  @Test
  void rejectsTaskForDifferentTeachingClassDespiteEnrollmentInAnotherClass() {
    var task = createCurrentlyValidTask(2);
    assertEquals(
        0,
        db.count(
            "SELECT COUNT(*) FROM enrollment WHERE student_id=? AND teaching_class_id=2 AND enroll_status=1",
            studentId));
    var rejected =
        assertThrows(
            BizException.class, () -> harmony.sign(num(task.get("id")), signBody(task, ownDeviceId)));
    assertEquals(403, rejected.status);
    assertNoAttendanceRecord(task);
  }

  @Test
  void rejectsUnknownTimetableWhenTeacherPublishesTask() {
    as(teacherId, "attendance-audit-teacher-device");
    long missing = Long.MAX_VALUE;
    assertEquals(0, db.count("SELECT COUNT(*) FROM timetable WHERE id=?", missing));
    long taskCountBefore = db.count("SELECT COUNT(*) FROM attendance_task");
    var rejected =
        assertThrows(
            BizException.class,
            () ->
                harmony.attendance(
                    map(
                        "timetable_id", missing,
                        "class_date", fixtureDate,
                        "start_time", fixtureDate.atTime(14, 0),
                        "end_time", fixtureDate.atTime(14, 30))));
    assertEquals(404, rejected.status);
    assertEquals(taskCountBefore, db.count("SELECT COUNT(*) FROM attendance_task"));
  }

  @Test
  void rejectsClassDateThatDoesNotMatchTimetableWeekday() {
    long timetable = timetableFor(1, fixtureDate);
    LocalDate differentWeekday = fixtureDate.plusDays(1);
    as(teacherId, "attendance-audit-teacher-device");
    var rejected =
        assertThrows(
            BizException.class,
            () ->
                harmony.attendance(
                    map(
                        "timetable_id", timetable,
                        "class_date", differentWeekday,
                        "start_time", differentWeekday.atTime(14, 0),
                        "end_time", differentWeekday.atTime(14, 30))));
    assertEquals(400, rejected.status);
    assertTrue(rejected.getMessage().contains("该日期不属于此排课"));
    assertEquals(
        0, db.count("SELECT COUNT(*) FROM attendance_task WHERE timetable_id=?", timetable));
  }

  @Test
  void acceptsOpenTaskRegardlessOfFutureScheduleTime() {
    LocalDate tomorrow = fixtureDate.plusDays(1);
    var task = createTask(1, tomorrow, tomorrow.atTime(9, 0), tomorrow.atTime(9, 30));
    var signed=(Map<String,Object>) harmony.sign(num(task.get("id")),signBody(task,ownDeviceId));
    assertEquals(1,integer(signed,"sign_status",-1));
    assertNotNull(signed.get("sign_time"));
  }

  @Test
  void acceptsOpenTaskRegardlessOfPastScheduleTime() {
    LocalDate yesterday = fixtureDate.minusDays(1);
    var task = createTask(1, yesterday, yesterday.atTime(9, 0), yesterday.atTime(9, 30));
    assertEquals(1, integer(db.get("attendance_task", num(task.get("id"))), "task_status", -1));
    var signed=(Map<String,Object>) harmony.sign(num(task.get("id")),signBody(task,ownDeviceId));
    assertEquals(1,integer(signed,"sign_status",-1));
    assertNotNull(signed.get("sign_time"));
  }

  @Test
  void teacherCanCloseTaskWithoutDeletingRecordsAndNewSignIsRejected() {
    var task=createCurrentlyValidTask(1);
    as(teacherId,"attendance-audit-teacher-device");
    harmony.closeAttendance(num(task.get("id")));
    harmony.closeAttendance(num(task.get("id")));
    asEnrolledStudent();
    var rejected=assertThrows(BizException.class,()->harmony.sign(num(task.get("id")),signBody(task,ownDeviceId)));
    assertEquals(409,rejected.status);
    assertTrue(rejected.getMessage().contains("教师已结束"));
    assertNoAttendanceRecord(task);
  }

  @Test
  void studentCannotCloseTeachersTask() {
    var task=createCurrentlyValidTask(1);
    assertEquals(403,assertThrows(BizException.class,()->harmony.closeAttendance(num(task.get("id")))).status);
    assertEquals(1,integer(db.get("attendance_task",num(task.get("id"))),"task_status",-1));
  }

  @Test
  void repeatedPublishingReusesTaskAndRecordsButRotatesOldCode() {
    var task=createCurrentlyValidTask(1);
    var first=(Map<String,Object>)harmony.sign(num(task.get("id")),signBody(task,ownDeviceId));
    var row=db.get("attendance_task",num(task.get("id")));
    as(teacherId,"attendance-audit-teacher-device");
    harmony.closeAttendance(num(task.get("id")));
    var again=(Map<String,Object>)harmony.attendance(map("timetable_id",row.get("timetable_id"),"class_date",row.get("class_date"),"start_time",row.get("start_time"),"end_time",row.get("end_time")));
    assertEquals(num(task.get("id")),num(again.get("id")));
    assertEquals(true,again.get("reused"));
    assertNotEquals(task.get("sign_code"),again.get("sign_code"));
    assertEquals(1,db.count("SELECT COUNT(*) FROM attendance_task WHERE timetable_id=? AND class_date=?",row.get("timetable_id"),row.get("class_date")));
    asEnrolledStudent();
    assertEquals(400,assertThrows(BizException.class,()->harmony.sign(num(task.get("id")),signBody(task,ownDeviceId))).status);
    var duplicate=(Map<String,Object>)harmony.sign(num(again.get("id")),signBody(again,ownDeviceId));
    assertEquals(num(first.get("id")),num(duplicate.get("id")));
    assertEquals(1,db.count("SELECT COUNT(*) FROM attendance_record WHERE task_id=?",task.get("id")));
  }

  @Test
  void previousSignDoesNotBypassCurrentDeviceVerification() {
    var task=createCurrentlyValidTask(1);
    harmony.sign(num(task.get("id")),signBody(task,ownDeviceId));
    db.update("device",ownDeviceId,map("trust_status",0));
    assertEquals(403,assertThrows(BizException.class,()->harmony.sign(num(task.get("id")),signBody(task,ownDeviceId))).status);
  }

  @Test
  @SuppressWarnings("unchecked")
  void acceptsCorrectClassOwnTrustedDeviceValidCodeAndActiveWindow() {
    var task = createCurrentlyValidTask(1);
    var signed =
        (Map<String, Object>)
            harmony.sign(num(task.get("id")), signBody(task, ownDeviceId));
    assertEquals(studentId, num(signed.get("student_id")));
    assertEquals(num(task.get("id")), num(signed.get("task_id")));
    assertEquals(ownDeviceId, num(signed.get("device_id")));
    assertEquals(1, integer(signed, "sign_status", -1));
    assertNotNull(signed.get("sign_time"));
    assertEquals(
        1,
        db.count(
            "SELECT COUNT(*) FROM attendance_record WHERE task_id=? AND student_id=?",
            task.get("id"), studentId));
  }
}
