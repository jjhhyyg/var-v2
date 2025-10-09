# VAR 熔池视频分析系统

> 基于深度学习的焊接熔池视频智能分析系统

## 📋 项目概述

本项目是一个完整的视频分析平台，用于检测和分析 VAR（真空自耗电弧重熔）熔池视频中的异常事件，包括电极粘连3. 使用脚本切换环境（会自动复制配置到各模块）：

   ```bash
   ./scripts/use-env.sh dev
   ```

> 💡 **提示**:。

### 技术栈

- **前端**: Nuxt 4 + Vue 3 + TypeScript
- **后端**: Spring Boo**RabbitMQ 配置：**

```env
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=var_user
RABBITMQ_PASSWORD=var_password
RABBITMQ_VHOST=/
```

**文件存储配置：**

```env
STORAGE_BASE_PATH=./storage
STORAGE_VIDEOS_SUBDIR=videos
STORAGE_RESULT_VIDEOS_SUBDIR=result_videos
STORAGE_PREPROCESSED_VIDEOS_SUBDIR=preprocessed_videos
STORAGE_TEMP_SUBDIR=temp
```

#### Backend 独有配置 (env/backend/)

```env
SERVER_PORT=8080
BACKEND_BASE_URL=http://localhost:8080
CORS_ORIGINS=http://localhost:3000
LOG_LEVEL=DEBUG
```

#### Frontend 独有配置 (env/frontend/)

```env
NUXT_PUBLIC_API_BASE=http://localhost:8080
```

#### AI-Processor 独有配置 (env/ai-processor/)

```env
AI_PROCESSOR_PORT=5000
YOLO_MODEL_PATH=weights/best.pt
YOLO_MODEL_VERSION=yolo11m
YOLO_DEVICE=mps
TRACKER_CONFIG=botsort.yaml
BACKEND_BASE_URL=http://localhost:8080
```

> 📝 **详细配置说明**: 查看 [`env/README.md`](env/README.md) 了解完整的配置文档。

### 配置文件管理建议

1. **版本控制**：
   - ✅ 提交 `.env.example` 文件（作为模板）
   - ✅ 提交 `.env.development` 文件（开发环境默认配置）
   - ❌ 不要提交 `.env.production` 文件（包含敏感信息）
   - ❌ 不要提交各模块的 `.env` 文件（运行时生成）

2. **安全性**：
   - 生产环境的敏感信息（密码、密钥）应使用环境变量或密钥管理服务
   - 定期更新 JWT 密钥和数据库密码

3. **环境一致性**：
   - 使用 `use-env.sh` 脚本确保所有模块使用相同的环境配置
   - 在团队中统一开发环境配置,减少"在我机器上能跑"的问题

---

## 🏗️ 项目结构

```text
codes/
├── backend/              # Spring Boot 后端服务（Git Submodule）
├── frontend/             # Nuxt 前端应用（Git Submodule）
├── ai-processor/         # AI 视频分析模块（Git Submodule）
├── env/                  # 环境配置统一管理目录
│   ├── shared/           # 共享配置（数据库、Redis、RabbitMQ）
│   │   ├── .env.example
│   │   ├── .env.development
│   │   └── .env.production
│   ├── backend/          # 后端配置
│   │   ├── .env.example
│   │   ├── .env.development
│   │   └── .env.production
│   ├── frontend/         # 前端配置
│   │   ├── .env.example
│   │   ├── .env.development
│   │   └── .env.production
│   └── ai-processor/     # AI 模块配置
│       ├── .env.example
│       ├── .env.development
│       └── .env.production
├── scripts/              # 工具脚本
│   └── use-env.sh        # 环境切换脚本
├── storage/              # 存储目录（运行时生成）
│   ├── videos/           # 原始视频
│   ├── result_videos/    # 分析结果视频
│   ├── preprocessed_videos/  # 预处理视频
│   └── temp/             # 临时文件
└── docker-compose.dev.yml  # 开发环境基础设施配置
```

