package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.NoticeService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class NoticeController {
  private final NoticeService s;

  public NoticeController(NoticeService s) {
    this.s = s;
  }

  @GetMapping("/notices")
  public Result list(@RequestParam Map<String, Object> q) {
    return Result.success(s.list(q));
  }

  @GetMapping("/notices/{id}")
  public Result detail(@PathVariable long id) {
    return Result.success(s.detail(id));
  }

  @PostMapping("/notices")
  public Result create(@RequestBody Map<String, Object> b) {
    return Result.success(s.create(b));
  }

  @PostMapping("/notices/{id}/ack")
  public Result ack(@PathVariable long id) {
    return Result.success(s.ack(id));
  }

  @PostMapping("/notices/{id}/withdraw")
  public Result withdraw(@PathVariable long id) {
    s.withdraw(id);
    return Result.success(null);
  }

  @GetMapping("/messages")
  public Result messages(@RequestParam Map<String, Object> q) {
    return Result.success(s.messages(q));
  }

  @PostMapping("/messages/{id}/read")
  public Result read(@PathVariable long id) {
    s.read(id);
    return Result.success(null);
  }
}
