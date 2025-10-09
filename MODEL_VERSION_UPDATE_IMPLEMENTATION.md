# 模型版本实时更新功能实现总结

## 功能需求

在 AI-Processor 接收到分析任务时，应该向后端更新模型版本，并在前端实时显示。

## 实现方案

### 1. 后端修改

#### 1.1 添加更新模型版本的服务接口

**文件：** `backend/src/main/java/ustb/hyy/app/backend/service/AnalysisTaskService.java`

```java
/**
 * 更新任务的模型版本
 *
 * @param taskId 任务ID
 * @param modelVersion 模型版本
 */
void updateModelVersion(Long taskId, String modelVersion);
```

#### 1.2 实现服务方法（带 WebSocket 推送）

**文件：** `backend/src/main/java/ustb/hyy/app/backend/service/impl/AnalysisTaskServiceImpl.java`

```java
@Override
@Transactional
public void updateModelVersion(Long taskId, String modelVersion) {
    TaskConfig config = configRepository.findByTaskId(taskId)
            .orElseThrow(() -> new ResourceNotFoundException("任务配置", taskId));
    config.setModelVersion(modelVersion);
    configRepository.save(config);
    log.info("更新任务模型版本，taskId: {}, modelVersion: {}", taskId, modelVersion);

    // 通过WebSocket推送更新，通知前端重新加载任务信息
    try {
        AnalysisTask task = findTaskById(taskId);
        TaskResponse response = buildTaskResponse(task, config);
        messagingTemplate.convertAndSend("/topic/tasks/" + taskId + "/update", response);
        log.debug("WebSocket消息已推送（模型版本更新），taskId: {}, modelVersion: {}", taskId, modelVersion);
    } catch (Exception e) {
        log.error("WebSocket消息推送失败（模型版本更新），taskId: {}", taskId, e);
    }
}
```

#### 1.3 添加 REST API 端点

**文件：** `backend/src/main/java/ustb/hyy/app/backend/controller/TaskController.java`

```java
/**
 * 更新模型版本（AI模块回调）
 */
@Operation(summary = "更新模型版本", description = "AI模块回调接口，更新任务使用的模型版本")
@PutMapping("/{taskId:[0-9]+}/model-version")
public Result<String> updateModelVersion(
        @Parameter(description = "任务ID") @PathVariable Long taskId,
        @RequestBody Map<String, String> request) {
    String modelVersion = request.get("modelVersion");
    log.info("更新模型版本，taskId: {}, modelVersion: {}", taskId, modelVersion);
    taskService.updateModelVersion(taskId, modelVersion);
    return Result.success("模型版本更新成功");
}
```

### 2. AI-Processor 修改

#### 2.1 在接收任务时更新模型版本

**文件：** `ai-processor/mq_consumer.py`

在创建 `VideoAnalyzer` 实例后，立即获取模型版本并向后端发送更新请求：

```python
# 为每个任务创建独立的视频分析器实例
task_analyzer = VideoAnalyzer(
    model_path=Config.MODEL_PATH,
    device=Config.DEVICE
)
logger.info(f"Task {task_id}: Created independent analyzer instance")

# 获取模型版本并更新到后端
try:
    model_version = task_analyzer.yolo_tracker.model_version
    logger.info(f"Task {task_id}: Model version: {model_version}")
    
    # 向后端更新模型版本
    import requests
    update_url = f"{Config.BACKEND_BASE_URL}/api/tasks/{task_id}/model-version"
    response = requests.put(
        update_url,
        json={'modelVersion': model_version},
        timeout=10
    )
    if response.status_code == 200:
        logger.info(f"Task {task_id}: Model version updated in backend: {model_version}")
    else:
        logger.warning(f"Task {task_id}: Failed to update model version: {response.status_code}")
except Exception as e:
    logger.error(f"Task {task_id}: Failed to update model version: {e}")
```

### 3. 前端修改

#### 3.1 添加任务详情更新订阅

**文件：** `frontend/app/pages/index.vue`

修改主页，为每个任务订阅详情更新（包括模型版本等所有字段的更新）：

