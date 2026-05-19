import os
import sys
import subprocess
import threading
from tkinter import *
from tkinter import ttk, messagebox, filedialog
from config_manager import ConfigManager
from converter import MarkdownConverter
from formatter import WordFormatter

class MainWindow(Tk):
    def __init__(self):
        super().__init__()
        self.selected_file = None
        self.config_manager = ConfigManager()
        self.init_ui()

    def init_ui(self):
        self.title('文档格式一键转换器 V1.1')
        self.geometry('600x280')
        self.minsize(550, 250)
        self.configure(bg='#F0F0F0')

        style = ttk.Style()
        style.theme_use('clam')

        main_frame = Frame(self, bg='#F0F0F0', padx=30, pady=25)
        main_frame.pack(fill=BOTH, expand=True)

        row1_frame = Frame(main_frame, bg='#F0F0F0')
        row1_frame.pack(fill=X, pady=(0, 15))

        select_label = Label(row1_frame, text="选择文件：", font=('Microsoft YaHei UI', 11, 'bold'),
                           bg='#F0F0F0', fg='#333333')
        select_label.pack(side=LEFT)

        self.select_btn = Button(row1_frame, text="选择文件", command=self.select_file,
                                font=('Microsoft YaHei UI', 10), width=12,
                                bg='#4A90E2', fg='white', activebackground='#357ABD',
                                activeforeground='white', relief=FLAT, cursor='hand2',
                                padx=18, pady=6)
        self.select_btn.pack(side=LEFT, padx=(10, 0))

        row2_frame = Frame(main_frame, bg='#F0F0F0')
        row2_frame.pack(fill=X, pady=(0, 15))

        path_label = Label(row2_frame, text="文件路径：", font=('Microsoft YaHei UI', 11, 'bold'),
                          bg='#F0F0F0', fg='#333333')
        path_label.pack(side=LEFT)

        self.path_display = Entry(row2_frame, font=('Microsoft YaHei UI', 10),
                                 state='readonly', width=50)
        self.path_display.insert(0, "请先选择文件")
        self.path_display.pack(side=LEFT, fill=X, expand=True, padx=(10, 0))

        row3_frame = Frame(main_frame, bg='#F0F0F0')
        row3_frame.pack(fill=X, pady=(0, 20))

        self.convert_btn = Button(row3_frame, text="Md文档转格式化Word",
                                 command=self.convert_md_to_docx,
                                 font=('Microsoft YaHei UI', 10, 'bold'), width=22,
                                 bg='#CCCCCC', fg='#666666', state=DISABLED,
                                 relief=FLAT, cursor='hand2', pady=8)
        self.convert_btn.pack(side=LEFT, padx=(0, 10))

        self.format_btn = Button(row3_frame, text="一键格式化Word",
                                command=self.format_word,
                                font=('Microsoft YaHei UI', 10, 'bold'), width=22,
                                bg='#CCCCCC', fg='#666666', state=DISABLED,
                                relief=FLAT, cursor='hand2', pady=8)
        self.format_btn.pack(side=LEFT)

        bottom_frame = Frame(main_frame, bg='#F0F0F0')
        bottom_frame.pack(fill=X)

        self.settings_btn = Button(bottom_frame, text="格式设置", command=self.open_config_file,
                                  font=('Microsoft YaHei UI', 10, 'bold'), width=12,
                                  bg='#6C757D', fg='white', activebackground='#5A6268',
                                  activeforeground='white', relief=FLAT, cursor='hand2',
                                  padx=14, pady=6)
        self.settings_btn.pack(side=RIGHT)

        self.progress_var = StringVar()
        self.progress_var.set("")
        self.progress_label = Label(main_frame, textvariable=self.progress_var,
                                   font=('Microsoft YaHei UI', 9), bg='#F0F0F0', fg='#4A90E2')
        self.progress_label.pack(pady=(10, 0))

    def select_file(self):
        file_path = filedialog.askopenfilename(
            title="选择文件",
            filetypes=[
                ("支持格式", "*.md *.doc *.docx"),
                ("Markdown 文件", "*.md"),
                ("Word 文件", "*.doc *.docx")
            ]
        )

        if file_path:
            self.selected_file = file_path
            self.path_display.config(state=NORMAL)
            self.path_display.delete(0, END)
            self.path_display.insert(0, file_path)
            self.path_display.config(state='readonly')
            self.update_button_states()

    def update_button_states(self):
        if not self.selected_file:
            self.convert_btn.config(state=DISABLED, bg='#CCCCCC', fg='#666666')
            self.format_btn.config(state=DISABLED, bg='#CCCCCC', fg='#666666')
            return

        _, ext = os.path.splitext(self.selected_file)
        ext = ext.lower()

        if ext == '.md':
            self.convert_btn.config(state=NORMAL, bg='#28A745', fg='white',
                                   activebackground='#218838')
            self.format_btn.config(state=DISABLED, bg='#CCCCCC', fg='#666666')
        elif ext in ['.doc', '.docx']:
            self.convert_btn.config(state=DISABLED, bg='#CCCCCC', fg='#666666')
            self.format_btn.config(state=NORMAL, bg='#FFC107', fg='#333333',
                                  activebackground='#E0A800')
        else:
            self.convert_btn.config(state=DISABLED, bg='#CCCCCC', fg='#666666')
            self.format_btn.config(state=DISABLED, bg='#CCCCCC', fg='#666666')

    def convert_md_to_docx(self):
        if not self.selected_file:
            return
        self._start_conversion('md_to_docx')

    def format_word(self):
        if not self.selected_file:
            return
        self._start_conversion('format_word')

    def _start_conversion(self, operation):
        self.progress_var.set("正在处理，请稍候...")
        self.convert_btn.config(state=DISABLED)
        self.format_btn.config(state=DISABLED)
        self.select_btn.config(state=DISABLED)

        thread = threading.Thread(target=self._run_conversion, args=(operation,))
        thread.daemon = True
        thread.start()
        self.after(100, self._check_thread, thread)

    def _run_conversion(self, operation):
        try:
            config = ConfigManager()
            if operation == 'md_to_docx':
                converter = MarkdownConverter(config)
                output_path = converter.convert(self.selected_file)
                self.after(0, self._show_success, '转换成功', output_path)
            elif operation == 'format_word':
                formatter = WordFormatter(config)
                output_path = formatter.format_document(self.selected_file)
                self.after(0, self._show_success, '格式化成功', output_path)
        except Exception as e:
            self.after(0, self._show_error, str(e))
        finally:
            self.after(0, self._reset_buttons)

    def _check_thread(self, thread):
        if thread.is_alive():
            self.after(100, self._check_thread, thread)

    def _show_success(self, message, output_path):
        self.progress_var.set("")
        messagebox.showinfo("操作成功", f"{message}\n\n文件已保存至：\n{output_path}")

    def _show_error(self, error_message):
        self.progress_var.set("")
        messagebox.showerror("操作失败", f"处理过程中出现错误：\n\n{error_message}")

    def _reset_buttons(self):
        self.update_button_states()
        self.select_btn.config(state=NORMAL)

    def open_config_file(self):
        config_path = self.config_manager.get_config_path()

        if not os.path.exists(config_path):
            self.config_manager.create_default_config()

        try:
            if sys.platform == 'win32':
                os.startfile(config_path)
            elif sys.platform == 'darwin':
                subprocess.run(['open', config_path])
            else:
                subprocess.run(['xdg-open', config_path])
        except Exception as e:
            messagebox.showwarning("无法打开配置文件",
                                 f"无法自动打开配置文件，请手动打开以下路径：\n\n{config_path}\n\n错误信息：\n{str(e)}")

def main():
    root = MainWindow()
    root.mainloop()

if __name__ == '__main__':
    main()
