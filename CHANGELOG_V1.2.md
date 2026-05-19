# 文档格式一键转换器 V1.2 更新说明

## 📋 版本信息

- **版本号**: V1.2
- **发布日期**: 2026-05-19
- **前一版本**: V1.1

---

## ✨ 新增功能

### 1. 🎯 修复 Word 文档页码显示问题

**问题描述:**
- 格式化后的 Word 文档中，每页页脚显示的都是固定的数字 "1"
- 无法正确显示动态页码（1, 2, 3, ...）

**根本原因:**
- 原实现使用静态文本设置页码：`run.text = str(start_from + section_idx)`
- 这导致所有页面都显示相同的固定数字

**修复方案:**
- 改用 Word 域代码（Field Code）实现动态页码
- 插入 `PAGE` 域指令，让 Word 自动计算并显示当前页码
- 新增 `_add_page_number_field()` 方法处理域代码插入

**技术实现:**
```python
# 使用 Word 域代码结构
fld_char_begin = OxmlElement('w:fldChar')  # 域开始
instr_text = OxmlElement('w:instrText')     # PAGE 指令
fld_char_separate = OxmlElement('w:fldChar') # 分隔符
fld_char_end = OxmlElement('w:fldChar')      # 域结束
```

**影响:**
- ✅ 现在每页会正确显示对应的页码（第1页显示1，第2页显示2...）
- ✅ 在 Microsoft Word 中打开时自动更新页码
- ✅ 保持原有的字体、字号、加粗等格式设置不变

**修改文件:**
- `formatter.py` (第 271-326 行)
  - 重构 `_insert_page_numbers()` 方法
  - 新增 `_add_page_number_field()` 方法

---

## 🔄 其他改进

### 2. 版本号更新至 V1.2

更新了所有相关文件中的版本号：

**修改的文件:**
- ✅ `build_exe.py` - Windows 打包脚本（V1.1 → V1.2）
- ✅ `build.spec` - PyInstaller 配置文件（新建 V1.2 版本）
- ✅ `build_windows.bat` - Windows 批处理打包脚本

**生成的可执行文件名:**
- Windows: `文档格式一键转换器 V1.2.exe`
- Linux: `文档格式一键转换器 V1.2`

---

## 📊 技术细节

### 代码变更统计

| 文件 | 变更类型 | 行数变化 |
|------|---------|---------|
| `formatter.py` | 功能增强 + Bug 修复 | +30 行 |
| `build_exe.py` | 版本号更新 | 2 行 |
| `build.spec` | 新建 V1.2 配置 | 38 行 |
| **总计** | - | **+70 行** |

### 核心改进对比

| 项目 | V1.1 实现 | V1.2 实现 |
|------|----------|----------|
| 页码方式 | 静态文本 | 动态域代码 |
| 显示效果 | 所有页显示"1" | 每页显示正确页码 |
| Word 兼容性 | 需手动更新 | 自动计算更新 |
| 代码可维护性 | 简单但功能有限 | 符合 Word 标准 |

---

## 🚀 升级指南

### Windows 用户

**方式 1：使用 Python 脚本打包（推荐）**
```bash
# 运行打包脚本
python build_exe.py

# 生成的新文件：
# dist\文档格式一键转换器V1.2.exe
```

**方式 2：使用批处理脚本**
```bash
# 运行批处理脚本
build_windows.bat

# 或使用 PyInstaller 直接打包
pyinstaller build.spec --clean --noconfirm

# 生成的新文件：
# dist\文档格式一键转换器 V1.2.exe
```

### Linux 用户

**方式 1：重新打包**
```bash
chmod +x build_linux.sh
./build_linux.sh

# 生成的新文件：
# dist/文档格式一键转换器 V1.2
```

**方式 2：源码运行**
```bash
python3 main.py
```

### Docker 用户

```bash
# 重新构建镜像
docker build -t doc-formatter:v1.2 .

# 运行新版本
docker run -it --rm -e DISPLAY=$DISPLAY doc-formatter:v1.2
```

---

## 📝 向后兼容性

### ✅ 完全兼容

- **配置文件**: V1.1 的 `format_config.yaml` 可继续在 V1.2 中使用
- **输出格式**: 页码功能增强，其他格式保持一致
- **API 接口**: 所有模块接口保持不变
- **依赖要求**: 所需的 Python 包版本无变化

### ⚠️ 注意事项

- **可执行文件名**: 打包后的文件名从 V1.1 改为 V1.2
- **窗口标题**: GUI 窗口标题将显示为 V1.2
- **页码行为**: 已有文档重新格式化后，页码会正常显示

---

## 🧪 测试验证

### 测试环境

| 操作系统 | Python 版本 | python-docx 版本 | 测试状态 |
|---------|------------|-----------------|---------|
| Windows 10/11 | 3.8-3.12 | 1.1.2+ | ✅ 通过 |

### 测试用例

#### 页码功能测试
```bash
# 运行测试脚本
python test_formatting.py

# 预期输出：
# Section 1 Footer:
#   Field char type: begin
#   Field instruction: ' PAGE '
#   Field char type: separate
#   Field char type: end
#
#   SUCCESS: Page number field code found!
#   Total field elements: 4
```

#### 手动验证步骤
1. 使用测试文档进行格式化
2. 在 Microsoft Word 中打开生成的文档
3. 检查每一页的页脚是否显示正确的页码
4. 验证字体、字号、对齐方式等格式是否正确

---

## 🐛 已知问题

目前无已知问题。

如遇到问题，请收集以下信息：
1. 操作系统及版本
2. Python 版本 (`python --version`)
3. python-docx 版本 (`pip show python-docx`)
4. 完整的错误信息
5. 复现步骤（包括使用的文档）

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

## 🎯 下一版本计划 (V1.3)

计划中的功能：
- [ ] 批量处理多个文件
- [ ] 支持更多文档格式（PDF、RTF 等）
- [ ] 命令行模式（无 GUI）
- [ ] 自定义输出路径
- [ ] 格式预览功能
- [ ] 自动更新检测
- [ ] 页眉支持
- [ ] 更多页码格式选项（如："第 X 页 / 共 Y 页"）

---

## 📜 版本历史

| 版本 | 日期 | 主要变更 |
|------|------|---------|
| V1.0 | 2026-05-15 | 初始版本发布 |
| V1.1 | 2026-05-18 | 修复 bulletListPr 错误，增强稳定性 |
| V1.2 | 2026-05-19 | **修复页码显示问题，使用域代码实现动态页码** |

---

**感谢使用文档格式一键转换器！** 🎉

### 本次更新亮点

🔧 **核心修复**: 解决了用户反馈的页码显示问题  
⚡ **技术升级**: 采用标准的 Word 域代码实现  
✨ **用户体验**: 现在可以正确查看多页文档的页码  

如有任何问题或建议，欢迎反馈！