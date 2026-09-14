package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Timetable;
import org.apache.ibatis.annotations.Mapper;

/** 课表信息表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface TimetableMapper extends BaseMapper<Timetable> {}
