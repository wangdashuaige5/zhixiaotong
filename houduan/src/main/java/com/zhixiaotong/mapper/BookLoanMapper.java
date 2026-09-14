package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.BookLoan;
import org.apache.ibatis.annotations.Mapper;

/** 图书借阅记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface BookLoanMapper extends BaseMapper<BookLoan> {}
