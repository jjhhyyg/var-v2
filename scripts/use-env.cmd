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

REM 映射环境名称
if "%ENV%"=="dev" (
    set ENV_FULL=development
) else (
    set ENV_FULL=production
)

echo Switching to %ENV_FULL% environment...

REM 复制配置文件到各模块
copy /Y env\backend\.env.%ENV_FULL% backend\.env >nul
copy /Y env\frontend\.env.%ENV_FULL% frontend\.env >nul
copy /Y env\ai-processor\.env.%ENV_FULL% ai-processor\.env >nul

REM 将 shared 配置追加到各模块的 .env 文件
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

    echo. >> .env
    echo # ===== Shared Configuration ===== >> .env
    type env\shared\.env.%ENV_FULL% >> .env
)

echo.
echo √ Environment switched to %ENV_FULL%
echo.
echo Loaded configurations:
echo   - backend\.env (with shared config)
echo   - frontend\.env (with shared config)
echo   - ai-processor\.env (with shared config)
echo   - .env (with shared config)
