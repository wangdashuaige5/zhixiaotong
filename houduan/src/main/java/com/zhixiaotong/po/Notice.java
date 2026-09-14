package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 通知公告表：保存通知内容、有效期和紧急等级。数据库字段使用下画线。 */
@TableName("`notice`")
public class Notice {
  /** 通知ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 通知标题； */
  @TableField("notice_title")
  private String noticeTitle;

  public String getNoticeTitle() {
    return noticeTitle;
  }

  public void setNoticeTitle(String value) {
    this.noticeTitle = value;
  }

  /** 通知内容； */
  @TableField("content")
  private String content;

  public String getContent() {
    return content;
  }

  public void setContent(String value) {
    this.content = value;
  }

  /** 发布人ID；user(id) */
  @TableField("publisher_id")
  private Long publisherId;

  public Long getPublisherId() {
    return publisherId;
  }

  public void setPublisherId(Long value) {
    this.publisherId = value;
  }

  /** 紧急等级；0普通；1重要；2紧急 */
  @TableField("urgency_level")
  private Integer urgencyLevel;

  public Integer getUrgencyLevel() {
    return urgencyLevel;
  }

  public void setUrgencyLevel(Integer value) {
    this.urgencyLevel = value;
  }

  /** 是否置顶；0否；1是 */
  @TableField("is_pinned")
  private Integer isPinned;

  public Integer getIsPinned() {
    return isPinned;
  }

  public void setIsPinned(Integer value) {
    this.isPinned = value;
  }

  /** 需要回执；0否；1是；紧急通知须为1 */
  @TableField("need_ack")
  private Integer needAck;

  public Integer getNeedAck() {
    return needAck;
  }

  public void setNeedAck(Integer value) {
    this.needAck = value;
  }

  /** 生效时间； */
  @TableField("start_time")
  private LocalDateTime startTime;

  public LocalDateTime getStartTime() {
    return startTime;
  }

  public void setStartTime(LocalDateTime value) {
    this.startTime = value;
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

  /** 发布时间； */
  @TableField("publish_time")
  private LocalDateTime publishTime;

  public LocalDateTime getPublishTime() {
    return publishTime;
  }

  public void setPublishTime(LocalDateTime value) {
    this.publishTime = value;
  }

  /** 发布状态；0草稿；1已发布；2撤回；组合查询索引 */
  @TableField("publish_status")
  private Integer publishStatus;

  public Integer getPublishStatus() {
    return publishStatus;
  }

  public void setPublishStatus(Integer value) {
    this.publishStatus = value;
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
