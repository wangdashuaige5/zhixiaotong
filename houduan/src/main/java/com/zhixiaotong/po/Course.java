package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 课程表：保存课程目录、学分和课程大纲。数据库字段使用下画线。 */
@TableName("`course`")
public class Course {
  /** 课程ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 课程编码； */
  @TableField("course_code")
  private String courseCode;

  public String getCourseCode() {
    return courseCode;
  }

  public void setCourseCode(String value) {
    this.courseCode = value;
  }

  /** 课程名称； */
  @TableField("course_name")
  private String courseName;

  public String getCourseName() {
    return courseName;
  }

  public void setCourseName(String value) {
    this.courseName = value;
  }

  /** 开课组织ID；org_unit(id)；组合查询索引 */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 课程类别；关联课程类别字典 */
  @TableField("course_type")
  private String courseType;

  public String getCourseType() {
    return courseType;
  }

  public void setCourseType(String value) {
    this.courseType = value;
  }

  /** 学分；大于等于0 */
  @TableField("credit")
  private BigDecimal credit;

  public BigDecimal getCredit() {
    return credit;
  }

  public void setCredit(BigDecimal value) {
    this.credit = value;
  }

  /** 总学时；正整数 */
  @TableField("total_hours")
  private Integer totalHours;

  public Integer getTotalHours() {
    return totalHours;
  }

  public void setTotalHours(Integer value) {
    this.totalHours = value;
  }

  /** 课程大纲； */
  @TableField("syllabus")
  private String syllabus;

  public String getSyllabus() {
    return syllabus;
  }

  public void setSyllabus(String value) {
    this.syllabus = value;
  }

  /** 启用状态；0停用；1启用 */
  @TableField("is_enabled")
  private Integer isEnabled;

  public Integer getIsEnabled() {
    return isEnabled;
  }

  public void setIsEnabled(Integer value) {
    this.isEnabled = value;
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
