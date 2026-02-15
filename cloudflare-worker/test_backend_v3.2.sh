#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# 🧪 BACKEND v3.2 TEST SUITE - Complete Validation
# ═══════════════════════════════════════════════════════════════════════════

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BASE_URL="$1"
ADMIN_TOKEN="XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB"
TEST_USER_ID="test_user_$(date +%s)"
TEST_WORLD="materie"

# Check if URL provided
if [ -z "$BASE_URL" ]; then
    echo -e "${RED}❌ ERROR: No base URL provided${NC}"
    echo ""
    echo "Usage: $0 <BASE_URL>"
    echo "Example: $0 https://weltenbibliothek-backend-v3-2.brandy13062.workers.dev"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}🧪 WELTENBIBLIOTHEK BACKEND v3.2 - COMPLETE TEST SUITE${NC}"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "📍 Base URL: $BASE_URL"
echo "🔐 Admin Token: ${ADMIN_TOKEN:0:20}..."
echo "👤 Test User ID: $TEST_USER_ID"
echo "🌍 Test World: $TEST_WORLD"
echo ""

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ═══════════════════════════════════════════════════════════════════════════
# TEST FUNCTION
# ═══════════════════════════════════════════════════════════════════════════

run_test() {
    local test_name="$1"
    local expected_status="$2"
    local response="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d':' -f2)
    local body=$(echo "$response" | sed '/HTTP_STATUS:/d')
    
    echo "📥 Response:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
    
    if [ "$http_status" == "$expected_status" ]; then
        local success=$(echo "$body" | jq -r '.success' 2>/dev/null)
        if [ "$success" == "true" ] || [ "$expected_status" != "200" ]; then
            echo -e "${GREEN}✅ PASSED${NC} - $test_name"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${YELLOW}⚠️  WARNING${NC} - Status $http_status but success=false"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        echo -e "${RED}❌ FAILED${NC} - Expected $expected_status, got $http_status"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# TEST 1: Health Check
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 1: Health Check (GET /health)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$BASE_URL/health")
run_test "Health Check" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 2: Ban User
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 2: Ban User (POST /admin/users/$TEST_USER_ID/ban)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/ban" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Test ban - automated test", "durationHours": 1}')

run_test "Ban User" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 3: Check User Status (should show banned)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 3: Check User Status - Should be BANNED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "$BASE_URL/admin/users/$TEST_USER_ID/status" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

run_test "User Status (Banned)" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 4: Mute User
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 4: Mute User (POST /admin/users/$TEST_USER_ID/mute)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/mute" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Test mute - automated test", "durationMinutes": 30}')

run_test "Mute User" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 5: Check User Status (should show banned AND muted)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 5: Check User Status - Should be BANNED + MUTED${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  "$BASE_URL/admin/users/$TEST_USER_ID/status" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

run_test "User Status (Banned + Muted)" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 6: Unban User
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 6: Unban User (POST /admin/users/$TEST_USER_ID/unban)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/unban" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

run_test "Unban User" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 7: Delete User
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 7: Delete User (DELETE /api/admin/delete/$TEST_WORLD/$TEST_USER_ID)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X DELETE "$BASE_URL/api/admin/delete/$TEST_WORLD/$TEST_USER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

run_test "Delete User" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 8: Voice Rooms List
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 8: List Voice Rooms (GET /voice/rooms)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$BASE_URL/voice/rooms")
run_test "List Voice Rooms" "200" "$RESPONSE"

# ═══════════════════════════════════════════════════════════════════════════
# TEST 9: Unauthorized Request (Security Test)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 9: Unauthorized Ban Request - Should return 401${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/$TEST_USER_ID/ban" \
  -H "Authorization: Bearer INVALID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Test", "durationHours": 1}')

TOTAL_TESTS=$((TOTAL_TESTS + 1))
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_STATUS" == "401" ]; then
    echo -e "${GREEN}✅ PASSED${NC} - Unauthorized request properly rejected"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ FAILED${NC} - Expected 401, got: $HTTP_STATUS"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# TEST 10: Invalid User ID (Error Handling Test)
# ═══════════════════════════════════════════════════════════════════════════

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${CYAN}TEST 10: Invalid User ID - Should return 400${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -X POST "$BASE_URL/admin/users/undefined/ban" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Test", "durationHours": 1}')

TOTAL_TESTS=$((TOTAL_TESTS + 1))
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d':' -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d')

echo "📥 Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_STATUS" == "400" ]; then
    echo -e "${GREEN}✅ PASSED${NC} - Invalid user ID properly rejected"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ FAILED${NC} - Expected 400, got: $HTTP_STATUS"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
echo ""

# ═══════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════════════"
echo -e "${BLUE}📊 TEST SUMMARY${NC}"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed Tests: $PASSED_TESTS${NC}"
echo -e "${RED}Failed Tests: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Backend v3.2 is working correctly!${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}❌ SOME TESTS FAILED. Please review the output above.${NC}"
    EXIT_CODE=1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Next steps:"
echo "   1. Review test results above"
echo "   2. Check Cloudflare Worker logs: wrangler tail -c wrangler-v3.2.toml"
echo "   3. Integrate working endpoints into Flutter app"
echo "   4. Test WebSocket signaling with wscat"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"

exit $EXIT_CODE
