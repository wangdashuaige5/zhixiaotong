package com.zhixiaotong.security;

public record LoginUser(long id, String sessionId, String deviceCode) {}
