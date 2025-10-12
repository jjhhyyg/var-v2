#!/bin/bash
# 使用方式: ./scripts/use-env.sh dev 或 ./scripts/use-env.sh prod

ENV=$1

if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: ./scripts/use-env.sh [dev|prod]"
    exit 1
fi

# 映射环境名称
if [ "$ENV" == "dev" ]; then
    ENV_FULL="development"
else
    ENV_FULL="production"
fi

echo "Switching to $ENV_FULL environment..."

# 删除现有的环境变量文件
echo "Cleaning existing environment files..."
rm -f backend/.env
rm -f frontend/.env
rm -f ai-processor/.env
rm -f .env

# 复制配置文件到各模块
cp env/backend/.env.$ENV_FULL backend/.env
cp env/frontend/.env.$ENV_FULL frontend/.env
cp env/ai-processor/.env.$ENV_FULL ai-processor/.env

# 将 shared 配置追加到各模块的 .env 文件
if [ -f env/shared/.env.$ENV_FULL ]; then
    echo "" >> backend/.env
    echo "# ===== Shared Configuration =====" >> backend/.env
    cat env/shared/.env.$ENV_FULL >> backend/.env
    
    echo "" >> frontend/.env
    echo "# ===== Shared Configuration =====" >> frontend/.env
    cat env/shared/.env.$ENV_FULL >> frontend/.env
    
    echo "" >> ai-processor/.env
    echo "# ===== Shared Configuration =====" >> ai-processor/.env
    cat env/shared/.env.$ENV_FULL >> ai-processor/.env

    echo "" >> .env
    echo "# ===== Shared Configuration =====" >> .env
    cat env/shared/.env.$ENV_FULL >> .env
fi

echo "Environment switched to $ENV_FULL"
echo ""
echo "Loaded configurations:"
echo "  - backend/.env (with shared config)"
echo "  - frontend/.env (with shared config)"
echo "  - ai-processor/.env (with shared config)"
echo "  - .env (with shared config)"