package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.LeaveApproval;
import org.apache.ibatis.annotations.Mapper;

/** 请假审批记录表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface LeaveApprovalMapper extends BaseMapper<LeaveApproval> {}