### Git Submodules

本项目使用 **Git Submodule** 管理三个独立的子项目：

| 子模块 | 说明 | 技术栈 |
|--------|------|--------|
| `backend/` | 后端 API 服务 | Spring Boot 3 + PostgreSQL + Redis |
| `frontend/` | 前端 Web 应用 | Nuxt 4 + Vue 3 + TypeScript |
| `ai-processor/` | AI 视频分析引擎 | Flask + PyTorch + YOLO11 |

---

## 🚀 快速开始

### 1. 克隆仓库（包含子模块）

```bash
# 克隆主仓库并初始化所有子模块
git clone --recurse-submodules https://github.com/jjhhyyg/var-v2.git

# 或者先克隆主仓库，再初始化子模块
git clone https://github.com/jjhhyyg/var-v2.git
cd codes
git submodule update --init --recursive
```

### 2. 环境准备

#### 配置环境变量

本项目采用统一的环境配置管理，所有配置文件集中存放在 `env/` 目录下。

**快速切换环境：**

```bash
# 切换到开发环境
./scripts/use-env.sh dev

# 切换到生产环境
./scripts/use-env.sh prod
```

**首次使用时的配置步骤：**

1. 查看配置模板文件：
   - `env/shared/.env.example` - 共享配置（数据库、Redis、RabbitMQ）
   - `env/backend/.env.example` - 后端配置
   - `env/frontend/.env.example` - 前端配置
   - `env/ai-processor/.env.example` - AI 模块配置

2. 根据你的环境修改对应的配置文件：
   - 开发环境：修改 `env/*/.env.development`
   - 生产环境：修改 `env/*/.env.production`

3. 使用脚本切换环境（会自动复制配置到各模块）：

   ```bash
   ./scripts/use-env.sh dev
   ```

> 💡 **提示**：
>
> - `.env.example` 文件仅作为模板参考
> - `.env.development` 和 `.env.production` 包含实际配置
> - 使用 `use-env.sh` 脚本会自动将配置复制到各模块的 `.env` 文件

#### 启动基础设施服务

使用 Docker Compose 启动 PostgreSQL、Redis、RabbitMQ：

```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 3. 启动各模块

#### 后端服务 (Backend)

```bash
cd backend
./mvnw spring-boot:run
```

后端服务默认运行在 `http://localhost:8080`

#### 前端应用 (Frontend)

```bash
cd frontend
pnpm install
pnpm dev
```

前端应用默认运行在 `http://localhost:3000`

#### AI 处理模块 (AI Processor)

```bash
cd ai-processor
pip install -r requirements.txt
python app.py
```

AI 模块默认运行在 `http://localhost:5000`

---

## ⚙️ 环境变量配置

本项目采用集中式环境配置管理，所有配置文件统一存放在 `env/` 目录下。

### 环境配置结构

```text
env/
├── shared/              # 共享配置（数据库、Redis、RabbitMQ）
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

### 快速切换环境

使用 `use-env.sh` 脚本一键切换开发或生产环境：

```bash
# 切换到开发环境
./scripts/use-env.sh dev

# 切换到生产环境
./scripts/use-env.sh prod
```

脚本会自动将 `env/` 目录下的配置文件复制到各个模块：

- `env/backend/.env.{environment}` → `backend/.env`
- `env/frontend/.env.{environment}` → `frontend/.env`
- `env/ai-processor/.env.{environment}` → `ai-processor/.env`
- `env/shared/.env.{environment}` → `.env.shared`

### 主要配置说明

#### 共享配置 (env/shared/)

Backend 和 AI-Processor 共同使用的基础服务配置。

**数据库配置：**

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=var_analysis
DB_USER=var_user
DB_PASSWORD=var_password
```

**Redis 配置：**

