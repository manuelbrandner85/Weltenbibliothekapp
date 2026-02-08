#!/usr/bin/env python3
"""
Korrigiert Enum-Zugriff in Community-Tabs
"""

import re

# MATERIE Community
with open('/home/user/flutter_app/lib/screens/materie/materie_community_tab.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: quellentyp.toUpperCase() -> quellenTypLabel
content = re.sub(
    r'feed\.quellentyp\.toUpperCase\(\)',
    'feed.quellenTypLabel',
    content
)

# Fix 2: _getTypeIcon(feed.quellentyp) -> _getTypeIcon(feed.quellenTypLabel)
content = re.sub(
    r'_getTypeIcon\(feed\.quellentyp\)',
    '_getTypeIcon(feed.quellenTypLabel)',
    content
)

# Fix 3: updateType == 'neu' -> updateType == UpdateType.neu
content = re.sub(
    r"feed\.updateType == 'neu'",
    'feed.updateType == UpdateType.neu',
    content
)

# Füge Import hinzu
if '../../models/live_feed_entry.dart' not in content:
    content = content.replace(
        "import '../../models/community_post.dart';",
        "import '../../models/community_post.dart';\nimport '../../models/live_feed_entry.dart';"
    )

with open('/home/user/flutter_app/lib/screens/materie/materie_community_tab.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ MATERIE Community Enum-Zugriff korrigiert")

# ENERGIE Community
with open('/home/user/flutter_app/lib/screens/energie/energie_community_tab.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: quellentyp.toUpperCase() -> quellenTypLabel
content = re.sub(
    r'feed\.quellentyp\.toUpperCase\(\)',
    'feed.quellenTypLabel',
    content
)

# Fix 2: _getTypeIcon(feed.quellentyp) -> _getTypeIcon(feed.quellenTypLabel)
content = re.sub(
    r'_getTypeIcon\(feed\.quellentyp\)',
    '_getTypeIcon(feed.quellenTypLabel)',
    content
)

# Fix 3: updateType == 'neu' -> updateType == UpdateType.neu
content = re.sub(
    r"feed\.updateType == 'neu'",
    'feed.updateType == UpdateType.neu',
    content
)

# Füge Import hinzu falls fehlt
if '../../models/live_feed_entry.dart' not in content:
    content = content.replace(
        "import '../../models/community_post.dart';",
        "import '../../models/community_post.dart';\nimport '../../models/live_feed_entry.dart';"
    )

with open('/home/user/flutter_app/lib/screens/energie/energie_community_tab.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ ENERGIE Community Enum-Zugriff korrigiert")
