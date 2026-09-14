package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 成绩表：保存选课成绩、绩点及发布状态。数据库字段使用下画线。 */
@TableName("`grade`")
public class Grade {
  /** 成绩ID；自增长类型 */
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

  /** 审核ID；grade_review(id)；查询索引 */
  @TableField("review_id")
  private Long reviewId;

  public Long getReviewId() {
    return reviewId;
  }

  public void setReviewId(Long value) {
    this.reviewId = value;
  }

  /** 平时成绩；草稿可空；范围0至100 */
  @TableField("usual_score")
  private BigDecimal usualScore;

  public BigDecimal getUsualScore() {
    return usualScore;
  }

  public void setUsualScore(BigDecimal value) {
    this.usualScore = value;
  }

  /** 期末成绩；草稿或缺考可空 */
  @TableField("final_score")
  private BigDecimal finalScore;

  public BigDecimal getFinalScore() {
    return finalScore;
  }

  public void setFinalScore(BigDecimal value) {
    this.finalScore = value;
  }

  /** 总评成绩；按权重计算；范围0至100 */
  @TableField("total_score")
  private BigDecimal totalScore;

  public BigDecimal getTotalScore() {
    return totalScore;
  }

  public void setTotalScore(BigDecimal value) {
    this.totalScore = value;
  }

  /** 绩点；按学校绩点规则计算 */
  @TableField("grade_point")
  private BigDecimal gradePoint;

  public BigDecimal getGradePoint() {
    return gradePoint;
  }

  public void setGradePoint(BigDecimal value) {
    this.gradePoint = value;
  }

  /** 考试标记；0正常；1缺考；2缓考；3免修 */
  @TableField("exam_flag")
  private Integer examFlag;

  public Integer getExamFlag() {
    return examFlag;
  }

  public void setExamFlag(Integer value) {
    this.examFlag = value;
  }

  /** 成绩状态；0草稿；1待审；2退回；3发布 */
  @TableField("grade_status")
  private Integer gradeStatus;

  public Integer getGradeStatus() {
    return gradeStatus;
  }

  public void setGradeStatus(Integer value) {
    this.gradeStatus = value;
  }

  /** 录入人ID；user(id) */
  @TableField("operator_id")
  private Long operatorId;

  public Long getOperatorId() {
    return operatorId;
  }

  public void setOperatorId(Long value) {
    this.operatorId = value;
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

  /** 版本号； */
  @TableField("version")
  private Integer version;

  public Integer getVersion() {
    return version;
  }

  public void setVersion(Integer value) {
    this.version = value;
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
