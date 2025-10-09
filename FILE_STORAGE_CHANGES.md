# 文件存储逻辑修改说明

## 修改概述

本次修## 文件名示例

### 原始视频

- 修改前: `video.mp4`
- 修改后: `video_20241010_143000.mp4`

### 预处理视频

- 修改前: `video_preprocessed.mp4`
- 修改后: `video_preprocessed_20241010_143030.mp4`
  
注：格式为 `<基础名称>_preprocessed_<时间戳>.mp4`

### 结果视频

- 修改前: `102084901943115776_r13粘连物_preprocessed_result.mp4`
- 修改后: `r13粘连物_result_20241010_143100.mp4`
  
注：格式为 `<基础名称>_result_<时间戳>.mp4`（基础名称会去掉原视频的时间戳和预处理后缀）所有视频文件（原始视频、预处理视频、结果视频）都包含时间戳。

## 修改前的逻辑

- **原始视频**: 不添加时间戳
- **预处理视频**: 不添加时间戳
- **结果视频**: 添加任务ID作为前缀（如 `{taskId}_xxx_result.mp4`）

## 修改后的逻辑

- **原始视频**: 如果没有时间戳则添加，如果有则更新
- **预处理视频**: 如果没有时间戳则添加，如果有则更新
- **结果视频**: 如果没有时间戳则添加，如果有则更新

## 时间戳格式

时间戳格式为：`yyyyMMdd_HHmmss`

示例：

- `20241010_143000` 表示 2024年10月10日 14:30:00

## 文件名示例

### 原始视频

- 修改前: `video.mp4`
- 修改后: `video_20241010_143000.mp4`

### 预处理视频

- 修改前: `video_preprocessed.mp4`
- 修改后: `video_preprocessed_20241010_143030.mp4`

### 结果视频

- 修改前: `102084901943115776_r13粘连物_preprocessed_result.mp4`
- 修改后: `102084901943115776_r13粘连物_preprocessed_result_20241010_143100.mp4`

## 新增文件

### 1. Python工具模块

**文件**: `ai-processor/utils/filename_utils.py`

提供以下功能函数：

- `generate_timestamp()`: 生成当前时间戳字符串
- `extract_timestamp_from_filename(filename)`: 从文件名中提取时间戳和基础名称（改进版，支持时间戳后还有内容的情况）
- `extract_base_name(filename, remove_suffixes)`: 提取原始基础名称（去掉时间戳和指定后缀）**[新增]**
- `generate_filename_with_timestamp(base_name, extension, update_existing)`: 生成带时间戳的文件名
- `add_or_update_timestamp(filepath, update_existing)`: 为文件路径添加或更新时间戳

### 2. Java工具类

**文件**: `backend/src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java`

提供以下功能方法：

- `generateTimestamp()`: 生成当前时间戳字符串
- `extractTimestampFromFilename(String filename)`: 从文件名中提取时间戳和基础名称
- `generateFilenameWithTimestamp(String baseName, String extension, boolean updateExisting)`: 生成带时间戳的文件名
- `addOrUpdateTimestamp(String filepath, boolean updateExisting)`: 为文件路径添加或更新时间戳

## 修改的文件

### 1. 后端 - 原始视频保存

**文件**: `backend/src/main/java/ustb/hyy/app/backend/service/impl/AnalysisTaskServiceImpl.java`

**修改位置**: `saveVideoFile` 方法

**修改内容**:

```java
// 修改前
String filename = video.getOriginalFilename();

// 修改后
String originalFilename = video.getOriginalFilename();
String filename = ustb.hyy.app.backend.util.FilenameUtils.addOrUpdateTimestamp(
    originalFilename, true  // updateExisting=true 表示如果已有时间戳则更新
);
```

### 2. AI处理器 - 预处理视频保存

**文件**: `ai-processor/analyzer/video_processor.py`

**修改位置**: `analyze_video_task` 方法中的预处理部分

**修改内容**:

