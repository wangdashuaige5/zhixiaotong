package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.GradeChange;
import org.apache.ibatis.annotations.Mapper;

/** 成绩更正申请表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface GradeChangeMapper extends BaseMapper<GradeChange> {}
