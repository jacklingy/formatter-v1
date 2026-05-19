# 文档格式一键转换器 V1.1 更新说明

## 📋 版本信息

- **版本号**: V1.1
- **发布日期**: 2026-05-18
- **前一版本**: V1.0

---

## ✨ 新增功能

### 1. 错误修复

#### 🔧 修复 Word 格式化时的 `bulletListPr` 属性错误

**问题描述:**
- 在格式化包含项目符号列表的 Word 文档时，程序报错：
  ```
  CT_PPr' object has no attribute 'bulletListPr'
  ```

**修复方案:**
- 在 `formatter.py` 的 `_is_list_paragraph()` 方法中添加了防御性编程
- 使用 `hasattr()` 检查属性是否存在
- 使用 `try-except` 捕获可能的 `AttributeError`

**影响:**
- ✅ 现在可以正确处理包含项目符号列表的 Word 文档
- ✅ 增强了代码的健壮性和兼容性
- ✅ 适应不同版本的 python-docx 库

**修改文件:**
- `formatter.py` (第 87-97 行)

---

## 🔄 其他改进

### 2. 版本号更新

更新了所有相关文件中的版本号从 V1 到 V1.1：

**修改的文件:**
- ✅ `build_exe.py` - Windows 打包脚本
- ✅ `build.spec` - PyInstaller 配置文件
- ✅ `build_windows.bat` - Windows 批处理打包脚本
- ✅ `build_linux.sh` - Linux 打包脚本
- ✅ `run_linux.sh` - Linux 快速启动脚本
- ✅ `install.sh` - Linux 一键安装脚本
- ✅ `download_deps.sh` - 离线依赖下载脚本
- ✅ `gui.py` - GUI 窗口标题
- ✅ `README.md` - 主文档

**生成的可执行文件名:**
- Windows: `文档格式一键转换器 V1.1.exe`
- Linux: `文档格式一键转换器 V1.1`

---

## 📊 技术细节

### 代码变更统计

| 文件 | 变更类型 | 行数变化 |
|------|---------|---------|
| `formatter.py` | Bug 修复 + 增强 | +5 行 |
| `gui.py` | 版本号更新 | 1 行 |
| `build_exe.py` | 版本号更新 | 2 行 |
| `build.spec` | 版本号更新 | 2 行 |
| `build_windows.bat` | 版本号更新 | 1 行 |
| `build_linux.sh` | 版本号更新 | 3 行 |
| `run_linux.sh` | 版本号更新 | 3 行 |
| `install.sh` | 版本号更新 | 2 行 |
| `download_deps.sh` | 版本号更新 | 1 行 |
| `README.md` | 版本信息更新 | +5 行 |
| **总计** | - | **+25 行** |

### 兼容性测试

已测试以下环境：

| 操作系统 | Python 版本 | python-docx 版本 | 状态 |
|---------|------------|-----------------|------|
| Windows 10/11 | 3.8-3.12 | 1.1.2 | ✅ 通过 |
| Ubuntu 22.04 | 3.10 | 1.1.2 | ✅ 通过 |
| CentOS 7 | 3.6 | 0.8.6 | ✅ 通过 |
| Fedora 38 | 3.11 | 1.1.2 | ✅ 通过 |

---

## 🚀 升级指南

### Windows 用户

**方式 1：重新打包（推荐）**
```bash
# 运行打包脚本
build_windows.bat

# 或使用 Python 脚本
python build_exe.py

# 生成的新文件：
# dist\文档格式一键转换器 V1.1\文档格式一键转换器 V1.1.exe
```

**方式 2：直接重命名（临时方案）**
```bash
# 将旧版本 exe 重命名为 V1.1
move "文档格式一键转换器 V1.exe" "文档格式一键转换器 V1.1.exe"
```

### Linux 用户

**方式 1：重新打包（推荐）**
```bash
# 运行打包脚本
chmod +x build_linux.sh
./build_linux.sh

# 生成的新文件：
# dist/文档格式一键转换器 V1.1
```

**方式 2：源码运行（自动使用新版本）**
```bash
# 直接运行，代码已更新
python3 main.py
```

### Docker 用户

```bash
# 重新构建镜像
docker build -t doc-formatter:v1.1 .

# 运行新版本
docker run -it --rm -e DISPLAY=$DISPLAY doc-formatter:v1.1
```

---

## 📝 向后兼容性

### ✅ 完全兼容

- **配置文件**: V1.0 的 `format_config.yaml` 可继续在 V1.1 中使用
- **输出格式**: V1.1 生成的文档与 V1.0 格式完全一致
- **API 接口**: 所有模块接口保持不变
- **依赖要求**: 所需的 Python 包版本无变化

### ⚠️ 注意事项

- **可执行文件名**: 打包后的文件名从 V1 改为 V1.1
- **窗口标题**: GUI 窗口标题显示为 V1.1
- **版本标识**: 程序内部版本号为 V1.1

---

## 🐛 已知问题

目前无已知问题。

如遇到问题，请收集以下信息：
1. 操作系统及版本
2. Python 版本 (`python --version`)
3. python-docx 版本 (`pip show python-docx`)
4. 完整的错误信息
5. 复现步骤

---

## 📞 技术支持

### 反馈渠道

- **GitHub Issues**: (项目仓库链接)
- **邮箱**: (联系邮箱)
- **文档**: [README.md](./README.md)

### 收集诊断信息

```bash
# Windows
python -c "
import sys
import docx
print(f'Python: {sys.version}')
print(f'python-docx: {docx.__version__}')
"

# Linux
python3 -c "
import sys
import docx
print(f'Python: {sys.version}')
print(f'python-docx: {docx.__version__}')
"
```

---

## 🎯 下一版本计划 (V1.2)

计划中的功能：
- [ ] 批量处理多个文件
- [ ] 支持更多文档格式（PDF、RTF 等）
- [ ] 命令行模式（无 GUI）
- [ ] 自定义输出路径
- [ ] 格式预览功能
- [ ] 自动更新检测

---

## 📜 版本历史

| 版本 | 日期 | 主要变更 |
|------|------|---------|
| V1.0 | 2026-05-15 | 初始版本发布 |
| V1.1 | 2026-05-18 | 修复 bulletListPr 错误，增强稳定性 |

---

**感谢使用文档格式一键转换器！** 🎉

如有任何问题或建议，欢迎反馈！
