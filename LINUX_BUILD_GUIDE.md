# Linux版本打包操作手册 - V1.3-RELEASE

## 📋 前置条件检查清单

### ✅ 必须具备的环境
- [ ] Linux操作系统（Ubuntu 18.04+/Debian 10+/CentOS 7+等）
- [ ] Python 3.8+ 已安装
- [ ] tkinter GUI支持库已安装
- [ ] pip包管理器已安装
- [ ] 项目源代码已下载/克隆
- [ ] 网络连接（用于下载依赖）

---

## 🚀 方式一：使用自动打包脚本（推荐）

### 步骤1：准备环境

```bash
# Ubuntu/Debian系统
sudo apt update
sudo apt install -y python3 python3-pip python3-tk fonts-wqy-zenhei

# CentOS/RHEL系统
sudo yum install -y python3 python3-pip tkinter wqy-zenhei-fonts

# Fedora系统
sudo dnf install -y python3 python3-pip python3-tkinter wqy-zenhei-fonts

# Arch Linux系统
sudo pacman -S python python-pip tk wqy-zenhei
```

### 步骤2：进入项目目录

```bash
cd /path/to/formatter-v1
```

### 步骤3：执行自动打包脚本

```bash
# 添加执行权限
chmod +x build_linux.sh

# 执行打包
./build_linux.sh
```

**脚本会自动完成以下工作**：
- ✅ 检查Python3环境
- ✅ 验证tkinter安装
- ✅ 安装Python依赖包
- ✅ 安装PyInstaller
- ✅ 执行打包过程
- ✅ 添加执行权限
- ✅ 显示使用说明

### 步骤4：验证打包结果

```bash
# 检查生成的文件
ls -lh dist/

# 测试运行
cd dist
./文档格式一键转换器V1.3-RELEASE --version
# 或直接运行
./文档格式一键转换器V1.3-RELEASE
```

---

## 🔧 方式二：手动打包（适合高级用户）

### 步骤1：安装系统依赖

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y python3 python3-pip python3-tk

# 验证安装
python3 --version
python3 -c "import tkinter; print('tkinter OK')"
```

### 步骤2：创建虚拟环境（推荐）

```bash
cd /path/to/formatter-v1

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate
```

### 步骤3：安装Python依赖

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 步骤4：安装PyInstaller

```bash
pip install pyinstaller
```

### 步骤5：执行打包命令

```bash
pyinstaller \
    --onefile \
    --windowed \
    --name "文档格式一键转换器V1.3-RELEASE" \
    --noconfirm \
    main.py
```

**打包参数说明**：
| 参数 | 作用 | 说明 |
|------|------|------|
| `--onefile` | 单文件模式 | 打包成单个可执行文件 |
| `--windowed` | 无控制台窗口 | GUI模式运行 |
| `--name` | 输出文件名 | 指定可执行文件名称 |
| `--noconfirm` | 自动确认 | 覆盖旧文件不提示 |

### 步骤6：添加执行权限并测试

```bash
chmod +x dist/文档格式一键转换器V1.3-RELEASE

# 运行测试
./dist/文档格式一键转换器V1.3-RELEASE
```

---

## 📦 高级打包选项

### 选项A：添加图标文件

```bash
# 准备图标文件（.png或.icns）
pyinstaller \
    --onefile \
    --windowed \
    --icon=icon.png \
    --name "文档格式一键转换器V1.3-RELEASE" \
    main.py
```

### 选项B：添加数据文件（如配置模板）

```bash
pyinstaller \
    --onefile \
    --windowed \
    --add-data "format_config_template.yaml:." \
    --name "文档格式一键转换器V1.3-RELEASE" \
    main.py
```

### 选项C：调试模式打包

```bash
# 控制台模式（显示错误信息）
pyinstaller \
    --onefile \
    --console \
    --name "文档格式一键转换器V1.3-DEBUG" \
    main.py
