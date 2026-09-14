package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.AidBatch;
import org.apache.ibatis.annotations.Mapper;

/** 奖助贷批次表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AidBatchMapper extends BaseMapper<AidBatch> {}
