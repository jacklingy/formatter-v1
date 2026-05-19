#!/bin/bash

# ============================================================
# 依赖下载脚本 - 在在线环境中运行
# 用途：下载所有需要的依赖包，用于离线安装
# 使用方法: chmod +x download_deps.sh && ./download_deps.sh
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
echo "║   📦 文档格式转换器 V1.1 - 离线依赖下载工具     ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建输出目录
OFFLINE_DIR="offline_package"
DEPS_DIR="$OFFLINE_DIR/dependencies"
SYSTEM_DEPS_DIR="$OFFLINE_DIR/system_packages"
PYTHON_DEPS_DIR="$OFFLINE_DIR/python_packages"
FONTS_DIR="$OFFLINE_DIR/fonts"

log_info() { echo -e "${BLUE}[信息]${NC} $1"; }
log_success() { echo -e "${GREEN}[成功]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
log_error() { echo -e "${RED}[错误]${NC} $1"; }

# 清理并创建目录结构
prepare_directories() {
    log_info "准备目录结构..."
    
    rm -rf "$OFFLINE_DIR"
    
    mkdir -p "$DEPS_DIR"
    mkdir -p "$SYSTEM_DEPS_DIR/deb"           # Debian/Ubuntu .deb 包
    mkdir -p "$SYSTEM_DEPS_DIR/rpm"           # CentOS/RHEL .rpm 包
    mkdir -p "$SYSTEM_DEPS_DIR/arch"          # Arch Linux 包
    mkdir -p "$PYTHON_DEPS_DIR/wheels"        # Python wheel 文件
    mkdir -p "$PYTHON_DEPS_DIR/tarballs"      # Python 源码包
    mkdir -p "$FONTS_DIR"
    
    log_success "目录创建完成"
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
    
    log_info "检测到操作系统: $OS $OS_VERSION"
}

# 下载系统级依赖包（deb/rpm）
download_system_dependencies() {
    log_info "下载系统级依赖包..."
    
    case "$OS" in
        ubuntu|debian|linuxmint|pop)
            download_deb_packages
            ;;
        centos|rhel|fedora|rocky|almalinux)
            download_rpm_packages
            ;;
        arch|manjaro)
            download_arch_packages
            ;;
        *)
            log_warn "不支持的操作系统，跳过系统包下载"
            log_warn "您需要手动准备以下系统依赖："
            echo "  • python3 (>= 3.8)"
            echo "  • tkinter (python3-tk 或 python3-tkinter)"
            echo "  • 中文字体 (fonts-wqy-zenhei 等)"
            ;;
    esac
}

# 下载Debian/Ubuntu的.deb包
download_deb_packages() {
    log_info "下载 Debian/Ubuntu 系统包..."
    
    # 需要的系统包列表
    PACKAGES=(
        "python3"
        "python3-tk"
        "python3-pip"
        "fonts-wqy-zenhei"
        "fonts-wqy-microhei"
        "libfreetype6"
        "libpng16-16"
        "libtiff5"
    )
    
    # 创建下载列表文件
    PACKAGES_FILE="$SYSTEM_DEPS_DIR/packages_list.txt"
    > "$PACKAGES_FILE"
    
    for pkg in "${PACKAGES[@]}"; do
        echo "$pkg" >> "$PACKAGES_FILE"
    done
    
    # 使用apt-get下载（不安装）
    if command -v apt-get &> /dev/null; then
        log_info "使用 apt-get 下载 .deb 包..."
        
        # 更新包缓存
        sudo apt update
        
        # 下载所有包到指定目录
        for pkg in "${PACKAGES[@]}"; do
            log_info "  下载: $pkg"
            sudo apt-get install --reinstall --download-only \
                -o Dir::Cache::Archives="$SYSTEM_DEPS_DIR/deb" \
                -o Dir::State::Lists="$SYSTEM_DEPS_DIR/lists" \
                "$pkg" || true
            
            # 移动下载的包
            find /var/cache/apt/archives/ -name "*.deb" -exec mv {} "$SYSTEM_DEPS_DIR/deb/" \; 2>/dev/null || true
        done
        
        # 清理apt缓存
        sudo apt clean
        
        log_success ".deb 包下载完成"
        
        # 记录包列表
        ls "$SYSTEM_DEPS_DIR/deb/" > "$SYSTEM_DEPS_DIR/deb/package_list.txt" 2>/dev/null || true
    fi
}

