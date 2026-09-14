package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 考试安排表：保存课程考试地点、时间及监考安排。数据库字段使用下画线。 */
@TableName("`exam_plan`")
public class ExamPlan {
  /** 考试ID；自增长类型 */
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

  /** 教室ID；classroom(id) */
  @TableField("classroom_id")
  private Long classroomId;

  public Long getClassroomId() {
    return classroomId;
  }

  public void setClassroomId(Long value) {
    this.classroomId = value;
  }

  /** 考试名称； */
  @TableField("exam_name")
  private String examName;

  public String getExamName() {
    return examName;
  }

  public void setExamName(String value) {
    this.examName = value;
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

  /** 主监考ID；user(id)；组合查询索引 */
  @TableField("invigilator_id")
  private Long invigilatorId;

  public Long getInvigilatorId() {
    return invigilatorId;
  }

  public void setInvigilatorId(Long value) {
    this.invigilatorId = value;
  }

  /** 副监考ID；user(id) */
  @TableField("assistant_id")
  private Long assistantId;

  public Long getAssistantId() {
    return assistantId;
  }

  public void setAssistantId(Long value) {
    this.assistantId = value;
  }

  /** 安排状态；0草稿；1发布；2取消 */
  @TableField("plan_status")
  private Integer planStatus;

  public Integer getPlanStatus() {
    return planStatus;
  }

  public void setPlanStatus(Integer value) {
    this.planStatus = value;
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
