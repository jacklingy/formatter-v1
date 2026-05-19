from docx import Document
import os

output_file = 'test_format_fix_格式化.docx'

if os.path.exists(output_file):
    doc = Document(output_file)
    
    print("=== Document Structure ===\n")
    
    for i, para in enumerate(doc.paragraphs[:15]):
        text = para.text[:80] if para.text else "[Empty]"
        runs_info = []
        
        for run in para.runs:
            run_text = run.text[:20] if run.text else ""
            bold = run.bold if run.bold is not None else False
            italic = run.italic if run.italic is not None else False
            font_name = run.font.name or "Default"
            
            if run_text.strip():
                runs_info.append(f"'{run_text}'(bold={bold}, italic={italic}, font={font_name})")
        
        print(f"Para {i}: {text}")
        if runs_info:
            for info in runs_info:
                print(f"  -> {info}")
        print()
else:
    print(f"File not found: {output_file}")
