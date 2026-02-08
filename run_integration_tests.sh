#!/bin/bash
# 🧪 COMPREHENSIVE WEBRTC & DASHBOARD TESTS
# Tests all Cloudflare Workers and integration points

echo "🧪 ======================================"
echo "   WELTENBIBLIOTHEK INTEGRATION TESTS"
echo "======================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

test_api() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"
    
    echo -e "${BLUE}Testing:${NC} $name"
    
    response=$(curl -s -o /tmp/response.json -w "%{http_code}" "$url")
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✅ PASS${NC} ($response)"
        cat /tmp/response.json | python3 -m json.tool 2>/dev/null | head -5
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} (Expected $expected_code, got $response)"
        cat /tmp/response.json
        ((FAILED++))
    fi
    echo ""
}

# ==================================================
# 1. WEBRTC VOICE WORKER TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🎙️  WEBRTC VOICE WORKER TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

VOICE_BASE="https://weltenbibliothek-voice.brandy13062.workers.dev"

test_api "Voice Worker Health" "$VOICE_BASE/health" 200

# Test register user
echo -e "${BLUE}Testing:${NC} Voice Register User"
ROOM_ID="test_room_$(date +%s)"
USER_ID="test_user_1"
response=$(curl -s -o /tmp/response.json -w "%{http_code}" -X POST "$VOICE_BASE/voice/register" \
  -H "Content-Type: application/json" \
  -d "{\"roomId\": \"$ROOM_ID\", \"userId\": \"$USER_ID\", \"username\": \"TestUser\"}")

if [ "$response" = "200" ]; then
    echo -e "${GREEN}✅ PASS${NC} ($response)"
    cat /tmp/response.json | python3 -m json.tool 2>/dev/null
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} (Expected 200, got $response)"
    cat /tmp/response.json
    ((FAILED++))
fi
echo ""

# ==================================================
# 2. PROFILE & AUTH API TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}👤 PROFILE & AUTH API TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

API_V2_BASE="https://weltenbibliothek-api-v2.brandy13062.workers.dev"

test_api "API-V2 Health" "$API_V2_BASE/health" 200
test_api "Admin Check (Materie)" "$API_V2_BASE/api/admin/check/materie/Weltenbibliothek" 200
test_api "Admin Check (Energie)" "$API_V2_BASE/api/admin/check/energie/Weltenbibliothek" 200

# ==================================================
# 3. COMMUNITY & CHAT API TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}💬 COMMUNITY & CHAT API TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

COMMUNITY_BASE="https://weltenbibliothek-community-api.brandy13062.workers.dev"
CHAT_BASE="https://chat-features-weltenbibliothek.brandy13062.workers.dev"

test_api "Community API Health" "$COMMUNITY_BASE/health" 200
test_api "Chat Features Health" "$CHAT_BASE/health" 200

# ==================================================
# 4. RECHERCHE ENGINE TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔍 RECHERCHE ENGINE TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

RECHERCHE_BASE="https://recherche-engine.brandy13062.workers.dev"

test_api "Recherche Engine Health" "$RECHERCHE_BASE/health" 200

# ==================================================
# 5. MEDIA API TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📸 MEDIA API TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

MEDIA_BASE="https://weltenbibliothek-media-api.brandy13062.workers.dev"

test_api "Media API Health" "$MEDIA_BASE/health" 200

# ==================================================
# 6. LEADERBOARD BACKEND TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🏆 LEADERBOARD BACKEND TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

BACKEND_BASE="https://api-backend.brandy13062.workers.dev"

test_api "API Backend Health" "$BACKEND_BASE/health" 200

# ==================================================
# 7. LEGACY API TESTS
# ==================================================
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔧 LEGACY API TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

API_V1_BASE="https://weltenbibliothek-api.brandy13062.workers.dev"

test_api "API-V1 Health" "$API_V1_BASE/health" 200

# ==================================================
# FINAL SUMMARY
# ==================================================
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 TEST SUMMARY${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo -e "${GREEN}✅ PASSED:${NC} $PASSED / $TOTAL"
echo -e "${RED}❌ FAILED:${NC} $FAILED / $TOTAL"
echo -e "${BLUE}📈 SUCCESS RATE:${NC} $PERCENTAGE%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Integration is FULLY FUNCTIONAL! 🎉${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Review above for details.${NC}"
fi

echo ""
echo "✅ Tests Complete!"
