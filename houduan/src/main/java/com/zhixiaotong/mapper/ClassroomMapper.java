package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Classroom;
import org.apache.ibatis.annotations.Mapper;

/** 教室表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface ClassroomMapper extends BaseMapper<Classroom> {}
