package com.zhixiaotong.config;

import com.fasterxml.jackson.databind.*;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import java.math.BigDecimal;
import java.time.*;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.*;

@Configuration
public class JsonConfig {
  @Bean
  Jackson2ObjectMapperBuilderCustomizer jsonTypes() {
    return b -> {
      b.serializerByType(Long.class, ToStringSerializer.instance);
      b.serializerByType(Long.TYPE, ToStringSerializer.instance);
      b.serializerByType(BigDecimal.class, ToStringSerializer.instance);
      b.serializerByType(
          LocalDateTime.class,
          new JsonSerializer<LocalDateTime>() {
            public void serialize(
                LocalDateTime v, com.fasterxml.jackson.core.JsonGenerator g, SerializerProvider p)
                throws java.io.IOException {
              g.writeString(v.atZone(ZoneId.of("Asia/Shanghai")).toOffsetDateTime().toString());
            }
          });
    };
  }
}
