package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.MessageReceipt;
import org.apache.ibatis.annotations.Mapper;

/** 消息回执表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface MessageReceiptMapper extends BaseMapper<MessageReceipt> {}
