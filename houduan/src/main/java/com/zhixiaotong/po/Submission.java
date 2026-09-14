package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 作业提交表：保存每轮提交内容、批改与退回记录。数据库字段使用下画线。 */
@TableName("`submission`")
public class Submission {
  /** 提交ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 作业ID；assignment(id) */
  @TableField("assignment_id")
  private Long assignmentId;

  public Long getAssignmentId() {
    return assignmentId;
  }

  public void setAssignmentId(Long value) {
    this.assignmentId = value;
  }

  /** 学生ID；user(id) */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 提交轮次；与作业ID、学生ID联合唯一 */
  @TableField("submit_round")
  private Integer submitRound;

  public Integer getSubmitRound() {
    return submitRound;
  }

  public void setSubmitRound(Integer value) {
    this.submitRound = value;
  }

  /** 提交内容；文本或附件至少一项 */
  @TableField("content")
  private String content;

  public String getContent() {
    return content;
  }

  public void setContent(String value) {
    this.content = value;
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

  /** 提交状态；0已提交；1退回；2已批改；3已发布 */
  @TableField("submit_status")
  private Integer submitStatus;

  public Integer getSubmitStatus() {
    return submitStatus;
  }

  public void setSubmitStatus(Integer value) {
    this.submitStatus = value;
  }

  /** 得分；0至作业满分 */
  @TableField("score")
  private BigDecimal score;

  public BigDecimal getScore() {
    return score;
  }

  public void setScore(BigDecimal value) {
    this.score = value;
  }

  /** 批改反馈； */
  @TableField("feedback")
  private String feedback;

  public String getFeedback() {
    return feedback;
  }

  public void setFeedback(String value) {
    this.feedback = value;
  }

  /** 批改人ID；user(id) */
  @TableField("grader_id")
  private Long graderId;

  public Long getGraderId() {
    return graderId;
  }

  public void setGraderId(Long value) {
    this.graderId = value;
  }

  /** 批改时间； */
  @TableField("grade_time")
  private LocalDateTime gradeTime;

  public LocalDateTime getGradeTime() {
    return gradeTime;
  }

  public void setGradeTime(LocalDateTime value) {
    this.gradeTime = value;
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
