package com.zhixiaotong.common;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import java.util.*;

public final class Json {
  private static final ObjectMapper M =
      new ObjectMapper()
          .registerModule(new JavaTimeModule())
          .disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

  public static String write(Object v) {
    try {
      return M.writeValueAsString(v);
    } catch (Exception e) {
      throw new IllegalArgumentException("JSON无法编码", e);
    }
  }

  public static Object read(Object v) {
    try {
      if (v instanceof Map<?, ?> || v instanceof List<?>) return v;
      if (v instanceof byte[] b) v = new String(b, java.nio.charset.StandardCharsets.UTF_8);
      Object x = M.readValue(v.toString(), Object.class);
      return x instanceof String s && (s.startsWith("{") || s.startsWith("["))
          ? M.readValue(s, Object.class)
          : x;
    } catch (Exception e) {
      throw new BizException(400, "JSON格式不正确");
    }
  }

  @SuppressWarnings("unchecked")
  public static Map<String, Object> object(Object v) {
    return (Map<String, Object>) read(v);
  }

  @SuppressWarnings("unchecked")
  public static List<Map<String, Object>> list(Object v) {
    return (List<Map<String, Object>>) read(v);
  }
}
