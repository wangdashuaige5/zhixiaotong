package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.security.*;
import java.math.*;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 本地模拟账本和图书规则；正式模式在取得学校协议之前明确关闭外部写操作。 */
@Service
public class LifeService {
  private final Db db;
  private final Access access;
  private final AuditService audit;
  private final String mode, secret;

  public LifeService(
      Db db,
      Access access,
      AuditService audit,
      @Value("${campus.integration-mode}") String mode,
      @Value("${campus.payment-secret}") String secret) {
    this.db = db;
    this.access = access;
    this.audit = audit;
    this.mode = mode;
    this.secret = secret;
  }

  private void mock() {
    check(mode.equals("mock"), 503, "学校平台接口尚未配置，此操作暂不可用");
  }

  private Map<String, Object> account() {
    access.require("life:write");
    var a = db.one("SELECT * FROM card_account WHERE user_id=?", access.uid());
    check(a != null, 404, "尚未绑定校园卡");
    return a;
  }

  public Object balance() {
    var a = account();
    var r = pick(a, "id", "card_no", "balance", "account_status", "sync_time");
    r.put("integration_mode", mode);
    return r;
  }

  @Transactional
  public Object recharge(Map<String, Object> b) {
    mock();
    var a = account();
    db.lock("user", access.uid());
    String key = text(b, "request_key", 64);
    var amount = dec(b, "amount");
    check(
        amount.signum() > 0
            && amount.scale() <= 2
            && amount.compareTo(new BigDecimal("10000")) <= 0,
        400,
        "充值金额应大于0、不超过10000且最多两位小数");
    String channel = text(b, "pay_channel", 32);
    check(channel.equals("MOCK_PAY"), 400, "演示模式仅支持MOCK_PAY");
    var old = db.one("SELECT * FROM recharge_order WHERE request_key=?", key);
    if (old != null) {
      check(
          eq(old.get("account_id"), a.get("id"))
              && amount.compareTo(dec(old, "amount")) == 0
              && eq(old.get("pay_channel"), channel),
          409,
          "请求键已用于不同充值");
      return old;
    }
    check(integer(a, "account_status", 0) == 1, 409, "校园卡账户不可充值");
    long id =
        db.insert(
            "recharge_order",
            map(
                "order_no",
                "MOCK-" + UUID.randomUUID(),
                "account_id",
                a.get("id"),
                "amount",
                amount,
                "pay_channel",
                channel,
                "request_key",
                key,
                "expire_time",
                now().plusMinutes(30)));
    audit.log("RECHARGE_CREATE", "recharge_order", id, map("amount", amount, "mode", mode));
    return db.get("recharge_order", id);
  }

  public Object order(long id) {
    var r = db.get("recharge_order", id);
    check(eq(r.get("account_id"), account().get("id")), 403, "只能查询本人充值");
    r.put("integration_mode", mode);
    return r;
  }

  public Object transactions(Map<String, Object> q) {
    return db.page(
        "SELECT * FROM card_transaction WHERE account_id=?"
            + (q.containsKey("start_date") ? " AND transaction_time>=?" : "")
            + " ORDER BY id DESC",
        q,
        q.containsKey("start_date")
            ? new Object[] {account().get("id"), date(q.get("start_date")).atStartOfDay()}
            : new Object[] {account().get("id")});
  }

  public void verifySignature(String raw, String timestamp, String signature) {
    mock();
    check(secret.length() >= 24, 503, "支付模拟验签密钥未配置");
    long sec;
    try {
      sec = Long.parseLong(timestamp);
    } catch (Exception e) {
      throw new BizException(401, "支付时间戳无效");
    }
    check(Math.abs(System.currentTimeMillis() / 1000 - sec) <= 300, 401, "支付通知时间戳已过期");
    check(Crypto.same(Crypto.hmac(secret, timestamp + "\n" + raw), signature), 401, "支付通知验签失败");
  }

  @Transactional(noRollbackFor = BizException.class)
  public Object callback(Map<String, Object> b) {
    mock();
    String no = text(b, "order_no", 64), trade = text(b, "pay_trade_no", 64);
    var r = db.one("SELECT * FROM recharge_order WHERE order_no=? FOR UPDATE", no);
    check(r != null, 404, "充值订单不存在");
    long id = num(r.get("id"));
    check(
        str(r, "pay_channel").equals(text(b, "pay_channel", 32))
            && dec(r, "amount").compareTo(dec(b, "amount")) == 0,
        400,
        "通知渠道或金额与订单不一致");
    int state = integer(r, "order_status", 0);
    if (state == 3) {
      audit.logAs(
          null,
          "PAYMENT_RECONCILIATION",
          "recharge_order",
          id,
          map("reason", "已关闭订单收到支付通知"),
          false);
      throw new BizException(409, "已关闭订单收到付款，请联系管理员对账");
    }
    if (state == 1 || state == 2) {
      check(eq(r.get("pay_trade_no"), trade), 409, "支付交易号不一致");
      return r;
    }
    db.update(
        "recharge_order",
        id,
        map("pay_trade_no", trade, "order_status", 1, "pay_time", now(), "callback_time", now()));
    audit.logAs(null, "PAYMENT_VERIFIED", "recharge_order", id, map("mode", "mock"), false);
    return db.get("recharge_order", id);
  }

