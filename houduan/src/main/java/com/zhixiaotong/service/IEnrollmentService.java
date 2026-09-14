package com.zhixiaotong.service;

import java.util.Map;

public interface IEnrollmentService {
  Object batches();

  Object options(Map<String, Object> query);

  Object mine(Map<String, Object> query);

  Map<String, Object> submit(Map<String, Object> body);

  Map<String, Object> drop(long id);

  void settle(long batchCourseId);
}
