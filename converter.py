import os
import re
from docx import Document
from docx.shared import Pt, Inches, Cm, RGBColor, Twips
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

class MarkdownConverter:
    def __init__(self, config_manager):
        self.config = config_manager

    def convert(self, md_file_path):
        if not os.path.exists(md_file_path):
            raise FileNotFoundError(f"Markdown文件不存在: {md_file_path}")

        with open(md_file_path, 'r', encoding='utf-8') as f:
            md_content = f.read()

        output_path = self._get_output_path(md_file_path)
        doc = Document()
        self._apply_document_settings(doc)
        self._parse_markdown(doc, md_content)
        doc.save(output_path)
        return output_path

    def _get_output_path(self, input_path):
        base_name = os.path.splitext(input_path)[0]
        return f"{base_name}_格式化.docx"

    def _apply_document_settings(self, doc):
        doc_settings = self.config.get_document_settings()
        if 'page_margin' in doc_settings:
            margins = doc_settings['page_margin']
            for section in doc.sections:
                section.top_margin = Twips(margins.get('top', 1440))
                section.bottom_margin = Twips(margins.get('bottom', 1440))
                section.left_margin = Twips(margins.get('left', 1800))
                section.right_margin = Twips(margins.get('right', 1800))

    def _parse_markdown(self, doc, content):
        lines = content.split('\n')
        i = 0
        in_list = False
        list_type = None
        list_items = []

        while i < len(lines):
            line = lines[i].rstrip()

            heading_match = re.match(r'^(#{1,6})\s+(.+)$', line)
            if heading_match:
                if in_list and list_items:
                    self._add_list(doc, list_type, list_items)
                    list_items = []
                    in_list = False
                level = len(heading_match.group(1))
                text = heading_match.group(2).strip()
                self._add_heading(doc, text, level)
                i += 1
                continue

            if line.startswith('- ') or line.startswith('* '):
                if not in_list or list_type != 'bullet':
                    if in_list and list_items:
                        self._add_list(doc, list_type, list_items)
                        list_items = []
                    in_list = True
                    list_type = 'bullet'
                list_items.append(line[2:].strip())
                i += 1
                continue

            numbered_match = re.match(r'^\d+\.\s+(.+)$', line)
            if numbered_match:
                if not in_list or list_type != 'numbered':
                    if in_list and list_items:
                        self._add_list(doc, list_type, list_items)
                        list_items = []
                    in_list = True
                    list_type = 'numbered'
                list_items.append(numbered_match.group(1).strip())
                i += 1
                continue

            if in_list and list_items:
                self._add_list(doc, list_type, list_items)
                list_items = []
                in_list = False

            if line.strip() == '':
                i += 1
                continue

            code_block_match = re.match(r'^```(\w*)$', line)
            if code_block_match:
                lang = code_block_match.group(1)
                code_lines = []
                i += 1
                while i < len(lines) and lines[i].strip() != '```':
                    code_lines.append(lines[i])
                    i += 1
                self._add_code_block(doc, '\n'.join(code_lines), lang)
                i += 1
                continue

            table_match = re.match(r'^\|(.+)\|$', line)
            if table_match:
                table_lines = [line]
                i += 1
                while i < len(lines) and (lines[i].startswith('|') or re.match(r'^[\|\s\-:]+$', lines[i])):
                    if not re.match(r'^[\|\s\-:]+$', lines[i]):
                        table_lines.append(lines[i])
                    i += 1
                self._add_table(doc, table_lines)
                continue

            text = line
            while i + 1 < len(lines) and lines[i + 1].strip() != '' and \
                  not lines[i + 1].startswith('#') and \
                  not lines[i + 1].startswith('-') and \
                  not lines[i + 1].startswith('*') and \
                  not re.match(r'^\d+\.', lines[i + 1]) and \
                  not lines[i + 1].startswith('|') and \
                  not lines[i + 1].startswith('```'):
                i += 1
                text += '\n' + lines[i]

            self._add_paragraph(doc, text)
            i += 1

        if in_list and list_items:
            self._add_list(doc, list_type, list_items)

    def _add_heading(self, doc, text, level):
        style_config = self.config.get_heading_style(level)
        para = doc.add_paragraph()
        run = para.add_run(text)

        font_name = style_config.get('font_name', '黑体')
        font_size = style_config.get('font_size', 14)
        bold = style_config.get('bold', True)
        alignment = style_config.get('alignment', 'left')
        space_before = style_config.get('space_before', 120)
        space_after = style_config.get('space_after', 60)
        color = style_config.get('color', '000000')

        run.font.name = font_name
        run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
        run.font.size = Pt(font_size)
        run.font.bold = bold
        run.font.color.rgb = RGBColor.from_string(color)

        alignment_map = {
            'left': WD_ALIGN_PARAGRAPH.LEFT,
            'center': WD_ALIGN_PARAGRAPH.CENTER,
            'right': WD_ALIGN_PARAGRAPH.RIGHT,
            'justify': WD_ALIGN_PARAGRAPH.JUSTIFY
        }
        para.alignment = alignment_map.get(alignment, WD_ALIGN_PARAGRAPH.LEFT)

        para_format = para.paragraph_format
        para_format.space_before = Pt(space_before / 20)
        para_format.space_after = Pt(space_after / 20)

    def _add_paragraph(self, doc, text):
        para_style = self.config.get_paragraph_style()
        font_settings = self.config.get_font_settings()

        para = doc.add_paragraph()
        processed_text = self._process_inline_formatting(text)
        run = para.add_run(processed_text)

        font_name = font_settings.get('default_font', '宋体')
        font_size = font_settings.get('default_size', 12)
        color = font_settings.get('default_color', '000000')

        run.font.name = font_name
        run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
        run.font.size = Pt(font_size)
        run.font.color.rgb = RGBColor.from_string(color)

        line_spacing = para_style.get('line_spacing', 1.5)
        first_indent = para_style.get('first_line_indent', 480)
        space_before = para_style.get('space_before', 0)
        space_after = para_style.get('space_after', 0)

        para_format = para.paragraph_format
        para_format.line_spacing = line_spacing
        para_format.first_line_indent = Twips(first_indent)
        para_format.space_before = Pt(space_before / 20)
        para_format.space_after = Pt(space_after / 20)

    def _add_list(self, doc, list_type, items):
        list_style = self.config.get_list_style()
        font_settings = self.config.get_font_settings()

        for item in items:
            para = doc.add_paragraph()
            prefix = list_style.get('bullet_char', '•') + ' ' if list_type == 'bullet' else ''
            run = para.add_run(f"{prefix}{item}")

            font_name = font_settings.get('default_font', '宋体')
            font_size = font_settings.get('default_size', 12)

            run.font.name = font_name
            run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
            run.font.size = Pt(font_size)

            indent_left = list_style.get('indent_left', 720)
            para.paragraph_format.left_indent = Twips(indent_left)

    def _add_code_block(self, doc, code, language=None):
        para = doc.add_paragraph()
        run = para.add_run(code)
        run.font.name = 'Consolas'
        run.font.size = Pt(10)
        para.paragraph_format.left_indent = Twips(720)

    def _add_table(self, doc, table_lines):
        if not table_lines:
            return

        rows_data = []
        for line in table_lines:
            cells = [cell.strip() for cell in line.split('|')[1:-1]]
            rows_data.append(cells)

        if len(rows_data) < 1:
            return

        num_cols = len(rows_data[0])
        table = doc.add_table(rows=len(rows_data), cols=num_cols)
        table.style = 'Table Grid'

        table_style_config = self.config.get_table_style()

        for i, row_data in enumerate(rows_data):
            row = table.rows[i]
            for j, cell_text in enumerate(row_data):
                if j < len(row.cells):
                    cell = row.cells[j]
                    cell.text = cell_text
                    for paragraph in cell.paragraphs:
                        for run in paragraph.runs:
                            run.font.size = Pt(10)
                            run.font.name = '宋体'
                            run._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')

    def _process_inline_formatting(self, text):
        text = re.sub(r'\*\*(.+?)\*\*', r'\1', text)
        text = re.sub(r'\*(.+?)\*', r'\1', text)
        text = re.sub(r'`(.+?)`', r'\1', text)
        return text
