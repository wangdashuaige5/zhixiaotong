package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Assignment;
import org.apache.ibatis.annotations.Mapper;

/** 作业表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AssignmentMapper extends BaseMapper<Assignment> {}
