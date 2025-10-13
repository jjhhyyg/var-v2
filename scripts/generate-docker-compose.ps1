# 生成独立的 docker-compose.yml 文件（PowerShell 脚本版本）
# 使用方式: .\scripts\generate-docker-compose.ps1 [dev|prod]
#
# 此脚本会调用 Python 版本的脚本来完成实际工作

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "prod")]
    [string]$Environment
)

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# 切换到项目根目录
Set-Location $ProjectRoot

# 检查 Python 是否可用
$pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
}

if (-not $pythonCmd) {
    Write-Error "错误: 未找到 Python"
    Write-Host "请安装 Python 3 或直接使用 generate-docker-compose.py"
    exit 1
}

# 调用 Python 脚本
& $pythonCmd.Source "$ScriptDir\generate-docker-compose.py" $Environment
