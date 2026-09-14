package com.zhixiaotong.security;

import com.zhixiaotong.common.*;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

/** 演示使用单进程存储；生产使用Redis原子轮换，旧凭证重放撤销整条会话。 */
@Component
public class SessionStore {
  private final String mode;
  private final StringRedisTemplate redis;
  private final Map<String, Session> local = new ConcurrentHashMap<>();

  public record Session(
      long userId, int version, String refreshHash, long expiresAt, String deviceCode) {}

  public SessionStore(@Value("${campus.session-mode}") String mode, StringRedisTemplate redis) {
    this.mode = mode;
    this.redis = redis;
  }

  public void put(String sid, Session s) {
    try {
      if (mode.equals("memory")) local.put(sid, s);
      else
        redis
            .opsForValue()
            .set(
                "campus:session:" + sid,
                Json.write(s),
                Duration.ofMillis(Math.max(1, s.expiresAt - System.currentTimeMillis())));
    } catch (Exception e) {
      throw new BizException(503, "会话服务暂不可用");
    }
  }

  public Session get(String sid) {
    try {
      Session s;
      if (mode.equals("memory")) s = local.get(sid);
      else {
        String v = redis.opsForValue().get("campus:session:" + sid);
        if (v == null) return null;
        var m = Json.object(v);
        s =
            new Session(
                Data.num(m.get("userId")),
                Data.integer(m, "version", 0),
                Data.str(m, "refreshHash"),
                Data.num(m.get("expiresAt")),
                Data.str(m, "deviceCode"));
      }
      if (s != null && s.expiresAt < System.currentTimeMillis()) {
        remove(sid);
        return null;
      }
      return s;
    } catch (BizException e) {
      throw e;
    } catch (Exception e) {
      throw new BizException(503, "会话服务暂不可用");
    }
  }

  public void remove(String sid) {
    try {
      if (mode.equals("memory")) local.remove(sid);
      else redis.delete("campus:session:" + sid);
    } catch (Exception e) {
      throw new BizException(503, "会话服务暂不可用");
    }
  }

  public synchronized Session rotate(String sid, String oldHash, String newHash) {
    if (mode.equals("memory")) {
      Session s = get(sid);
      if (s == null) return null;
      if (!Crypto.same(s.refreshHash, oldHash)) {
        remove(sid);
        return null;
      }
      Session n = new Session(s.userId, s.version, newHash, s.expiresAt, s.deviceCode);
      put(sid, n);
      return n;
    }
    try {
      String lua =
          "local v=redis.call('GET',KEYS[1]); if not v then return nil end; local"
              + " s=cjson.decode(v); if s.refreshHash~=ARGV[1] then redis.call('DEL',KEYS[1]);"
              + " return nil end; s.refreshHash=ARGV[2]; local n=cjson.encode(s);"
              + " redis.call('SET',KEYS[1],n,'KEEPTTL'); return n";
      String raw =
          redis.execute(
              new DefaultRedisScript<>(lua, String.class),
              List.of("campus:session:" + sid),
              oldHash,
              newHash);
      if (raw == null) return null;
      var m = Json.object(raw);
      return new Session(
          Data.num(m.get("userId")),
          Data.integer(m, "version", 0),
          Data.str(m, "refreshHash"),
          Data.num(m.get("expiresAt")),
          Data.str(m, "deviceCode"));
    } catch (Exception e) {
      throw new BizException(503, "会话服务暂不可用");
    }
  }
}
