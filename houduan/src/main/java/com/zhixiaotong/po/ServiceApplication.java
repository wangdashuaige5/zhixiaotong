package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 学生办事申请表：统一保存证明开具与毕业离校申请。数据库字段使用下画线。 */
@TableName("`service_application`")
public class ServiceApplication {
  /** 申请ID；自增长类型 */
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

  /** 事项类型；1证明开具；2毕业离校 */
  @TableField("service_type")
  private Integer serviceType;

  public Integer getServiceType() {
    return serviceType;
  }

  public void setServiceType(Integer value) {
    this.serviceType = value;
  }

  /** 事项名称； */
  @TableField("service_name")
  private String serviceName;

  public String getServiceName() {
    return serviceName;
  }

  public void setServiceName(String value) {
    this.serviceName = value;
  }

  /** 申请内容；按事项模板校验；敏感项加密 */
  @TableField("apply_data")
  private String applyData;

  public String getApplyData() {
    return applyData;
  }

  public void setApplyData(String value) {
    this.applyData = value;
  }

  /** 办理状态；0草稿；1办理中；2办结；3退回；4撤回 */
  @TableField("service_status")
  private Integer serviceStatus;

  public Integer getServiceStatus() {
    return serviceStatus;
  }

  public void setServiceStatus(Integer value) {
    this.serviceStatus = value;
  }

  /** 结果文件ID；file_upload(id) */
  @TableField("result_file_id")
  private Long resultFileId;

  public Long getResultFileId() {
    return resultFileId;
  }

  public void setResultFileId(Long value) {
    this.resultFileId = value;
  }

  /** 提交时间； */
  @TableField("submit_time")
  private LocalDateTime submitTime;

  public LocalDateTime getSubmitTime() {
    return submitTime;
  }

  public void setSubmitTime(LocalDateTime value) {
    this.submitTime = value;
  }

  /** 办结时间； */
  @TableField("finish_time")
  private LocalDateTime finishTime;

  public LocalDateTime getFinishTime() {
    return finishTime;
  }

  public void setFinishTime(LocalDateTime value) {
    this.finishTime = value;
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
