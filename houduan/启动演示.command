#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
if ! command -v docker >/dev/null 2>&1; then
  echo '请先安装并启动 Docker Desktop。'
  exit 1
fi
docker compose -f compose.demo.yml up -d --build
echo '启动请求已提交。首次初始化需要稍等，然后访问 http://localhost:8080/swagger-ui.html'
docker compose -f compose.demo.yml logs --tail=50 app
