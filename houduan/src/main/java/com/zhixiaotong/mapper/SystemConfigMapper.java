package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.SystemConfig;
import org.apache.ibatis.annotations.Mapper;

/** 系统配置字典表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface SystemConfigMapper extends BaseMapper<SystemConfig> {}
