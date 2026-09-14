package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 充值订单表：通过验签支付回调确认充值并防重。数据库字段使用下画线。 */
@TableName("`recharge_order`")
public class RechargeOrder {
  /** 订单ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 充值单号； */
  @TableField("order_no")
  private String orderNo;

  public String getOrderNo() {
    return orderNo;
  }

  public void setOrderNo(String value) {
    this.orderNo = value;
  }

  /** 账户ID；card_account(id)；组合查询索引 */
  @TableField("account_id")
  private Long accountId;

  public Long getAccountId() {
    return accountId;
  }

  public void setAccountId(Long value) {
    this.accountId = value;
  }

  /** 充值金额；单位元；必须大于0 */
  @TableField("amount")
  private BigDecimal amount;

  public BigDecimal getAmount() {
    return amount;
  }

  public void setAmount(BigDecimal value) {
    this.amount = value;
  }

  /** 支付渠道； */
  @TableField("pay_channel")
  private String payChannel;

  public String getPayChannel() {
    return payChannel;
  }

  public void setPayChannel(String value) {
    this.payChannel = value;
  }

  /** 支付流水号；与支付渠道联合唯一 */
  @TableField("pay_trade_no")
  private String payTradeNo;

  public String getPayTradeNo() {
    return payTradeNo;
  }

  public void setPayTradeNo(String value) {
    this.payTradeNo = value;
  }

  /** 幂等键； */
  @TableField("request_key")
  private String requestKey;

  public String getRequestKey() {
    return requestKey;
  }

  public void setRequestKey(String value) {
    this.requestKey = value;
  }

  /** 订单状态；0待付；1支付成功待入账；2已入账；3关闭 */
  @TableField("order_status")
  private Integer orderStatus;

  public Integer getOrderStatus() {
    return orderStatus;
  }

  public void setOrderStatus(Integer value) {
    this.orderStatus = value;
  }

  /** 支付时间； */
  @TableField("pay_time")
  private LocalDateTime payTime;

  public LocalDateTime getPayTime() {
    return payTime;
  }

  public void setPayTime(LocalDateTime value) {
    this.payTime = value;
  }

  /** 回调时间；验签并核对金额及订单 */
  @TableField("callback_time")
  private LocalDateTime callbackTime;

  public LocalDateTime getCallbackTime() {
    return callbackTime;
  }

  public void setCallbackTime(LocalDateTime value) {
    this.callbackTime = value;
  }

  /** 入账时间；与余额及流水同一事务 */
  @TableField("posted_time")
  private LocalDateTime postedTime;

  public LocalDateTime getPostedTime() {
    return postedTime;
  }

  public void setPostedTime(LocalDateTime value) {
    this.postedTime = value;
  }

  /** 过期时间； */
  @TableField("expire_time")
  private LocalDateTime expireTime;

  public LocalDateTime getExpireTime() {
    return expireTime;
  }

  public void setExpireTime(LocalDateTime value) {
    this.expireTime = value;
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
