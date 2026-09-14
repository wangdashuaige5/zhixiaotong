package com.zhixiaotong.config;

import static com.zhixiaotong.common.BizException.check;

import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/** 防止把演示密钥或模拟集成配置误带入正式部署。 */
@Component
@Profile("prod")
public class ProductionGuard {
  public ProductionGuard(Environment env) {
    for (String key : new String[] {"campus.jwt-secret", "campus.encryption-key"}) {
      String value = env.getRequiredProperty(key);
      check(
          value.length() >= 32 && !value.toLowerCase().contains("demo"),
          500,
          "正式环境必须使用独立安全密钥：" + key);
    }
    check(!env.matchesProfiles("demo"), 500, "prod不能同时启用demo");
    check(
        env.getProperty("campus.session-mode", "").equals("redis")
            && env.getProperty("campus.message-mode", "").equals("rabbit")
            && env.getProperty("campus.storage-mode", "").equals("minio")
            && env.getProperty("campus.scan-mode", "").equals("clamav"),
        500,
        "正式环境必须配置Redis、RabbitMQ、私有对象存储和病毒扫描");
    check(
        !env.getProperty("campus.integration-mode", "").equals("mock")
            && !env.getProperty("campus.demo-seed", "false").equals("true"),
        500,
        "正式环境禁止模拟充值和演示数据");
  }
}
