package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 请假审批记录表：保留每轮审批节点、审批意见和时间。数据库字段使用下画线。 */
@TableName("`leave_approval`")
public class LeaveApproval {
  /** 审批ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 请假ID；leave_request(id) */
  @TableField("leave_id")
  private Long leaveId;

  public Long getLeaveId() {
    return leaveId;
  }

  public void setLeaveId(Long value) {
    this.leaveId = value;
  }

  /** 申请轮次； */
  @TableField("apply_round")
  private Integer applyRound;

  public Integer getApplyRound() {
    return applyRound;
  }

  public void setApplyRound(Integer value) {
    this.applyRound = value;
  }

  /** 节点顺序；与请假ID、申请轮次联合唯一 */
  @TableField("node_order")
  private Integer nodeOrder;

  public Integer getNodeOrder() {
    return nodeOrder;
  }

  public void setNodeOrder(Integer value) {
    this.nodeOrder = value;
  }

  /** 节点类型；1辅导员；2院系领导 */
  @TableField("node_type")
  private Integer nodeType;

  public Integer getNodeType() {
    return nodeType;
  }

  public void setNodeType(Integer value) {
    this.nodeType = value;
  }

  /** 审批人ID；user(id)；组合查询索引 */
  @TableField("approver_id")
  private Long approverId;

  public Long getApproverId() {
    return approverId;
  }

  public void setApproverId(Long value) {
    this.approverId = value;
  }

  /** 审批结果；0待办；1同意；2驳回；3退回；4取消 */
  @TableField("decision")
  private Integer decision;

  public Integer getDecision() {
    return decision;
  }

  public void setDecision(Integer value) {
    this.decision = value;
  }

  /** 审批意见； */
  @TableField("opinion")
  private String opinion;

  public String getOpinion() {
    return opinion;
  }

  public void setOpinion(String value) {
    this.opinion = value;
  }

  /** 审批时间； */
  @TableField("approve_time")
  private LocalDateTime approveTime;

  public LocalDateTime getApproveTime() {
    return approveTime;
  }

  public void setApproveTime(LocalDateTime value) {
    this.approveTime = value;
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
