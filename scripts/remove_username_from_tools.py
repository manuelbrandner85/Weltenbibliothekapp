#!/usr/bin/env python3
"""
Remove username parameter from all tools temporarily
We'll add proper backend integration step by step later
"""
import re
import os

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
    
    # Remove ", required this.username" from constructors
    content = re.sub(r',\s*required this\.username', '', content)
    
    # Remove "final String username;" field declarations
    content = re.sub(r'\s*final String username;\n', '', content)
    
    with open(full_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Removed username from: {tool_path}")

print("\n✅ All tools reverted - username parameter removed")
print("💡 Tools can be enhanced with backend integration later")