```typescript
// 引入 subscribeToTaskDetailUpdate
const { connect, disconnect, subscribeToTaskUpdates, subscribeToTaskDetailUpdate } = useWebSocket()

// 添加任务详情订阅管理
const taskDetailUnsubscribers = new Map<string, () => void>()

// 订阅所有任务的详情更新
const subscribeToTaskDetails = () => {
  // 先取消所有现有订阅
  taskDetailUnsubscribers.forEach(unsubscribe => unsubscribe())
  taskDetailUnsubscribers.clear()

  // 为每个任务订阅详情更新
  tasks.value.forEach((task) => {
    const unsubscribe = subscribeToTaskDetailUpdate(task.taskId, (updatedTask) => {
      console.log('收到任务详情更新:', updatedTask)
      // 更新列表中的任务数据
      const taskIndex = tasks.value.findIndex(t => t.taskId === updatedTask.taskId)
      if (taskIndex !== -1) {
        tasks.value[taskIndex] = updatedTask
      }
    })
    taskDetailUnsubscribers.set(task.taskId, unsubscribe)
  })
}

// 在加载任务列表后订阅
const loadTasks = async () => {
  loading.value = true
  try {
    const result: PageResult<Task> = await listTasks(currentPage.value, 20, selectedStatus.value)
    tasks.value = result.items
    totalPages.value = result.totalPages

    // 订阅每个任务的详情更新
    subscribeToTaskDetails()
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : '加载失败'
    toast.add({ title: '加载失败', description: errorMessage, color: 'error' })
  } finally {
    loading.value = false
  }
}

// 清理时取消所有订阅
onUnmounted(() => {
  if (unsubscribeUpdates) {
    unsubscribeUpdates()
  }
  // 取消所有任务详情订阅
  taskDetailUnsubscribers.forEach(unsubscribe => unsubscribe())
  taskDetailUnsubscribers.clear()
  
  disconnect()
})
```

## 工作流程

1. **用户点击"开始分析"**
   - 前端调用后端 API 开始任务

2. **后端发送消息到 RabbitMQ**
   - 任务消息被发送到 `video_analysis_queue`

3. **AI-Processor 接收任务**
   - 创建 `VideoAnalyzer` 实例
   - 从模型文件中读取模型版本（通过 `YOLOTracker.model_version`）

4. **AI-Processor 更新后端**
   - 调用 `PUT /api/tasks/{taskId}/model-version`
   - 传递模型版本到后端

5. **后端更新数据库并推送 WebSocket**
   - 更新 `task_configs` 表中的 `model_version` 字段
   - 通过 WebSocket 推送完整的任务对象到 `/topic/tasks/{taskId}/update`

6. **前端实时更新显示**
   - 订阅的 WebSocket 回调接收更新
   - 更新任务列表中对应任务的数据
   - 模型版本在 UI 中实时显示

## WebSocket 主题说明

- `/topic/tasks/updates` - 任务列表简化更新（仅 taskId, status, progress）
- `/topic/tasks/{taskId}/update` - 特定任务的完整详情更新（包括 modelVersion 等所有字段）

## 测试要点

1. ✅ 点击"开始分析"后，模型版本应在数据库中正确更新
2. ✅ 前端应实时显示更新的模型版本，无需手动刷新页面
3. ✅ 查看浏览器控制台，应能看到 WebSocket 消息：`收到任务详情更新: {...}`
4. ✅ 查看后端日志，应能看到：`更新任务模型版本，taskId: xxx, modelVersion: xxx`
5. ✅ 查看 AI-Processor 日志，应能看到：`Task xxx: Model version updated in backend: xxx`

## 优势

- **实时性**：模型版本在任务开始时立即更新，前端通过 WebSocket 实时显示
- **准确性**：模型版本直接从模型文件中读取，确保与实际使用的模型一致
- **可维护性**：复用现有的 WebSocket 基础设施，无需额外轮询
- **用户体验**：用户点击开始分析后立即看到模型版本，无需等待或刷新
