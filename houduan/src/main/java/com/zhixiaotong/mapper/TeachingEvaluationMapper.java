package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.TeachingEvaluation;
import org.apache.ibatis.annotations.Mapper;

/** 教学评价表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface TeachingEvaluationMapper extends BaseMapper<TeachingEvaluation> {}
