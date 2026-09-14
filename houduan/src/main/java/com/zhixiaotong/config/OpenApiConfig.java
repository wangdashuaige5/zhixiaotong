package com.zhixiaotong.config;

import io.swagger.v3.oas.models.*;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.*;
import org.springframework.context.annotation.*;

@Configuration
public class OpenApiConfig {
  @Bean
  OpenAPI campusApi() {
    return new OpenAPI()
        .info(
            new Info()
                .title("智校通后端接口")
                .version("1.0.0")
                .description(
                    "字段采用下画线；ID和金额输出为字符串。Map请求的具体字段见docs/接口说明.md与api.http。demo下校园卡和图书为模拟服务。"))
        .components(
            new Components()
                .addSecuritySchemes(
                    "bearerAuth",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")))
        .addSecurityItem(new SecurityRequirement().addList("bearerAuth"));
  }
}
