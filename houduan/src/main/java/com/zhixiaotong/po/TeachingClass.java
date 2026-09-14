package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 教学班表：设置开课教师、容量与成绩计算规则。数据库字段使用下画线。 */
@TableName("`teaching_class`")
public class TeachingClass {
  /** 教学班ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 教学班编码； */
  @TableField("class_code")
  private String classCode;

  public String getClassCode() {
    return classCode;
  }

  public void setClassCode(String value) {
    this.classCode = value;
  }

  /** 课程ID；course(id) */
  @TableField("course_id")
  private Long courseId;

  public Long getCourseId() {
    return courseId;
  }

  public void setCourseId(Long value) {
    this.courseId = value;
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

  /** 教师ID；user(id) */
  @TableField("teacher_id")
  private Long teacherId;

  public Long getTeacherId() {
    return teacherId;
  }

  public void setTeacherId(Long value) {
    this.teacherId = value;
  }

  /** 教学班名称； */
  @TableField("class_name")
  private String className;

  public String getClassName() {
    return className;
  }

  public void setClassName(String value) {
    this.className = value;
  }

  /** 容量；大于0 */
  @TableField("capacity")
  private Integer capacity;

  public Integer getCapacity() {
    return capacity;
  }

  public void setCapacity(Integer value) {
    this.capacity = value;
  }

  /** 已选人数；仅成功选课计数；原子更新 */
  @TableField("enrolled_count")
  private Integer enrolledCount;

  public Integer getEnrolledCount() {
    return enrolledCount;
  }

  public void setEnrolledCount(Integer value) {
    this.enrolledCount = value;
  }

  /** 平时权重；0至1 */
  @TableField("usual_weight")
  private BigDecimal usualWeight;

  public BigDecimal getUsualWeight() {
    return usualWeight;
  }

  public void setUsualWeight(BigDecimal value) {
    this.usualWeight = value;
  }

  /** 期末权重；两项权重之和为1 */
  @TableField("final_weight")
  private BigDecimal finalWeight;

  public BigDecimal getFinalWeight() {
    return finalWeight;
  }

  public void setFinalWeight(BigDecimal value) {
    this.finalWeight = value;
  }

  /** 版本号；容量更新并发控制 */
  @TableField("version")
  private Integer version;

  public Integer getVersion() {
    return version;
  }

  public void setVersion(Integer value) {
    this.version = value;
  }

  /** 教学班状态；0未开；1开放；2结课 */
  @TableField("class_status")
  private Integer classStatus;

  public Integer getClassStatus() {
    return classStatus;
  }

  public void setClassStatus(Integer value) {
    this.classStatus = value;
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
