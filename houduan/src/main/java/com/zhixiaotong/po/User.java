package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.*;

/** 用户表：保存师生账号、组织归属与认证信息。数据库字段使用下画线。 */
@TableName("`user`")
public class User {
  /** 用户ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 账号； */
  @TableField("user_name")
  private String userName;

  public String getUserName() {
    return userName;
  }

  public void setUserName(String value) {
    this.userName = value;
  }

  /** 密码哈希；强哈希；不保存明文 */
  @TableField("password_hash")
  @JsonIgnore
  private String passwordHash;

  public String getPasswordHash() {
    return passwordHash;
  }

  public void setPasswordHash(String value) {
    this.passwordHash = value;
  }

  /** 姓名； */
  @TableField("real_name")
  private String realName;

  public String getRealName() {
    return realName;
  }

  public void setRealName(String value) {
    this.realName = value;
  }

  /** 学工号；学生学号或教工号 */
  @TableField("user_no")
  private String userNo;

  public String getUserNo() {
    return userNo;
  }

  public void setUserNo(String value) {
    this.userNo = value;
  }

  /** 性别；0未知；1男；2女 */
  @TableField("gender")
  private Integer gender;

  public Integer getGender() {
    return gender;
  }

  public void setGender(Integer value) {
    this.gender = value;
  }

  /** 手机号；敏感信息加密保存 */
  @TableField("phone")
  @JsonIgnore
  private String phone;

  public String getPhone() {
    return phone;
  }

  public void setPhone(String value) {
    this.phone = value;
  }

  /** 邮箱； */
  @TableField("email")
  private String email;

  public String getEmail() {
    return email;
  }

  public void setEmail(String value) {
    this.email = value;
  }

  /** 组织ID；org_unit(id)；查询索引 */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 班级ID；school_class(id)；学生必填；查询索引 */
  @TableField("class_id")
  private Long classId;

  public Long getClassId() {
    return classId;
  }

  public void setClassId(Long value) {
    this.classId = value;
  }

  /** 头像ID；file_upload(id) */
  @TableField("avatar_id")
  private Long avatarId;

  public Long getAvatarId() {
    return avatarId;
  }

  public void setAvatarId(Long value) {
    this.avatarId = value;
  }

  /** 账号状态；0停用；1正常；2注销 */
  @TableField("user_status")
  private Integer userStatus;

  public Integer getUserStatus() {
    return userStatus;
  }

  public void setUserStatus(Integer value) {
    this.userStatus = value;
  }

  /** 失败次数； */
  @TableField("failed_count")
  private Integer failedCount;

  public Integer getFailedCount() {
    return failedCount;
  }

  public void setFailedCount(Integer value) {
    this.failedCount = value;
  }

  /** 锁定截止； */
  @TableField("lock_until")
  private LocalDateTime lockUntil;

  public LocalDateTime getLockUntil() {
    return lockUntil;
  }

  public void setLockUntil(LocalDateTime value) {
    this.lockUntil = value;
  }

  /** 令牌版本；修改密码或撤销时递增 */
  @TableField("token_version")
  private Integer tokenVersion;

  public Integer getTokenVersion() {
    return tokenVersion;
  }

  public void setTokenVersion(Integer value) {
    this.tokenVersion = value;
  }

  /** 创建时间； */
  @TableField("create_time")
  private LocalDateTime createTime;

  public LocalDateTime getCreateTime() {
    return createTime;
  }

  public void setCreateTime(LocalDateTime value) {
    this.createTime = value;
  }

  /** 更新时间；更新时由服务端写入 */
  @TableField("update_time")
  private LocalDateTime updateTime;

  public LocalDateTime getUpdateTime() {
    return updateTime;
  }

  public void setUpdateTime(LocalDateTime value) {
    this.updateTime = value;
  }
}
