package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.TeachingClass;
import org.apache.ibatis.annotations.Mapper;

/** 教学班表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface TeachingClassMapper extends BaseMapper<TeachingClass> {}
