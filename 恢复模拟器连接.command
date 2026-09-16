#!/bin/sh
# 功能：重建智校通模拟器到本机后端的连接，不重启数据库、不清理应用数据。
set -eu
zxt_hdc='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
zxt_finish() {
  if [ -t 0 ]; then
    printf '\n按回车关闭窗口。'
    read -r zxt_reply || true
  fi
}
trap zxt_finish EXIT
if [ ! -x "$zxt_hdc" ]; then
  printf '%s\n' '未找到本机 DevEco 设备工具，请检查 DevEco 安装位置。'
  exit 1
fi
if ! curl -fsS --max-time 8 http://127.0.0.1:8080/actuator/health | grep -q '"status":"UP"'; then
  printf '%s\n' '本机后端未就绪，请先启动智校通后端；本脚本不会擅自重建数据库。'
  exit 1
fi
# 功能：只处理唯一已连接设备，避免多个设备时误改其他人的连接。
zxt_devices=$("$zxt_hdc" list targets | tr -d '\r' | awk 'NF == 1 && $0 !~ /^\[/ {print}')
zxt_count=$(printf '%s\n' "$zxt_devices" | awk 'NF {count++} END {print count+0}')
if [ "$zxt_count" -ne 1 ]; then
  printf '%s\n' '请先在 DevEco 启动一台模拟器，并保证只连接一个调试设备，再重试。'
  exit 1
fi
zxt_rules=$("$zxt_hdc" -t "$zxt_devices" fport ls | tr -d '\r')
if ! printf '%s\n' "$zxt_rules" | awk -v target="$zxt_devices" '$1 == target && $2 == "tcp:8080" && $3 == "tcp:8080" && $4 == "[Reverse]" {ok=1} END {exit !ok}'; then
  zxt_result=$("$zxt_hdc" -t "$zxt_devices" rport tcp:8080 tcp:8080)
  if ! printf '%s\n' "$zxt_result" | grep -q 'Forwardport result:OK'; then
    printf '%s\n' "$zxt_result" '转发未恢复。若提示 8080 listen failed，可能有模拟器内部残留通道；请正常重启模拟器后再运行本脚本。不要清除应用数据，也无需修改数据库端口。'
    exit 1
  fi
fi
printf '%s\n' '本机后端正常，模拟器 8080 转发规则已建立。请打开智校通重新登录。' '如果仍无法连接，可正常重启模拟器后再次运行本脚本。本脚本不会修改项目源码、安装包或业务数据。'
