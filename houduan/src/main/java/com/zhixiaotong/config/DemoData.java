package com.zhixiaotong.config;

import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.Db;
import com.zhixiaotong.security.Crypto;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** 仅空库且显式 demo 配置时创建虚构演示数据，不覆盖使用者已有数据。 */
@Component
@Profile("demo")
@ConditionalOnProperty(name = "campus.demo-seed", havingValue = "true")
public class DemoData implements ApplicationRunner {
  private final Db db;

  public DemoData(Db db) {
    this.db = db;
  }

  @Override
  @Transactional
  public void run(ApplicationArguments args) {
    if (db.count("SELECT COUNT(*) FROM `user`") != 0
        || db.count("SELECT COUNT(*) FROM org_unit") != 0) return;
    long school =
        db.insert("org_unit", map("org_code", "DEMO", "org_name", "智校通演示学校", "org_type", 1));
    long dept =
        db.insert(
            "org_unit",
            map("parent_id", school, "org_code", "CS", "org_name", "信息工程学院", "org_type", 2));
    long major =
        db.insert(
            "org_unit",
            map("parent_id", dept, "org_code", "SOFTWARE", "org_name", "软件技术", "org_type", 3));
    long grade =
        db.insert(
            "org_unit",
            map("parent_id", major, "org_code", "DEMO_GRADE", "org_name", "演示年级", "org_type", 4));
    long cls =
        db.insert(
            "school_class",
            map(
                "class_code",
                "SOFT_01",
                "class_name",
                "软件一班",
                "grade_id",
                grade,
                "entry_year",
                now().getYear(),
                "school_years",
                3));
    long cls2 =
        db.insert(
            "school_class",
            map(
                "class_code",
                "SOFT_02",
                "class_name",
                "软件二班",
                "grade_id",
                grade,
                "entry_year",
                now().getYear(),
                "school_years",
                3));
    String all =
        "teaching:read teaching:write enrollment:write grade:write grade:review leave:write"
            + " leave:counselor leave:dean life:write affairs:write affairs:apply affairs:handle"
            + " aid:review focus:write focus:read notice:read notice:publish device:write"
            + " attendance:write attendance:sign file:write admin:read admin:write admin:grant"
            + " audit:read report:export";
    Map<String, Long> permissions = new LinkedHashMap<>();
    for (String p : all.split(" "))
      permissions.put(
          p,
          db.insert(
              "permission", map("permission_code", p, "permission_name", p, "permission_type", 3)));
    long student =
        role(
            "STUDENT",
            "学生",
            1,
            "teaching:read enrollment:write leave:write life:write affairs:apply notice:read"
                + " device:write attendance:sign file:write",
            permissions);
    long teacher =
        role(
            "TEACHER",
            "任课教师",
            2,
            "teaching:read teaching:write grade:write notice:read notice:publish device:write"
                + " attendance:write file:write report:export",
            permissions);
    long counselor =
        role(
            "COUNSELOR",
            "辅导员",
            3,
            "affairs:write affairs:handle aid:review focus:write focus:read leave:counselor"
                + " notice:read notice:publish file:write device:write",
            permissions);
    long admin =
        role(
            "ADMIN",
            "管理员",
            5,
            all.replace("focus:write ", "").replace("focus:read ", ""),
            permissions);
    long secretary =
        role(
            "SECRETARY",
            "教学秘书",
            4,
            "grade:review teaching:read notice:read file:write report:export",
            permissions);
    long dean =
        role(
            "DEAN",
            "院系负责人",
            4,
            "leave:dean affairs:handle aid:review notice:read notice:publish file:write",
            permissions);
    long s = user("student_demo", "演示学生", grade, cls, student);
    long t = user("teacher_demo", "演示教师", dept, null, teacher);
    long c = user("counselor_demo", "演示辅导员", dept, null, counselor);
    user("admin_demo", "演示管理员", school, null, admin);
    long sec = user("secretary_demo", "演示教学秘书", dept, null, secretary);
    long d = user("dean_demo", "演示院系负责人", dept, null, dean);
    user("student_two", "演示学生乙", grade, cls, student);
    user("student_other", "其他班级学生", grade, cls2, student);
    scope(sec, dept);
    scope(d, dept);
    db.insert(
        "counselor_class",
        map("counselor_id", c, "class_id", cls, "start_time", now().minusYears(1)));
    LocalDate monday = now().toLocalDate().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    long semester =
        db.insert(
            "semester",
            map(
                "semester_code",
                "DEMO_CURRENT",
                "semester_name",
                "当前演示学期",
                "start_date",
                monday,
                "end_date",
                monday.plusWeeks(20).minusDays(1),
                "week_count",
                20,
                "is_current",
                1));
    long room =
        db.insert(
            "classroom",
            map(
                "room_code",
                "A101",
                "room_name",
                "A101",
                "campus_name",
                "主校区",
                "building_name",
                "教学楼A",
                "capacity",
                50));
    long room2 =
        db.insert(
            "classroom",
            map(
                "room_code",
                "B201",
                "room_name",
                "B201",
                "campus_name",
                "主校区",
                "building_name",
                "教学楼B",
                "capacity",
                50));
    long batch =
        db.insert(
            "selection_batch",
            map(
                "batch_code",
                "DEMO_OPEN",
                "batch_name",
                "演示补退选",
                "semester_id",
                semester,
                "batch_stage",
                3,
                "start_time",
                now().minusDays(1),
                "end_time",
                now().plusDays(14),
                "drop_deadline",
                now().plusDays(14),
                "max_courses",
                5,
                "max_credits",
                20,
                "batch_status",
                1));
    String[] names = {"Java程序设计", "数据库技术", "Web应用开发"};
    for (int i = 0; i < names.length; i++) {
      long course =
          db.insert(
              "course",
              map(
                  "course_code",
                  "DEMO_C" + (i + 1),
                  "course_name",
                  names[i],
                  "org_id",
                  dept,
                  "course_type",
                  "专业课",
                  "credit",
                  3,
                  "total_hours",
                  48,
                  "syllabus",
                  "演示课程大纲，可由管理接口维护"));
      long tc =
          db.insert(
              "teaching_class",
              map(
                  "class_code",
                  "DEMO_T" + (i + 1),
                  "course_id",
                  course,
                  "semester_id",
                  semester,
                  "teacher_id",
                  t,
                  "class_name",
                  names[i] + "演示班",
                  "capacity",
                  30));
      db.insert(
          "timetable",
          map(
              "teaching_class_id",
              tc,
              "classroom_id",
              i == 2 ? room2 : room,
              "start_week",
              1,
              "end_week",
              20,
              "week_day",
              i + 1,
              "start_period",
              1,
              "end_period",
              2,
              "start_time",
              LocalTime.of(9, 0),
              "end_time",
              LocalTime.of(10, 30)));
      long bc = db.insert("batch_course", map("batch_id", batch, "teaching_class_id", tc));
      db.insert(
          "selection_scope", map("batch_course_id", bc, "org_id", dept, "include_children", 1));
    }
    db.insert(
        "card_account",
        map("user_id", s, "card_no", "MOCK-CARD-001", "balance", 100, "sync_time", now()));
    for (int i = 1; i <= 2; i++) {
      long book =
          db.insert(
              "book",
              map(
                  "book_code",
                  "DEMO_B" + i,
                  "book_name",
                  i == 1 ? "Java入门演示书目" : "数据库入门演示书目",
                  "author",
                  "演示作者",
                  "category_code",
                  "COMPUTER"));
      long copy =
          db.insert(
              "book_copy",
              map(
                  "book_id",
                  book,
                  "copy_no",
                  "DEMO_COPY" + i,
                  "location",
                  "图书馆三楼",
                  "copy_status",
                  i == 2 ? 1 : 0));
      if (i == 2)
        db.insert(
            "book_loan",
            map(
                "reader_id",
                s,
                "copy_id",
                copy,
                "external_loan_no",
                "MOCK_LOAN_001",
                "borrow_time",
                now().minusDays(2),
                "due_time",
                now().plusDays(28)));
    }
    db.insert(
        "aid_batch",
        map(
            "batch_name",
            "演示助学金",
            "aid_type",
            "助学金",
            "org_id",
            dept,
            "semester_id",
            semester,
            "start_time",
            now().minusDays(1),
            "end_time",
            now().plusDays(14),
            "quota",
            1,
            "aid_amount",
            1000,
            "requirements",
            "仅用于验证申请审批流程，不代表真实资助政策",
            "batch_status",
            1));
  }

  private long role(
      String code, String name, int scope, String allowed, Map<String, Long> permissions) {
    long id = db.insert("role", map("role_code", code, "role_name", name, "scope_type", scope));
    for (String p : allowed.split(" "))
      db.insert("role_permission", map("role_id", id, "permission_id", permissions.get(p)));
    return id;
  }

  private long user(String name, String real, long org, Long cls, long role) {
    long id =
        db.insert(
            "user",
            map(
                "user_name",
                name,
                "real_name",
                real,
                "user_no",
                "DEMO_" + name,
                "password_hash",
                Crypto.password("Demo@123456"),
                "org_id",
                org,
                "class_id",
                cls));
    db.insert("user_role", map("user_id", id, "role_id", role));
    return id;
  }

  private void scope(long user, long org) {
    var ur = db.one("SELECT id FROM user_role WHERE user_id=?", user);
    db.insert(
        "user_scope", map("user_role_id", ur.get("id"), "org_id", org, "include_children", 1));
  }
}
