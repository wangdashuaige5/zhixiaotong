package com.zhixiaotong.service;

import java.util.Map;

public interface IUserService {
  Map<String, Object> login(Map<String, Object> body);

  Map<String, Object> me();

  Map<String, Object> profile(Map<String, Object> body);

  void password(Map<String, Object> body);
}
