import os
import sys
import yaml

class ConfigManager:
    def __init__(self):
        self.config_file = self._get_fixed_config_path()
        self.config = None
        self.load_or_create_config()

    def _get_fixed_config_path(self):
        if getattr(sys, 'frozen', False):
            base_dir = os.path.dirname(sys.executable)
        else:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        
        config_path = os.path.join(base_dir, 'format_config.yaml')
        return config_path

    def get_default_config(self):
        return {
            'document': {
                'page_margin': {
                    'top': 1440,
                    'bottom': 1440,
                    'left': 1800,
                    'right': 1800
                }
            },
            'font_settings': {
                'default_font': '仿宋_GB2312',
                'default_size': 12,
                'default_color': '000000'
            },
            'heading_styles': {
                'heading1': {
                    'font_name': '宋体',
                    'font_size': 18,
                    'bold': True,
                    'alignment': 'center',
                    'first_line_indent': 0,
                    'space_before': 240,
                    'space_after': 120,
                    'color': '000000'
                },
                'heading2': {
                    'font_name': '黑体',
                    'font_size': 12,
                    'bold': True,
                    'alignment': 'justify',
                    'first_line_indent': 480,
                    'space_before': 200,
                    'space_after': 100,
                    'color': '000000'
                },
                'heading3': {
                    'font_name': '楷体_GB2312',
                    'font_size': 12,
                    'bold': True,
                    'alignment': 'justify',
                    'first_line_indent': 480,
                    'space_before': 160,
                    'space_after': 80,
                    'color': '000000'
                },
                'heading4': {
                    'font_name': '仿宋_GB2312',
                    'font_size': 12,
                    'bold': True,
                    'alignment': 'justify',
                    'first_line_indent': 480,
                    'space_before': 120,
                    'space_after': 60,
                    'color': '000000'
                },
                'heading5': {
                    'font_name': '仿宋_GB2312',
                    'font_size': 12,
                    'bold': True,
                    'alignment': 'justify',
                    'first_line_indent': 480,
                    'space_before': 100,
                    'space_after': 50,
                    'color': '000000'
                },
                'heading6': {
                    'font_name': '仿宋_GB2312',
                    'font_size': 12,
                    'bold': True,
                    'alignment': 'justify',
                    'first_line_indent': 480,
                    'space_before': 80,
                    'space_after': 40,
                    'color': '000000'
                }
            },
            'paragraph_style': {
                'line_spacing': 1.5,
                'alignment': 'justify',
                'first_line_indent': 480,
                'bold': False,
                'space_before': 0,
                'space_after': 0
            },
            'list_style': {
                'bullet_char': '•',
                'numbered_format': '%d.',
                'indent_left': 720,
                'space_between_items': 60
            },
            'page_number': {
                'enabled': True,
                'position': 'bottom_center',
                'font_name': '宋体',
                'chinese_font': '宋体',
                'western_font': 'Times New Roman',
                'font_size': 10.5,
                'bold': False,
                'format': '{n}',
                'start_from': 1,
                'show_on_first_page': True
            },
            'number_format': {
                'thousands_separator': True,
                'separator_char': ',',
                'decimal_point': '.',
                'min_decimal_places': -1,
                'max_decimal_places': -1,
                'handle_negative': True,
                'pattern': '^-?\\d{1,3}(,\\d{3})*(\\.\\d+)?$',
                'ignore_patterns': [
                    '\\b\\d{4}\\b',
                    'v\\d+\\.\\d+\\.\\d+',
                    '\\d{11}',
                    '\\d{15,18}',
                    '\\d+-\\d+-\\d+'
                ]
            },
            'table_style': {
                'border_color': '000000',
                'border_width': 1,
                'cell_padding': 100,
                'auto_fit': True,
                'width_strategy': 'auto',
                'min_column_width': 1080,
                'max_column_width': 4320,
                'header': {
                    'font_name': '宋体',
                    'font_size': 10.5,
                    'bold': True,
                    'background_color': [217, 217, 217],
                    'text_alignment': 'center'
                },
                'body': {
                    'font_name': '宋体',
                    'font_size': 10.5,
                    'bold': False,
                    'background_color': [255, 255, 255],
                    'text_alignment': 'center'
                }
            }
        }

    def load_or_create_config(self):
        if os.path.exists(self.config_file):
            self.load_config()
        else:
            self.create_default_config()

    def create_default_config(self):
        self.config = self.get_default_config()
        with open(self.config_file, 'w', encoding='utf-8') as f:
            yaml.dump(self.config, f, allow_unicode=True, default_flow_style=False, sort_keys=False)

    def load_config(self):
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                self.config = yaml.safe_load(f)
                if self.config is None:
                    self.create_default_config()
                    return
                default_config = self.get_default_config()
                for key in default_config:
                    if key not in self.config:
                        self.config[key] = default_config[key]
        except Exception as e:
            print(f"加载配置文件失败: {e}")
            self.create_default_config()

    def get_heading_style(self, level):
        heading_key = f'heading{level}'
        if heading_key in self.config.get('heading_styles', {}):
            return self.config['heading_styles'][heading_key]
        return self.config['heading_styles'].get('heading1', {})

    def get_paragraph_style(self):
        return self.config.get('paragraph_style', {})

    def get_list_style(self):
        return self.config.get('list_style', {})

    def get_font_settings(self):
        return self.config.get('font_settings', {})

    def get_document_settings(self):
        return self.config.get('document', {})

    def get_table_style(self):
        return self.config.get('table_style', {})

    def get_page_number_settings(self):
        return self.config.get('page_number', {})

    def get_number_format_settings(self):
        return self.config.get('number_format', {})

    def get_config_path(self):
        return self.config_file

    def reload_config(self):
        self.load_or_create_config()
