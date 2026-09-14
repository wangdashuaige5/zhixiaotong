package com.zhixiaotong.controller;

import com.zhixiaotong.common.*;
import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.LifeService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class LifeController {
  private final LifeService s;

  public LifeController(LifeService s) {
    this.s = s;
  }

  @GetMapping("/cards/balance")
  public Result balance() {
    return Result.success(s.balance());
  }

  @PostMapping("/cards/recharges")
  public Result recharge(@RequestBody Map<String, Object> b) {
    return Result.success(s.recharge(b));
  }

  @GetMapping("/cards/recharges/{id}")
  public Result order(@PathVariable long id) {
    return Result.success(s.order(id));
  }

  @GetMapping("/cards/transactions")
  public Result transactions(@RequestParam Map<String, Object> q) {
    return Result.success(s.transactions(q));
  }

  @PostMapping("/integrations/payments/callback")
  public Result callback(
      @RequestBody String raw,
      @RequestHeader("X-Payment-Timestamp") String timestamp,
      @RequestHeader("X-Payment-Signature") String signature) {
    s.verifySignature(raw, timestamp, signature);
    var r = (Map<String, Object>) s.callback(Json.object(raw));
    if (Data.integer(r, "order_status", 0) == 1)
      return Result.success(s.post(Data.num(r.get("id"))));
    return Result.success(r);
  }

  @GetMapping("/library/books")
  public Result books(@RequestParam Map<String, Object> q) {
    return Result.success(s.books(q));
  }

  @GetMapping("/library/loans/me")
  public Result loans(@RequestParam Map<String, Object> q) {
    return Result.success(s.loans(q));
  }

  @PostMapping("/library/loans/{id}/renew")
  public Result renew(@PathVariable long id) {
    return Result.success(s.renew(id));
  }

  @PostMapping("/library/reservations")
  public Result reserve(@RequestBody Map<String, Object> b) {
    return Result.success(s.reserve(b));
  }

  @GetMapping("/library/reservations/me")
  public Result reservations(@RequestParam Map<String, Object> q) {
    return Result.success(s.reservations(q));
  }

  @DeleteMapping("/library/reservations/{id}")
  public Result cancel(@PathVariable long id) {
    s.cancel(id);
    return Result.success(null);
  }
}
