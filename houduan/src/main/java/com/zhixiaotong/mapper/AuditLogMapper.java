package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.AuditLog;
import org.apache.ibatis.annotations.Mapper;

/** 操作审计日志表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface AuditLogMapper extends BaseMapper<AuditLog> {}
