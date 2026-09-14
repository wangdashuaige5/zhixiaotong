package com.zhixiaotong.common;

import static com.zhixiaotong.common.BizException.check;

import java.util.*;

/** UTF-8 CSV，支持引号、逗号和字段内换行；导出阻止表格公式注入。 */
public final class Csv {
  public static List<Map<String, Object>> parse(String text) {
    if (text.startsWith("\uFEFF")) text = text.substring(1);
    List<List<String>> rows = new ArrayList<>();
    List<String> row = new ArrayList<>();
    StringBuilder cell = new StringBuilder();
    boolean quoted = false;
    for (int i = 0; i < text.length(); i++) {
      char c = text.charAt(i);
      if (c == '"') {
        if (quoted && i + 1 < text.length() && text.charAt(i + 1) == '"') {
          cell.append('"');
          i++;
        } else quoted = !quoted;
      } else if (c == ',' && !quoted) {
        row.add(cell.toString());
        cell.setLength(0);
      } else if ((c == '\n' || c == '\r') && !quoted) {
        if (c == '\r' && i + 1 < text.length() && text.charAt(i + 1) == '\n') i++;
        row.add(cell.toString());
        cell.setLength(0);
        if (row.stream().anyMatch(s -> !s.isEmpty())) rows.add(row);
        row = new ArrayList<>();
      } else cell.append(c);
      check(cell.length() <= 30000, 400, "CSV单元格过长");
    }
    check(!quoted, 400, "CSV引号未闭合");
    if (!cell.isEmpty() || !row.isEmpty()) {
      row.add(cell.toString());
      rows.add(row);
    }
    check(!rows.isEmpty() && rows.size() <= 201, 400, "CSV须有表头且最多200行数据");
    List<String> header = rows.remove(0);
    check(new HashSet<>(header).size() == header.size(), 400, "CSV存在重复列名");
    List<Map<String, Object>> result = new ArrayList<>();
    for (var r : rows) {
      check(r.size() == header.size(), 400, "CSV行列数不一致");
      Map<String, Object> m = new LinkedHashMap<>();
      for (int i = 0; i < header.size(); i++)
        if (!r.get(i).isEmpty()) m.put(header.get(i), r.get(i));
      result.add(m);
    }
    return result;
  }

  public static byte[] encode(List<String> fields, List<Map<String, Object>> rows) {
    StringBuilder out = new StringBuilder("\uFEFF");
    out.append(String.join(",", fields)).append("\r\n");
    for (var row : rows) {
      var values = new ArrayList<String>();
      for (String f : fields) {
        String s = row.get(f) == null ? "" : row.get(f).toString();
        String trimmed = s.stripLeading();
        if ((!trimmed.isEmpty() && "=+@-".indexOf(trimmed.charAt(0)) >= 0)
            || s.startsWith("\t")
            || s.startsWith("\r")) s = "'" + s;
        values.add("\"" + s.replace("\"", "\"\"") + "\"");
      }
      out.append(String.join(",", values)).append("\r\n");
    }
    return out.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
  }
}
