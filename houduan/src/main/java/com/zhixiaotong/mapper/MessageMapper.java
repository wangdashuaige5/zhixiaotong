package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Message;
import org.apache.ibatis.annotations.Mapper;

/** 站内消息表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface MessageMapper extends BaseMapper<Message> {}
