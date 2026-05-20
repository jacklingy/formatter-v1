#!/bin/bash

# ============================================================
# Linux .deb 包生成器 V1.4.2
# 用途：生成可双击安装的 Debian/Ubuntu 安装包
# 使用方法: chmod +x build_deb.sh && ./build_deb.sh
# 输出: doc-formatter-v1.4.2-amd64.deb
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
echo "║ 📦 .deb 安装包生成器 V1.4.2                     ║"
echo "║    支持 Debian/Ubuntu 双击安装                   ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

APP_NAME="doc-formatter"
APP_NAME_CN="文档格式一键转换器"
VERSION="1.4.2"
PKG_VERSION="${VERSION}-1"
ARCH="amd64"
DEB_NAME="${APP_NAME}_${VERSION}-${ARCH}.deb"

log_info() { echo -e "${BLUE}[ℹ]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo -e "${BOLD}本脚本将自动完成：${NC}"
echo "  1. 创建虚拟环境并安装依赖"
echo "  2. 使用 PyInstaller 打包可执行文件"
echo "  3. 生成 .deb 安装包（支持双击安装）"
echo ""
read -p "是否继续？(Y/n): " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]] && exit 0

# ==================== 步骤 1: 环境检查 ====================
echo ""
log_info "步骤 1/6: 环境检查..."

if ! command -v python3 &> /dev/null; then
    log_error "未找到 python3！"
    exit 1
fi

PYTHON_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
log_info "Python 版本: $PYTHON_VER"

if ! python3 -m venv --help &> /dev/null; then
    log_error "python3-venv 未安装！"
    log_info "请运行: sudo apt install python3${PYTHON_VER}-venv"
    exit 1
fi

if ! command -v dpkg-deb &> /dev/null; then
    log_error "dpkg-deb 未安装！"
    log_info "请运行: sudo apt install dpkg"
    exit 1
fi

log_success "环境检查通过"

# ==================== 步骤 2: 创建虚拟环境 ====================
echo ""
log_info "步骤 2/6: 创建虚拟环境..."

VENV_DIR=".build_venv"
rm -rf "$VENV_DIR" build/ dist/ *.spec 2>/dev/null || true

python3 -m venv "$VENV_DIR"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
    log_error "虚拟环境创建失败！"
    exit 1
fi

source "$VENV_DIR/bin/activate"
log_success "虚拟环境已激活"

pip install --upgrade pip -q 2>/dev/null || true

# ==================== 步骤 3: 安装依赖并打包 ====================
echo ""
log_info "步骤 3/6: 安装依赖并打包..."

pip install -r requirements.txt -q

log_info "安装 PyInstaller..."
pip install pyinstaller -q

log_info "开始打包（约需 2-5 分钟）..."
pyinstaller \
    --onefile \
    --windowed \
    --name "${APP_NAME}" \
    --noconfirm \
    --clean \
    --hidden-import=tkinter \
    --hidden-import=tkinter.ttk \
    --hidden-import=tkinter.messagebox \
    --hidden-import=tkinter.filedialog \
    --hidden-import=config_manager \
    --hidden-import=converter \
    --hidden-import=formatter \
    --add-data "format_config.yaml:." \
    main.py

if [ ! -f "dist/${APP_NAME}" ]; then
    log_error "打包失败！"
    deactivate
    rm -rf "$VENV_DIR"
    exit 1
fi

FILE_SIZE=$(du -h "dist/${APP_NAME}" | cut -f1)
log_success "可执行文件已生成: $FILE_SIZE"

# ==================== 步骤 4: 组装 .deb 包目录结构 ====================
echo ""
log_info "步骤 4/6: 组装 .deb 包..."

DEB_ROOT="${APP_NAME}_${VERSION}_${ARCH}"
rm -rf "$DEB_ROOT" 2>/dev/null || true

INSTALL_DIR="/opt/${APP_NAME}"

mkdir -p "${DEB_ROOT}/DEBIAN"
mkdir -p "${DEB_ROOT}${INSTALL_DIR}"
mkdir -p "${DEB_ROOT}/usr/share/applications"
mkdir -p "${DEB_ROOT}/usr/share/doc/${APP_NAME}"
mkdir -p "${DEB_ROOT}/usr/bin"

# --- 复制可执行文件 ---
cp "dist/${APP_NAME}" "${DEB_ROOT}${INSTALL_DIR}/"
chmod 755 "${DEB_ROOT}${INSTALL_DIR}/${APP_NAME}"

# --- 复制配置文件 ---
cp format_config.yaml "${DEB_ROOT}${INSTALL_DIR}/"
cp requirements.txt "${DEB_ROOT}${INSTALL_DIR}/"

# --- 复制源代码（备用） ---
for f in *.py; do
    [ -f "$f" ] && cp "$f" "${DEB_ROOT}${INSTALL_DIR}/"
done

