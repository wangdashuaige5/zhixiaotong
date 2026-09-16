package com.zhixiaotong;

import static com.zhixiaotong.common.Data.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import com.zhixiaotong.service.*;
import java.util.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

/**
 * 全功能检查后修复的正常行为回归测试。
 * 仅使用独立 H2 内存库和虚构 demo 数据，每项测试事务回滚，不连接本机 MySQL。
 * 断言均检查修复后的正确结果，不以复现缺陷作为通过条件。
 */
@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:backend_repairs;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1;NON_KEYWORDS=USER;LOCK_TIMEOUT=15000",
    "spring.datasource.username=sa", "spring.datasource.password=",
    "spring.datasource.driver-class-name=org.h2.Driver", "spring.flyway.enabled=false",
    "campus.jobs-enabled=false", "campus.storage-path=./target/backend-repair-files"
})
@AutoConfigureMockMvc
@ActiveProfiles({"demo", "test"})
@Transactional
@SuppressWarnings("unchecked")
class BackendRepairRegressionTest {
  @Autowired Db db;
  @Autowired IUserService users;
  @Autowired IEnrollmentService enrollment;
  @Autowired GradeService grades;
  @Autowired AdminService admin;
  @Autowired TeachingService teaching;
  @Autowired HarmonyService harmony;
  @Autowired LeaveService leaves;
  @Autowired ScheduleValidator schedule;
  @Autowired MockMvc mvc;

  private long userId(String name) {
    return num(db.one("SELECT id FROM `user` WHERE user_name=?", name).get("id"));
  }

  private void as(String name) { as(userId(name)); }

  private void as(long id) {
    SecurityContextHolder.getContext().setAuthentication(
        new UsernamePasswordAuthenticationToken(
            new LoginUser(id, "backend-repair-session", "backend-repair-device"), null, List.of()));
  }

  @AfterEach
  void clearAuthentication() { SecurityContextHolder.clearContext(); }

  private String token(String name) {
    var login = users.login(map("user_name", name, "password", "Demo@123456",
        "device_code", "backend-repair-device"));
    return "Bearer " + str(login, "access_token");
  }

  private List<Map<String, Object>> list(Object rows) {
    return (List<Map<String, Object>>) rows;
  }

  private Map<String, Object> object(Object value) {
    return (Map<String, Object>) value;
  }

  private void todayWithoutTeachingPermission(String name) throws Exception {
    String auth = token(name);
    mvc.perform(get("/api/users/me").header("Authorization", auth)).andExpect(status().isOk());
    mvc.perform(get("/api/harmony/cards/today").header("Authorization", auth))
        .andExpect(status().isOk()).andExpect(jsonPath("$.data.timetables").isEmpty())
        // 项目统一把 Long 序列化为字符串，以免 ArkTS 丢失大整数精度。
        .andExpect(jsonPath("$.data.pending_leaves").value("0"))
        .andExpect(jsonPath("$.data.unread_messages").value("0"));
    // 今日卡片可用并不意味着给审批角色追加了教学权限。
    mvc.perform(get("/api/timetables").header("Authorization", auth))
        .andExpect(status().isForbidden());
  }

  @Test
  void counselorTodayCardWorksWithoutTeachingPermission() throws Exception {
    todayWithoutTeachingPermission("counselor_demo");
  }

  @Test
  void deanTodayCardWorksWithoutTeachingPermission() throws Exception {
    todayWithoutTeachingPermission("dean_demo");
  }

  @Test
  void todayPendingCountRespectsCurrentCounselorScope() {
    as("student_demo");
    leaves.create(map("leave_type", "事假", "start_time", now().plusDays(1),
        "end_time", now().plusDays(2), "leave_reason", "内存库回归测试"));
    as("counselor_demo");
    assertEquals(1, num(object(harmony.today()).get("pending_leaves")));
    var pending = list(leaves.pending(map()));
    assertEquals(1, pending.size());
    assertEquals("演示学生", pending.get(0).get("real_name"));
    assertEquals("DEMO_student_demo", pending.get(0).get("user_no"));
    assertFalse(pending.get(0).containsKey("password_hash"));
    db.exec("UPDATE counselor_class SET end_time=? WHERE counselor_id=?",
        now().minusSeconds(1), userId("counselor_demo"));
    assertEquals(0, num(object(harmony.today()).get("pending_leaves")),
        "审批归属失效后不得通过卡片看到旧待办数量");
    assertTrue(list(leaves.pending(map())).isEmpty());
  }

