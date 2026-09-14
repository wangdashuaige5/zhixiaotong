package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.*;

/** 跨设备流转任务表：控制身份、可访问范围和流转超时回收。数据库字段使用下画线。 */
@TableName("`continuation`")
public class Continuation {
  /** 流转ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 用户ID；user(id)；组合查询索引 */
  @TableField("user_id")
  private Long userId;

  public Long getUserId() {
    return userId;
  }

  public void setUserId(Long value) {
    this.userId = value;
  }

  /** 源设备ID；device(id) */
  @TableField("source_device_id")
  private Long sourceDeviceId;

  public Long getSourceDeviceId() {
    return sourceDeviceId;
  }

  public void setSourceDeviceId(Long value) {
    this.sourceDeviceId = value;
  }

  /** 目标设备ID；device(id)；接收前校验属于同一用户 */
  @TableField("target_device_id")
  private Long targetDeviceId;

  public Long getTargetDeviceId() {
    return targetDeviceId;
  }

  public void setTargetDeviceId(Long value) {
    this.targetDeviceId = value;
  }

  /** 业务类型； */
  @TableField("biz_type")
  private String bizType;

  public String getBizType() {
    return bizType;
  }

  public void setBizType(String value) {
    this.bizType = value;
  }

  /** 业务ID；逻辑引用；重新校验业务权限 */
  @TableField("biz_id")
  private Long bizId;

  public Long getBizId() {
    return bizId;
  }

  public void setBizId(Long value) {
    this.bizId = value;
  }

  /** 授权范围；最小必要字段；不可扩大权限 */
  @TableField("scope_data")
  private String scopeData;

  public String getScopeData() {
    return scopeData;
  }

  public void setScopeData(String value) {
    this.scopeData = value;
  }

  /** 流转凭证哈希；一次性凭证；仅存哈希 */
  @TableField("token_hash")
  @JsonIgnore
  private String tokenHash;

  public String getTokenHash() {
    return tokenHash;
  }

  public void setTokenHash(String value) {
    this.tokenHash = value;
  }

  /** 流转状态；0待接收；1已接收；2完成；3过期；4撤销 */
  @TableField("task_status")
  private Integer taskStatus;

  public Integer getTaskStatus() {
    return taskStatus;
  }

  public void setTaskStatus(Integer value) {
    this.taskStatus = value;
  }

  /** 失效时间； */
  @TableField("expire_time")
  private LocalDateTime expireTime;

  public LocalDateTime getExpireTime() {
    return expireTime;
  }

  public void setExpireTime(LocalDateTime value) {
    this.expireTime = value;
  }

  /** 接收时间； */
  @TableField("accept_time")
  private LocalDateTime acceptTime;

  public LocalDateTime getAcceptTime() {
    return acceptTime;
  }

  public void setAcceptTime(LocalDateTime value) {
    this.acceptTime = value;
  }

  /** 回收时间； */
  @TableField("reclaim_time")
  private LocalDateTime reclaimTime;

  public LocalDateTime getReclaimTime() {
    return reclaimTime;
  }

  public void setReclaimTime(LocalDateTime value) {
    this.reclaimTime = value;
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
