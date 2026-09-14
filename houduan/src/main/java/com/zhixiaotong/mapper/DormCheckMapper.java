package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.DormCheck;
import org.apache.ibatis.annotations.Mapper;

/** 查寝晚归记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface DormCheckMapper extends BaseMapper<DormCheck> {}
