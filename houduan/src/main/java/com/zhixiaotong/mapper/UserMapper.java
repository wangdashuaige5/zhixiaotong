package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.User;
import org.apache.ibatis.annotations.Mapper;

/** 用户表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface UserMapper extends BaseMapper<User> {}
