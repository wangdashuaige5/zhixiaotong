package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Role;
import org.apache.ibatis.annotations.Mapper;

/** 角色表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface RoleMapper extends BaseMapper<Role> {}
