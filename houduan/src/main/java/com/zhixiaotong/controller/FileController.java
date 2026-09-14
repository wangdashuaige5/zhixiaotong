package com.zhixiaotong.controller;

import com.zhixiaotong.dto.Result;
import com.zhixiaotong.service.FileService;
import java.nio.charset.StandardCharsets;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/files")
public class FileController {
  private final FileService s;

  public FileController(FileService s) {
    this.s = s;
  }

  @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public Result upload(@RequestPart("file") MultipartFile f) throws java.io.IOException {
    return Result.success(s.upload(f));
  }

  @GetMapping("/{id}")
  public Result status(@PathVariable long id) {
    return Result.success(s.status(id));
  }

  @DeleteMapping("/{id}")
  public Result delete(@PathVariable long id) {
    s.delete(id);
    return Result.success(null);
  }

  @GetMapping("/{id}/download")
  public ResponseEntity<byte[]> download(@PathVariable long id) {
    var meta = s.status(id);
    return ResponseEntity.ok()
        .contentType(MediaType.parseMediaType(meta.get("mime_type").toString()))
        .header(
            "Content-Disposition",
            ContentDisposition.attachment()
                .filename(meta.get("original_name").toString(), StandardCharsets.UTF_8)
                .build()
                .toString())
        .header("Cache-Control", "no-store")
        .header("X-Content-Type-Options", "nosniff")
        .body(s.download(id));
  }
}
