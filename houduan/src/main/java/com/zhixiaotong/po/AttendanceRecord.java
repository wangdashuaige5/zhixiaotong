package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 课程签到记录表：记录学生签到结果并避免重复签到。数据库字段使用下画线。 */
@TableName("`attendance_record`")
public class AttendanceRecord {
  /** 签到ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 签到任务ID；attendance_task(id) */
  @TableField("task_id")
  private Long taskId;

  public Long getTaskId() {
    return taskId;
  }

  public void setTaskId(Long value) {
    this.taskId = value;
  }

  /** 学生ID；user(id)；与签到任务ID联合唯一 */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 签到结果；0待签；1已签；2迟到；3请假；4缺勤 */
  @TableField("sign_status")
  private Integer signStatus;

  public Integer getSignStatus() {
    return signStatus;
  }

  public void setSignStatus(Integer value) {
    this.signStatus = value;
  }

  /** 签到时间； */
  @TableField("sign_time")
  private LocalDateTime signTime;

  public LocalDateTime getSignTime() {
    return signTime;
  }

  public void setSignTime(LocalDateTime value) {
    this.signTime = value;
  }

  /** 设备ID；device(id) */
  @TableField("device_id")
  private Long deviceId;

  public Long getDeviceId() {
    return deviceId;
  }

  public void setDeviceId(Long value) {
    this.deviceId = value;
  }

  /** 备注；须验证在课名单和任务有效期 */
  @TableField("remark")
  private String remark;

  public String getRemark() {
    return remark;
  }

  public void setRemark(String value) {
    this.remark = value;
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
