package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.AdminService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
public class AdminController {
  private final AdminService s;

  public AdminController(AdminService s) {
    this.s = s;
  }

  @GetMapping("/orgs")
  public Result orgs() {
    return Result.success(s.orgs());
  }

  @PostMapping("/orgs")
  public Result org(@RequestBody Map<String, Object> b) {
    return Result.success(s.org(b));
  }

  @GetMapping("/users")
  public Result users(@RequestParam Map<String, Object> q) {
    return Result.success(s.users(q));
  }

  @PostMapping("/users")
  public Result createUser(@RequestBody Map<String, Object> b) {
    return Result.success(s.createUser(b));
  }

  @PutMapping("/users/{id}")
  public Result user(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.updateUser(id, b));
  }

  @PutMapping("/users/{id}/roles")
  public Result grant(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.grantUser(id, b));
  }

  @PutMapping("/roles/{id}")
  public Result role(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.role(id, b));
  }

  @GetMapping("/audit-logs")
  public Result audit(@RequestParam Map<String, Object> q) {
    return Result.success(s.audit(q));
  }

  @PostMapping("/semesters")
  public Result semester(@RequestBody Map<String, Object> b) {
    return Result.success(s.semester(b));
  }

  @PostMapping("/teaching-classes")
  public Result teachingClass(@RequestBody Map<String, Object> b) {
    return Result.success(s.teachingClass(b));
  }

  @PostMapping("/timetables")
  public Result timetable(@RequestBody Map<String, Object> b) {
    return Result.success(s.timetable(b));
  }

  @PostMapping("/selection-batches")
  public Result batch(@RequestBody Map<String, Object> b) {
    return Result.success(s.batch(b));
  }

  @GetMapping("/data/{resource}")
  public Result data(@PathVariable String resource, @RequestParam Map<String, Object> q) {
    return Result.success(s.catalog(resource, q));
  }

  @PostMapping("/data/{resource}")
  public Result base(@PathVariable String resource, @RequestBody Map<String, Object> b) {
    return Result.success(s.base(resource, b));
  }

  @GetMapping("/reports/summary")
  public Result summary() {
    return Result.success(s.summary());
  }
}
