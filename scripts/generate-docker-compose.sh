#!/bin/bash
# 生成独立的 docker-compose.yml 文件（shell 脚本版本）
# 使用方式: ./scripts/generate-docker-compose.sh [dev|prod]
#
# 此脚本会调用 Python 版本的脚本来完成实际工作
# 如果你的系统没有安装 Python 3，请使用 generate-docker-compose.py

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 切换到项目根目录
cd "$PROJECT_ROOT"

# 检查参数
if [ "$#" -ne 1 ] || ([ "$1" != "dev" ] && [ "$1" != "prod" ]); then
    echo "使用方式: ./scripts/generate-docker-compose.sh [dev|prod]"
    echo ""
    echo "说明:"
    echo "  dev  - 使用开发环境配置生成 docker-compose.yml"
    echo "  prod - 使用生产环境配置生成 docker-compose.yml"
    exit 1
fi

# 检查 Python 是否可用
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到 python3"
    echo "请安装 Python 3 或直接使用 generate-docker-compose.py"
    exit 1
fi

# 调用 Python 脚本
python3 "$SCRIPT_DIR/generate-docker-compose.py" "$1"
