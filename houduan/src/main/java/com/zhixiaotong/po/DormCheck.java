package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 查寝晚归记录表：保存学生查寝结果、晚归与处理意见。数据库字段使用下画线。 */
@TableName("`dorm_check`")
public class DormCheck {
  /** 查寝ID；自增长类型 */
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

  /** 宿舍位置； */
  @TableField("dorm_location")
  private String dormLocation;

  public String getDormLocation() {
    return dormLocation;
  }

  public void setDormLocation(String value) {
    this.dormLocation = value;
  }

  /** 检查时间； */
  @TableField("check_time")
  private LocalDateTime checkTime;

  public LocalDateTime getCheckTime() {
    return checkTime;
  }

  public void setCheckTime(LocalDateTime value) {
    this.checkTime = value;
  }

  /** 检查结果；1正常；2晚归；3未归；4已请假 */
  @TableField("check_result")
  private Integer checkResult;

  public Integer getCheckResult() {
    return checkResult;
  }

  public void setCheckResult(Integer value) {
    this.checkResult = value;
  }

  /** 返寝时间； */
  @TableField("return_time")
  private LocalDateTime returnTime;

  public LocalDateTime getReturnTime() {
    return returnTime;
  }

  public void setReturnTime(LocalDateTime value) {
    this.returnTime = value;
  }

  /** 处理意见； */
  @TableField("handle_note")
  private String handleNote;

  public String getHandleNote() {
    return handleNote;
  }

  public void setHandleNote(String value) {
    this.handleNote = value;
  }

  /** 检查人ID；user(id) */
  @TableField("checker_id")
  private Long checkerId;

  public Long getCheckerId() {
    return checkerId;
  }

  public void setCheckerId(Long value) {
    this.checkerId = value;
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