log_info "已复制程序文件"

# --- 创建启动脚本 ---
cat > "${DEB_ROOT}${INSTALL_DIR}/run.sh" << 'LAUNCHER'
#!/bin/bash
INSTALL_DIR="/opt/doc-formatter"
cd "$INSTALL_DIR"

# 设置环境变量
export DISPLAY=${DISPLAY:-:0}
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export PYTHONPATH="$INSTALL_DIR:$PYTHONPATH"

# 检查tkinter
if ! python3 -c "import tkinter" 2>/dev/null; then
    echo "错误: tkinter未安装"
    echo "请运行: sudo apt install python3-tk"
    exit 1
fi

# 运行程序
exec "./doc-formatter" "$@"
LAUNCHER
chmod 755 "${DEB_ROOT}${INSTALL_DIR}/run.sh"

# --- 创建 /usr/bin 符号链接脚本 ---
cat > "${DEB_ROOT}/usr/bin/${APP_NAME}" << 'BINLINK'
#!/bin/bash
exec /opt/doc-formatter/run.sh "$@"
BINLINK
chmod 755 "${DEB_ROOT}/usr/bin/${APP_NAME}"

log_info "已创建启动脚本和命令行入口"

# --- 创建桌面快捷方式 ---
cat > "${DEB_ROOT}/usr/share/applications/${APP_NAME}.desktop" << DESKTOP
[Desktop Entry]
Name=${APP_NAME_CN}
Name[en]=Document Formatter
Comment=Markdown to Word converter and document formatter
Comment[zh_CN]=Markdown转Word文档格式化工具
Exec=/opt/doc-formatter/run.sh
Icon=application-msword
Terminal=false
Type=Application
Categories=Office;TextEditor;Utility;
StartupNotify=true
Path=/opt/doc-formatter
MimeType=application/vnd.openxmlformats-officedocument.wordprocessingml.document;text/markdown;
Keywords=word;markdown;formatter;converter;
DESKTOP

log_info "已创建桌面快捷方式"

# --- 创建 control 文件 ---
INSTALLED_SIZE=$(du -sk "${DEB_ROOT}" | cut -f1)

cat > "${DEB_ROOT}/DEBIAN/control" << CONTROL
Package: ${APP_NAME}
Version: ${PKG_VERSION}
Section: office
Priority: optional
Architecture: ${ARCH}
Depends: libx11-6, libxext6, libxrender1, libxtst6, libxi6, libglib2.0-0, libgl1, fonts-wqy-zenhei
Recommends: fonts-wqy-microhei
Maintainer: Doc Formatter Team <formatter@example.com>
Description: ${APP_NAME_CN}
 A tool for converting Markdown to Word documents and
 formatting Word documents with customizable styles.
 Supports Chinese text, tables, headings, lists, etc.
Description[zh_CN]: ${APP_NAME_CN} - Markdown转Word和Word格式化工具
 支持Markdown转Word文档，支持标题、表格、列表、
 引用、代码块等格式转换，支持自定义格式配置。
Installed-Size: ${INSTALLED_SIZE}
CONTROL

log_info "已创建 control 文件"

# --- 创建 postinst 脚本（安装后执行） ---
cat > "${DEB_ROOT}/DEBIAN/postinst" << POSTINST
#!/bin/bash
set -e

# 检查必要的依赖
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "警告: $1 未安装，某些功能可能无法使用"
    fi
}

# 检查Python和tkinter
if ! python3 -c "import tkinter" 2>/dev/null; then
    echo "错误: python3-tk 未安装"
    echo "请运行: sudo apt install python3-tk"
    exit 1
fi

# 更新桌面数据库
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database -q /usr/share/applications/ 2>/dev/null || true
fi

# 更新图标缓存
if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor/ 2>/dev/null || true
fi

# 更新 MIME 数据库
if command -v update-mime-database &> /dev/null; then
    update-mime-database /usr/share/mime/ 2>/dev/null || true
fi

# 创建用户配置目录
USER_CONFIG_DIR="\${HOME}/.config/doc-formatter"
mkdir -p "\${USER_CONFIG_DIR}" 2>/dev/null || true

# 复制默认配置（如果不存在）
if [ ! -f "\${USER_CONFIG_DIR}/format_config.yaml" ] && [ -f "/opt/doc-formatter/format_config.yaml" ]; then
    cp "/opt/doc-formatter/format_config.yaml" "\${USER_CONFIG_DIR}/" 2>/dev/null || true
fi

echo ""
echo "✅ ${APP_NAME_CN} 安装成功！"
echo ""
echo "启动方式："
echo "  • 应用菜单 → 办公 → ${APP_NAME_CN}"
echo "  • 命令行: doc-formatter"
echo "  • 配置文件: ~/.config/doc-formatter/format_config.yaml"
echo ""
POSTINST
chmod 755 "${DEB_ROOT}/DEBIAN/postinst"

