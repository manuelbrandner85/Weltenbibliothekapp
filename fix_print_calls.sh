#!/bin/bash
echo "🔧 Fixing print() → debugPrint() calls..."

# Backup files
cp lib/screens/materie/materie_live_chat_screen.dart lib/screens/materie/materie_live_chat_screen.dart.backup
cp lib/screens/energie/energie_live_chat_screen.dart lib/screens/energie/energie_live_chat_screen.dart.backup

# Replace print( with debugPrint( (only standalone print, not within strings)
find lib -name "*_live_chat_screen.dart" -exec sed -i 's/\bprint(/debugPrint(/g' {} \;

echo "✅ print() → debugPrint() replacement done"
echo "Files modified:"
find lib -name "*_live_chat_screen.dart" | wc -l
