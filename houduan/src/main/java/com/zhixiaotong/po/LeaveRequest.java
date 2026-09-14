package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 请假单表：保存请假申请、分级审批和销假信息。数据库字段使用下画线。 */
@TableName("`leave_request`")
public class LeaveRequest {
  /** 请假ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 学生ID；user(id)；组合查询索引 */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 请假类型；请假类型字典 */
  @TableField("leave_type")
  private String leaveType;

  public String getLeaveType() {
    return leaveType;
  }

  public void setLeaveType(String value) {
    this.leaveType = value;
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

  /** 结束时间；必须晚于开始时间 */
  @TableField("end_time")
  private LocalDateTime endTime;

  public LocalDateTime getEndTime() {
    return endTime;
  }

  public void setEndTime(LocalDateTime value) {
    this.endTime = value;
  }

  /** 请假天数；按校规计算；超过3天转院系 */
  @TableField("leave_days")
  private BigDecimal leaveDays;

  public BigDecimal getLeaveDays() {
    return leaveDays;
  }

  public void setLeaveDays(BigDecimal value) {
    this.leaveDays = value;
  }

  /** 请假原因；覆盖上课时段时通知授课教师 */
  @TableField("leave_reason")
  private String leaveReason;

  public String getLeaveReason() {
    return leaveReason;
  }

  public void setLeaveReason(String value) {
    this.leaveReason = value;
  }

  /** 请假状态；0草稿；1辅导员审；2院系审；3通过；4驳回；5退回；6撤回；7销假 */
  @TableField("leave_status")
  private Integer leaveStatus;

  public Integer getLeaveStatus() {
    return leaveStatus;
  }

  public void setLeaveStatus(Integer value) {
    this.leaveStatus = value;
  }

  /** 申请轮次； */
  @TableField("apply_round")
  private Integer applyRound;

  public Integer getApplyRound() {
    return applyRound;
  }

  public void setApplyRound(Integer value) {
    this.applyRound = value;
  }

  /** 提交时间； */
  @TableField("submit_time")
  private LocalDateTime submitTime;

  public LocalDateTime getSubmitTime() {
    return submitTime;
  }

  public void setSubmitTime(LocalDateTime value) {
    this.submitTime = value;
  }

  /** 销假时间； */
  @TableField("close_time")
  private LocalDateTime closeTime;

  public LocalDateTime getCloseTime() {
    return closeTime;
  }

  public void setCloseTime(LocalDateTime value) {
    this.closeTime = value;
  }

  /** 销假方式；0未销；1本人；2自动 */
  @TableField("close_type")
  private Integer closeType;

  public Integer getCloseType() {
    return closeType;
  }

  public void setCloseType(Integer value) {
    this.closeType = value;
  }

  /** 销假人ID；user(id)；系统自动销假时为空 */
  @TableField("closer_id")
  private Long closerId;

  public Long getCloserId() {
    return closerId;
  }

  public void setCloserId(Long value) {
    this.closerId = value;
  }

  /** 销假说明； */
  @TableField("close_note")
  private String closeNote;

  public String getCloseNote() {
    return closeNote;
  }

  public void setCloseNote(String value) {
    this.closeNote = value;
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
