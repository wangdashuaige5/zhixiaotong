package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.RechargeOrder;
import org.apache.ibatis.annotations.Mapper;

/** 充值订单表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface RechargeOrderMapper extends BaseMapper<RechargeOrder> {}
