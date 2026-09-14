package com.zhixiaotong.controller;

import com.zhixiaotong.common.Data;
import com.zhixiaotong.dto.Result;
import com.zhixiaotong.security.*;
import com.zhixiaotong.service.IUserService;
import java.util.Map;
import org.springframework.web.bind.annotation.*;

/** 示例UserController的智校通版本；采用明确HTTP方法与JSON请求。 */
@RestController
@RequestMapping("/api")
public class UserController {
  private final IUserService users;
  private final TokenService tokens;
  private final Access access;

  public UserController(IUserService users, TokenService tokens, Access access) {
    this.users = users;
    this.tokens = tokens;
    this.access = access;
  }

  @PostMapping("/auth/login")
  public Result login(@RequestBody Map<String, Object> b) {
    return Result.success(users.login(b));
  }

  @PostMapping("/auth/refresh")
  public Result refresh(@RequestBody Map<String, Object> b) {
    return Result.success(tokens.refresh(Data.text(b, "refresh_token", 256)));
  }

  @PostMapping("/auth/logout")
  public Result logout() {
    tokens.logout(access.current());
    return Result.success(null);
  }

  @GetMapping("/users/me")
  public Result me() {
    return Result.success(users.me());
  }

  @PutMapping("/users/profile")
  public Result profile(@RequestBody Map<String, Object> b) {
    return Result.success(users.profile(b));
  }

  @PutMapping("/users/password")
  public Result password(@RequestBody Map<String, Object> b) {
    users.password(b);
    return Result.success(null);
  }
}
