package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 成绩更正申请表：保留成绩更正前后值及审批责任人。数据库字段使用下画线。 */
@TableName("`grade_change`")
public class GradeChange {
  /** 更正ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 成绩ID；grade(id)；查询索引 */
  @TableField("grade_id")
  private Long gradeId;

  public Long getGradeId() {
    return gradeId;
  }

  public void setGradeId(Long value) {
    this.gradeId = value;
  }

  /** 申请人ID；user(id) */
  @TableField("applicant_id")
  private Long applicantId;

  public Long getApplicantId() {
    return applicantId;
  }

  public void setApplicantId(Long value) {
    this.applicantId = value;
  }

  /** 原成绩；含分项、总评、绩点及版本 */
  @TableField("before_value")
  private String beforeValue;

  public String getBeforeValue() {
    return beforeValue;
  }

  public void setBeforeValue(String value) {
    this.beforeValue = value;
  }

  /** 拟改成绩；与原成绩同结构 */
  @TableField("after_value")
  private String afterValue;

  public String getAfterValue() {
    return afterValue;
  }

  public void setAfterValue(String value) {
    this.afterValue = value;
  }

  /** 更正原因； */
  @TableField("change_reason")
  private String changeReason;

  public String getChangeReason() {
    return changeReason;
  }

  public void setChangeReason(String value) {
    this.changeReason = value;
  }

  /** 审核人ID；user(id) */
  @TableField("reviewer_id")
  private Long reviewerId;

  public Long getReviewerId() {
    return reviewerId;
  }

  public void setReviewerId(Long value) {
    this.reviewerId = value;
  }

  /** 审核状态；0待审；1通过；2驳回 */
  @TableField("review_status")
  private Integer reviewStatus;

  public Integer getReviewStatus() {
    return reviewStatus;
  }

  public void setReviewStatus(Integer value) {
    this.reviewStatus = value;
  }

  /** 审核意见； */
  @TableField("review_comment")
  private String reviewComment;

  public String getReviewComment() {
    return reviewComment;
  }

  public void setReviewComment(String value) {
    this.reviewComment = value;
  }

  /** 审核时间； */
  @TableField("review_time")
  private LocalDateTime reviewTime;

  public LocalDateTime getReviewTime() {
    return reviewTime;
  }

  public void setReviewTime(LocalDateTime value) {
    this.reviewTime = value;
  }

  /** 生效时间；审核通过后事务更新原成绩 */
  @TableField("apply_time")
  private LocalDateTime applyTime;

  public LocalDateTime getApplyTime() {
    return applyTime;
  }

  public void setApplyTime(LocalDateTime value) {
    this.applyTime = value;
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
