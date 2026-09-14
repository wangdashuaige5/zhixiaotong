package com.zhixiaotong.security;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import java.util.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/** 权限与数据范围按同一个角色授权结合，不能用另一角色扩大本权限的范围。 */
@Component
public class Access {
  private final Db db;

  public Access(Db db) {
    this.db = db;
  }

  public LoginUser current() {
    var a = SecurityContextHolder.getContext().getAuthentication();
    check(a != null && a.getPrincipal() instanceof LoginUser, 401, "请先登录");
    return (LoginUser) a.getPrincipal();
  }

  public long uid() {
    return current().id();
  }

  public Map<String, Object> user() {
    return db.get("user", uid());
  }

  public List<Map<String, Object>> roles(long uid, String permission) {
    return db.list(
        "SELECT r.*,ur.id AS user_role_id FROM `role` r JOIN user_role ur ON r.id=ur.role_id JOIN"
            + " role_permission rp ON rp.role_id=r.id JOIN permission p ON p.id=rp.permission_id"
            + " WHERE ur.user_id=? AND r.is_enabled=1 AND p.is_enabled=1 AND p.permission_code=?",
        uid,
        permission);
  }

  public boolean has(String permission) {
    return !roles(uid(), permission).isEmpty();
  }

  public void require(String permission) {
    check(has(permission), 403, "无权执行此操作");
  }

  public boolean isRole(String code) {
    return db.count(
            "SELECT COUNT(*) FROM user_role ur JOIN `role` r ON ur.role_id=r.id WHERE ur.user_id=?"
                + " AND r.role_code=? AND r.is_enabled=1",
            uid(),
            code)
        > 0;
  }

  public void student() {
    check(isRole("STUDENT"), 403, "仅学生可办理此业务");
  }

  public boolean desc(long child, long parent) {
    Set<Long> seen = new HashSet<>();
    while (seen.add(child)) {
      if (child == parent) return true;
      var r = db.one("SELECT parent_id FROM org_unit WHERE id=?", child);
      if (r == null || r.get("parent_id") == null) return false;
      child = num(r.get("parent_id"));
    }
    return false;
  }

  private boolean scopeRow(Map<String, Object> row, long org, Object cls) {
    if (row.get("class_id") != null) return eq(row.get("class_id"), cls);
    if (row.get("org_id") == null) return false;
    long p = num(row.get("org_id"));
    return org == p || (integer(row, "include_children", 0) == 1 && desc(org, p));
  }

  public boolean canOrg(long actor, long org, String permission) {
    for (var r : roles(actor, permission)) {
      int type = integer(r, "scope_type", 1);
      if (type == 5) return true;
      if (type == 4)
        for (var s :
            db.list("SELECT * FROM user_scope WHERE user_role_id=?", r.get("user_role_id")))
          if (scopeRow(s, org, null)) return true;
    }
    return false;
  }

  public void org(long org, String permission) {
    require(permission);
    check(canOrg(uid(), org, permission), 403, "超出组织授权范围");
  }

  public boolean canStudent(long actor, long target, String permission) {
    var u = db.get("user", target);
    for (var r : roles(actor, permission)) {
      int type = integer(r, "scope_type", 1);
      if (type == 5) return true;
      if (type == 1 && actor == target) return true;
      if (type == 2
          && db.count(
                  "SELECT COUNT(*) FROM enrollment e JOIN teaching_class tc ON"
                      + " tc.id=e.teaching_class_id WHERE e.student_id=? AND tc.teacher_id=? AND"
                      + " e.enroll_status=1",
                  target,
                  actor)
              > 0) return true;
      if (type == 3
          && db.count(
                  "SELECT COUNT(*) FROM counselor_class WHERE counselor_id=? AND class_id=? AND"
                      + " start_time<=? AND (end_time IS NULL OR end_time>?)",
                  actor,
                  u.get("class_id"),
                  now(),
                  now())
              > 0) return true;
      if (type == 4)
        for (var s :
            db.list("SELECT * FROM user_scope WHERE user_role_id=?", r.get("user_role_id")))
          if (scopeRow(s, num(u.get("org_id")), u.get("class_id"))) return true;
    }
    return false;
  }

  public void person(long id, String permission) {
    require(permission);
    check(canStudent(uid(), id, permission), 403, "超出学生数据范围");
  }

  public Map<String, Object> teaching(long id, boolean write) {
    var tc = db.get("teaching_class", id);
    String p = write ? "teaching:write" : "teaching:read";
    require(p);
    boolean ok = eq(tc.get("teacher_id"), uid());
    if (!write)
      ok |=
          db.count(
                  "SELECT COUNT(*) FROM enrollment WHERE student_id=? AND teaching_class_id=? AND"
                      + " enroll_status=1",
                  uid(),
                  id)
              > 0;
    var c = db.get("course", num(tc.get("course_id")));
    ok |= canOrg(uid(), num(c.get("org_id")), p);
    check(ok, 403, "无权访问该教学班");
    return tc;
  }

  public Map<String, Object> courseClass(long course, Map<String, Object> body, boolean write) {
    var tc = teaching(id(body, "teaching_class_id"), write);
    check(eq(tc.get("course_id"), course), 400, "课程与教学班不一致");
    return tc;
  }

  public long approver(long student, String permission) {
    return db
        .list(
            "SELECT DISTINCT u.id FROM `user` u JOIN user_role ur ON u.id=ur.user_id JOIN"
                + " role_permission rp ON ur.role_id=rp.role_id JOIN permission p ON"
                + " rp.permission_id=p.id WHERE p.permission_code=? AND u.user_status=1 ORDER BY"
                + " u.id",
            permission)
        .stream()
        .map(r -> num(r.get("id")))
        .filter(
            id -> roles(id, permission).stream().anyMatch(r -> integer(r, "scope_type", 5) != 5))
        .filter(id -> id != student && canStudent(id, student, permission))
        .findFirst()
        .orElseThrow(() -> new BizException(409, "尚未配置有效审批人：" + permission));
  }

  public void confirmed(Map<String, Object> b) {
    check(Boolean.TRUE.equals(b.get("confirmed")), 400, "高风险操作需要confirmed=true二次确认");
  }
}
