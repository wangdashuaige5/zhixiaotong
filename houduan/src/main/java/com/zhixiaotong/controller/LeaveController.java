package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.LeaveService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/leaves")
public class LeaveController {
  private final LeaveService s;

  public LeaveController(LeaveService s) {
    this.s = s;
  }

  @PostMapping
  public Result create(@RequestBody Map<String, Object> b) {
    return Result.success(s.create(b));
  }

  @GetMapping("/me")
  public Result mine(@RequestParam Map<String, Object> q) {
    return Result.success(s.mine(q));
  }

  @GetMapping("/pending")
  public Result pending(@RequestParam Map<String, Object> q) {
    return Result.success(s.pending(q));
  }

  @GetMapping("/{id}")
  public Result detail(@PathVariable long id) {
    return Result.success(s.detail(id));
  }

  @PutMapping("/{id}")
  public Result edit(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.edit(id, b));
  }

  @PostMapping("/{id}/approve")
  public Result approve(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.approve(id, b));
  }

  @PostMapping("/{id}/withdraw")
  public Result withdraw(@PathVariable long id) {
    return Result.success(s.withdraw(id));
  }

  @PostMapping("/{id}/close")
  public Result close(@PathVariable long id) {
    return Result.success(s.close(id));
  }
}
