#!/bin/bash

# Linux 一键安装脚本 - 文档格式一键转换器 V1.1
# 支持系统：Ubuntu/Debian, CentOS/RHEL, Fedora, Arch Linux
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/your-repo/main/install.sh | bash
#   或
#   wget -qO- https://raw.githubusercontent.com/your-repo/main/install.sh | bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 图标
CHECKMARK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARNING="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"
ARROW="${CYAN}→${NC}"

# 打印带颜色的信息
print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║     📄 文档格式一键转换器 V1 一键安装脚本        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${INFO} ${ARROW} $1"; }
log_success() { echo -e "${CHECKMARK} $1"; }
log_warn() { echo -e "${WARNING} $1"; }
log_error() { echo -e "${CROSS} ${RED}$1${NC}"; }
log_step() { echo -e "\n${BOLD}${CYAN}[步骤 $1]${NC} ${BOLD}$2${NC}"; }

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(lsb_release -sr)
    else
        OS=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
    
    log_info "检测到操作系统: $OS $OS_VERSION"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_warn "部分操作需要sudo权限，脚本会自动请求权限"
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# 安装依赖（根据不同系统）
install_dependencies() {
    log_step "1" "安装系统依赖"
    
    case "$OS" in
        ubuntu|debian|linuxmint|pop)
            log_info "使用 apt 安装依赖..."
            $SUDO apt update
            $SUDO apt install -y \
                python3 \
                python3-pip \
                python3-tk \
                python3-dev \
                fonts-wqy-zenhei \
                fonts-wqy-microhei \
                wget \
                curl \
                git \
                xdg-utils
            ;;
        
        centos|rhel|fedora|rocky|almalinux)
            if [ "$OS" = "fedora" ]; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            
            log_info "使用 $PKG_MGR 安装依赖..."
            
            # CentOS/RHEL 7需要先安装EPEL
            if [[ "$OS_VERSION" == 7* ]] && [[ "$OS" =~ ^(centos|rhel)$ ]]; then
                $SUDO $PKG_MGR install -y epel-release
            fi
            
            $SUDO $PKG_MGR install -y \
                python3 \
                python3-pip \
                python3-tkinter \
                python3-devel \
                wqy-zenhei-fonts \
                git \
                wget \
                curl
            ;;
        
        arch|manjaro)
            log_info "使用 pacman 安装依赖..."
            $SUDO pacman -Syu --noconfirm
            $SUDO pacman -S --noconfirm \
                python \
                python-pip \
                tk \
                git \
                wget \
                curl \
                wqy-zenhei
            ;;
        
        opensuse*|sles)
            log_info "使用 zypper 安装依赖..."
            $SUDO zypper refresh
            $SUDO zypper install -y \
                python3 \
                python3-pip \
                python3-tk \
                python3-devel \
                wqy-zenhei-fonts \
                git \
                wget \
                curl
            ;;
        
        *)
            log_error "不支持的操作系统: $OS"
            echo ""
            echo "支持的系统："
            echo "  • Ubuntu/Debian 及衍生版"
            echo "  • CentOS/RHEL/Fedora/Rocky/AlmaLinux"
            echo "  • Arch Linux/Manjaro"
            echo "  • openSUSE/SLES"
            echo ""
            echo "请手动安装以下依赖后重试："
            echo "  • Python 3.8+"
            echo "  • pip (Python包管理器)"
            echo "  • tkinter (Python GUI库)"
            echo "  • 中文字体 (如：fonts-wqy-zenhei)"
            exit 1
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

# 获取项目代码
get_source_code() {
    log_step "2" "获取项目代码"
    
    INSTALL_DIR="$HOME/formatter-v1"
    
    # 检查目录是否存在
    if [ -d "$INSTALL_DIR" ]; then
        log_warn "目录已存在: $INSTALL_DIR"
        read -p "是否删除并重新下载？(Y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            rm -rf "$INSTALL_DIR"
        else
            log_info "使用现有代码..."
            cd "$INSTALL_DIR"
            return
        fi
    fi
    
    # 尝试Git克隆（如果配置了仓库）
    GIT_REPO="${GIT_REPO:-}"
    
    if [ -n "$GIT_REPO" ]; then
        log_info "从Git仓库克隆: $GIT_REPO"
        git clone "$GIT_REPO" "$INSTALL_DIR"
    else
        # 如果没有Git仓库，提示用户手动下载
        log_warn "未配置Git仓库地址"
        echo ""
        echo "请选择一种方式获取源代码："
        echo ""
        echo "  方式1：设置环境变量后重新运行"
        echo "    export GIT_REPO=https://github.com/yourusername/formatter-v1.git"
        echo "    ./install.sh"
        echo ""
        echo "  方式2：手动下载"
        echo "    1. 从GitHub/其他平台下载项目压缩包"
        echo "    2. 解压到 $INSTALL_DIR"
        echo "    3. 运行: cd $INSTALL_DIR && ./run_linux.sh"
        echo ""
        
        read -p "是否继续安装（假设代码已在$INSTALL_DIR）？(Y/n): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
            exit 0
        fi
        
        mkdir -p "$INSTALL_DIR"
    fi
    
    cd "$INSTALL_DIR"
    log_success "代码准备完成"
}

