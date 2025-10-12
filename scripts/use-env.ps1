# 使用方式: .\scripts\use-env.ps1 dev 或 .\scripts\use-env.ps1 prod

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'prod')]
    [string]$Env
)

# 映射环境名称
if ($Env -eq 'dev') {
    $EnvFull = 'development'
} else {
    $EnvFull = 'production'
}

Write-Host "Switching to $EnvFull environment..." -ForegroundColor Cyan

# 删除现有的环境变量文件
Write-Host "Cleaning existing environment files..." -ForegroundColor Yellow
Remove-Item "backend\.env" -Force -ErrorAction SilentlyContinue
Remove-Item "frontend\.env" -Force -ErrorAction SilentlyContinue
Remove-Item "ai-processor\.env" -Force -ErrorAction SilentlyContinue
Remove-Item ".env" -Force -ErrorAction SilentlyContinue

# 复制配置文件到各模块
Copy-Item "env\backend\.env.$EnvFull" "backend\.env" -Force
Copy-Item "env\frontend\.env.$EnvFull" "frontend\.env" -Force
Copy-Item "env\ai-processor\.env.$EnvFull" "ai-processor\.env" -Force

# 将 shared 配置追加到各模块的 .env 文件
$sharedConfig = "env\shared\.env.$EnvFull"
if (Test-Path $sharedConfig) {
    $sharedContent = Get-Content $sharedConfig -Raw
    
    # 追加到 backend/.env
    Add-Content -Path "backend\.env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path "backend\.env" -Value $sharedContent
    
    # 追加到 frontend/.env
    Add-Content -Path "frontend\.env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path "frontend\.env" -Value $sharedContent
    
    # 追加到 ai-processor/.env
    Add-Content -Path "ai-processor\.env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path "ai-processor\.env" -Value $sharedContent

    # 追加到根目录 .env
    Add-Content -Path ".env" -Value "`n# ===== Shared Configuration ====="
    Add-Content -Path ".env" -Value $sharedContent
}

Write-Host ""
Write-Host "Environment switched to $EnvFull" -ForegroundColor Green
Write-Host ""
Write-Host "Loaded configurations:"
Write-Host "  - backend\.env (with shared config)"
Write-Host "  - frontend\.env (with shared config)"
Write-Host "  - ai-processor\.env (with shared config)"
Write-Host "  - .env (with shared config)"
