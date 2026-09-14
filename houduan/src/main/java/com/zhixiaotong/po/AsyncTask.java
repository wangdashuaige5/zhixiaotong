package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.time.*;

/** 异步任务表：管理导入、导出和统计报表任务进度。数据库字段使用下画线。 */
@TableName("`async_task`")
public class AsyncTask {
  /** 任务ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 任务编码； */
  @TableField("task_no")
  private String taskNo;

  public String getTaskNo() {
    return taskNo;
  }

  public void setTaskNo(String value) {
    this.taskNo = value;
  }

  /** 任务类型； */
  @TableField("task_type")
  private String taskType;

  public String getTaskType() {
    return taskType;
  }

  public void setTaskType(String value) {
    this.taskType = value;
  }

  /** 发起人ID；user(id)；组合查询索引 */
  @TableField("creator_id")
  private Long creatorId;

  public Long getCreatorId() {
    return creatorId;
  }

  public void setCreatorId(Long value) {
    this.creatorId = value;
  }

  /** 任务参数；记录过滤条件和数据权限快照 */
  @TableField("task_params")
  private String taskParams;

  public String getTaskParams() {
    return taskParams;
  }

  public void setTaskParams(String value) {
    this.taskParams = value;
  }

  /** 输入文件ID；file_upload(id) */
  @TableField("input_file_id")
  private Long inputFileId;

  public Long getInputFileId() {
    return inputFileId;
  }

  public void setInputFileId(Long value) {
    this.inputFileId = value;
  }

  /** 结果文件ID；file_upload(id) */
  @TableField("result_file_id")
  private Long resultFileId;

  public Long getResultFileId() {
    return resultFileId;
  }

  public void setResultFileId(Long value) {
    this.resultFileId = value;
  }

  /** 任务状态；0等待；1执行中；2成功；3失败；4取消 */
  @TableField("task_status")
  private Integer taskStatus;

  public Integer getTaskStatus() {
    return taskStatus;
  }

  public void setTaskStatus(Integer value) {
    this.taskStatus = value;
  }

  /** 完成进度；0至100 */
  @TableField("progress")
  private Integer progress;

  public Integer getProgress() {
    return progress;
  }

  public void setProgress(Integer value) {
    this.progress = value;
  }

  /** 失败原因； */
  @TableField("error_message")
  private String errorMessage;

  public String getErrorMessage() {
    return errorMessage;
  }

  public void setErrorMessage(String value) {
    this.errorMessage = value;
  }

  /** 开始时间； */
  @TableField("start_time")
  private LocalDateTime startTime;

  public LocalDateTime getStartTime() {
    return startTime;
  }

  public void setStartTime(LocalDateTime value) {
    this.startTime = value;
  }

  /** 结束时间； */
  @TableField("finish_time")
  private LocalDateTime finishTime;

  public LocalDateTime getFinishTime() {
    return finishTime;
  }

  public void setFinishTime(LocalDateTime value) {
    this.finishTime = value;
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
