package com.zhixiaotong.dto;

import java.util.List;

public record PageDto(List<?> items, long total, int pageNo, int pageSize) {}
