#!/bin/bash

# ============================================================
# 离线环境自动安装脚本
# 用途：在无网络的Linux环境中安装所有依赖并运行程序
# 使用方法: chmod +x install_offline.sh && ./install_offline.sh
# 前提：已通过 download_deps.sh 下载好依赖包
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║   📦 文档格式转换器 - 离线安装工具              ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# 检查是否在正确的目录中（应该包含 dependencies 目录）
check_environment() {
    log_info "检查离线包完整性..."
    
    if [ ! -d "dependencies" ]; then
        log_error "未找到 dependencies 目录！"
        echo ""
        echo "请确保："
        echo "  1. 此脚本位于 offline_package/ 目录内"
        echo "  2. 已通过 download_deps.sh 生成了完整的离线包"
        echo ""
        exit 1
    fi
    
    # 检查关键文件
    MISSING_FILES=()
    
    [ ! -f "main.py" ] && MISSING_FILES+=("main.py")
    [ ! -f "gui.py" ] && MISSING_FILES+=("gui.py")
    [ ! -f "config_manager.py" ] && MISSING_FILES+=("config_manager.py")
    [ ! -f "requirements.txt" ] && MISSING_FILES+=("requirements.txt")
    
    if [ ${#MISSING_FILES[@]} -gt 0 ]; then
        log_error "缺少必要文件: ${MISSING_FILES[*]}"
        exit 1
    fi
    
    log_success "离线包检查通过"
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        OS=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
    
    log_info "目标系统: $OS $OS_VERSION"
}

# 安装系统级依赖（使用本地下载的包）
install_system_packages() {
    log_info "安装系统级依赖..."
    
    case "$OS" in
        ubuntu|debian|linuxmint|pop)
            install_deb_packages
            ;;
        centos|rhel|fedora|rocky|almalinux)
            install_rpm_packages
            ;;
        arch|manjaro)
            install_arch_packages
            ;;
        *)
            log_warn "不支持的操作系统，跳过系统包安装"
            log_warn "请确保已手动安装以下依赖："
            echo "  • python3 (>= 3.8)"
            echo "  • tkinter (python3-tk 或 python3-tkinter)"
            echo "  • pip3"
            read -p "是否继续？(Y/n): " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]] && exit 1
            ;;
    esac
}

