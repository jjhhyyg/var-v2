# 存储路径配置说明

**文档创建时间**: 2025-10-08

---

## 📁 存储路径配置项

### 环境变量定义 (.env.example)

```bash
# 存储基础路径（相对于 codes/ 目录）
STORAGE_BASE_PATH=storage

# 存储子目录（相对于 STORAGE_BASE_PATH）
STORAGE_VIDEOS_SUBDIR=videos
STORAGE_RESULT_VIDEOS_SUBDIR=result_videos
STORAGE_PREPROCESSED_VIDEOS_SUBDIR=preprocessed_videos
STORAGE_TEMP_SUBDIR=temp
```

## 🔄 各模块如何使用

### 1. Backend (Spring Boot)

#### application.yaml 配置
```yaml
app:
  storage:
    base-path: ${STORAGE_BASE_PATH:storage}
    videos-subdir: ${STORAGE_VIDEOS_SUBDIR:videos}
    result-videos-subdir: ${STORAGE_RESULT_VIDEOS_SUBDIR:result_videos}
    preprocessed-videos-subdir: ${STORAGE_PREPROCESSED_VIDEOS_SUBDIR:preprocessed_videos}
    temp-subdir: ${STORAGE_TEMP_SUBDIR:temp}
```

#### Java 代码使用
**AnalysisTaskServiceImpl.java**:
```java
@Value("${app.storage.base-path}")
private String storageBasePath;  // "storage"

@Value("${app.storage.videos-subdir}")
private String videosSubdir;  // "videos"

// 使用示例
private String getVideoStoragePath() {
    return storageBasePath + "/" + videosSubdir;  // "storage/videos"
}

// 保存文件后返回相对路径
String relativePath = storageBasePath + "/" + videosSubdir + "/" + filename;
// 例如: "storage/videos/test.mp4"
```

**VideoServiceImpl.java**:
```java
// 从数据库读取相对路径
String path = task.getVideoPath();  // "storage/videos/xxx.mp4"
String path = task.getResultVideoPath();  // "storage/result_videos/xxx_result.mp4"
String path = task.getPreprocessedVideoPath();  // "storage/preprocessed_videos/xxx_preprocessed.mp4"

// 转换为相对于backend目录的路径
return "../" + path;  // "../storage/videos/xxx.mp4"
```

**使用说明**:
- ✅ 视频上传：使用 `videos-subdir` (已实现)
- ✅ 视频读取：从数据库读取路径 (已实现)
- ⚠️ **未使用**: `result-videos-subdir`, `preprocessed-videos-subdir`, `temp-subdir` 
  - Backend只需要读取这些路径（由AI模块写入）
  - 不需要在Java代码中配置，因为AI模块会通过回调设置完整路径

---

### 2. AI Processor (Python)

#### config.py 配置
```python
# 存储路径配置（相对于 codes/ 目录）
STORAGE_BASE_PATH = os.getenv('STORAGE_BASE_PATH', 'storage')
STORAGE_VIDEOS_SUBDIR = os.getenv('STORAGE_VIDEOS_SUBDIR', 'videos')
STORAGE_RESULT_VIDEOS_SUBDIR = os.getenv('STORAGE_RESULT_VIDEOS_SUBDIR', 'result_videos')
STORAGE_PREPROCESSED_VIDEOS_SUBDIR = os.getenv('STORAGE_PREPROCESSED_VIDEOS_SUBDIR', 'preprocessed_videos')

# 完整路径（废弃，保留用于向后兼容）
RESULT_VIDEO_PATH = os.getenv('RESULT_VIDEO_PATH', './storage/result_videos')
PREPROCESSED_VIDEO_PATH = os.getenv('PREPROCESSED_VIDEO_PATH', './storage/preprocessed_videos')
```

#### 使用方法
```python
# 推荐方式：使用新的配置
result_dir = Config.get_storage_path(Config.STORAGE_RESULT_VIDEOS_SUBDIR)
# 返回: /path/to/codes/storage/result_videos

preprocessed_dir = Config.get_storage_path(Config.STORAGE_PREPROCESSED_VIDEOS_SUBDIR)
# 返回: /path/to/codes/storage/preprocessed_videos

# 兼容方式：使用旧的配置（会被逐步替换）
preprocessed_dir = Config.resolve_path(Config.PREPROCESSED_VIDEO_PATH)
```

**实际使用位置**:

**video_processor.py** (预处理视频):
```python
# 当前使用（兼容方式）
preprocessed_dir = Path(Config.resolve_path(Config.PREPROCESSED_VIDEO_PATH))
# 返回: /path/to/codes/storage/preprocessed_videos

# 推荐改为
preprocessed_dir = Path(Config.get_storage_path(Config.STORAGE_PREPROCESSED_VIDEOS_SUBDIR))
```

**video_processor.py** (结果视频):
```python
# 当前使用
result_dir = Config.resolve_path(Config.RESULT_VIDEO_PATH)

# 推荐改为
result_dir = Config.get_storage_path(Config.STORAGE_RESULT_VIDEOS_SUBDIR)
```

---

## 📊 路径流转示例

### 场景1: 用户上传视频

1. **Frontend** → **Backend**: 上传视频文件
2. **Backend**: 保存到 `storage/videos/test.mp4`
3. **Backend**: 数据库存储相对路径 `storage/videos/test.mp4`
4. **Backend**: 发送任务到 RabbitMQ，包含路径 `storage/videos/test.mp4`

### 场景2: AI模块预处理视频

