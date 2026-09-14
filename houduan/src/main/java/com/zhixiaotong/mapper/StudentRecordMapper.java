package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.StudentRecord;
import org.apache.ibatis.annotations.Mapper;

/** 学生奖惩记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface StudentRecordMapper extends BaseMapper<StudentRecord> {}
