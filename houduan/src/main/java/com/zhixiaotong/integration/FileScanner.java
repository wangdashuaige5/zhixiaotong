package com.zhixiaotong.integration;

import com.zhixiaotong.common.BizException;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class FileScanner {
  private final String mode, host;
  private final int port;

  public FileScanner(
      @Value("${campus.scan-mode}") String mode,
      @Value("${campus.clamav-host}") String host,
      @Value("${campus.clamav-port}") int port) {
    this.mode = mode;
    this.host = host;
    this.port = port;
  }

  public void scan(byte[] bytes) {
    if (mode.equals("demo")) {
      String s = new String(bytes, StandardCharsets.ISO_8859_1);
      BizException.check(
          !s.contains("EICAR-STANDARD-ANTIVIRUS-TEST-FILE") && !s.toLowerCase().contains("<script"),
          400,
          "演示检测拒绝危险内容");
      return;
    }
    try (Socket sock = new Socket()) {
      sock.connect(new InetSocketAddress(host, port), 3000);
      sock.setSoTimeout(15000);
      var out = new DataOutputStream(sock.getOutputStream());
      out.write("zINSTREAM\0".getBytes(StandardCharsets.US_ASCII));
      for (int i = 0; i < bytes.length; i += 65536) {
        int n = Math.min(65536, bytes.length - i);
        out.writeInt(n);
        out.write(bytes, i, n);
      }
      out.writeInt(0);
      out.flush();
      var in = sock.getInputStream();
      var reply = new ByteArrayOutputStream();
      for (int n; (n = in.read()) > 0 && reply.size() < 4096; ) reply.write(n);
      String text = reply.toString(StandardCharsets.UTF_8);
      BizException.check(text.endsWith(" OK"), 400, "恶意文件检测未通过");
    } catch (BizException e) {
      throw e;
    } catch (Exception e) {
      throw new BizException(503, "恶意文件检测服务暂不可用");
    }
  }
}
