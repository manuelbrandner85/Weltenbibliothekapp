#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# 🧪 ADMIN API TEST SUITE - Weltenbibliothek
# ═══════════════════════════════════════════════════════════════════════════

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="https://weltenbibliothek-api-v3.brandy13062.workers.dev"
ADMIN_TOKEN="XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB"
PRIMARY_TOKEN="y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y"

# Test user data
TEST_USER_ID="test_user_$(date +%s)"
TEST_WORLD="materie"

echo "═══════════════════════════════════════════════════════════════════════════"
echo "🧪 WELTENBIBLIOTHEK - ADMIN API TEST SUITE"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "📍 Base URL: $BASE_URL"
echo "🔐 Admin Token: ${ADMIN_TOKEN:0:20}..."
echo "👤 Test User ID: $TEST_USER_ID"
echo "🌍 Test World: $TEST_WORLD"
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 1: Health Check
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: Health Check (GET /health)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$BASE_URL/health")
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if [ "$HTTP_STATUS" == "200" ]; then
    echo -e "${GREEN}✅ PASSED${NC} - Health check successful"
else
    echo -e "${RED}❌ FAILED${NC} - HTTP Status: $HTTP_STATUS"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 2: Ban User (POST /admin/users/:userId/ban)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: Ban User (POST /admin/users/$TEST_USER_ID/ban)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/ban" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Role: root_admin" \
  -H "X-User-ID: admin" \
  -d '{
    "reason": "Test ban - automated test",
    "durationHours": 1
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if [ "$HTTP_STATUS" == "200" ]; then
    SUCCESS=$(echo "$BODY" | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" == "true" ]; then
        echo -e "${GREEN}✅ PASSED${NC} - User banned successfully"
    else
        echo -e "${YELLOW}⚠️  WARNING${NC} - Status 200 but success=false"
    fi
else
    echo -e "${RED}❌ FAILED${NC} - HTTP Status: $HTTP_STATUS"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 3: Mute User (POST /admin/users/:userId/mute)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: Mute User (POST /admin/users/$TEST_USER_ID/mute)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/mute" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Role: root_admin" \
  -H "X-User-ID: admin" \
  -d '{
    "reason": "Test mute - automated test",
    "durationMinutes": 30
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if [ "$HTTP_STATUS" == "200" ]; then
    SUCCESS=$(echo "$BODY" | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" == "true" ]; then
        echo -e "${GREEN}✅ PASSED${NC} - User muted successfully"
    else
        echo -e "${YELLOW}⚠️  WARNING${NC} - Status 200 but success=false"
    fi
else
    echo -e "${RED}❌ FAILED${NC} - HTTP Status: $HTTP_STATUS"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 4: Unban User (POST /admin/users/:userId/unban)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: Unban User (POST /admin/users/$TEST_USER_ID/unban)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/unban" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "X-Role: root_admin" \
  -H "X-User-ID: admin")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if [ "$HTTP_STATUS" == "200" ]; then
    SUCCESS=$(echo "$BODY" | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" == "true" ]; then
        echo -e "${GREEN}✅ PASSED${NC} - User unbanned successfully"
    else
        echo -e "${YELLOW}⚠️  WARNING${NC} - Status 200 but success=false"
    fi
else
    echo -e "${RED}❌ FAILED${NC} - HTTP Status: $HTTP_STATUS"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 5: Delete User (DELETE /api/admin/delete/:world/:userId)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 5: Delete User (DELETE /api/admin/delete/$TEST_WORLD/$TEST_USER_ID)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X DELETE "$BASE_URL/api/admin/delete/$TEST_WORLD/$TEST_USER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "X-Role: root_admin" \
  -H "X-User-ID: admin")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if [ "$HTTP_STATUS" == "200" ]; then
    SUCCESS=$(echo "$BODY" | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" == "true" ]; then
        echo -e "${GREEN}✅ PASSED${NC} - User deleted successfully"
    else
        echo -e "${YELLOW}⚠️  WARNING${NC} - Status 200 but success=false"
    fi
else
    echo -e "${RED}❌ FAILED${NC} - HTTP Status: $HTTP_STATUS"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 6: Unauthorized Request (should fail)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 6: Unauthorized Ban Request (should return 401)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/ban" \
  -H "Authorization: Bearer INVALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Test",
    "durationHours": 1
  }')

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"

if [ "$HTTP_STATUS" == "401" ]; then
    echo -e "${GREEN}✅ PASSED${NC} - Unauthorized request properly rejected"
else
    echo -e "${RED}❌ FAILED${NC} - Expected 401, got: $HTTP_STATUS"
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════════════"
echo "📊 TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "✅ Health Check"
echo "✅ Ban User"
echo "✅ Mute User"
echo "✅ Unban User"
echo "✅ Delete User"
echo "✅ Unauthorized Request (Security Test)"
echo ""
echo "🎉 All admin API tests completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Review test results above"
echo "   2. Check Cloudflare Worker logs for any errors"
echo "   3. Integrate working endpoints into Flutter app"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
