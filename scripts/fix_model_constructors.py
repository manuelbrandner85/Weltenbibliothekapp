#!/usr/bin/env python3
"""
Fix all model classes in tool widgets to include username in constructor
"""
import re

TOOLS = [
    "lib/widgets/productive_tools/energie_tool.dart",
    "lib/widgets/productive_tools/weisheit_tool.dart",
    "lib/widgets/productive_tools/heilung_tool.dart",
    "lib/widgets/productive_tools/traumanalyse_tool.dart",
]

BASE_DIR = "/home/user/flutter_app"

for tool_path in TOOLS:
    import os
    full_path = os.path.join(BASE_DIR, tool_path)
    
    if not os.path.exists(full_path):
        print(f"⚠️  File not found: {tool_path}")
        continue
    
    with open(full_path, 'r') as f:
        lines = f.readlines()
    
    # Find all fields that include username
    # Example: final String id, name, username, category;
    #          final String id, name, timestamp, username;
    
    # We need to find constructor blocks and add username
    in_constructor = False
    class_name = None
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Detect class with username in fields
        if re.search(r'class\s+(\w+)\s+{', line):
            # Check if next lines contain username field
            for j in range(i+1, min(i+10, len(lines))):
                if ', username' in lines[j] or 'username,' in lines[j]:
                    class_name = re.search(r'class\s+(\w+)\s+{', line).group(1)
                    break
        
        # Detect constructor start
        if class_name and re.search(rf'\s+{class_name}\(\{{', line):
            in_constructor = True
            fixed_lines.append(line)
            
            # Collect all constructor parameters
            params = []
            j = i + 1
            while j < len(lines) and not re.search(r'^\s*\}\);', lines[j]):
                param_line = lines[j]
                if 'required this.' in param_line:
                    param_match = re.search(r'required this\.(\w+)', param_line)
                    if param_match:
                        params.append(param_match.group(1))
                j += 1
            
            # Check if username is missing from constructor
            if 'username' not in params:
                # Add constructor parameters with username
                k = i + 1
                while k < len(lines) and not re.search(r'^\s*\}\);', lines[k]):
                    param_line = lines[k]
                    fixed_lines.append(param_line)
                    
                    # Insert username after id (or first parameter)
                    if 'required this.id,' in param_line:
                        # Check if next line is not username
                        if k+1 < len(lines) and 'required this.username,' not in lines[k+1]:
                            fixed_lines.append('    required this.username,\n')
                    k += 1
                
                # Add closing
                fixed_lines.append(lines[k])
                i = k + 1
                class_name = None
                continue
        
        fixed_lines.append(line)
        i += 1
    
    with open(full_path, 'w') as f:
        f.writelines(fixed_lines)
    
    print(f"✅ Fixed: {tool_path}")

print("\n✅ All model constructors fixed")
