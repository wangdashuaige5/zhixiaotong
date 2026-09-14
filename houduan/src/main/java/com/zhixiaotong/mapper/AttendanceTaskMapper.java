package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.AttendanceTask;
import org.apache.ibatis.annotations.Mapper;

/** 课程签到任务表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AttendanceTaskMapper extends BaseMapper<AttendanceTask> {}
