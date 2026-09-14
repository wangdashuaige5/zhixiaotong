package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 教室表：保存排课教室、地点和容纳人数。数据库字段使用下画线。 */
@TableName("`classroom`")
public class Classroom {
  /** 教室ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 教室编码； */
  @TableField("room_code")
  private String roomCode;

  public String getRoomCode() {
    return roomCode;
  }

  public void setRoomCode(String value) {
    this.roomCode = value;
  }

  /** 教室名称； */
  @TableField("room_name")
  private String roomName;

  public String getRoomName() {
    return roomName;
  }

  public void setRoomName(String value) {
    this.roomName = value;
  }

  /** 所在校区； */
  @TableField("campus_name")
  private String campusName;

  public String getCampusName() {
    return campusName;
  }

  public void setCampusName(String value) {
    this.campusName = value;
  }

  /** 教学楼； */
  @TableField("building_name")
  private String buildingName;

  public String getBuildingName() {
    return buildingName;
  }

  public void setBuildingName(String value) {
    this.buildingName = value;
  }

  /** 容纳人数；大于0 */
  @TableField("capacity")
  private Integer capacity;

  public Integer getCapacity() {
    return capacity;
  }

  public void setCapacity(Integer value) {
    this.capacity = value;
  }

  /** 启用状态；0停用；1启用 */
  @TableField("is_enabled")
  private Integer isEnabled;

  public Integer getIsEnabled() {
    return isEnabled;
  }

  public void setIsEnabled(Integer value) {
    this.isEnabled = value;
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
