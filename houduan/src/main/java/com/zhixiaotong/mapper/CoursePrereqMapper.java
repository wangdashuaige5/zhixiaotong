package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.CoursePrereq;
import org.apache.ibatis.annotations.Mapper;

/** 课程先修条件表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface CoursePrereqMapper extends BaseMapper<CoursePrereq> {}
