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

# 复制配置文件到各模块
cp env/backend/.env.$ENV_FULL backend/.env
cp env/frontend/.env.$ENV_FULL frontend/.env
cp env/ai-processor/.env.$ENV_FULL ai-processor/.env
cp env/shared/.env.$ENV_FULL .env.shared

echo "✓ Environment switched to $ENV_FULL"
echo ""
echo "Loaded configurations:"
echo "  - backend/.env"
echo "  - frontend/.env"
echo "  - ai-processor/.env"
echo "  - .env.shared"
