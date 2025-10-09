# 配置修复说明（快速参考）

## 🎯 主要变更

### 1. 环境变量统一

- **所有配置都在根目录 `.env` 文件中**
- 删除了 `ai-processor/.env` 的重复配置
- 优化了配置命名和结构

### 2. 关键配置变更

| 配置项 | 旧值 | 新值 |
|-------|------|------|
| 后端回调URL | `AI_CALLBACK_URL=http://localhost:8080/api/tasks` | `BACKEND_BASE_URL=http://localhost:8080` |
| 存储路径 | `STORAGE_BASE_PATH=./storage` | `STORAGE_BASE_PATH=storage` |
| AI日志 | 硬编码 `INFO` | `AI_LOG_LEVEL=INFO` |
| 前端API | 硬编码 | `NUXT_PUBLIC_API_BASE=http://localhost:8080` |

## 🚀 快速迁移（5分钟）

```bash
# 1. 备份旧配置
cd /Users/erikssonhou/Projects/VAR熔池挑战/codes
cp .env .env.backup 2>/dev/null || true

# 2. 使用新配置模板
cp .env.example .env

# 3. 编辑配置文件，填入实际值
# 重点检查以下配置：
# - DB_PASSWORD
# - REDIS_PASSWORD  
# - RABBITMQ_PASSWORD
# - BACKEND_BASE_URL (原 AI_CALLBACK_URL)

# 4. 删除AI模块的独立配置（可选）
rm ai-processor/.env.example
# rm ai-processor/.env  # 如果存在
```

## ✅ 验证

```bash
# Backend
cd backend && ./mvnw spring-boot:run

# AI模块
cd ai-processor && python app.py

# 前端
cd frontend && pnpm dev
```

## 📋 完整文档

- **详细迁移指南**: [CONFIG_MIGRATION.md](./CONFIG_MIGRATION.md)
- **配置审查报告**: [CODE_REVIEW_CONFIG.md](./CODE_REVIEW_CONFIG.md)
