#!/usr/bin/env python3
"""
Automatic Unused Import Remover
Entfernt unused imports basierend auf Flutter analyze Output
"""

import re
import sys

# Unused imports aus flutter_warnings.txt
UNUSED_IMPORTS = [
    ("lib/screens/energie/energie_community_tab.dart", 12, "../../services/user_service.dart"),
    ("lib/screens/energie/moon_journal_screen.dart", 5, "package:weltenbibliothek/services/storage_service.dart"),
    ("lib/screens/energie/spirit_tab_cloudflare.dart", 2, "../../services/cloudflare_api_service.dart"),
    ("lib/screens/energie_world_wrapper.dart", 2, "../models/energie_profile.dart"),
    ("lib/screens/energie_world_wrapper.dart", 3, "../services/storage_service.dart"),
    ("lib/screens/materie/enhanced_recherche_tab.dart", 19, "../../services/recherche_timeout_handler.dart"),
    ("lib/screens/materie/materie_research_screen.dart", 2, "../../services/cloudflare_api_service.dart"),
]

def remove_import_line(file_path, line_number, import_path):
    """Remove specific import line from file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Check if line exists and contains the import
        if line_number > 0 and line_number <= len(lines):
            line = lines[line_number - 1]
            if import_path in line and 'import' in line:
                # Remove the line
                lines.pop(line_number - 1)
                
                # Write back
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                
                print(f"✅ Removed: {file_path}:{line_number} - {import_path}")
                return True
            else:
                print(f"⏭️  Skipped: {file_path}:{line_number} - Line content doesn't match")
                return False
        else:
            print(f"⚠️  Invalid line number: {file_path}:{line_number}")
            return False
            
    except FileNotFoundError:
        print(f"❌ File not found: {file_path}")
        return False
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    print("🧹 UNUSED IMPORT REMOVER")
    print("=" * 60)
    
    removed_count = 0
    
    for file_path, line_num, import_path in UNUSED_IMPORTS:
        if remove_import_line(file_path, line_num, import_path):
            removed_count += 1
    
    print("=" * 60)
    print(f"✅ Removed {removed_count}/{len(UNUSED_IMPORTS)} unused imports")

if __name__ == '__main__':
    main()
