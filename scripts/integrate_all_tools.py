#!/usr/bin/env python3
"""
Automatische Backend-Integration für alle Tools
"""
import os
import re

TOOLS = {
    "lib/widgets/productive_tools/traumanalyse_tool.dart": {
        "tool_type": "traumanalyse",
        "realm": "energie",
        "tool_name": "Traumanalyse",
    },
    "lib/widgets/productive_tools/energie_tool.dart": {
        "tool_type": "energie",
        "realm": "energie",
        "tool_name": "Energie-Tracking",
    },
    "lib/widgets/productive_tools/weisheit_tool.dart": {
        "tool_type": "weisheit",
        "realm": "energie",
        "tool_name": "Weisheit",
    },
    "lib/widgets/productive_tools/heilung_tool.dart": {
        "tool_type": "heilung",
        "realm": "energie",
        "tool_name": "Heilung",
    },
    "lib/widgets/productive_tools/debattenkarte_tool.dart": {
        "tool_type": "debatte",
        "realm": "materie",
        "tool_name": "Debatte",
    },
    "lib/widgets/productive_tools/zeitleiste_tool.dart": {
        "tool_type": "zeitleiste",
        "realm": "materie",
        "tool_name": "Zeitleiste",
    },
    "lib/widgets/productive_tools/sichtungskarte_tool.dart": {
        "tool_type": "sichtung",
        "realm": "materie",
        "tool_name": "UFO-Sichtung",
    },
    "lib/widgets/productive_tools/recherche_tool.dart": {
        "tool_type": "recherche",
        "realm": "materie",
        "tool_name": "Recherche",
    },
    "lib/widgets/productive_tools/experiment_tool.dart": {
        "tool_type": "experiment",
        "realm": "materie",
        "tool_name": "Experiment",
    },
}

BASE_DIR = "/home/user/flutter_app"

def integrate_tool(file_path, config):
    full_path = os.path.join(BASE_DIR, file_path)
    
    if not os.path.exists(full_path):
        print(f"⚠️  File not found: {file_path}")
        return False
    
    with open(full_path, 'r') as f:
        content = f.read()
    
    # 1. Add ChatToolsService import if not exists
    if 'chat_tools_service.dart' not in content:
        content = content.replace(
            "import '../../services/cloudflare_api_service.dart';",
            "import '../../services/cloudflare_api_service.dart';\nimport '../../services/chat_tools_service.dart';"
        )
    
    # 2. Add ChatToolsService instance if not exists
    if '_toolsService = ChatToolsService()' not in content:
        # Find CloudflareApiService line and add after it
        content = re.sub(
            r'(final CloudflareApiService _api = CloudflareApiService\(\);)',
            r'\1\n  final ChatToolsService _toolsService = ChatToolsService();',
            content
        )
    
    # 3. Fix baseUrl if wrong
    content = content.replace(
        'https://weltenbibliothek-api.brandy13062.workers.dev',
        'https://weltenbibliothek-community-api.brandy13062.workers.dev'
    )
    
    # 4. Remove old bearer token lines
    content = re.sub(r'\s*static const String _bearerToken = [^;]+;\n', '', content)
    
    with open(full_path, 'w') as f:
        f.write(content)
    
    print(f"✅ Integrated: {os.path.basename(file_path)}")
    return True

# Integrate all tools
success_count = 0
for file_path, config in TOOLS.items():
    if integrate_tool(file_path, config):
        success_count += 1

print(f"\n✅ {success_count}/{len(TOOLS)} tools integrated")
print("\n💡 Note: Load/Save methods need manual adjustment for each tool")
print("   See session_tool.dart for reference implementation")
