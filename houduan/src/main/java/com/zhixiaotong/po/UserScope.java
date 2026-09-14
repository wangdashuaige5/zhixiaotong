package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 用户数据范围表：限定角色授权下的组织或班级范围。数据库字段使用下画线。 */
@TableName("`user_scope`")
public class UserScope {
  /** 范围ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 授权ID；user_role(id) */
  @TableField("user_role_id")
  private Long userRoleId;

  public Long getUserRoleId() {
    return userRoleId;
  }

  public void setUserRoleId(Long value) {
    this.userRoleId = value;
  }

  /** 组织ID；org_unit(id)；与授权ID联合唯一 */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 班级ID；school_class(id)；与组织ID恰一非空；与授权ID联合唯一 */
  @TableField("class_id")
  private Long classId;

  public Long getClassId() {
    return classId;
  }

  public void setClassId(Long value) {
    this.classId = value;
  }

  /** 包含下级；0否；1是；仅组织范围有效 */
  @TableField("include_children")
  private Integer includeChildren;

  public Integer getIncludeChildren() {
    return includeChildren;
  }

  public void setIncludeChildren(Integer value) {
    this.includeChildren = value;
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
