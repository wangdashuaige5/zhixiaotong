package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 图书预约表：记录预约队列、到书通知与取书期限。数据库字段使用下画线。 */
@TableName("`book_reservation`")
public class BookReservation {
  /** 预约ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 读者ID；user(id)；锁定读者行；同书仅一条有效预约；组合查询索引 */
  @TableField("reader_id")
  private Long readerId;

  public Long getReaderId() {
    return readerId;
  }

  public void setReaderId(Long value) {
    this.readerId = value;
  }

  /** 图书ID；book(id)；组合查询索引 */
  @TableField("book_id")
  private Long bookId;

  public Long getBookId() {
    return bookId;
  }

  public void setBookId(Long value) {
    this.bookId = value;
  }

  /** 留置副本ID；book_copy(id) */
  @TableField("copy_id")
  private Long copyId;

  public Long getCopyId() {
    return copyId;
  }

  public void setCopyId(Long value) {
    this.copyId = value;
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

  /** 预约时间； */
  @TableField("reserve_time")
  private LocalDateTime reserveTime;

  public LocalDateTime getReserveTime() {
    return reserveTime;
  }

  public void setReserveTime(LocalDateTime value) {
    this.reserveTime = value;
  }

  /** 取书截止； */
  @TableField("expire_time")
  private LocalDateTime expireTime;

  public LocalDateTime getExpireTime() {
    return expireTime;
  }

  public void setExpireTime(LocalDateTime value) {
    this.expireTime = value;
  }

  /** 预约状态；0排队；1可取；2完成；3取消；4过期 */
  @TableField("reserve_status")
  private Integer reserveStatus;

  public Integer getReserveStatus() {
    return reserveStatus;
  }

  public void setReserveStatus(Integer value) {
    this.reserveStatus = value;
  }

  /** 通知时间； */
  @TableField("notify_time")
  private LocalDateTime notifyTime;

  public LocalDateTime getNotifyTime() {
    return notifyTime;
  }

  public void setNotifyTime(LocalDateTime value) {
    this.notifyTime = value;
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
