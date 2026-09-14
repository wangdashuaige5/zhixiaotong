package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.*;

/** 课程签到任务表：支持移动端与智慧屏课堂签到场景。数据库字段使用下画线。 */
@TableName("`attendance_task`")
public class AttendanceTask {
  /** 签到任务ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 课表ID；timetable(id) */
  @TableField("timetable_id")
  private Long timetableId;

  public Long getTimetableId() {
    return timetableId;
  }

  public void setTimetableId(Long value) {
    this.timetableId = value;
  }

  /** 发起人ID；user(id) */
  @TableField("creator_id")
  private Long creatorId;

  public Long getCreatorId() {
    return creatorId;
  }

  public void setCreatorId(Long value) {
    this.creatorId = value;
  }

  /** 上课日期；与课表ID联合唯一 */
  @TableField("class_date")
  private LocalDate classDate;

  public LocalDate getClassDate() {
    return classDate;
  }

  public void setClassDate(LocalDate value) {
    this.classDate = value;
  }

  /** 开始时间； */
  @TableField("start_time")
  private LocalDateTime startTime;

  public LocalDateTime getStartTime() {
    return startTime;
  }

  public void setStartTime(LocalDateTime value) {
    this.startTime = value;
  }

  /** 截止时间； */
  @TableField("end_time")
  private LocalDateTime endTime;

  public LocalDateTime getEndTime() {
    return endTime;
  }

  public void setEndTime(LocalDateTime value) {
    this.endTime = value;
  }

  /** 签到码哈希；短期凭证；仅存哈希 */
  @TableField("code_hash")
  @JsonIgnore
  private String codeHash;

  public String getCodeHash() {
    return codeHash;
  }

  public void setCodeHash(String value) {
    this.codeHash = value;
  }

  /** 任务状态；0未开；1开放；2结束 */
  @TableField("task_status")
  private Integer taskStatus;

  public Integer getTaskStatus() {
    return taskStatus;
  }

  public void setTaskStatus(Integer value) {
    this.taskStatus = value;
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
