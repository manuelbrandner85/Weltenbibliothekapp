#!/usr/bin/env python3
"""
Empty Catch Block Fixer
Fügt debugPrint logging zu allen empty catch blocks hinzu
"""

import re
from pathlib import Path

# Files mit empty catch blocks
FILES_TO_FIX = [
    "lib/widgets/inline_tools/collaborative_news_board.dart",  # 2 catches
    "lib/widgets/inline_tools/connections_board_enhanced.dart",
    "lib/widgets/inline_tools/group_meditation_widget.dart",  # 2 catches
    "lib/widgets/inline_tools/heilfrequenz_player_enhanced.dart",
    "lib/widgets/inline_tools/news_board_enhanced.dart",
    "lib/widgets/inline_tools/patent_archiv_enhanced.dart",
    "lib/widgets/inline_tools/traum_tagebuch_enhanced.dart",
    "lib/widgets/productive_tools/sichtungskarte_tool.dart",
    "lib/widgets/productive_tools/zeitleiste_tool.dart",
]

def fix_empty_catch_blocks(file_path):
    """Fix empty catch blocks in a file"""
    path = Path(file_path)
    
    if not path.exists():
        print(f"❌ File not found: {file_path}")
        return False
    
    try:
        content = path.read_text(encoding='utf-8')
        original_content = content
        
        # Check if debugPrint is already imported
        has_debug_import = 'kDebugMode' in content and 'debugPrint' in content
        
        # Add import if needed
        if not has_debug_import:
            # Find first import and add after it
            import_match = re.search(r"(import ['\"].*?['\"];)", content)
            if import_match:
                insert_pos = import_match.end()
                import_line = "\nimport 'package:flutter/foundation.dart' show kDebugMode, debugPrint;"
                content = content[:insert_pos] + import_line + content[insert_pos:]
        
        # Pattern to find empty catch blocks: } catch (e) {}
        # Replace with logging version
        widget_name = path.stem.replace('_', ' ').title().replace(' ', '')
        
        # Pattern 1: catch (e) {}
        pattern1 = r'(\s+)catch\s*\((\w+)\)\s*\{\s*\}'
        replacement1 = r'\1catch (\2) {\n\1  if (kDebugMode) {\n\1    debugPrint(\'⚠️ ' + widget_name + r': Error - $\2\');\n\1  }\n\1  // Silently fail - widget remains functional\n\1}'
        content = re.sub(pattern1, replacement1, content)
        
        # Pattern 2: catch (e, stackTrace) {}
        pattern2 = r'(\s+)catch\s*\((\w+),\s*(\w+)\)\s*\{\s*\}'
        replacement2 = r'\1catch (\2, \3) {\n\1  if (kDebugMode) {\n\1    debugPrint(\'⚠️ ' + widget_name + r': Error - $\2\');\n\1    debugPrint(\'Stack: $\3\');\n\1  }\n\1  // Silently fail - widget remains functional\n\1}'
        content = re.sub(pattern2, replacement2, content)
        
        # Write back if changes were made
        if content != original_content:
            path.write_text(content, encoding='utf-8')
            print(f"✅ Fixed: {file_path}")
            return True
        else:
            print(f"⏭️  No changes needed: {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    print("🔧 EMPTY CATCH BLOCK FIXER")
    print("=" * 60)
    
    fixed_count = 0
    
    for file_path in FILES_TO_FIX:
        if fix_empty_catch_blocks(file_path):
            fixed_count += 1
    
    print("=" * 60)
    print(f"✅ Fixed {fixed_count}/{len(FILES_TO_FIX)} files")

if __name__ == '__main__':
    main()
