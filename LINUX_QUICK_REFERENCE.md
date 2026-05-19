# Linux 快速参考卡 - 文档格式一键转换器V1

## 🚀 30秒快速启动

### Ubuntu/Debian
```bash
# 复制粘贴这一整段即可！
sudo apt update && sudo apt install -y python3 python3-pip python3-tk fonts-wqy-zenhei && \
pip3 install --user -r requirements.txt && \
python3 main.py
```

### CentOS/RHEL/Fedora
```bash
sudo yum install -y python3 python3-pip python3-tkinter wqy-zenhei-fonts && \
pip3 install --user -r requirements.txt && \
python3 main.py
```

---

## 📋 常用命令速查

### 安装相关
| 操作 | 命令 |
|------|------|
| **安装系统依赖** | `sudo apt install python3 python3-tk fonts-wqy-zenhei` |
| **安装Python依赖** | `pip3 install --user -r requirements.txt` |
| **一键全部安装** | `chmod +x install.sh && ./install.sh` |
| **打包可执行文件** | `chmod +x build_linux.sh && ./build_linux.sh` |
| **快速启动** | `chmod +x run_linux.sh && ./run_linux.sh` |

### 运行程序
| 方式 | 命令 |
|------|------|
| **源码模式** | `python3 main.py` |
| **打包版本** | `./dist/文档格式一键转换器V1` |
| **后台运行** | `nohup ./dist/文档格式一键转换器V1 &` |

### 故障排除
| 问题 | 命令 |
|------|------|
| **检查Python** | `python3 --version` |
| **检查tkinter** | `python3 -c "import tkinter"` |
| **检查字体** | `fc-list :lang=zh \| head -10` |
| **查看日志** | `python3 main.py 2>&1 \| tee log.txt` |
| **清理缓存** | `pip3 cache purge && rm -rf __pycache__ build dist` |

---

## 🔧 系统依赖安装（各发行版）

### Ubuntu / Debian / Mint
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-tk \
    fonts-wqy-zenhei fonts-wqy-microhei xdg-utils
```

### CentOS / RHEL 7+
```bash
sudo yum install epel-release -y
sudo yum install -y python3 python3-pip python3-tkinter \
    wqy-zenhei-fonts
```

### Fedora
```bash
sudo dnf install -y python3 python3-pip python3-tkinter \
    wqy-zenhei-fonts
```

### Arch Linux / Manjaro
```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm python python-pip tk wqy-zenhei
```

### openSUSE
```bash
sudo zypper refresh
sudo zypper install -y python3 python3-pip python3-tk \
    wqy-zenhei-fonts
```

---

## 📦 打包命令

### 基础打包
```bash
pyinstaller --onefile --windowed --name "文档格式一键转换器V1" main.py
```

### 高级打包（优化体积）
```bash
pyinstaller --onefile --windowed \
    --name "文档格式一键转换器V1" \
    --exclude-module matplotlib \
    --exclude-module numpy \
    --exclude-module pandas \
    --upx-dir=/usr/bin \
    main.py
```

### 使用脚本打包（推荐）
```bash
chmod +x build_linux.sh
./build_linux.sh
```

---

## 🖥️ 桌面集成

### 创建应用菜单入口
```bash
cat > ~/.local/share/applications/文档格式一键转换器.desktop << 'EOF'
[Desktop Entry]
Name=文档格式一键转换器V1
Exec=/path/to/dist/文档格式一键转换器V1
Icon=application-msword
Type=Application
Categories=Office;
EOF
```

### 创建桌面快捷方式
```bash
cat > ~/Desktop/文档格式一键转换器.desktop << 'EOF'
[Desktop Entry]
Name=文档格式一键转换器V1
Exec=/path/to/文档格式一键转换器V1
Icon=text-x-generic
Type=Application
EOF
chmod +x ~/Desktop/文档格式一键转换器.desktop
```

### 刷新图标缓存
```bash
update-desktop-database ~/.local/share/applications/
fc-cache -fv
```

---

## ⚙️ 配置文件位置

| 类型 | 路径 |
|------|------|
| **默认配置** | `./format_config.yaml`（程序目录） |
| **用户配置** | `~/.config/formatter-v1/format_config.yaml` |
| **全局配置** | `/etc/formatter-v1/config.yaml` |

### 编辑配置
```bash
# 使用nano编辑器
nano format_config.yaml

