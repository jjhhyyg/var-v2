# 使用方式: .\scripts\use-env.ps1 dev 或 .\scripts\use-env.ps1 prod

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'prod')]
    [string]$Env
)

# 映射环境全名
if ($Env -eq 'dev') {
    $EnvFull = 'development'
} else {
    $EnvFull = 'production'
}

Write-Host "Switching to $EnvFull environment..." -ForegroundColor Cyan

# 1. 删除现有的环境变量文件
Write-Host "Cleaning existing environment files..." -ForegroundColor Yellow
Remove-Item "backend\.env" -Force -ErrorAction SilentlyContinue
Remove-Item "frontend\.env" -Force -ErrorAction SilentlyContinue
Remove-Item "ai-processor\.env" -Force -ErrorAction SilentlyContinue
Remove-Item ".env" -Force -ErrorAction SilentlyContinue

# 2. 复制各模块的配置文件
Copy-Item "env\backend\.env.$EnvFull" "backend\.env" -Force
Copy-Item "env\frontend\.env.$EnvFull" "frontend\.env" -Force
Copy-Item "env\ai-processor\.env.$EnvFull" "ai-processor\.env" -Force

# 3. 将 shared 配置追加到各模块的 .env 文件
$sharedConfigPath = "env\shared\.env.$EnvFull"
if (Test-Path $sharedConfigPath) {
    $sharedContent = Get-Content $sharedConfigPath -Raw
    
    Add-Content -Path "backend\.env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path "backend\.env" -Value $sharedContent
    
    Add-Content -Path "frontend\.env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path "frontend\.env" -Value $sharedContent
    
    Add-Content -Path "ai-processor\.env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path "ai-processor\.env" -Value $sharedContent
}

# 4. (核心修改) 创建根 .env 文件，并根据操作系统注入 UID/GID
Write-Host "Creating root .env file for docker-compose..."
$envMessage = ".env (仅包含 shared config)" # 默认提示信息

if (Test-Path $sharedConfigPath) {
    Copy-Item $sharedConfigPath ".env" -Force
}

# 检查操作系统，只有在 Linux 或 macOS 上才添加 UID/GID
if ($IsLinux -or $IsMacOS) {
    Write-Host "Linux/macOS detected, appending UID/GID..." -ForegroundColor Blue
    $uid = (id -u).Trim()
    $gid = (id -g).Trim()
    Add-Content -Path ".env" -Value "`n# ===== Docker Host User (auto-generated) ====="
    Add-Content -Path ".env" -Value "UID=$uid"
    Add-Content -Path ".env" -Value "GID=$gid"
    $envMessage = ".env (包含 shared config 和自动生成的 UID/GID)"
} else {
    Write-Host "Windows detected, skipping UID/GID generation." -ForegroundColor Blue
    Add-Content -Path ".env" -Value "`n# ===== Docker Host User (Windows) ====="
    Add-Content -Path ".env" -Value "# On Windows, UID/GID are not required as Docker Desktop handles permissions automatically."
    $envMessage = ".env (包含 shared config, 已为 Windows 跳过 UID/GID)"
}

Write-Host ""
Write-Host "Environment switched to $EnvFull" -ForegroundColor Green
Write-Host ""
Write-Host "Loaded configurations:"
Write-Host "  - backend\.env"
Write-Host "  - frontend\.env"
Write-Host "  - ai-processor\.env"
Write-Host "  - $envMessage"