```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

**RabbitMQ 配置：**

```env
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
```

#### 后端配置 (env/backend/)

Spring Boot 应用配置，包括服务器端口、数据源、JWT 等。

```env
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=dev
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/var_database
JWT_SECRET=your_jwt_secret_key
```

#### 前端配置 (env/frontend/)

Nuxt 应用配置，包括 API 地址、WebSocket 等。

```env
NUXT_PUBLIC_API_BASE_URL=http://localhost:8080/api
NUXT_PUBLIC_WS_URL=ws://localhost:8080/ws
NUXT_PUBLIC_ENV=development
```

#### AI 模块配置 (env/ai-processor/)

AI 处理模块配置，包括模型路径、视频存储路径等。

```env
STORAGE_BASE_PATH=storage
STORAGE_VIDEOS_SUBDIR=videos
STORAGE_RESULT_VIDEOS_SUBDIR=result_videos
STORAGE_PREPROCESSED_VIDEOS_SUBDIR=preprocessed_videos
```

### 后端 URL 配置

```env
# 后端服务地址（供 AI 模块回调使用）
BACKEND_BASE_URL=http://localhost:8080

# 前端 API 基础地址
NUXT_PUBLIC_API_BASE=http://localhost:8080
```

---

## 📦 Git Submodule 管理

### 更新所有子模块到最新版本

```bash
git submodule update --remote --merge
```

### 拉取主仓库和所有子模块的更新

```bash
git pull --recurse-submodules
```

### 进入子模块进行开发

```bash
cd backend
# 现在可以在 backend 目录中进行正常的 git 操作
git checkout -b feature/new-feature
# ... 开发和提交
git push origin feature/new-feature
```

### 更新主仓库中子模块的引用

当子模块有新提交时，主仓库需要更新引用：

```bash
# 在主仓库根目录
git add backend  # 或 frontend / ai-processor
git commit -m "chore: 更新 backend 子模块到最新版本"
git push
```

---

## 🔄 系统架构

### 消息流程

```text
用户上传视频
    ↓
Frontend → Backend
    ↓
Backend 保存视频 → PostgreSQL
    ↓
Backend 发送任务 → RabbitMQ (video_analysis_queue)
    ↓
AI Processor 消费任务
    ↓
AI Processor 分析视频
    ↓
AI Processor HTTP 回调 → Backend
    ↓
Backend 更新任务状态 → PostgreSQL
    ↓
Frontend 轮询获取结果
```

### 核心功能

- ✅ **视频上传与管理** - 支持大文件上传（最大 2GB）
- ✅ **异步任务处理** - 基于 RabbitMQ 的任务队列
- ✅ **AI 视频分析** - YOLO11 目标检测 + BoT-SORT 跟踪
- ✅ **事件检测** - 自动检测电极粘连、辉光等异常事件
- ✅ **结果可视化** - 生成标注后的结果视频
- ✅ **进度追踪** - 实时查看分析进度

---

## 🛠️ 开发指南

### 代码提交规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```text
feat: 新功能
fix: 修复 Bug
refactor: 重构代码
docs: 文档更新
style: 代码格式调整
test: 测试相关
chore: 构建/工具链更新
```

### 子模块开发流程

1. 进入子模块目录
2. 创建功能分支 `git checkout -b feature/xxx`
3. 开发并提交到子模块仓库
4. 回到主仓库，更新子模块引用
5. 提交主仓库的更新

---

## 🐛 问题排查

### 常见问题

#### 1. 子模块目录为空

```bash
git submodule update --init --recursive
```

#### 2. 数据库连接失败

检查 Docker 容器是否运行：

```bash
docker-compose -f docker-compose.dev.yml ps
```

#### 3. AI 模块分析失败

检查 RabbitMQ 连接和权重文件：

```bash
# 检查权重文件
ls -lh ai-processor/weights/best.pt

# 查看 AI 模块日志
cd ai-processor
tail -f logs/app.log
```

---

## 📄 许可证

[待定]

---

## 👥 贡献者

- [@erikssonhou](https://github.com/erikssonhou)

---

**最后更新**: 2025-10-09
