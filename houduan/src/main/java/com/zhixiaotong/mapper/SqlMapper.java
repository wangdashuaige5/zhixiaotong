package com.zhixiaotong.mapper;

import java.util.*;
import org.apache.ibatis.annotations.*;

/** 仅服务端常量SQL可调用；所有值通过#{args[n]}绑定，绝不接受客户端SQL。 */
@Mapper
public interface SqlMapper {
  @SelectProvider(type = Provider.class, method = "sql")
  List<Map<String, Object>> query(Command command);

  @UpdateProvider(type = Provider.class, method = "sql")
  int execute(Command command);

  @InsertProvider(type = Provider.class, method = "sql")
  @Options(useGeneratedKeys = true, keyProperty = "id")
  int insert(Command command);

  class Command {
    public String sql;
    public Object[] args;
    public Long id;

    public Command(String sql, Object... args) {
      this.sql = sql;
      this.args = args;
    }
  }

  class Provider {
    public static String sql(Command c) {
      StringBuilder s = new StringBuilder();
      int index = 0;
      for (char ch : c.sql.toCharArray()) {
        if (ch == '?') s.append("#{args[").append(index++).append("],javaType=java.lang.Object}");
        else s.append(ch);
      }
      if (index != c.args.length) throw new IllegalArgumentException("SQL参数数量不匹配");
      return s.toString();
    }
  }
}
