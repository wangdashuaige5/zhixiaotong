package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.CardAccount;
import org.apache.ibatis.annotations.Mapper;

/** 校园卡账户表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface CardAccountMapper extends BaseMapper<CardAccount> {}
