package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.RolePermission;
import org.apache.ibatis.annotations.Mapper;

/** 角色权限关联表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface RolePermissionMapper extends BaseMapper<RolePermission> {}
