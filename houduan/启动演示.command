#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
if ! command -v docker >/dev/null 2>&1; then
  echo '请先安装 Docker，并启动 Docker Desktop 或 Colima。'
  exit 1
fi
# 功能：兼容 Docker Desktop 内置 Compose 和本机独立安装的 docker-compose。
zxt_compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo '未找到 Docker Compose，请先安装 Compose。' >&2
    return 1
  fi
}
if ! docker info >/dev/null 2>&1; then
  echo 'Docker 服务尚未启动，请先启动 Docker Desktop 或 Colima 后重试。'
  exit 1
fi
zxt_compose -f compose.demo.yml up -d --build
echo '启动请求已提交。首次初始化需要稍等，然后访问 http://localhost:8080/swagger-ui.html'
zxt_compose -f compose.demo.yml logs --tail=50 app
