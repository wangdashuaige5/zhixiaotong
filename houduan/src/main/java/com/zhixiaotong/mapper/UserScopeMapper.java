package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.UserScope;
import org.apache.ibatis.annotations.Mapper;

/** 用户数据范围表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface UserScopeMapper extends BaseMapper<UserScope> {}
