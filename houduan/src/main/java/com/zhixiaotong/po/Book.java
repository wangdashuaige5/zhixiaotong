package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 图书书目表：保存图书检索所需的书目信息。数据库字段使用下画线。 */
@TableName("`book`")
public class Book {
  /** 图书ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 书目编码； */
  @TableField("book_code")
  private String bookCode;

  public String getBookCode() {
    return bookCode;
  }

  public void setBookCode(String value) {
    this.bookCode = value;
  }

  /** ISBN；查询索引 */
  @TableField("isbn")
  private String isbn;

  public String getIsbn() {
    return isbn;
  }

  public void setIsbn(String value) {
    this.isbn = value;
  }

  /** 书名；查询索引 */
  @TableField("book_name")
  private String bookName;

  public String getBookName() {
    return bookName;
  }

  public void setBookName(String value) {
    this.bookName = value;
  }

  /** 作者； */
  @TableField("author")
  private String author;

  public String getAuthor() {
    return author;
  }

  public void setAuthor(String value) {
    this.author = value;
  }

  /** 出版社； */
  @TableField("publisher")
  private String publisher;

  public String getPublisher() {
    return publisher;
  }

  public void setPublisher(String value) {
    this.publisher = value;
  }

  /** 分类编码；查询索引 */
  @TableField("category_code")
  private String categoryCode;

  public String getCategoryCode() {
    return categoryCode;
  }

  public void setCategoryCode(String value) {
    this.categoryCode = value;
  }

  /** 内容简介； */
  @TableField("summary")
  private String summary;

  public String getSummary() {
    return summary;
  }

  public void setSummary(String value) {
    this.summary = value;
  }

  /** 封面ID；file_upload(id) */
  @TableField("cover_id")
  private Long coverId;

  public Long getCoverId() {
    return coverId;
  }

  public void setCoverId(Long value) {
    this.coverId = value;
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
