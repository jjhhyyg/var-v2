# 配置修复完成 - 迁移说明

## ✅ 已完成的修复

### 1. 统一环境变量文件 ✨

- ✅ 更新了根目录 `.env.example`，添加了所有AI模块特有配置
- ✅ 移除了配置重复
- ✅ 优化了配置结构和注释

**主要变更**:

- 添加了 `FRONTEND_PORT`, `AI_PROCESSOR_PORT` 等端口配置
- 将 `AI_CALLBACK_URL` 改为 `BACKEND_BASE_URL`（更明确）
- 添加了存储子目录配置：`STORAGE_VIDEOS_SUBDIR`, `STORAGE_RESULT_VIDEOS_SUBDIR` 等
- 添加了 `RABBITMQ_QUEUE` 配置
- 添加了 `AI_LOG_LEVEL` 日志级别配置
- 完善了追踪器配置参数

### 2. 修复AI模块配置加载路径 🔧

**文件**: `ai-processor/config.py`

**修改内容**:

```python
# 修改前
load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))

# 修改后
_root_dir = os.path.join(os.path.dirname(__file__), '..')
load_dotenv(os.path.join(_root_dir, '.env'))
```

- ✅ 现在从根目录 `codes/.env` 加载配置
- ✅ 修正了 `BACKEND_BASE_URL` 环境变量名称
- ✅ 添加了新的存储路径配置
- ✅ 新增 `get_storage_path()` 方法

### 3. 统一存储路径配置 📁

**Backend**: `application.yaml`

**修改内容**:

```yaml
# 修改前
app:
  storage:
    base-path: ${STORAGE_BASE_PATH:../storage}
    video-path: ${app.storage.base-path}/videos

# 修改后  
app:
  storage:
    base-path: ${STORAGE_BASE_PATH:storage}
    videos-subdir: ${STORAGE_VIDEOS_SUBDIR:videos}
    result-videos-subdir: ${STORAGE_RESULT_VIDEOS_SUBDIR:result_videos}
```

**Java代码**: `AnalysisTaskServiceImpl.java`

- ✅ 使用 `app.storage.base-path` + `app.storage.videos-subdir`
- ✅ 简化了路径拼接逻辑
- ✅ 统一使用相对于 `codes/` 目录的路径

### 4. 前端API配置使用环境变量 🌐

**文件**: `frontend/nuxt.config.ts`

**修改内容**:

```typescript
// 修改前
runtimeConfig: {
  public: {
    apiBase: 'http://localhost:8080'
  }
}

// 修改后
runtimeConfig: {
  public: {
    apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://localhost:8080'
  }
}
```

- ✅ 支持通过环境变量 `NUXT_PUBLIC_API_BASE` 配置
- ✅ 保留默认值用于开发环境

### 5. AI模块日志级别配置化 📝

**文件**: `ai-processor/app.py`

**修改内容**:

```python
# 修改前
logging.basicConfig(
    level=logging.INFO,
    format='...'
)

# 修改后
log_level = os.getenv('AI_LOG_LEVEL', 'INFO').upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format='...'
)
```

- ✅ 支持通过 `AI_LOG_LEVEL` 环境变量配置
- ✅ 启动时会显示当前日志级别

---

## 🔄 需要执行的迁移步骤

### 步骤1: 更新环境变量文件

#### 开发环境

```bash
cd /Users/erikssonhou/Projects/VAR熔池挑战/codes

# 备份旧的配置
cp .env .env.backup 2>/dev/null || true
cp ai-processor/.env ai-processor/.env.backup 2>/dev/null || true

# 使用新的配置模板
cp .env.example .env

# 编辑 .env 文件，填入实际的配置值
# 特别注意以下配置项的修改：
# - BACKEND_BASE_URL=http://localhost:8080  (原 AI_CALLBACK_URL)
# - STORAGE_BASE_PATH=storage  (原 ./storage)
```

#### 删除AI模块的独立配置文件（可选）

```bash
# ai-processor/.env 文件已不再需要，可以删除
rm ai-processor/.env.example  # 示例文件
# rm ai-processor/.env  # 如果存在实际配置文件，请先备份
```

### 步骤2: 更新Docker Compose配置

**文件**: `docker-compose.dev.yml`

确保环境变量正确传递：

```yaml
# 无需修改，docker-compose会自动读取 .env 文件
```

### 步骤3: 前端环境变量（可选）

如果需要在前端使用不同的API地址：

```bash
# 在 frontend/ 目录或根目录创建 .env
echo "NUXT_PUBLIC_API_BASE=http://localhost:8080" >> .env
```

### 步骤4: 验证配置

