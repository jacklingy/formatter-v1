@echo off
echo ========================================
echo   文档格式一键转换器 - 打包工具
echo ========================================
echo.

echo [1/3] 检查 Python 环境...
python --version >nul 2>&1
if errorlevel 1 (
    echo 错误：未检测到 Python 环境，请先安装 Python
    pause
    exit /b 1
)
echo Python 环境检查通过

echo.
echo [2/3] 安装依赖包...
pip install -r requirements.txt -q
if errorlevel 1 (
    echo 错误：依赖包安装失败
    pause
    exit /b 1
)
echo 依赖包安装完成

echo.
echo [3/3] 开始打包 Windows 可执行文件...
echo 这可能需要几分钟时间，请耐心等待...
echo.

pyinstaller build.spec --clean --noconfirm

if errorlevel 1 (
    echo.
    echo 错误：打包失败！请检查错误信息
    pause
    exit /b 1
)

echo.
echo ========================================
echo   打包完成！
echo ========================================
echo.
echo 可执行文件位置：
echo   dist\文档格式一键转换器 V1.1\文档格式一键转换器 V1.1.exe
echo.
echo 配置文件将自动生成在 exe 同目录下
echo.

pause