1. **AI Processor**: 接收任务，路径 `storage/videos/test.mp4`
2. **AI Processor**: 转换为绝对路径 `/path/to/codes/storage/videos/test.mp4`
3. **AI Processor**: 预处理后保存到 `storage/preprocessed_videos/test_preprocessed.mp4`
4. **AI Processor**: 回调Backend，更新预处理视频路径

```python
# AI模块代码
preprocessed_dir = Path(Config.resolve_path(Config.PREPROCESSED_VIDEO_PATH))
# 或使用新方法
preprocessed_dir = Path(Config.get_storage_path(Config.STORAGE_PREPROCESSED_VIDEOS_SUBDIR))

preprocessed_video_path = str(preprocessed_dir / f"{video_stem}_preprocessed.mp4")
# 绝对路径: /path/to/codes/storage/preprocessed_videos/test_preprocessed.mp4

# 转换为相对路径
relative_path = Config.to_relative_path(os.path.abspath(preprocessed_video_path))
# 返回: storage/preprocessed_videos/test_preprocessed.mp4

# 回调Backend更新
requests.put(
    f"{Config.BACKEND_BASE_URL}/api/tasks/{task_id}/preprocessed-video",
    json={"preprocessedVideoPath": relative_path}
)
```

### 场景3: AI模块生成结果视频

1. **AI Processor**: 分析完成，保存结果到 `storage/result_videos/test_result.mp4`
2. **AI Processor**: 回调Backend，更新结果视频路径

```python
# 类似预处理视频的流程
result_dir = Config.get_storage_path(Config.STORAGE_RESULT_VIDEOS_SUBDIR)
result_video_path = os.path.join(result_dir, f"{task_id}_{video_stem}_result.mp4")
```

### 场景4: Frontend请求视频

1. **Frontend**: 请求 `/api/videos/{taskId}/result`
2. **Backend**: 从数据库读取 `storage/result_videos/test_result.mp4`
3. **Backend**: 转换为相对backend的路径 `../storage/result_videos/test_result.mp4`
4. **Backend**: 流式传输视频

---

## ✅ 配置完整性检查清单

### Backend (application.yaml)
- [x] `app.storage.base-path`
- [x] `app.storage.videos-subdir`
- [x] `app.storage.result-videos-subdir`
- [x] `app.storage.preprocessed-videos-subdir`
- [x] `app.storage.temp-subdir`

### Backend (Java代码)
- [x] **AnalysisTaskServiceImpl**: 使用 `base-path` + `videos-subdir`
- [x] **VideoServiceImpl**: 从数据库读取路径（无需额外配置）

### AI Processor (config.py)
- [x] `STORAGE_BASE_PATH`
- [x] `STORAGE_VIDEOS_SUBDIR`
- [x] `STORAGE_RESULT_VIDEOS_SUBDIR`
- [x] `STORAGE_PREPROCESSED_VIDEOS_SUBDIR`
- [x] `get_storage_path()` 方法

### AI Processor (实际使用)
- [ ] **TODO**: 将 `video_processor.py` 中的旧方法改为使用 `get_storage_path()`
- [x] **当前**: 使用兼容方式 `Config.PREPROCESSED_VIDEO_PATH`

---

## 🔧 建议优化（可选）

### 优化1: 统一AI模块的路径获取方式

**当前代码** (video_processor.py):
```python
preprocessed_dir = Path(Config.resolve_path(Config.PREPROCESSED_VIDEO_PATH))
```

**建议改为**:
```python
preprocessed_dir = Path(Config.get_storage_path(Config.STORAGE_PREPROCESSED_VIDEOS_SUBDIR))
```

**优点**:
- 统一配置方式
- 减少配置项重复
- 更清晰的配置结构

### 优化2: 添加路径验证

在启动时验证所有存储路径是否存在，不存在则自动创建：

```python
# config.py
@classmethod
def ensure_storage_dirs(cls):
    """确保所有存储目录存在"""
    for subdir in [cls.STORAGE_VIDEOS_SUBDIR, 
                   cls.STORAGE_RESULT_VIDEOS_SUBDIR,
                   cls.STORAGE_PREPROCESSED_VIDEOS_SUBDIR,
                   cls.STORAGE_TEMP_SUBDIR]:
        path = Path(cls.get_storage_path(subdir))
        path.mkdir(parents=True, exist_ok=True)
        print(f"✓ 存储目录已就绪: {path}")
```

---

## 📝 总结

### 配置完整性: ✅ 已完成

1. ✅ `.env.example` 中定义了所有路径配置
2. ✅ `application.yaml` 中引用了所有配置
3. ✅ `config.py` 中加载了所有配置
4. ✅ Backend Java代码使用了必要的配置（videos-subdir）
5. ✅ AI模块使用兼容方式访问所有路径

### Backend为什么不需要使用所有子目录配置？

Backend **只需要创建**上传视频的存储目录（`videos-subdir`），其他目录的文件都由AI模块创建：

- `result-videos-subdir`: AI模块创建结果视频
- `preprocessed-videos-subdir`: AI模块创建预处理视频
- `temp-subdir`: AI模块使用临时文件

Backend **只需要读取**这些路径，而路径已经由AI模块通过回调API设置到数据库中了。

### 配置使用正确吗？ ✅ 是的

当前的配置设计是合理的：
- Backend: 负责视频上传，需要 `videos-subdir`
- AI模块: 负责视频处理，需要所有子目录配置
- 路径通过数据库传递，无需重复配置

---

**文档创建时间**: 2025-10-08
