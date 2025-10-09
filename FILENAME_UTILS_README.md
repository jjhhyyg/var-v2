# 文件时间戳工具使用指南

## 概述

为了避免文件名冲突并提供更好的文件可追溯性，我们为所有视频文件（原始视频、预处理视频、结果视频）的文件名添加了时间戳功能。

## 快速开始

### Python 版本（AI处理器）

```python
from utils.filename_utils import add_or_update_timestamp, generate_filename_with_timestamp

# 方法1: 直接为文件路径添加/更新时间戳
filepath = "/path/to/video.mp4"
new_filepath = add_or_update_timestamp(filepath, update_existing=True)
# 结果: /path/to/video_20241010_143000.mp4

# 方法2: 只生成带时间戳的文件名
filename = generate_filename_with_timestamp("video", ".mp4", update_existing=True)
# 结果: video_20241010_143000.mp4
```

### Java 版本（后端）

```java
import ustb.hyy.app.backend.util.FilenameUtils;

// 方法1: 直接为文件路径添加/更新时间戳
String filepath = "/path/to/video.mp4";
String newFilepath = FilenameUtils.addOrUpdateTimestamp(filepath, true);
// 结果: /path/to/video_20241010_143000.mp4

// 方法2: 只生成带时间戳的文件名
String filename = FilenameUtils.generateFilenameWithTimestamp("video", ".mp4", true);
// 结果: video_20241010_143000.mp4
```

## API 文档

### Python API

#### `generate_timestamp()`

生成当前时间戳字符串。

**返回**: `str` - 格式为 `yyyyMMdd_HHmmss` 的时间戳字符串

**示例**:

```python
timestamp = generate_timestamp()
# 返回: "20241010_143000"
```

#### `extract_timestamp_from_filename(filename)`

从文件名中提取时间戳和基础名称。

**参数**:

- `filename` (str): 文件名（可以包含或不包含扩展名）

**返回**: `tuple[str, str | None]` - (基础名称, 时间戳或None)

**示例**:

```python
base, timestamp = extract_timestamp_from_filename("video_20241010_143000.mp4")
# 返回: ("video", "20241010_143000")

base, timestamp = extract_timestamp_from_filename("video.mp4")
# 返回: ("video", None)
```

#### `generate_filename_with_timestamp(base_name, extension=".mp4", update_existing=True)`

生成带时间戳的文件名。

**参数**:

- `base_name` (str): 基础文件名（可能已包含时间戳）
- `extension` (str): 文件扩展名（默认 ".mp4"）
- `update_existing` (bool): 如果文件名已包含时间戳，是否更新（默认 True）

**返回**: `str` - 带时间戳的完整文件名

**示例**:

```python
# 添加新时间戳
filename = generate_filename_with_timestamp("video")
# 返回: "video_20241010_143000.mp4"

# 更新现有时间戳
filename = generate_filename_with_timestamp("video_20240101_120000", update_existing=True)
# 返回: "video_20241010_143000.mp4"

# 保留现有时间戳
filename = generate_filename_with_timestamp("video_20240101_120000", update_existing=False)
# 返回: "video_20240101_120000.mp4"
```

#### `add_or_update_timestamp(filepath, update_existing=True)`

为文件路径添加或更新时间戳。

**参数**:

- `filepath` (str): 完整的文件路径
- `update_existing` (bool): 如果文件名已包含时间戳，是否更新（默认 True）

**返回**: `str` - 带时间戳的完整文件路径

**示例**:

```python
# 添加时间戳
path = add_or_update_timestamp("/path/to/video.mp4")
# 返回: "/path/to/video_20241010_143000.mp4"

# 更新时间戳
path = add_or_update_timestamp("/path/to/video_20240101_120000.mp4", update_existing=True)
# 返回: "/path/to/video_20241010_143000.mp4"

# 保留原时间戳
path = add_or_update_timestamp("/path/to/video_20240101_120000.mp4", update_existing=False)
# 返回: "/path/to/video_20240101_120000.mp4"
```

### Java API

#### `generateTimestamp()`

生成当前时间戳字符串。

**返回**: `String` - 格式为 `yyyyMMdd_HHmmss` 的时间戳字符串

**示例**:

```java
String timestamp = FilenameUtils.generateTimestamp();
// 返回: "20241010_143000"
```

#### `extractTimestampFromFilename(String filename)`

从文件名中提取时间戳和基础名称。

**参数**:

- `filename` (String): 文件名（可以包含或不包含扩展名）

**返回**: `String[]` - [基础名称, 时间戳或null]

**示例**:

```java
String[] parts = FilenameUtils.extractTimestampFromFilename("video_20241010_143000.mp4");
// 返回: ["video", "20241010_143000"]

String[] parts = FilenameUtils.extractTimestampFromFilename("video.mp4");
// 返回: ["video", null]
```

#### `generateFilenameWithTimestamp(String baseName, String extension, boolean updateExisting)`

生成带时间戳的文件名。

**参数**:

