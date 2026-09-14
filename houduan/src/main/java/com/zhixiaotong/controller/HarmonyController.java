package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.HarmonyService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class HarmonyController {
  private final HarmonyService s;

  public HarmonyController(HarmonyService s) {
    this.s = s;
  }

  @GetMapping("/harmony/cards/today")
  public Result today() {
    return Result.success(s.today());
  }

  @PostMapping("/devices")
  public Result device(@RequestBody Map<String, Object> b) {
    return Result.success(s.register(b));
  }

  @PostMapping("/devices/{id}/revoke")
  public Result revokeDevice(@PathVariable long id) {
    s.revokeDevice(id);
    return Result.success(null);
  }

  @PostMapping("/harmony/continuations")
  public Result create(@RequestBody Map<String, Object> b) {
    return Result.success(s.continuation(b));
  }

  @PostMapping("/harmony/continuations/{id}/accept")
  public Result accept(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.accept(id, b));
  }

  @PostMapping("/harmony/continuations/{id}/finish")
  public Result finish(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.finish(id, b));
  }

  @PostMapping("/attendance/tasks")
  public Result attendance(@RequestBody Map<String, Object> b) {
    return Result.success(s.attendance(b));
  }

  @PostMapping("/attendance/tasks/{id}/sign")
  public Result sign(@PathVariable long id, @RequestBody Map<String, Object> b) {
    return Result.success(s.sign(id, b));
  }

  @GetMapping("/attendance/tasks/{id}/records")
  public Result records(@PathVariable long id) {
    return Result.success(s.records(id));
  }
}
