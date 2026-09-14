package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 用户角色关联表：支持一名用户拥有多个业务角色。数据库字段使用下画线。 */
@TableName("`user_role`")
public class UserRole {
  /** 关联ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 用户ID；user(id) */
  @TableField("user_id")
  private Long userId;

  public Long getUserId() {
    return userId;
  }

  public void setUserId(Long value) {
    this.userId = value;
  }

  /** 角色ID；role(id)；与用户ID联合唯一 */
  @TableField("role_id")
  private Long roleId;

  public Long getRoleId() {
    return roleId;
  }

  public void setRoleId(Long value) {
    this.roleId = value;
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
}
