#!/usr/bin/env python3
"""
Responsive Design Migration Helper
Automatisches Ersetzen von hardcoded Werten durch responsive Utilities
"""

import os
import re
from pathlib import Path

# Migration-Regeln
REPLACEMENTS = [
    # SizedBox height/width
    (r'const SizedBox\(height:\s*(\d+)\)', lambda m: f'context.vSpace({int(m.group(1))/12:.1f})'),
    (r'const SizedBox\(width:\s*(\d+)\)', lambda m: f'context.hSpace({int(m.group(1))/12:.1f})'),
    (r'SizedBox\(height:\s*(\d+)\)', lambda m: f'context.vSpace({int(m.group(1))/12:.1f})'),
    (r'SizedBox\(width:\s*(\d+)\)', lambda m: f'context.hSpace({int(m.group(1))/12:.1f})'),
    
    # EdgeInsets.all
    (r'const EdgeInsets\.all\((\d+)\)', lambda m: _map_padding(int(m.group(1)))),
    (r'EdgeInsets\.all\((\d+)\)', lambda m: _map_padding(int(m.group(1)))),
    
    # BorderRadius.circular
    (r'BorderRadius\.circular\((\d+)\)', lambda m: _map_border_radius(int(m.group(1)))),
]

def _map_padding(value):
    """Map padding value to responsive constant"""
    if value <= 6:
        return 'context.paddingXs'
    elif value <= 10:
        return 'context.paddingSm'
    elif value <= 14:
        return 'context.paddingMd'
    elif value <= 20:
        return 'context.paddingLg'
    else:
        return 'context.paddingXl'

def _map_border_radius(value):
    """Map border radius to responsive constant"""
    if value <= 8:
        return f'BorderRadius.circular(context.responsive.borderRadiusSm)'
    elif value <= 14:
        return f'BorderRadius.circular(context.responsive.borderRadiusMd)'
    else:
        return f'BorderRadius.circular(context.responsive.borderRadiusLg)'

def needs_import(content):
    """Check if file needs responsive imports"""
    has_context_responsive = 'context.responsive' in content or 'context.textStyles' in content
    has_import = 'import \'../utils/responsive_utils.dart\'' in content
    return has_context_responsive and not has_import

def add_imports(content):
    """Add responsive imports to file"""
    import_block = """import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

"""
    
    # Find first import statement
    import_pattern = r'import [\'"].*?[\'"];'
    match = re.search(import_pattern, content)
    
    if match:
        # Insert after the first import
        insert_pos = match.end()
        return content[:insert_pos] + '\n' + import_block + content[insert_pos:]
    
    return import_block + content

def migrate_file(file_path):
    """Migrate a single Dart file to responsive design"""
    print(f"📝 Processing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    changes_made = False
    
    # Apply replacements
    for pattern, replacement in REPLACEMENTS:
        if callable(replacement):
            new_content = re.sub(pattern, replacement, content)
        else:
            new_content = re.sub(pattern, replacement, content)
        
        if new_content != content:
            changes_made = True
            content = new_content
    
    # Add imports if needed
    if changes_made and needs_import(content):
        content = add_imports(content)
    
    # Write back if changes were made
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"   ✅ Updated: {file_path}")
        return True
    else:
        print(f"   ⏭️  No changes needed: {file_path}")
        return False

def migrate_directory(directory, pattern='**/*.dart'):
    """Migrate all Dart files in directory"""
    path = Path(directory)
    dart_files = list(path.glob(pattern))
    
    print(f"🔍 Found {len(dart_files)} Dart files in {directory}")
    print(f"{'='*60}\n")
    
    updated_count = 0
    
    for file_path in dart_files:
        # Skip generated files
        if any(skip in str(file_path) for skip in ['.g.dart', '.freezed.dart', 'generated']):
            continue
        
        if migrate_file(file_path):
            updated_count += 1
    
    print(f"\n{'='*60}")
    print(f"✅ Migration complete!")
    print(f"📊 Updated {updated_count} out of {len(dart_files)} files")

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        target = 'lib'
    
    print("""
╔═══════════════════════════════════════════════════════════╗
║  RESPONSIVE DESIGN MIGRATION HELPER                       ║
║  Weltenbibliothek - Automatic Migration Script            ║
╚═══════════════════════════════════════════════════════════╝

⚠️  This script will modify Dart files in place!
📝 Make sure you have committed your changes before running.

""")
    
    response = input("Continue? (y/n): ")
    
    if response.lower() == 'y':
        migrate_directory(target)
    else:
        print("❌ Migration cancelled.")
