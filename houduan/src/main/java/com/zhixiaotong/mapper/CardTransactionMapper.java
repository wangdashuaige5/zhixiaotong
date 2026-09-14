package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.CardTransaction;
import org.apache.ibatis.annotations.Mapper;

/** 校园卡流水表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface CardTransactionMapper extends BaseMapper<CardTransaction> {}
