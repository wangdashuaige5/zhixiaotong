package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Grade;
import org.apache.ibatis.annotations.Mapper;

/** 成绩表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface GradeMapper extends BaseMapper<Grade> {}