```python
# 修改前
video_stem = Path(video_path).stem
preprocessed_filename = f"{video_stem}_preprocessed.mp4"

# 修改后
from utils.filename_utils import add_or_update_timestamp, extract_base_name

video_stem = Path(video_path).stem
# 提取原始基础名称（去掉时间戳）
base_name = extract_base_name(video_stem)
# 添加 _preprocessed 后缀，然后添加时间戳
base_filename = f"{base_name}_preprocessed.mp4"
preprocessed_filename = Path(add_or_update_timestamp(base_filename, update_existing=True)).name
```

**关键改进**: 使用 `extract_base_name` 提取原始基础名称，避免时间戳重复

### 3. AI处理器 - 结果视频保存

**文件**: `ai-processor/mq_consumer.py`

**修改位置**: `process_task` 方法中的结果视频生成部分

**修改内容**:

```python
# 修改前
video_filename = os.path.basename(analyzed_video_path)
name_without_ext = os.path.splitext(video_filename)[0]
output_filename = f"{task_id}_{name_without_ext}_result.mp4"

# 修改后
from utils.filename_utils import add_or_update_timestamp, extract_base_name

video_filename = os.path.basename(analyzed_video_path)

# 提取原始基础名称（去掉时间戳和 _preprocessed 后缀）
base_name = extract_base_name(video_filename, remove_suffixes=['_preprocessed'])

# 生成结果视频文件名：基础名_result，然后添加时间戳
base_output_filename = f"{base_name}_result.mp4"
output_filename = os.path.basename(add_or_update_timestamp(base_output_filename, update_existing=True))
```

**关键改进**:

1. 使用 `extract_base_name` 提取原始基础名称，去掉时间戳和 `_preprocessed` 后缀
2. 移除了 `task_id` 前缀，使文件名更简洁
3. 避免时间戳和后缀重复

## 工具函数使用说明

### Python版本

```python
from utils.filename_utils import add_or_update_timestamp

# 为文件添加时间戳（如果没有）
filename = add_or_update_timestamp("video.mp4", update_existing=False)
# 结果: video_20241010_143000.mp4

# 更新已有时间戳
filename = add_or_update_timestamp("video_20240101_120000.mp4", update_existing=True)
# 结果: video_20241010_143000.mp4 (时间戳被更新为当前时间)
```

### Java版本

```java
import ustb.hyy.app.backend.util.FilenameUtils;

// 为文件添加时间戳（如果没有）
String filename = FilenameUtils.addOrUpdateTimestamp("video.mp4", false);
// 结果: video_20241010_143000.mp4

// 更新已有时间戳
String filename = FilenameUtils.addOrUpdateTimestamp("video_20240101_120000.mp4", true);
// 结果: video_20241010_143000.mp4 (时间戳被更新为当前时间)
```

## 影响分析

### 优点

1. **唯一性**: 时间戳确保了文件名的唯一性，避免了同名文件覆盖的问题
2. **可追溯性**: 通过时间戳可以快速识别文件的创建或更新时间
3. **一致性**: 所有视频文件都采用统一的命名规范

### 注意事项

1. **数据库路径**: 数据库中存储的路径会包含时间戳，需要确保前端能正确处理
2. **历史数据**: 之前存储的没有时间戳的文件仍然可以正常使用，但新上传的文件都会包含时间戳
3. **文件查找**: 如果需要根据原始文件名查找文件，需要使用模糊匹配或提取基础名称后再查找

## 测试

### Python工具测试

```bash
cd ai-processor
python utils/filename_utils.py
```

### Java工具测试

```bash
cd backend
javac -d target/test-classes -cp target/classes src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java src/main/java/ustb/hyy/app/backend/util/FilenameUtilsTest.java
java -cp target/test-classes:target/classes ustb.hyy.app.backend.util.FilenameUtilsTest
```

## 兼容性

本修改向后兼容，对于已有的不带时间戳的文件路径，系统仍然可以正常访问和处理。只是新创建的文件会自动添加时间戳。
