package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 作业表：发布课程作业、截止时间和评分标准。数据库字段使用下画线。 */
@TableName("`assignment`")
public class Assignment {
  /** 作业ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 教学班ID；teaching_class(id)；查询索引 */
  @TableField("teaching_class_id")
  private Long teachingClassId;

  public Long getTeachingClassId() {
    return teachingClassId;
  }

  public void setTeachingClassId(Long value) {
    this.teachingClassId = value;
  }

  /** 教师ID；user(id) */
  @TableField("teacher_id")
  private Long teacherId;

  public Long getTeacherId() {
    return teacherId;
  }

  public void setTeacherId(Long value) {
    this.teacherId = value;
  }

  /** 作业标题； */
  @TableField("assignment_title")
  private String assignmentTitle;

  public String getAssignmentTitle() {
    return assignmentTitle;
  }

  public void setAssignmentTitle(String value) {
    this.assignmentTitle = value;
  }

  /** 作业内容； */
  @TableField("content")
  private String content;

  public String getContent() {
    return content;
  }

  public void setContent(String value) {
    this.content = value;
  }

  /** 评分标准； */
  @TableField("grading_rule")
  private String gradingRule;

  public String getGradingRule() {
    return gradingRule;
  }

  public void setGradingRule(String value) {
    this.gradingRule = value;
  }

  /** 满分；大于0 */
  @TableField("max_score")
  private BigDecimal maxScore;

  public BigDecimal getMaxScore() {
    return maxScore;
  }

  public void setMaxScore(BigDecimal value) {
    this.maxScore = value;
  }

  /** 截止时间； */
  @TableField("deadline")
  private LocalDateTime deadline;

  public LocalDateTime getDeadline() {
    return deadline;
  }

  public void setDeadline(LocalDateTime value) {
    this.deadline = value;
  }

  /** 允许补交；0否；1是 */
  @TableField("allow_late")
  private Integer allowLate;

  public Integer getAllowLate() {
    return allowLate;
  }

  public void setAllowLate(Integer value) {
    this.allowLate = value;
  }

  /** 发布状态；0草稿；1发布；2关闭 */
  @TableField("publish_status")
  private Integer publishStatus;

  public Integer getPublishStatus() {
    return publishStatus;
  }

  public void setPublishStatus(Integer value) {
    this.publishStatus = value;
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
