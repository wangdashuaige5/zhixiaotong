package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Notice;
import org.apache.ibatis.annotations.Mapper;

/** 通知公告表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface NoticeMapper extends BaseMapper<Notice> {}
