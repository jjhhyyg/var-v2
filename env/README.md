# 环境配置文件说明

## 配置结构

本项目采用分层环境配置管理,将配置分为**共享配置**和**模块独有配置**:

```text
env/
├── shared/              # 共享配置(Backend 和 AI-Processor 共用)
│   ├── .env.example
│   ├── .env.development
│   └── .env.production
├── backend/             # Backend 独有配置
│   ├── .env.example
│   ├── .env.development
│   └── .env.production
├── frontend/            # Frontend 独有配置
│   ├── .env.example
│   ├── .env.development
│   └── .env.production
└── ai-processor/        # AI-Processor 独有配置
    ├── .env.example
    ├── .env.development
    └── .env.production
```

## 配置分类

### 共享配置 (env/shared/)

多个模块共同使用的基础服务配置:

- **数据库配置** (`DB_*`) - Backend 和 AI-Processor
- **Redis配置** (`REDIS_*`) - Backend 和 AI-Processor
- **RabbitMQ配置** (`RABBITMQ_*`) - Backend 和 AI-Processor
- **文件存储配置** (`STORAGE_*`) - Backend 和 AI-Processor
- **任务处理参数** (`DEFAULT_*`) - Backend 和 AI-Processor

### Backend 独有配置 (env/backend/)

- `SERVER_PORT` - 服务器端口
- `BACKEND_BASE_URL` - 后端自己的URL(供AI回调)
- `CORS_ORIGINS` - CORS允许的源
- `SNOWFLAKE_*` - 雪花算法配置
- `LOG_LEVEL`, `WEB_LOG_LEVEL`, `SQL_LOG_LEVEL` 等 - 日志配置
- `SHOW_SQL` - 是否显示SQL

### Frontend 独有配置 (env/frontend/)

- `NUXT_PUBLIC_API_BASE` - 后端API基础URL

### AI-Processor 独有配置 (env/ai-processor/)

- `AI_PROCESSOR_PORT`, `AI_PROCESSOR_HOST`, `AI_PROCESSOR_DEBUG` - 服务器配置
- `BACKEND_BASE_URL` - 后端服务URL(用于回调)
- `YOLO_MODEL_*` - YOLO模型配置
- `TRACKER_CONFIG` - 追踪器配置文件
- `TRACK_*`, `MATCH_THRESH`, `GMC_METHOD` 等 - 追踪器参数
- `WITH_REID`, `PROXIMITY_THRESH`, `APPEARANCE_THRESH` - BotSort特有参数
- `PROGRESS_UPDATE_INTERVAL` - 进度更新频率

## 使用方法

### 1. 快速切换环境

```bash
# 切换到开发环境
./scripts/use-env.sh dev

# 切换到生产环境
./scripts/use-env.sh prod
```

### 2. 脚本执行效果

脚本会自动将配置文件复制到各模块:

- `env/shared/.env.{environment}` → `.env.shared`
- `env/backend/.env.{environment}` → `backend/.env`
- `env/frontend/.env.{environment}` → `frontend/.env`
- `env/ai-processor/.env.{environment}` → `ai-processor/.env`

### 3. 首次配置

1. 查看示例配置文件 `.env.example`
2. 根据实际环境修改 `.env.development` 或 `.env.production`
3. 运行切换脚本应用配置

## 版本控制

### ✅ 应该提交到 Git

- `env/**/.env.example` - 配置模板
- `env/**/.env.development` - 开发环境配置(不含敏感信息)
- `scripts/use-env.sh` - 环境切换脚本

### ❌ 不应提交到 Git

- `env/**/.env.production` - 生产环境配置(含敏感信息)
- `backend/.env` - 实际使用的配置
- `frontend/.env` - 实际使用的配置
- `ai-processor/.env` - 实际使用的配置
- `.env.shared` - 共享配置

## 配置来源说明

此配置结构基于代码分析:

- Backend: `/backend/src/main/resources/application.yaml`
- AI-Processor: `/ai-processor/config.py`
- Frontend: `/frontend/nuxt.config.ts`

确保配置文件中的环境变量与代码中实际使用的变量名一致。
