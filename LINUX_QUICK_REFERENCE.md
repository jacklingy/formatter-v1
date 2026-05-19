# Linux版本打包 - 快速参考卡

## 🎯 三种打包方式对比

| 方式 | 适用场景 | 难度 | 时间 | 推荐度 |
|------|---------|------|------|--------|
| **自动脚本** | Linux环境直接运行 | ⭐简单 | 2-5分钟 | ⭐⭐⭐⭐⭐ |
| **Docker打包** | Windows/Linux/Mac通用 | ⭐⭐中等 | 5-10分钟 | ⭐⭐⭐⭐ |
| **手动命令** | 需要自定义配置 | ⭐⭐⭐复杂 | 3-8分钟 | ⭐⭐⭐ |

---

## 🚀 方式一：Linux环境自动脚本（最快）

```bash
# 一键执行（在Linux系统中）
cd /path/to/formatter-v1
chmod +x build_linux.sh && ./build_linux.sh

# 完成！文件在 dist/ 目录下
```

**前置要求**：
```bash
# Ubuntu/Debian (一键安装所有依赖)
sudo apt update && sudo apt install -y python3 python3-pip python3-tk fonts-wqy-zenhei
```

---

## 🐳 方式二：Docker打包（跨平台）

### Windows用户（双击运行）
```
双击: build_linux_docker.bat
```

### Mac/Linux用户（命令行）
```bash
# 构建镜像
docker build -t doc-formatter-builder -f Dockerfile.build .

# 运行打包
docker run --rm \
    -v $(pwd):/app/source \
    -v $(pwd)/dist_linux:/output \
    doc-formatter-builder

# 结果在 dist_linux/ 目录
```

**前置要求**：安装Docker Desktop

---

## 🔧 方式三：手动打包（完全控制）

```bash
# 1. 安装依赖
pip install pyinstaller -r requirements.txt

# 2. 执行打包
pyinstaller \
    --onefile \
    --windowed \
    --name "文档格式一键转换器V1.3-RELEASE" \
    main.py

# 3. 测试运行
chmod +x dist/文档格式一键转换器V1.3-RELEASE
./dist/文档格式一键转换器V1.3-RELEASE
```

---

## ✅ 打包完成检查清单

- [ ] 文件存在：`dist/文档格式一键转换器V1.3-RELEASE`
- [ ] 文件大小：30-80MB（正常范围）
- [ ] 有执行权限：`chmod +x` 已执行
- [ ] 能正常启动：GUI界面显示正常
- [ ] 功能测试：Word转换和Markdown转换正常

---

## 📦 分发准备

### 创建发布压缩包
```bash
# Linux/macOS
tar -czvf doc-formatter-V1.3-RELEASE-linux.tar.gz \
    -C dist \
    文档格式一键转换器V1.3-RELEASE \
    README_LINUX.md \
    CHANGELOG_V1.3-RELEASE.md

# Windows (使用PowerShell)
Compress-Archive -Path dist\文档格式一键转换器V1.3-RELEASE `
    -DestinationPath doc-formatter-V1.3-RELEASE.zip
```

### 发布包内容结构
```
doc-formatter-V1.3-RELEASE-linux/
├── 文档格式一键转换器V1.3-RELEASE   # 可执行文件
├── README_LINUX.md                   # Linux使用说明
├── CHANGELOG_V1.3-RELEASE.md         # 更新日志
└── LINUX_BUILD_GUIDE.md              # 详细构建指南（可选）
```

---

## 🔍 常见问题速查

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| `tkinter not found` | 缺少GUI库 | `sudo apt install python3-tk` |
| 中文乱码 | 缺少中文字体 | `sudo apt install fonts-wqy-zenhei` |
| Permission denied | 无执行权限 | `chmod +x 文件名` |
| 打包失败 | 依赖缺失 | 使用虚拟环境重新安装 |
| 程序无法启动 | 缺少系统库 | `ldd ./程序名` 检查 |

---

## 📞 获取帮助

- **详细指南**：查看 `LINUX_BUILD_GUIDE.md`
- **使用说明**：查看 `README_LINUX.md`
- **更新日志**：查看 `CHANGELOG_V1.3-RELEASE.md`
- **问题反馈**：提交GitHub Issue

---

**版本**: V1.3-RELEASE  
**最后更新**: 2026-05-19  
**推荐方式**: 自动脚本（Linux）或Docker（跨平台）
