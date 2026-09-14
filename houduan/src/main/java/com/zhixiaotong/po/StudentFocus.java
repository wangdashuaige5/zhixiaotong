package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.*;

/** 重点关注记录表：保存限权访问的重点关注与跟进信息。数据库字段使用下画线。 */
@TableName("`student_focus`")
public class StudentFocus {
  /** 关注ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 学生ID；user(id)；查询索引 */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 关注类别； */
  @TableField("focus_type")
  private String focusType;

  public String getFocusType() {
    return focusType;
  }

  public void setFocusType(String value) {
    this.focusType = value;
  }

  /** 关注内容；加密保存；禁止无授权导出 */
  @TableField("focus_content")
  @JsonIgnore
  private String focusContent;

  public String getFocusContent() {
    return focusContent;
  }

  public void setFocusContent(String value) {
    this.focusContent = value;
  }

  /** 跟进记录； */
  @TableField("follow_up")
  @JsonIgnore
  private String followUp;

  public String getFollowUp() {
    return followUp;
  }

  public void setFollowUp(String value) {
    this.followUp = value;
  }

  /** 负责人ID；user(id)；组合查询索引 */
  @TableField("owner_id")
  private Long ownerId;

  public Long getOwnerId() {
    return ownerId;
  }

  public void setOwnerId(Long value) {
    this.ownerId = value;
  }

  /** 关注状态；1跟进中；2已结束 */
  @TableField("focus_status")
  private Integer focusStatus;

  public Integer getFocusStatus() {
    return focusStatus;
  }

  public void setFocusStatus(Integer value) {
    this.focusStatus = value;
  }

  /** 结束时间； */
  @TableField("close_time")
  private LocalDateTime closeTime;

  public LocalDateTime getCloseTime() {
    return closeTime;
  }

  public void setCloseTime(LocalDateTime value) {
    this.closeTime = value;
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
