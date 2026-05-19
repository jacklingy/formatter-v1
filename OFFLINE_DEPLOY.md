# 离线环境部署指南 - 文档格式一键转换器V1

## 📋 目录

- [场景说明](#场景说明)
- [离线包类型对比](#离线包类型对比)
- [完整操作流程](#完整操作流程)
  - [阶段一：在线环境准备](#阶段一在线环境准备)
  - [阶段二：传输到离线环境](#阶段二传输到离线环境)
  - [阶段三：离线环境安装](#阶段三离线环境安装)
- [各脚本详细说明](#各脚本详细说明)
- [常见问题解决](#常见问题解决)
- [高级用法](#高级用法)

---

## 场景说明

### 适用场景

✅ **完全隔离的内网环境**（无任何外网访问）  
✅ **安全要求高的服务器**（禁止安装未知软件源）  
✅ **批量部署多台机器**（避免重复下载）  
✅ **带宽受限或按流量计费的网络**  
✅ **审计合规要求**（所有软件需预先审核）

### 不适用场景

❌ 需要实时更新依赖的动态环境  
❌ 目标机器架构与生成环境不同（如x86 vs ARM）

---

## 离线包类型对比

| 类型 | 大小 | 包含内容 | 适用场景 | 推荐度 |
|------|------|---------|---------|--------|
| **完整版** | 100-200MB | 系统包 + Python包 + 字体 + 可执行文件 | 完全裸机、无任何预装环境 | ⭐⭐⭐⭐⭐ |
| **标准版** | 50-80MB | Python包 + 字体 + 可执行文件 | 已有Python3和tkinter基础环境 | ⭐⭐⭐⭐ |
| **轻量版** | 20-30MB | 仅Python包（wheel格式） | 有完整Python开发环境 | ⭐⭐⭐ |
| **自定义版** | 可变 | 按需选择组件 | 特殊需求场景 | ⭐⭐⭐ |

### 如何选择？

```bash
# 如果目标机器是全新安装的Linux系统 → 完整版
# 如果目标机器已有python3和tkinter → 标准版
# 如果目标机器有完整的开发工具链 → 轻量版
# 其他情况 → 自定义版
```

---

## 完整操作流程

### 阶段一：在线环境准备 🌐

#### 前置条件

在**有网络访问**的Linux机器上执行以下操作：

```bash
# 确保已安装基础工具
sudo apt update
sudo apt install python3 python3-pip python3-tk wget tar tree -y
```

#### 方式A：使用一键生成工具（推荐）⭐⭐⭐⭐⭐

```bash
# 1. 进入项目目录
cd /path/to/formatter-v1

# 2. 赋予执行权限
chmod +x create_offline_package.sh

# 3. 运行一键生成工具
./create_offline_package.sh

# 4. 选择模式（推荐选择"1"完整版）
#    输入: 1 并回车
#    当询问是否打包可执行文件时，输入: y

# 5. 等待完成，生成的文件：
#     doc-formatter-v1-offline-package-YYYYMMDD.tar.gz (完整版)
#     或其他对应版本的压缩包
```

**输出示例：**
```
╔═══════════════════════════════════════════════════╗
║       ✅ 离线包生成完成！                        ║
╚═══════════════════════════════════════════════════╝

📦 生成的文件:
  • doc-formatter-v1-offline-package-20260518.tar.gz (156MB)
```

#### 方式B：分步手动生成

**步骤1：下载依赖**

```bash
# 运行依赖下载脚本
chmod +x download_deps.sh
./download_deps.sh
```

此脚本会：
- ✅ 自动检测操作系统类型
- ✅ 下载系统级依赖包（.deb/.rpm）
- ✅ 下载Python依赖包（wheel + 源码）
- ✅ 下载中文字体文件
- ✅ 复制项目源代码
- ✅ （可选）打包可执行文件
- ✅ 生成完整的离线目录结构
- ✅ 创建最终的tar.gz压缩包

**步骤2：（可选）单独打包可执行文件**

如果步骤1中未打包，可以单独执行：

```bash
# 安装PyInstaller（仅用于打包）
pip3 install pyinstaller

# 打包
pyinstaller --onefile --windowed \
    --name "文档格式一键转换器V1" \
    --noconfirm \
    main.py

# 复制到离线包目录
cp dist/文档格式一键转换器V1 offline_package/
chmod +x offline_package/文档格式一键转换器V1
```

**步骤3：重新打包**

```bash
# 更新压缩包（如果修改了内容）
tar -czvf doc-formatter-v1-offline-updated.tar.gz offline_package/
```

---

### 阶段二：传输到离线环境 💾

#### 传输方式

**方式1：U盘/移动硬盘**
```bash
# 在线环境：复制到U盘
cp doc-formatter-v1-offline-package-*.tar.gz /media/usb/

# 离线环境：从U盘复制
cp /media/usb/doc-formatter-v1-offline-package-*.tar.gz ~/
```

**方式2：内网SMB/NFS共享**
```bash
# 在线环境：复制到共享目录
cp doc-formatter-v1-offline-package-*.tar.gz /mnt/network_share/

# 离线环境：从共享目录复制
cp /mnt/network_share/doc-formatter-v1-offline-package-*.tar.gz ~/
```

**方式3：SCP/SSH隧道（如果有有限网络连接）**
```bash
# 从在线环境推送到离线环境
scp doc-formatter-v1-offline-package-*.tar.gz user@offline-server:/home/user/
```

**方式4：光盘/DVD（适用于严格安全环境）**
```bash
# 刻录到光盘
growisofs -Z /dev/dvd=doc-formatter-v1-offline-package-*.tar.gz
```

#### 验证传输完整性

```bash
# 在线环境计算MD5/SHA256
md5sum doc-formatter-v1-offline-package-*.tar.gz > checksum.md5
sha256sum doc-formriter-v1-offline-package-*.tar.gz > checksum.sha256

# 将checksum文件一起传输

# 离线环境验证
md5sum -c checksum.md5
# 应该显示: doc-formatter-v1-offline-package-*.tar.gz: OK
```

---

### 阶段三：离线环境安装 🔧

#### 步骤1：解压

```bash
# 解压到用户主目录
cd ~
tar -xzvf doc-formatter-v1-offline-package-*.tar.gz

# 进入目录
cd offline_package*   # 或 offline_package_standard 等

# 查看内容
ls -lh
```

**预期输出：**
```
总用量 180M
drwxr-xr-x  2 user user 4.0K  dependencies/
-rwxr-xr-x 1 user user 15K   config_manager.py
-rwxr-xr-x 1 user user 8.2K  converter.py
drwx------ 2 user user 4.0K  dependencies/fonts/
-rw-r--r-- 1 user user 2.1K  format_config.yaml
-rwxr-xr-x 1 user user 12K   formatter.py
-rwxr-xr-x 1 user user 18K   gui.py
-rwxr-xr-x 1 user user 3.5K  install_offline.sh      ← 离线安装脚本
-rwxr-xr-x 1 user user 892   main.py
-rwxr-xr-x 1 user user 2.8K  requirements.txt
-rwxr-xr-x 1 user user 2.9K  run_linux.sh             ← 启动脚本
-rwxr-xr-x 1 user user 45M   文档格式一键转换器V1     ← 可执行文件（如有）
```

#### 步骤2：运行自动安装

```bash
# 赋予执行权限
chmod +x install_offline.sh

# 运行安装脚本
./install_offline.sh
```

**安装过程示例输出：**

```
╔═══════════════════════════════════════════════════╗
║   📦 文档格式转换器 - 离线安装工具              ║
╚═══════════════════════════════════════════════════╝

[ℹ] 检查离线包完整性...
[✓] 离线包检查通过
[ℹ] 目标系统: ubuntu 22.04
[ℹ] 安装系统级依赖...
[ℹ] 安装 Debian/Ubuntu 系统包...
[ℹ] 发现 12 个 .deb 包
正在解压 python3 (3.10.6-1~22.04) ...
正在设置 python3-tk ...
...
[✓] 系统包安装完成
[ℹ] 安装中文字体...
[✓] 字体安装完成 (2 个文件)
[ℹ] 安装Python依赖包...
[ℹ] Python版本: 3.10.6
[ℹ] 安装 Wheel 格式包...
[✓] Wheel包安装完成
[ℹ] 验证Python模块...
  ✓ GUI界面 (tkinter)
  ✓ Word文档处理 (docx)
  ✓ 配置文件解析 (yaml)
[✓] 所有Python模块验证通过
[ℹ] 配置运行环境...
[✓] 可执行文件就绪
[✓] 环境配置完成

╔═══════════════════════════════════════════════════╗
║           ✅ 离线安装成功！                      ║
╚═══════════════════════════════════════════════════╝

🎉 恭喜！文档格式一键转换器V1 已成功安装到离线环境！

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 启动方式（选择一种）：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  方式1（推荐）: 直接运行打包版本
    $ ./文档格式一键转换器V1

  方式2: 使用启动脚本
    $ ./run_linux.sh

  方式3: 源码模式运行
    $ python3 main.py

是否现在启动程序？(Y/n): 
```

#### 步骤3：启动程序

**方式1：直接运行可执行文件（最快）**
```bash
./文档格式一键转换器V1
```

**方式2：使用启动脚本（自动检测环境）**
```bash
./run_linux.sh
```

**方式3：源码模式（便于调试）**
```bash
python3 main.py
```

#### 步骤4：验证功能

程序启动后：
1. 点击"选择文件"，选择一个测试用的 `.md` 文件
2. 点击"Md文档转格式化Word"按钮
3. 等待转换完成，查看是否生成了 `*_格式化.docx` 文件
4. 打开生成的Word文档检查格式是否正确

---

## 各脚本详细说明

### 📜 download_deps.sh - 依赖下载器

**用途：** 在有网络的环境中下载所有需要的依赖包  
**位置：** 项目根目录  
**依赖：** python3, pip3, wget, apt-get/yum/dnf

**主要功能：**
```bash
# 基本用法
./download_deps.sh

# 功能列表：
# 1. 自动检测当前操作系统类型
# 2. 下载对应的系统级依赖包：
#    • Debian/Ubuntu → .deb 包
#    • CentOS/RHEL/Fedora → .rpm 包
#    • Arch Linux → .pkg.tar.xz 包
# 3. 下载Python依赖包（两种格式）：
#    • Wheel格式（.whl）→ 快速安装，无需编译
#    • 源码格式（.tar.gz）→ 备选方案
# 4. 下载开源中文字体（文泉驿正黑等）
# 5. 复制项目核心源代码文件
# 6. 可选：调用PyInstaller打包可执行文件
# 7. 生成完整的目录结构和清单文件
# 8. 最终打包为 tar.gz 压缩文件
```

**交互提示：**
- 是否同时打包可执行文件？（建议选择 Y）

**输出文件：**
```
offline_package/                    # 主目录
├── MANIFEST.txt                    # 清单文件
├── dependencies/
│   ├── system_packages/
│   │   ├── deb/                   # Debian/Ubuntu包
│   │   ├── rpm/                   # CentOS/RHEL包
│   │   └── arch/                  # Arch Linux包
│   ├── python_packages/
│   │   ├── wheels/                # Python wheel包
│   │   └── tarballs/              # Python源码包
│   └── fonts/                     # 中文字体文件
├── *.py                            # 项目源代码
├── format_config.yaml              # 配置文件
├── install_offline.sh              # 离线安装脚本
├── run_linux.sh                    # 启动脚本
└── 文档格式一键转换器V1            # 可执行文件（可选）

doc-formatter-v1-offline-package-YYYYMMDD.tar.gz  # 最终压缩包
```

---

### 📜 install_offline.sh - 离线安装器

**用途：** 在无网络环境中自动安装所有依赖  
**位置：** 离线包根目录（offline_package/ 内部）  
**前置条件：** 必须先运行 download_deps.sh 生成离线包

**主要功能：**
```bash
# 基本用法
cd offline_package
chmod +x install_offline.sh
./install_offline.sh

# 功能列表：
# 1. 验证离线包完整性（检查必要文件是否存在）
# 2. 检测目标操作系统类型
# 3. 安装系统级依赖：
#    • 使用 dpkg -i 安装 .deb 包
#    • 使用 yum/dnf install 安装 .rpm 包
#    • 使用 pacman -U 安装 Arch 包
# 4. 安装中文字体到用户目录或系统目录
# 5. 刷新字体缓存（fc-cache）
# 6. 安装Python依赖包：
#    • 优先使用 pip3 install --no-index --find-links 安装wheel
#    • 如失败则尝试源码编译安装
# 7. 验证关键模块是否正确导入
# 8. 设置可执行权限
# 9. 显示完成信息和启动选项
# 10. 可选：立即启动程序
```

**特点：**
- ✅ 全自动，无需人工干预
- ✅ 智能错误处理和回退机制
- ✅ 支持多种Linux发行版
- ✅ 彩色输出，状态清晰
- ✅ 详细日志记录

**注意事项：**
- 需要root/sudo权限来安装系统包
- 如遇依赖冲突会自动尝试修复
- 安装失败时会给出明确的错误提示

---

### 📜 create_offline_package.sh - 一键生成工具

**用途：** 提供菜单式界面，快速生成不同类型的离线包  
**位置：** 项目根目录  
**依赖：** download_deps.sh, install_offline.sh

**主要功能：**
```bash
# 基本用法
./create_offline_package.sh

# 会显示菜单：
# 请选择要生成的离线包类型：
#
#  1) 完整版（系统包 + Python包 + 字体 + 可执行文件）⭐ 推荐
#  2) 标准版（Python包 + 字体 + 可执行文件）
#  3) 轻量版（仅Python包）
#  4) 自定义模式（手动选择组件）
#  5) 仅下载依赖（不打包可执行文件）
#  q) 退出
```

**各模式详解：**

**模式1 - 完整版：**
- 调用 download_deps.sh 的全部功能
- 包含所有可能的依赖
- 适合完全空白的离线环境
- 大小：100-200MB

**模式2 - 标准版：**
- 跳过系统包下载（假设目标机器已有python3/tkinter）
- 只包含Python依赖和字体
- 打包可执行文件
- 大小：50-80MB

**模式3 - 轻量版：**
- 仅包含Python wheel包
- 最小的体积
- 适合开发环境
- 大小：20-30MB

**模式4 - 自定义：**
- 交互式选择需要包含的组件
- 可以精确控制包的内容
- 适合特殊需求

**模式5 - 仅依赖：**
- 只下载依赖，不打包exe
- 适合后续手动处理

**推荐使用场景：**
- 初次使用 → 选择模式1（完整版）
- 批量部署多台相似环境的机器 → 选择模式1
- 目标环境已知有部分依赖 → 选择模式2或3
- 需要严格控制大小 → 选择模式4自定义

---

## 常见问题解决

### ❓ 问题1：下载依赖时网络超时

**原因：** 网络不稳定或被防火墙限制

**解决方案：**
```bash
# 方法1：重试多次
for i in {1..3}; do
    echo "第 $i 次尝试..."
    ./download_deps.sh && break
    sleep 5
done

# 方法2：配置代理（如果可用）
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
./download_deps.sh

# 方法3：使用国内镜像源（针对Python包）
pip3 download -d wheels/ \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    -r requirements.txt
```

---

### ❓ 问题2：dpkg安装时依赖冲突

**错误信息：**
```
dpkg: dependency problems prevent configuration of python3-tk:
 python3-tk depends on python3 (>= 3.8); however:
  Package python3 is not configured yet.
```

**解决方案：**
```bash
# install_offline.sh 已经内置了修复逻辑
# 如果仍然失败，手动执行：

# 尝试修复
sudo apt-get -f install -y

# 或者强制配置
sudo dpkg --configure -a

# 如果缺少某些依赖但无法联网，可能需要在在线环境补充下载这些依赖包
```

---

### ❓ 问题3：pip安装wheel包失败

**错误信息：**
```
ERROR: Could not find a version that satisfies the requirement xxx
```

**解决方案：**
```bash
# 方法1：使用备选的源码包
pip3 install --no-index \
    --find-links=./dependencies/python_packages/tarballs \
    -r requirements.txt

# 方法2：逐个安装并跳过失败的包
for whl in ./dependencies/python_packages/wheels/*.whl; do
    pip3 install --no-index "$whl" || echo "跳过: $(basename $whl)"
done

# 方法3：检查Python版本兼容性
python3 --version
# 确保下载的wheel包与目标Python版本匹配
```

---

### ❓ 问题4：字体安装后中文仍显示异常

**原因：** 字体缓存未刷新或字体路径未识别

**解决方案：**
```bash
# 1. 手动刷新字体缓存
fc-cache -fv

# 2. 验证字体是否被识别
fc-list :lang=zh family

# 3. 查看字体实际位置
ls ~/.local/share/fonts/doc-formatter/

# 4. 如果仍未生效，重启桌面环境或注销重新登录

# 5. 检查字体文件完整性
file ~/.local/share/fonts/doc-formatter/*.ttf
# 应显示: TrueType font data
```

---

### ❓ 问题5：可执行文件无法运行

**错误信息：**
```
-bash: ./文档格式一键转换器V1: cannot execute binary file
```

**原因：** 架构不匹配（如x86_64 vs aarch64）

**解决方案：**
```bash
# 检查当前架构
uname -m
# 输出: x86_64 或 aarch64

# 检查可执行文件架构
file 文档格式一键转换器V1
# 输出应与 uname -m 一致

# 如果不匹配，需要在对应架构的机器上重新打包
# 或者在当前离线环境使用源码模式运行：
python3 main.py
```

---

### ❓ 问题6：磁盘空间不足

**解决方案：**
```bash
# 检查可用空间
df -h .

# 清理不必要的文件
rm -rf offline_package/dependencies/system_packages/arch/  # 不需要的平台
rm -rf offline_package/dependencies/python_packages/tarballs/ # 如果只用wheel

# 使用轻量版替代完整版
./create_offline_package.sh
# 选择 3) 轻量版
```

---

### ❓ 问题7：权限不足

**错误信息：**
```
Permission denied
```

**解决方案：**
```bash
# 为所有脚本添加执行权限
chmod +x *.sh
chmod +x 文档格式一键转换器V1

# 如果仍然报错，检查文件所有权
ls -la
# 应该属于当前用户

# 如果不是，修改所有权
chown -R $USER:$USER .
```

---

### ❓ 问题8：GUI窗口无法打开（display error）

**错误信息：**
```
_tkinter.TclError: couldn't connect to display ":0"
```

**原因：** 未在图形桌面环境中运行

**解决方案：**
```bash
# 方法1：确保在图形环境中运行
# 不要在纯TTY终端（Ctrl+Alt+F1-F6）中运行
# 要在图形桌面（GNOME/KDE/XFCE）的终端中运行

# 方法2：如果是SSH远程连接，启用X11转发
ssh -X user@localhost
./run_linux.sh

# 方法3：使用虚拟显示（headless模式）
xvfb-run python3 main.py
# 或
xvfb-run ./文档格式一键转换器V1
```

---

## 高级用法

### 🎯 场景1：批量部署到100台离线机器

```bash
# 在线环境（管理员工作站）：

# 1. 生成一次离线包
./create_offline_package.sh
# 选择 1) 完整版

# 2. 创建批量安装脚本
cat > batch_install.sh << 'EOF'
#!/bin/bash
# 批量安装脚本 - 在每台目标机器上运行

TAR_FILE="$1"
TARGET_DIR="/opt/doc-formatter"

# 解压
mkdir -p "$TARGET_DIR"
tar -xzf "$TAR_FILE" -C "$TARGET_DIR"
cd "$TARGET_DIR/offline_package"

# 安装
./install_offline.sh << 'INPUT'
n
INPUT

# 创建全局命令链接
ln -sf "$TARGET_DIR/offline_package/文档格式一键转换器V1" /usr/local/bin/doc-formatter

echo "安装完成！可通过 'doc-formatter' 命令启动"
EOF
chmod +x batch_install.sh

# 3. 通过内部文件服务器分发
cp doc-formatter-v1-offline-package-*.tar.gz /var/www/html/downloads/
cp batch_install.sh /var/www/html/downloads/

# 4. 在每台目标机器上执行：
# wget http://internal-server/downloads/batch_install.sh
# wget http://internal-server/downloads/doc-formatter-v1-offline-package-*.tar.gz
# chmod +x batch_install.sh
# ./batch_install.sh doc-formatter-v1-offline-package-*.tar.gz
```

---

### 🎯 场景2：创建企业内部YUM/APT仓库

```bash
# 在线环境：

# 1. 提取系统包
mkdir -p repo/{deb,rpm}
cp offline_package/dependencies/system_packages/deb/*.pdf repo/deb/
cp offline_package/dependencies/system_packages/rpm/*.rpm repo/rpm/

# 2. 创建APT仓库（Debian/Ubuntu）
cd repo/deb
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
# 将整个repo目录放到HTTP服务器上

# 3. 创建YUM仓库（CentOS/RHEL）
cd repo/rpm
createrepo .
# 同样放到HTTP服务器

# 4. 目标机器配置源后可直接apt/yum安装
```

---

### 🎯 场景3：Docker离线镜像

```bash
# 在线环境：

# 1. 构建Docker镜像
docker build -t doc-formatter:v1 .

# 2. 导出镜像为文件
docker save -o doc-formatter-v1-docker-image.tar doc-formatter:v1

# 3. 传输到离线环境

# 4. 在离线环境加载
docker load -i doc-formatter-v1-docker-image.tar

# 5. 运行
docker run -it --rm \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    doc-formatter:v1
```

---

### 🎯 场景4：定期更新离线包

```bash
# 创建更新脚本 update_offline.sh
#!/bin/bash
# 每月更新一次离线包

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/offline-packages"

# 备份旧版本
[ -f doc-formatter-*-offline-*.tar.gz ] && {
    mv doc-formatter-*-offline-*.tar.gz "$BACKUP_DIR/"
}

# 生成新版本
./create_offline_package.sh << 'EOF'
1
y
EOF

# 记录更新日志
echo "$(date): 生成新版离线包 - $(ls doc-formatter-*-offline-*.tar.gz)" >> update.log

# 发送通知（可选）
echo "新的离线包已生成: $(pwd)/doc-formatter-*-offline-*.tar.gz" | mail -s "离线包更新" admin@company.com
```

---

## 📊 性能参考数据

### 各阶段耗时估算

| 操作 | 环境 | 耗时 | 说明 |
|------|------|------|------|
| 下载系统包 | 100Mbps宽带 | 2-5分钟 | 取决于OS类型 |
| 下载Python包 | 100Mbps宽带 | 1-3分钟 | 约20个包 |
| 下载字体 | 100Mbps宽带 | <30秒 | 约10MB |
| 打包可执行文件 | 本地CPU | 1-3分钟 | PyInstaller |
| 解压离线包 | 本地硬盘 | 10-30秒 | 取决于磁盘速度 |
| 安装系统包 | 本地 | 30秒-2分钟 | dpkg/yum |
| 安装Python包 | 本地 | 10-30秒 | pip |
| 启动程序 | - | 2-5秒 | 首次稍慢 |

### 存储空间需求

| 组件 | 大小 |
|------|------|
| 系统包（deb） | 50-80MB |
| 系统包（rpm） | 40-70MB |
| Python wheel包 | 15-25MB |
| Python源码包 | 20-35MB |
| 字体文件 | 8-15MB |
| 项目源码 | <1MB |
| 可执行文件 | 40-60MB |
| **总计（完整版）** | **100-200MB** |
| **总计（标准版）** | **50-80MB** |
| **总计（轻量版）** | **20-30MB** |

---

## 🔒 安全注意事项

### 1. 完整性验证

始终在传输后验证文件完整性：
```bash
# 生成校验和
sha256sum doc-formatter-v1-offline-package-*.tar.gz > checksum.txt

# 验证
sha256sum -c checksum.txt
# 必须显示 OK
```

### 2. 来源可信度

- ✅ 仅从官方或受信任的源下载依赖
- ✅ 记录每个包的来源URL（MANIFEST.txt中有记录）
- ❌ 不要从未知来源添加额外的包到离线包中

### 3. 权限控制

```bash
# 离线包安装后建议调整权限
chmod -R go-w offline_package/
# 特别是可执行文件
chmod 755 文档格式一键转换器V1
```

### 4. 审计追踪

保留离线包的版本历史：
```bash
# 版本管理
mkdir -p versions
mv doc-formatter-v1-offline-package-20260518.tar.gz versions/
# 记录变更
git log --oneline > versions/changelog.txt
```

---

## 📞 技术支持

### 收集诊断信息

如果在离线环境遇到问题，请收集以下信息：

```bash
# 创建诊断报告
cat > diagnostic_report.txt << EOF
=== 系统信息 ===
$(uname -a)

=== 操作系统 ===
$(cat /etc/os-release)

=== Python ===
$(python3 --version 2>&1 || echo "Python未安装")
$(which python3 || echo "python3不在PATH中")

=== Pip ===
$(pip3 --version 2>&1 || echo "pip3未安装")

=== tkinter ===
$(python3 -c "import tkinter; print('tkinter正常')" 2>&1 || echo "tkinter有问题")

=== python-docx ===
$(python3 -c "import docx; print('python-docx:', docx.__version__)" 2>&1 || echo "python-docx未安装")

=== PyYAML ===
$(python3 -c "import yaml; print('PyYAML:', yaml.__version__)" 2>&1 || echo "PyYAML未安装")

=== 字体 ===
$(fc-list :lang=zh family 2>/dev/null | head -5 || echo "无中文字体")

=== 磁盘空间 ===
$(df -h .)

=== 离线包内容 ===
$(ls -lh)

=== 安装日志 ===
(此处粘贴install_offline.sh的完整输出)
EOF

echo "诊断报告已保存到: diagnostic_report.txt"
```

---

## 🎓 总结

### 快速参考卡

```bash
# ========== 在线环境 ==========
# 一键生成（最简单）
./create_offline_package.sh          # 选1，然后选y

# 分步执行
./download_deps.sh                   # 下载所有依赖
# （可选）手动打包exe
tar -czvf package.tar.gz offline_package/

# ========== 传输 ==========
scp package.tar.gz user@offline-machine:~/
# 或使用U盘/光盘

# ========== 离线环境 ==========
tar -xzvf package.tar.gz
cd offline_package
./install_offline.sh                 # 全自动安装
./run_linux.sh                       # 启动程序

# ========== 故障排除 ==========
fc-cache -fv                         # 刷新字体
python3 -c "import tkinter"          # 测试tkinter
pip3 list                            # 查看已安装包
```

### 推荐最佳实践

1. ✅ **首次部署**：使用完整版（模式1），确保万无一失
2. ✅ **批量部署**：先生成一个完整版测试，确认无误后再大规模分发
3. ✅ **版本管理**：保留每次生成的离线包，方便回滚
4. ✅ **文档记录**：记录目标环境的信息（OS版本、架构等）
5. ✅ **安全第一**：始终验证文件完整性
6. ✅ **定期更新**：每月或每季度更新离线包以获取bug修复

---

**文档版本**: V1.0  
**最后更新**: 2026-05-18  
**适用范围**: Linux离线环境部署  
**相关文档**: [README_LINUX.md](./README_LINUX.md), [LINUX_QUICK_REFERENCE.md](./LINUX_QUICK_REFERENCE.md)

💾 **建议将本文档与离线包一起分发，以便离线环境查阅**
