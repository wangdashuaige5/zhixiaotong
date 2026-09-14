package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.SelectionScope;
import org.apache.ibatis.annotations.Mapper;

/** 选课开放范围表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface SelectionScopeMapper extends BaseMapper<SelectionScope> {}
