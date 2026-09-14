package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 图书馆藏副本表：区分同一书目的实体册与可借状态。数据库字段使用下画线。 */
@TableName("`book_copy`")
public class BookCopy {
  /** 副本ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
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

  /** 馆藏条码； */
  @TableField("copy_no")
  private String copyNo;

  public String getCopyNo() {
    return copyNo;
  }

  public void setCopyNo(String value) {
    this.copyNo = value;
  }

  /** 馆藏位置； */
  @TableField("location")
  private String location;

  public String getLocation() {
    return location;
  }

  public void setLocation(String value) {
    this.location = value;
  }

  /** 副本状态；0可借；1借出；2预约留置；3停用 */
  @TableField("copy_status")
  private Integer copyStatus;

  public Integer getCopyStatus() {
    return copyStatus;
  }

  public void setCopyStatus(Integer value) {
    this.copyStatus = value;
  }

  /** 版本号；借出及预约并发控制 */
  @TableField("version")
  private Integer version;

  public Integer getVersion() {
    return version;
  }

  public void setVersion(Integer value) {
    this.version = value;
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
