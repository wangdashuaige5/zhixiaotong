package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 辅导员班级关联表：记录辅导员所辖班级及授权有效期。数据库字段使用下画线。 */
@TableName("`counselor_class`")
public class CounselorClass {
  /** 关联ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 辅导员ID；user(id) */
  @TableField("counselor_id")
  private Long counselorId;

  public Long getCounselorId() {
    return counselorId;
  }

  public void setCounselorId(Long value) {
    this.counselorId = value;
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

  /** 生效时间；与辅导员ID、班级ID联合唯一 */
  @TableField("start_time")
  private LocalDateTime startTime;

  public LocalDateTime getStartTime() {
    return startTime;
  }

  public void setStartTime(LocalDateTime value) {
    this.startTime = value;
  }

  /** 失效时间；须晚于生效时间 */
  @TableField("end_time")
  private LocalDateTime endTime;

  public LocalDateTime getEndTime() {
    return endTime;
  }

  public void setEndTime(LocalDateTime value) {
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