  @Transactional
  public Object post(long id) {
    mock();
    var r = db.lock("recharge_order", id);
    if (integer(r, "order_status", 0) == 2) return r;
    check(integer(r, "order_status", 0) == 1, 409, "支付尚未核验");
    var a = db.lock("card_account", num(r.get("account_id")));
    check(integer(a, "account_status", 0) == 1, 409, "卡账户不可入账，转对账处理");
    BigDecimal before = dec(a, "balance"), amount = dec(r, "amount"), after = before.add(amount);
    db.insert(
        "card_transaction",
        map(
            "transaction_no",
            "MOCK-TX-" + UUID.randomUUID(),
            "account_id",
            a.get("id"),
            "recharge_id",
            id,
            "source_system",
            "MOCK_PAY",
            "source_trade_no",
            r.get("pay_trade_no"),
            "transaction_type",
            1,
            "amount",
            amount,
            "balance_before",
            before,
            "balance_after",
            after,
            "transaction_time",
            now()));
    db.update(
        "card_account",
        num(a.get("id")),
        map("balance", after, "version", integer(a, "version", 0) + 1, "sync_time", now()));
    db.update("recharge_order", id, map("order_status", 2, "posted_time", now()));
    audit.log("RECHARGE_POST", "recharge_order", id, map("amount", amount));
    audit.event("recharge_order", id, "模拟充值已入账", List.of(num(a.get("user_id"))));
    return db.get("recharge_order", id);
  }

  public Object books(Map<String, Object> q) {
    access.require("life:write");
    String words = "%" + str(q, "keywords") + "%";
    return db.page(
        "SELECT b.*,(SELECT COUNT(*) FROM book_copy c WHERE c.book_id=b.id AND c.copy_status=0) AS"
            + " available_count FROM book b WHERE (b.book_name LIKE ? OR b.author LIKE ?)"
            + (q.containsKey("category_code") ? " AND b.category_code=?" : "")
            + " ORDER BY b.id",
        q,
        q.containsKey("category_code")
            ? new Object[] {words, words, text(q, "category_code", 32)}
            : new Object[] {words, words});
  }

  public Object loans(Map<String, Object> q) {
    access.require("life:write");
    return db.page(
        "SELECT l.*,b.book_name,c.copy_no FROM book_loan l JOIN book_copy c ON c.id=l.copy_id JOIN"
            + " book b ON b.id=c.book_id WHERE l.reader_id=? ORDER BY l.id DESC",
        q,
        access.uid());
  }

  @Transactional
  public Object renew(long id) {
    mock();
    access.require("life:write");
    db.lock("user", access.uid());
    var initial = db.get("book_loan", id);
    var copy = db.get("book_copy", num(initial.get("copy_id")));
    db.lock("book", num(copy.get("book_id")));
    var loan = db.lock("book_loan", id);
    check(eq(loan.get("reader_id"), access.uid()), 403, "只能续借本人图书");
    check(integer(loan, "loan_status", 0) == 0, 409, "图书已归还或挂失");
    if (loan.get("renew_time") != null
        && time(loan.get("renew_time")).isAfter(now().minusMinutes(1))) return loan;
    check(
        time(loan.get("due_time")).isAfter(now()) && integer(loan, "renew_count", 0) < 2,
        409,
        "已逾期或达到2次续借上限");
    check(
        db.count(
                "SELECT COUNT(*) FROM book_reservation WHERE book_id=? AND reserve_status IN (0,1)"
                    + " AND reader_id<>?",
                copy.get("book_id"),
                access.uid())
            == 0,
        409,
        "该书已被其他读者预约");
    db.update(
        "book_loan",
        id,
        map(
            "due_time",
            time(loan.get("due_time")).plusDays(30),
            "renew_count",
            integer(loan, "renew_count", 0) + 1,
            "renew_time",
            now()));
    audit.log("LIBRARY_RENEW", "book_loan", id, map("mode", mode));
    return db.get("book_loan", id);
  }

