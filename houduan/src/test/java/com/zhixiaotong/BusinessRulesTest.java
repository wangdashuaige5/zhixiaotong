package com.zhixiaotong;

import static com.zhixiaotong.common.Data.*;
import static org.junit.jupiter.api.Assertions.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Crypto;
import com.zhixiaotong.service.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import org.junit.jupiter.api.Test;

class BusinessRulesTest {
  @Test
  void oppositeParityAndTouchingTimesDoNotClash() {
    var a =
        map(
            "week_day",
            1,
            "start_time",
            "09:00",
            "end_time",
            "10:00",
            "start_week",
            1,
            "end_week",
            18,
            "week_mode",
            2);
    var b = new HashMap<>(a);
    b.put("week_mode", 3);
    assertFalse(ScheduleValidator.overlap(a, b));
    b.put("week_mode", 1);
    assertTrue(ScheduleValidator.overlap(a, b));
    b.put("start_time", "10:00");
    b.put("end_time", "11:00");
    assertFalse(ScheduleValidator.overlap(a, b));
  }

  @Test
  void leaveBoundaryAndJsonDate() {
    var start = LocalDateTime.of(2026, 9, 7, 9, 0);
    assertEquals(new BigDecimal("3.00"), LeaveService.days(start, start.plusDays(3)));
    assertTrue(
        LeaveService.days(start, start.plusDays(3).plusSeconds(1)).compareTo(new BigDecimal("3"))
            > 0);
    assertEquals(start, time(Json.object(Json.write(map("time", start))).get("time")));
  }

  @Test
  void scoreWeightsAndMissingExam() {
    var tc = map("usual_weight", "0.4", "final_weight", "0.6");
    assertEquals(
        new BigDecimal("86.00"),
        GradeService.calculate(map("usual_score", 80, "final_score", 90), tc, true)
            .get("total_score"));
    assertEquals(
        new BigDecimal("32.00"),
        GradeService.calculate(map("usual_score", 80, "exam_flag", 1), tc, true)
            .get("total_score"));
    assertThrows(
        BizException.class, () -> GradeService.calculate(map("usual_score", 101), tc, true));
    assertThrows(
        BizException.class,
        () -> GradeService.calculate(map("usual_score", 80, "exam_flag", 2), tc, true));
  }

  @Test
  void csvQuotedNewlinesAndFormulaProtection() {
    var rows = Csv.parse("name,note\n\"张三\",\"第一行\n第二行\"\n");
    assertEquals(1, rows.size());
    assertEquals("第一行\n第二行", rows.get(0).get("note"));
    var csv =
        new String(
            Csv.encode(List.of("name"), List.of(map("name", "=1+1"))),
            java.nio.charset.StandardCharsets.UTF_8);
    assertTrue(csv.contains("'=1+1"));
    assertThrows(BizException.class, () -> Csv.parse("a,a\n1,2"));
  }

  @Test
  void encryptionIsAuthenticated() {
    var crypto = new Crypto("test-encryption-key-at-least-thirty-two-chars");
    String value = crypto.encrypt("测试敏感数据");
    assertNotEquals("测试敏感数据", value);
    assertEquals("测试敏感数据", crypto.decrypt(value));
    assertThrows(
        IllegalStateException.class,
        () -> new Crypto("another-encryption-key-at-least-thirty-two").decrypt(value));
  }
}
