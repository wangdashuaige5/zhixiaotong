package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 权限表：统一维护菜单、按钮与接口权限。数据库字段使用下画线。 */
@TableName("`permission`")
public class Permission {
  /** 权限ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 父权限ID；permission(id) */
  @TableField("parent_id")
  private Long parentId;

  public Long getParentId() {
    return parentId;
  }

  public void setParentId(Long value) {
    this.parentId = value;
  }

  /** 权限编码； */
  @TableField("permission_code")
  private String permissionCode;

  public String getPermissionCode() {
    return permissionCode;
  }

  public void setPermissionCode(String value) {
    this.permissionCode = value;
  }

  /** 权限名称； */
  @TableField("permission_name")
  private String permissionName;

  public String getPermissionName() {
    return permissionName;
  }

  public void setPermissionName(String value) {
    this.permissionName = value;
  }

  /** 权限类型；1菜单；2按钮；3接口 */
  @TableField("permission_type")
  private Integer permissionType;

  public Integer getPermissionType() {
    return permissionType;
  }

  public void setPermissionType(Integer value) {
    this.permissionType = value;
  }

  /** 资源路径； */
  @TableField("resource_path")
  private String resourcePath;

  public String getResourcePath() {
    return resourcePath;
  }

  public void setResourcePath(String value) {
    this.resourcePath = value;
  }

  /** 请求方法； */
  @TableField("http_method")
  private String httpMethod;

  public String getHttpMethod() {
    return httpMethod;
  }

  public void setHttpMethod(String value) {
    this.httpMethod = value;
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
