package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.OutboxEvent;
import org.apache.ibatis.annotations.Mapper;

/** 可靠消息事件表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface OutboxEventMapper extends BaseMapper<OutboxEvent> {}
