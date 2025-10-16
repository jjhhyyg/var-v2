#!/bin/bash
# 使用方式: ./scripts/use-env.sh dev 或 ./scripts/use-env.sh prod

# -- 脚本开始 --

# 检查输入参数
ENV=$1
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "Usage: ./scripts/use-env.sh [dev|prod]"
    exit 1
fi

# 映射环境全名
if [ "$ENV" == "dev" ]; then
    ENV_FULL="development"
else
    ENV_FULL="production"
fi

echo "Switching to $ENV_FULL environment..."

# 1. 删除现有的环境变量文件
echo "Cleaning existing environment files..."
rm -f backend/.env
rm -f frontend/.env
rm -f ai-processor/.env
rm -f .env # 根目录的 .env 也一并删除，重新生成

# 2. 复制各模块的配置文件
echo "Copying service-specific configurations..."
cp env/backend/.env.$ENV_FULL backend/.env
cp env/frontend/.env.$ENV_FULL frontend/.env
cp env/ai-processor/.env.$ENV_FULL ai-processor/.env

# 3. 将 shared 配置追加到各模块的 .env 文件
if [ -f env/shared/.env.$ENV_FULL ]; then
    echo "Appending shared configuration to services..."
    # 为 backend 追加
    echo "" >> backend/.env
    echo "# ===== Shared Configuration =====" >> backend/.env
    cat env/shared/.env.$ENV_FULL >> backend/.env
    
    # 为 frontend 追加
    echo "" >> frontend/.env
    echo "# ===== Shared Configuration =====" >> frontend/.env
    cat env/shared/.env.$ENV_FULL >> frontend/.env
    
    # 为 ai-processor 追加
    echo "" >> ai-processor/.env
    echo "# ===== Shared Configuration =====" >> ai-processor/.env
    cat env/shared/.env.$ENV_FULL >> ai-processor/.env
fi

# 4. (核心修改) 创建根 .env 文件，并注入 UID/GID
echo "Creating root .env file for docker-compose..."
# 首先，将 shared 配置复制到根 .env (如果存在)
if [ -f env/shared/.env.$ENV_FULL ]; then
    cat env/shared/.env.$ENV_FULL > .env
    echo "" >> .env # 在末尾添加一个换行符
fi

# 然后，在根 .env 文件中追加自动生成的 UID 和 GID
echo "# ===== Docker Host User (auto-generated) =====" >> .env
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env

# -- 脚本结束 --

echo ""
echo "Environment switched to $ENV_FULL"
echo ""
echo "Loaded configurations:"
echo "  - backend/.env"
echo "  - frontend/.env"
echo "  - ai-processor/.env"
echo "  - .env (包含了 shared config 和自动生成的 UID/GID)"