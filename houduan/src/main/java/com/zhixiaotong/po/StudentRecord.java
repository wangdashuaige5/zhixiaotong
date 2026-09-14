package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 学生奖惩记录表：登记奖励、处分及撤销情况。数据库字段使用下画线。 */
@TableName("`student_record`")
public class StudentRecord {
  /** 记录ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 学生ID；user(id)；组合查询索引 */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 记录类型；1奖励；2处分 */
  @TableField("record_type")
  private Integer recordType;

  public Integer getRecordType() {
    return recordType;
  }

  public void setRecordType(Integer value) {
    this.recordType = value;
  }

  /** 事项名称； */
  @TableField("record_title")
  private String recordTitle;

  public String getRecordTitle() {
    return recordTitle;
  }

  public void setRecordTitle(String value) {
    this.recordTitle = value;
  }

  /** 事项级别； */
  @TableField("record_level")
  private String recordLevel;

  public String getRecordLevel() {
    return recordLevel;
  }

  public void setRecordLevel(String value) {
    this.recordLevel = value;
  }

  /** 事项说明； */
  @TableField("description")
  private String description;

  public String getDescription() {
    return description;
  }

  public void setDescription(String value) {
    this.description = value;
  }

  /** 发生日期； */
  @TableField("record_date")
  private LocalDate recordDate;

  public LocalDate getRecordDate() {
    return recordDate;
  }

  public void setRecordDate(LocalDate value) {
    this.recordDate = value;
  }

  /** 登记人ID；user(id) */
  @TableField("operator_id")
  private Long operatorId;

  public Long getOperatorId() {
    return operatorId;
  }

  public void setOperatorId(Long value) {
    this.operatorId = value;
  }

  /** 记录状态；1有效；2撤销 */
  @TableField("record_status")
  private Integer recordStatus;

  public Integer getRecordStatus() {
    return recordStatus;
  }

  public void setRecordStatus(Integer value) {
    this.recordStatus = value;
  }

  /** 撤销原因； */
  @TableField("revoke_reason")
  private String revokeReason;

  public String getRevokeReason() {
    return revokeReason;
  }

  public void setRevokeReason(String value) {
    this.revokeReason = value;
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
