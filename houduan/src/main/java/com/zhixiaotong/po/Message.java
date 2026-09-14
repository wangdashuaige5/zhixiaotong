package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 站内消息表：保存通知和业务结果的统一消息内容。数据库字段使用下画线。 */
@TableName("`message`")
public class Message {
  /** 消息ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 消息标题； */
  @TableField("message_title")
  private String messageTitle;

  public String getMessageTitle() {
    return messageTitle;
  }

  public void setMessageTitle(String value) {
    this.messageTitle = value;
  }

  /** 消息内容； */
  @TableField("content")
  private String content;

  public String getContent() {
    return content;
  }

  public void setContent(String value) {
    this.content = value;
  }

  /** 通知ID；notice(id) */
  @TableField("notice_id")
  private Long noticeId;

  public Long getNoticeId() {
    return noticeId;
  }

  public void setNoticeId(Long value) {
    this.noticeId = value;
  }

  /** 业务类型；请假、成绩、选课、充值等 */
  @TableField("biz_type")
  private String bizType;

  public String getBizType() {
    return bizType;
  }

  public void setBizType(String value) {
    this.bizType = value;
  }

  /** 业务ID；按类型校验的逻辑引用 */
  @TableField("biz_id")
  private Long bizId;

  public Long getBizId() {
    return bizId;
  }

  public void setBizId(Long value) {
    this.bizId = value;
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

  /** 需要回执；0否；1是 */
  @TableField("need_ack")
  private Integer needAck;

  public Integer getNeedAck() {
    return needAck;
  }

  public void setNeedAck(Integer value) {
    this.needAck = value;
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
