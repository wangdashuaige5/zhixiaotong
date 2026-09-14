package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.BatchCourse;
import org.apache.ibatis.annotations.Mapper;

/** 批次课程关联表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface BatchCourseMapper extends BaseMapper<BatchCourse> {}
