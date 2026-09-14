package com.zhixiaotong.integration;

import com.zhixiaotong.common.BizException;
import io.minio.*;
import java.io.*;
import java.nio.file.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ObjectStorage {
  private final String mode, bucket;
  private final Path root;
  private final MinioClient minio;

  public ObjectStorage(
      @Value("${campus.storage-mode}") String mode,
      @Value("${campus.storage-path}") String root,
      @Value("${campus.minio-endpoint}") String endpoint,
      @Value("${campus.minio-access-key}") String key,
      @Value("${campus.minio-secret-key}") String secret,
      @Value("${campus.minio-bucket}") String bucket) {
    this.mode = mode;
    this.root = Path.of(root).toAbsolutePath().normalize();
    this.bucket = bucket;
    this.minio =
        mode.equals("minio")
            ? MinioClient.builder().endpoint(endpoint).credentials(key, secret).build()
            : null;
  }

  private Path path(String key) {
    BizException.check(key.matches("[a-zA-Z0-9_-]{20,100}"), 400, "对象键不合法");
    return root.resolve(key);
  }

  public void put(String key, byte[] data, String mime) {
    try {
      if (mode.equals("local")) {
        Files.createDirectories(root);
        Files.write(path(key), data, StandardOpenOption.CREATE_NEW);
      } else
        minio.putObject(
            PutObjectArgs.builder().bucket(bucket).object(key).contentType(mime).stream(
                    new ByteArrayInputStream(data), data.length, -1)
                .build());
    } catch (Exception e) {
      throw new BizException(503, "对象存储暂不可用，请检查私有桶配置");
    }
  }

  public byte[] read(String key) {
    try {
      if (mode.equals("local")) return Files.readAllBytes(path(key));
      try (var in = minio.getObject(GetObjectArgs.builder().bucket(bucket).object(key).build())) {
        return in.readAllBytes();
      }
    } catch (Exception e) {
      throw new BizException(503, "文件对象暂不可用");
    }
  }

  public void delete(String key) {
    try {
      if (mode.equals("local")) Files.deleteIfExists(path(key));
      else minio.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(key).build());
    } catch (Exception e) {
      throw new BizException(503, "文件清理失败，稍后重试");
    }
  }

  public String bucket() {
    return mode.equals("local") ? "local-private" : bucket;
  }
}
