package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.OrgUnit;
import org.apache.ibatis.annotations.Mapper;

/** 组织机构表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface OrgUnitMapper extends BaseMapper<OrgUnit> {}