  @Test
  void todayCardOutsideSemesterReturnsEmptyTimetableInsteadOfFailing() {
    as("teacher_demo");
    db.update("semester", 1, map("start_date", now().toLocalDate().minusYears(1),
        "end_date", now().toLocalDate().minusDays(1)));
    assertTrue(list(object(harmony.today()).get("timetables")).isEmpty());
    db.update("semester", 1, map("is_current", 0));
    assertDoesNotThrow(() -> harmony.today());
  }

  private long enroll(String name) {
    as(name);
    return num(enrollment.submit(map("batch_course_id", 1, "request_key", UUID.randomUUID().toString()))
        .get("id"));
  }

  private long correction() {
    long eid = enroll("student_demo");
    as("teacher_demo");
    // 未录入成绩的学生仍必须保留真实 enrollment_id，供教师首次录入。
    var roster = list(grades.classGrades(1, map("teaching_class_id", 1)));
    assertEquals(eid, num(roster.get(0).get("enrollment_id")));
    grades.save(1, map("teaching_class_id", 1, "items",
        List.of(map("enrollment_id", eid, "usual_score", 80, "final_score", 90))));
    long review = num(object(grades.submit(1, map("teaching_class_id", 1))).get("id"));
    as("secretary_demo");
    var batch = list(grades.pending()).get(0);
    assertEquals("Java程序设计", batch.get("course_name"));
    assertEquals("Java程序设计演示班", batch.get("class_name"));
    assertEquals("演示教师", batch.get("submitter_name"));
    var snapshot = list(batch.get("grade_snapshot"));
    assertEquals("演示学生", snapshot.get(0).get("real_name"));
    assertEquals("DEMO_student_demo", snapshot.get(0).get("user_no"));
    assertEquals(86, dec(snapshot.get(0), "total_score").intValue());
    assertFalse(Json.list(db.get("grade_review", review).get("grade_snapshot")).get(0)
        .containsKey("real_name"), "展示附加姓名不能改写数据库中的审核快照");
    grades.review(review, map("decision", 1));
    var grade = db.one("SELECT * FROM grade WHERE enrollment_id=?", eid);
    as("teacher_demo");
    return num(object(grades.change(num(grade.get("id")), map(
        "version", grade.get("version"), "usual_score", 90, "final_score", 90,
        "change_reason", "内存库回归：更正平时分"))).get("id"));
  }

