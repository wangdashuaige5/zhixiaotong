package com.zhixiaotong.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhixiaotong.common.*;
import com.zhixiaotong.dto.Result;
import com.zhixiaotong.security.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.util.*;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.*;
import org.springframework.web.filter.OncePerRequestFilter;

@Configuration
public class SecurityConfig {
  @Bean
  SecurityFilterChain security(
      HttpSecurity http,
      TokenService tokens,
      Access access,
      RequestLimiter limiter,
      ObjectMapper json,
      @Value("${campus.allowed-origins}") String origins)
      throws Exception {
    http.csrf(c -> c.disable())
        .cors(
            c ->
                c.configurationSource(
                    r -> {
                      var cors = new CorsConfiguration();
                      cors.setAllowedOrigins(Arrays.asList(origins.split(",")));
                      cors.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
                      cors.setAllowedHeaders(
                          List.of(
                              "Authorization",
                              "Content-Type",
                              "X-Request-Id",
                              "X-Payment-Signature",
                              "X-Payment-Timestamp"));
                      return cors;
                    }))
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
    http.authorizeHttpRequests(
        a ->
            a.requestMatchers(
                    "/api/auth/login",
                    "/api/auth/refresh",
                    "/api/integrations/payments/callback",
                    "/actuator/health",
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/v3/api-docs/**")
                .permitAll()
                .anyRequest()
                .authenticated());
    http.exceptionHandling(
        e ->
            e.authenticationEntryPoint((r, s, x) -> write(s, json, 401, "请先登录"))
                .accessDeniedHandler((r, s, x) -> write(s, json, 403, "无权访问")));
    http.addFilterBefore(
        new OncePerRequestFilter() {
          @Override
          protected void doFilterInternal(
              HttpServletRequest req, HttpServletResponse res, FilterChain chain)
              throws java.io.IOException, ServletException {
            String requestId = req.getHeader("X-Request-Id");
            if (requestId == null || !requestId.matches("[A-Za-z0-9_-]{1,64}"))
              requestId = UUID.randomUUID().toString();
            MDC.put("request_id", requestId);
            res.setHeader("X-Request-Id", requestId);
            try {
              if (req.getRequestURI().startsWith("/api/auth/"))
                limiter.check("auth:" + req.getRemoteAddr(), 30, 60);
              String auth = req.getHeader("Authorization");
              if (auth != null && auth.startsWith("Bearer ")) {
                var user =
                    tokens.verify(
                        auth.substring(7), req.getRequestURI().equals("/api/auth/logout"));
                SecurityContextHolder.getContext()
                    .setAuthentication(
                        new UsernamePasswordAuthenticationToken(user, null, List.of()));
              }
              if (req.getRequestURI().startsWith("/actuator/")
                  && !req.getRequestURI().equals("/actuator/health")) access.require("admin:read");
              if (req.getRequestURI().matches("/api/attendance/tasks/[^/]+/sign"))
                limiter.check("sign:" + access.uid(), 10, 60);
              chain.doFilter(req, res);
            } catch (BizException e) {
              write(res, json, e.status, e.getMessage());
            } catch (org.springframework.data.redis.RedisConnectionFailureException e) {
              write(res, json, 503, "认证服务暂不可用");
            } finally {
              SecurityContextHolder.clearContext();
              MDC.remove("request_id");
            }
          }
        },
        UsernamePasswordAuthenticationFilter.class);
    return http.build();
  }

  private static void write(HttpServletResponse r, ObjectMapper j, int code, String message)
      throws java.io.IOException {
    r.setStatus(code);
    r.setContentType("application/json;charset=UTF-8");
    j.writeValue(r.getOutputStream(), Result.error(code, message));
  }
}
