package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 课程资源表：维护教学班课件、资料及可见范围。数据库字段使用下画线。 */
@TableName("`course_resource`")
public class CourseResource {
  /** 资源ID；自增长类型 */
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

  /** 资源标题； */
  @TableField("resource_title")
  private String resourceTitle;

  public String getResourceTitle() {
    return resourceTitle;
  }

  public void setResourceTitle(String value) {
    this.resourceTitle = value;
  }

  /** 文件ID；file_upload(id) */
  @TableField("file_id")
  private Long fileId;

  public Long getFileId() {
    return fileId;
  }

  public void setFileId(Long value) {
    this.fileId = value;
  }

  /** 上传人ID；user(id) */
  @TableField("uploader_id")
  private Long uploaderId;

  public Long getUploaderId() {
    return uploaderId;
  }

  public void setUploaderId(Long value) {
    this.uploaderId = value;
  }

  /** 可见范围；1本班学生及教师；2仅教师 */
  @TableField("visible_scope")
  private Integer visibleScope;

  public Integer getVisibleScope() {
    return visibleScope;
  }

  public void setVisibleScope(Integer value) {
    this.visibleScope = value;
  }

  /** 排序值； */
  @TableField("sort_order")
  private Integer sortOrder;

  public Integer getSortOrder() {
    return sortOrder;
  }

  public void setSortOrder(Integer value) {
    this.sortOrder = value;
  }

  /** 发布状态；0草稿；1已发布 */
  @TableField("publish_status")
  private Integer publishStatus;

  public Integer getPublishStatus() {
    return publishStatus;
  }

  public void setPublishStatus(Integer value) {
    this.publishStatus = value;
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
