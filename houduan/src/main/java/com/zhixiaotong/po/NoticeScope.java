package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 通知范围表：限定通知对应的学校、组织、班级或课程。数据库字段使用下画线。 */
@TableName("`notice_scope`")
public class NoticeScope {
  /** 范围ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 通知ID；notice(id)；查询索引 */
  @TableField("notice_id")
  private Long noticeId;

  public Long getNoticeId() {
    return noticeId;
  }

  public void setNoticeId(Long value) {
    this.noticeId = value;
  }

  /** 范围类型；1全校；2组织；3班级；4教学班 */
  @TableField("scope_type")
  private Integer scopeType;

  public Integer getScopeType() {
    return scopeType;
  }

  public void setScopeType(Integer value) {
    this.scopeType = value;
  }

  /** 组织ID；org_unit(id) */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 班级ID；school_class(id) */
  @TableField("class_id")
  private Long classId;

  public Long getClassId() {
    return classId;
  }

  public void setClassId(Long value) {
    this.classId = value;
  }

  /** 教学班ID；teaching_class(id)；全校时均空；其他类型仅对应ID非空 */
  @TableField("teaching_class_id")
  private Long teachingClassId;

  public Long getTeachingClassId() {
    return teachingClassId;
  }

  public void setTeachingClassId(Long value) {
    this.teachingClassId = value;
  }

  /** 包含下级；0否；1是；仅组织范围有效 */
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
