import os
import re
from docx import Document
from docx.shared import Pt, Twips, RGBColor, Emu, Cm, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

class WordFormatter:
    def __init__(self, config_manager):
        self.config = config_manager

    def format_document(self, docx_file_path):
        if not os.path.exists(docx_file_path):
            raise FileNotFoundError(f"Word文档不存在: {docx_file_path}")

        output_path = self._get_output_path(docx_file_path)
        doc = Document(docx_file_path)

        self._apply_document_settings(doc)
        self._format_paragraphs(doc)
        self._format_tables(doc)
        self._insert_page_numbers(doc)

        doc.save(output_path)
        return output_path

    def _get_output_path(self, input_path):
        base_name = os.path.splitext(input_path)[0]
        return f"{base_name}_已格式化.docx"

    def _apply_document_settings(self, doc):
        doc_settings = self.config.get_document_settings()
        if 'page_margin' in doc_settings:
            margins = doc_settings['page_margin']
            for section in doc.sections:
                section.top_margin = Twips(margins.get('top', 1440))
                section.bottom_margin = Twips(margins.get('bottom', 1440))
                section.left_margin = Twips(margins.get('left', 1800))
                section.right_margin = Twips(margins.get('right', 1800))

    def _format_paragraphs(self, doc):
        for para in doc.paragraphs:
            style_name = para.style.name if para.style else ''
            
            if self._is_heading_style(style_name):
                level = self._extract_heading_level(style_name)
                self._apply_heading_format(para, level)
            elif self._is_list_paragraph(para):
                self._apply_list_format(para)
            else:
                self._apply_paragraph_format(para)

    def _is_heading_style(self, style_name):
        return bool(re.match(r'Heading\s*\d+', style_name, re.IGNORECASE))

    def _extract_heading_level(self, style_name):
        match = re.search(r'\d+', style_name)
        return int(match.group()) if match else 1

    def _is_list_paragraph(self, para):
        if para.style and 'List' in para.style.name:
            return True
        if para._element.pPr is not None:
            pPr = para._element.pPr
            if pPr.numPr is not None:
                return True
            try:
                if hasattr(pPr, 'bulletListPr') and pPr.bulletListPr is not None:
                    return True
            except AttributeError:
                pass
        text = para.text.strip()
        if text and (text.startswith('•') or text.startswith('-') or 
                     re.match(r'^\d+[.\)]', text)):
            return True
        return False

    def _apply_heading_format(self, para, level):
        style_config = self.config.get_heading_style(level)
        
        font_name = style_config.get('font_name', '黑体')
        font_size = style_config.get('font_size', 14)
        bold = style_config.get('bold', True)
        alignment = style_config.get('alignment', 'left')
        space_before = style_config.get('space_before', 120)
        space_after = style_config.get('space_after', 60)
        color = style_config.get('color', '000000')
        first_line_indent = style_config.get('first_line_indent', 480)

        for run in para.runs:
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
        
        if first_line_indent and first_line_indent > 0:
            para_format.first_line_indent = Twips(first_line_indent)
        else:
            para_format.first_line_indent = Twips(0)

    def _apply_paragraph_format(self, para):
        para_style = self.config.get_paragraph_style()
        font_settings = self.config.get_font_settings()

        font_name = font_settings.get('default_font', '宋体')
        font_size = font_settings.get('default_size', 12)
        color = font_settings.get('default_color', '000000')
        line_spacing = para_style.get('line_spacing', 1.5)
        first_indent = para_style.get('first_line_indent', 480)
        alignment = para_style.get('alignment', 'left')
        bold = para_style.get('bold', False)
        space_before = para_style.get('space_before', 0)
        space_after = para_style.get('space_after', 0)

        for run in para.runs:
            run.font.name = font_name
            run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
            run.font.size = Pt(font_size)
            run.font.color.rgb = RGBColor.from_string(color)
            run.font.bold = bold

        alignment_map = {
            'left': WD_ALIGN_PARAGRAPH.LEFT,
            'center': WD_ALIGN_PARAGRAPH.CENTER,
            'right': WD_ALIGN_PARAGRAPH.RIGHT,
            'justify': WD_ALIGN_PARAGRAPH.JUSTIFY
        }
        
        para_format = para.paragraph_format
        para_format.alignment = alignment_map.get(alignment, WD_ALIGN_PARAGRAPH.LEFT)
        para_format.line_spacing = line_spacing
        para_format.first_line_indent = Twips(first_indent)
        para_format.space_before = Pt(space_before / 20)
        para_format.space_after = Pt(space_after / 20)

    def _apply_list_format(self, para):
        list_style = self.config.get_list_style()
        font_settings = self.config.get_font_settings()

        font_name = font_settings.get('default_font', '宋体')
        font_size = font_settings.get('default_size', 12)
        indent_left = list_style.get('indent_left', 720)

        for run in para.runs:
            run.font.name = font_name
            run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
            run.font.size = Pt(font_size)

        para.paragraph_format.left_indent = Twips(indent_left)

    def _format_tables(self, doc):
        table_style_config = self.config.get_table_style()
        
        for table in doc.tables:
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            
            self._set_table_auto_fit(table)
            
            for row_idx, row in enumerate(table.rows):
                is_header_row = (row_idx == 0)
                
                if is_header_row:
                    style = table_style_config.get('header', {})
                else:
                    style = table_style_config.get('body', {})
                
                font_name = style.get('font_name', '宋体')
                font_size = style.get('font_size', 10.5)
                bold = style.get('bold', False)
                bg_color = style.get('background_color', [255, 255, 255])
                text_align = style.get('text_alignment', 'center')
                
                row.height_rule = None
                
                for cell in row.cells:
                    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
                    
                    self._set_cell_borders(cell)
                    
                    self._set_cell_background(cell, bg_color)
                    
                    for paragraph in cell.paragraphs:
                        if is_header_row:
                            paragraph.paragraph_format.keep_with_next = True
                        
                        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                        
                        for run in paragraph.runs:
                            run.font.name = font_name
                            run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
                            run._element.rPr.rFonts.set(qn('w:ascii'), font_name)
                            run._element.rPr.rFonts.set(qn('w:hAnsi'), font_name)
                            run._element.rPr.rFonts.set(qn('w:cs'), font_name)
                            
                            run.font.size = Pt(font_size)
                            run.font.bold = bold
                            run.font.italic = False
                            run.font.color.rgb = RGBColor(0, 0, 0)

    def _set_table_auto_fit(self, table):
        tbl = table._tbl
        tblPr = tbl.tblPr if tbl.tblPr is not None else OxmlElement('w:tblPr')
        
        tblLayout = OxmlElement('w:tblLayout')
        tblLayout.set(qn('w:type'), 'auto')
        tblPr.append(tblLayout)
        
        if tbl.tblPr is None:
            tbl.insert(0, tblPr)
    
    def _set_cell_borders(self, cell, border_color='000000', border_width=1):
        tc = cell._tc
        tcPr = tc.tcPr if tc.tcPr is not None else OxmlElement('w:tcPr')
        
        tcBorders = OxmlElement('w:tcBorders')
        for border_name in ['top', 'left', 'bottom', 'right']:
            border = OxmlElement(f'w:{border_name}')
            border.set(qn('w:val'), 'single')
            border.set(qn('w:sz'), str(border_width * 8))
            border.set(qn('w:color'), border_color)
            border.set(qn('w:space'), '0')
            tcBorders.append(border)
        
        tcPr.append(tcBorders)
        
        if tc.tcPr is None:
            tc.insert(0, tcPr)
    
    def _set_cell_background(self, cell, rgb_color):
        tc = cell._tc
        tcPr = tc.tcPr if tc.tcPr is not None else OxmlElement('w:tcPr')
        
        shd = OxmlElement('w:shd')
        shd.set(qn('w:val'), 'clear')
        shd.set(qn('w:color'), 'auto')
        
        r, g, b = rgb_color
        hex_color = '{:02X}{:02X}{:02X}'.format(r, g, b)
        shd.set(qn('w:fill'), hex_color)
        
        tcPr.append(shd)
        
        if tc.tcPr is None:
            tc.insert(0, tcPr)

    def _insert_page_numbers(self, doc):
        page_number_config = self.config.get_page_number_settings()
        
        if not page_number_config.get('enabled', False):
            return
        
        position = page_number_config.get('position', 'bottom_center')
        font_name = page_number_config.get('font_name', '宋体')
        chinese_font = page_number_config.get('chinese_font', '宋体')
        western_font = page_number_config.get('western_font', 'Times New Roman')
        font_size = page_number_config.get('font_size', 10.5)
        bold = page_number_config.get('bold', False)
        format_str = page_number_config.get('format', '{n}')
        start_from = page_number_config.get('start_from', 1)
        show_on_first = page_number_config.get('show_on_first_page', True)
        
        for section_idx, section in enumerate(doc.sections):
            footer = section.footer
            footer.is_linked_to_previous = False
            
            if len(footer.paragraphs) == 0:
                footer.add_paragraph()
            
            paragraph = footer.paragraphs[0]
            paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
            
            self._add_page_number_field(paragraph, start_from, font_name, chinese_font, 
                                       western_font, font_size, bold, format_str)

    def _add_page_number_field(self, paragraph, start_from, font_name, chinese_font, 
                               western_font, font_size, bold, format_str):
        run = paragraph.add_run()
        
        fld_char_begin = OxmlElement('w:fldChar')
        fld_char_begin.set(qn('w:fldCharType'), 'begin')
        
        instr_text = OxmlElement('w:instrText')
        field_code = ' PAGE '
        if start_from != 1:
            field_code = f' PAGE \\* MERGEFORMAT '
        instr_text.text = field_code
        
        fld_char_separate = OxmlElement('w:fldChar')
        fld_char_separate.set(qn('w:fldCharType'), 'separate')
        
        fld_char_end = OxmlElement('w:fldChar')
        fld_char_end.set(qn('w:fldCharType'), 'end')
        
        run._r.append(fld_char_begin)
        run._r.append(instr_text)
        run._r.append(fld_char_separate)
        run._r.append(fld_char_end)
        
        run.font.name = font_name
        run._element.rPr.rFonts.set(qn('w:eastAsia'), chinese_font)
        run._element.rPr.rFonts.set(qn('w:ascii'), western_font)
        run._element.rPr.rFonts.set(qn('w:hAnsi'), western_font)
        run._element.rPr.rFonts.set(qn('w:cs'), western_font)
        
        run.font.size = Pt(font_size)
        run.font.bold = bold
        run.font.color.rgb = RGBColor(0, 0, 0)
