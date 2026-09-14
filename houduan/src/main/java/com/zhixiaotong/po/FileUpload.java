package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 文件上传记录表：保存对象存储元数据、业务归属和检测状态。数据库字段使用下画线。 */
@TableName("`file_upload`")
public class FileUpload {
  /** 文件ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 存储桶； */
  @TableField("bucket_name")
  private String bucketName;

  public String getBucketName() {
    return bucketName;
  }

  public void setBucketName(String value) {
    this.bucketName = value;
  }

  /** 对象键；与存储桶联合唯一 */
  @TableField("object_key")
  private String objectKey;

  public String getObjectKey() {
    return objectKey;
  }

  public void setObjectKey(String value) {
    this.objectKey = value;
  }

  /** 原始文件名； */
  @TableField("original_name")
  private String originalName;

  public String getOriginalName() {
    return originalName;
  }

  public void setOriginalName(String value) {
    this.originalName = value;
  }

  /** 文件类型； */
  @TableField("mime_type")
  private String mimeType;

  public String getMimeType() {
    return mimeType;
  }

  public void setMimeType(String value) {
    this.mimeType = value;
  }

  /** 文件大小；单位字节；上限100MB */
  @TableField("file_size")
  private Long fileSize;

  public Long getFileSize() {
    return fileSize;
  }

  public void setFileSize(Long value) {
    this.fileSize = value;
  }

  /** 内容哈希；SHA-256 */
  @TableField("file_hash")
  private String fileHash;

  public String getFileHash() {
    return fileHash;
  }

  public void setFileHash(String value) {
    this.fileHash = value;
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

  /** 业务ID；按类型校验；附件绑定后必填 */
  @TableField("biz_id")
  private Long bizId;

  public Long getBizId() {
    return bizId;
  }

  public void setBizId(Long value) {
    this.bizId = value;
  }

  /** 上传人ID；user(id) */
  @TableField("uploader_id")
  private Long uploaderId;

  public Long getUploaderId() {
    return uploaderId;
  }

  public void setUploaderId(Long value) {
    this.uploaderId = value;
  }

  /** 检测状态；0待检；1通过；2拒绝 */
  @TableField("scan_status")
  private Integer scanStatus;

  public Integer getScanStatus() {
    return scanStatus;
  }

  public void setScanStatus(Integer value) {
    this.scanStatus = value;
  }

  /** 文件状态；0临时；1已绑定；2待清理 */
  @TableField("file_status")
  private Integer fileStatus;

  public Integer getFileStatus() {
    return fileStatus;
  }

  public void setFileStatus(Integer value) {
    this.fileStatus = value;
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
