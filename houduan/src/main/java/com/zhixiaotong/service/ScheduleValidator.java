package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import org.springframework.stereotype.Service;

@Service
public class ScheduleValidator {
  private final Db db;

  public ScheduleValidator(Db db) {
    this.db = db;
  }

  public static boolean active(Map<String, Object> t, int week, int day) {
    int mode = integer(t, "week_mode", 1);
    return week >= integer(t, "start_week", 1)
        && week <= integer(t, "end_week", 1)
        && integer(t, "week_day", 1) == day
        && (mode == 1 || (mode == 2 && week % 2 == 1) || (mode == 3 && week % 2 == 0));
  }

  public static boolean overlap(Map<String, Object> a, Map<String, Object> b) {
    if (integer(a, "week_day", 0) != integer(b, "week_day", 0)) return false;
    if (!clock(a.get("start_time")).isBefore(clock(b.get("end_time")))
        || !clock(b.get("start_time")).isBefore(clock(a.get("end_time")))) return false;
    int low = Math.max(integer(a, "start_week", 1), integer(b, "start_week", 1)),
        high = Math.min(integer(a, "end_week", 1), integer(b, "end_week", 1));
    for (int w = low; w <= high; w++)
      if (active(a, w, integer(a, "week_day", 1)) && active(b, w, integer(b, "week_day", 1)))
        return true;
    return false;
  }

  public void studentConflict(long student, long teachingClass) {
    var target = db.get("teaching_class", teachingClass);
    var own =
        db.list(
            "SELECT t.* FROM timetable t JOIN enrollment e ON"
                + " e.teaching_class_id=t.teaching_class_id JOIN teaching_class tc ON"
                + " tc.id=t.teaching_class_id WHERE e.student_id=? AND e.enroll_status=1 AND"
                + " tc.semester_id=? AND tc.id<>?",
            student,
            target.get("semester_id"),
            teachingClass);
    for (var a : db.list("SELECT * FROM timetable WHERE teaching_class_id=?", teachingClass))
      for (var b : own) check(!overlap(a, b), 409, "与已选课程时间冲突");
  }

  public void validate(Map<String, Object> row, Long ignoreId) {
    var tc = db.get("teaching_class", id(row, "teaching_class_id"));
    validate(row, ignoreId, tc);
  }

  /** 使用待保存的教学班配置复核排课，不先写库，避免换教师或扩容绕过排课约束。 */
  public void validate(Map<String, Object> row, Long ignoreId, Map<String, Object> tc) {
    check(eq(row.get("teaching_class_id"), tc.get("id")), 400, "教学班与排课不一致");
    var sem = db.get("semester", num(tc.get("semester_id")));
    var room = db.get("classroom", id(row, "classroom_id"));
    check(integer(sem, "is_locked", 0) == 0, 409, "学期已锁定");
    check(
        integer(room, "is_enabled", 0) == 1
            && integer(room, "capacity", 0) >= integer(tc, "capacity", 0),
        400,
        "教室未启用或容量不足");
    int start = integer(row, "start_week", 0), end = integer(row, "end_week", 0);
    range(start, 1, integer(sem, "week_count", 0), "start_week");
    range(end, start, integer(sem, "week_count", 0), "end_week");
    range(integer(row, "week_mode", 1), 1, 3, "week_mode");
    range(integer(row, "week_day", 0), 1, 7, "week_day");
    range(integer(row, "start_period", 0), 1, 20, "start_period");
    range(integer(row, "end_period", 0), integer(row, "start_period", 0), 20, "end_period");
    check(clock(row.get("start_time")).isBefore(clock(row.get("end_time"))), 400, "结束时刻必须晚于开始");
    for (var other :
        db.list(
            "SELECT t.* FROM timetable t JOIN teaching_class tc ON t.teaching_class_id=tc.id WHERE"
                + " tc.semester_id=? AND (tc.teacher_id=? OR t.classroom_id=? OR tc.id=?)",
            tc.get("semester_id"),
            tc.get("teacher_id"),
            row.get("classroom_id"),
            tc.get("id")))
      if (ignoreId == null || !eq(other.get("id"), ignoreId))
        check(!overlap(row, other), 409, "教师或教室排课冲突");
  }

  public int week(Map<String, Object> semester, LocalDate day) {
    return (int)
            Math.floorDiv(
                ChronoUnit.DAYS.between(
                    date(semester.get("start_date")).with(java.time.DayOfWeek.MONDAY), day),
                7)
        + 1;
  }

  /** 请假与实际上课日期相交，考虑学期、周次、单双周和半开时间区间。 */
  public boolean affected(long teachingClass, Map<String, Object> leave) {
    var tc = db.get("teaching_class", teachingClass);
    var sem = db.get("semester", num(tc.get("semester_id")));
    var start = time(leave.get("start_time"));
    var end = time(leave.get("end_time"));
    var first =
        start.toLocalDate().isBefore(date(sem.get("start_date")))
            ? date(sem.get("start_date"))
            : start.toLocalDate();
    var last =
        end.toLocalDate().isAfter(date(sem.get("end_date")))
            ? date(sem.get("end_date"))
            : end.toLocalDate();
    var rows = db.list("SELECT * FROM timetable WHERE teaching_class_id=?", teachingClass);
    for (var day = first; !day.isAfter(last); day = day.plusDays(1))
      for (var t : rows) {
        if (active(t, week(sem, day), day.getDayOfWeek().getValue())
            && day.atTime(clock(t.get("start_time"))).isBefore(end)
            && start.isBefore(day.atTime(clock(t.get("end_time"))))) return true;
      }
    return false;
  }
}
