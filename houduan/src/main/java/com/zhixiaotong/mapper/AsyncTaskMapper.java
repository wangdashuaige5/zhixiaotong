package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.AsyncTask;
import org.apache.ibatis.annotations.Mapper;

/** 异步任务表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AsyncTaskMapper extends BaseMapper<AsyncTask> {}