# 或使用vscode
code format_config.yaml

# 或使用gedit
gedit format_config.yaml &
```

---

## 🔍 验证安装

### 完整环境检查脚本
```bash
echo "=== 环境检查 ==="
echo "Python: $(python3 --version)"
echo "Pip: $(pip3 --version)"
echo ""
echo "=== 模块检查 ==="
python3 -c "import tkinter; print('✓ tkinter')" || echo "✗ tkinter"
python3 -c "import docx; print('✓ python-docx:', docx.__version__)" || echo "✗ docx"
python3 -c "import yaml; print('✓ PyYAML:', yaml.__version__)" || echo "✗ yaml"
echo ""
echo "=== 字体检查 ==="
fc-list :lang=zh family | head -5
echo ""
echo "=== 可执行文件 ==="
ls -lh dist/文档格式一键转换器V1 2>/dev/null || echo "未找到打包文件"
```

---

## 💡 使用技巧

### 1. 批量转换多个Markdown文件
```bash
for file in *.md; do
    echo "处理: $file"
    # （需要GUI操作或等待CLI版本）
done
```

### 2. 监控文件夹自动转换（需要inotify-tools）
```bash
sudo apt install inotify-tools
while inotifywait -e close_write *.md; do
    echo "检测到文件变更，请手动转换"
done
```

### 3. 后台持续运行
```bash
# 启动后即使关闭终端也继续运行
nohup ./dist/文档格式一键转换器V1 > /dev/null 2>&1 &

# 查看进程
ps aux | grep 文档格式一键转换器

# 停止进程
pkill -f 文档格式一键转换器
```

### 4. SSH远程使用（X11转发）
```bash
# 连接时启用X11转发
ssh -X user@remote-server

# 运行程序
cd ~/formatter-v1
./run_linux.sh
```

---

## 🆘 常见问题速查

### Q: tkinter报错？
```bash
# 安装tkinter
sudo apt install python3-tk        # Debian/Ubuntu
sudo yum install python3-tkinter   # CentOS/RHEL
```

### Q: 中文显示方框？
```bash
# 安装中文字体
sudo apt install fonts-wqy-zenhei fonts-noto-cjk
fc-cache -fv
```

### Q: 权限不足？
```bash
# 添加执行权限
chmod +x *.sh dist/文档格式一键转换器V1

# 或修改所有者
sudo chown $USER:$USER dist/文档格式一键转换器V1
```

### Q: 显示错误 "cannot open display"?
```bash
# 确保在图形桌面中运行，不要在纯TTY中运行
# 或使用SSH X11转发: ssh -X host
```

### Q: 如何完全卸载？
```bash
rm -rf ~/formatter-v1
rm -f ~/.local/share/applications/文档格式一键转换器.desktop
rm -rf ~/.config/formatter-v1/
pip3 cache purge
```

---

## 📊 性能对比

| 运行方式 | 内存占用 | 启动速度 | 推荐场景 |
|---------|---------|---------|---------|
| `python3 main.py` | ~50MB | <1秒 | 开发调试 |
| 打包exe | ~80MB | 2-5秒 | 日常使用 ⭐ |
| Docker | ~200MB | 5-10秒 | 服务器部署 |

---

## 🔗 相关链接

- 📖 **完整文档**: [README.md](./README.md)
- 🐧 **Linux指南**: [README_LINUX.md](./README_LINUX.md) ⭐
- 🐳 **Docker部署**: [Dockerfile](./Dockerfile)
- 📦 **项目仓库**: (GitHub链接)

---

## 📞 技术支持

### 收集诊断信息
```bash
echo "=== 系统信息 ===" > debug_info.txt
uname -a >> debug_info.txt
cat /etc/os-release >> debug_info.txt
echo "" >> debug_info.txt
echo "=== Python ===" >> debug_info.txt
python3 --version >> debug_info.txt
pip3 list >> debug_info.txt
echo "" >> debug_info.txt
echo "=== 测试导入 ===" >> debug_info.txt
python3 -c "
import sys
import tkinter
import docx
import yaml
print('All imports successful')
" >> debug_info.txt 2>&1

cat debug_info.txt
```

---

**最后更新**: 2025年  
**适用版本**: V1.0  
**快捷键**: `Ctrl+F` 搜索关键词

💾 **建议收藏此页面以备查阅**
