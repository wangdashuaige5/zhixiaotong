package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 课程先修条件表：定义选课前必须通过的先修课程。数据库字段使用下画线。 */
@TableName("`course_prereq`")
public class CoursePrereq {
  /** 条件ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
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

  /** 先修课程ID；course(id)；禁止自指及循环依赖；与课程ID联合唯一 */
  @TableField("prereq_id")
  private Long prereqId;

  public Long getPrereqId() {
    return prereqId;
  }

  public void setPrereqId(Long value) {
    this.prereqId = value;
  }

  /** 最低成绩；取已发布成绩；范围0至100 */
  @TableField("min_score")
  private BigDecimal minScore;

  public BigDecimal getMinScore() {
    return minScore;
  }

  public void setMinScore(BigDecimal value) {
    this.minScore = value;
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
