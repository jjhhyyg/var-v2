#!/bin/bash
# VAR熔池视频分析系统 - 一键部署脚本

set -e  # 遇到错误立即退出

# 脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 检查Docker是否安装
check_docker() {
    print_info "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装，请先安装Docker"
        exit 1
    fi

    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi

    print_success "Docker环境检查通过"
}

# 检查环境配置文件
check_env_file() {
    print_info "检查环境配置文件..."
    if [ ! -f ".env" ]; then
        print_warning ".env文件不存在，正在从.env.example创建..."
        if [ ! -f ".env.example" ]; then
            print_error ".env.example文件不存在"
            exit 1
        fi
        cp .env.example .env
        print_warning "请编辑.env文件，配置数据库密码、Redis密码等敏感信息"
        read -p "是否现在编辑.env文件？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-vi} .env
        else
            print_warning "请稍后手动编辑.env文件后再运行部署脚本"
            exit 0
        fi
    fi
    print_success "环境配置文件检查通过"
}

# 检查模型文件
check_model_file() {
    print_info "检查AI模型文件..."
    MODEL_PATH=$(grep "YOLO_MODEL_PATH=" .env | cut -d '=' -f2)
    MODEL_PATH=${MODEL_PATH:-weights/best.pt}

    # 检查ai-processor目录下的模型路径
    FULL_MODEL_PATH="ai-processor/${MODEL_PATH}"

    if [ ! -f "$FULL_MODEL_PATH" ]; then
        print_warning "模型文件 ${FULL_MODEL_PATH} 不存在"
        print_warning "首次运行时会自动下载预训练模型（yolo11n）"
        print_warning "如需使用自定义模型，请将模型文件放置在：${FULL_MODEL_PATH}"
    else
        print_success "模型文件检查通过"
    fi
}

# 检查配置文件
check_config_files() {
    print_info "检查配置文件..."

    # 检查botsort配置
    if [ ! -f "ai-processor/botsort.yaml" ]; then
        print_warning "ai-processor/botsort.yaml不存在，将使用Ultralytics默认配置"
    fi

    # 检查nginx配置
    if [ ! -f "nginx/nginx.conf" ]; then
        print_error "nginx/nginx.conf不存在"
        exit 1
    fi

    print_success "配置文件检查通过"
}

# 构建镜像
build_images() {
    print_header "开始构建Docker镜像"

    print_info "构建后端镜像..."
    docker compose build backend
    print_success "后端镜像构建完成"

    print_info "构建AI处理模块镜像..."
    docker compose build ai-processor
    print_success "AI处理模块镜像构建完成"

    print_info "构建前端镜像..."
    docker compose build frontend
    print_success "前端镜像构建完成"

    print_success "所有镜像构建完成"
}

# 启动服务
start_services() {
    print_header "启动服务"

    print_info "启动所有服务..."
    docker compose up -d

    print_info "等待服务启动..."
    sleep 5

    print_success "服务启动完成"
}

# 检查服务健康状态
check_health() {
    print_header "检查服务健康状态"

    print_info "等待服务健康检查..."

    MAX_WAIT=180  # 最多等待3分钟
    ELAPSED=0
    INTERVAL=5

    while [ $ELAPSED -lt $MAX_WAIT ]; do
        # 检查所有服务是否都健康
        UNHEALTHY=$(docker compose ps --format json | jq -r '.[] | select(.Health != "healthy") | .Service' 2>/dev/null || true)

        if [ -z "$UNHEALTHY" ]; then
            print_success "所有服务健康检查通过"
            return 0
        fi

        print_info "等待服务启动中... (${ELAPSED}s/${MAX_WAIT}s)"
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
    done

    print_warning "部分服务健康检查超时，请检查日志"
    docker compose ps
    return 1
}

# 显示服务状态
show_status() {
    print_header "服务状态"
    docker compose ps

    echo ""
    print_header "访问信息"
    echo -e "${GREEN}系统访问地址:${NC} http://localhost:8086"
    echo -e "${GREEN}RabbitMQ管理界面:${NC} http://localhost:15672"
    echo -e "  用户名: \$(grep RABBITMQ_USER .env | cut -d '=' -f2)"
    echo -e "  密码: \$(grep RABBITMQ_PASSWORD .env | cut -d '=' -f2)"
    echo ""
    print_info "使用以下命令查看日志："
    echo "  docker compose logs -f [服务名]"
    echo ""
    print_info "使用以下命令停止服务："
    echo "  docker compose down"
}

# 显示帮助信息
show_help() {
    echo "VAR熔池视频分析系统 - 部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  deploy        完整部署（检查环境、构建镜像、启动服务）"
    echo "  build         仅构建镜像"
    echo "  start         仅启动服务"
    echo "  stop          停止服务"
    echo "  restart       重启服务"
    echo "  status        查看服务状态"
    echo "  logs [服务名]  查看日志"
    echo "  clean         清理所有容器、镜像和数据卷（危险操作）"
    echo "  help          显示此帮助信息"
    echo ""
}

# 停止服务
stop_services() {
    print_header "停止服务"
    docker compose down
    print_success "服务已停止"
}

# 重启服务
restart_services() {
    print_header "重启服务"
    docker compose restart
    print_success "服务已重启"
}

# 查看日志
view_logs() {
    SERVICE=$1
    if [ -z "$SERVICE" ]; then
        docker compose logs -f
    else
        docker compose logs -f "$SERVICE"
    fi
}

# 清理所有资源
clean_all() {
    print_warning "此操作将删除所有容器、镜像、数据卷和网络"
    read -p "确定要继续吗？(yes/no) " -r
    echo
    if [[ $REPLY == "yes" ]]; then
        print_info "停止并删除所有容器..."
        docker compose down -v

        print_info "删除镜像..."
        docker compose down --rmi all

        print_success "清理完成"
    else
        print_info "已取消清理操作"
    fi
}

# 完整部署流程
full_deploy() {
    print_header "VAR熔池视频分析系统 - 开始部署"

    check_docker
    check_env_file
    check_model_file
    check_config_files
    build_images
    start_services
    check_health
    show_status

    print_success "部署完成！"
}

# 主函数
main() {
    case "${1:-deploy}" in
        deploy)
            full_deploy
            ;;
        build)
            check_docker
            build_images
            ;;
        start)
            check_docker
            start_services
            check_health
            show_status
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            view_logs "$2"
            ;;
        clean)
            clean_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
