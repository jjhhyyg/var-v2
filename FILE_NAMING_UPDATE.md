# 文件命名更新 - UUID_时间戳格式

## 更新日期
2025-10-13

## 问题描述

原先上传的文件名称现在是空的，存储到数据库中的也是空的。需要创建分析任务时：
1. 将真实文件名保存至数据库中
2. 真实保存的文件转为 `UUID_时间戳` 的方式存储（添加时间字符串的逻辑不变，但原文件名改为UUID）

## 解决方案

### 1. 数据库层面

**修改文件**: `backend/src/main/java/ustb/hyy/app/backend/domain/entity/AnalysisTask.java`

- 添加了新字段 `originalFilename` 用于存储用户上传的真实文件名
- 该字段可为空，长度限制为255字符

```java
/**
 * 原始文件名（用户上传时的真实文件名）
 */
@Column(length = 255)
private String originalFilename;
```

### 2. 文件命名工具

**修改文件**: `backend/src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java`

- 添加了 UUID 依赖
- 新增 `generateUuidFilename()` 方法，生成 UUID_timestamp 格式的文件名

```java
/**
 * 生成基于UUID和时间戳的文件名
 *
 * @param originalFilename 原始文件名（用于提取扩展名）
 * @return UUID_timestamp.extension 格式的文件名
 *
 * 示例:
 *   generateUuidFilename("video.mp4")
 *   -> "a1b2c3d4-e5f6-7890-abcd-ef1234567890_20240101_120000.mp4"
 */
public static String generateUuidFilename(String originalFilename)
```

### 3. 服务层面

**修改文件**: `backend/src/main/java/ustb/hyy/app/backend/service/impl/AnalysisTaskServiceImpl.java`

#### 3.1 新增内部类 SaveVideoResult

用于返回保存结果，包含存储路径和原始文件名：

```java
private static class SaveVideoResult {
    String videoPath;
    String originalFilename;

    SaveVideoResult(String videoPath, String originalFilename) {
        this.videoPath = videoPath;
        this.originalFilename = originalFilename;
    }
}
```

#### 3.2 修改 saveVideoFile() 方法

- 更改返回类型从 `String` 到 `SaveVideoResult`
- 保存原始文件名信息
- 使用 `FilenameUtils.generateUuidFilename()` 生成 UUID_timestamp 格式的文件名
- 添加空文件名的容错处理

```java
// 获取原始文件名
String originalFilename = video.getOriginalFilename();
if (originalFilename == null || originalFilename.isEmpty()) {
    originalFilename = "unknown.mp4";
}

// 使用UUID_timestamp格式命名文件
String filename = ustb.hyy.app.backend.util.FilenameUtils.generateUuidFilename(originalFilename);
```

#### 3.3 修改 uploadTask() 方法

- 使用新的 `SaveVideoResult` 获取保存结果
- 将原始文件名保存到数据库的 `originalFilename` 字段

```java
// 2. 保存视频文件
SaveVideoResult saveResult = saveVideoFile(video);
String videoPath = saveResult.videoPath;
String originalFilename = saveResult.originalFilename;

// ...

// 5. 创建任务
AnalysisTask task = AnalysisTask.builder()
        .name(Optional.ofNullable(request.getName()).orElse(originalFilename))
        .originalFilename(originalFilename)  // 保存原始文件名
        .videoPath(videoPath)
        // ...
        .build();
```

#### 3.4 修改 buildTaskResponse() 方法

- 添加 `originalFilename` 到响应对象

```java
return TaskResponse.builder()
        .taskId(String.valueOf(task.getId()))
        .name(task.getName())
        .originalFilename(task.getOriginalFilename())  // 添加原始文件名
        // ...
        .build();
```

### 4. DTO层面

**修改文件**: `backend/src/main/java/ustb/hyy/app/backend/dto/response/TaskResponse.java`

- 添加 `originalFilename` 字段到响应 DTO