- `baseName` (String): 基础文件名（可能已包含时间戳）
- `extension` (String): 文件扩展名（如 ".mp4"）
- `updateExisting` (boolean): 如果文件名已包含时间戳，是否更新

**返回**: `String` - 带时间戳的完整文件名

**示例**:

```java
// 添加新时间戳
String filename = FilenameUtils.generateFilenameWithTimestamp("video", ".mp4", true);
// 返回: "video_20241010_143000.mp4"

// 更新现有时间戳
String filename = FilenameUtils.generateFilenameWithTimestamp("video_20240101_120000", ".mp4", true);
// 返回: "video_20241010_143000.mp4"

// 保留现有时间戳
String filename = FilenameUtils.generateFilenameWithTimestamp("video_20240101_120000", ".mp4", false);
// 返回: "video_20240101_120000.mp4"
```

#### `addOrUpdateTimestamp(String filepath, boolean updateExisting)`

为文件路径添加或更新时间戳。

**参数**:

- `filepath` (String): 完整的文件路径
- `updateExisting` (boolean): 如果文件名已包含时间戳，是否更新

**返回**: `String` - 带时间戳的完整文件路径

**示例**:

```java
// 添加时间戳
String path = FilenameUtils.addOrUpdateTimestamp("/path/to/video.mp4", true);
// 返回: "/path/to/video_20241010_143000.mp4"

// 更新时间戳
String path = FilenameUtils.addOrUpdateTimestamp("/path/to/video_20240101_120000.mp4", true);
// 返回: "/path/to/video_20241010_143000.mp4"

// 保留原时间戳
String path = FilenameUtils.addOrUpdateTimestamp("/path/to/video_20240101_120000.mp4", false);
// 返回: "/path/to/video_20240101_120000.mp4"
```

## 时间戳格式说明

时间戳格式: `yyyyMMdd_HHmmss`

格式组成:

- `yyyy`: 4位年份
- `MM`: 2位月份（01-12）
- `dd`: 2位日期（01-31）
- `HH`: 2位小时（00-23，24小时制）
- `mm`: 2位分钟（00-59）
- `ss`: 2位秒数（00-59）

示例: `20241010_143025` 表示 2024年10月10日 14:30:25

## 实际应用场景

### 1. 上传原始视频（后端）

```java
// AnalysisTaskServiceImpl.java
private String saveVideoFile(MultipartFile video) {
    String originalFilename = video.getOriginalFilename();
    // 添加或更新时间戳
    String filename = FilenameUtils.addOrUpdateTimestamp(originalFilename, true);
    // 保存文件...
}
```

### 2. 生成预处理视频（AI处理器）

```python
# video_processor.py
from utils.filename_utils import add_or_update_timestamp

video_stem = Path(video_path).stem
base_filename = f"{video_stem}_preprocessed.mp4"
# 添加或更新时间戳
preprocessed_filename = Path(add_or_update_timestamp(base_filename, update_existing=True)).name
```

### 3. 生成结果视频（AI处理器）

```python
# mq_consumer.py
from utils.filename_utils import add_or_update_timestamp

video_filename = os.path.basename(analyzed_video_path)
name_without_ext = os.path.splitext(video_filename)[0]
base_output_filename = f"{task_id}_{name_without_ext}_result.mp4"
# 添加或更新时间戳
output_filename = os.path.basename(add_or_update_timestamp(base_output_filename, update_existing=True))
```

## 测试

### Python 工具测试

```bash
cd ai-processor
python utils/filename_utils.py
```

### Java 工具测试

创建测试类并运行：

```bash
cd backend
# 编译
javac -d target/test-classes -cp target/classes \
  src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java \
  src/main/java/ustb/hyy/app/backend/util/FilenameUtilsTest.java

# 运行
java -cp target/test-classes:target/classes \
  ustb.hyy.app.backend.util.FilenameUtilsTest
```

## 常见问题

### Q: 为什么要添加时间戳？

A: 时间戳可以：

1. 防止同名文件覆盖
2. 提供文件的创建/更新时间信息
3. 方便文件版本管理和追溯

### Q: 如果文件名已经有时间戳会怎样？

A: 取决于 `update_existing` 参数：

- `true`: 更新为当前时间戳
- `false`: 保留原有时间戳

### Q: 会影响已有的文件吗？

A: 不会。已有的文件保持不变，只有新创建的文件会添加时间戳。

### Q: 数据库中的路径会改变吗？

A: 是的，新保存的文件路径会包含时间戳。但前端可以正常访问，因为完整路径会存储在数据库中。

## 注意事项

1. **时间精度**: 时间戳精确到秒级，如果在1秒内多次调用可能会生成相同的时间戳
2. **跨时区**: 时间戳使用服务器本地时间，不考虑时区转换
3. **文件查找**: 如需根据原始文件名查找，应使用 `extract_timestamp_from_filename` 提取基础名称后再查找

## 相关文件

- Python工具: `ai-processor/utils/filename_utils.py`
- Java工具: `backend/src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java`
- 修改说明: `FILE_STORAGE_CHANGES.md`
