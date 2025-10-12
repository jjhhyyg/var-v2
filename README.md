# VAR 熔池视频分析系统

> 基于深度学习的焊接熔池视频智能分析系统

## 📋 项目概述

本项目是一个完整的视频分析平台，用于检测和分析 VAR（真空自耗电弧重熔）熔池视频中的异常事件。

### 技术架构

- **前端**: Nuxt 4 + Vue 3 + TypeScript
- **后端**: Spring Boot 3 + PostgreSQL + Redis
- **AI 引擎**: Flask + PyTorch + YOLO11
- **消息队列**: RabbitMQ

### 核心功能

- 视频上传与管理（支持最大 2GB）
- 基于 RabbitMQ 的异步任务处理
- YOLO11 目标检测 + BoT-SORT 跟踪
- 自动检测电极粘连、辉光等异常事件
- 生成标注后的结果视频
- 实时进度追踪

---

## 🚀 快速开始

### 1. 克隆仓库

```bash
# 克隆主仓库并初始化所有子模块
git clone --recurse-submodules https://github.com/jjhhyyg/var-v2.git
cd var-v2

# 或者先克隆主仓库，再初始化子模块
git clone https://github.com/jjhhyyg/var-v2.git
cd var-v2
git submodule update --init --recursive
```

### 2. 开发环境快速启动

#### 步骤 1: 配置环境变量

```bash
# Linux/macOS
./scripts/use-env.sh dev

# Windows PowerShell
.\scripts\use-env.ps1 dev

# Windows CMD
scripts\use-env.cmd dev
```

> 💡 首次使用请先根据 `env/*/.env.example` 修改 `env/*/.env.development` 中的配置

#### 步骤 2: 启动基础设施（PostgreSQL、Redis、RabbitMQ）

```bash
docker-compose -f docker-compose.dev.yml up -d
```

#### 步骤 3: 启动各服务

**后端服务**

```bash
cd backend
./mvnw spring-boot:run
# 服务运行在 http://localhost:8080
```

**前端应用**

```bash
cd frontend
pnpm install
pnpm dev
# 服务运行在 http://localhost:3000
```

**AI 处理模块**

```bash
cd ai-processor
pip install -r requirements.txt
python app.py
# 服务运行在 http://localhost:5000
```

### 3. 生产环境部署（Docker）

#### 步骤 1: 配置生产环境变量

```bash
# Linux/macOS
./scripts/use-env.sh prod

# Windows PowerShell
.\scripts\use-env.ps1 prod

# Windows CMD
scripts\use-env.cmd prod
```

> ⚠️ 生产环境请务必修改 `env/*/.env.production` 中的敏感信息（数据库密码、JWT 密钥等）

#### 步骤 2: 准备 AI 模型权重文件

确保 YOLO 模型权重文件已放置在正确位置：

```bash
# 确保权重文件存在
ls ai-processor/weights/best.pt
```

#### 步骤 3: 使用 Docker Compose 一键部署

```bash
# 构建并启动所有服务（包括 PostgreSQL、Redis、RabbitMQ、Backend、Frontend、AI-Processor）
docker-compose -f docker-compose.prod.yml up -d --build

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看服务日志
docker-compose -f docker-compose.prod.yml logs -f

# 停止所有服务
docker-compose -f docker-compose.prod.yml down
```

部署完成后，服务访问地址：

- 前端: <http://localhost:8848>
- 后端 API: <http://localhost:8080>
- AI 处理模块: <http://localhost:5000>
- RabbitMQ 管理界面: <http://localhost:15672>

> 💡 **GPU 支持**: 如果服务器有 NVIDIA GPU，可在 `docker-compose.prod.yml` 中取消注释 AI 模块的 GPU 配置部分

---

## 📚 更多文档

- **详细配置说明**: 查看 [`env/README.md`](env/README.md)
- **Git Submodule 管理**: 查看各子项目的 README
  - [backend/](backend/)
  - [frontend/](frontend/)
  - [ai-processor/](ai-processor/)

---

## 📄 许可证

[待定]

---

**最后更新**: 2025-10-12