  @Transactional
  public Object reserve(Map<String, Object> b) {
    mock();
    access.require("life:write");
    db.lock("user", access.uid());
    long book = id(b, "book_id");
    db.lock("book", book);
    String key = text(b, "request_key", 64);
    var old = db.one("SELECT * FROM book_reservation WHERE request_key=?", key);
    if (old != null) {
      check(
          eq(old.get("reader_id"), access.uid()) && eq(old.get("book_id"), book),
          409,
          "请求键已用于其他预约");
      return old;
    }
    allocateWaiting(book);
    check(
        db.count(
                "SELECT COUNT(*) FROM book_reservation WHERE reader_id=? AND book_id=? AND"
                    + " reserve_status IN (0,1)",
                access.uid(),
                book)
            == 0,
        409,
        "已有有效预约");
    var copy =
        db.one(
            "SELECT * FROM book_copy WHERE book_id=? AND copy_status=0 ORDER BY id LIMIT 1 FOR"
                + " UPDATE",
            book);
    int state = copy == null ? 0 : 1;
    if (copy != null)
      db.update(
          "book_copy",
          num(copy.get("id")),
          map("copy_status", 2, "version", integer(copy, "version", 0) + 1));
    long id =
        db.insert(
            "book_reservation",
            map(
                "reader_id",
                access.uid(),
                "book_id",
                book,
                "copy_id",
                copy == null ? null : copy.get("id"),
                "request_key",
                key,
                "reserve_time",
                now(),
                "reserve_status",
                state,
                "expire_time",
                copy == null ? null : now().plusDays(2),
                "notify_time",
                copy == null ? null : now()));
    audit.log("BOOK_RESERVE", "book_reservation", id, map("state", state));
    return db.get("book_reservation", id);
  }

  @Transactional
  public void cancel(long id) {
    mock();
    access.require("life:write");
    db.lock("user", access.uid());
    var r = db.get("book_reservation", id);
    db.lock("book", num(r.get("book_id")));
    r = db.lock("book_reservation", id);
    check(eq(r.get("reader_id"), access.uid()), 403, "仅可取消本人预约");
    if (integer(r, "reserve_status", 0) == 3) return;
    check(Set.of(0, 1).contains(integer(r, "reserve_status", 0)), 409, "当前预约不可取消");
    release(r, 3);
    audit.log("BOOK_CANCEL", "book_reservation", id, map());
  }

  private void release(Map<String, Object> r, int status) {
    if (r.get("copy_id") != null) {
      var c = db.lock("book_copy", num(r.get("copy_id")));
      if (integer(c, "copy_status", 0) == 2)
        db.update(
            "book_copy",
            num(c.get("id")),
            map("copy_status", 0, "version", integer(c, "version", 0) + 1));
    }
    db.update("book_reservation", num(r.get("id")), map("reserve_status", status));
    allocateWaiting(num(r.get("book_id")));
  }

  @Transactional
  public void allocate(long book) {
    mock();
    db.lock("book", book);
    allocateWaiting(book);
  }

  private void allocateWaiting(long book) {
    for (; ; ) {
      var next =
          db.one(
              "SELECT * FROM book_reservation WHERE book_id=? AND reserve_status=0 ORDER BY"
                  + " reserve_time,id LIMIT 1 FOR UPDATE",
              book);
      if (next == null) return;
      var copy =
          db.one(
              "SELECT * FROM book_copy WHERE book_id=? AND copy_status=0 ORDER BY id LIMIT 1 FOR"
                  + " UPDATE",
              book);
      if (copy == null) return;
      db.update(
          "book_copy",
          num(copy.get("id")),
          map("copy_status", 2, "version", integer(copy, "version", 0) + 1));
      db.update(
          "book_reservation",
          num(next.get("id")),
          map(
              "copy_id",
              copy.get("id"),
              "reserve_status",
              1,
              "notify_time",
              now(),
              "expire_time",
              now().plusDays(2)));
      audit.event(
          "book_reservation", num(next.get("id")), "预约图书已可领取", List.of(num(next.get("reader_id"))));
    }
  }

  @Transactional
  public void expireReservation(long id) {
    var initial = db.get("book_reservation", id);
    db.lock("user", num(initial.get("reader_id")));
    db.lock("book", num(initial.get("book_id")));
    var r = db.lock("book_reservation", id);
    if (integer(r, "reserve_status", 0) == 1
        && r.get("expire_time") != null
        && time(r.get("expire_time")).isBefore(now())) release(r, 4);
  }

  public Object reservations(Map<String, Object> q) {
    access.require("life:write");
    return db.page(
        "SELECT r.*,b.book_name FROM book_reservation r JOIN book b ON b.id=r.book_id WHERE"
            + " r.reader_id=? ORDER BY r.id DESC",
        q,
        access.uid());
  }

  @Transactional
  public void expireOrder(long id) {
    mock();
    var r = db.lock("recharge_order", id);
    if (integer(r, "order_status", 0) == 0 && time(r.get("expire_time")).isBefore(now())) {
      db.update("recharge_order", id, map("order_status", 3));
      audit.logAs(null, "MOCK_ORDER_CLOSE", "recharge_order", id, map(), false);
    }
  }
}
