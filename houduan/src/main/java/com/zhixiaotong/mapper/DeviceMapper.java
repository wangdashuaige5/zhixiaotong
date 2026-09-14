package com.zhixiaotong.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.zhixiaotong.po.Device;
import org.apache.ibatis.annotations.Mapper;

/** 用户设备表数据访问；复杂事务由业务服务负责。 */
@Mapper
public interface DeviceMapper extends BaseMapper<Device> {}
