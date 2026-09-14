package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 选课开放范围表：按组织或班级限定可选人群。数据库字段使用下画线。 */
@TableName("`selection_scope`")
public class SelectionScope {
  /** 范围ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 批次课程ID；batch_course(id) */
  @TableField("batch_course_id")
  private Long batchCourseId;

  public Long getBatchCourseId() {
    return batchCourseId;
  }

  public void setBatchCourseId(Long value) {
    this.batchCourseId = value;
  }

  /** 组织ID；org_unit(id)；与批次课程ID联合唯一 */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 班级ID；school_class(id)；与组织ID恰一非空；与批次课程ID联合唯一 */
  @TableField("class_id")
  private Long classId;

  public Long getClassId() {
    return classId;
  }

  public void setClassId(Long value) {
    this.classId = value;
  }

  /** 包含下级；0否；1是；无范围记录不开放 */
  @TableField("include_children")
  private Integer includeChildren;

  public Integer getIncludeChildren() {
    return includeChildren;
  }

  public void setIncludeChildren(Integer value) {
    this.includeChildren = value;
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
