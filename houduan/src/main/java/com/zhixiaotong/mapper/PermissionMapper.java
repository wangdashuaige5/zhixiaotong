package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Permission;
import org.apache.ibatis.annotations.Mapper;

/** 权限表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface PermissionMapper extends BaseMapper<Permission> {}
