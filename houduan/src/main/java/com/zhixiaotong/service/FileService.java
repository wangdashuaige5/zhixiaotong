package com.zhixiaotong.service;

import static com.zhixiaotong.common.BizException.check;
import static com.zhixiaotong.common.Data.*;

import com.zhixiaotong.common.*;
import com.zhixiaotong.integration.*;
import com.zhixiaotong.security.*;
import java.io.*;
import java.util.*;
import org.apache.tika.Tika;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.*;
import org.springframework.web.multipart.MultipartFile;

@Service
public class FileService {
  private final Db db;
  private final Access access;
  private final ObjectStorage storage;
  private final FileScanner scanner;
  private final BusinessAccess business;
  private final AuditService audit;

  public FileService(
      Db db,
      Access access,
      ObjectStorage storage,
      FileScanner scanner,
      BusinessAccess business,
      AuditService audit) {
    this.db = db;
    this.access = access;
    this.storage = storage;
    this.scanner = scanner;
    this.business = business;
    this.audit = audit;
  }

  @Transactional
  public Object upload(MultipartFile file) throws IOException {
    access.require("file:write");
    check(!file.isEmpty() && file.getSize() <= 100L * 1024 * 1024, 400, "文件必须在1字节至100MB之间");
    String name =
        file.getOriginalFilename() == null
            ? "attachment"
            : file.getOriginalFilename().replaceAll("[\\\\/\\r\\n]", "_");
    check(name.length() <= 255, 400, "文件名过长");
    byte[] bytes = file.getBytes();
    String mime = new Tika().detect(bytes);
    String ext = name.contains(".") ? name.substring(name.lastIndexOf('.') + 1).toLowerCase() : "";
    var extensions =
        db.one(
            "SELECT config_value FROM system_config WHERE config_key='file.allowed_extensions' AND"
                + " is_enabled=1");
    if (extensions != null)
      check(
          Arrays.stream(str(extensions, "config_value").split(","))
              .map(String::trim)
              .anyMatch(ext::equals),
          400,
          "该文件类型已被管理员禁用");
    var max =
        db.one(
            "SELECT config_value FROM system_config WHERE config_key='file.max_mb' AND"
                + " is_enabled=1");
    if (max != null)
      check(
          bytes.length <= Math.min(100, Long.parseLong(str(max, "config_value"))) * 1024 * 1024,
          400,
          "超过管理员设置的文件大小上限");
    boolean valid =
        (mime.equals("application/pdf") && ext.equals("pdf"))
            || (mime.equals("image/png") && ext.equals("png"))
            || (mime.equals("image/jpeg") && Set.of("jpg", "jpeg").contains(ext))
            || (mime.equals("text/plain") && Set.of("txt", "csv").contains(ext));
    if (Set.of("docx", "xlsx", "pptx").contains(ext)
        && (mime.equals("application/zip") || mime.startsWith("application/vnd.openxmlformats"))) {
      validateOffice(bytes);
      valid = true;
      mime =
          switch (ext) {
            case "docx" ->
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            case "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            default -> "application/vnd.openxmlformats-officedocument.presentationml.presentation";
          };
    }
    check(valid, 400, "支持PDF、PNG、JPEG、TXT、CSV及不含宏的Office文件，实际内容须匹配类型");
    scanner.scan(bytes);
    long id = saveGenerated(name, mime, bytes, "temporary", null, access.uid());
    audit.log("FILE_UPLOAD", "file_upload", id, map("size", bytes.length));
    return status(id);
  }

  private void validateOffice(byte[] bytes) throws IOException {
    boolean content = false;
    long total = 0;
    int count = 0;
    try (var zip = new java.util.zip.ZipInputStream(new ByteArrayInputStream(bytes))) {
      for (java.util.zip.ZipEntry e; (e = zip.getNextEntry()) != null; ) {
        check(++count <= 5000, 400, "压缩包文件过多");
        String n = e.getName();
        check(
            !n.contains("..") && !n.toLowerCase().contains("vbaproject") && !n.startsWith("/"),
            400,
            "Office文件包含危险项目");
        if (n.equals("[Content_Types].xml")) content = true;
        byte[] buf = new byte[8192];
        int len;
        while ((len = zip.read(buf)) != -1) {
          total += len;
          check(total <= 200L * 1024 * 1024, 400, "文件展开体积超过限制");
        }
      }
    }
    check(content, 400, "Office结构无效");
  }

