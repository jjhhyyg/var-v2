@echo off
REM 使用方式: scripts\use-env.cmd dev 或 scripts\use-env.cmd prod

set ENV=%1

if "%ENV%"=="" (
    echo Usage: scripts\use-env.cmd [dev^|prod]
    exit /b 1
)

if not "%ENV%"=="dev" if not "%ENV%"=="prod" (
    echo Usage: scripts\use-env.cmd [dev^|prod]
    exit /b 1
)

REM 映射环境全名
if "%ENV%"=="dev" (
    set ENV_FULL=development
) else (
    set ENV_FULL=production
)

echo Switching to %ENV_FULL% environment...

REM 1. 删除现有的环境变量文件
echo Cleaning existing environment files...
if exist backend\.env del /Q backend\.env
if exist frontend\.env del /Q frontend\.env
if exist ai-processor\.env del /Q ai-processor\.env
if exist .env del /Q .env

REM 2. 复制各模块的配置文件
copy /Y env\backend\.env.%ENV_FULL% backend\.env >nul
copy /Y env\frontend\.env.%ENV_FULL% frontend\.env >nul
copy /Y env\ai-processor\.env.%ENV_FULL% ai-processor\.env >nul

REM 3. 将 shared 配置追加到各模块的 .env 文件
if exist env\shared\.env.%ENV_FULL% (
    echo. >> backend\.env
    echo # ===== Shared Configuration ===== >> backend\.env
    type env\shared\.env.%ENV_FULL% >> backend\.env
    
    echo. >> frontend\.env
    echo # ===== Shared Configuration ===== >> frontend\.env
    type env\shared\.env.%ENV_FULL% >> frontend\.env
    
    echo. >> ai-processor\.env
    echo # ===== Shared Configuration ===== >> ai-processor\.env
    type env\shared\.env.%ENV_FULL% >> ai-processor\.env
)

REM 4. (核心修改) 创建根 .env 文件
echo Creating root .env file for docker-compose...
if exist env\shared\.env.%ENV_FULL% (
    copy /Y env\shared\.env.%ENV_FULL% .env >nul
)

REM 在 Windows CMD 中无法直接获取与 Linux 兼容的 UID/GID。
REM Docker Desktop for Windows 会自动处理文件权限，通常不需要进行设置。
echo. >> .env
echo # ===== Docker Host User (Windows) ===== >> .env
echo # On Windows, UID/GID are not required as Docker Desktop handles permissions automatically. >> .env

echo.
echo Environment switched to %ENV_FULL%
echo.
echo Loaded configurations:
echo   - backend\.env
echo   - frontend\.env
echo   - ai-processor\.env
echo   - .env (包含了 shared config, 已为 Windows 跳过 UID/GID)