# 下载CentOS/RHEL的.rpm包
download_rpm_packages() {
    log_info "下载 CentOS/RHEL 系统包..."
    
    PACKAGES=(
        "python3"
        "python3-pip"
        "python3-tkinter"
        "wqy-zenhei-fonts"
    )
    
    if command -v yum &> /dev/null || command -v dnf &> /dev/null; then
        PKG_MGR="yum"
        [ -x "$(command -v dnf)" ] && PKG_MGR="dnf"
        
        for pkg in "${PACKAGES[@]}"; do
            log_info "  下载: $pkg"
            
            if [ "$PKG_MGR" = "dnf" ]; then
                sudo dnf download --destdir="$SYSTEM_DEPS_DIR/rpm" "$pkg" || true
            else
                sudo yum install --downloadonly --downloaddir="$SYSTEM_DEPS_DIR/rpm" "$pkg" || true
            fi
        done
        
        log_success ".rpm 包下载完成"
        
        # 记录包列表
        ls "$SYSTEM_DEPS_DIR/rpm/" > "$SYSTEM_DEPS_DIR/rpm/package_list.txt" 2>/dev/null || true
    fi
}

# 下载Arch Linux包
download_arch_packages() {
    log_info "下载 Arch Linux 系统包..."
    
    PACKAGES=(
        "python"
        "tk"
        "wqy-zenhei"
    )
    
    if command -v pacman &> /dev/null; then
        # 获取包URL并下载
        for pkg in "${PACKAGES[@]}"; do
            log_info "  下载: $pkg"
            
            # 使用pacman获取下载链接
            URL=$(pacman -S --print-format "%u" "$pkg" | head -1)
            
            if [ -n "$URL" ]; then
                wget -q -P "$SYSTEM_DEPS_DIR/arch" "$URL" || true
            fi
        done
        
        log_success "Arch 包下载完成"
    fi
}

# 下载Python依赖包
download_python_dependencies() {
    log_info "下载Python依赖包..."
    
    # 方法1：下载wheel文件（推荐，安装快速）
    log_info "  下载wheel格式包..."
    pip3 download \
        -d "$PYTHON_DEPS_DIR/wheels" \
        --no-binary=:none: \
        -r requirements.txt \
        || {
            # 如果失败，尝试只下载二进制包
            log_warn "尝试仅下载二进制wheel包..."
            pip3 download \
                -d "$PYTHON_DEPS_DIR/wheels" \
                -r requirements.txt \
                || true
        }
    
    # 方法2：同时下载源码包作为备选
    log_info "  下载源码包（备选）..."
    pip3 download \
        --no-binary=:all: \
        -d "$PYTHON_DEPS_DIR/tarballs" \
        -r requirements.txt \
        || true
    
    # 单独下载PyInstaller（打包工具）
    log_info "  下载 PyInstaller..."
    pip3 download \
        -d "$PYTHON_DEPS_DIR/wheels" \
        pyinstaller \
        || true
    
    log_success "Python依赖包下载完成"
    
    # 统计下载的包数量
    WHEEL_COUNT=$(ls "$PYTHON_DEPS_DIR/wheels/"*.whl 2>/dev/null | wc -l)
    TAR_COUNT=$(ls "$PYTHON_DEPS_DIR/tarballs/"*.tar.gz 2>/dev/null | wc -l)
    
    log_info "  Wheel包: $WHEEL_COUNT 个"
    log_info "  源码包: $TAR_COUNT 个"
}

# 下载中文字体文件
download_fonts() {
    log_info "下载中文字体..."
    
    # 文泉驿正黑字体（开源）
    FONT_URLS=(
        "https://github.com/google/fonts/raw/main/ofl/wenquanyizenhei/WenQuanYiZenHei-Regular.ttf"
        "https://github.com/adobe-fonts/source-han-sans/blob/release/OTF/SimplifiedChinese/SourceHanSansSC-Regular.otf?raw=true"
    )
    
    cd "$FONTS_DIR"
    
    for url in "${FONT_URLS[@]}"; do
        FILENAME=$(basename "$url" | cut -d'?' -f1)
        log_info "  下载: $FILENAME"
        wget -q --timeout=30 -O "$FILENAME" "$url" || true
    done
    
    cd "$SCRIPT_DIR"
    
    log_success "字体文件下载完成"
    
    # 列出已下载的字体
    FONTS_DOWNLOADED=$(ls "$FONTS_DIR" 2>/dev/null | wc -l)
    log_info "  已下载字体文件: $FONTS_DOWNLOADED 个"
}

