package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.ServiceStep;
import org.apache.ibatis.annotations.Mapper;

/** 学生办事环节表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface ServiceStepMapper extends BaseMapper<ServiceStep> {}
