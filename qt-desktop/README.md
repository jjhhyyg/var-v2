# VAR熔池分析系统 - Qt桌面应用

基于 Qt 6 的桌面客户端，采用混合架构设计，嵌入现有的 Web 前端和后端服务。

## 架构设计

```
Qt 桌面应用
├── Qt Widgets 主窗口框架
├── Qt WebEngineView (嵌入 Nuxt 前端)
├── 服务管理器
│   ├── Spring Boot 后端服务
│   └── Python AI 处理引擎
└── 系统托盘 + 菜单
```

## 技术栈

- **UI框架**: Qt 6 Widgets + Qt WebEngine
- **构建系统**: CMake 3.16+
- **编译器**: C++17 标准
- **嵌入服务**:
  - Backend: Spring Boot (GraalVM Native Image)
  - AI Processor: Python (PyInstaller)

## 开发环境要求

### 必需工具

1. **Qt 6.5+**
   ```bash
   # macOS (使用 Homebrew)
   brew install qt@6

   # 或从官方下载安装器
   # https://www.qt.io/download-qt-installer
   ```

2. **CMake 3.16+**
   ```bash
   brew install cmake
   ```

3. **C++ 编译器**
   - macOS: Xcode Command Line Tools
   - Windows: MSVC 2019+ 或 MinGW
   - Linux: GCC 9+ 或 Clang 10+

### 可选工具

- Qt Creator (推荐，用于 UI 设计和调试)
- Ninja 构建系统 (更快的构建速度)

## 构建步骤

### 1. 配置项目

```bash
cd qt-desktop
mkdir build && cd build

# 配置 CMake
cmake .. -DCMAKE_PREFIX_PATH=/opt/homebrew/opt/qt@6

# 或使用 Qt Creator 自带的 CMake
```

### 2. 编译

```bash
# 使用 make
make -j$(nproc)

# 或使用 ninja
cmake --build . --parallel
```

### 3. 运行

```bash
# 直接运行
./bin/VAR-PoolAnalysis

# 或使用 Qt Creator 的运行按钮
```

## 项目结构

```
qt-desktop/
├── CMakeLists.txt              # 项目构建配置
├── src/
│   ├── main.cpp                # 程序入口
│   ├── mainwindow.h/cpp/ui     # 主窗口
│   └── servicemanager.h/cpp    # 服务管理器
├── resources/
│   ├── resources.qrc           # Qt 资源文件
│   ├── icons/                  # 应用图标
│   └── images/                 # 图片资源
├── installer/
│   ├── nsis/                   # Windows 安装包配置
│   └── scripts/                # 打包脚本
└── build/                      # 构建输出目录（git忽略）
```

## 核心功能

### 1. 服务管理器 (ServiceManager)

负责管理后端服务和 AI 引擎的生命周期：

- **启动管理**: 自动启动嵌入的服务进程
- **健康监控**: 定期检查服务健康状态
- **崩溃恢复**: 自动重启崩溃的服务
- **日志收集**: 收集服务日志用于调试

### 2. 主窗口 (MainWindow)

提供用户界面和交互：

- **Web 视图**: 嵌入 Nuxt 前端页面
- **系统托盘**: 支持最小化到托盘，后台运行
- **菜单系统**: 文件、服务、帮助菜单
- **状态显示**: 实时显示服务状态

### 3. 资源管理

- 图标和图片资源嵌入
- 应用程序图标设置
- 多分辨率支持

## 打包部署

### Windows

使用 NSIS 创建安装包：

```bash
cd installer/scripts
./build-windows.sh
```

### macOS

创建 DMG 安装包：

```bash
cd installer/scripts
./build-macos.sh
```

### Linux

创建 AppImage：

```bash
cd installer/scripts
./build-linux.sh
```

## 开发指南

### 添加新功能

1. 在 `src/` 下创建新的类文件
2. 在 `CMakeLists.txt` 中添加源文件
3. 使用 Qt 信号/槽机制进行通信

### 修改 UI

1. 使用 Qt Designer 编辑 `.ui` 文件
2. 或直接在代码中使用 Qt Widgets API
3. 重新构建项目

### 调试

```bash
# 启用调试模式
cmake .. -DCMAKE_BUILD_TYPE=Debug

# 使用 Qt Creator 的调试器
# 或使用 gdb/lldb
```

## 下一步计划

- [ ] 完善服务健康检查机制
- [ ] 添加配置管理界面
- [ ] 实现自动更新功能
- [ ] 优化启动速度
- [ ] 添加日志查看器
- [ ] 完善安装包构建脚本

## 常见问题

### 1. Qt 找不到

确保设置了正确的 `CMAKE_PREFIX_PATH`:

```bash
export CMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/clang_64
```

### 2. WebEngine 不可用

确保安装了 Qt WebEngine 模块：

```bash
# 使用 Qt Maintenance Tool 安装 WebEngine
```

### 3. 服务启动失败

检查嵌入的服务可执行文件路径是否正确。

## 许可证

遵循主项目的 AGPL-3.0 许可证。

---

**开发中** - 当前版本：v0.1.0-alpha
