package com.zhixiaotong.security;

import static com.zhixiaotong.common.BizException.check;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class Crypto {
  private final byte[] encryptionKey;
  private static final SecureRandom RANDOM = new SecureRandom();

  public Crypto(@Value("${campus.encryption-key}") String key) {
    check(key.length() >= 32, 500, "加密密钥至少32字符");
    encryptionKey = digest(key);
  }

  public static String random() {
    byte[] b = new byte[32];
    RANDOM.nextBytes(b);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
  }

  private static byte[] digest(String s) {
    try {
      return MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
  }

  public static String hash(String s) {
    return HexFormat.of().formatHex(digest(s));
  }

  public static boolean same(String a, String b) {
    return a != null
        && b != null
        && MessageDigest.isEqual(
            a.getBytes(StandardCharsets.UTF_8), b.getBytes(StandardCharsets.UTF_8));
  }

  public static String hmac(String key, String content) {
    try {
      Mac mac = Mac.getInstance("HmacSHA256");
      mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
      return HexFormat.of().formatHex(mac.doFinal(content.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
  }

  public String encrypt(String value) {
    if (value == null) return null;
    check(value.getBytes(StandardCharsets.UTF_8).length <= 48000, 400, "敏感内容过长，请分次记录");
    try {
      byte[] iv = new byte[12];
      RANDOM.nextBytes(iv);
      Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
      c.init(
          Cipher.ENCRYPT_MODE,
          new SecretKeySpec(encryptionKey, "AES"),
          new GCMParameterSpec(128, iv));
      return "gcm:"
          + Base64.getEncoder().encodeToString(iv)
          + ":"
          + Base64.getEncoder().encodeToString(c.doFinal(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
  }

  public String decrypt(String value) {
    if (value == null) return null;
    try {
      String[] p = value.split(":");
      Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
      c.init(
          Cipher.DECRYPT_MODE,
          new SecretKeySpec(encryptionKey, "AES"),
          new GCMParameterSpec(128, Base64.getDecoder().decode(p[1])));
      return new String(c.doFinal(Base64.getDecoder().decode(p[2])), StandardCharsets.UTF_8);
    } catch (Exception e) {
      throw new IllegalStateException("敏感数据无法解密");
    }
  }

  public static String password(String password) {
    byte[] salt = new byte[16];
    RANDOM.nextBytes(salt);
    return "$pbkdf2-sha256$600000$"
        + Base64.getEncoder().encodeToString(salt)
        + "$"
        + Base64.getEncoder().encodeToString(derive(password, salt, 600000));
  }

  private static byte[] derive(String p, byte[] salt, int iterations) {
    try {
      var spec = new PBEKeySpec(p.toCharArray(), salt, iterations, 256);
      try {
        return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            .generateSecret(spec)
            .getEncoded();
      } finally {
        spec.clearPassword();
      }
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
  }

  public static boolean passwordMatches(String raw, String encoded) {
    try {
      String[] p = encoded.split("\\$");
      if (p.length != 5 || !p[1].equals("pbkdf2-sha256")) return false;
      int n = Integer.parseInt(p[2]);
      if (n < 100000 || n > 2000000) return false;
      return MessageDigest.isEqual(
          derive(raw, Base64.getDecoder().decode(p[3]), n), Base64.getDecoder().decode(p[4]));
    } catch (Exception e) {
      return false;
    }
  }
}
