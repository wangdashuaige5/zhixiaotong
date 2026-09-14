package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.ReportService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/tasks")
public class ReportController {
  private final ReportService s;

  public ReportController(ReportService s) {
    this.s = s;
  }

  @PostMapping
  public Result create(@RequestBody Map<String, Object> b) {
    return Result.success(s.create(b));
  }

  @GetMapping("/{id}")
  public Result task(@PathVariable long id) {
    return Result.success(s.task(id));
  }

  @PostMapping("/{id}/confirm")
  public Result confirm(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.confirm(id, b));
  }
}
