#!/bin/bash

echo "=== 🔥 KRITISCHE BACKEND-SERVICES ANALYSE ==="
echo ""

# 1. Profile Sync Service - API-Endpunkt prüfen
echo "👤 1. PROFILE-SYNC SERVICE:"
echo "   Datei: lib/services/profile_sync_service.dart"
grep -A 2 "baseUrl\|String.*url" lib/services/profile_sync_service.dart | head -6
echo ""

# 2. Community Service - Haupt-API
echo "💬 2. COMMUNITY SERVICE:"
echo "   Datei: lib/services/community_service.dart"
grep -A 2 "baseUrl\|_apiUrl" lib/services/community_service.dart | head -6
echo ""

# 3. Cloudflare API Service - Zentrale API
echo "🌐 3. CLOUDFLARE API SERVICE:"
echo "   Datei: lib/services/cloudflare_api_service.dart"
grep -A 2 "baseUrl\|apiUrl" lib/services/cloudflare_api_service.dart | head -6
echo ""

# 4. Leaderboard Service
echo "🏆 4. LEADERBOARD SERVICE:"
echo "   Datei: lib/services/leaderboard_service.dart"
grep -A 2 "baseUrl\|apiUrl" lib/services/leaderboard_service.dart | head -6
echo ""

# 5. Chat Tools Service
echo "💭 5. CHAT TOOLS SERVICE:"
echo "   Datei: lib/services/chat_tools_service.dart"
grep -A 2 "baseUrl\|apiUrl" lib/services/chat_tools_service.dart | head -6
echo ""

# 6. Backend Health Service
echo "🏥 6. BACKEND HEALTH SERVICE:"
echo "   Datei: lib/services/backend_health_service.dart"
grep -A 2 "baseUrl\|apiUrl" lib/services/backend_health_service.dart | head -6
echo ""

# 7. Recherche Service
echo "🔍 7. RECHERCHE SERVICE:"
echo "   Datei: lib/services/recherche_service.dart"
grep -A 2 "baseUrl\|apiUrl" lib/services/recherche_service.dart | head -6
echo ""

# 8. Tool API Service
echo "🛠️ 8. TOOL API SERVICE:"
echo "   Datei: lib/services/tool_api_service.dart"
grep -A 2 "baseUrl\|apiUrl" lib/services/tool_api_service.dart | head -6
echo ""

