package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.AidReview;
import org.apache.ibatis.annotations.Mapper;

/** 奖助贷评审记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AidReviewMapper extends BaseMapper<AidReview> {}
