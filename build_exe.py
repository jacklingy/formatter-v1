import subprocess
import sys
import os

def main():
    print("=" * 60)
    print("  文档格式一键转换器 - 打包工具")
    print("=" * 60)
    print()

    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    print("[1/2] 开始打包程序...")
    print("这可能需要几分钟时间，请耐心等待...")
    print()

    try:
        result = subprocess.run([
            sys.executable, '-m', 'PyInstaller',
            '--onefile',
            '--windowed',
            '--name', '文档格式一键转换器V1.3-RELEASE',
            'main.py',
            '--noconfirm'
        ], capture_output=True, text=True, encoding='utf-8')

        if result.returncode == 0:
            print()
            print("=" * 60)
            print("  打包成功！")
            print("=" * 60)
            print()
            exe_path = os.path.join('dist', '文档格式一键转换器V1.3-RELEASE.exe')
            if os.path.exists(exe_path):
                print(f"可执行文件位置：")
                print(f"  {os.path.abspath(exe_path)}")
                print(f"文件大小：{os.path.getsize(exe_path) / (1024*1024):.2f} MB")
            else:
                print("请检查 dist 目录获取生成的文件")
            print()
        else:
            print()
            print("错误：打包失败！")
            print("错误输出：")
            print(result.stderr)

    except Exception as e:
        print(f"打包过程中出现异常：{e}")

if __name__ == '__main__':
    main()