# --- 创建 prerm 脚本（卸载前执行） ---
cat > "${DEB_ROOT}/DEBIAN/prerm" << PRERM
#!/bin/bash
set -e
# 卸载前无需特殊处理
PRERM
chmod 755 "${DEB_ROOT}/DEBIAN/prerm"

# --- 创建 postrm 脚本（卸载后执行） ---
cat > "${DEB_ROOT}/DEBIAN/postrm" << POSTRM
#!/bin/bash
set -e

# 更新桌面数据库
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database -q /usr/share/applications/ 2>/dev/null || true
fi

# 询问是否删除用户配置
if [ -d "\${HOME}/.config/doc-formatter" ]; then
    echo ""
    read -p "是否删除用户配置文件？(~/.config/doc-formatter) [y/N]: " -n 1 -r
    echo
    if [[ \$REPLY =~ ^[Yy]$ ]]; then
        rm -rf "\${HOME}/.config/doc-formatter"
        echo "已删除用户配置"
    else
        echo "已保留用户配置"
    fi
fi
POSTRM
chmod 755 "${DEB_ROOT}/DEBIAN/postrm"

# --- 创建 changelog ---
mkdir -p "${DEB_ROOT}/usr/share/doc/${APP_NAME}"

cat > "${DEB_ROOT}/usr/share/doc/${APP_NAME}/changelog.Debian" << CHANGELOG
${APP_NAME} (${PKG_VERSION}) stable; urgency=low

  * V1.4.2: 修复表格黑色小方块问题
  * V1.4.1: 修复加粗、斜体、引用等内联格式
  * V1.4.0: 全面重构 Markdown 转换引擎
  * V1.3.0: 新增 Markdown 转 Word 功能
  * V1.2.0: 修复页码顺序编号问题
  * V1.1.0: 初始发布

 -- Doc Formatter Team <formatter@example.com>  $(date -R)
CHANGELOG
gzip -9 "${DEB_ROOT}/usr/share/doc/${APP_NAME}/changelog.Debian"

# --- 创建 copyright ---
cat > "${DEB_ROOT}/usr/share/doc/${APP_NAME}/copyright" << COPYRIGHT
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${APP_NAME}
Source: https://github.com/example/doc-formatter

Files: *
Copyright: 2024-2025 Doc Formatter Team
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files, to deal
 in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software.
COPYRIGHT

log_success ".deb 包目录结构组装完成"

# ==================== 步骤 5: 构建 .deb 包 ====================
echo ""
log_info "步骤 5/6: 构建 .deb 包..."

dpkg-deb --build --root-owner-group "$DEB_ROOT" "$DEB_NAME"

if [ ! -f "$DEB_NAME" ]; then
    log_error ".deb 包构建失败！"
    deactivate
    rm -rf "$VENV_DIR"
    exit 1
fi

DEB_SIZE=$(du -h "$DEB_NAME" | cut -f1)
log_success ".deb 包已生成: $DEB_NAME ($DEB_SIZE)"

# ==================== 步骤 6: 清理 ====================
echo ""
log_info "步骤 6/6: 清理临时文件..."

deactivate
rm -rf "$VENV_DIR"
rm -rf "$DEB_ROOT"
rm -rf build/ dist/ *.spec 2>/dev/null || true
log_success "清理完成"

# ==================== 完成 ====================
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║          ✅ .deb 安装包生成成功！                ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BOLD}📦 输出文件:${NC}"
echo "  文件名: ${DEB_NAME}"
echo "  大小:   ${DEB_SIZE}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🎯 用户安装方式：${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  ${BOLD}方式 1: 双击安装（推荐）${NC}"
echo "    在文件管理器中双击 ${DEB_NAME}"
echo "    → 软件中心自动打开并安装"
echo ""
echo "  ${BOLD}方式 2: 命令行安装${NC}"
echo "    sudo dpkg -i ${DEB_NAME}"
echo "    sudo apt-get install -f"
echo ""
echo "  ${BOLD}方式 3: GDebi 安装（推荐）${NC}"
echo "    sudo apt install gdebi-core"
echo "    sudo gdebi ${DEB_NAME}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🚀 安装后启动：${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  • 应用菜单: 办公 → ${APP_NAME_CN}"
echo "  • 命令行:   doc-formatter"
echo "  • 配置文件: ~/.config/doc-formatter/format_config.yaml"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}🗑️  卸载方式：${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  sudo dpkg -r ${APP_NAME}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}📋 包信息：${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  包名:     ${APP_NAME}"
echo "  版本:     ${PKG_VERSION}"
echo "  架构:     ${ARCH}"
echo "  安装路径: /opt/${APP_NAME}"
echo "  依赖:     libx11-6, fonts-wqy-zenhei 等"
echo ""
echo -e "${CYAN}感谢使用！${NC}"
echo ""
