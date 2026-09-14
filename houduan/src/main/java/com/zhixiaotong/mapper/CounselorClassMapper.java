package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.CounselorClass;
import org.apache.ibatis.annotations.Mapper;

/** 辅导员班级关联表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface CounselorClassMapper extends BaseMapper<CounselorClass> {}
