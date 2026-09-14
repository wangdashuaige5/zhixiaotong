package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.StudentFocus;
import org.apache.ibatis.annotations.Mapper;

/** 重点关注记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface StudentFocusMapper extends BaseMapper<StudentFocus> {}
