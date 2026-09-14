package com.zhixiaotong.po;

import com.baomidou.mybatisplus.annotation.*;
import java.math.BigDecimal;
import java.time.*;

/** 奖助贷评审记录表：记录分级评审意见、评分和操作人。数据库字段使用下画线。 */
@TableName("`aid_review`")
public class AidReview {
  /** 评审ID；自增长类型 */
  @TableId(type = IdType.AUTO)
  private Long id;

  public Long getId() {
    return id;
  }

  public void setId(Long value) {
    this.id = value;
  }

  /** 申请ID；aid_application(id) */
  @TableField("application_id")
  private Long applicationId;

  public Long getApplicationId() {
    return applicationId;
  }

  public void setApplicationId(Long value) {
    this.applicationId = value;
  }

  /** 申请轮次； */
  @TableField("apply_round")
  private Integer applyRound;

  public Integer getApplyRound() {
    return applyRound;
  }

  public void setApplyRound(Integer value) {
    this.applyRound = value;
  }

  /** 节点顺序； */
  @TableField("node_order")
  private Integer nodeOrder;

  public Integer getNodeOrder() {
    return nodeOrder;
  }

  public void setNodeOrder(Integer value) {
    this.nodeOrder = value;
  }

  /** 评审人ID；user(id)；与申请ID、申请轮次、节点顺序联合唯一 */
  @TableField("reviewer_id")
  private Long reviewerId;

  public Long getReviewerId() {
    return reviewerId;
  }

  public void setReviewerId(Long value) {
    this.reviewerId = value;
  }

  /** 评审分数； */
  @TableField("review_score")
  private BigDecimal reviewScore;

  public BigDecimal getReviewScore() {
    return reviewScore;
  }

  public void setReviewScore(BigDecimal value) {
    this.reviewScore = value;
  }

  /** 评审结果；0待评；1通过；2驳回；3退回 */
  @TableField("decision")
  private Integer decision;

  public Integer getDecision() {
    return decision;
  }

  public void setDecision(Integer value) {
    this.decision = value;
  }

  /** 评审意见； */
  @TableField("opinion")
  private String opinion;

  public String getOpinion() {
    return opinion;
  }

  public void setOpinion(String value) {
    this.opinion = value;
  }

  /** 评审时间； */
  @TableField("review_time")
  private LocalDateTime reviewTime;

  public LocalDateTime getReviewTime() {
    return reviewTime;
  }

  public void setReviewTime(LocalDateTime value) {
    this.reviewTime = value;
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
