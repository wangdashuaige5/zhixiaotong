package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.TeachingService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class TeachingController {
  private final TeachingService s;

  public TeachingController(TeachingService s) {
    this.s = s;
  }

  @GetMapping("/timetables")
  public Result timetable(@RequestParam Map<String, Object> q) {
    return Result.success(s.timetables(q));
  }

  @GetMapping("/courses/{id}")
  public Result course(@PathVariable long id, @RequestParam Map<String, Object> q) {
    return Result.success(s.course(id, q));
  }

  @GetMapping("/exams/me")
  public Result exams(@RequestParam Map<String, Object> q) {
    return Result.success(s.exams(q));
  }

  @PostMapping("/enrollments/{id}/evaluation")
  public Result evaluation(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.evaluation(id, b));
  }

  @GetMapping("/courses/{id}/resources")
  public Result resources(@PathVariable long id, @RequestParam Map<String, Object> q) {
    return Result.success(s.resources(id, q));
  }

  @GetMapping("/courses/{id}/leaves")
  public Result leaves(@PathVariable long id, @RequestParam Map<String, Object> q) {
    return Result.success(s.leaves(id, q));
  }

  @PostMapping("/courses/{id}/resources")
  public Result resource(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.resource(id, b));
  }

  @GetMapping("/courses/{id}/assignments")
  public Result assignments(@PathVariable long id, @RequestParam Map<String, Object> q) {
    return Result.success(s.assignments(id, q));
  }

  @PostMapping("/courses/{id}/assignments")
  public Result assignment(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.assignment(id, b));
  }

  @PostMapping("/assignments/{id}/submissions")
  public Result submit(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.submit(id, b));
  }

  @GetMapping("/assignments/{id}/submissions")
  public Result submissions(@PathVariable long id) {
    return Result.success(s.submissions(id));
  }

  @PutMapping("/submissions/{id}/grade")
  public Result grade(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.grade(id, b));
  }
}
