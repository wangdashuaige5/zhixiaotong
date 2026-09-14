package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 角色权限关联表：将可操作权限授予角色。数据库字段使用下画线。 */
@TableName("`role_permission`")
public class RolePermission {
  /** 关联ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 角色ID；role(id) */
  @TableField("role_id")
  private Long roleId;

  public Long getRoleId() {
    return roleId;
  }

  public void setRoleId(Long value) {
    this.roleId = value;
  }

  /** 权限ID；permission(id)；与角色ID联合唯一 */
  @TableField("permission_id")
  private Long permissionId;

  public Long getPermissionId() {
    return permissionId;
  }

  public void setPermissionId(Long value) {
    this.permissionId = value;
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
