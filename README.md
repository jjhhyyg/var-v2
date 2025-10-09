# VAR 熔池视频分析系统

> 基于深度学习的焊接熔池视频智能分析系统

## 📋 项目概述

本项目是一个完整的视频分析平台，用于检测和分析 VAR（真空自耗电弧重熔）熔池视频中的异常事件，包括电极粘连、辉光现象等。

### 技术栈

- **前端**: Nuxt 4 + Vue 3 + TypeScript
- **后端**: Spring Boot 3.5 + PostgreSQL + Redis
- **AI模块**: Flask + PyTorch + YOLO11 + BoT-SORT
- **基础设施**: Docker + RabbitMQ

---

## 🏗️ 项目结构

```text
codes/
├── backend/              # Spring Boot 后端服务（Git Submodule）
├── frontend/             # Nuxt 前端应用（Git Submodule）
├── ai-processor/         # AI 视频分析模块（Git Submodule）
├── storage/              # 存储目录（运行时生成）
│   ├── videos/           # 原始视频
│   ├── result_videos/    # 分析结果视频
│   ├── preprocessed_videos/  # 预处理视频
│   └── temp/             # 临时文件
├── .env.example          # 环境变量模板
├── docker-compose.dev.yml  # 开发环境基础设施配置
└── deploy.sh             # 部署脚本
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
git clone --recurse-submodules <repository-url>

# 或者先克隆主仓库，再初始化子模块
git clone <repository-url>
cd codes
git submodule update --init --recursive
```

### 2. 环境准备

#### 复制环境变量配置文件

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入必要的配置信息。

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

主要环境变量说明（详见 `.env.example`）：

### 数据库配置

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=var_analysis
DB_USER=var_user
DB_PASSWORD=your_password
```

### Redis 配置

```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
```

### RabbitMQ 配置

```env
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=var_user
RABBITMQ_PASSWORD=your_rabbitmq_password
RABBITMQ_VIDEO_ANALYSIS_QUEUE=video_analysis_queue
```

### 存储路径配置

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

**最后更新**: 2025-10-08