# 打包可执行文件（可选）
build_executable() {
    read -p "是否同时打包可执行文件？(Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        log_info "打包可执行文件..."
        
        # 先在当前环境安装PyInstaller（临时）
        pip3 install --user pyinstaller -q
        
        # 执行打包
        pyinstaller \
            --onefile \
            --windowed \
            --name "文档格式一键转换器V1" \
            --noconfirm \
            main.py
        
        if [ -f "dist/文档格式一键转换器V1" ]; then
            cp "dist/文档格式一键转换器V1" "$OFFLINE_DIR/"
            chmod +x "$OFFLINE_DIR/文档格式一键转换器V1"
            log_success "可执行文件已添加到离线包"
        fi
    fi
}

# 复制项目必要文件
copy_project_files() {
    log_info "复制项目文件..."
    
    # 复制核心文件
    cp main.py "$OFFLINE_DIR/"
    cp gui.py "$OFFLINE_DIR/"
    cp config_manager.py "$OFFLINE_DIR/"
    cp converter.py "$OFFLINE_DIR/"
    cp formatter.py "$OFFLINE_DIR/"
    cp format_config.yaml "$OFFLINE_DIR/"
    cp requirements.txt "$OFFLINE_DIR/"
    
    # 复制安装和启动脚本
    cp install_offline.sh "$OFFLINE_DIR/" 2>/dev/null || true
    cp run_linux.sh "$OFFLINE_DIR/"
    
    log_success "项目文件复制完成"
}

