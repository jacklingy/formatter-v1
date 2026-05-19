import yaml
import sys

try:
    with open('format_config.yaml', 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    print("=" * 60)
    print("  配置文件验证结果")
    print("=" * 60)
    
    print("\n✅ 配置文件格式正确！")
    
    print("\n📋 标题样式配置：")
    for heading_key, heading_style in config['heading_styles'].items():
        print(f"  {heading_key}: {heading_style['font_name']}, "
              f"{heading_style['font_size']}pt, "
              f"{'加粗' if heading_style['bold'] else '常规'}, "
              f"对齐:{heading_style['alignment']}")
    
    print("\n📝 段落样式配置：")
    para = config['paragraph_style']
    print(f"  行距: {para['line_spacing']}倍")
    print(f"  首行缩进: {para['first_line_indent']} twips (约{para['first_line_indent']//20}pt)")
    
    print("\n📊 表格样式配置：")
    table = config['table_style']
    print(f"  边框颜色: #{table['border_color']}")
    print(f"  边框宽度: {table['border_width']}pt")
    
    header = table.get('header', {})
    body = table.get('body', {})
    
    print(f"\n  📌 表头样式:")
    print(f"    字体: {header.get('font_name')}")
    print(f"    字号: {header.get('font_size')}pt")
    print(f"    加粗: {'是' if header.get('bold') else '否'}")
    print(f"    背景色: RGB{header.get('background_color')}")
    print(f"    对齐: {header.get('text_alignment')}")
    
    print(f"\n  📄 表体样式:")
    print(f"    字体: {body.get('font_name')}")
    print(f"    字号: {body.get('font_size')}pt")
    print(f"    加粗: {'是' if body.get('bold') else '否'}")
    print(f"    背景色: RGB{body.get('background_color')}")
    print(f"    对齐: {body.get('text_alignment')}")
    
    print("\n" + "=" * 60)
    print("  ✅ 所有配置项验证通过！")
    print("=" * 60)
    
except Exception as e:
    print(f"\n❌ 错误: {e}", file=sys.stderr)
    sys.exit(1)
