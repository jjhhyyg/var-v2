# Docker 基础镜像

本目录包含项目使用的自定义 Docker 基础镜像。

## 基础镜像列表

### 1. Java + FFmpeg 基础镜像 (`var-base-java-ffmpeg:21`)

**文件**: `Dockerfile.java-ffmpeg`

**用途**: 用于后端服务，提供 Java 21 JRE + FFmpeg 环境

**包含组件**:

- Eclipse Temurin 21 JRE (Alpine)
- FFmpeg (用于 JavaCV 视频元数据解析)
- curl (用于健康检查)

**使用场景**:

- 后端需要使用 JavaCV 的 `FFmpegFrameGrabber` 解析视频元数据（时长、帧率、分辨率等）

**构建命令**:

```bash
docker build -f docker/base/Dockerfile.java-ffmpeg -t var-base-java-ffmpeg:21 docker/base
```

## 为什么使用基础镜像？

### 优势

1. **避免重复**: 统一管理 FFmpeg 等依赖的安装
2. **一致性**: 确保所有服务使用相同版本的依赖
3. **构建效率**: 基础镜像可以缓存，加快后续构建速度
4. **易于维护**: 依赖升级只需修改基础镜像

### 设计原则

- **最小化**: 只安装必需的依赖
- **按需创建**: 只为确实需要的服务创建基础镜像
- **版本明确**: 使用明确的版本标签

## 依赖说明

### 后端 (Backend)

- ✅ **需要 FFmpeg**: 使用 JavaCV 解析视频文件
- 使用基础镜像: `var-base-java-ffmpeg:21`

### AI 处理器 (AI-processor)

- ❌ **不需要 FFmpeg**: 使用 OpenCV (cv2) 处理视频，OpenCV 自带编解码功能
- 使用基础镜像: `python:3.13-slim` (官方镜像)

## 维护指南

### 更新基础镜像

1. 修改对应的 Dockerfile
2. 重新构建基础镜像
3. 重新构建使用该基础镜像的服务

### 添加新的基础镜像

1. 在 `docker/base/` 目录创建新的 Dockerfile
2. 使用命名规范: `Dockerfile.<用途>-<主要依赖>`
3. 更新本 README 文档

## 镜像大小优化

### Alpine vs Debian

- **Alpine**: 更小 (~5-50MB)，适合 Java 等编译型语言
- **Debian Slim**: 中等 (~100-150MB)，兼容性更好，适合 Python

### 最佳实践

- 使用 `--no-cache-dir` (pip) 或 `--no-cache` (apk)
- 清理包管理器缓存 (`rm -rf /var/lib/apt/lists/*`)
- 合并 RUN 命令减少层数
- 使用 `.dockerignore` 排除不需要的文件
