package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 选课记录表：保存申请、录取、退选及幂等状态。数据库字段使用下画线。 */
@TableName("`enrollment`")
public class Enrollment {
  /** 选课ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 学生ID；user(id)；锁定学生行校验同学期重复课程及时间冲突 */
  @TableField("student_id")
  private Long studentId;

  public Long getStudentId() {
    return studentId;
  }

  public void setStudentId(Long value) {
    this.studentId = value;
  }

  /** 教学班ID；teaching_class(id)；与学生ID联合唯一；组合查询索引 */
  @TableField("teaching_class_id")
  private Long teachingClassId;

  public Long getTeachingClassId() {
    return teachingClassId;
  }

  public void setTeachingClassId(Long value) {
    this.teachingClassId = value;
  }

  /** 批次课程ID；batch_course(id)；必修导入可空；教学班须一致 */
  @TableField("batch_course_id")
  private Long batchCourseId;

  public Long getBatchCourseId() {
    return batchCourseId;
  }

  public void setBatchCourseId(Long value) {
    this.batchCourseId = value;
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

  /** 选课状态；0待筛选；1成功；2未录取；3已退 */
  @TableField("enroll_status")
  private Integer enrollStatus;

  public Integer getEnrollStatus() {
    return enrollStatus;
  }

  public void setEnrollStatus(Integer value) {
    this.enrollStatus = value;
  }

  /** 筛选顺序；保存抽签或优先级排序 */
  @TableField("selection_rank")
  private Integer selectionRank;

  public Integer getSelectionRank() {
    return selectionRank;
  }

  public void setSelectionRank(Integer value) {
    this.selectionRank = value;
  }

  /** 选课时间； */
  @TableField("enroll_time")
  private LocalDateTime enrollTime;

  public LocalDateTime getEnrollTime() {
    return enrollTime;
  }

  public void setEnrollTime(LocalDateTime value) {
    this.enrollTime = value;
  }

  /** 退选时间； */
  @TableField("drop_time")
  private LocalDateTime dropTime;

  public LocalDateTime getDropTime() {
    return dropTime;
  }

  public void setDropTime(LocalDateTime value) {
    this.dropTime = value;
  }

  /** 处理说明；仅成功占容量；退选原子释放 */
  @TableField("result_note")
  private String resultNote;

  public String getResultNote() {
    return resultNote;
  }

  public void setResultNote(String value) {
    this.resultNote = value;
  }

  /** 版本号；重选更新原记录；历史写审计 */
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
