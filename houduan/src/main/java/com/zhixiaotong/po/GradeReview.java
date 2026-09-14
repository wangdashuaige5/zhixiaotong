package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 成绩审核表：记录院系教学秘书每轮审核结论。数据库字段使用下画线。 */
@TableName("`grade_review`")
public class GradeReview {
  /** 审核ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 教学班ID；teaching_class(id) */
  @TableField("teaching_class_id")
  private Long teachingClassId;

  public Long getTeachingClassId() {
    return teachingClassId;
  }

  public void setTeachingClassId(Long value) {
    this.teachingClassId = value;
  }

  /** 审核轮次；与教学班ID联合唯一 */
  @TableField("review_round")
  private Integer reviewRound;

  public Integer getReviewRound() {
    return reviewRound;
  }

  public void setReviewRound(Integer value) {
    this.reviewRound = value;
  }

  /** 提交人ID；user(id) */
  @TableField("submitter_id")
  private Long submitterId;

  public Long getSubmitterId() {
    return submitterId;
  }

  public void setSubmitterId(Long value) {
    this.submitterId = value;
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

  /** 成绩快照；提交时各成绩ID、版本与数值 */
  @TableField("grade_snapshot")
  private String gradeSnapshot;

  public String getGradeSnapshot() {
    return gradeSnapshot;
  }

  public void setGradeSnapshot(String value) {
    this.gradeSnapshot = value;
  }

  /** 异常提示；成绩分布异常及处理说明 */
  @TableField("warning_note")
  private String warningNote;

  public String getWarningNote() {
    return warningNote;
  }

  public void setWarningNote(String value) {
    this.warningNote = value;
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

  /** 审核状态；0待审；1通过；2退回 */
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
