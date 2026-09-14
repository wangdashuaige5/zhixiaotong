package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Continuation;
import org.apache.ibatis.annotations.Mapper;

/** 跨设备流转任务表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface ContinuationMapper extends BaseMapper<Continuation> {}
