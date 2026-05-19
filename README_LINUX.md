# Linux 使用指南 - 文档格式一键转换器V1

## 📋 目录
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [安装方式](#安装方式)
  - [方式一：源码运行（推荐开发测试）](#方式一源码运行推荐开发测试)
  - [方式二：打包为可执行文件（推荐生产环境）](#方式二打包为可执行文件推荐生产环境)
  - [方式三：从Windows复制exe（不推荐）](#方式三从windows复制exe不推荐)
- [详细安装步骤](#详细安装步骤)
- [常见问题解决](#常见问题解决)
- [高级配置](#高级配置)
- [桌面集成](#桌面集成)

---

## 系统要求

### 操作系统
- ✅ Ubuntu 18.04+ / Debian 10+
- ✅ CentOS 7+ / RHEL 7+
- ✅ Fedora 31+
- ✅ Arch Linux / Manjaro
- ✅ 其他主流Linux发行版

### 必需组件
| 组件 | 版本要求 | 用途 |
|------|---------|------|
| Python | 3.8+ | 运行环境 |
| tkinter | 已包含在Python标准库 | GUI界面 |
| 图形桌面环境 | GNOME/KDE/XFCE等 | 显示GUI窗口 |

### 可选组件
| 组件 | 用途 | 推荐安装 |
|------|------|---------|
| 中文字体 | 正确显示中文界面和文档 | **强烈推荐** |
| 文件管理器 | 双击打开文件/文件夹 | 推荐 |

---

## 快速开始

### 🚀 最快上手（Ubuntu/Debian）

```bash
# 1. 安装系统依赖
sudo apt update
sudo apt install -y python3 python3-pip python3-tk fonts-wqy-zenhei

# 2. 克隆或下载项目代码
cd ~
git clone <your-repo-url>
cd formatter-v1

# 3. 安装Python依赖
pip3 install --user -r requirements.txt

# 4. 启动程序
python3 main.py
```

### 🚀 最快上手（CentOS/RHEL/Fedora）

```bash
# CentOS/RHEL 7+
sudo yum install -y python3 python3-pip tkinter wqy-zenhei-fonts

# Fedora
sudo dnf install -y python3 python3-pip python3-tkinter wqy-zenhei-fonts

# 后续步骤同上...
```

---

## 安装方式

### 方式一：源码运行（推荐开发测试）

**优点**：无需打包，修改代码即时生效  
**缺点**：需要Python环境和依赖库  

#### 步骤：

```bash
# 1. 进入项目目录
cd /path/to/formatter-v1

# 2. 创建虚拟环境（推荐，避免污染系统Python）
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# 或: venv\Scripts\activate  # Windows

# 3. 安装依赖
pip install -r requirements.txt

# 4. 运行程序
python3 main.py
```

**退出虚拟环境**：
```bash
deactivate
```

---

### 方式二：打包为可执行文件（推荐生产环境）✨

**优点**：零依赖、单文件、可直接分发  
**缺点**：需要先打包一次  

#### 方法A：使用自动打包脚本（推荐）

```bash
# 1. 添加执行权限
chmod +x build_linux.sh

# 2. 执行打包脚本
./build_linux.sh

# 3. 打包完成后，运行可执行文件
cd dist
./文档格式一键转换器V1
```

#### 方法B：手动打包

```bash
# 1. 安装PyInstaller
pip3 install --user pyinstaller

# 2. 进入项目目录
cd /path/to/formatter-v1

# 3. 执行打包命令
pyinstaller --onefile --windowed \
    --name "文档格式一键转换器V1" \
    --noconfirm \
    main.py

# 4. 运行生成的可执行文件
chmod +x dist/文档格式一键转换器V1
./dist/文档格式一键转换器V1
```

**打包参数说明**：
- `--onefile`：打包成单个可执行文件
- `--windowed`：不显示控制台窗口（GUI模式）
- `--name`：指定输出文件名
- `--noconfirm`：覆盖输出目录不询问

---

### 方式三：从Windows复制exe（不推荐）

⚠️ **不推荐！Windows exe无法在Linux上运行**

如需跨平台使用，建议：
- 在Linux上重新打包Linux版本
- 或使用Docker容器化部署

---

## 详细安装步骤

### Ubuntu/Debian 完整安装流程

```bash
# ===== 第一步：更新系统 =====
sudo apt update && sudo apt upgrade -y

# ===== 第二步：安装基础依赖 =====
sudo apt install -y \
    python3 \
    python3-pip \
    python3-tk \
    python3-dev \
    git \
    wget \
    curl \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    xdg-utils

# ===== 第三步：验证安装 =====
python3 --version          # 应显示 Python 3.x.x
python3 -c "import tkinter; print('tkinter OK')"  # 应显示 tkinter OK

# ===== 第四步：获取项目代码 =====
# 方式A：Git克隆（如果有仓库）
git clone https://github.com/yourusername/formatter-v1.git
cd formatter-v1

# 方式B：下载压缩包
wget https://example.com/formatter-v1.zip
unzip formatter-v1.zip
cd formatter-v1

# ===== 第五步：安装Python依赖 =====
# 推荐使用用户级安装（无需sudo）
pip3 install --user -r requirements.txt

# 如果遇到权限问题，使用虚拟环境
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# ===== 第六步：启动程序 =====
python3 main.py

# 或者打包后再运行
./build_linux.sh
./dist/文档格式一键转换器V1
```

### CentOS/RHEL 7+ 完整安装流程

```bash
# ===== 第一步：安装EPEL仓库（如果未安装）=====
sudo yum install -y epel-release

# ===== 第二步：安装基础依赖 =====
sudo yum install -y \
    python3 \
    python3-pip \
    python3-tkinter \
    git \
    wget \
    wqy-zenhei-fonts

# ===== 第三步：后续步骤与Ubuntu相同 =====
# ... （参考上方第四至第六步）
```

### Arch Linux 完整安装流程

```bash
# ===== 第一步：安装依赖 =====
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm \
    python \
    python-pip \
    tk \
    git \
    wget \
    wqy-zenhei

# ===== 第二步：后续步骤相同 =====
# ...
```

---

## 常见问题解决

### ❓ 问题1：ImportError: No module named '_tkinter'

**原因**：tkinter未安装或编译时未启用tk支持

**解决方案**：

```bash
# Ubuntu/Debian
sudo apt install python3-tk

# CentOS/RHEL
sudo yum install python3-tkinter

# Fedora
sudo dnf install python3-tkinter

# Arch Linux
sudo pacman -S tk

# 如果仍然不行，可能需要重装Python（带tk支持）
# Ubuntu/Debian:
sudo apt install --reinstall python3-dev python3-tk
```

---

### ❓ 问题2：中文显示为方框或乱码

**原因**：系统中缺少中文字体

**解决方案**：

```bash
# 安装中文字体（选择一个或多个）
# Ubuntu/Debian:
sudo apt install -y fonts-wqy-zenhei      # 文泉驿正黑
sudo apt install -y fonts-wqy-microhei     # 文泉驿微米黑
sudo apt install -y fonts-noto-cjk         # Google Noto CJK字体
sudo apt install -y fonts-arphic-uming     # 文鼎PL UMing
sudo apt install -y fonts-arphic-ukai      # 文鼎PL UKai

# CentOS/RHEL:
sudo yum install -y wqy-zenhei-fonts
sudo yum install -y cjkuni-ukai-fonts

# Fedora:
sudo dnf install -y wqy-zenhei-fonts

# Arch Linux:
sudo pacman -S wqy-zenhei

# 刷新字体缓存
fc-cache -fv

# 验证字体是否可用
fc-list :lang=zh
```

**临时解决方案**（修改配置文件中的字体名）：
```yaml
# 编辑 format_config.yaml
font_settings:
  default_font: 'WenQuanYi Zen Hei'   # 改为已安装的中文字体

heading_styles:
  heading1:
    font_name: 'WenQuanYi Zen Hei'     # 同上
```

---

### ❓ 问题3：显示错误 "display cannot be opened"

**原因**：未连接图形显示器或在SSH远程连接中运行

**解决方案**：

**情况A：本地桌面环境**
```bash
# 确保已登录图形桌面（GNOME/KDE/XFCE等）
# 不要通过纯终端（TTY1-TTY6）运行
# 需要在图形终端中运行
```

**情况B：SSH远程连接（X11转发）**
```bash
# SSH连接时添加 -X 参数
ssh -X username@remote-server

# 然后再运行程序
python3 main.py
```

**情况C：无头服务器（无显示器）**
```bash
# 无法使用GUI版本
# 考虑：
# 1. 使用VNC/远程桌面
# 2. 开发命令行版本（CLI）
# 3. 使用Docker + VNC
```

---

### ❓ 问题4：Permission denied (权限不足)

**原因**：文件没有执行权限

**解决方案**：

```bash
# 添加执行权限
chmod +x dist/文档格式一键转换器V1
chmod +x build_linux.sh

# 如果是脚本文件
chmod +x *.sh

# 如果是当前用户没有执行权限
# 检查文件所有者
ls -l dist/文档格式一键转换器V1

# 修改所有者（如果需要）
sudo chown $USER:$USER dist/文档格式一键转换器V1
```

---

### ❓ 问题5：ModuleNotFoundError: No module named 'xxx'

**原因**：Python依赖包未正确安装

**解决方案**：

```bash
# 重新安装所有依赖
pip3 install --user -r requirements.txt --force-reinstall --no-cache-dir

# 如果使用虚拟环境
source venv/bin/activate
pip install -r requirements.txt --force-reinstall

# 检查Python路径
which python3
python3 -c "import sys; print(sys.path)"

# 确保pip和python对应同一版本
python3 -m pip install -r requirements.txt
```

---

### ❓ 问题6：打包后的exe文件太大

**正常现象**：PyInstaller会将所有依赖打包进去

**优化方案**：

```bash
# 1. 排除不需要的模块（编辑 .spec文件或命令行参数）
pyinstaller --onefile --windowed \
    --exclude-module matplotlib \
    --exclude-module numpy \
    --exclude-module pandas \
    --name "文档格式一键转换器V1" \
    main.py

# 2. 使用UPX压缩（需要单独安装upx）
sudo apt install upx-ucl  # Ubuntu
pyinstaller --onefile --windowed --upx-dir=/usr/bin main.py

# 3. 通常大小在15-25MB属于正常范围
```

---

## 高级配置

### 1. 配置文件位置

程序会在以下位置查找 `format_config.yaml`：

1. **优先级1**：可执行文件所在目录
2. **优先级2**：用户主目录 `~/.config/formatter-v1/`
3. **优先级3**：程序内部默认配置

**自定义配置文件位置**：
```bash
# 创建配置目录
mkdir -p ~/.config/formatter-v1/

# 复制默认配置
cp format_config.yaml ~/.config/formatter-v1/

# 编辑配置
nano ~/.config/formatter-v1/format_config.yaml
```

### 2. 中文字体配置示例

```yaml
# 常用Linux中文字体名称
font_settings:
  # 选项1：文泉驿正黑（最常用）
  default_font: 'WenQuanYi Zen Hei'
  
  # 选项2：Noto Sans CJK SC（Google字体）
  # default_font: 'Noto Sans CJK SC'
  
  # 选项3：思源黑体
  # default_font: 'Source Han Sans SC'
  
  # 选项4：文鼎PL
  # default_font: 'AR PL UMing CN'

heading_styles:
  heading1:
    font_name: 'WenQuanYi Zen Hei'
    font_size: 18
    bold: true
    alignment: center
```

**查看系统已安装的中文字体**：
```bash
fc-list :lang=zh family | sort | uniq
```

### 3. 性能优化

对于大文件处理（>10MB的Markdown），可以调整：

```yaml
# 编辑 config_manager.py 或配置文件
# （目前不支持，但可以在代码中添加）
```

---

## 桌面集成

### 创建桌面快捷方式

#### 方法A：自动创建（推荐）

```bash
# 创建桌面入口文件
cat > ~/.local/share/applications/文档格式一键转换器.desktop << EOF
[Desktop Entry]
Name=文档格式一键转换器V1
Name[en]=Document Formatter V1
Comment=Markdown to Word Converter
Exec=/path/to/dist/文档格式一键转换器V1
Icon=application-msword
Terminal=false
Type=Application
Categories=Office;Utility;
StartupNotify=true
EOF

# 设置权限
chmod +x ~/.local/share/applications/文档格式一键转换器.desktop

# 刷新桌面图标
update-desktop-database ~/.local/share/applications/
```

现在可以在应用菜单中搜索"文档格式一键转换器"并启动。

#### 方法B：桌面快捷方式

```bash
# 创建桌面快捷方式
cat > ~/Desktop/文档格式一键转换器.desktop << EOF
[Desktop Entry]
Name=文档格式一键转换器V1
Exec=/path/to/dist/文档格式一键转换器V1
Icon=text-x-generic
Type=Application
EOF

chmod +x ~/Desktop/文档格式一键转换器.desktop
```

**注意**：某些发行版需要在文件管理器中右键 → 允许启动

#### 自定义图标

```bash
# 下载图标（可选）
wget -O ~/.local/share/icons/doc-formatter.png \
    https://example.com/icon.png

# 修改desktop文件的Icon行
Icon=doc-formatter
```

---

### 添加到右键菜单（Nautilus/Files）

```bash
# 创建Nautilus脚本
mkdir -p ~/.local/share/nautilus/scripts
cat > ~/.local/share/nautilus/scripts/"转换为格式化Word" << 'EOF'
#!/bin/bash
for file in "$@"; do
    /path/to/dist/文档格式一键转换器V1 "$file"
done
EOF

chmod +x ~/.local/share/nautilus/scripts/*
```

现在右键文件时会出现"转换为格式化Word"选项。

---

## Docker 部署（进阶）

适用于无头服务器或需要隔离环境的场景：

```dockerfile
# Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-tk \
    fonts-wqy-zenhei \
    xvfb  # 虚拟显示器

WORKDIR /app
COPY . .
RUN pip3 install -r requirements.txt

CMD ["xvfb-run", "python3", "main.py"]
```

构建和运行：
```bash
docker build -t doc-formatter .
docker run -it --rm \
    -v /path/to/documents:/documents \
    -e DISPLAY=:0 \
    doc-formatter
```

---

## 性能对比

| 运行方式 | 启动速度 | 内存占用 | 分发便利性 | 推荐场景 |
|---------|---------|---------|-----------|---------|
| 源码运行 | 快 | 低 | 差 | 开发调试 |
| 单文件exe | 较慢（2-5秒） | 中 | ⭐⭐⭐⭐⭐ | 生产环境 |
| 目录分发 | 中 | 中 | ⭐⭐⭐ | 内部使用 |
| Docker | 慢 | 高 | ⭐⭐⭐⭐ | 云端/CI |

---

## 命令行参数（未来扩展）

当前版本仅支持GUI操作。计划在未来版本添加CLI接口：

```bash
# 计划支持的用法
./文档格式一键转换器V1 input.md -o output.docx
./文档格式一键转换器V1 input.docx --format
./文档格式一键转换器V1 --config custom.yaml batch/*.md
```

---

## 技术支持

### 日志查看

```bash
# 查看程序输出（如果从终端启动）
python3 main.py 2>&1 | tee log.txt

# 查看系统日志（如果崩溃）
journalctl -f | grep -i python
dmesg | tail
```

### 常用调试命令

```bash
# 检查Python环境
python3 -c "
import sys
print('Python:', sys.version)
import tkinter
print('tkinter: OK')
import docx
print('python-docx:', docx.__version__)
import yaml
print('PyYAML:', yaml.__version__)
"

# 检查文件权限
ls -lh dist/文档格式一键转换器V1

# 检查字体
fc-list | grep -i "wenquanyi\|noto.*cjk"
```

---

## 更新升级

```bash
# 如果使用Git
cd ~/formatter-v1
git pull origin main
pip3 install --user -r requirements.txt --upgrade
./build_linux.sh  # 重新打包

# 如果手动下载
# 下载新版本 → 解压 → 重复安装步骤
```

---

## 卸载清理

### 源码版本卸载

```bash
# 删除虚拟环境（如果使用了）
rm -rf ~/formatter-v1/venv

# 删除项目目录
rm -rf ~/formatter-v1

# 清理pip缓存的包（可选）
pip3 cache purge
```

### 打包版本卸载

```bash
# 删除可执行文件
rm -f ~/formatter-v1/dist/文档格式一键转换器V1

# 删除桌面快捷方式
rm -f ~/.local/share/applications/文档格式一键转换器.desktop
rm -f ~/Desktop/文档格式一键转换器.desktop

# 删除配置文件（可选，会丢失自定义设置）
rm -f ~/formatter-v1/format_config.yaml
rm -rf ~/.config/formatter-v1/
```

---

## 总结

✅ **推荐的生产环境使用流程**：

1. **安装系统依赖**：`sudo apt install python3 python3-tk fonts-wqy-zenhei`
2. **获取代码**：`git clone <repo>` 或下载zip
3. **打包**：`chmod +x build_linux.sh && ./build_linux.sh`
4. **运行**：`./dist/文档格式一键转换器V1`
5. **(可选) 创建快捷方式**：参考[桌面集成](#桌面集成)章节

🎉 **恭喜！您现在可以在Linux上愉快地使用文档格式转换工具了！**

---

**最后更新**: 2025年  
**适用版本**: V1.0  
**测试环境**: Ubuntu 22.04 LTS, CentOS 8, Fedora 36, Arch Linux
