package com.zhixiaotong.dto;

import org.slf4j.MDC;

/** 沿用示例统一响应思路，补齐请求追踪和规范状态码。 */
public record Result(int code, String message, Object data, String requestId) {
  public static Result success(Object data) {
    return new Result(0, "成功", data, MDC.get("request_id"));
  }

  public static Result error(int code, String message) {
    return new Result(code, message, null, MDC.get("request_id"));
  }
}
