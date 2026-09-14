package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 可靠消息事件表：保存待投递事件并支持消息队列重试。数据库字段使用下画线。 */
@TableName("`outbox_event`")
public class OutboxEvent {
  /** 事件ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 事件编码； */
  @TableField("event_key")
  private String eventKey;

  public String getEventKey() {
    return eventKey;
  }

  public void setEventKey(String value) {
    this.eventKey = value;
  }

  /** 事件类型； */
  @TableField("event_type")
  private String eventType;

  public String getEventType() {
    return eventType;
  }

  public void setEventType(String value) {
    this.eventType = value;
  }

  /** 事件内容；与业务同事务写入；不含明文敏感信息 */
  @TableField("payload")
  private String payload;

  public String getPayload() {
    return payload;
  }

  public void setPayload(String value) {
    this.payload = value;
  }

  /** 投递状态；0待发；1发送中；2已确认；3失败；组合查询索引 */
  @TableField("send_status")
  private Integer sendStatus;

  public Integer getSendStatus() {
    return sendStatus;
  }

  public void setSendStatus(Integer value) {
    this.sendStatus = value;
  }

  /** 重试次数； */
  @TableField("retry_count")
  private Integer retryCount;

  public Integer getRetryCount() {
    return retryCount;
  }

  public void setRetryCount(Integer value) {
    this.retryCount = value;
  }

  /** 下次重试； */
  @TableField("next_retry_time")
  private LocalDateTime nextRetryTime;

  public LocalDateTime getNextRetryTime() {
    return nextRetryTime;
  }

  public void setNextRetryTime(LocalDateTime value) {
    this.nextRetryTime = value;
  }

  /** 锁定截止；工作进程中断后可重领 */
  @TableField("lock_until")
  private LocalDateTime lockUntil;

  public LocalDateTime getLockUntil() {
    return lockUntil;
  }

  public void setLockUntil(LocalDateTime value) {
    this.lockUntil = value;
  }

  /** 确认时间； */
  @TableField("confirmed_time")
  private LocalDateTime confirmedTime;

  public LocalDateTime getConfirmedTime() {
    return confirmedTime;
  }

  public void setConfirmedTime(LocalDateTime value) {
    this.confirmedTime = value;
  }

  /** 错误摘要； */
  @TableField("error_message")
  private String errorMessage;

  public String getErrorMessage() {
    return errorMessage;
  }

  public void setErrorMessage(String value) {
    this.errorMessage = value;
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
