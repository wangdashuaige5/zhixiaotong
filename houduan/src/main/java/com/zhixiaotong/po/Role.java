package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 角色表：定义学生、教师、辅导员及管理角色。数据库字段使用下画线。 */
@TableName("`role`")
public class Role {
  /** 角色ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 角色编码； */
  @TableField("role_code")
  private String roleCode;

  public String getRoleCode() {
    return roleCode;
  }

  public void setRoleCode(String value) {
    this.roleCode = value;
  }

  /** 角色名称； */
  @TableField("role_name")
  private String roleName;

  public String getRoleName() {
    return roleName;
  }

  public void setRoleName(String value) {
    this.roleName = value;
  }

  /** 数据范围；1本人；2授课；3所辖；4自定义；5全校 */
  @TableField("scope_type")
  private Integer scopeType;

  public Integer getScopeType() {
    return scopeType;
  }

  public void setScopeType(Integer value) {
    this.scopeType = value;
  }

  /** 角色说明； */
  @TableField("description")
  private String description;

  public String getDescription() {
    return description;
  }

  public void setDescription(String value) {
    this.description = value;
  }

  /** 启用状态；0停用；1启用 */
  @TableField("is_enabled")
  private Integer isEnabled;

  public Integer getIsEnabled() {
    return isEnabled;
  }

  public void setIsEnabled(Integer value) {
    this.isEnabled = value;
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
