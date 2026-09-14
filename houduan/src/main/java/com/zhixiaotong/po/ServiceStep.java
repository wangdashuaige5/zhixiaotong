package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 学生办事环节表：记录证明审核或离校各部门办理环节。数据库字段使用下画线。 */
@TableName("`service_step`")
public class ServiceStep {
  /** 环节ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 申请ID；service_application(id) */
  @TableField("application_id")
  private Long applicationId;

  public Long getApplicationId() {
    return applicationId;
  }

  public void setApplicationId(Long value) {
    this.applicationId = value;
  }

  /** 环节顺序；与申请ID联合唯一 */
  @TableField("step_order")
  private Integer stepOrder;

  public Integer getStepOrder() {
    return stepOrder;
  }

  public void setStepOrder(Integer value) {
    this.stepOrder = value;
  }

  /** 环节名称； */
  @TableField("step_name")
  private String stepName;

  public String getStepName() {
    return stepName;
  }

  public void setStepName(String value) {
    this.stepName = value;
  }

  /** 办理组织ID；org_unit(id) */
  @TableField("org_id")
  private Long orgId;

  public Long getOrgId() {
    return orgId;
  }

  public void setOrgId(Long value) {
    this.orgId = value;
  }

  /** 办理人ID；user(id) */
  @TableField("handler_id")
  private Long handlerId;

  public Long getHandlerId() {
    return handlerId;
  }

  public void setHandlerId(Long value) {
    this.handlerId = value;
  }

  /** 办理结果；0待办；1通过；2退回 */
  @TableField("decision")
  private Integer decision;

  public Integer getDecision() {
    return decision;
  }

  public void setDecision(Integer value) {
    this.decision = value;
  }

  /** 办理意见； */
  @TableField("opinion")
  private String opinion;

  public String getOpinion() {
    return opinion;
  }

  public void setOpinion(String value) {
    this.opinion = value;
  }

  /** 办理时间； */
  @TableField("handle_time")
  private LocalDateTime handleTime;

  public LocalDateTime getHandleTime() {
    return handleTime;
  }

  public void setHandleTime(LocalDateTime value) {
    this.handleTime = value;
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
