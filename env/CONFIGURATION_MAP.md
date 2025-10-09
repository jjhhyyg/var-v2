# 环境变量配置映射表

本文档说明每个环境变量在哪个模块中使用。

## 共享配置 (env/shared/)

| 环境变量 | Backend | AI-Processor | 说明 |
|---------|---------|--------------|------|
| `DB_HOST` | ✅ | ✅ | 数据库主机地址 |
| `DB_PORT` | ✅ | ✅ | 数据库端口 |
| `DB_NAME` | ✅ | ✅ | 数据库名称 |
| `DB_USER` | ✅ | ✅ | 数据库用户名 |
| `DB_PASSWORD` | ✅ | ✅ | 数据库密码 |
| `REDIS_HOST` | ✅ | ✅ | Redis主机地址 |
| `REDIS_PORT` | ✅ | ✅ | Redis端口 |
| `REDIS_PASSWORD` | ✅ | ✅ | Redis密码 |
| `REDIS_DB` | ✅ | ✅ | Redis数据库编号 |
| `RABBITMQ_HOST` | ✅ | ✅ | RabbitMQ主机地址 |
| `RABBITMQ_PORT` | ✅ | ✅ | RabbitMQ端口 |
| `RABBITMQ_USER` | ✅ | ✅ | RabbitMQ用户名 |
| `RABBITMQ_PASSWORD` | ✅ | ✅ | RabbitMQ密码 |
| `RABBITMQ_VHOST` | ✅ | ✅ | RabbitMQ虚拟主机 |
| `STORAGE_BASE_PATH` | ✅ | ✅ | 存储基础路径 |
| `STORAGE_VIDEOS_SUBDIR` | ✅ | ✅ | 视频子目录 |
| `STORAGE_RESULT_VIDEOS_SUBDIR` | ✅ | ✅ | 结果视频子目录 |
| `STORAGE_PREPROCESSED_VIDEOS_SUBDIR` | ✅ | ✅ | 预处理视频子目录 |
| `STORAGE_TEMP_SUBDIR` | ✅ | ✅ | 临时文件子目录 |
| `DEFAULT_TIMEOUT_RATIO` | ✅ | ✅ | 默认超时比例 |
| `DEFAULT_CONFIDENCE_THRESHOLD` | ✅ | ✅ | 默认置信度阈值 |
| `DEFAULT_IOU_THRESHOLD` | ✅ | ✅ | 默认IoU阈值 |

## Backend 独有配置 (env/backend/)

| 环境变量 | 说明 | 代码位置 |
|---------|------|---------|
| `SERVER_PORT` | 服务器端口 | `application.yaml` |
| `BACKEND_BASE_URL` | 后端自己的URL(供AI回调) | `application.yaml` |
| `CORS_ORIGINS` | CORS允许的源 | `CorsConfig.java` |
| `SNOWFLAKE_DATACENTER_ID` | 雪花算法数据中心ID | `application.yaml` |
| `SNOWFLAKE_WORKER_ID` | 雪花算法工作机器ID | `application.yaml` |
| `LOG_LEVEL` | 应用日志级别 | `application.yaml` |
| `WEB_LOG_LEVEL` | Web日志级别 | `application.yaml` |
| `SQL_LOG_LEVEL` | SQL日志级别 | `application.yaml` |
| `SQL_PARAM_LOG_LEVEL` | SQL参数日志级别 | `application.yaml` |
| `SHOW_SQL` | 是否显示SQL语句 | `application.yaml` |

## Frontend 独有配置 (env/frontend/)

| 环境变量 | 说明 | 代码位置 |
|---------|------|---------|
| `NUXT_PUBLIC_API_BASE` | 后端API基础URL | `nuxt.config.ts` |

## AI-Processor 独有配置 (env/ai-processor/)

| 环境变量 | 说明 | 代码位置 |
|---------|------|---------|
| `AI_PROCESSOR_PORT` | AI处理模块端口 | `config.py` |
| `AI_PROCESSOR_HOST` | AI处理模块主机 | `config.py` |
| `AI_PROCESSOR_DEBUG` | 是否开启调试模式 | `config.py` |
| `BACKEND_BASE_URL` | 后端服务URL(用于回调) | `config.py` |
| `YOLO_MODEL_PATH` | YOLO模型文件路径 | `config.py` |
| `YOLO_MODEL_VERSION` | YOLO模型版本 | `config.py` |
| `YOLO_DEVICE` | 计算设备(cpu/cuda/mps) | `config.py` |
| `YOLO_VERBOSE` | 是否显示详细输出 | `config.py` |
| `TRACKER_CONFIG` | 追踪器配置文件 | `config.py` |
| `TRACK_HIGH_THRESH` | 高置信度阈值 | `config.py` |
| `TRACK_LOW_THRESH` | 低置信度阈值 | `config.py` |
| `NEW_TRACK_THRESH` | 新轨迹阈值 | `config.py` |
| `TRACK_BUFFER` | 轨迹缓冲帧数 | `config.py` |
| `MATCH_THRESH` | 匹配阈值 | `config.py` |
| `FUSE_SCORE` | 是否融合分数 | `config.py` |
| `GMC_METHOD` | 全局运动补偿方法 | `config.py` |
| `WITH_REID` | 是否使用ReID | `config.py` |
| `PROXIMITY_THRESH` | 接近阈值 | `config.py` |
| `APPEARANCE_THRESH` | 外观阈值 | `config.py` |
| `PROGRESS_UPDATE_INTERVAL` | 进度更新间隔(帧) | `config.py` |

## 注意事项

1. **Backend 和 AI-Processor 中的 `BACKEND_BASE_URL`**:
   - Backend 中: 后端自己的URL,供AI模块回调使用
   - AI-Processor 中: 后端服务的URL,用于回调
   - 两者通常是相同的值,但在Docker环境中可能不同

2. **开发环境 vs 生产环境**:
   - 开发环境: 使用 `localhost` 和相对路径
   - 生产环境: 使用实际的主机名/域名和绝对路径

3. **配置文件合并**: 
   - 各模块的 `.env` 文件会合并 `shared` 和模块独有的配置
   - `use-env.sh` 脚本会自动处理这个合并过程
