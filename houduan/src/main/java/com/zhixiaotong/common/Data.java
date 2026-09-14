package com.zhixiaotong.common;

import static com.zhixiaotong.common.BizException.check;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;

/** DTO字段验证；控制器不直接把客户端Map作为数据库更新内容。 */
public final class Data {
  private Data() {}

  public static Map<String, Object> map(Object... pairs) {
    Map<String, Object> m = new LinkedHashMap<>();
    for (int i = 0; i < pairs.length; i += 2) m.put((String) pairs[i], pairs[i + 1]);
    return m;
  }

  public static long num(Object value) {
    try {
      return Long.parseLong(String.valueOf(value));
    } catch (Exception e) {
      throw new BizException(400, "ID或整数格式不正确");
    }
  }

  public static long id(Map<String, Object> m, String key) {
    long x = num(m.get(key));
    check(x > 0, 400, key + "必须是正整数");
    return x;
  }

  public static int integer(Map<String, Object> m, String key, int defaultValue) {
    return m.get(key) == null ? defaultValue : Math.toIntExact(num(m.get(key)));
  }

  public static String str(Map<String, Object> m, String key) {
    return m.get(key) == null ? "" : String.valueOf(m.get(key));
  }

  public static String text(Map<String, Object> m, String key, int max) {
    String s = str(m, key).trim();
    check(!s.isEmpty() && s.length() <= max, 400, key + "不能为空且不能超过" + max + "字符");
    return s;
  }

  public static String optional(Map<String, Object> m, String key, int max) {
    String s = str(m, key);
    check(s.length() <= max, 400, key + "过长");
    return s.isBlank() ? null : s;
  }

  public static BigDecimal decimal(Object value) {
    try {
      return new BigDecimal(value.toString());
    } catch (Exception e) {
      throw new BizException(400, "小数格式不正确");
    }
  }

  public static BigDecimal dec(Map<String, Object> m, String key) {
    return decimal(m.get(key));
  }

  public static LocalDateTime time(Object value) {
    if (value instanceof LocalDateTime t) return t;
    if (value instanceof java.sql.Timestamp t) return t.toLocalDateTime();
    try {
      return OffsetDateTime.parse(value.toString())
          .atZoneSameInstant(ZoneId.of("Asia/Shanghai"))
          .toLocalDateTime();
    } catch (Exception ignored) {
      try {
        return LocalDateTime.parse(value.toString().replace(' ', 'T'));
      } catch (Exception e) {
        throw new BizException(400, "时间格式不正确");
      }
    }
  }

  public static LocalDate date(Object value) {
    try {
      return value instanceof LocalDate d ? d : LocalDate.parse(value.toString());
    } catch (Exception e) {
      throw new BizException(400, "日期格式不正确");
    }
  }

  public static LocalTime clock(Object value) {
    try {
      return value instanceof LocalTime d ? d : LocalTime.parse(value.toString());
    } catch (Exception e) {
      throw new BizException(400, "时刻格式不正确");
    }
  }

  @SuppressWarnings("unchecked")
  public static List<Map<String, Object>> rows(Map<String, Object> m, String key) {
    Object v = m.get(key);
    check(v instanceof List<?>, 400, key + "必须是数组");
    List<?> l = (List<?>) v;
    check(l.size() <= 1000 && l.stream().allMatch(x -> x instanceof Map), 400, key + "最多1000项对象");
    return (List<Map<String, Object>>) v;
  }

  public static List<Long> ids(Map<String, Object> m, String key) {
    if (m.get(key) == null) return List.of();
    check(m.get(key) instanceof List<?>, 400, key + "必须是数组");
    List<?> l = (List<?>) m.get(key);
    check(l.size() <= 30, 400, "附件数量超过30");
    return l.stream().map(Data::num).toList();
  }

  public static Map<String, Object> pick(Map<String, Object> m, String... keys) {
    Map<String, Object> r = new LinkedHashMap<>();
    for (String k : keys) if (m.containsKey(k)) r.put(k, m.get(k));
    return r;
  }

  public static boolean eq(Object a, Object b) {
    return a != null && b != null && a.toString().equals(b.toString());
  }

  public static LocalDateTime now() {
    return LocalDateTime.now(ZoneId.of("Asia/Shanghai"));
  }

  public static void range(int value, int min, int max, String name) {
    check(value >= min && value <= max, 400, name + "超出允许范围");
  }

  public static void keys(Map<String, Object> m, String... allowed) {
    Set<String> s = Set.of(allowed);
    for (String k : m.keySet()) check(s.contains(k), 400, "不允许的字段：" + k);
  }
}
