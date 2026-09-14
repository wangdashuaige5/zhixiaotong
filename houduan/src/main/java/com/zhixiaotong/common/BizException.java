package com.zhixiaotong.common;

public class BizException extends RuntimeException {
  public final int status;

  public BizException(int status, String message) {
    super(message);
    this.status = status;
  }

  public static void check(boolean ok, int status, String message) {
    if (!ok) throw new BizException(status, message);
  }
}
