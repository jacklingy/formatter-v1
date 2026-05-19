#!/bin/bash

# ============================================================
# 一键生成离线部署包
# 用途：自动完成从下载依赖到打包的全部流程
# 使用方法: chmod +x create_offline_package.sh && ./create_offline_package.sh
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
echo "╔══════════════════════════════════════════════════════╗"
echo "║  📦 文档格式转换器 - 离线包一键生成工具          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

log_info() { echo -e "${BLUE}[信息]${NC} $1"; }
log_success() { echo -e "${GREEN}[成功]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
log_error() { echo -e "${RED}[错误]${NC} $1"; }

# 检查前置条件
check_prerequisites() {
    log_info "检查前置条件..."
    
    MISSING_TOOLS=()
    
    # 检查必要工具
    command -v python3 &> /dev/null || MISSING_TOOLS+=("python3")
    command -v pip3 &> /dev/null || MISSING_TOOLS+=("pip3")
    command -v wget &> /dev/null || MISSING_TOOLS+=("wget")
    command -v tar &> /dev/null || MISSING_TOOLS+=("tar")
    
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${MISSING_TOOLS[*]}"
        echo ""
        echo "请安装缺失的工具后重试"
        exit 1
    fi
    
    # 检查关键文件
    if [ ! -f "requirements.txt" ]; then
        log_error "未找到 requirements.txt"
        exit 1
    fi
    
    if [ ! -f "main.py" ]; then
        log_error "未找到 main.py"
        exit 1
    fi
    
    log_success "前置条件检查通过"
}

# 显示选项菜单
show_menu() {
    echo ""
    echo -e "${BOLD}请选择要生成的离线包类型：${NC}"
    echo ""
    echo "  ${BOLD}1)${NC} 完整版（系统包 + Python包 + 字体 + 可执行文件）⭐ 推荐"
    echo "     大小：约 100-200MB"
    echo "     适用：完全隔离的离线环境"
    echo ""
    echo "  ${BOLD}2)${NC} 标准版（Python包 + 字体 + 可执行文件）"
    echo "     大小：约 50-80MB"
    echo "     适用：目标机器已有基础运行环境（python3、tkinter）"
    echo ""
    echo "  ${BOLD}3)${NC} 轻量版（仅Python包）"
    echo "     大小：约 20-30MB"
    echo "     适用：目标机器有完整开发环境"
    echo ""
    echo "  ${BOLD}4)${NC} 自定义模式（手动选择组件）"
    echo ""
    echo "  ${BOLD}5)${NC} 仅下载依赖（不打包可执行文件）"
    echo ""
    echo "  ${BOLD}q)${NC} 退出"
    echo ""
    
    read -p "请输入选项 [1-5/q]: " choice
    echo ""
    
    case "$choice" in
        1) MODE="full";;
        2) MODE="standard";;
        3) MODE="minimal";;
        4) MODE="custom";;
        5) MODE="deps_only";;
        q|Q) 
            log_info "操作已取消"
            exit 0
            ;;
        *)
            log_error "无效选项"
            show_menu
            ;;
    esac
}

# 执行完整版打包
build_full_package() {
    log_info "开始构建完整版离线包..."
    
    # 调用download_deps.sh，并选择打包可执行文件
    {
        echo "y" | bash download_deps.sh
    } || true
    
    log_success "完整版离线包已生成"
}

# 执行标准版打包
build_standard_package() {
    log_info "开始构建标准版离线包..."
    
    OFFLINE_DIR="offline_package_standard"
    rm -rf "$OFFLINE_DIR"
    
    mkdir -p "$OFFLINE_DIR/dependencies/python_packages/wheels"
    mkdir -p "$OFFLINE_DIR/dependencies/python_packages/tarballs"
    mkdir -p "$OFFLINE_DIR/dependencies/fonts"
    
    # 下载Python包
    log_info "下载Python依赖包..."
    pip3 download \
        -d "$OFFLINE_DIR/dependencies/python_packages/wheels" \
        -r requirements.txt \
        || true
    
    pip3 download \
        --no-binary=:all: \
        -d "$OFFLINE_DIR/dependencies/python_packages/tarballs" \
        -r requirements.txt \
        || true
    
    # 下载字体
    log_info "下载字体文件..."
    cd "$OFFLINE_DIR/dependencies/fonts"
    wget -q --timeout=30 "https://github.com/google/fonts/raw/main/ofl/wenquanyizenhei/WenQuanYiZenHei-Regular.ttf" || true
    cd "$SCRIPT_DIR"
    
    # 复制项目文件
    log_info "复制项目文件..."
    cp *.py "$OFFLINE_DIR/"
    cp format_config.yaml "$OFFLINE_DIR/" 2>/dev/null || true
    cp requirements.txt "$OFFLINE_DIR/"
    cp install_offline.sh "$OFFLINE_DIR/"
    cp run_linux.sh "$OFFLINE_DIR/"
    
    # 打包可执行文件
    log_info "打包可执行文件..."
    pip3 install pyinstaller -q
    pyinstaller --onefile --windowed \
        --name "文档格式一键转换器V1" \
        --noconfirm \
        main.py && \
        cp dist/文档格式一键转换器V1 "$OFFLINE_DIR/" && \
        chmod +x "$OFFLINE_DIR/文档格式一键转换器V1"
    
    # 创建压缩包
    ARCHIVE_NAME="doc-formatter-v1-standard-offline-$(date +%Y%m%d).tar.gz"
    tar -czvf "$ARCHIVE_NAME" "$OFFLINE_DIR"
    
    SIZE=$(du -sh "$ARCHIVE_NAME" | cut -f1)
    log_success "标准版离线包已生成: $ARCHIVE_NAME ($SIZE)"
}

