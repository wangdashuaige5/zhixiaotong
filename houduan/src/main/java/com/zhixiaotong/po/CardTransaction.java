package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 校园卡流水表：保存充值、消费、退款及余额变动。数据库字段使用下画线。 */
@TableName("`card_transaction`")
public class CardTransaction {
  /** 流水ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 流水号； */
  @TableField("transaction_no")
  private String transactionNo;

  public String getTransactionNo() {
    return transactionNo;
  }

  public void setTransactionNo(String value) {
    this.transactionNo = value;
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

  /** 充值订单ID；recharge_order(id)；充值入账时必填 */
  @TableField("recharge_id")
  private Long rechargeId;

  public Long getRechargeId() {
    return rechargeId;
  }

  public void setRechargeId(Long value) {
    this.rechargeId = value;
  }

  /** 来源系统； */
  @TableField("source_system")
  private String sourceSystem;

  public String getSourceSystem() {
    return sourceSystem;
  }

  public void setSourceSystem(String value) {
    this.sourceSystem = value;
  }

  /** 来源流水号；与来源系统联合唯一 */
  @TableField("source_trade_no")
  private String sourceTradeNo;

  public String getSourceTradeNo() {
    return sourceTradeNo;
  }

  public void setSourceTradeNo(String value) {
    this.sourceTradeNo = value;
  }

  /** 交易类型；1充值；2消费；3退款 */
  @TableField("transaction_type")
  private Integer transactionType;

  public Integer getTransactionType() {
    return transactionType;
  }

  public void setTransactionType(Integer value) {
    this.transactionType = value;
  }

  /** 变动金额；单位元；收入正、支出负 */
  @TableField("amount")
  private BigDecimal amount;

  public BigDecimal getAmount() {
    return amount;
  }

  public void setAmount(BigDecimal value) {
    this.amount = value;
  }

  /** 变动前余额； */
  @TableField("balance_before")
  private BigDecimal balanceBefore;

  public BigDecimal getBalanceBefore() {
    return balanceBefore;
  }

  public void setBalanceBefore(BigDecimal value) {
    this.balanceBefore = value;
  }

  /** 变动后余额；前余额加变动金额；非负 */
  @TableField("balance_after")
  private BigDecimal balanceAfter;

  public BigDecimal getBalanceAfter() {
    return balanceAfter;
  }

  public void setBalanceAfter(BigDecimal value) {
    this.balanceAfter = value;
  }

  /** 商户名称； */
  @TableField("merchant_name")
  private String merchantName;

  public String getMerchantName() {
    return merchantName;
  }

  public void setMerchantName(String value) {
    this.merchantName = value;
  }

  /** 交易时间； */
  @TableField("transaction_time")
  private LocalDateTime transactionTime;

  public LocalDateTime getTransactionTime() {
    return transactionTime;
  }

  public void setTransactionTime(LocalDateTime value) {
    this.transactionTime = value;
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
}
