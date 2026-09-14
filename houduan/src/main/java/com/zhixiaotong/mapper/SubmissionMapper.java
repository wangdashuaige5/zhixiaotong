package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Submission;
import org.apache.ibatis.annotations.Mapper;

/** 作业提交表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface SubmissionMapper extends BaseMapper<Submission> {}