# 执行轻量版打包
build_minimal_package() {
    log_info "开始构建轻量版离线包..."
    
    OFFLINE_DIR="offline_package_minimal"
    rm -rf "$OFFLINE_DIR"
    
    mkdir -p "$OFFLINE_DIR/python_packages/wheels"
    mkdir -p "$OFFLINE_DIR/python_packages/tarballs"
    
    # 仅下载Python包
    log_info "下载Python依赖包..."
    pip3 download \
        -d "$OFFLINE_DIR/python_packages/wheels" \
        -r requirements.txt \
        || true
    
    # 复制核心文件
    cp *.py "$OFFLINE_DIR/"
    cp format_config.yaml "$OFFLINE_DIR/" 2>/dev/null || true
    cp requirements.txt "$OFFLINE_DIR/"
    
    # 创建简化安装脚本
    cat > "$OFFLINE_DIR/install_minimal.sh" << 'EOF'
#!/bin/bash
echo "安装Python依赖..."
pip3 install --no-index --find-links=./python_packages/wheels -r requirements.txt
echo "安装完成！"
echo "启动命令: python3 main.py"
EOF
    chmod +x "$OFFLINE_DIR/install_minimal.sh"
    
    # 创建压缩包
    ARCHIVE_NAME="doc-formatter-v1-minimal-offline-$(date +%Y%m%d).tar.gz"
    tar -czvf "$ARCHIVE_NAME" "$OFFLINE_DIR"
    
    SIZE=$(du -sh "$ARCHIVE_NAME" | cut -f1)
    log_success "轻量版离线包已生成: $ARCHIVE_NAME ($SIZE)"
}