# 创建离线包清单
create_manifest() {
    log_info "生成离线包清单..."
    
    MANIFEST="$OFFLINE_DIR/MANIFEST.txt"
    
    cat > "$MANIFEST" << EOF
============================================================
  文档格式一键转换器 V1 - 离线部署包
============================================================

生成时间: $(date '+%Y-%m-%d %H:%M:%S')
生成环境: $(uname -a)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 目录结构说明
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$OFFLINE_DIR/
├── dependencies/
│   ├── system_packages/
│   │   ├── deb/              # Debian/Ubuntu系统包 (.deb)
│   │   │   └── package_list.txt
│   │   ├── rpm/              # CentOS/RHEL系统包 (.rpm)
│   │   │   └── package_list.txt
│   │   └── arch/             # Arch Linux系统包
│   │
│   ├── python_packages/
│   │   ├── wheels/           # Python Wheel包（推荐）
│   │   └── tarballs/         # Python源码包（备选）
│   │
│   └── fonts/                # 中文字体文件
│
├── *.py                      # 项目源代码
├── format_config.yaml        # 配置文件模板
├── requirements.txt          # Python依赖列表
├── install_offline.sh        # 离线安装脚本 ⭐
├── run_linux.sh              # 启动脚本
├── 文档格式一键转换器V1      # 可执行文件（如果打包了）
└── MANIFEST.txt              # 本文件

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 内容统计
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

    # 统计各部分大小
    if [ -d "$SYSTEM_DEPS_DIR/deb" ]; then
        DEB_SIZE=$(du -sh "$SYSTEM_DEPS_DIR/deb" 2>/dev/null | cut -f1)
        DEB_COUNT=$(ls "$SYSTEM_DEPS_DIR/deb"/*.deb 2>/dev/null | wc -l)
        echo "Debian/Ubuntu 包: $DEB_COUNT 个 ($DEB_SIZE)" >> "$MANIFEST"
    fi
    
    if [ -d "$SYSTEM_DEPS_DIR/rpm" ]; then
        RPM_SIZE=$(du -sh "$SYSTEM_DEPS_DIR/rpm" 2>/dev/null | cut -f1)
        RPM_COUNT=$(ls "$SYSTEM_DEPS_DIR/rpm"/*.rpm 2>/dev/null | wc -l)
        echo "CentOS/RHEL 包: $RPM_COUNT 个 ($RPM_SIZE)" >> "$MANIFEST"
    fi
    
    WHEEL_SIZE=$(du -sh "$PYTHON_DEPS_DIR/wheels" 2>/dev/null | cut -f1)
    WHEEL_COUNT=$(ls "$PYTHON_DEPS_DIR/wheels"/*.whl 2>/dev/null | wc -l)
    echo "Python Wheel包: $WHEEL_COUNT 个 ($WHEEL_SIZE)" >> "$MANIFEST"
    
    TAR_SIZE=$(du -sh "$PYTHON_DEPS_DIR/tarballs" 2>/dev/null | cut -f1)
    TAR_COUNT=$(ls "$PYTHON_DEPS_DIR/tarballs"/*.tar.gz 2>/dev/null | wc -l)
    echo "Python 源码包: $TAR_COUNT 个 ($TAR_SIZE)" >> "$MANIFEST"
    
    FONTS_SIZE=$(du -sh "$FONTS_DIR" 2>/dev/null | cut -f1)
    FONTS_COUNT=$(ls "$FONTS_DIR" 2>/dev/null | wc -l)
    echo "字体文件: $FONTS_COUNT 个 ($FONTS_SIZE)" >> "$MANIFEST"
    
    TOTAL_SIZE=$(du -sh "$OFFLINE_DIR" 2>/dev/null | cut -f1)
    echo "" >> "$MANIFEST"
    echo "总大小: $TOTAL_SIZE" >> "$MANIFEST"
    
    echo "" >> "$MANIFEST"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$MANIFEST"
    echo "🚀 安装步骤" >> "$MANIFEST"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$MANIFEST"
    echo "" >> "$MANIFEST"
    echo "1. 将整个 offline_package 目录传输到目标机器" >> "$MANIFEST"
    echo "2. 进入目录: cd offline_package" >> "$MANIFEST"
    echo "3. 运行安装脚本:" >> "$MANIFEST"
    echo "   chmod +x install_offline.sh" >> "$MANIFEST"
    echo "   ./install_offline.sh" >> "$MANIFEST"
    echo "" >> "$MANIFEST"
    echo "4. 启动程序:" >> "$MANIFEST"
    echo "   ./run_linux.sh" >> "$MANIFEST"
    echo "   或直接运行: ./文档格式一键转换器V1" >> "$MANIFEST"
    echo "" >> "$MANIFEST"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$MANIFEST"
    
    log_success "清单文件已生成: $MANIFEST"
}

# 创建最终的压缩包
create_archive() {
    log_info "创建离线部署压缩包..."
    
    ARCHIVE_NAME="doc-formatter-v1-offline-package-$(date +%Y%m%d).tar.gz"
    
    tar -czvf "$ARCHIVE_NAME" "$OFFLINE_DIR"
    
    ARCHIVE_SIZE=$(du -sh "$ARCHIVE_NAME" | cut -f1)
    
    log_success "离线包创建成功！"
    log_info "文件名: $ARCHIVE_NAME"
    log_info "大小: $ARCHIVE_SIZE"
    log_info ""
    log_info "📍 位置: $(realpath $ARCHIVE_NAME)"
    log_info ""
    log_info "下一步操作："
    log_info "  1. 将此压缩包传输到离线环境的机器上"
    log_info "  2. 解压: tar -xzvf $ARCHIVE_NAME"
    log_info "  3. 进入目录并运行: ./install_offline.sh"
}

# 主函数
main() {
    echo ""
    echo "此脚本将执行以下操作："
    echo "  1. 检测当前操作系统"
    echo "  2. 下载系统级依赖包（.deb/.rpm）"
    echo "  3. 下载Python依赖包（wheel + 源码）"
    echo "  4. 下载中文字体文件"
    echo "  5. 复制项目源代码"
    echo "  6. （可选）打包可执行文件"
    echo "  7. 生成完整的离线部署包"
    echo ""
    
    read -p "是否继续？(Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        log_info "操作已取消"
        exit 0
    fi
    
    # 执行各步骤
    prepare_directories
    detect_os
    download_system_dependencies
    download_python_dependencies
    download_fonts
    copy_project_files
    build_executable
    create_manifest
    create_archive
    
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║       ✅ 离线依赖包下载完成！                    ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}📦 生成的文件:${NC}"
    echo "  • 压缩包: ${ARCHIVE_NAME}"
    echo "  • 目录: ${OFFLINE_DIR}/"
    echo ""
    echo -e "${BOLD}📋 下一步操作:${NC}"
    echo "  1. 将 ${ARCHIVE_NAME} 传输到离线机器"
    echo "  2. 解压: tar -xzvf ${ARCHIVE_NAME}"
    echo "  3. 运行: cd ${OFFLINE_DIR} && ./install_offline.sh"
    echo ""
}

# 运行主函数
main "$@"
