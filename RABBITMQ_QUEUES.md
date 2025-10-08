# RabbitMQ 消息队列配置说明

## 📋 队列概览

系统使用 **1个RabbitMQ队列** 用于视频分析任务：

| 队列名称 | 配置键 | 默认值 | 用途 |
|---------|--------|--------|------|
| 视频分析队列 | `app.queue.video-analysis` | `video_analysis_queue` | Backend → AI模块：发送视频分析任务 |

---

## 🔍 video_analysis_queue (视频分析队列)

### 消息流程

```
用户上传视频
  ↓
Backend保存视频并创建任务
  ↓
Backend发送消息到 video_analysis_queue
  ↓
AI模块消费消息，开始分析
  ↓
AI模块通过HTTP回调返回结果
```

### 配置位置

**Backend (application.yaml)**:
```yaml
app:
  queue:
    video-analysis: video_analysis_queue
```

**AI模块 (.env)**:
```bash
RABBITMQ_VIDEO_ANALYSIS_QUEUE=video_analysis_queue
```

### 代码实现

**Backend - 生产者 (VideoAnalysisProducer.java)**:
```java
@Value("${app.queue.video-analysis}")
private String videoAnalysisQueue;

public void sendAnalysisTask(VideoAnalysisMessage message) {
    rabbitTemplate.convertAndSend(videoAnalysisQueue, message);
}
```

**AI模块 - 消费者 (mq_consumer.py)**:
```python
RABBITMQ_VIDEO_ANALYSIS_QUEUE = Config.RABBITMQ_VIDEO_ANALYSIS_QUEUE

def connect(self):
    self.channel.queue_declare(queue=self.queue_name, durable=True)
    self.channel.basic_consume(
        queue=self.queue_name, 
        on_message_callback=self.callback
    )
```

### 消息格式

```json
{
  "taskId": 123,
  "videoPath": "storage/videos/test.mp4",
  "videoDuration": 1800,
  "timeoutThreshold": 7200,
  "callbackUrl": "http://localhost:8080",
  "config": {
    "enablePreprocessing": true,
    "preprocessingStrength": "moderate"
  }
}
```

---

## 🔄 结果返回方式

### 当前实现：HTTP 回调

AI模块分析完成后，通过 **HTTP POST** 请求将结果返回给Backend：

```python
# AI模块实现
result_url = Config.get_callback_url(task_id, 'result')
# 返回: http://localhost:8080/api/tasks/123/result

requests.post(result_url, json={
    "status": "COMPLETED",
    "resultVideoPath": "storage/result_videos/xxx_result.mp4",
    "events": [...],
    "globalMetrics": {...}
})
```

### 为什么使用HTTP回调？

| 特性 | HTTP回调 | MQ回调 |
|-----|---------|--------|
| 实时性 | 高 | 较高 |
| 可靠性 | 依赖网络 | 更可靠（消息持久化） |
| 复杂度 | ✅ 简单直接 | 需要消费者实现 |
| 错误处理 | HTTP重试机制 | 自动重新入队 |
| 当前选择 | ✅ 采用 | ❌ 未采用 |

**选择原因**：
- ✅ 实现简单，易于调试
- ✅ 实时性好，立即返回结果
- ✅ 满足当前业务需求

---

## ⚙️ 环境变量配置

### .env 示例

```bash
# ==================== RabbitMQ配置 ====================
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=var_user
RABBITMQ_PASSWORD=your_rabbitmq_password_here
RABBITMQ_VHOST=/

# RabbitMQ队列名称
# 视频分析任务队列（Backend → AI模块）
RABBITMQ_VIDEO_ANALYSIS_QUEUE=video_analysis_queue
```

### 配置说明

**Backend (application.yaml)**:
```yaml
app:
  queue:
    video-analysis: ${RABBITMQ_VIDEO_ANALYSIS_QUEUE}
```

**AI模块 (config.py)**:
```python
# 从根目录的 .env 加载配置
RABBITMQ_VIDEO_ANALYSIS_QUEUE = os.getenv(
    'RABBITMQ_VIDEO_ANALYSIS_QUEUE', 
    'video_analysis_queue'
)
```

---

## 📝 总结

### 当前系统架构

**消息流程**:
```
Frontend → Backend → RabbitMQ → AI模块
                    (video_analysis_queue)
                    
AI模块 → Backend (HTTP回调)
   └─ POST /api/tasks/{taskId}/result
```

**架构特点**:
- ✅ **简洁清晰** - 单一队列，职责明确
- ✅ **易于维护** - 减少配置复杂度
- ✅ **实时性好** - HTTP回调即时返回结果
- ✅ **符合现状** - 满足当前业务需求

### 后续优化方向（可选）

如果未来有更高可靠性需求，可考虑：

1. **引入MQ回调** - 替代HTTP回调，提高可靠性（消息持久化）
2. **任务控制队列** - 支持任务暂停/恢复/取消功能
3. **死信队列** - 处理失败任务的自动重试机制

---

**文档创建时间**: 2025-10-08  
**相关文档**: 
- [配置迁移指南](./CONFIG_MIGRATION.md)
- [存储路径配置](./STORAGE_PATH_GUIDE.md)
- [配置更新说明](./CONFIG_UPDATE.md)