# 自定义模式
build_custom_package() {
    log_info "进入自定义模式..."
    
    OFFLINE_DIR="offline_package_custom"
    rm -rf "$OFFLINE_DIR"
    mkdir -p "$OFFLINE_DIR"
    
    INCLUDE_SYSTEM_PKGS=false
    INCLUDE_PYTHON_PKGS=false
    INCLUDE_FONTS=false
    INCLUDE_EXECUTABLE=false
    
    echo -e "${BOLD}请选择要包含的组件（Y/N）：${NC}"
    echo ""
    
    read -p "是否包含系统依赖包 (.deb/.rpm)? (Y/n): " resp1
    [[ $resp1 =~ ^[Yy]$ ]] || [[ -z $resp1 ]] && INCLUDE_SYSTEM_PKGS=true
    
    read -p "是否包含Python依赖包? (Y/n): " resp2
    [[ $resp2 =~ ^[Yy]$ ]] || [[ -z $resp2 ]] && INCLUDE_PYTHON_PKGS=true
    
    read -p "是否包含中文字体? (Y/n): " resp3
    [[ $resp3 =~ ^[Yy]$ ]] || [[ -z $resp3 ]] && INCLUDE_FONTS=true
    
    read -p "是否打包可执行文件? (Y/n): " resp4
    [[ $resp4 =~ ^[Yy]$ ]] || [[ -z $resp4 ]] && INCLUDE_EXECUTABLE=true
    
    echo ""
    log_info "您的选择:"
    echo "  • 系统依赖: $INCLUDE_SYSTEM_PKGS"
    echo "  • Python包: $INCLUDE_PYTHON_PKGS"
    echo "  • 中文字体: $INCLUDE_FONTS"
    echo "  • 可执行文件: $INCLUDE_EXECUTABLE"
    echo ""
    
    read -p "确认？(Y/n): " confirm
    [[ ! $confirm =~ ^[Yy]$ ]] && [[ -n $confirm ]] && return
    
    # 按选择执行
    if [ "$INCLUDE_SYSTEM_PKGS" = true ]; then
        mkdir -p "$OFFLINE_DIR/dependencies/system_packages/deb"
        mkdir -p "$OFFLINE_DIR/dependencies/system_packages/rpm"
        
        # 下载系统包（根据当前OS）
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    log_info "下载 .deb 包..."
                    sudo apt-get install --reinstall --download-only \
                        -o Dir::Cache::Archives="$OFFLINE_DIR/dependencies/system_packages/deb" \
                        python3 python3-tk python3-pip fonts-wqy-zenhei 2>/dev/null || true
                    find /var/cache/apt/archives/ -name "*.deb" \
                        -exec mv {} "$OFFLINE_DIR/dependencies/system_packages/deb/" \; 2>/dev/null || true
                    sudo apt clean
                    ;;
                centos|rhel|fedora)
                    log_info "下载 .rpm 包..."
                    PKG_MGR="yum"
                    [ -x "$(command -v dnf)" ] && PKG_MGR="dnf"
                    for pkg in python3 python3-pip python3-tkinter wqy-zenhei-fonts; do
                        sudo $PKG_MGR download --destdir="$OFFLINE_DIR/dependencies/system_packages/rpm" "$pkg" 2>/dev/null || true
                    done
                    ;;
            esac
        fi
    fi
    
    if [ "$INCLUDE_PYTHON_PKGS" = true ]; then
        mkdir -p "$OFFLINE_DIR/dependencies/python_packages/wheels"
        mkdir -p "$OFFLINE_DIR/dependencies/python_packages/tarballs"
        
        log_info "下载Python包..."
        pip3 download -d "$OFFLINE_DIR/dependencies/python_packages/wheels" -r requirements.txt || true
        pip3 download --no-binary=:all: -d "$OFFLINE_DIR/dependencies/python_packages/tarballs" -r requirements.txt || true
    fi
    
    if [ "$INCLUDE_FONTS" = true ]; then
        mkdir -p "$OFFLINE_DIR/dependencies/fonts"
        
        log_info "下载字体..."
        cd "$OFFLINE_DIR/dependencies/fonts"
        wget -q --timeout=30 "https://github.com/google/fonts/raw/main/ofl/wenquanyizenhei/WenQuanYiZenHei-Regular.ttf" || true
        cd "$SCRIPT_DIR"
    fi
    
    # 复制项目文件
    cp *.py "$OFFLINE_DIR/"
    cp format_config.yaml "$OFFLINE_DIR/" 2>/dev/null || true
    cp requirements.txt "$OFFLINE_DIR/"
    cp install_offline.sh "$OFFLINE_DIR/" 2>/dev/null || true
    cp run_linux.sh "$OFFLINE_DIR/"
    
    if [ "$INCLUDE_EXECUTABLE" = true ]; then
        log_info "打包可执行文件..."
        pip3 install pyinstaller -q
        pyinstaller --onefile --windowed \
            --name "文档格式一键转换器V1" \
            --noconfirm \
            main.py && \
            cp dist/文档格式一键转换器V1 "$OFFLINE_DIR/" && \
            chmod +x "$OFFLINE_DIR/文档格式一键转换器V1"
    fi
    
    # 打包
    ARCHIVE_NAME="doc-formatter-v1-custom-offline-$(date +%Y%m%d).tar.gz"
    tar -czvf "$ARCHIVE_NAME" "$OFFLINE_DIR"
    
    SIZE=$(du -sh "$ARCHIVE_NAME" | cut -f1)
    log_success "自定义离线包已生成: $ARCHIVE_NAME ($SIZE)"
}

# 仅下载依赖
download_dependencies_only() {
    log_info "仅下载依赖（不打包可执行文件）..."
    
    # 创建临时脚本修改版本
    TEMP_SCRIPT="/tmp/download_deps_no_build.sh"
    sed 's/build_executable/# build_executable/' download_deps.sh > "$TEMP_SCRIPT"
    chmod +x "$TEMP_SCRIPT"
    
    # 运行（自动跳过打包）
    {
        echo "n" | bash "$TEMP_SCRIPT"
    } || true
    
    rm -f "$TEMP_SCRIPT"
    
    log_success "依赖下载完成"
}

# 显示结果摘要
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║       ✅ 离线包生成完成！                        ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}📦 生成的文件:${NC}"
    ls -lh *.tar.gz 2>/dev/null | awk '{print "  •", $9, "(" $5 ")"}'
    echo ""
    
    if [ -d "offline_package" ]; then
        echo -e "${BOLD}📁 解压后的目录结构:${NC}"
        tree -L 2 offline_package 2>/dev/null || find offline_package -maxdepth 2 -type f | head -20
        echo ""
    fi
    
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🚀 在离线环境中使用：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1. 将压缩包传输到离线机器（U盘、内网共享等）"
    echo ""
    echo "  2. 解压："
    echo "     tar -xzvf doc-formatter-*-offline-*.tar.gz"
    echo ""
    echo "  3. 进入目录："
    echo "     cd offline_package*"
    echo ""
    echo "  4. 安装："
    echo "     chmod +x install_offline.sh"
    echo "     ./install_offline.sh"
    echo ""
    echo "  5. 启动程序："
    echo "     ./run_linux.sh"
    echo ""
    echo -e "${CYAN}所有离线包已准备就绪！${NC}"
    echo ""
}

# 主函数
main() {
    check_prerequisites
    show_menu
    
    case "$MODE" in
        full)
            build_full_package
            ;;
        standard)
            build_standard_package
            ;;
        minimal)
            build_minimal_package
            ;;
        custom)
            build_custom_package
            ;;
        deps_only)
            download_dependencies_only
            ;;
    esac
    
    show_summary
}

# 运行主函数
main "$@"
