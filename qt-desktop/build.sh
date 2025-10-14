#!/bin/bash
# Qt桌面应用构建脚本

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  VAR熔池分析系统 - Qt桌面应用构建${NC}"
echo -e "${GREEN}========================================${NC}\n"

# 检测操作系统
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    MINGW*)     PLATFORM=Windows;;
    *)          PLATFORM="UNKNOWN:${OS}"
esac

echo -e "${YELLOW}检测到平台: ${PLATFORM}${NC}\n"

# 查找Qt安装路径
QT_PATH=""
if [ "$PLATFORM" = "Mac" ]; then
    # macOS上常见的Qt安装位置
    QT_PATHS=(
        "/opt/homebrew/opt/qt@6"
        "/usr/local/opt/qt@6"
        "$HOME/Qt/6.5.3/macos"
        "$HOME/Qt/6.6.0/macos"
    )

    for path in "${QT_PATHS[@]}"; do
        if [ -d "$path" ]; then
            QT_PATH="$path"
            echo -e "${GREEN}找到Qt: $QT_PATH${NC}"
            break
        fi
    done
fi

if [ -z "$QT_PATH" ]; then
    echo -e "${YELLOW}未找到Qt，请手动指定CMAKE_PREFIX_PATH${NC}"
    read -p "请输入Qt安装路径 (或按Enter跳过): " USER_QT_PATH
    if [ -n "$USER_QT_PATH" ]; then
        QT_PATH="$USER_QT_PATH"
    fi
fi

# 创建构建目录
BUILD_DIR="build"
if [ -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}清理旧的构建目录...${NC}"
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# 配置CMake
echo -e "\n${GREEN}配置CMake...${NC}"
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release"

if [ -n "$QT_PATH" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_PREFIX_PATH=$QT_PATH"
fi

cmake .. $CMAKE_ARGS

if [ $? -ne 0 ]; then
    echo -e "${RED}CMake配置失败！${NC}"
    exit 1
fi

# 编译
echo -e "\n${GREEN}编译项目...${NC}"
cmake --build . --parallel $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

if [ $? -ne 0 ]; then
    echo -e "${RED}编译失败！${NC}"
    exit 1
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  构建成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n可执行文件位置: ${YELLOW}$BUILD_DIR/bin/VAR-PoolAnalysis${NC}\n"
echo -e "运行命令: ${YELLOW}cd $BUILD_DIR && ./bin/VAR-PoolAnalysis${NC}\n"
