package com.zhixiaotong.security;

import static com.zhixiaotong.common.BizException.check;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.*;
import com.nimbusds.jwt.*;
import com.zhixiaotong.common.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class TokenService {
  private final byte[] key;
  private final SessionStore store;
  private final Db db;
  private final int minutes, days;

  public TokenService(
      @Value("${campus.jwt-secret}") String secret,
      @Value("${campus.access-minutes}") int minutes,
      @Value("${campus.refresh-days}") int days,
      SessionStore store,
      Db db) {
    check(secret.length() >= 32, 500, "JWT密钥至少32字符");
    this.key = secret.getBytes(StandardCharsets.UTF_8);
    this.minutes = minutes;
    this.days = days;
    this.store = store;
    this.db = db;
  }

  public Map<String, Object> issue(long user, int version, String device) {
    String sid = UUID.randomUUID().toString(), r = Crypto.random();
    var s =
        new SessionStore.Session(
            user, version, Crypto.hash(r), System.currentTimeMillis() + days * 86400000L, device);
    store.put(sid, s);
    return pair(sid, r, s);
  }

  private Map<String, Object> pair(String sid, String refresh, SessionStore.Session s) {
    try {
      long now = System.currentTimeMillis();
      var claims =
          new JWTClaimsSet.Builder()
              .subject(Long.toString(s.userId()))
              .issuer("zhixiaotong")
              .audience("campus-api")
              .issueTime(new Date(now))
              .expirationTime(new Date(now + minutes * 60000L))
              .claim("sid", sid)
              .claim("ver", s.version())
              .build();
      SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
      jwt.sign(new MACSigner(key));
      return Data.map(
          "access_token",
          jwt.serialize(),
          "refresh_token",
          sid + "." + refresh,
          "token_type",
          "Bearer",
          "expires_in",
          minutes * 60);
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
  }

  public Map<String, Object> refresh(String token) {
    String[] p = token.split("\\.");
    check(p.length == 2, 401, "刷新凭证失效");
    String next = Crypto.random();
    var s = store.rotate(p[0], Crypto.hash(p[1]), Crypto.hash(next));
    check(s != null, 401, "刷新凭证失效或已重用");
    var u = db.get("user", s.userId());
    check(
        Data.integer(u, "user_status", 0) == 1
            && Data.integer(u, "token_version", 0) == s.version(),
        401,
        "账号凭证已撤销");
    return pair(p[0], next, s);
  }

  public LoginUser verify(String token, boolean logout) {
    try {
      SignedJWT jwt = SignedJWT.parse(token);
      check(
          JWSAlgorithm.HS256.equals(jwt.getHeader().getAlgorithm())
              && jwt.verify(new MACVerifier(key)),
          401,
          "令牌失效");
      var c = jwt.getJWTClaimsSet();
      check(
          "zhixiaotong".equals(c.getIssuer())
              && c.getAudience().contains("campus-api")
              && c.getExpirationTime() != null
              && c.getExpirationTime().after(new Date()),
          401,
          "令牌已过期");
      long uid = Long.parseLong(c.getSubject());
      String sid = c.getStringClaim("sid");
      var u = db.get("user", uid);
      check(
          Data.integer(u, "user_status", 0) == 1
              && Data.integer(u, "token_version", 0) == c.getIntegerClaim("ver"),
          401,
          "账号或凭证已失效");
      var s = store.get(sid);
      check(
          logout || (s != null && s.userId() == uid && s.version() == c.getIntegerClaim("ver")),
          401,
          "会话已撤销");
      return new LoginUser(uid, sid, s == null ? "" : s.deviceCode());
    } catch (BizException e) {
      throw e;
    } catch (Exception e) {
      throw new BizException(401, "令牌无效");
    }
  }

  public void logout(LoginUser user) {
    store.remove(user.sessionId());
  }
}
