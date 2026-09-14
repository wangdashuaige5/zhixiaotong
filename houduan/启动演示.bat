@echo off
chcp 65001 >nul
cd /d "%~dp0"
docker compose -f compose.demo.yml up -d --build
if errorlevel 1 goto failed
echo 启动请求已提交，首次初始化需要稍等。
echo 接口调试页：http://localhost:8080/swagger-ui.html
docker compose -f compose.demo.yml logs --tail=50 app
pause
exit /b 0
:failed
echo 请检查 Docker Desktop 是否已经安装并启动，以及网络是否可用。
pause
exit /b 1
