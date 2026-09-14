package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 学期表：设置学期日期、教学周和锁定状态。数据库字段使用下画线。 */
@TableName("`semester`")
public class Semester {
  /** 学期ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 学期编码； */
  @TableField("semester_code")
  private String semesterCode;

  public String getSemesterCode() {
    return semesterCode;
  }

  public void setSemesterCode(String value) {
    this.semesterCode = value;
  }

  /** 学期名称； */
  @TableField("semester_name")
  private String semesterName;

  public String getSemesterName() {
    return semesterName;
  }

  public void setSemesterName(String value) {
    this.semesterName = value;
  }

  /** 开始日期； */
  @TableField("start_date")
  private LocalDate startDate;

  public LocalDate getStartDate() {
    return startDate;
  }

  public void setStartDate(LocalDate value) {
    this.startDate = value;
  }

  /** 结束日期；不早于开始日期 */
  @TableField("end_date")
  private LocalDate endDate;

  public LocalDate getEndDate() {
    return endDate;
  }

  public void setEndDate(LocalDate value) {
    this.endDate = value;
  }

  /** 教学周数；正整数 */
  @TableField("week_count")
  private Integer weekCount;

  public Integer getWeekCount() {
    return weekCount;
  }

  public void setWeekCount(Integer value) {
    this.weekCount = value;
  }

  /** 当前学期；0否；1是；仅一条为1 */
  @TableField("is_current")
  private Integer isCurrent;

  public Integer getIsCurrent() {
    return isCurrent;
  }

  public void setIsCurrent(Integer value) {
    this.isCurrent = value;
  }

  /** 锁定状态；0未锁；1锁定 */
  @TableField("is_locked")
  private Integer isLocked;

  public Integer getIsLocked() {
    return isLocked;
  }

  public void setIsLocked(Integer value) {
    this.isLocked = value;
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
