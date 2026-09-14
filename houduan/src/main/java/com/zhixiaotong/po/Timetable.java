package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 课表信息表：记录周次、节次、星期与上课教室。数据库字段使用下画线。 */
@TableName("`timetable`")
public class Timetable {
  /** 课表ID；自增长类型 */
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

  /** 教室ID；classroom(id)；组合查询索引 */
  @TableField("classroom_id")
  private Long classroomId;

  public Long getClassroomId() {
    return classroomId;
  }

  public void setClassroomId(Long value) {
    this.classroomId = value;
  }

  /** 开始周；从1开始 */
  @TableField("start_week")
  private Integer startWeek;

  public Integer getStartWeek() {
    return startWeek;
  }

  public void setStartWeek(Integer value) {
    this.startWeek = value;
  }

  /** 结束周； */
  @TableField("end_week")
  private Integer endWeek;

  public Integer getEndWeek() {
    return endWeek;
  }

  public void setEndWeek(Integer value) {
    this.endWeek = value;
  }

  /** 周次模式；1每周；2单周；3双周 */
  @TableField("week_mode")
  private Integer weekMode;

  public Integer getWeekMode() {
    return weekMode;
  }

  public void setWeekMode(Integer value) {
    this.weekMode = value;
  }

  /** 星期；1至7对应周一至周日 */
  @TableField("week_day")
  private Integer weekDay;

  public Integer getWeekDay() {
    return weekDay;
  }

  public void setWeekDay(Integer value) {
    this.weekDay = value;
  }

  /** 起始节次； */
  @TableField("start_period")
  private Integer startPeriod;

  public Integer getStartPeriod() {
    return startPeriod;
  }

  public void setStartPeriod(Integer value) {
    this.startPeriod = value;
  }

  /** 结束节次； */
  @TableField("end_period")
  private Integer endPeriod;

  public Integer getEndPeriod() {
    return endPeriod;
  }

  public void setEndPeriod(Integer value) {
    this.endPeriod = value;
  }

  /** 上课时间； */
  @TableField("start_time")
  private LocalTime startTime;

  public LocalTime getStartTime() {
    return startTime;
  }

  public void setStartTime(LocalTime value) {
    this.startTime = value;
  }

  /** 下课时间；需校验学生、教师及教室冲突 */
  @TableField("end_time")
  private LocalTime endTime;

  public LocalTime getEndTime() {
    return endTime;
  }

  public void setEndTime(LocalTime value) {
    this.endTime = value;
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
