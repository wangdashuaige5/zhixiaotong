package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.*;

/** 用户设备表：登记鸿蒙终端绑定关系和信任状态。数据库字段使用下画线。 */
@TableName("`device`")
public class Device {
  /** 设备ID；自增长类型 */
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

  /** 设备标识；存储脱敏标识；与用户ID联合唯一 */
  @TableField("device_code")
  private String deviceCode;

  public String getDeviceCode() {
    return deviceCode;
  }

  public void setDeviceCode(String value) {
    this.deviceCode = value;
  }

  /** 设备名称； */
  @TableField("device_name")
  private String deviceName;

  public String getDeviceName() {
    return deviceName;
  }

  public void setDeviceName(String value) {
    this.deviceName = value;
  }

  /** 设备类型；手机、平板、手表或智慧屏 */
  @TableField("device_type")
  private String deviceType;

  public String getDeviceType() {
    return deviceType;
  }

  public void setDeviceType(String value) {
    this.deviceType = value;
  }

  /** 推送标识；加密保存 */
  @TableField("push_token")
  @JsonIgnore
  private String pushToken;

  public String getPushToken() {
    return pushToken;
  }

  public void setPushToken(String value) {
    this.pushToken = value;
  }

  /** 信任状态；0未认证；1可信；2撤销 */
  @TableField("trust_status")
  private Integer trustStatus;

  public Integer getTrustStatus() {
    return trustStatus;
  }

  public void setTrustStatus(Integer value) {
    this.trustStatus = value;
  }

  /** 最近在线； */
  @TableField("last_seen_time")
  private LocalDateTime lastSeenTime;

  public LocalDateTime getLastSeenTime() {
    return lastSeenTime;
  }

  public void setLastSeenTime(LocalDateTime value) {
    this.lastSeenTime = value;
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
