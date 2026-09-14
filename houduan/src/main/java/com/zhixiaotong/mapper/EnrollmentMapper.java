package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Enrollment;
import org.apache.ibatis.annotations.Mapper;

/** 选课记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface EnrollmentMapper extends BaseMapper<Enrollment> {}
