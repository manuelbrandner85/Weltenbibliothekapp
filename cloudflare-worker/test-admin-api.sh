#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# 🧪 WELTENBIBLIOTHEK - ADMIN API TEST SUITE
# ═══════════════════════════════════════════════════════════════════════════

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKER_URL="${WORKER_URL:-https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev}"
ADMIN_TOKEN="${ADMIN_TOKEN:-XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB}"

echo "═══════════════════════════════════════════════════════════════════════════"
echo "🧪 ADMIN API TEST SUITE"
echo "═══════════════════════════════════════════════════════════════════════════"
echo "Worker URL: $WORKER_URL"
echo "Admin Token: ${ADMIN_TOKEN:0:10}..."
echo ""

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ═══════════════════════════════════════════════════════════════════════════
# TEST HELPERS
# ═══════════════════════════════════════════════════════════════════════════

run_test() {
  local test_name="$1"
  local expected_status="$2"
  local method="$3"
  local endpoint="$4"
  local data="$5"
  local auth_required="$6"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -e "${BLUE}[TEST $TOTAL_TESTS]${NC} $test_name"
  
  # Build curl command
  local curl_cmd="curl -s -w '\n%{http_code}' -X $method"
  
  if [ "$auth_required" = "true" ]; then
    curl_cmd="$curl_cmd -H 'Authorization: Bearer $ADMIN_TOKEN'"
  fi
  
  if [ -n "$data" ]; then
    curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
  fi
  
  curl_cmd="$curl_cmd '$WORKER_URL$endpoint'"
  
  # Execute request
  response=$(eval "$curl_cmd")
  status_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  
  # Validate status code
  if [ "$status_code" = "$expected_status" ]; then
    echo -e "  ${GREEN}✅ PASS${NC} - Status: $status_code"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    
    # Pretty print JSON response
    if command -v jq &> /dev/null; then
      echo "$body" | jq '.' 2>/dev/null || echo "  Response: $body"
    else
      echo "  Response: $body"
    fi
  else
    echo -e "  ${RED}❌ FAIL${NC} - Expected: $expected_status, Got: $status_code"
    echo "  Response: $body"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE
# ═══════════════════════════════════════════════════════════════════════════

echo "─────────────────────────────────────────────────────────────────────────"
echo "📡 SECTION 1: HEALTH & STATUS"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

run_test "Health Check" 200 GET "/health" "" false

run_test "List Active Rooms" 200 GET "/voice/rooms" "" false

echo "─────────────────────────────────────────────────────────────────────────"
echo "🛡️ SECTION 2: ADMIN - BAN OPERATIONS"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

run_test "Ban User (Authenticated)" 200 POST "/admin/users/test-user-123/ban" \
  '{"reason":"Test ban","durationHours":24}' true

run_test "Ban User (No Auth - Should Fail)" 401 POST "/admin/users/test-user-123/ban" \
  '{"reason":"Test ban","durationHours":24}' false

run_test "Ban User (Invalid Token - Should Fail)" 401 POST "/admin/users/test-user-123/ban" \
  '{"reason":"Test ban","durationHours":24}' false

run_test "Unban User (Authenticated)" 200 POST "/admin/users/test-user-123/unban" \
  '' true

run_test "Unban User (No Auth - Should Fail)" 401 POST "/admin/users/test-user-123/unban" \
  '' false

echo "─────────────────────────────────────────────────────────────────────────"
echo "🔇 SECTION 3: ADMIN - MUTE OPERATIONS"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

run_test "Mute User (Authenticated)" 200 POST "/admin/users/test-user-456/mute" \
  '{"reason":"Test mute","durationMinutes":60}' true

run_test "Mute User (No Auth - Should Fail)" 401 POST "/admin/users/test-user-456/mute" \
  '{"reason":"Test mute","durationMinutes":60}' false

echo "─────────────────────────────────────────────────────────────────────────"
echo "🗑️ SECTION 4: ADMIN - DELETE OPERATIONS"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

run_test "Delete User (Authenticated)" 200 DELETE "/api/admin/delete/MATERIE/test-user-789" \
  '' true

run_test "Delete User (No Auth - Should Fail)" 401 DELETE "/api/admin/delete/MATERIE/test-user-789" \
  '' false

run_test "Delete User ENERGIE World" 200 DELETE "/api/admin/delete/ENERGIE/test-user-999" \
  '' true

echo "─────────────────────────────────────────────────────────────────────────"
echo "📊 SECTION 5: ROOM INFO API"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

run_test "Get Room Info (Non-Existent Room)" 200 GET "/voice/rooms/test-room-123" "" false

# ═══════════════════════════════════════════════════════════════════════════
# TEST SUMMARY
# ═══════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════════════"
echo "📊 TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "Total Tests:  $TOTAL_TESTS"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
  exit 0
else
  echo -e "${RED}❌ SOME TESTS FAILED!${NC}"
  exit 1
fi
