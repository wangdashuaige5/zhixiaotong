package com.zhixiaotong;

import static com.zhixiaotong.common.Data.*;
import static org.junit.jupiter.api.Assertions.*;
import com.zhixiaotong.common.Db;
import com.zhixiaotong.config.SoftwareEngineeringDemoData;
import com.zhixiaotong.service.ScheduleValidator;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest(properties={"spring.datasource.url=jdbc:h2:mem:software_demo_test;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1;NON_KEYWORDS=USER",
  "spring.datasource.username=sa","spring.datasource.password=","spring.datasource.driver-class-name=org.h2.Driver","spring.flyway.enabled=false","campus.jobs-enabled=false"})
@ActiveProfiles({"demo","test"}) @Transactional
class SoftwareDemoDataTest {
  @Autowired Db db;
  @Autowired ScheduleValidator schedules;
  void seed() { new SoftwareEngineeringDemoData(db,schedules).run(new DefaultApplicationArguments()); }
  @Test void createsConnectedUniversityDatasetWithoutOverwritingAndDoesNotRepeat() {
    var before=db.one("SELECT * FROM `user` WHERE user_name='student_demo'");
    long users=db.count("SELECT COUNT(*) FROM `user`");
    seed();
    assertEquals(users+26,db.count("SELECT COUNT(*) FROM `user`"));
    assertEquals(8,db.count("SELECT COUNT(*) FROM course WHERE course_code LIKE 'SE26_C%'"));
    assertEquals(162,db.count("SELECT COUNT(*) FROM enrollment WHERE request_key LIKE 'SE26_REQUIRED_%'"));
    assertEquals(24,db.count("SELECT COUNT(*) FROM assignment a JOIN teaching_class tc ON tc.id=a.teaching_class_id WHERE tc.class_code LIKE 'SE26_T%'"));
    assertEquals(36,db.count("SELECT COUNT(*) FROM book_copy WHERE copy_no LIKE 'SE26_COPY_%'"));
    assertEquals(before,db.one("SELECT * FROM `user` WHERE user_name='student_demo'"));
    long enrollments=db.count("SELECT COUNT(*) FROM enrollment"), submissions=db.count("SELECT COUNT(*) FROM submission");
    seed();
    assertEquals(users+26,db.count("SELECT COUNT(*) FROM `user`"));
    assertEquals(enrollments,db.count("SELECT COUNT(*) FROM enrollment"));
    assertEquals(submissions,db.count("SELECT COUNT(*) FROM submission"));
  }
  @Test void seededRostersMatchCapacityAndTimetablesHaveNoStudentTeacherRoomConflicts() {
    seed();
    for(var tc:db.list("SELECT * FROM teaching_class WHERE class_code LIKE 'SE26_T%'")) {
      assertEquals(db.count("SELECT COUNT(*) FROM enrollment WHERE teaching_class_id=? AND enroll_status=1",tc.get("id")),num(tc.get("enrolled_count")));
      assertTrue(num(tc.get("capacity"))>=num(tc.get("enrolled_count")));
      for(var row:db.list("SELECT * FROM timetable WHERE teaching_class_id=?",tc.get("id"))) schedules.validate(row,num(row.get("id")));
      for(var e:db.list("SELECT * FROM enrollment WHERE teaching_class_id=?",tc.get("id"))) schedules.studentConflict(num(e.get("student_id")),num(tc.get("id")));
    }
    assertEquals(0,db.count("SELECT COUNT(*) FROM grade g JOIN enrollment e ON e.id=g.enrollment_id WHERE e.request_key LIKE 'SE26_REQUIRED_%' AND g.grade_status<>0"));
  }
}
