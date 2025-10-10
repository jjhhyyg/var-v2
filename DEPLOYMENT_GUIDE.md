# 追踪轨迹合并功能 - 快速部署指南

## 🚀 一键部署步骤

### 1. 数据库迁移（自动）

**后端启动时会自动执行迁移脚本**：

```bash
cd backend
mvn spring-boot:run
```

✅ 自动应用 `V9__add_tracking_merge_fields.sql`  
✅ 添加 `enable_tracking_merge` 和 `tracking_merge_strategy` 字段

如果需要手动执行（可选）：

```bash
# 查看迁移状态
mvn flyway:info

# 手动迁移
mvn flyway:migrate
```

---

### 2. 后端部署

**无需额外配置！** 已自动集成。

验证后端更新：

```bash
cd backend
mvn clean package
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

检查日志：

```
✓ Flyway migration V9 applied successfully
✓ TaskConfig entity loaded with new fields
✓ AnalysisTaskServiceImpl updated
```

---

### 3. Python AI 处理器

**无需额外配置！** 已自动集成合并算法。

验证 Python 环境：

```bash
cd ai-processor

# 确保已安装依赖（之前已安装）
pip install -r requirements.txt

# 测试合并算法
python test_tracking_merger.py
```

启动 AI 处理器：

```bash
python app.py
```

检查日志：

```
✓ Tracking merger module loaded
✓ MQ consumer ready to process messages
✓ Merge strategies: auto, adhesion, ingot_crown, conservative, aggressive
```

---

### 4. 前端部署

**无需额外配置！** UI已更新。

```bash
cd frontend

# 安装依赖（如有新增）
pnpm install

# 启动开发服务器
pnpm dev

# 或生产构建
pnpm build
pnpm preview
```

验证前端功能：

1. 打开 <http://localhost:3000>
2. 在上传表单中应该看到：
   - ✅ "启用追踪轨迹合并" 复选框（默认勾选）
   - ✅ "合并策略" 下拉菜单（5个选项）
   - ✅ 悬停提示信息

---

## 🧪 功能测试

### 测试步骤

1. **上传测试视频**：

   ```
   - 选择包含粘连物或锭冠的视频
   - 启用"追踪轨迹合并"
   - 选择"自动识别"策略
   - 点击"创建分析任务"
   ```

2. **监控日志**：

   **后端日志** (backend/logs/):

   ```
   任务已发送到分析队列，taskId: xxx
   配置: enableTrackingMerge=true, strategy=auto
   ```

   **Python日志** (ai-processor/):

   ```
   Task xxx: Applying tracking merge algorithm with strategy 'auto'
   Task xxx: Merge completed - 162 → 65 objects (减少 59.9%)
   Task xxx: Merged 6 groups
   ```

3. **查看结果**：

   ```
   - 进入任务详情页
   - 查看"任务配置"部分
   - 应显示：追踪合并 ✓ 已启用
   - 应显示：合并策略 - 自动识别
   ```

---

## 📊 验证成功标志

### ✅ 数据库层

```sql
-- 检查表结构
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'task_configs' 
  AND column_name IN ('enable_tracking_merge', 'tracking_merge_strategy');
```

应返回：

```
enable_tracking_merge | boolean | true
tracking_merge_strategy | varchar(20) | 'auto'
```

### ✅ 后端层

访问 API：

```bash
curl http://localhost:8080/api/tasks/{taskId}
```

响应应包含：

```json
{
  "config": {
    "enableTrackingMerge": true,
    "trackingMergeStrategy": "auto"
  }
}
```

### ✅ AI 处理层

查看日志文件：

```bash
tail -f ai-processor/logs/app.log | grep "Merge"
```

应看到：

```
Applying tracking merge algorithm with strategy 'auto'
Merge completed - X → Y objects
```

### ✅ 前端层

1. 浏览器开发者工具 → Network
2. 创建任务时检查请求payload
3. 应包含：

   ```json
   {
     "config": {
       "enableTrackingMerge": true,
       "trackingMergeStrategy": "auto"
     }
   }
   ```

---

## 🔄 回滚方案（如需要）

### 回滚数据库

```sql
-- 删除新增字段
ALTER TABLE task_configs 
DROP COLUMN enable_tracking_merge,
DROP COLUMN tracking_merge_strategy;
```

### 回滚后端

```bash
cd backend
git checkout HEAD~1 src/main/java/ustb/hyy/app/backend/
mvn clean package
```

### 回滚前端

```bash
cd frontend
git checkout HEAD~1 app/
pnpm install
pnpm build
```

### 回滚 Python

```bash
cd ai-processor
git checkout HEAD~1 analyzer/video_processor.py mq_consumer.py
```

---

## 📝 环境变量（可选配置）

无需额外配置！使用默认值即可。

如需自定义，可在 `.env` 文件中添加：

```bash
# AI处理器默认合并策略（可选）
DEFAULT_TRACKING_MERGE_STRATEGY=auto

# 是否默认启用合并（可选）
DEFAULT_ENABLE_TRACKING_MERGE=true
```

---

## 🐛 常见问题

### Q1: 数据库迁移失败？

**A:** 检查数据库连接和 Flyway 配置：

```bash
mvn flyway:info
mvn flyway:repair  # 如果迁移状态异常
mvn flyway:migrate
```

### Q2: 前端看不到新选项？

**A:** 清除缓存并重新构建：

```bash
cd frontend
rm -rf .nuxt node_modules/.vite
pnpm install
pnpm dev
```

### Q3: Python合并未生效？

**A:** 检查依赖和模块导入：

```bash
cd ai-processor
python -c "from utils.tracking_utils import smart_merge; print('✓ Import success')"
```

### Q4: 合并效果不理想？

**A:** 尝试不同策略：

- 粘连物视频 → 选择 "粘连物专用"
- 锭冠视频 → 选择 "锭冠专用"
- 严重断裂 → 选择 "激进模式"

参考 `ai-processor/TRACKING_ID_MAINTENANCE.md` 调优指南

---

## 📚 相关文档

- 📖 **集成总结**: `/codes/TRACKING_MERGE_INTEGRATION.md`
- 📖 **技术方案**: `/codes/ai-processor/TRACKING_ID_MAINTENANCE.md`
- 📖 **快速使用**: `/codes/ai-processor/README_TRACKING_MERGE.md`
- 📖 **代码示例**: `/codes/ai-processor/MERGE_USAGE_EXAMPLES.py`

---

## ✨ 部署检查清单

- [ ] 数据库迁移成功（检查 flyway_schema_history 表）
- [ ] 后端启动无错误
- [ ] Python AI处理器启动无错误
- [ ] 前端显示追踪合并选项
- [ ] 创建测试任务成功
- [ ] 日志显示合并算法已执行
- [ ] 任务详情显示合并配置
- [ ] 追踪对象数量减少（40-60%）

---

**部署完成！** 🎉

系统现在具备智能追踪轨迹合并能力，可以完整追踪粘连物和锭冠的整个生命周期！
