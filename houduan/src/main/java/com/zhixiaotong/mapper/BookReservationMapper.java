package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.BookReservation;
import org.apache.ibatis.annotations.Mapper;

/** 图书预约表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface BookReservationMapper extends BaseMapper<BookReservation> {}
