package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 校园卡账户表：保存校园卡绑定关系及入账余额。数据库字段使用下画线。 */
@TableName("`card_account`")
public class CardAccount {
  /** 账户ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 用户ID；user(id) */
  @TableField("user_id")
  private Long userId;

  public Long getUserId() {
    return userId;
  }

  public void setUserId(Long value) {
    this.userId = value;
  }

  /** 校园卡号； */
  @TableField("card_no")
  private String cardNo;

  public String getCardNo() {
    return cardNo;
  }

  public void setCardNo(String value) {
    this.cardNo = value;
  }

  /** 账户余额；单位元；禁止负值 */
  @TableField("balance")
  private BigDecimal balance;

  public BigDecimal getBalance() {
    return balance;
  }

  public void setBalance(BigDecimal value) {
    this.balance = value;
  }

  /** 账户状态；0冻结；1正常；2注销 */
  @TableField("account_status")
  private Integer accountStatus;

  public Integer getAccountStatus() {
    return accountStatus;
  }

  public void setAccountStatus(Integer value) {
    this.accountStatus = value;
  }

  /** 版本号；账务并发控制 */
  @TableField("version")
  private Integer version;

  public Integer getVersion() {
    return version;
  }

  public void setVersion(Integer value) {
    this.version = value;
  }

  /** 同步时间；外部卡系统对账时间 */
  @TableField("sync_time")
  private LocalDateTime syncTime;

  public LocalDateTime getSyncTime() {
    return syncTime;
  }

  public void setSyncTime(LocalDateTime value) {
    this.syncTime = value;
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
