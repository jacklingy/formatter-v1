#!/bin/bash

# ============================================================
# Linux 离线分发包生成器 V1.4.2 - 简化版
# 解决：externally-managed-environment 错误
# 使用方法: chmod +x build_linux_offline.sh && ./build_linux_offline.sh
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
echo "╔═══════════════════════════════════════════════════╗"
echo "║ 🐧 Linux 离线包生成器 V1.4.2 (简化版)           ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

VERSION="V1.4.2"
PACKAGE_NAME="doc-formatter-${VERSION}-linux-offline"

log_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo -e "${BOLD}本脚本将自动完成以下操作：${NC}"
echo "  1. ✅ 创建虚拟环境（避免系统Python保护）"
echo "  2. ✅ 在虚拟环境中安装所有依赖"
echo "  3. ✅ 打包可执行文件"
echo "  4. ✅ 生成分发包"
echo ""
read -p "是否继续？(Y/n): " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]] && exit 0

# ==================== 步骤 1: 清理并创建虚拟环境 ====================
log_info "步骤 1/5: 准备工作..."

rm -rf "$PACKAGE_NAME" .build_venv build/ dist/ *.spec 2>/dev/null || true

if ! command -v python3 &> /dev/null; then
    log_error "未找到 python3！请先安装 Python 3.8+"
    exit 1
fi

PYTHON_VER=$(python3 --version | awk '{print $2}')
log_info "Python 版本: $PYTHON_VER"

# 检查 venv 模块是否可用
if ! python3 -m venv --help &> /dev/null; then
    log_error "python3-venv 模块未安装！"
    echo ""
    echo "请根据您的系统安装："
    echo "  Ubuntu/Debian: sudo apt install python3$(echo $PYTHON_VER | cut -d. -f1,2)-venv"
    echo "  CentOS/RHEL:   sudo yum install python3-devel"
    echo "  Fedora:        sudo dnf install python3-virtualenv"
    exit 1
fi

log_success "前置检查通过"

# ==================== 步骤 2: 创建虚拟环境 ====================
echo ""
log_info "步骤 2/5: 创建虚拟环境..."

VENV_DIR=".build_venv"

log_info "创建虚拟环境: $VENV_DIR"
python3 -m venv "$VENV_DIR"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    log_error "虚拟环境创建失败！"
    exit 1
fi

source "$VENV_DIR/bin/activate"
log_success "虚拟环境已激活"

# 升级 pip
log_info "升级 pip..."
pip install --upgrade pip -q 2>/dev/null || true
log_success "Pip 已升级到最新版本"

# ==================== 步骤 3: 安装依赖并打包 ====================
echo ""
log_info "步骤 3/5: 安装依赖并打包可执行文件..."

log_info "安装项目依赖..."
pip install -r requirements.txt -q

log_info "安装 PyInstaller..."
pip install pyinstaller -q

log_info "开始打包（约需 2-5 分钟）..."
pyinstaller \
    --onefile \
    --windowed \
    --name "文档格式一键转换器V${VERSION}" \
    --noconfirm \
    --clean \
    main.py

if [ ! -f "dist/文档格式一键转换器V${VERSION}" ]; then
    log_error "打包失败！请检查错误信息"
    deactivate
    rm -rf "$VENV_DIR"
    exit 1
fi

FILE_SIZE=$(du -h "dist/文档格式一键转换器V${VERSION}" | cut -f1)
log_success "可执行文件已生成: $FILE_SIZE"

# ==================== 步骤 4: 组装分发包 ====================
echo ""
log_info "步骤 4/5: 组装离线包..."

mkdir -p "$PACKAGE_NAME"

# 复制可执行文件
cp "dist/文档格式一键转换器V${VERSION}" "$PACKAGE_NAME/"
chmod +x "$PACKAGE_NAME/文档格式一键转换器V${VERSION}"
log_info "已复制可执行文件"

# 复制源代码（备用）
for file in *.py format_config.yaml requirements.txt; do
    [ -f "$file" ] && cp "$file" "$PACKAGE_NAME/"
done
log_info "已复制源代码文件"

# 创建启动脚本
cat > "$PACKAGE_NAME/run.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
EXECUTABLE=$(find . -maxdepth 1 -name "文档格式一键转换器*" -type f | head -1)
if [ -n "$EXECUTABLE" ]; then
    exec "$EXECUTABLE" "$@"
else
    exec python3 main.py "$@"
fi
EOF
chmod +x "$PACKAGE_NAME/run.sh"
log_info "已创建启动脚本"

# 创建使用说明
cat > "$PACKAGE_NAME/README.md" << EOF
# 📄 文档格式一键转换器 ${VERSION} - Linux 离线版

## 🚀 快速启动

\`\`\`bash
# 方式一：直接运行（推荐）
./文档格式一键转换器${VERSION}

# 方式二：使用启动脚本
./run.sh
\`\`\`

## ⚙️ 系统要求

- Linux x86_64 系统
- 图形界面 (X11/Wayland)
- 无需安装 Python 或任何依赖！

## 💡 提示

- 首次启动可能需要几秒钟
- 支持中文路径和文件名
- 配置文件: format_config.yaml

## 🔧 常见问题

**中文乱码**: 安装中文字体
\`\`\`bash
sudo apt install fonts-wqy-zenhei  # Debian/Ubuntu
sudo yum install wqy-zenhei-fonts # CentOS/RHEL
\`\`\`

**权限不足**:
\`\`\`bash
chmod +x 文档格式一键转换器${VERSION}
\`\`\`

---
版本: ${VERSION}
日期: $(date +%Y-%m-%d)
EOF

log_info "已创建使用说明"

# ==================== 步骤 5: 打包分发 ====================
echo ""
log_info "步骤 5/5: 创建分发压缩包..."

ARCHIVE_NAME="${PACKAGE_NAME}.tar.gz"
tar -czvf "$ARCHIVE_NAME" "$PACKAGE_NAME"

ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
PACKAGE_SIZE=$(du -sh "$PACKAGE_NAME" | cut -f1)

# 清理虚拟环境
deactivate
rm -rf "$VENV_DIR"
rm -rf build/ dist/ *.spec 2>/dev/null || true
log_info "已清理临时文件"

# ==================== 完成 ====================
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║          ✅ 离线分发包生成成功！                ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BOLD}📦 输出文件:${NC}"
echo "  文件名: ${ARCHIVE_NAME}"
echo "  大小:   ${ARCHIVE_SIZE}"
echo ""
echo -e "${BOLD}📁 包含内容:${NC}"
ls -lh "$PACKAGE_NAME/" | tail -n +1
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🎯 用户使用方法（在离线环境下）：${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  1️⃣  传输 ${ARCHIVE_NAME} 到目标机器"
echo ""
echo "  2️⃣  解压:"
echo "      tar -xzvf ${ARCHIVE_NAME}"
echo ""
echo "  3️⃣  运行:"
echo "      cd ${PACKAGE_NAME}"
echo "      ./文档格式一键转换器${VERSION}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}✨ 特点:${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  ✅ 完全离线，无需网络"
echo "  ✅ 无需安装 Python"
echo "  ✅ 开箱即用，解压即运行"
echo "  ✅ 单文件分发，便于携带"
echo ""
echo -e "${CYAN}感谢使用！${NC}"
echo ""
