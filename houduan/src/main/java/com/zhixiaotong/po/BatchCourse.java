package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 批次课程关联表：指定批次可选教学班及超选处理方式。数据库字段使用下画线。 */
@TableName("`batch_course`")
public class BatchCourse {
  /** 关联ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 批次ID；selection_batch(id) */
  @TableField("batch_id")
  private Long batchId;

  public Long getBatchId() {
    return batchId;
  }

  public void setBatchId(Long value) {
    this.batchId = value;
  }

  /** 教学班ID；teaching_class(id)；与批次ID联合唯一 */
  @TableField("teaching_class_id")
  private Long teachingClassId;

  public Long getTeachingClassId() {
    return teachingClassId;
  }

  public void setTeachingClassId(Long value) {
    this.teachingClassId = value;
  }

  /** 录取方式；1先到先得；2抽签；3优先级 */
  @TableField("admission_type")
  private Integer admissionType;

  public Integer getAdmissionType() {
    return admissionType;
  }

  public void setAdmissionType(Integer value) {
    this.admissionType = value;
  }

  /** 优先级规则；方式3必填；保存规则及版本 */
  @TableField("priority_rule")
  private String priorityRule;

  public String getPriorityRule() {
    return priorityRule;
  }

  public void setPriorityRule(String value) {
    this.priorityRule = value;
  }

  /** 处理状态；0未处理；1处理中；2完成 */
  @TableField("process_status")
  private Integer processStatus;

  public Integer getProcessStatus() {
    return processStatus;
  }

  public void setProcessStatus(Integer value) {
    this.processStatus = value;
  }

  /** 处理时间； */
  @TableField("process_time")
  private LocalDateTime processTime;

  public LocalDateTime getProcessTime() {
    return processTime;
  }

  public void setProcessTime(LocalDateTime value) {
    this.processTime = value;
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
