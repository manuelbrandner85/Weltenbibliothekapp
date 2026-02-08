#!/bin/bash

echo "=== 🧪 API CONNECTION TESTS ==="
echo ""

# Test API-V2 Profile Endpoint
echo "1️⃣  Testing Profile API (weltenbibliothek-api-v2)..."
response=$(curl -s -w "\n%{http_code}" -X POST \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/profile/materie \
  -H "Content-Type: application/json" \
  -d '{"username":"test_user","name":"Test","avatar_url":"","avatar_emoji":"🧪","bio":"API Test"}' \
  2>/dev/null)
http_code=$(echo "$response" | tail -1)
if [ "$http_code" = "200" ]; then
  echo "   ✅ Profile API: Working ($http_code)"
else
  echo "   ⚠️  Profile API: $http_code"
fi
echo ""

# Test Admin Check Endpoint
echo "2️⃣  Testing Admin Check API..."
response=$(curl -s -w "\n%{http_code}" \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/admin/check/materie/Weltenbibliothek \
  2>/dev/null)
http_code=$(echo "$response" | tail -1)
if [ "$http_code" = "200" ]; then
  echo "   ✅ Admin Check: Working ($http_code)"
  body=$(echo "$response" | head -n -1)
  echo "   Response: $(echo $body | jq -c '.' 2>/dev/null || echo $body | head -c 80)"
else
  echo "   ⚠️  Admin Check: $http_code"
fi
echo ""

# Test Backend Health
echo "3️⃣  Testing Backend Health API..."
response=$(curl -s -w "\n%{http_code}" \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/health \
  2>/dev/null)
http_code=$(echo "$response" | tail -1)
if [ "$http_code" = "200" ]; then
  echo "   ✅ Health API: Working ($http_code)"
else
  echo "   ⚠️  Health API: $http_code"
fi
echo ""

# Test Leaderboard Backend
echo "4️⃣  Testing Leaderboard Backend..."
response=$(curl -s -w "\n%{http_code}" \
  https://api-backend.brandy13062.workers.dev/health \
  2>/dev/null)
http_code=$(echo "$response" | tail -1)
if [ "$http_code" = "200" ]; then
  echo "   ✅ Leaderboard Backend: Working ($http_code)"
else
  echo "   ⚠️  Leaderboard Backend: $http_code"
fi
echo ""

# Test Group Tools (Community API Fallback)
echo "5️⃣  Testing Group Tools (Community API)..."
response=$(curl -s -w "\n%{http_code}" \
  https://weltenbibliothek-community-api.brandy13062.workers.dev/health \
  2>/dev/null)
http_code=$(echo "$response" | tail -1)
if [ "$http_code" = "200" ]; then
  echo "   ✅ Group Tools (Community): Working ($http_code)"
else
  echo "   ⚠️  Group Tools: $http_code"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ API Connection Tests Complete"

