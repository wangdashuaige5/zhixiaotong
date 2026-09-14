package com.zhixiaotong.controller;

import com.zhixiaotong.common.*;
import com.zhixiaotong.dto.Result;
import com.zhixiaotong.security.Access;
import com.zhixiaotong.service.IEnrollmentService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class EnrollmentController {
  private final IEnrollmentService service;
  private final Access access;
  private final Db db;

  public EnrollmentController(IEnrollmentService service, Access access, Db db) {
    this.service = service;
    this.access = access;
    this.db = db;
  }

  @GetMapping("/enrollments/options")
  public Result options(@RequestParam Map<String, Object> q) {
    return Result.success(service.options(q));
  }

  @GetMapping("/enrollments/batches")
  public Result batches() {
    return Result.success(service.batches());
  }

  @GetMapping("/semesters")
  public Result semesters() {
    access.require("teaching:read");
    return Result.success(
        db.list(
            "SELECT id,semester_name,start_date,end_date,week_count,is_current,is_locked FROM"
                + " semester ORDER BY start_date DESC"));
  }

  @GetMapping("/enrollments/me")
  public Result mine(@RequestParam Map<String, Object> q) {
    return Result.success(service.mine(q));
  }

  @PostMapping("/enrollments")
  public Result submit(@RequestBody Map<String, Object> b) {
    return Result.success(service.submit(b));
  }

  @DeleteMapping("/enrollments/{id}")
  public Result drop(@PathVariable long id) {
    return Result.success(service.drop(id));
  }

  @PostMapping("/admin/batch-courses/{id}/settle")
  public Result settle(@PathVariable long id, @RequestBody Map<String, Object> b) {
    access.confirmed(b);
    var bc = db.get("batch_course", id);
    var tc = db.get("teaching_class", Data.num(bc.get("teaching_class_id")));
    var c = db.get("course", Data.num(tc.get("course_id")));
    access.org(Data.num(c.get("org_id")), "admin:write");
    service.settle(id);
    return Result.success(null);
  }
}
