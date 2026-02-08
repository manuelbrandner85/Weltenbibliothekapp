#!/bin/bash

# Script to add 'username' parameter to all Tool widgets

TOOLS=(
  "lib/widgets/productive_tools/session_tool.dart"
  "lib/widgets/productive_tools/traumanalyse_tool.dart"
  "lib/widgets/productive_tools/energie_tool.dart"
  "lib/widgets/productive_tools/weisheit_tool.dart"
  "lib/widgets/productive_tools/heilung_tool.dart"
  "lib/widgets/productive_tools/debattenkarte_tool.dart"
  "lib/widgets/productive_tools/zeitleiste_tool.dart"
  "lib/widgets/productive_tools/sichtungskarte_tool.dart"
  "lib/widgets/productive_tools/recherche_tool.dart"
  "lib/widgets/productive_tools/experiment_tool.dart"
)

cd /home/user/flutter_app

for TOOL in "${TOOLS[@]}"; do
  if [ -f "$TOOL" ]; then
    echo "Processing: $TOOL"
    
    # Add username parameter to constructor if not exists
    if ! grep -q "required this.username" "$TOOL"; then
      # Find the line with "required this.roomId"
      sed -i '/required this.roomId/a\    required this.username,' "$TOOL"
    fi
    
    # Add final String username field if not exists
    if ! grep -q "final String username;" "$TOOL"; then
      # Add after "final String roomId;"
      sed -i '/final String roomId;/a\  final String username;' "$TOOL"
    fi
    
    echo "✅ Updated: $TOOL"
  else
    echo "⚠️  File not found: $TOOL"
  fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "✅ All tools updated with username parameter"
echo "═══════════════════════════════════════════"