# 安装Python依赖
install_python_packages() {
    log_step "3" "安装Python依赖包"
    
    # 升级pip
    log_info "升级pip..."
    python3 -m pip install --user --upgrade pip -q
    
    # 安装依赖
    log_info "安装requirements.txt中的依赖..."
    
    if [ -f requirements.txt ]; then
        python3 -m pip install --user -r requirements.txt -q
        
        if [ $? -eq 0 ]; then
            log_success "Python依赖安装完成"
        else
            log_warn "尝试使用sudo安装..."
            $SUDO python3 -m pip install -r requirements.txt -q
            log_success "Python依赖安装完成（使用sudo）"
        fi
    else
        log_warn "未找到requirements.txt，跳过Python依赖安装"
    fi
}

# 打包可执行文件
build_executable() {
    log_step "4" "打包可执行文件"
    
    # 检查PyInstaller
    if ! command -v pyinstaller &> /dev/null; then
        log_info "安装PyInstaller..."
        python3 -m pip install --user pyinstaller -q
    fi
    
    # 执行打包
    log_info "开始打包（这可能需要2-5分钟）..."
    
    pyinstaller \
        --onefile \
        --windowed \
        --name "文档格式一键转换器V1" \
        --noconfirm \
        main.py
    
    if [ $? -eq 0 ] && [ -f "dist/文档格式一键转换器V1" ]; then
        chmod +x "dist/文档格式一键转换器V1"
        log_success "打包成功！"
        
        FILE_SIZE=$(du -h "dist/文档格式一键转换器V1" | cut -f1)
        log_info "文件大小: $FILE_SIZE"
        log_info "文件位置: $(realpath dist/文档格式一键转换器V1)"
    else
        log_warn "打包失败，但您仍可以使用源码模式运行"
    fi
}

# 创建快捷方式
create_shortcuts() {
    log_step "5" "创建桌面快捷方式"
    
    # 创建应用菜单入口
    DESKTOP_FILE="$HOME/.local/share/applications/文档格式一键转换器.desktop"
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=文档格式一键转换器V1
Name[en]=Document Formatter V1
Comment=Markdown to Word Converter & Document Formatter
Exec=bash -c "cd $(pwd) && ./run_linux.sh"
Icon=application-msword
Terminal=false
Type=Application
Categories=Office;TextEditor;Utility;
StartupNotify=true
EOF

    chmod +x "$DESKTOP_FILE"
    
    # 创建桌面快捷方式（如果桌面目录存在）
    if [ -d "$HOME/Desktop" ] || [ -d "$HOME/桌面" ]; then
        DESKTOP_PATH="$HOME/Desktop"
        [ ! -d "$HOME/Desktop" ] && DESKTOP_PATH="$HOME/桌面"
        
        cp "$DESKTOP_FILE" "$DESKTOP_PATH/文档格式一键转换器.desktop"
        log_success "桌面快捷方式已创建"
    fi
    
    # 刷新桌面数据库
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true
    fi
    
    log_success "快捷方式创建完成"
}

# 显示安装完成信息
show_completion_message() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║              ✅ 安装成功！                       ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}🎉 恭喜！文档格式一键转换器V1 已成功安装！${NC}"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}📋 启动方式：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ${ARROW} ${BOLD}方式1：直接运行${NC}"
    echo "     $(pwd)/run_linux.sh"
    echo ""
    echo "  ${ARROW} ${BOLD}方式2：运行打包版本${NC}"
    if [ -f "dist/文档格式一键转换器V1" ]; then
        echo "     $(pwd)/dist/文档格式一键转换器V1"
    else
        echo "     （打包版本未生成，请运行: ./build_linux.sh）"
    fi
    echo ""
    echo "  ${ARROW} ${BOLD}方式3：从应用菜单启动${NC}"
    echo "     应用程序 → 办公 → 文档格式一键转换器V1"
    echo ""
    echo "  ${ARROW} ${BOLD}方式4：命令行启动${NC}"
    echo "     cd $(pwd) && python3 main.py"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}⚙️  配置文件：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  配置文件位置: $(pwd)/format_config.yaml"
    echo "  首次启动时会自动生成默认配置"
    echo "  可通过界面右下角'格式设置'按钮打开编辑"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}📖 帮助文档：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  完整文档: $(pwd)/README.md"
    echo "  Linux指南: $(pwd)/README_LINUX.md"
    echo "  Docker部署: $(pwd)/Dockerfile"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🔧 常用命令：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  重新打包:   ./build_linux.sh"
    echo "  快速启动:   ./run_linux.sh"
    echo "  更新程序:   git pull && ./build_linux.sh"
    echo "  卸载程序:   rm -rf $(pwd)"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💡 提示：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  • 确保系统中已安装中文字体（安装时已自动安装）"
    echo "  • 如遇显示问题，请检查是否连接了图形显示器"
    echo "  • 配置文件支持自定义所有格式参数"
    echo "  • 支持中文路径和文件名"
    echo ""
    echo -e "${CYAN}感谢使用！如有问题请查看README_LINUX.md${NC}"
    echo ""
}

# 主函数
main() {
    print_header
    
    # 显示欢迎信息
    echo "此脚本将自动完成以下操作："
    echo "  1. 安装系统依赖（Python、tkinter、中文字体等）"
    echo "  2. 获取项目代码"
    echo "  3. 安装Python依赖包"
    echo "  4. 打包可执行文件"
    echo "  5. 创建桌面快捷方式"
    echo ""
    
    read -p "是否继续？(Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    # 执行安装步骤
    detect_os
    check_root
    install_dependencies
    get_source_code
    install_python_packages
    build_executable
    create_shortcuts
    show_completion_message
}

# 运行主函数
main "$@"