```java
/**
 * 原始文件名（用户上传时的真实文件名）
 */
private String originalFilename;
```

### 5. 前端接口

**修改文件**: `frontend/app/composables/useTaskApi.ts`

- 在 `Task` 接口中添加 `originalFilename` 字段

```typescript
export interface Task {
  taskId: string
  name: string
  originalFilename?: string // 原始文件名（用户上传时的真实文件名）
  videoDuration: number
  // ...
}
```

## 文件命名格式对比

### 修改前
```
原始文件: video.mp4
保存文件: video_20241013_153045.mp4
数据库中: name = "video.mp4" (或为空)
```

### 修改后
```
原始文件: video.mp4
保存文件: a1b2c3d4-e5f6-7890-abcd-ef1234567890_20241013_153045.mp4
数据库中:
  - name = "video.mp4" (任务名称)
  - originalFilename = "video.mp4" (原始文件名)
  - videoPath = "storage/videos/a1b2c3d4-e5f6-7890-abcd-ef1234567890_20241013_153045.mp4"
```

## 优势

1. **唯一性保证**: UUID 确保文件名全局唯一，避免文件名冲突
2. **时间追溯**: 保留时间戳，方便查看文件创建时间
3. **原始信息保留**: 数据库中保存原始文件名，便于用户识别
4. **安全性提升**: 避免原始文件名中的特殊字符或路径遍历攻击
5. **系统隔离**: 存储文件名与用户提供的文件名隔离，提高系统安全性

## 数据库迁移

已创建 Flyway 迁移脚本：`backend/src/main/resources/db/migration/V11__add_original_filename.sql`

该脚本会自动在应用启动时执行，添加 `original_filename` 字段：

```sql
ALTER TABLE analysis_tasks ADD COLUMN IF NOT EXISTS original_filename VARCHAR(255);
```

对于已存在的记录，`original_filename` 将为 NULL，不影响现有功能。
如果需要为旧数据填充该字段，可以手动执行脚本中注释的 UPDATE 语句。

## 后续建议

1. **前端展示**: 在任务列表和详情页面展示 `originalFilename`，让用户能看到原始文件名
2. **下载功能**: 导出结果视频时，可以使用原始文件名作为下载文件名
3. **搜索功能**: 支持按原始文件名搜索任务
4. **文件清理**: 定期清理过期的视频文件时，可以根据时间戳进行过滤

## 影响范围

### 后端修改
- ✅ Entity: `AnalysisTask.java`
- ✅ Util: `FilenameUtils.java`
- ✅ Service: `AnalysisTaskServiceImpl.java`
- ✅ DTO: `TaskResponse.java`

### 前端修改
- ✅ Interface: `useTaskApi.ts`

### 数据库修改
- ✅ **Flyway 迁移脚本**: `V11__add_original_filename.sql` (应用启动时自动执行)

## 测试建议

1. **上传测试**: 测试上传不同格式的视频文件
2. **文件名测试**: 测试包含特殊字符、中文、空格的文件名
3. **空文件名测试**: 测试 `originalFilename` 为 null 的情况
4. **并发测试**: 测试同时上传多个同名文件，确认 UUID 的唯一性
5. **兼容性测试**: 测试旧数据（没有 originalFilename）的兼容性

## 相关文件清单

### 修改的文件
- `backend/src/main/java/ustb/hyy/app/backend/domain/entity/AnalysisTask.java`
- `backend/src/main/java/ustb/hyy/app/backend/util/FilenameUtils.java`
- `backend/src/main/java/ustb/hyy/app/backend/service/impl/AnalysisTaskServiceImpl.java`
- `backend/src/main/java/ustb/hyy/app/backend/dto/response/TaskResponse.java`
- `frontend/app/composables/useTaskApi.ts`

### 新增的文件
- `backend/src/main/resources/db/migration/V11__add_original_filename.sql`
- `FILE_NAMING_UPDATE.md`（本文件）
