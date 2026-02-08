#!/bin/bash

echo "=== 🔍 BACKEND-ABHÄNGIGKEITS-ANALYSE ==="
echo ""

# 1. Services mit API-Calls finden
echo "📡 1. API-Services (HTTP-Calls):"
grep -r "http\." lib/services/*.dart 2>/dev/null | cut -d: -f1 | sort -u | while read file; do
  echo "  - $(basename $file)"
done
echo ""

# 2. Cloudflare Workers API-Endpunkte
echo "🌐 2. Cloudflare API-Endpunkte:"
grep -rh "https://.*workers\.dev\|https://.*brandy.*workers\.dev" lib/ 2>/dev/null | grep -o "https://[^'\"]*" | sort -u
echo ""

# 3. Firebase-bezogene Services
echo "🔥 3. Firebase-Services:"
grep -l "firebase\|firestore" lib/services/*.dart 2>/dev/null | while read file; do
  echo "  - $(basename $file)"
done
echo ""

# 4. Profile-Sync Services
echo "👤 4. Profile-Sync Services:"
grep -l "saveMaterieProfile\|saveEnergieProfile\|ProfileSyncService" lib/services/*.dart lib/screens/**/*.dart 2>/dev/null | sort -u | head -10
echo ""

# 5. Community/Chat Backend
echo "💬 5. Community/Chat Backend-Calls:"
grep -l "community.*post\|chat.*message\|LiveChatService" lib/services/*.dart lib/screens/**/*.dart 2>/dev/null | head -10
echo ""

# 6. Leaderboard/Stats Backend
echo "🏆 6. Leaderboard/Stats Backend:"
grep -l "leaderboard\|CloudflareLeaderboardApi" lib/services/*.dart 2>/dev/null
echo ""

# 7. Admin/Auth Services
echo "🔐 7. Admin/Auth Services:"
grep -l "admin\|auth\|token" lib/services/*.dart 2>/dev/null | head -10
echo ""