  public long saveGenerated(
      String name, String mime, byte[] bytes, String type, Long bizId, long owner) {
    String key = Crypto.random();
    storage.put(key, bytes, mime);
    if (TransactionSynchronizationManager.isSynchronizationActive())
      TransactionSynchronizationManager.registerSynchronization(
          new TransactionSynchronization() {
            @Override
            public void afterCompletion(int state) {
              if (state != STATUS_COMMITTED)
                try {
                  storage.delete(key);
                } catch (Exception ignored) {
                }
            }
          });
    String hash;
    try {
      hash =
          HexFormat.of()
              .formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (Exception e) {
      throw new IllegalStateException(e);
    }
    try {
      return db.insert(
          "file_upload",
          map(
              "bucket_name",
              storage.bucket(),
              "object_key",
              key,
              "original_name",
              name,
              "mime_type",
              mime,
              "file_size",
              (long) bytes.length,
              "file_hash",
              hash,
              "biz_type",
              type,
              "biz_id",
              bizId,
              "uploader_id",
              owner,
              "scan_status",
              1,
              "file_status",
              bizId == null ? 0 : 1));
    } catch (RuntimeException e) {
      storage.delete(key);
      throw e;
    }
  }

  public void bind(List<Long> ids, String type, long bizId) {
    for (long id : new TreeSet<>(ids)) {
      var f = db.lock("file_upload", id);
      check(eq(f.get("uploader_id"), access.uid()), 403, "附件必须属于当前用户");
      check(integer(f, "scan_status", 0) == 1, 409, "附件尚未检测通过");
      check(
          integer(f, "file_status", 0) == 0
              || (str(f, "biz_type").equals(type) && eq(f.get("biz_id"), bizId)),
          409,
          "附件已经绑定其他业务");
      db.update("file_upload", id, map("biz_type", type, "biz_id", bizId, "file_status", 1));
    }
  }

  public Map<String, Object> status(long id) {
    var f = db.get("file_upload", id);
    check(integer(f, "file_status", 0) != 2, 404, "文件正在清理");
    if (integer(f, "file_status", 0) == 0)
      check(eq(f.get("uploader_id"), access.uid()), 403, "无权读取附件");
    else business.checkRead(str(f, "biz_type"), num(f.get("biz_id")));
    return pick(
        f,
        "id",
        "original_name",
        "mime_type",
        "file_size",
        "file_hash",
        "scan_status",
        "file_status",
        "biz_type",
        "biz_id",
        "create_time");
  }

  public byte[] download(long id) {
    status(id);
    var f = db.get("file_upload", id);
    check(integer(f, "scan_status", 0) == 1, 409, "文件尚未检测通过");
    audit.log("FILE_DOWNLOAD", "file_upload", id, map());
    return storage.read(str(f, "object_key"));
  }

  @Transactional
  public void delete(long id) {
    var f = db.lock("file_upload", id);
    check(eq(f.get("uploader_id"), access.uid()), 403, "无权移除附件");
    check(integer(f, "file_status", 0) != 1, 409, "已绑定文件须从业务流程处理");
    storage.delete(str(f, "object_key"));
    db.update("file_upload", id, map("file_status", 2));
    audit.log("FILE_DELETE", "file_upload", id, map());
  }

  @Transactional
  public void cleanup(long id) {
    var f = db.lock("file_upload", id);
    if (integer(f, "file_status", 0) == 0
        && time(f.get("create_time")).isBefore(now().minusHours(24))) {
      storage.delete(str(f, "object_key"));
      db.update("file_upload", id, map("file_status", 2));
    }
  }

  public byte[] ownInput(long id) {
    var f = db.get("file_upload", id);
    check(
        eq(f.get("uploader_id"), access.uid())
            && integer(f, "scan_status", 0) == 1
            && integer(f, "file_status", 0) != 2,
        403,
        "无权使用输入文件");
    return storage.read(str(f, "object_key"));
  }
}
