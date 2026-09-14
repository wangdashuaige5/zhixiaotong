package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Semester;
import org.apache.ibatis.annotations.Mapper;

/** 学期表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface SemesterMapper extends BaseMapper<Semester> {}
