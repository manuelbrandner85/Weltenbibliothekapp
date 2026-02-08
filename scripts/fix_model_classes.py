#!/usr/bin/env python3
"""
Fix all model classes in tool widgets - add missing constructors
"""
import re
import os

TOOLS = {
    "lib/widgets/productive_tools/energie_tool.dart": "EnergieReading",
    "lib/widgets/productive_tools/weisheit_tool.dart": "Weisheit",
    "lib/widgets/productive_tools/heilung_tool.dart": "HeilProtokoll",
}

BASE_DIR = "/home/user/flutter_app"

def fix_model_class(file_path, class_name):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Find the class definition
    class_pattern = rf'class {class_name} \{{[^}}]*?final[^}}]*?factory {class_name}\.fromJson'
    match = re.search(class_pattern, content, re.DOTALL)
    
    if not match:
        print(f"⚠️  Could not find class {class_name} in {file_path}")
        return False
    
    class_block = match.group(0)
    
    # Extract fields
    field_pattern = r'final\s+(?:String|int|Map<[^>]+>|DateTime|List<[^>]+>)\s+([^;]+);'
    fields = []
    for field_match in re.finditer(field_pattern, class_block):
        field_line = field_match.group(1)
        # Handle multiple fields on one line: "id, username"
        for field in field_line.split(','):
            field = field.strip()
            if field and not field.startswith('_'):
                fields.append(field)
    
    if not fields:
        print(f"⚠️  No fields found for {class_name}")
        return False
    
    # Create constructor
    constructor = f"  {class_name}({{\n"
    for field in fields:
        constructor += f"    required this.{field},\n"
    constructor += "  });\n\n"
    
    # Find where to insert constructor (after fields, before factory)
    insert_pattern = rf'(class {class_name} \{{[^}}]*?final[^;]+;\s*)\n(\s*factory {class_name}\.fromJson)'
    
    replacement = rf'\1\n{constructor}\2'
    new_content = re.sub(insert_pattern, replacement, content, flags=re.DOTALL)
    
    if new_content == content:
        print(f"⚠️  Could not insert constructor for {class_name}")
        return False
    
    with open(file_path, 'w') as f:
        f.write(new_content)
    
    print(f"✅ Fixed {class_name} in {os.path.basename(file_path)}")
    return True

for file_path, class_name in TOOLS.items():
    full_path = os.path.join(BASE_DIR, file_path)
    if os.path.exists(full_path):
        fix_model_class(full_path, class_name)
    else:
        print(f"⚠️  File not found: {file_path}")

print("\n✅ All model classes fixed")
