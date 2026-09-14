package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.ExamPlan;
import org.apache.ibatis.annotations.Mapper;

/** 考试安排表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface ExamPlanMapper extends BaseMapper<ExamPlan> {}
