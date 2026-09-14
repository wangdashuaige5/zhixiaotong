package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.GradeService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class GradeController {
  private final GradeService s;

  public GradeController(GradeService s) {
    this.s = s;
  }

  @PutMapping("/courses/{id}/grades")
  public Result save(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.save(id, b));
  }

  @GetMapping("/courses/{id}/grades")
  public Result classGrades(@PathVariable long id, @RequestParam Map<String, Object> q) {
    return Result.success(s.classGrades(id, q));
  }

  @PostMapping("/courses/{id}/grades/submit")
  public Result submit(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.submit(id, b));
  }

  @PostMapping("/grade-reviews/{id}")
  public Result review(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.review(id, b));
  }

  @GetMapping("/grade-reviews/pending")
  public Result pending() {
    return Result.success(s.pending());
  }

  @GetMapping("/grades/me")
  public Result mine(@RequestParam Map<String, Object> q) {
    return Result.success(s.mine(q));
  }

  @PostMapping("/grades/{id}/changes")
  public Result change(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.change(id, b));
  }

  @PostMapping("/grade-changes/{id}/decision")
  public Result decide(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.decideChange(id, b));
  }
}
