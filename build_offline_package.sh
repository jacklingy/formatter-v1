#!/bin/bash

# ============================================================
# Linux 离线分发包一键生成器 - V1.4.2
# 用途：在联网环境下生成包含所有依赖的完整离线包
# 使用方法: chmod +x build_offline_package.sh && ./build_offline_package.sh
# 输出: doc-formatter-V1.4.2-linux-offline.tar.gz (约 50-80MB)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║ 🐧 Linux 离线分发包生成器 V1.4.2                  ║"
echo "║    文档格式一键转换器 - 完全离线版                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="V1.4.2"
PACKAGE_NAME="doc-formatter-${VERSION}-linux-offline"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

check_prerequisites() {
    log_info "检查前置条件..."
    
    MISSING_TOOLS=()
    
    command -v python3 &> /dev/null || MISSING_TOOLS+=("python3")
    command -v pip3 &> /dev/null || MISSING_TOOLS+=("pip3")
    command -v tar &> /dev/null || MISSING_TOOLS+=("tar")
    
    if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
        log_error "缺少必要工具: ${MISSING_TOOLS[*]}"
        exit 1
    fi
    
    if [ ! -f "requirements.txt" ] || [ ! -f "main.py" ]; then
        log_error "未找到项目文件（main.py 或 requirements.txt）"
        exit 1
    fi
    
    log_success "前置条件检查通过"
}

