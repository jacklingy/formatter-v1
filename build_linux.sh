#!/bin/bash

# Linux 打包脚本 - 文档格式一键转换器 V1.1
# 使用方法：chmod +x build_linux.sh && ./build_linux.sh

set -e

echo "╔══════════════════════════════════════════════╗"
echo "║   文档格式一键转换器 V1.1 - Linux 打包工具     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[信息]${NC} $1"; }
log_success() { echo -e "${GREEN}[成功]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
log_error() { echo -e "${RED}[错误]${NC} $1"; }

# 检查Python3
log_info "检查Python3环境..."
if ! command -v python3 &> /dev/null; then
    log_error "未检测到Python3"
    echo ""
    echo "请安装Python3："
    echo "  Ubuntu/Debian: sudo apt update && sudo apt install python3 python3-pip python3-tk"
    echo "  CentOS/RHEL:   sudo yum install python3 python3-pip tkinter"
    echo "  Arch Linux:    sudo pacman -S python python-pip tk"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}')
log_success "Python版本: $PYTHON_VERSION"

# 检查tkinter
log_info "检查tkinter GUI支持..."
if ! python3 -c "import tkinter" 2>/dev/null; then
    log_error "tkinter未安装（GUI界面必需）"
    echo ""
    echo "请安装tkinter："
    echo "  Ubuntu/Debian: sudo apt install python3-tk"
    echo "  CentOS/RHEL:   sudo yum install tkinter"
    echo "  Fedora:        sudo dnf install python3-tkinter"
    echo "  Arch Linux:    sudo pacman -S tk"
    exit 1
fi
log_success "tkinter已安装"

# 检查pip
if ! command -v pip3 &> /dev/null; then
    log_info "安装pip..."
    if command -v apt-get &> /dev/null; then
        sudo apt install -y python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip
    else
        log_error "无法自动安装pip，请手动安装"
        exit 1
    fi
fi

# 安装依赖
log_info "安装Python依赖包..."
pip3 install --user -r requirements.txt -q
if [ $? -ne 0 ]; then
    log_warn "尝试使用sudo安装依赖..."
    sudo pip3 install -r requirements.txt -q
fi
log_success "依赖包安装完成"

# 检查PyInstaller
log_info "检查PyInstaller..."
if ! command -v pyinstaller &> /dev/null; then
    log_info "安装PyInstaller..."
    pip3 install --user pyinstaller -q
fi
log_success "PyInstaller就绪"

# 开始打包
log_info "开始打包可执行文件..."
echo "这可能需要2-5分钟时间，请耐心等待..."
echo ""

# 使用单文件模式打包（推荐）
pyinstaller \
    --onefile \
    --windowed \
    --name "文档格式一键转换器 V1.1" \
    --noconfirm \
    main.py

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║              ✅ 打包成功！                  ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    
    EXE_PATH="dist/文档格式一键转换器 V1.1"
    
    if [ -f "$EXE_PATH" ]; then
        FILE_SIZE=$(du -h "$EXE_PATH" | cut -f1)
        log_success "可执行文件：$(realpath $EXE_PATH)"
        log_success "文件大小：$FILE_SIZE"
        echo ""
        
        # 添加执行权限
        chmod +x "$EXE_PATH"
        log_success "已添加执行权限"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 使用方法："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  方式1：直接运行"
    echo "    cd dist"
    echo "    ./文档格式一键转换器V1"
    echo ""
    echo "  方式2：创建桌面快捷方式（可选）"
    echo "    见 README_LINUX.md"
    echo ""
    echo "  方式3：复制到系统PATH目录"
    echo "    sudo cp dist/文档格式一键转换器V1 /usr/local/bin/"
    echo "    文档格式一键转换器V1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  注意事项："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  • 首次运行会自动生成 format_config.yaml 配置文件"
    echo "  • 确保系统已安装中文字体（如：fonts-wqy-zenhei）"
    echo "  • 如遇显示问题，检查是否安装了图形桌面环境"
    echo ""
else
    log_error "打包失败！请查看上方错误信息"
    exit 1
fi
