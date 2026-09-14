package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 消息回执表：按接收人记录送达、已读和确认状态。数据库字段使用下画线。 */
@TableName("`message_receipt`")
public class MessageReceipt {
  /** 回执ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 消息ID；message(id) */
  @TableField("message_id")
  private Long messageId;

  public Long getMessageId() {
    return messageId;
  }

  public void setMessageId(Long value) {
    this.messageId = value;
  }

  /** 接收人ID；user(id)；与消息ID联合唯一；组合查询索引 */
  @TableField("receiver_id")
  private Long receiverId;

  public Long getReceiverId() {
    return receiverId;
  }

  public void setReceiverId(Long value) {
    this.receiverId = value;
  }

  /** 送达状态；0待送；1已送；2失败 */
  @TableField("delivery_status")
  private Integer deliveryStatus;

  public Integer getDeliveryStatus() {
    return deliveryStatus;
  }

  public void setDeliveryStatus(Integer value) {
    this.deliveryStatus = value;
  }

  /** 送达时间； */
  @TableField("delivered_time")
  private LocalDateTime deliveredTime;

  public LocalDateTime getDeliveredTime() {
    return deliveredTime;
  }

  public void setDeliveredTime(LocalDateTime value) {
    this.deliveredTime = value;
  }

  /** 阅读时间； */
  @TableField("read_time")
  private LocalDateTime readTime;

  public LocalDateTime getReadTime() {
    return readTime;
  }

  public void setReadTime(LocalDateTime value) {
    this.readTime = value;
  }

  /** 确认时间； */
  @TableField("ack_time")
  private LocalDateTime ackTime;

  public LocalDateTime getAckTime() {
    return ackTime;
  }

  public void setAckTime(LocalDateTime value) {
    this.ackTime = value;
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

  /** 失败原因； */
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
