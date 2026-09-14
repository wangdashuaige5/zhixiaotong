package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 教学评价表：记录学生对已选课程的教学评价。数据库字段使用下画线。 */
@TableName("`teaching_evaluation`")
public class TeachingEvaluation {
  /** 评价ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 选课ID；enrollment(id) */
  @TableField("enrollment_id")
  private Long enrollmentId;

  public Long getEnrollmentId() {
    return enrollmentId;
  }

  public void setEnrollmentId(Long value) {
    this.enrollmentId = value;
  }

  /** 综合评分；0至100 */
  @TableField("total_score")
  private BigDecimal totalScore;

  public BigDecimal getTotalScore() {
    return totalScore;
  }

  public void setTotalScore(BigDecimal value) {
    this.totalScore = value;
  }

  /** 指标评分；按系统配置保存指标及分值 */
  @TableField("item_scores")
  private String itemScores;

  public String getItemScores() {
    return itemScores;
  }

  public void setItemScores(String value) {
    this.itemScores = value;
  }

  /** 评价意见； */
  @TableField("comment")
  private String comment;

  public String getComment() {
    return comment;
  }

  public void setComment(String value) {
    this.comment = value;
  }

  /** 匿名展示；0否；1是；教师端隐藏身份 */
  @TableField("is_anonymous")
  private Integer isAnonymous;

  public Integer getIsAnonymous() {
    return isAnonymous;
  }

  public void setIsAnonymous(Integer value) {
    this.isAnonymous = value;
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
}
