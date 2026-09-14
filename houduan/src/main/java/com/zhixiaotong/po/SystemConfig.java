package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 系统配置字典表：维护系统参数、字典项和规则配置。数据库字段使用下画线。 */
@TableName("`system_config`")
public class SystemConfig {
  /** 配置ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 配置分组； */
  @TableField("config_group")
  private String configGroup;

  public String getConfigGroup() {
    return configGroup;
  }

  public void setConfigGroup(String value) {
    this.configGroup = value;
  }

  /** 配置编码；与配置分组联合唯一 */
  @TableField("config_key")
  private String configKey;

  public String getConfigKey() {
    return configKey;
  }

  public void setConfigKey(String value) {
    this.configKey = value;
  }

  /** 配置名称； */
  @TableField("config_name")
  private String configName;

  public String getConfigName() {
    return configName;
  }

  public void setConfigName(String value) {
    this.configName = value;
  }

  /** 配置值；不保存明文密钥 */
  @TableField("config_value")
  private String configValue;

  public String getConfigValue() {
    return configValue;
  }

  public void setConfigValue(String value) {
    this.configValue = value;
  }

  /** 值类型；string、number、bool或json */
  @TableField("value_type")
  private String valueType;

  public String getValueType() {
    return valueType;
  }

  public void setValueType(String value) {
    this.valueType = value;
  }

  /** 配置说明； */
  @TableField("description")
  private String description;

  public String getDescription() {
    return description;
  }

  public void setDescription(String value) {
    this.description = value;
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

  /** 更新人ID；user(id) */
  @TableField("updater_id")
  private Long updaterId;

  public Long getUpdaterId() {
    return updaterId;
  }

  public void setUpdaterId(Long value) {
    this.updaterId = value;
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