  @Test
  void reviewerDiscoversAndApprovesCorrectionWithoutChangingBatchPendingContract() throws Exception {
    long id = correction();
    as("secretary_demo");
    assertTrue(list(grades.pending()).isEmpty(), "批次待办不混入更正申请");
    var pending = list(grades.pendingChanges());
    assertEquals(1, pending.size());
    var item = pending.get(0);
    assertEquals(id, num(item.get("id")));
    assertEquals("演示学生", item.get("student_name"));
    assertEquals("演示教师", item.get("applicant_name"));
    assertEquals(1, num(item.get("teaching_class_id")));
    assertTrue(item.get("before_value") instanceof Map);
    assertTrue(item.get("after_value") instanceof Map);
    String auth = token("secretary_demo");
    mvc.perform(get("/api/grade-changes/pending").header("Authorization", auth))
        .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].id").value(id));
    mvc.perform(get("/api/grade-changes/" + id).header("Authorization", auth))
        .andExpect(status().isOk()).andExpect(jsonPath("$.data.after_value.total_score").value(90));
    as("secretary_demo");
    grades.decideChange(id, map("decision", 1));
    assertEquals(1, integer(db.get("grade_change", id), "review_status", -1));
    assertTrue(list(grades.pendingChanges()).isEmpty());
    assertEquals(90, dec(db.get("grade", num(item.get("grade_id"))), "total_score").intValue());
  }

  @Test
  void correctionDetailOnlyVisibleToApplicantOrInScopeReviewer() {
    long id = correction();
    as("teacher_demo");
    assertEquals(id, num(object(grades.changeDetail(id)).get("id")));
    assertEquals(403, assertThrows(BizException.class, () -> grades.pendingChanges()).status);
    as("student_demo");
    assertEquals(403, assertThrows(BizException.class, () -> grades.changeDetail(id)).status);
    as("student_two");
    assertEquals(403, assertThrows(BizException.class, () -> grades.changeDetail(id)).status);
    as("admin_demo");
    long unrelatedTeacher = newTeacher();
    as(unrelatedTeacher);
    assertEquals(403, assertThrows(BizException.class, () -> grades.changeDetail(id)).status);
    as("teacher_demo");
    // 角色撤销之后，本人申请也不能继续凭历史身份读取敏感成绩详情。
    db.exec("DELETE FROM role_permission WHERE role_id IN(SELECT id FROM `role` WHERE"
        + " role_code='TEACHER') AND permission_id IN(SELECT id FROM permission"
        + " WHERE permission_code='grade:write')");
    assertEquals(403, assertThrows(BizException.class, () -> grades.changeDetail(id)).status);
  }

  @Test
  void correctionReviewerScopeCannotBeBorrowedFromUnrelatedRole() {
    long id = correction();
    long outsider = db.insert("org_unit", map("parent_id", 1, "org_code", "REPAIR_OUTSIDE",
        "org_name", "其他院系", "org_type", 2));
    long secretary = userId("secretary_demo");
    db.exec("UPDATE user_scope SET org_id=? WHERE user_role_id IN"
        + "(SELECT id FROM user_role WHERE user_id=?)", outsider, secretary);
    long unrelatedRole = db.insert("role", map("role_code", "REPAIR_GLOBAL_TEACHING",
        "role_name", "全校教学只读", "scope_type", 5));
    long readPermission = num(db.one("SELECT id FROM permission WHERE permission_code='teaching:read'")
        .get("id"));
    db.insert("role_permission", map("role_id", unrelatedRole, "permission_id", readPermission));
    db.insert("user_role", map("user_id", secretary, "role_id", unrelatedRole));
    as("secretary_demo");
    assertTrue(list(grades.pendingChanges()).isEmpty());
    assertEquals(403, assertThrows(BizException.class, () -> grades.changeDetail(id)).status);
    assertEquals(403, assertThrows(BizException.class,
        () -> grades.decideChange(id, map("decision", 1))).status);
    assertEquals(0, integer(db.get("grade_change", id), "review_status", -1));
  }

  @Test
  void correctionApplicantWithReviewRoleIsNotOfferedSelfApproval() {
    long id = correction();
    long teacher = userId("teacher_demo");
    long reviewerRole = num(db.one("SELECT id FROM `role` WHERE role_code='SECRETARY'").get("id"));
    long roleLink = db.insert("user_role", map("user_id", teacher, "role_id", reviewerRole));
    db.insert("user_scope", map("user_role_id", roleLink, "org_id", 2, "include_children", 1));
    as("teacher_demo");
    assertTrue(list(grades.pendingChanges()).isEmpty());
    assertEquals(id, num(object(grades.changeDetail(id)).get("id")));
    assertEquals(403, assertThrows(BizException.class,
        () -> grades.decideChange(id, map("decision", 1))).status);
  }

  @Test
  void gradeBatchSubmitterWithReviewRoleIsNotOfferedSelfApproval() {
    long eid = enroll("student_demo");
    as("teacher_demo");
    grades.save(1, map("teaching_class_id", 1, "items",
        List.of(map("enrollment_id", eid, "usual_score", 80, "final_score", 90))));
    long review = num(object(grades.submit(1, map("teaching_class_id", 1))).get("id"));
    long teacher = userId("teacher_demo");
    long reviewerRole = num(db.one("SELECT id FROM `role` WHERE role_code='SECRETARY'").get("id"));
    long roleLink = db.insert("user_role", map("user_id", teacher, "role_id", reviewerRole));
    db.insert("user_scope", map("user_role_id", roleLink, "org_id", 2, "include_children", 1));
    as("teacher_demo");
    assertTrue(list(grades.pending()).isEmpty(), "本人提交的批次不能作为可处理审核待办");
    assertEquals(403, assertThrows(BizException.class,
        () -> grades.review(review, map("decision", 1))).status);
    assertEquals(0, integer(db.get("grade_review", review), "review_status", -1));
    as("secretary_demo");
    var pending = list(grades.pending());
    assertEquals(1, pending.size(), "其他有范围授权的审核人仍能发现该批次");
    assertEquals(review, num(pending.get(0).get("id")));
    grades.review(review, map("decision", 1));
    assertEquals(1, integer(db.get("grade_review", review), "review_status", -1));
  }

  private Map<String, Object> classUpdate(long id) {
    var body = pick(db.get("teaching_class", id), "id", "class_code", "class_name", "course_id",
        "semester_id", "teacher_id", "capacity", "usual_weight", "final_weight", "class_status");
    body.put("confirmed", true);
    return body;
  }

  private long newTeacher() {
    var teacher = object(admin.createUser(map("confirmed", true, "user_name",
        "repair_teacher_" + UUID.randomUUID().toString().substring(0, 8),
        "real_name", "回归测试教师", "password", "RepairDemo@123456", "org_id", 2)));
    long id = num(teacher.get("id"));
    long role = num(db.one("SELECT id FROM `role` WHERE role_code='TEACHER'").get("id"));
    admin.grantUser(id, map("confirmed", true, "role_ids", List.of(role)));
    return id;
  }

  @Test
  void teachingClassExpansionCannotExceedAssignedRoomAndLeavesNoPartialWrite() {
    as("admin_demo");
    var before = db.get("teaching_class", 2);
    long auditBefore = db.count("SELECT COUNT(*) FROM audit_log WHERE action_type='TEACHING_CLASS_SAVE'");
    var update = classUpdate(2);
    update.put("capacity", 51);
    var rejected = assertThrows(BizException.class, () -> admin.teachingClass(update));
    assertEquals(400, rejected.status);
    assertTrue(rejected.getMessage().contains("容量不足"));
    assertEquals(before, db.get("teaching_class", 2), "失败不能修改容量、版本或更新时间");
    assertEquals(auditBefore, db.count("SELECT COUNT(*) FROM audit_log WHERE action_type='TEACHING_CLASS_SAVE'"));
  }

  @Test
  void teachingClassUpdateRevalidatesEveryAssignedTimetable() {
    as("admin_demo");
    long smallerRoom = db.insert("classroom", map("room_code", "REPAIR_SMALL",
        "room_name", "较小教室", "campus_name", "测试校区", "building_name", "测试楼", "capacity", 35));
    var first = db.one("SELECT * FROM timetable WHERE teaching_class_id=2 ORDER BY id LIMIT 1");
    var second = pick(first, "teaching_class_id", "start_week", "end_week", "week_mode",
        "week_day", "start_period", "end_period", "start_time", "end_time");
    second.putAll(map("confirmed", true, "classroom_id", smallerRoom, "week_day", 5));
    admin.timetable(second);
    var before = db.get("teaching_class", 2);
    var update = classUpdate(2);
    update.put("capacity", 40);
    assertEquals(400, assertThrows(BizException.class, () -> admin.teachingClass(update)).status);
    assertEquals(before, db.get("teaching_class", 2));
  }

  @Test
  void teacherChangeCannotIntroduceOverlappingClassesAndRollsBackConfiguration() {
    as("admin_demo");
    long teacherTwo = newTeacher();
    var initialUpdate = classUpdate(2);
    initialUpdate.put("teacher_id", teacherTwo);
    admin.teachingClass(initialUpdate);
    var first = db.one("SELECT * FROM timetable WHERE teaching_class_id=1 ORDER BY id LIMIT 1");
    var second = db.one("SELECT * FROM timetable WHERE teaching_class_id=2 ORDER BY id LIMIT 1");
    var move = pick(first, "start_week", "end_week", "week_mode", "week_day", "start_period",
        "end_period", "start_time", "end_time");
    move.putAll(map("confirmed", true, "id", second.get("id"), "teaching_class_id", 2,
        "classroom_id", 2));
    admin.timetable(move);
    var saved = db.get("timetable", num(second.get("id")));
    assertTrue(ScheduleValidator.overlap(first, saved));
    schedule.validate(saved, num(saved.get("id")));
    var before = db.get("teaching_class", 2);
    var update = classUpdate(2);
    update.put("teacher_id", userId("teacher_demo"));
    var rejected = assertThrows(BizException.class, () -> admin.teachingClass(update));
    assertEquals(409, rejected.status);
    assertTrue(rejected.getMessage().contains("排课冲突"));
    assertEquals(before, db.get("teaching_class", 2));
    assertEquals(saved, db.get("timetable", num(saved.get("id"))));
  }

  @Test
  void legalCapacityAndTeacherChangesStillSucceed() {
    as("admin_demo");
    long otherTeacher = newTeacher();
    var before = db.get("teaching_class", 2);
    var update = classUpdate(2);
    update.putAll(map("capacity", 40, "teacher_id", otherTeacher));
    var saved = object(admin.teachingClass(update));
    assertEquals(40, integer(saved, "capacity", 0));
    assertEquals(otherTeacher, num(saved.get("teacher_id")));
    assertEquals(integer(before, "version", 0) + 1, integer(saved, "version", -1));
    for (var t : db.list("SELECT * FROM timetable WHERE teaching_class_id=2"))
      assertDoesNotThrow(() -> schedule.validate(t, num(t.get("id"))));
  }

  @Test
  void myClassesIncludesNotYetScheduledClassesAndIgnoresWeekFilter() throws Exception {
    as("admin_demo");
    var pending = classUpdate(1);
    pending.remove("id");
    pending.putAll(map("class_code", "REPAIR_NO_TIMETABLE", "class_name", "未排课教学班"));
    long tid = num(object(admin.teachingClass(pending)).get("id"));
    as("teacher_demo");
    var classes = list(teaching.myTeachingClasses(map()));
    assertEquals(4, classes.size());
    assertTrue(classes.stream().anyMatch(c -> eq(c.get("id"), tid)));
    assertTrue(classes.stream().allMatch(c -> eq(c.get("teacher_id"), userId("teacher_demo"))));
    String auth = token("teacher_demo");
    mvc.perform(get("/api/teaching-classes/mine").header("Authorization", auth))
        .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(4))
        .andExpect(jsonPath("$.data[0].usual_weight").exists())
        .andExpect(jsonPath("$.data[0].teacher_name").value("演示教师"));
  }

  @Test
  void myClassesOnlyReturnsOwnActiveEnrollmentAndDoesNotExposeAdminGlobalScope() {
    as("student_demo");
    assertTrue(list(teaching.myTeachingClasses(map())).isEmpty());
    long eid = enroll("student_demo");
    var classes = list(teaching.myTeachingClasses(map()));
    assertEquals(1, classes.size());
    assertEquals(1, num(classes.get(0).get("id")));
    enrollment.drop(eid);
    assertTrue(list(teaching.myTeachingClasses(map())).isEmpty());
    as("student_two");
    assertTrue(list(teaching.myTeachingClasses(map())).isEmpty());
    as("admin_demo");
    assertTrue(list(teaching.myTeachingClasses(map())).isEmpty());
    as("counselor_demo");
    assertEquals(403, assertThrows(BizException.class,
        () -> teaching.myTeachingClasses(map())).status);
  }

  @Test
  void myClassesHonorsSemesterParameter() {
    as("admin_demo");
    long sem = db.insert("semester", map("semester_code", "REPAIR_OLD",
        "semester_name", "历史学期", "start_date", now().toLocalDate().minusYears(1),
        "end_date", now().toLocalDate().minusMonths(6), "week_count", 20));
    var body = classUpdate(1);
    body.remove("id");
    body.putAll(map("class_code", "REPAIR_OLD_CLASS", "semester_id", sem));
    long tid = num(object(admin.teachingClass(body)).get("id"));
    as("teacher_demo");
    assertEquals(3, list(teaching.myTeachingClasses(map())).size());
    var previous = list(teaching.myTeachingClasses(map("semester_id", sem)));
    assertEquals(1, previous.size());
    assertEquals(tid, num(previous.get(0).get("id")));
  }

  @Test
  void submissionNamesDoNotExposeOtherStudentsOrUnpublishedScores() {
    enroll("student_demo");
    enroll("student_two");
    as("teacher_demo");
    long assignment = num(object(teaching.assignment(1, map("teaching_class_id", 1,
        "assignment_title", "隔离回归作业", "content", "测试题目", "max_score", 100,
        "deadline", now().plusDays(1), "publish_status", 1))).get("id"));
    as("student_demo");
    long first = num(object(teaching.submit(assignment, map("content", "学生甲答案"))).get("id"));
    as("student_two");
    teaching.submit(assignment, map("content", "学生乙答案"));
    as("teacher_demo");
    teaching.grade(first, map("action", "grade", "score", 80));
    var all = list(teaching.submissions(assignment));
    assertEquals(2, all.size());
    assertTrue(all.stream().allMatch(s -> s.get("real_name") != null));
    as("student_demo");
    var own = list(teaching.submissions(assignment));
    assertEquals(1, own.size());
    assertEquals("演示学生", own.get(0).get("real_name"));
    assertFalse(own.get(0).containsKey("score"), "未发布分数仍须对学生隐藏");
    assertFalse(own.get(0).containsKey("password_hash"));
  }

  @Test
  void newReadEndpointsStillRequireAuthentication() throws Exception {
    SecurityContextHolder.clearContext();
    mvc.perform(get("/api/teaching-classes/mine")).andExpect(status().isUnauthorized());
    mvc.perform(get("/api/grade-changes/pending")).andExpect(status().isUnauthorized());
    mvc.perform(get("/api/grade-changes/1")).andExpect(status().isUnauthorized());
  }

  @Test
  void attendanceRecordsAddNamesWithoutExposingOtherStudentsOrGeneratingAbsence() {
    enroll("student_demo");
    enroll("student_two");
    long timetable = num(db.one("SELECT id FROM timetable WHERE teaching_class_id=1 LIMIT 1").get("id"));
    long task = db.insert("attendance_task", map("timetable_id", timetable,
        "creator_id", userId("teacher_demo"), "class_date", now().toLocalDate(),
        "start_time", now().minusMinutes(20), "end_time", now().minusMinutes(1),
        "code_hash", Crypto.hash("123456"), "task_status", 1));
    long sid = userId("student_demo");
    db.insert("attendance_record", map("task_id", task, "student_id", sid,
        "sign_status", 1, "sign_time", now().minusMinutes(19)));
    as("teacher_demo");
    var records = list(harmony.records(task));
    assertEquals(1, records.size(), "未签到学生不应被查询接口擅自记为缺勤");
    assertEquals("演示学生", records.get(0).get("real_name"));
    assertEquals("DEMO_student_demo", records.get(0).get("user_no"));
    assertFalse(records.get(0).containsKey("password_hash"));
    as("student_demo");
    assertEquals(1, list(harmony.records(task)).size());
    as("student_two");
    assertTrue(list(harmony.records(task)).isEmpty());
    as("student_other");
    assertEquals(403, assertThrows(BizException.class, () -> harmony.records(task)).status);
    assertEquals(1, db.count("SELECT COUNT(*) FROM attendance_record WHERE task_id=?", task));
  }
}
