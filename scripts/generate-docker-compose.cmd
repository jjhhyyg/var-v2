@echo off
REM 生成独立的 docker-compose.yml 文件（Windows CMD 脚本版本）
REM 使用方式: scripts\generate-docker-compose.cmd [dev|prod]
REM
REM 此脚本会调用 Python 版本的脚本来完成实际工作

setlocal

if "%~1"=="" goto usage
if not "%~1"=="dev" if not "%~1"=="prod" goto usage

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..

REM 切换到项目根目录
cd /d "%PROJECT_ROOT%"

REM 检查 Python 是否可用
where python3 >nul 2>&1
if %errorlevel% equ 0 (
    python3 "%SCRIPT_DIR%generate-docker-compose.py" %1
    goto end
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    python "%SCRIPT_DIR%generate-docker-compose.py" %1
    goto end
)

echo 错误: 未找到 Python
echo 请安装 Python 3 或直接使用 generate-docker-compose.py
exit /b 1

:usage
echo 使用方式: scripts\generate-docker-compose.cmd [dev^|prod]
echo.
echo 说明:
echo   dev  - 使用开发环境配置生成 docker-compose.yml
echo   prod - 使用生产环境配置生成 docker-compose.yml
exit /b 1

:end
endlocal
