package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 选课批次表：配置预选、正选和补退选开放阶段。数据库字段使用下画线。 */
@TableName("`selection_batch`")
public class SelectionBatch {
  /** 批次ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 批次编码； */
  @TableField("batch_code")
  private String batchCode;

  public String getBatchCode() {
    return batchCode;
  }

  public void setBatchCode(String value) {
    this.batchCode = value;
  }

  /** 批次名称； */
  @TableField("batch_name")
  private String batchName;

  public String getBatchName() {
    return batchName;
  }

  public void setBatchName(String value) {
    this.batchName = value;
  }

  /** 学期ID；semester(id)；查询索引 */
  @TableField("semester_id")
  private Long semesterId;

  public Long getSemesterId() {
    return semesterId;
  }

  public void setSemesterId(Long value) {
    this.semesterId = value;
  }

  /** 批次阶段；1预选；2正选；3补退选 */
  @TableField("batch_stage")
  private Integer batchStage;

  public Integer getBatchStage() {
    return batchStage;
  }

  public void setBatchStage(Integer value) {
    this.batchStage = value;
  }

  /** 开放时间； */
  @TableField("start_time")
  private LocalDateTime startTime;

  public LocalDateTime getStartTime() {
    return startTime;
  }

  public void setStartTime(LocalDateTime value) {
    this.startTime = value;
  }

  /** 结束时间； */
  @TableField("end_time")
  private LocalDateTime endTime;

  public LocalDateTime getEndTime() {
    return endTime;
  }

  public void setEndTime(LocalDateTime value) {
    this.endTime = value;
  }

  /** 退选截止； */
  @TableField("drop_deadline")
  private LocalDateTime dropDeadline;

  public LocalDateTime getDropDeadline() {
    return dropDeadline;
  }

  public void setDropDeadline(LocalDateTime value) {
    this.dropDeadline = value;
  }

  /** 限选门数；0表示不限制 */
  @TableField("max_courses")
  private Integer maxCourses;

  public Integer getMaxCourses() {
    return maxCourses;
  }

  public void setMaxCourses(Integer value) {
    this.maxCourses = value;
  }

  /** 限选学分；0表示不限制 */
  @TableField("max_credits")
  private BigDecimal maxCredits;

  public BigDecimal getMaxCredits() {
    return maxCredits;
  }

  public void setMaxCredits(BigDecimal value) {
    this.maxCredits = value;
  }

  /** 选课公告； */
  @TableField("announcement")
  private String announcement;

  public String getAnnouncement() {
    return announcement;
  }

  public void setAnnouncement(String value) {
    this.announcement = value;
  }

  /** 批次状态；0未开；1开放；2结束；3锁定 */
  @TableField("batch_status")
  private Integer batchStatus;

  public Integer getBatchStatus() {
    return batchStatus;
  }

  public void setBatchStatus(Integer value) {
    this.batchStatus = value;
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
