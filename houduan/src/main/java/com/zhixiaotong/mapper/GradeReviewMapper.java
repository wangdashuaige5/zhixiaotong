package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.GradeReview;
import org.apache.ibatis.annotations.Mapper;

/** 成绩审核表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface GradeReviewMapper extends BaseMapper<GradeReview> {}
