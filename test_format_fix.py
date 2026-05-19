import os
from converter import MarkdownConverter
from config_manager import ConfigManager

config = ConfigManager()
converter = MarkdownConverter(config)

test_md = """# Test Document

This is a **bold text** test.

## Section 1

> This is a blockquote with *italic* text.

---

### Subsection

Normal paragraph with `inline code` and more **bold** text.

- List item 1 with **bold**
- List item 2 with *italic*
- List item 3 normal

---

> Another blockquote
"""

temp_file = 'test_format_fix.md'
with open(temp_file, 'w', encoding='utf-8') as f:
    f.write(test_md)

try:
    output = converter.convert(temp_file)
    print(f"SUCCESS: {output}")
    if os.path.exists(output):
        print(f"File size: {os.path.getsize(output)} bytes")
except Exception as e:
    print(f"ERROR: {e}")
finally:
    if os.path.exists(temp_file):
        os.remove(temp_file)
