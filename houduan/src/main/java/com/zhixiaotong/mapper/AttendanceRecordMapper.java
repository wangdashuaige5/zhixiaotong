package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.AttendanceRecord;
import org.apache.ibatis.annotations.Mapper;

/** 课程签到记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AttendanceRecordMapper extends BaseMapper<AttendanceRecord> {}
