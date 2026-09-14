package com.zhixiaotong.security;

import com.zhixiaotong.common.BizException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

/** 演示单机限流；正式配置通过 Redis 原子计数支持多实例。 */
@Component
public class RequestLimiter {
  private final String mode;
  private final StringRedisTemplate redis;
  private final Map<String, AtomicLong> counts = new ConcurrentHashMap<>();

  public RequestLimiter(@Value("${campus.session-mode}") String mode, StringRedisTemplate redis) {
    this.mode = mode;
    this.redis = redis;
  }

  public void check(String subject, int limit, int seconds) {
    long window = System.currentTimeMillis() / 1000 / seconds;
    String key = "campus:limit:" + Crypto.hash(subject) + ":" + window;
    long n;
    if (mode.equals("redis")) {
      Long result =
          redis.execute(
              new DefaultRedisScript<Long>(
                  "local n=redis.call('INCR',KEYS[1]); if n==1 then"
                      + " redis.call('EXPIRE',KEYS[1],ARGV[1]); end; return n",
                  Long.class),
              List.of(key),
              Integer.toString(seconds * 2));
      BizException.check(result != null, 503, "限流服务暂不可用");
      n = result;
    } else {
      if (counts.size() > 10000) counts.keySet().removeIf(k -> !k.endsWith(":" + window));
      n = counts.computeIfAbsent(key, k -> new AtomicLong()).incrementAndGet();
    }
    BizException.check(n <= limit, 429, "操作过于频繁，请稍后重试");
  }
}
