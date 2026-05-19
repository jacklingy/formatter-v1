import os
import sys
from config_manager import ConfigManager

def test_config_persistence():
    print("=" * 70)
    print("  配置文件持久化测试")
    print("=" * 70)
    
    config_path = 'format_config.yaml'
    
    if not os.path.exists(config_path):
        print(f"\n❌ 配置文件不存在: {config_path}")
        return False
    
    print(f"\n📂 配置文件路径: {os.path.abspath(config_path)}")
    
    print("\n" + "-" * 70)
    print("  测试 1: 首次加载配置")
    print("-" * 70)
    
    config1 = ConfigManager()
    original_font = config1.get_heading_style(1).get('font_name', '')
    print(f"\n✅ 首次加载成功")
    print(f"   标题1 字体: {original_font}")
    
    print("\n" + "-" * 70)
    print("  测试 2: 模拟用户修改配置")
    print("-" * 70)
    
    import yaml
    with open(config_path, 'r', encoding='utf-8') as f:
        config_data = yaml.safe_load(f)
    
    test_value = "测试字体_临时修改"
    config_data['heading_styles']['heading1']['font_name'] = test_value
    
    with open(config_path, 'w', encoding='utf-8') as f:
        yaml.dump(config_data, f, allow_unicode=True, default_flow_style=False, sort_keys=False)
    
    print(f"\n✅ 已修改配置: 标题1字体 → '{test_value}'")
    
    print("\n" + "-" * 70)
    print("  测试 3: 重新加载配置（模拟重启程序）")
    print("-" * 70)
    
    config2 = ConfigManager()
    reloaded_font = config2.get_heading_style(1).get('font_name', '')
    
    print(f"\n✅ 重新加载成功")
    print(f"   标题1 字体: {reloaded_font}")
    
    if reloaded_font == test_value:
        print("\n🎉 成功！配置修改已持久保存")
        persistence_result = True
    else:
        print(f"\n❌ 失败！期望: '{test_value}', 实际: '{reloaded_font}'")
        persistence_result = False
    
    print("\n" + "-" * 70)
    print("  测试 4: 恢复原始配置")
    print("-" * 70)
    
    with open(config_path, 'r', encoding='utf-8') as f:
        config_data = yaml.safe_load(f)
    
    config_data['heading_styles']['heading1']['font_name'] = original_font
    
    with open(config_path, 'w', encoding='utf-8') as f:
        yaml.dump(config_data, f, allow_unicode=True, default_flow_style=False, sort_keys=False)
    
    print(f"\n✅ 已恢复原始配置: 标题1字体 → '{original_font}'")
    
    config3 = ConfigManager()
    final_font = config3.get_heading_style(1).get('font_name', '')
    
    if final_font == original_font:
        print("✅ 验证恢复成功")
    else:
        print(f"⚠️ 恢复验证失败: '{final_font}'")
    
    print("\n" + "=" * 70)
    if persistence_result:
        print("  ✅ 配置持久化测试通过！")
    else:
        print("  ❌ 配置持久化测试失败！")
    print("=" * 70)
    
    return persistence_result

if __name__ == '__main__':
    success = test_config_persistence()
    exit(0 if success else 1)