# 安装.deb包（Debian/Ubuntu）
install_deb_packages() {
    DEB_DIR="dependencies/system_packages/deb"
    
    if [ ! -d "$DEB_DIR" ] || [ -z "$(ls -A $DEB_DIR/*.deb 2>/dev/null)" ]; then
        log_warn "未找到 .deb 包，跳过系统依赖安装"
        return
    fi
    
    log_info "安装 Debian/Ubuntu 系统包..."
    
    DEB_COUNT=$(ls "$DEB_DIR"/*.deb 2>/dev/null | wc -l)
    log_info "发现 $DEB_COUNT 个 .deb 包"
    
    # 使用dpkg安装所有包
    sudo dpkg -i "$DEB_DIR"/*.deb || {
        # 如果有依赖问题，尝试修复
        log_warn "部分包可能存在依赖问题，尝试修复..."
        sudo apt-get -f install -y
    }
    
    log_success "系统包安装完成"
}

# 安装.rpm包（CentOS/RHEL）
install_rpm_packages() {
    RPM_DIR="dependencies/system_packages/rpm"
    
    if [ ! -d "$RPM_DIR" ] || [ -z "$(ls -A $RPM_DIR/*.rpm 2>/dev/null)" ]; then
        log_warn "未找到 .rpm 包，跳过系统依赖安装"
        return
    fi
    
    log_info "安装 CentOS/RHEL 系统包..."
    
    RPM_COUNT=$(ls "$RPM_DIR"/*.rpm 2>/dev/null | wc -l)
    log_info "发现 $RPM_COUNT 个 .rpm 包"
    
    # 使用yum/dnf安装
    PKG_MGR="yum"
    [ -x "$(command -v dnf)" ] && PKG_MGR="dnf"
    
    sudo $PKG_MGR install -y "$RPM_DIR"/*.rpm || true
    
    log_success "系统包安装完成"
}

# 安装Arch Linux包
install_arch_packages() {
    ARCH_DIR="dependencies/system_packages/arch"
    
    if [ ! -d "$ARCH_DIR" ] || [ -z "$(ls -A $ARCH_DIR 2>/dev/null)" ]; then
        log_warn "未找到 Arch 包，跳过系统依赖安装"
        return
    fi
    
    log_info "安装 Arch Linux 系统包..."
    
    for pkg_file in "$ARCH_DIR"/*; do
        if [ -f "$pkg_file" ]; then
            log_info "  安装: $(basename $pkg_file)"
            sudo pacman -U --noconfirm "$pkg_file" || true
        fi
    done
    
    log_success "系统包安装完成"
}

# 安装中文字体
install_fonts() {
    FONTS_DIR="dependencies/fonts"
    
    if [ ! -d "$FONTS_DIR" ] || [ -z "$(ls -A $FONTS_DIR 2>/dev/null)" ]; then
        log_warn "未找到字体文件，尝试使用系统字体或后续手动配置"
        return
    fi
    
    log_info "安装中文字体..."
    
    # 创建用户字体目录
    FONT_TARGET="$HOME/.local/share/fonts/doc-formatter"
    mkdir -p "$FONT_TARGET"
    
    # 复制字体文件
    cp "$FONTS_DIR"/* "$FONT_TARGET/" 2>/dev/null || true
    
    # 刷新字体缓存
    fc-cache -fv "$FONT_TARGET" 2>/dev/null || true
    
    # 或者安装到系统目录（需要root权限）
    SYSTEM_FONT_DIR="/usr/local/share/fonts/truetype/doc-formatter"
    if [ -w "/usr/local/share/fonts" ] || [ "$EUID" -eq 0 ]; then
        mkdir -p "$SYSTEM_FONT_DIR"
        cp "$FONTS_DIR"/* "$SYSTEM_FONT_DIR/" 2>/dev/null || true
        fc-cache -fv 2>/dev/null || true
    fi
    
    FONTS_INSTALLED=$(ls "$FONT_TARGET" 2>/dev/null | wc -l)
    log_success "字体安装完成 ($FONTS_INSTALLED 个文件)"
}

# 安装Python依赖包
install_python_packages() {
    WHEELS_DIR="dependencies/python_packages/wheels"
    TAR_DIR="dependencies/python_packages/tarballs"
    
    log_info "安装Python依赖包..."
    
    # 检查Python和pip是否可用
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装！请先安装系统依赖"
        exit 1
    fi
    
    if ! command -v pip3 &> /dev/null; then
        log_error "pip3 未安装！请先安装系统依赖"
        exit 1
    fi
    
    PYTHON_VER=$(python3 --version | awk '{print $2}')
    log_info "Python版本: $PYTHON_VER"
    
    # 方法1：优先安装wheel包（快速，无需编译）
    if [ -d "$WHEELS_DIR" ] && [ -n "$(ls -A $WHEELS_DIR/*.whl 2>/dev/null)" ]; then
        log_info "安装 Wheel 格式包..."
        
        pip3 install --no-index --find-links="$WHEELS_DIR" \
            -r requirements.txt || {
                log_warn "Wheel安装失败，尝试逐个安装..."
                
                for wheel in "$WHEELS_DIR"/*.whl; do
                    [ -f "$wheel" ] || continue
                    log_info "  安装: $(basename $wheel)"
                    pip3 install --no-index --find-links="$WHEELS_DIR" "$wheel" || true
                done
            }
        
        log_success "Wheel包安装完成"
    else
        log_warn "未找到 Wheel 包"
    fi
    
    # 方法2：如果wheel失败，尝试源码包
    if [ -d "$TAR_DIR" ] && [ -n "$(ls -A $TAR_DIR/*.tar.gz 2>/dev/null)" ]; then
        log_info "安装源码格式包（备选）..."
        
        for tarball in "$TAR_DIR"/*.tar.gz; do
            [ -f "$tarball" ] || continue
            log_info "  编译安装: $(basename $tarball)"
            pip3 install --no-index --find-links="$TAR_DIR" "$tarball" || true
        done
        
        log_success "源码包安装完成"
    fi
    
    # 验证关键模块
    log_info "验证Python模块..."
    
    python3 << 'EOF'
import sys

modules = [
    ('tkinter', 'GUI界面'),
    ('docx', 'Word文档处理'),
    ('yaml', '配置文件解析'),
]

all_ok = True
for module, desc in modules:
    try:
        __import__(module)
        print(f"  ✓ {desc} ({module})")
    except ImportError as e:
        print(f"  ✗ {desc} ({module}): {e}")
        all_ok = False

if all_ok:
    sys.exit(0)
else:
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        log_success "所有Python模块验证通过"
    else
        log_warn "部分模块安装失败，程序可能无法正常运行"
    fi
}

# 配置环境
setup_environment() {
    log_info "配置运行环境..."
    
    # 确保脚本可执行
    chmod +x run_linux.sh 2>/dev/null || true
    
    # 如果存在可执行文件，确保可执行
    if [ -f "文档格式一键转换器V1" ]; then
        chmod +x "文档格式一键转换器V1"
        log_success "可执行文件就绪"
    fi
    
    # 创建配置目录
    CONFIG_DIR="$HOME/.config/formatter-v1"
    mkdir -p "$CONFIG_DIR"
    
    # 复制默认配置（如果不存在）
    if [ ! -f "$CONFIG_DIR/format_config.yaml" ] && [ -f "format_config.yaml" ]; then
        cp "format_config.yaml" "$CONFIG_DIR/"
        log_success "默认配置已复制到: $CONFIG_DIR"
    fi
    
    log_success "环境配置完成"
}

# 显示安装结果和使用说明
show_completion_message() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║           ✅ 离线安装成功！                      ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}🎉 恭喜！文档格式一键转换器V1 已成功安装到离线环境！${NC}"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🚀 启动方式（选择一种）：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f "文档格式一键转换器V1" ]; then
        echo "  ${BOLD}方式1（推荐）:${NC} 直接运行打包版本"
        echo "    $ ./文档格式一键转换器V1"
        echo ""
    fi
    
    echo "  ${BOLD}方式2:${NC} 使用启动脚本"
    echo "    $ ./run_linux.sh"
    echo ""
    
    echo "  ${BOLD}方式3:${NC} 源码模式运行"
    echo "    $ python3 main.py"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}⚙️  配置信息：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  配置文件位置:"
    echo "    • 当前目录: ./format_config.yaml"
    echo "    • 用户目录: ~/.config/formatter-v1/format_config.yaml"
    echo ""
    echo "  首次运行会自动生成默认配置"
    echo "  可通过界面右下角'格式设置'按钮编辑"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💡 提示：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  • 如遇中文显示异常，请检查字体是否正确安装"
    echo "  • 配置文件支持自定义所有格式参数"
    echo "  • 支持中文路径和文件名"
    echo "  • 所有操作不会修改原文件"
    echo ""
    echo -e "${CYAN}感谢使用！${NC}"
    echo ""
}

# 主函数
main() {
    check_environment
    detect_os
    install_system_packages
    install_fonts
    install_python_packages
    setup_environment
    show_completion_message
    
    # 询问是否立即启动
    echo ""
    read -p "是否现在启动程序？(Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo ""
        echo -e "${BLUE}正在启动程序...${NC}"
        
        if [ -f "文档格式一键转换器V1" ]; then
            ./文档格式一键转换器V1 &
        else
            ./run_linux.sh
        fi
    fi
}

# 运行主函数
main "$@"
