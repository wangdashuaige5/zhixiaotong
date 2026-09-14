package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 奖助贷批次表：配置评审项目、申请时间与名额。数据库字段使用下画线。 */
@TableName("`aid_batch`")
public class AidBatch {
  /** 批次ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
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

  /** 资助类型； */
  @TableField("aid_type")
  private String aidType;

  public String getAidType() {
    return aidType;
  }

  public void setAidType(String value) {
    this.aidType = value;
  }

  /** 组织ID；org_unit(id) */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 学期ID；semester(id)；组合查询索引 */
  @TableField("semester_id")
  private Long semesterId;

  public Long getSemesterId() {
    return semesterId;
  }

  public void setSemesterId(Long value) {
    this.semesterId = value;
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

  /** 结束时间； */
  @TableField("end_time")
  private LocalDateTime endTime;

  public LocalDateTime getEndTime() {
    return endTime;
  }

  public void setEndTime(LocalDateTime value) {
    this.endTime = value;
  }

  /** 名额；大于0 */
  @TableField("quota")
  private Integer quota;

  public Integer getQuota() {
    return quota;
  }

  public void setQuota(Integer value) {
    this.quota = value;
  }

  /** 资助金额；单位元；大于等于0 */
  @TableField("aid_amount")
  private BigDecimal aidAmount;

  public BigDecimal getAidAmount() {
    return aidAmount;
  }

  public void setAidAmount(BigDecimal value) {
    this.aidAmount = value;
  }

  /** 申请条件； */
  @TableField("requirements")
  private String requirements;

  public String getRequirements() {
    return requirements;
  }

  public void setRequirements(String value) {
    this.requirements = value;
  }

  /** 批次状态；0草稿；1开放；2评审；3结束 */
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
