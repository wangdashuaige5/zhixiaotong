package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.AffairsService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class AffairsController {
  private final AffairsService s;

  public AffairsController(AffairsService s) {
    this.s = s;
  }

  @GetMapping("/counselor/classes")
  public Result classes() {
    return Result.success(s.classes());
  }

  @PostMapping("/student-affairs/records")
  public Result record(@RequestBody Map<String, Object> b) {
    return Result.success(s.record(b));
  }

  @PostMapping("/student-affairs/records/{id}/revoke")
  public Result revoke(@PathVariable long id, @RequestBody Map<String, Object> b) {
    s.revokeRecord(id, b);
    return Result.success(null);
  }

  @PostMapping("/dorm-checks")
  public Result dorm(@RequestBody Map<String, Object> b) {
    return Result.success(s.dorm(b));
  }

  @PostMapping("/student-focuses")
  public Result focus(@RequestBody Map<String, Object> b) {
    return Result.success(s.focus(b));
  }

  @GetMapping("/student-focuses/{id}")
  public Result focusDetail(@PathVariable long id) {
    return Result.success(s.focusDetail(id));
  }

  @PutMapping("/student-focuses/{id}")
  public Result follow(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.followUp(id, b));
  }

  @PostMapping("/aid-applications")
  public Result aid(@RequestBody Map<String, Object> b) {
    return Result.success(s.applyAid(b));
  }

  @GetMapping("/aid-batches")
  public Result batches() {
    return Result.success(s.batches());
  }

  @PostMapping("/aid-reviews/{id}/decision")
  public Result review(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.reviewAid(id, b));
  }

  @PostMapping("/service-applications")
  public Result apply(@RequestBody Map<String, Object> b) {
    return Result.success(s.applyService(b));
  }

  @PostMapping("/service-steps/{id}/decision")
  public Result decide(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.decideStep(id, b));
  }

  @GetMapping("/student-affairs/me")
  public Result mine() {
    return Result.success(s.mine());
  }

  @GetMapping("/student-affairs/pending")
  public Result pending() {
    return Result.success(s.pending());
  }
}
