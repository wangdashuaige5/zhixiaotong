package com.zhixiaotong.common;

import static com.zhixiaotong.common.BizException.check;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhixiaotong.dto.PageDto;
import com.zhixiaotong.mapper.SqlMapper;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
public class Db {
  private final SqlMapper mapper;
  private final Map<String, Set<String>> columns = new HashMap<>();

  public Db(SqlMapper mapper) throws Exception {
    this.mapper = mapper;
    try (var in = getClass().getResourceAsStream("/schema-metadata.json")) {
      for (var t : new ObjectMapper().readTree(in)) {
        Set<String> fields = new HashSet<>();
        t.get("fields").forEach(f -> fields.add(f.get("code").asText()));
        columns.put(t.get("name").asText(), fields);
      }
    }
  }

  public List<Map<String, Object>> list(String sql, Object... args) {
    return mapper.query(new SqlMapper.Command(sql, args)).stream()
        .filter(Objects::nonNull)
        .map(
            row -> {
              Map<String, Object> m = new LinkedHashMap<>();
              row.forEach(
                  (k, v) -> {
                    String name = k.toLowerCase(Locale.ROOT);
                    m.put(
                        name,
                        v != null && JSON_FIELDS.contains(name) ? Json.read(v) : normalize(v));
                  });
              return m;
            })
        .toList();
  }

  private Object normalize(Object value) {
    if (value instanceof java.sql.Timestamp v) return v.toLocalDateTime();
    if (value instanceof java.sql.Date v) return v.toLocalDate();
    if (value instanceof java.sql.Time v) return v.toLocalTime();
    return value;
  }

  private static final Set<String> JSON_FIELDS =
      Set.of(
          "after_value",
          "apply_data",
          "before_value",
          "change_data",
          "grade_snapshot",
          "item_scores",
          "payload",
          "priority_rule",
          "scope_data",
          "task_params");

  public Map<String, Object> one(String sql, Object... args) {
    var l = list(sql, args);
    return l.isEmpty() ? null : l.get(0);
  }

  public long count(String sql, Object... args) {
    var r = one(sql, args);
    return r == null ? 0 : Data.num(r.values().iterator().next());
  }

  public int exec(String sql, Object... args) {
    return mapper.execute(new SqlMapper.Command(sql, args));
  }

  private void table(String t) {
    check(columns.containsKey(t), 400, "不支持的数据表");
  }

  public Map<String, Object> get(String t, long id) {
    table(t);
    var r = one("SELECT * FROM `" + t + "` WHERE id=?", id);
    check(r != null, 404, "记录不存在");
    return r;
  }

  public Map<String, Object> lock(String t, long id) {
    table(t);
    var r = one("SELECT * FROM `" + t + "` WHERE id=? FOR UPDATE", id);
    check(r != null, 404, "记录不存在");
    return r;
  }

  public long insert(String t, Map<String, Object> values) {
    table(t);
    var v = new LinkedHashMap<>(values);
    check(!v.isEmpty(), 400, "没有可保存字段");
    v.keySet().forEach(k -> check(columns.get(t).contains(k), 400, "不支持的字段：" + k));
    String names = v.keySet().stream().map(k -> "`" + k + "`").collect(Collectors.joining(","));
    var c =
        new SqlMapper.Command(
            "INSERT INTO `"
                + t
                + "` ("
                + names
                + ") VALUES ("
                + String.join(",", Collections.nCopies(v.size(), "?"))
                + ")",
            v.values().toArray());
    mapper.insert(c);
    return c.id;
  }

  public void update(String t, long id, Map<String, Object> values) {
    table(t);
    var v = new LinkedHashMap<>(values);
    check(!v.containsKey("id"), 400, "主键不可修改");
    if (columns.get(t).contains("update_time")) v.put("update_time", Data.now());
    check(!v.isEmpty(), 400, "没有可更新字段");
    v.keySet().forEach(k -> check(columns.get(t).contains(k), 400, "不支持字段"));
    var args = new ArrayList<>(v.values());
    args.add(id);
    exec(
        "UPDATE `"
            + t
            + "` SET "
            + v.keySet().stream().map(k -> "`" + k + "`=?").collect(Collectors.joining(","))
            + " WHERE id=?",
        args.toArray());
  }

  public PageDto page(String sql, Map<String, Object> q, Object... args) {
    int page = Data.integer(q, "page_no", 1), size = Data.integer(q, "page_size", 20);
    Data.range(page, 1, 100000, "page_no");
    Data.range(size, 1, 100, "page_size");
    long n = count("SELECT COUNT(*) FROM (" + sql + ") count_rows", args);
    var params = new ArrayList<>(Arrays.asList(args));
    params.add(size);
    params.add((page - 1) * size);
    return new PageDto(list(sql + " LIMIT ? OFFSET ?", params.toArray()), n, page, size);
  }
}
