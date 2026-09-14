package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 操作审计日志表：留痕登录、授权、审批、账务和敏感查询。数据库字段使用下画线。 */
@TableName("`audit_log`")
public class AuditLog {
  /** 日志ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 操作人ID；user(id)；系统任务或登录失败可空；组合查询索引 */
  @TableField("operator_id")
  private Long operatorId;

  public Long getOperatorId() {
    return operatorId;
  }

  public void setOperatorId(Long value) {
    this.operatorId = value;
  }

  /** 操作类型； */
  @TableField("action_type")
  private String actionType;

  public String getActionType() {
    return actionType;
  }

  public void setActionType(String value) {
    this.actionType = value;
  }

  /** 业务类型；组合查询索引 */
  @TableField("biz_type")
  private String bizType;

  public String getBizType() {
    return bizType;
  }

  public void setBizType(String value) {
    this.bizType = value;
  }

  /** 业务ID；逻辑引用；不随业务删除 */
  @TableField("biz_id")
  private Long bizId;

  public Long getBizId() {
    return bizId;
  }

  public void setBizId(Long value) {
    this.bizId = value;
  }

  /** 请求标识； */
  @TableField("request_id")
  private String requestId;

  public String getRequestId() {
    return requestId;
  }

  public void setRequestId(String value) {
    this.requestId = value;
  }

  /** 来源地址； */
  @TableField("ip_address")
  private String ipAddress;

  public String getIpAddress() {
    return ipAddress;
  }

  public void setIpAddress(String value) {
    this.ipAddress = value;
  }

  /** 变更摘要；保存脱敏前后值；不记凭据 */
  @TableField("change_data")
  private String changeData;

  public String getChangeData() {
    return changeData;
  }

  public void setChangeData(String value) {
    this.changeData = value;
  }

  /** 操作结果；0失败；1成功 */
  @TableField("result_status")
  private Integer resultStatus;

  public Integer getResultStatus() {
    return resultStatus;
  }

  public void setResultStatus(Integer value) {
    this.resultStatus = value;
  }

  /** 二次确认；0否；1是 */
  @TableField("confirmed")
  private Integer confirmed;

  public Integer getConfirmed() {
    return confirmed;
  }

  public void setConfirmed(Integer value) {
    this.confirmed = value;
  }

  /** 操作时间； */
  @TableField("operate_time")
  private LocalDateTime operateTime;

  public LocalDateTime getOperateTime() {
    return operateTime;
  }

  public void setOperateTime(LocalDateTime value) {
    this.operateTime = value;
  }
}
