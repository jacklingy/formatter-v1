@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
::  Windows下快速构建Linux版本 - V1.3-RELEASE
::  使用Docker容器化打包环境
:: ============================================

title 文档格式一键转换器 - Linux版本构建工具

echo.
echo ╔══════════════════════════════════════════════╗
echo ║   文档格式一键转换器 V1.3-RELEASE 构建工具     ║
echo ╚══════════════════════════════════════════════╝
echo.

:: 检查Docker是否安装
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未检测到Docker！
    echo.
    echo 请先安装Docker Desktop：
    echo   https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

echo [信息] Docker已安装

:: 检查Docker是否运行
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] Docker未运行！
    echo.
    echo 请启动Docker Desktop应用程序
    pause
    exit /b 1
)

echo [信息] Docker运行正常
echo.

:: 设置目录
set "SOURCE_DIR=%~dp0"
set "OUTPUT_DIR=%SOURCE_DIR%dist_linux"
set "IMAGE_NAME=doc-formatter-builder"
set "IMAGE_TAG=v1.3-release"

:: 创建输出目录
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [步骤 1/4] 构建Docker镜像...
echo.
docker build -t %IMAGE_NAME%:%IMAGE_TAG% -f Dockerfile.build .
if %errorlevel% neq 0 (
    echo [错误] Docker镜像构建失败！
    pause
    exit /b 1
)

echo.
echo [成功] Docker镜像构建完成
echo.
echo [步骤 2/4] 运行容器打包Linux可执行文件...
echo.
docker run --rm ^
    -v "%SOURCE_DIR%:/app/source" ^
    -v "%OUTPUT_DIR%:/output" ^
    %IMAGE_NAME%:%IMAGE_TAG%

if %errorlevel% neq 0 (
    echo [错误] 打包过程失败！
    pause
    exit /b 1
)

echo.
echo [成功] 打包完成
echo.
echo [步骤 3/4] 验证生成的文件...
echo.

:: 检查输出文件
if exist "%OUTPUT_DIR%\文档格式一键转换器V1.3-RELEASE" (
    for %%A in ("%OUTPUT_DIR%\文档格式一键转换器V1.3-RELEASE") do (
        set FILE_SIZE=%%~zA
        set /set FILE_SIZE_MB=!FILE_SIZE! / 1048576
    )
    
    echo [成功] 可执行文件已生成：
    echo   路径: %OUTPUT_DIR%\文档格式一键转换器V1.3-RELEASE
    
    :: 显示文件大小（使用PowerShell）
    for /f "tokens=*" %%i in ('powershell -command "(Get-Item '%OUTPUT_DIR%\文档格式一键转换器V1.3-RELEASE').Length / 1MB"') do set SIZE_MB=%%i
    echo   大小: 约 !SIZE_MB! MB
    
) else (
    echo [警告] 未找到预期的输出文件
    echo 请检查 %OUTPUT_DIR% 目录
)

echo.
echo [步骤 4/4] 清理临时资源（可选）...
echo.

:: 询问是否清理Docker镜像
set /p CLEANUP="是否清理Docker镜像以释放磁盘空间？(y/n): "
if /i "%CLEANUP%"=="y" (
    docker rmi %IMAGE_NAME%:%IMAGE_TAG%
    echo [信息] 已清理Docker镜像
)

echo.
echo ╔══════════════════════════════════════════════╗
echo ║              ✅ 构建完成！                   ║
echo ╚══════════════════════════════════════════════╝
echo.
echo 📦 输出位置: %OUTPUT_DIR%\
echo 📄 可执行文件: 文档格式一键转换器V1.3-RELEASE
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 使用方法：
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo  方式1：复制到Linux系统运行
echo    将可执行文件复制到Linux系统
echo    chmod +x 文档格式一键转换器V1.3-RELEASE
echo    ./文档格式一键转换器V1.3-RELEASE
echo.
echo  方式2：分发压缩包
echo    使用7-Zip或WinRAR压缩dist_linux文件夹
echo    分发给Linux用户
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
pause

:: 打开输出文件夹
explorer "%OUTPUT_DIR%"
