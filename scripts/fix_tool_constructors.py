#!/usr/bin/env python3
import re
import os

# Tools to update
TOOLS = [
    "lib/widgets/productive_tools/session_tool.dart",
    "lib/widgets/productive_tools/traumanalyse_tool.dart",
    "lib/widgets/productive_tools/energie_tool.dart",
    "lib/widgets/productive_tools/weisheit_tool.dart",
    "lib/widgets/productive_tools/heilung_tool.dart",
    "lib/widgets/productive_tools/debattenkarte_tool.dart",
    "lib/widgets/productive_tools/zeitleiste_tool.dart",
    "lib/widgets/productive_tools/sichtungskarte_tool.dart",
    "lib/widgets/productive_tools/recherche_tool.dart",
    "lib/widgets/productive_tools/experiment_tool.dart",
]

BASE_DIR = "/home/user/flutter_app"

for tool_path in TOOLS:
    full_path = os.path.join(BASE_DIR, tool_path)
    
    if not os.path.exists(full_path):
        print(f"⚠️  File not found: {tool_path}")
        continue
    
    with open(full_path, 'r') as f:
        content = f.read()
    
    # Pattern 1: Fix constructor with required parameters
    # Before: const SessionTool({Key? key, required this.roomId}) : super(key: key);
    # After:  const SessionTool({Key? key, required this.roomId, required this.username}) : super(key: key);
    
    pattern = r'(\s+const\s+\w+\({[^}]*required this\.roomId)(\}?\))'
    replacement = r'\1, required this.username\2'
    content = re.sub(pattern, replacement, content)
    
    # Pattern 2: Make sure username field exists after roomId
    if 'final String username;' not in content:
        # Find "final String roomId;" and add username after it
        content = re.sub(
            r'(final String roomId;)',
            r'\1\n  final String username;',
            content
        )
    
    # Remove duplicate username declarations (if sed added incorrectly)
    lines = content.split('\n')
    seen_username = False
    cleaned_lines = []
    
    for line in lines:
        # Skip malformed username lines from sed
        if 'required this.username,' in line and 'const ' not in line:
            continue
        
        # Skip duplicate username field declarations
        if 'final String username;' in line:
            if not seen_username:
                seen_username = True
                cleaned_lines.append(line)
        else:
            cleaned_lines.append(line)
    
    content = '\n'.join(cleaned_lines)
    
    with open(full_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Fixed: {tool_path}")

print("\n═══════════════════════════════════════════")
print("✅ All tools fixed with proper username parameter")
print("═══════════════════════════════════════════")
