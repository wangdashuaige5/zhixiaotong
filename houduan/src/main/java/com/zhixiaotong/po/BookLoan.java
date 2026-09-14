package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 图书借阅记录表：保存借出、到期、续借与归还记录。数据库字段使用下画线。 */
@TableName("`book_loan`")
public class BookLoan {
  /** 借阅ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 读者ID；user(id)；组合查询索引 */
  @TableField("reader_id")
  private Long readerId;

  public Long getReaderId() {
    return readerId;
  }

  public void setReaderId(Long value) {
    this.readerId = value;
  }

  /** 副本ID；book_copy(id)；事务锁定副本；同册仅一笔未还；组合查询索引 */
  @TableField("copy_id")
  private Long copyId;

  public Long getCopyId() {
    return copyId;
  }

  public void setCopyId(Long value) {
    this.copyId = value;
  }

  /** 外部借阅号； */
  @TableField("external_loan_no")
  private String externalLoanNo;

  public String getExternalLoanNo() {
    return externalLoanNo;
  }

  public void setExternalLoanNo(String value) {
    this.externalLoanNo = value;
  }

  /** 借出时间； */
  @TableField("borrow_time")
  private LocalDateTime borrowTime;

  public LocalDateTime getBorrowTime() {
    return borrowTime;
  }

  public void setBorrowTime(LocalDateTime value) {
    this.borrowTime = value;
  }

  /** 应还时间； */
  @TableField("due_time")
  private LocalDateTime dueTime;

  public LocalDateTime getDueTime() {
    return dueTime;
  }

  public void setDueTime(LocalDateTime value) {
    this.dueTime = value;
  }

  /** 归还时间； */
  @TableField("return_time")
  private LocalDateTime returnTime;

  public LocalDateTime getReturnTime() {
    return returnTime;
  }

  public void setReturnTime(LocalDateTime value) {
    this.returnTime = value;
  }

  /** 续借次数； */
  @TableField("renew_count")
  private Integer renewCount;

  public Integer getRenewCount() {
    return renewCount;
  }

  public void setRenewCount(Integer value) {
    this.renewCount = value;
  }

  /** 最近续借； */
  @TableField("renew_time")
  private LocalDateTime renewTime;

  public LocalDateTime getRenewTime() {
    return renewTime;
  }

  public void setRenewTime(LocalDateTime value) {
    this.renewTime = value;
  }

  /** 借阅状态；0借阅中；1已归还；2挂失 */
  @TableField("loan_status")
  private Integer loanStatus;

  public Integer getLoanStatus() {
    return loanStatus;
  }

  public void setLoanStatus(Integer value) {
    this.loanStatus = value;
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