```

---

## ✅ 打包成功验证清单

打包完成后，请验证以下项目：

### 文件检查
- [ ] `dist/文档格式一键转换器V1.3-RELEASE` 文件存在
- [ ] 文件大小合理（通常30-80MB）
- [ ] 文件具有可执行权限

### 功能测试
- [ ] 双击或命令行能正常启动程序
- [ ] GUI界面正常显示
- [ ] 中文显示正常（无乱码）
- [ ] Word文档转换功能正常
- [ ] Markdown转Word功能正常
- [ ] 页码功能正常

### 兼容性测试
- [ ] 在目标Linux发行版上运行无报错
- [ ] 依赖的系统库完整

---

## 🐛 常见问题解决

### 问题1：缺少tkinter

**错误信息**：`ModuleNotFoundError: No module named 'tkinter'`

**解决方案**：
```bash
# Ubuntu/Debian
sudo apt install python3-tk

# CentOS/RHEL
sudo yum install tkinter

# Fedora
sudo dnf install python3-tkinter
```

### 问题2：中文字体显示异常

**解决方案**：
```bash
# 安装中文字体
sudo apt install fonts-wqy-zenhei fonts-wqy-microhei

# 或复制Windows字体到Linux
mkdir -p ~/.fonts
cp /path/to/windows/fonts/*.ttf ~/.fonts/
fc-cache -fv
```

### 问题3：权限不足

**错误信息**：`Permission denied`

**解决方案**：
```bash
chmod +x dist/文档格式一键转换器V1.3-RELEASE
```

### 问题4：依赖安装失败

**解决方案**：
```bash
# 使用虚拟环境隔离依赖
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 问题5：打包后程序无法启动

**排查步骤**：
```bash
# 以控制台模式重新打包查看错误
pyinstaller --onefile --console --name debug_test main.py
./dist/debug_test

# 检查缺失的库
ldd dist/文档格式一键转换器V1.3-RELEASE
```

---

## 📤 分发打包结果

### 方法1：直接分发可执行文件

```bash
# 创建发布包
tar -czvf doc-formatter-V1.3-RELEASE-linux.tar.gz \
    -C dist \
    文档格式一键转换器V1.3-RELEASE \
    README_LINUX.md \
    CHANGELOG_V1.3-RELEASE.md
```

### 方法2：创建安装包（.deb/.rpm）

#### Debian/Ubuntu (.deb)
```bash
# 安装打包工具
sudo apt install -y dpkg-dev

# 创建deb包结构
mkdir -p pkg/DEBIAN
mkdir -p pkg/usr/local/bin
mkdir -p usr/share/applications

# 复制文件
cp dist/文档格式一键转换器V1.3-RELEASE pkg/usr/local/bin/
chmod 755 pkg/usr/local/bin/文档格式一键转换器V1.3-RELEASE

# 创建control文件
cat > pkg/DEBIAN/control << EOF
Package: doc-formatter
Version: 1.3-RELEASE
Section: utils
Priority: optional
Architecture: amd64
Depends: python3, libgtk-3-0, fonts-wqy-zenhei
Maintainer: Your Name <email@example.com>
Description: Document format one-click converter
 A tool to convert Word documents and Markdown files with formatting.
EOF

# 构建deb包
dpkg-deb --build pkg doc-formatter_1.3-RELEASE_amd64.deb
```

#### CentOS/RHEL/Fedora (.rpm)
```bash
# 安装rpmbuild
sudo yum install -y rpm-build

# 创建spec文件和构建rpm包
# （详细步骤略，可参考官方文档）
```

---

## 🎯 下一步操作

打包完成后，您可以：

1. **测试应用**：在多个Linux发行版上测试兼容性
2. **创建桌面快捷方式**：参考README_LINUX.md中的桌面集成部分
3. **编写用户手册**：为最终用户提供使用说明
4. **上传到服务器**：通过网站或网盘分发给用户
5. **CI/CD集成**：将打包流程自动化到GitHub Actions/GitLab CI

---

## 📞 技术支持

如遇到问题，请检查：

1. **日志文件**：打包过程中的输出信息
2. **系统环境**：Python版本、系统库版本
3. **依赖完整性**：requirements.txt是否全部安装成功
4. **权限设置**：文件和目录的读写执行权限

---

**版本**：V1.3-RELEASE  
**更新日期**：2026-05-19  
**适用平台**：Linux (x86_64)