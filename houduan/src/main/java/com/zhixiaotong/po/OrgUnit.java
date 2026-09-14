package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 组织机构表：维护学校、院系、专业和年级组织树。数据库字段使用下画线。 */
@TableName("`org_unit`")
public class OrgUnit {
  /** 组织ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 父组织ID；org_unit(id)；根节点为空；禁止环路；查询索引 */
  @TableField("parent_id")
  private Long parentId;

  public Long getParentId() {
    return parentId;
  }

  public void setParentId(Long value) {
    this.parentId = value;
  }

  /** 组织编码； */
  @TableField("org_code")
  private String orgCode;

  public String getOrgCode() {
    return orgCode;
  }

  public void setOrgCode(String value) {
    this.orgCode = value;
  }

  /** 组织名称； */
  @TableField("org_name")
  private String orgName;

  public String getOrgName() {
    return orgName;
  }

  public void setOrgName(String value) {
    this.orgName = value;
  }

  /** 组织类型；1学校；2院系；3专业；4年级 */
  @TableField("org_type")
  private Integer orgType;

  public Integer getOrgType() {
    return orgType;
  }

  public void setOrgType(Integer value) {
    this.orgType = value;
  }

  /** 排序值； */
  @TableField("sort_order")
  private Integer sortOrder;

  public Integer getSortOrder() {
    return sortOrder;
  }

  public void setSortOrder(Integer value) {
    this.sortOrder = value;
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
