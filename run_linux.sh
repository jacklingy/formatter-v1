#!/bin/bash

# Linux 快速启动脚本 - 文档格式一键转换器 V1.1
# 使用方法：chmod +x run_linux.sh && ./run_linux.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║     📄 文档格式一键转换器 V1.1 (Linux)        ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# 检查Python3
if ! command -v python3 &> /dev/null; then
    log_error "未找到Python3！"
    echo ""
    echo "请先安装Python3："
    echo "  Ubuntu/Debian: sudo apt install python3 python3-pip python3-tk"
    echo "  CentOS/RHEL:   sudo yum install python3 python3-pip tkinter"
    echo ""
    exit 1
fi

PYTHON_VER=$(python3 --version | awk '{print $2}')
log_info "Python版本: $PYTHON_VER"

# 检查tkinter
if ! python3 -c "import tkinter" 2>/dev/null; then
    log_error "tkinter未安装（GUI界面必需）！"
    echo ""
    echo "安装命令："
    echo "  Ubuntu/Debian: sudo apt install python3-tk"
    echo "  CentOS/RHEL:   sudo yum install python3-tkinter"
    echo "  Arch Linux:    sudo pacman -S tk"
    echo ""
    exit 1
fi

# 检查依赖包是否已安装
log_info "检查依赖包..."

MISSING_DEPS=()

check_dep() {
    if ! python3 -c "import $1" 2>/dev/null; then
        MISSING_DEPS+=("$1")
    fi
}

check_dep "docx"
check_dep "yaml"

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    log_warn "缺少依赖包: ${MISSING_DEPS[*]}"
    echo ""
    read -p "是否自动安装？(Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        log_info "正在安装依赖..."
        pip3 install --user -r requirements.txt
        
        if [ $? -eq 0 ]; then
            log_success "依赖安装完成"
        else
            log_warn "尝试使用sudo..."
            sudo pip3 install -r requirements.txt
        fi
    else
        log_error "无法继续，请手动安装依赖后重试"
        exit 1
    fi
fi

log_success "所有依赖就绪 ✓"

# 检查可执行文件是否存在
EXE_PATH="dist/文档格式一键转换器V1"

if [ -f "$EXE_PATH" ]; then
    log_info "发现打包版本，准备启动..."
    
    # 添加执行权限
    chmod +x "$EXE_PATH" 2>/dev/null || true
    
    # 启动程序
    echo ""
    echo -e "${GREEN}正在启动程序...${NC}"
    echo ""
    
    "$EXE_PATH" &
    PID=$!
    
    log_success "程序已启动 (PID: $PID)"
    echo ""
    echo "提示：关闭此窗口不会退出程序"
    echo "如需停止程序，请执行: kill $PID"
    echo ""
    
    # 等待用户输入
    read -p "按回车键退出此脚本..." 
else
    log_info "未发现打包版本，使用源码模式启动..."
    echo ""
    echo -e "${GREEN}正在启动程序...${NC}"
    echo ""
    
    python3 main.py &
    PID=$!
    
    log_success "程序已启动 (PID: $PID)"
    echo ""
    read -p "按回车键退出此脚本..."
fi

echo ""
log_info "感谢使用！"
