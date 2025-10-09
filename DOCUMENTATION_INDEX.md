# 📚 项目文档索引

本项目包含完整的文档体系，涵盖系统设计、配置管理、开发指南等内容。

---

## 🚀 快速开始

| 文档 | 说明 | 优先级 |
|------|------|--------|
| [README.md](./README.md) | **项目主文档** - 快速开始、技术栈、环境配置 | ⭐⭐⭐ 必读 |
| [GIT_SUBMODULE_GUIDE.md](./GIT_SUBMODULE_GUIDE.md) | **Git Submodule 使用指南** - 克隆、开发、协作流程 | ⭐⭐⭐ 必读 |
| [REPOSITORY_SETUP_COMPLETE.md](./REPOSITORY_SETUP_COMPLETE.md) | **仓库设置完成总结** - 当前状态和下一步操作 | ⭐⭐ 推荐 |

---

## 📋 系统设计文档

| 文档 | 说明 |
|------|------|
| [系统设计文档.md](./系统设计文档.md) | 系统架构、模块设计、技术选型 |
| [接口设计文档.md](./接口设计文档.md) | REST API 接口详细说明 |

---

## ⚙️ 配置管理文档

| 文档 | 说明 | 用途 |
|------|------|------|
| [.env.example](./.env.example) | **环境变量模板** | 配置所有环境变量 |
| [CODE_REVIEW_CONFIG.md](./CODE_REVIEW_CONFIG.md) | 配置审查报告 | 了解配置问题和优化建议 |
| [CONFIG_MIGRATION.md](./CONFIG_MIGRATION.md) | 配置迁移指南 | 了解配置整合过程 |
| [CONFIG_UPDATE.md](./CONFIG_UPDATE.md) | 配置更新说明 | 快速查看配置变更 |
| [STORAGE_PATH_GUIDE.md](./STORAGE_PATH_GUIDE.md) | 存储路径配置说明 | 了解文件存储结构 |

---

## 🔄 消息队列文档

| 文档 | 说明 |
|------|------|
| [RABBITMQ_QUEUES.md](./RABBITMQ_QUEUES.md) | RabbitMQ 队列架构说明 |
| [RABBITMQ_CLEANUP.md](./RABBITMQ_CLEANUP.md) | 队列清理总结（删除未使用队列） |

---

## 🛠️ 部署和运维

| 文件 | 说明 |
|------|------|
| [docker-compose.dev.yml](./docker-compose.dev.yml) | 开发环境基础设施配置（PostgreSQL, Redis, RabbitMQ） |
| [deploy.sh](./deploy.sh) | 部署脚本 |

---

## 📖 其他文档

| 文档 | 说明 |
|------|------|
| [CLAUDE.md](./CLAUDE.md) | AI 助手使用说明 |

---

## 📂 子模块文档

每个子模块都有自己的 README：

| 子模块 | 文档位置 | 说明 |
|--------|---------|------|
| Backend | [backend/HELP.md](./backend/HELP.md) | Spring Boot 后端开发指南 |
| Frontend | [frontend/README.md](./frontend/README.md) | Nuxt 前端开发指南 |
| AI Processor | [ai-processor/README.md](./ai-processor/README.md) | AI 模块使用说明 |

---

## 🗂️ 文档分类

### 按用户角色

#### 新成员入门

1. ✅ README.md - 了解项目概况
2. ✅ GIT_SUBMODULE_GUIDE.md - 学习如何克隆和开发
3. ✅ .env.example - 配置开发环境
4. ✅ 系统设计文档.md - 理解系统架构

#### 后端开发者

- ✅ backend/HELP.md - Spring Boot 开发
- ✅ 接口设计文档.md - API 接口规范
- ✅ RABBITMQ_QUEUES.md - 消息队列使用

#### 前端开发者

- ✅ frontend/README.md - Nuxt 开发
- ✅ 接口设计文档.md - API 对接

#### AI 模块开发者

- ✅ ai-processor/README.md - AI 模块说明
- ✅ STORAGE_PATH_GUIDE.md - 存储路径配置

#### 运维人员

- ✅ docker-compose.dev.yml - 基础设施配置
- ✅ deploy.sh - 部署流程
- ✅ CONFIG_UPDATE.md - 配置变更记录

### 按主题分类

#### Git 相关

- 📘 GIT_SUBMODULE_GUIDE.md
- 📘 REPOSITORY_SETUP_COMPLETE.md

#### 配置相关

- ⚙️ .env.example
- ⚙️ CODE_REVIEW_CONFIG.md
- ⚙️ CONFIG_MIGRATION.md
- ⚙️ CONFIG_UPDATE.md
- ⚙️ STORAGE_PATH_GUIDE.md

#### 架构相关

- 🏗️ 系统设计文档.md
- 🏗️ 接口设计文档.md
- 🏗️ RABBITMQ_QUEUES.md

---

## 📝 文档更新记录

| 日期 | 更新内容 |
|------|---------|
| 2025-10-08 | 初始化主仓库，创建 Git Submodule 架构 |
| 2025-10-08 | 添加 Git Submodule 使用指南 |
| 2025-10-08 | 创建配置优化和清理相关文档 |
| 2025-10-08 | 完成仓库设置总结 |

---

## 🔍 快速查找

### 我想要

- **开始开发** → [README.md](./README.md) + [GIT_SUBMODULE_GUIDE.md](./GIT_SUBMODULE_GUIDE.md)
- **了解 API** → [接口设计文档.md](./接口设计文档.md)
- **配置环境** → [.env.example](./.env.example)
- **理解架构** → [系统设计文档.md](./系统设计文档.md)
- **消息队列** → [RABBITMQ_QUEUES.md](./RABBITMQ_QUEUES.md)
- **存储路径** → [STORAGE_PATH_GUIDE.md](./STORAGE_PATH_GUIDE.md)
- **部署上线** → [deploy.sh](./deploy.sh) + [docker-compose.dev.yml](./docker-compose.dev.yml)

---

## 📌 重要提示

### 文档优先级

**必读文档** ⭐⭐⭐:

- README.md
- GIT_SUBMODULE_GUIDE.md
- .env.example

**推荐阅读** ⭐⭐:

- 系统设计文档.md
- 接口设计文档.md
- REPOSITORY_SETUP_COMPLETE.md

**按需查阅** ⭐:

- 其他配置和专题文档

### 文档维护

- 所有文档使用 Markdown 格式
- 保持文档与代码同步更新
- 重要变更记录在相应文档中

---

**最后更新**: 2025-10-08
