package com.zhixiaotong.common;

import com.zhixiaotong.dto.Result;
import org.slf4j.LoggerFactory;
import org.springframework.dao.*;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(BizException.class)
  ResponseEntity<Result> business(BizException e) {
    return ResponseEntity.status(e.status).body(Result.error(e.status, e.getMessage()));
  }

  @ExceptionHandler({
    MethodArgumentNotValidException.class,
    HttpMessageNotReadableException.class,
    MethodArgumentTypeMismatchException.class,
    org.springframework.web.bind.ServletRequestBindingException.class,
    IllegalArgumentException.class,
    ArithmeticException.class
  })
  ResponseEntity<Result> bad(Exception e) {
    return ResponseEntity.badRequest().body(Result.error(400, "请求字段、格式或取值不正确"));
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  ResponseEntity<Result> large(Exception e) {
    return ResponseEntity.status(413).body(Result.error(413, "单文件最多100MB"));
  }

  @ExceptionHandler({DataIntegrityViolationException.class, ConcurrencyFailureException.class})
  ResponseEntity<Result> conflict(Exception e) {
    return ResponseEntity.status(409).body(Result.error(409, "数据已变化、重复或违反约束，请核对后重试"));
  }

  @ExceptionHandler(DataAccessException.class)
  ResponseEntity<Result> database(Exception e) {
    LoggerFactory.getLogger(getClass()).error("数据库请求失败，异常类型 {}", e.getClass().getSimpleName());
    return ResponseEntity.status(503).body(Result.error(503, "数据服务暂不可用"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<Result> unknown(Exception e) {
    LoggerFactory.getLogger(getClass()).error("请求处理失败，异常类型 {}", e.getClass().getSimpleName());
    return ResponseEntity.internalServerError().body(Result.error(500, "服务器处理失败，请提供请求ID"));
  }
}
