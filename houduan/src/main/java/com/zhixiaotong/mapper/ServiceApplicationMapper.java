package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.ServiceApplication;
import org.apache.ibatis.annotations.Mapper;

/** 学生办事申请表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface ServiceApplicationMapper extends BaseMapper<ServiceApplication> {}
