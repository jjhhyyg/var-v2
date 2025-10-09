# 文件存储逻辑修复总结

## 问题描述

最初的实现存在文件名时间戳重复的问题：

### 问题案例

1. **原始视频**: `r12粘连物_20251010_015425.mkv` ✅ 正确
2. **预处理视频**: `r12粘连物_20251010_015425_preprocessed_20251010_015427.mp4` ❌ 错误（双重时间戳）
3. **结果视频**: `102084901943115776_r12粘连物_20251010_015425_preprocessed_20251010_015427_result_20251010_015454.mp4` ❌ 错误（三重时间戳 + taskId前缀）

### 问题原因

在生成预处理视频和结果视频时，直接使用了包含时间戳的文件名作为基础名称，然后又添加了新的时间戳，导致时间戳累积。

## 解决方案

### 1. 改进时间戳提取逻辑

**文件**: `ai-processor/utils/filename_utils.py`

修改了 `extract_timestamp_from_filename` 函数的正则表达式：

```python
# 修改前：只匹配末尾的时间戳
timestamp_pattern = r'_(\d{8}_\d{6})$'

# 修改后：匹配时间戳（可能在末尾或后面还有其他内容）
timestamp_pattern = r'_(\d{8}_\d{6})(?:_|$)'
```

这样可以正确处理类似 `video_20240101_120000_preprocessed` 这样的文件名。

### 2. 新增基础名称提取函数

**新增函数**: `extract_base_name(filename, remove_suffixes=None)`

功能：提取文件的原始基础名称（去掉时间戳和指定的后缀）

```python
def extract_base_name(filename: str, remove_suffixes: list[str] | None = None) -> str:
    """
    提取文件的原始基础名称（去掉时间戳和指定的后缀）
    
    示例:
        "video_20240101_120000.mp4" -> "video"
        "video_20240101_120000_preprocessed.mp4" -> "video" (remove_suffixes=['_preprocessed'])
        "video_preprocessed_20240101_120000.mp4" -> "video" (remove_suffixes=['_preprocessed'])
    """
```

### 3. 修改预处理视频文件名生成逻辑

**文件**: `ai-processor/analyzer/video_processor.py`

```python
# 修改后的逻辑
from utils.filename_utils import add_or_update_timestamp, extract_base_name

video_stem = Path(video_path).stem
# 提取原始基础名称（去掉时间戳）
base_name = extract_base_name(video_stem)
# 添加 _preprocessed 后缀，然后添加时间戳
base_filename = f"{base_name}_preprocessed.mp4"
preprocessed_filename = Path(add_or_update_timestamp(base_filename, update_existing=True)).name
```

### 4. 修改结果视频文件名生成逻辑

**文件**: `ai-processor/mq_consumer.py`

```python
# 修改后的逻辑
from utils.filename_utils import add_or_update_timestamp, extract_base_name

video_filename = os.path.basename(analyzed_video_path)

# 提取原始基础名称（去掉时间戳和 _preprocessed 后缀）
base_name = extract_base_name(video_filename, remove_suffixes=['_preprocessed'])

# 生成结果视频文件名：基础名_result，然后添加时间戳
base_output_filename = f"{base_name}_result.mp4"
output_filename = os.path.basename(add_or_update_timestamp(base_output_filename, update_existing=True))
```

**关键改进**:

- 使用 `extract_base_name` 提取原始基础名称
- 去掉了 `task_id` 前缀，使文件名更简洁
- 避免时间戳和后缀重复

## 修复后的文件名格式

### 正确的文件名格式

1. **原始视频**: `<基础名称>_<时间戳>.<扩展名>`
   - 示例: `r12粘连物_20251010_015425.mkv`

2. **预处理视频**: `<基础名称>_preprocessed_<时间戳>.mp4`
   - 示例: `r12粘连物_preprocessed_20251010_015427.mp4`

3. **结果视频**: `<基础名称>_result_<时间戳>.mp4`
   - 示例: `r12粘连物_result_20251010_015454.mp4`

### 文件名转换流程

```
原始视频: r12粘连物_20251010_015425.mkv
    ↓ (提取基础名: r12粘连物)
预处理视频: r12粘连物_preprocessed_20251010_015427.mp4
    ↓ (提取基础名: r12粘连物，去掉 _preprocessed 和时间戳)
结果视频: r12粘连物_result_20251010_015454.mp4
```

## 测试验证

### 测试用例

```python
# 测试1: 提取时间戳（改进版）
extract_timestamp_from_filename('r12粘连物_20251010_015427_preprocessed.mp4')
# 结果: ('r12粘连物_preprocessed', '20251010_015427') ✅

# 测试2: 提取基础名称
extract_base_name('r12粘连物_20251010_015427_preprocessed.mp4', ['_preprocessed'])
# 结果: 'r12粘连物' ✅

# 测试3: 预处理视频文件名生成
base_name = extract_base_name('r12粘连物_20251010_015425.mkv')  # 'r12粘连物'
preprocessed = f"{base_name}_preprocessed.mp4"
add_or_update_timestamp(preprocessed, True)
# 结果: 'r12粘连物_preprocessed_20251010_020245.mp4' ✅

# 测试4: 结果视频文件名生成
base_name = extract_base_name('r12粘连物_preprocessed_20251010_015427.mp4', ['_preprocessed'])  # 'r12粘连物'
result = f"{base_name}_result.mp4"
add_or_update_timestamp(result, True)
# 结果: 'r12粘连物_result_20251010_020245.mp4' ✅
```

所有测试通过！✅

## 更新的文件列表

### Python 文件

1. `ai-processor/utils/filename_utils.py` - 改进时间戳提取逻辑，新增 `extract_base_name` 函数
2. `ai-processor/utils/__init__.py` - 导出新函数
3. `ai-processor/analyzer/video_processor.py` - 修改预处理视频文件名生成逻辑
4. `ai-processor/mq_consumer.py` - 修改结果视频文件名生成逻辑

### Java 文件

1. `backend/src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java` - 时间戳工具类（未变更）
2. `backend/src/main/java/ustb/hyy/app/backend/service/impl/AnalysisTaskServiceImpl.java` - 原始视频保存逻辑（未变更）

### 文档文件

1. `FILE_STORAGE_CHANGES.md` - 更新了修改说明和示例
2. `FILENAME_UTILS_README.md` - API文档（需要更新）
3. `FILE_STORAGE_FIX_SUMMARY.md` - 本文档

## 关键要点

1. **避免时间戳累积**: 始终使用 `extract_base_name` 提取原始基础名称
2. **一致的文件名格式**: 所有视频文件遵循 `<基础名称>_<后缀>_<时间戳>.<扩展名>` 的格式
3. **简洁的命名**: 移除了不必要的 `task_id` 前缀
4. **可追溯性**: 通过时间戳可以追踪文件的创建/更新时间
5. **向后兼容**: 支持处理已有的各种文件名格式

## 后续工作

- [ ] 更新 `FILENAME_UTILS_README.md` 文档，添加 `extract_base_name` 函数的说明
- [ ] 清理旧的测试视频文件（包含错误格式的文件名）
- [ ] 考虑是否需要数据库迁移脚本来更新历史路径
