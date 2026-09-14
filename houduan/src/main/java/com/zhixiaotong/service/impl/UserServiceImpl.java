package com.zhixiaotong.service.impl;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import com.zhixiaotong.service.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements IUserService {
  private final Db db;
  private final Access access;
  private final TokenService tokens;
  private final Crypto crypto;
  private final AuditService audit;
  private static final String DUMMY = Crypto.password("dummy-password-for-timing");

  public UserServiceImpl(
      Db db, Access access, TokenService tokens, Crypto crypto, AuditService audit) {
    this.db = db;
    this.access = access;
    this.tokens = tokens;
    this.crypto = crypto;
    this.audit = audit;
  }

  @Transactional(noRollbackFor = BizException.class)
  public Map<String, Object> login(Map<String, Object> b) {
    String name = text(b, "user_name", 64),
        password = text(b, "password", 128),
        device = text(b, "device_code", 128);
    var u = db.one("SELECT * FROM `user` WHERE user_name=? FOR UPDATE", name);
    if (u == null) {
      Crypto.passwordMatches(password, DUMMY);
      throw new BizException(401, "账号或密码错误");
    }
    long id = num(u.get("id"));
    check(integer(u, "user_status", 0) == 1, 401, "账号不可用");
    check(
        u.get("lock_until") == null || !time(u.get("lock_until")).isAfter(now()),
        429,
        "账号暂时锁定，请15分钟后重试");
    if (!Crypto.passwordMatches(password, str(u, "password_hash"))) {
      int failures = integer(u, "failed_count", 0) + 1;
      db.update(
          "user",
          id,
          map(
              "failed_count",
              failures,
              "lock_until",
              failures >= 5 ? now().plusMinutes(15) : null));
      audit.logAs(id, "LOGIN_FAILED", "user", id, map("failure_count", failures), false);
      throw new BizException(401, "账号或密码错误");
    }
    db.update("user", id, map("failed_count", 0, "lock_until", null));
    var pair = tokens.issue(id, integer(u, "token_version", 0), device);
    pair.put(
        "roles",
        db.list(
            "SELECT r.role_code FROM `role` r JOIN user_role ur ON r.id=ur.role_id WHERE"
                + " ur.user_id=? AND r.is_enabled=1",
            id));
    audit.logAs(id, "LOGIN", "user", id, map(), false);
    return pair;
  }

  public Map<String, Object> me() {
    var u = access.user();
    var r =
        pick(
            u,
            "id",
            "user_name",
            "real_name",
            "user_no",
            "gender",
            "email",
            "org_id",
            "class_id",
            "avatar_id",
            "user_status");
    String p = crypto.decrypt((String) u.get("phone"));
    r.put("phone", p == null ? null : p.replaceAll("(?<=^.{3}).(?=.{4})", "*"));
    r.put(
        "roles",
        db.list(
            "SELECT r.role_code,r.scope_type FROM `role` r JOIN user_role ur ON r.id=ur.role_id"
                + " WHERE ur.user_id=? AND r.is_enabled=1",
            access.uid()));
    r.put(
        "permissions",
        db.list(
            "SELECT DISTINCT p.permission_code FROM permission p JOIN role_permission rp ON"
                + " p.id=rp.permission_id JOIN `role` r ON r.id=rp.role_id JOIN user_role ur ON"
                + " ur.role_id=r.id WHERE ur.user_id=? AND p.is_enabled=1 AND r.is_enabled=1",
            access.uid()));
    return r;
  }

  @Transactional
  public Map<String, Object> profile(Map<String, Object> b) {
    keys(b, "email", "avatar_id", "phone", "verification_code");
    var v = new LinkedHashMap<String, Object>();
    if (b.containsKey("email")) {
      String e = optional(b, "email", 128);
      check(e == null || e.matches("[^@\\s]+@[^@\\s]+\\.[^@\\s]+"), 400, "邮箱格式不正确");
      v.put("email", e);
    }
    if (b.containsKey("phone")) throw new BizException(503, "手机号变更需要学校短信验证码服务，当前尚未配置");
    if (b.containsKey("avatar_id")) {
      long id = id(b, "avatar_id");
      var f = db.lock("file_upload", id);
      check(
          eq(f.get("uploader_id"), access.uid())
              && integer(f, "scan_status", 0) == 1
              && str(f, "mime_type").startsWith("image/"),
          403,
          "头像必须是本人检测通过的图片");
      check(
          integer(f, "file_status", 0) == 0
              || (str(f, "biz_type").equals("avatar") && eq(f.get("biz_id"), access.uid())),
          409,
          "附件已用于其他业务");
      db.update(
          "file_upload", id, map("biz_type", "avatar", "biz_id", access.uid(), "file_status", 1));
      v.put("avatar_id", id);
    }
    check(!v.isEmpty(), 400, "没有可更新字段");
    db.update("user", access.uid(), v);
    audit.log("PROFILE", "user", access.uid(), map("fields", v.keySet()));
    return me();
  }

  @Transactional
  public void password(Map<String, Object> b) {
    var u = db.lock("user", access.uid());
    check(
        Crypto.passwordMatches(text(b, "old_password", 128), str(u, "password_hash")),
        400,
        "原密码错误");
    String p = text(b, "new_password", 128);
    check(
        p.length() >= 10 && p.matches(".*[A-Za-z].*") && p.matches(".*[0-9].*"),
        400,
        "新密码至少10位且包含字母和数字");
    db.update(
        "user",
        access.uid(),
        map(
            "password_hash",
            Crypto.password(p),
            "token_version",
            integer(u, "token_version", 0) + 1));
    audit.log("PASSWORD_CHANGE", "user", access.uid(), map());
  }
}
