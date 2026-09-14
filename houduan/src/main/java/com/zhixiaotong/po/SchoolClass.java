package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 班级表：维护行政班与年级归属。数据库字段使用下画线。 */
@TableName("`school_class`")
public class SchoolClass {
  /** 班级ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 班级编码； */
  @TableField("class_code")
  private String classCode;

  public String getClassCode() {
    return classCode;
  }

  public void setClassCode(String value) {
    this.classCode = value;
  }

  /** 班级名称； */
  @TableField("class_name")
  private String className;

  public String getClassName() {
    return className;
  }

  public void setClassName(String value) {
    this.className = value;
  }

  /** 年级ID；org_unit(id)；仅关联年级节点；查询索引 */
  @TableField("grade_id")
  private Long gradeId;

  public Long getGradeId() {
    return gradeId;
  }

  public void setGradeId(Long value) {
    this.gradeId = value;
  }

  /** 入学年份； */
  @TableField("entry_year")
  private Integer entryYear;

  public Integer getEntryYear() {
    return entryYear;
  }

  public void setEntryYear(Integer value) {
    this.entryYear = value;
  }

  /** 学制年数； */
  @TableField("school_years")
  private Integer schoolYears;

  public Integer getSchoolYears() {
    return schoolYears;
  }

  public void setSchoolYears(Integer value) {
    this.schoolYears = value;
  }

  /** 班级状态；0停用；1在读；2毕业 */
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