download_python_dependencies() {
    log_info "下载 Python 依赖包..."
    
    mkdir -p "$PACKAGE_NAME/dependencies/wheels"
    
    log_info "尝试下载预编译的 Wheel 包（优先）..."
    
    pip3 download \
        --python-version 3 \
        --prefer-binary \
        --platform manylinux2014_x86_64 \
        --implementation cp \
        -d "$PACKAGE_NAME/dependencies/wheels" \
        -r requirements.txt \
        2>&1 | tee /tmp/pip_download.log | grep -E "(Downloading|Saved|ERROR|Collecting)" || true
    
    WHEEL_COUNT=$(ls "$PACKAGE_NAME/dependencies/wheels"/*.whl 2>/dev/null | wc -l)
    TAR_COUNT=$(ls "$PACKAGE_NAME/dependencies/wheels"/*.tar.gz 2>/dev/null | wc -l)
    TOTAL_COUNT=$((WHEEL_COUNT + TAR_COUNT))
    
    if [ "$TOTAL_COUNT" -lt 3 ]; then
        log_warn "预编译包不足，尝试下载源码包..."
        
        pip3 download \
            --no-binary=:all: \
            -d "$PACKAGE_NAME/dependencies/wheels" \
            -r requirements.txt \
            2>&1 | grep -E "(Downloading|Saved|ERROR)" || true
        
        WHEEL_COUNT=$(ls "$PACKAGE_NAME/dependencies/wheels"/*.whl 2>/dev/null | wc -l)
        TAR_COUNT=$(ls "$PACKAGE_NAME/dependencies/wheels"/*.tar.gz 2>/dev/null | wc -l)
        TOTAL_COUNT=$((WHEEL_COUNT + TAR_COUNT))
    fi
    
    if [ "$TOTAL_COUNT" -eq 0 ]; then
        log_error "依赖包下载失败！请检查网络连接或手动下载"
        log_info "您可以手动运行: pip3 download -d $PACKAGE_NAME/dependencies/wheels -r requirements.txt"
        exit 1
    fi
    
    log_success "已下载 $TOTAL_COUNT 个依赖包 ($WHEEL_COUNT 个 Wheel + $TAR_COUNT 个源码包)"
}

install_pyinstaller_and_build() {
    log_info "创建临时虚拟环境（避免系统Python保护机制）..."
    
    VENV_DIR=".build_venv"
    
    if [ -d "$VENV_DIR" ]; then
        rm -rf "$VENV_DIR"
    fi
    
    python3 -m venv "$VENV_DIR"
    
    if [ ! -f "$VENV_DIR/bin/activate" ]; then
        log_error "虚拟环境创建失败！"
        log_info "可能原因: 缺少 python3-venv 模块"
        log_info "请运行: sudo apt install python3.12-venv (或对应版本)"
        exit 1
    fi
    
    source "$VENV_DIR/bin/activate"
    log_success "虚拟环境已创建并激活"
    
    log_info "升级 pip..."
    pip install --upgrade pip -q 2>/dev/null || true
    
    log_info "安装 PyInstaller..."
    pip install pyinstaller -q
    
    if ! command -v pyinstaller &> /dev/null; then
        log_error "PyInstaller 安装失败！"
        deactivate
        rm -rf "$VENV_DIR"
        exit 1
    fi
    
    log_success "PyInstaller 安装成功: $(pyinstaller --version)"
    
    log_info "打包可执行文件（这可能需要 2-5 分钟）..."
    
    pyinstaller \
        --onefile \
        --windowed \
        --name "文档格式一键转换器V${VERSION}" \
        --noconfirm \
        --clean \
        main.py
    
    if [ ! -f "dist/文档格式一键转换器V${VERSION}" ]; then
        log_error "可执行文件打包失败！"
        deactivate
        rm -rf "$VENV_DIR"
        exit 1
    fi
    
    chmod +x "dist/文档格式一键转换器V${VERSION}"
    
    FILE_SIZE=$(du -h "dist/文档格式一键转换器V${VERSION}" | cut -f1)
    log_success "可执行文件已生成: $FILE_SIZE"
    
    deactivate
    rm -rf "$VENV_DIR"
    log_info "临时虚拟环境已清理"
}

copy_project_files() {
    log_info "复制项目文件..."
    
    cp dist/文档格式一键转换器V${VERSION} "$PACKAGE_NAME/"
    chmod +x "$PACKAGE_NAME/文档格式一键转换器V${VERSION}"
    
    for file in *.py format_config.yaml requirements.txt; do
        [ -f "$file" ] && cp "$file" "$PACKAGE_NAME/"
    done
    
    log_success "项目文件复制完成"
}

create_install_script() {
    log_info "创建一键安装脚本..."
    
    cat > "$PACKAGE_NAME/install.sh" << 'INSTALL_SCRIPT'
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════╗"
echo "║ 📦 文档格式转换器 - 离线安装       ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

log_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[✗] 错误: 未找到 python3，请先安装 Python 3.8+${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
log_info "检测到 Python $PYTHON_VERSION"

EXECUTABLE=$(find . -maxdepth 1 -name "文档格式一键转换器*" -type f | head -1)

if [ -n "$EXECUTABLE" ] && [ -f "$EXECUTABLE" ]; then
    log_info "发现可执行文件: $(basename $EXECUTABLE)"
    
    chmod +x "$EXECUTABLE"
    
    cat > run.sh << 'RUN_SCRIPT'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
EXECUTABLE=$(find . -maxdepth 1 -name "文档格式一键转换器*" -type f | head -1)
exec "$EXECUTABLE" "$@"
RUN_SCRIPT
    chmod +x run.sh
    
    log_success "安装完成！"
    echo ""
    echo -e "${BOLD}启动方式:${NC}"
    echo "  ./run.sh"
    echo ""
else
    log_warn "未发现可执行文件，将使用源码模式运行"
    
    if [ -d "dependencies/wheels" ]; then
        log_info "从本地安装 Python 依赖..."
        
        pip3 install --user --no-index --find-links=dependencies/wheels \
            -r requirements.txt 2>/dev/null || {
            pip3 install --user --no-index --find-links=dependencies/wheels \
                python-docx PyYAML markdown 2>/dev/null || true
        }
        
        log_success "依赖安装完成"
    else
        log_warn "未找到依赖包目录，请确保系统已安装所需依赖"
    fi
    
    cat > run.sh << 'RUN_SCRIPT2'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
exec python3 main.py "$@"
RUN_SCRIPT2
    chmod +x run.sh
    
    log_success "安装完成！"
    echo ""
    echo -e "${BOLD}启动方式:${NC}"
    echo "  ./run.sh"
    echo ""
fi

echo -e "${BOLD}${YELLOW}提示: 首次运行可能需要几秒钟初始化时间${NC}"
echo ""
read -p "是否立即启动程序？(Y/n): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]] && ./run.sh &
INSTALL_SCRIPT

    chmod +x "$PACKAGE_NAME/install.sh"
    log_success "安装脚本已创建"
}

create_readme() {
    log_info "创建离线使用说明..."
    
    cat > "$PACKAGE_NAME/README_离线使用说明.md" << 'EOF'
# 📄 文档格式一键转换器 V1.4.2 - Linux 离线版

## ✨ 特点

- **完全离线**：无需网络连接即可运行
- **开箱即用**：所有依赖已包含在内
- **简单易用**：一条命令即可启动

## 📦 包含内容

```
├── 文档格式一键转换器V1.4.2    # 可执行文件（推荐）
├── dependencies/                 # Python 依赖包
│   └── wheels/                   # Wheel 格式包
├── install.sh                    # 一键安装脚本
├── run.sh                        # 启动脚本
├── main.py                       # 源代码入口
├── format_config.yaml            # 配置文件模板
└── README_离线使用说明.md         # 本文件
```

## 🚀 快速开始（3步）

### 方式一：使用可执行文件（推荐）

```bash
# 1. 解压压缩包
tar -xzvf doc-formatter-*-linux-offline.tar.gz

# 2. 进入目录
cd doc-formatter-*-linux-offline

# 3. 运行程序
./文档格式一键转换器V1.4.2
```

### 方式二：使用安装脚本

```bash
# 1. 解压压缩包
tar -xzvf doc-formatter-*-linux-offline.tar.gz

# 2. 进入目录
cd doc-formatter-*-linux-offline

# 3. 运行安装脚本
chmod +x install.sh
./install.sh

# 4. 启动程序
./run.sh
```

## ⚙️ 系统要求

### 必要条件

- **操作系统**: Linux (Ubuntu/Debian/CentOS/Fedora/Arch 等)
- **Python**: 3.8+ （如果使用源码模式）
- **GUI环境**: X11 或 Wayland 图形界面
- **中文字体**: 系统需安装中文字体（如文泉驿）

### 可选条件

- 使用可执行文件模式时，**无需安装 Python**

## 🔧 常见问题

### Q1: 提示 "Permission denied"

```bash
chmod +x 文档格式一键转换器V1.4.2
./文档格式一键转换器V1.4.2
```

### Q2: 中文显示乱码或方块

安装中文字体：

```bash
# Ubuntu/Debian
sudo apt install fonts-wqy-zenhei fonts-wqy-microhei

# CentOS/RHEL/Fedora
sudo yum install wqy-zenhei-fonts

# Arch Linux
sudo pacman -S wqy-zenhei
```

### Q3: tkinter 相关错误

```bash
# Ubuntu/Debian
sudo apt install python3-tk

# CentOS/RHEL/Fedora
sudo yum install python3-tkinter
```

### Q4: 如何自定义格式？

编辑 `format_config.yaml` 文件，或通过程序界面的"格式设置"按钮。

## 📋 功能特性

- ✅ Markdown 转 Word 文档
- ✅ Word 文档格式化（页码、字体、段落等）
- ✅ 支持多种 Markdown 格式（标题、表格、列表、代码块等）
- ✅ 自定义格式配置
- ✅ 中文路径和文件名支持

## 💡 使用技巧

1. **批量处理**: 可以同时选择多个文件进行转换
2. **配置保存**: 格式设置会自动保存，下次打开自动加载
3. **原文件保护**: 所有操作不会修改原始文件
4. **拖拽支持**: 支持将文件拖拽到窗口中

## 📞 技术支持

如遇问题，请检查：
1. 系统是否满足最低要求
2. 是否有足够的磁盘空间（建议 100MB+）
3. 是否有图形界面环境（不能纯命令行运行）

---

**版本**: V1.4.2  
**更新日期**: 2025-05-20  
**适用平台**: Linux x86_64
EOF

    log_success "说明文档已创建"
}

package_archive() {
    log_info "创建分发压缩包..."
    
    ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"
    tar -czvf "$ARCHIVE_NAME" "$PACKAGE_NAME"
    
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
    PACKAGE_SIZE=$(du -sh "$PACKAGE_NAME" | cut -f1)
    
    log_success "离线分发包已生成!"
    echo ""
    echo -e "${BOLD}📦 输出文件:${NC}"
    echo "  • 压缩包: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
    echo "  • 解压后: $PACKAGE_NAME ($PACKAGE_SIZE)"
    echo ""
    echo -e "${BOLD}📁 目录内容:${NC}"
    ls -lh "$PACKAGE_NAME/" | tail -n +1
}

show_completion_message() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║           ✅ 离线分发包生成成功！                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}🎉 恭喜！Linux 离线分发包已准备就绪！${NC}"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}📦 分发文件:${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  文件名: ${PACKAGE_NAME}.tar.gz"
    ls -lh "${PACKAGE_NAME}.tar.gz" 2>/dev/null | awk '{print "  大小: " $5}'
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🚀 用户使用步骤（离线环境）：${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1️⃣  将 ${PACKAGE_NAME}.tar.gz 传输到目标机器"
    echo "     （U盘、移动硬盘、内网共享等）"
    echo ""
    echo "  2️⃣  解压文件:"
    echo "     tar -xzvf ${PACKAGE_NAME}.tar.gz"
    echo ""
    echo "  3️⃣  进入目录:"
    echo "     cd ${PACKAGE_NAME}"
    echo ""
    echo "  4️⃣  运行程序（二选一）:"
    echo ""
    echo "     ${BOLD}方式 A（推荐）:${NC} 直接运行可执行文件"
    echo "       ./文档格式一键转换器V${VERSION}"
    echo ""
    echo "     ${BOLD}方式 B:${NC} 使用安装脚本"
    echo "       ./install.sh"
    echo "       ./run.sh"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}💡 重要提示:${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  ✅ 无需网络连接"
    echo "  ✅ 无需单独安装 Python 依赖（使用可执行文件模式）"
    echo "  ✅ 开箱即用，解压即运行"
    echo "  ⚠️  需要有图形界面环境（X11/Wayland）"
    echo "  ⚠️  如中文显示异常，请安装中文字体"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}🔗 下一步操作:${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  1. 测试运行: cd ${PACKAGE_NAME} && ./文档格式一键转换器V${VERSION}"
    echo "  2. 分发文件: 将 tar.gz 文件分享给 Linux 用户"
    echo "  3. 查看详情: cat ${PACKAGE_NAME}/README_离线使用说明.md"
    echo ""
    echo -e "${CYAN}感谢使用！${NC}"
    echo ""
}

cleanup_temp_files() {
    log_info "清理临时文件..."
    
    rm -rf build/ *.spec 2>/dev/null || true
    
    log_success "清理完成"
}

main() {
    check_prerequisites
    
    echo ""
    echo -e "${BOLD}即将执行以下操作：${NC}"
    echo "  1. 下载 Python 依赖包（wheel 格式）"
    echo "  2. 使用 PyInstaller 打包可执行文件"
    echo "  3. 复制项目文件和依赖"
    echo "  4. 创建安装和使用脚本"
    echo "  5. 打包为 tar.gz 分发文件"
    echo ""
    read -p "是否继续？(Y/n): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]] && { log_info "操作已取消"; exit 0; }
    
    rm -rf "$PACKAGE_NAME"
    mkdir -p "$PACKAGE_NAME"
    
    download_python_dependencies
    install_pyinstaller_and_build
    copy_project_files
    create_install_script
    create_readme
    package_archive
    cleanup_temp_files
    show_completion_message
}

main "$@"
