package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 奖助贷申请表：保存学生申请资料与评审进度。数据库字段使用下画线。 */
@TableName("`aid_application`")
public class AidApplication {
  /** 申请ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 批次ID；aid_batch(id) */
  @TableField("batch_id")
  private Long batchId;

  public Long getBatchId() {
    return batchId;
  }

  public void setBatchId(Long value) {
    this.batchId = value;
  }

  /** 学生ID；user(id)；与批次ID联合唯一 */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 申请理由；敏感资料按权限访问 */
  @TableField("apply_reason")
  private String applyReason;

  public String getApplyReason() {
    return applyReason;
  }

  public void setApplyReason(String value) {
    this.applyReason = value;
  }

  /** 申请金额；单位元；大于0 */
  @TableField("apply_amount")
  private BigDecimal applyAmount;

  public BigDecimal getApplyAmount() {
    return applyAmount;
  }

  public void setApplyAmount(BigDecimal value) {
    this.applyAmount = value;
  }

  /** 申请状态；0草稿；1待评；2通过；3驳回；4退回；5撤回 */
  @TableField("apply_status")
  private Integer applyStatus;

  public Integer getApplyStatus() {
    return applyStatus;
  }

  public void setApplyStatus(Integer value) {
    this.applyStatus = value;
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