**验证Backend**:

```bash
cd backend
./mvnw spring-boot:run

# 查看启动日志，确认配置正确加载
# 应该显示：
# - spring.datasource.url: jdbc:postgresql://localhost:5432/var_analysis
# - app.storage.base-path: storage
```

**验证AI模块**:

```bash
cd ai-processor
python app.py

# 查看启动日志，确认：
# - 日志级别设置为: INFO
# - ✓ 使用 MPS 设备 (或 CUDA/CPU)
# - Connected to RabbitMQ at localhost:5672
```

**验证前端**:

```bash
cd frontend
pnpm dev

# 访问 http://localhost:3000
# 打开浏览器控制台，检查API请求地址是否正确
```

---

## 📝 配置变更对照表

| 配置项 | 旧名称 | 新名称 | 说明 |
|-------|--------|--------|------|
| 后端回调URL | `AI_CALLBACK_URL` | `BACKEND_BASE_URL` | 更明确的命名 |
| 存储基础路径 | `STORAGE_BASE_PATH=./storage` | `STORAGE_BASE_PATH=storage` | 统一为相对路径 |
| 视频存储路径 | `app.storage.video-path` | `app.storage.videos-subdir` | 改为子目录配置 |
| 结果视频路径 | `app.storage.result-path` | `app.storage.result-videos-subdir` | 改为子目录配置 |
| AI日志级别 | 硬编码 `INFO` | `AI_LOG_LEVEL` | 支持环境变量 |
| 前端API地址 | 硬编码 | `NUXT_PUBLIC_API_BASE` | 支持环境变量 |

---

## 🔍 配置项说明

### 存储路径配置

```bash
# 基础路径（相对于 codes/ 目录）
STORAGE_BASE_PATH=storage

# 子目录（会自动拼接到基础路径后面）
STORAGE_VIDEOS_SUBDIR=videos
STORAGE_RESULT_VIDEOS_SUBDIR=result_videos
STORAGE_PREPROCESSED_VIDEOS_SUBDIR=preprocessed_videos
STORAGE_TEMP_SUBDIR=temp

# 最终路径：
# - 视频: codes/storage/videos/
# - 结果: codes/storage/result_videos/
# - 预处理: codes/storage/preprocessed_videos/
```

### 服务URL配置

```bash
# 后端服务（不包含 /api 路径）
BACKEND_BASE_URL=http://localhost:8080

# 前端应用
FRONTEND_BASE_URL=http://localhost:3000

# AI处理模块
AI_PROCESSOR_URL=http://localhost:5000

# 在代码中使用：
# Config.get_callback_url(task_id, 'progress')
# => http://localhost:8080/api/tasks/{task_id}/progress
```

### 日志配置

```bash
# 后端日志（Spring Boot）
LOG_LEVEL=DEBUG
WEB_LOG_LEVEL=INFO
SQL_LOG_LEVEL=DEBUG

# AI模块日志（Python）
AI_LOG_LEVEL=INFO  # 可选: DEBUG, INFO, WARNING, ERROR
```

---

## ⚠️ 注意事项

### 1. 路径兼容性

- **旧代码**: 使用 `../storage` (相对于backend目录)
- **新代码**: 使用 `storage` (相对于codes目录)
- 两种方式实际指向同一位置，已做兼容处理

### 2. URL配置

- `BACKEND_BASE_URL` 不应包含 `/api/tasks` 路径
- 代码会自动拼接完整的回调URL
- 示例：`http://localhost:8080` → `http://localhost:8080/api/tasks/123/progress`

### 3. 环境变量优先级

1. 系统环境变量
2. `.env` 文件
3. 代码中的默认值

### 4. Docker环境

在Docker中运行时，确保：

- 挂载正确的存储卷：`./storage:/app/storage`
- 服务间使用Docker网络名称：`backend:8080` 而不是 `localhost:8080`

---

## 🧪 测试清单

- [ ] Backend能正常启动，配置正确加载
- [ ] AI模块能连接到RabbitMQ
- [ ] 上传视频文件保存到正确位置 (`storage/videos/`)
- [ ] 分析任务能正常执行
- [ ] 结果视频保存到正确位置 (`storage/result_videos/`)
- [ ] 前端能正确调用后端API
- [ ] WebSocket连接正常
- [ ] 日志级别可通过环境变量控制

---

## 📚 相关文档

- [配置审查报告](./CODE_REVIEW_CONFIG.md)
- [系统设计文档](./系统设计文档.md)
- [部署文档](./deploy.sh)

---

**修复完成时间**: 2025-10-08  
**修复范围**: 配置统一、路径规范化、环境变量优化
