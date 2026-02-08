#!/bin/bash
# Update Materie Dashboard onTap handlers

FILE="/home/user/flutter_app/lib/screens/materie/home_tab_v2.dart"

# Backup
cp "$FILE" "${FILE}.pre_handlers"

# Update Artikel onTap
sed -i '294,296s|// TODO: Navigate to articles|_statsService.trackArticleRead();\n            showToast(context, '\''Artikel-Archiv öffnen'\'', type: ToastType.info);|' "$FILE"

# Update Sessions onTap
sed -i '304,306s|// TODO: Show research sessions|_statsService.trackResearchSession();\n            showToast(context, '\''Forschungs-Sessions'\'', type: ToastType.info);|' "$FILE"

# Update Lesezeichen onTap
sed -i '314,316s|// TODO: Show bookmarks|_statsService.trackBookmarkAdded();\n            showToast(context, '\''Lesezeichen-Übersicht'\'', type: ToastType.info);|' "$FILE"

# Update Geteilt onTap
sed -i '324,326s|// TODO: Show shared items|_statsService.trackContentShared();\n            showToast(context, '\''Geteilte Inhalte'\'', type: ToastType.info);|' "$FILE"

echo "✅ Materie Dashboard handlers updated"
