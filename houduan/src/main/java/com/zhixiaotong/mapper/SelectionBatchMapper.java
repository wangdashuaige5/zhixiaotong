package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.SelectionBatch;
import org.apache.ibatis.annotations.Mapper;

/** 选课批次表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface SelectionBatchMapper extends BaseMapper<SelectionBatch> {}
