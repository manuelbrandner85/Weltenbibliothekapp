#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# 🔍 DEPLOYMENT VERIFICATION SCRIPT
# ═══════════════════════════════════════════════════════════════
# Automated testing for Weltenbibliothek Cloudflare Worker
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
WORKER_URL="${1:-}"
TEST_USER_ID="verify_test_$(date +%s)"
PASSED=0
FAILED=0

# Print functions
print_success() { echo -e "${GREEN}✅ ${NC}$1"; ((PASSED++)); }
print_error() { echo -e "${RED}❌ ${NC}$1"; ((FAILED++)); }
print_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
print_header() { echo -e "\n${MAGENTA}═══ $1 ═══${NC}\n"; }

# Banner
print_banner() {
  echo -e "${BLUE}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                                                               ║"
  echo "║         🔍 WELTENBIBLIOTHEK DEPLOYMENT VERIFICATION           ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
  if [ -z "$WORKER_URL" ]; then
    print_error "Worker URL not provided"
    echo ""
    echo "Usage: $0 <worker_url>"
    echo "Example: $0 https://weltenbibliothek-api.your-account.workers.dev"
    exit 1
  fi
  
  if ! command -v curl &> /dev/null; then
    print_error "curl not found. Please install curl."
    exit 1
  fi
  
  if ! command -v jq &> /dev/null; then
    print_error "jq not found. Installing..."
    sudo apt-get install -y jq || brew install jq || {
      print_error "Failed to install jq. Please install manually."
      exit 1
    }
  fi
  
  print_info "Testing Worker URL: $WORKER_URL"
  echo ""
}

# Test 1: Health Check
test_health_check() {
  print_header "TEST 1: Health Check"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/health" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "200" ]; then
    print_success "Health endpoint returns 200"
  else
    print_error "Health endpoint failed (HTTP $HTTP_CODE)"
    return
  fi
  
  if echo "$BODY" | jq -e '.status == "healthy"' > /dev/null 2>&1; then
    print_success "Status is 'healthy'"
  else
    print_error "Status is not 'healthy'"
  fi
  
  if echo "$BODY" | jq -e '.checks.api.status == "ok"' > /dev/null 2>&1; then
    print_success "API check passed"
  else
    print_error "API check failed"
  fi
  
  if echo "$BODY" | jq -e '.checks.database.status == "ok"' > /dev/null 2>&1; then
    print_success "Database check passed"
  else
    print_error "Database check failed"
  fi
  
  if echo "$BODY" | jq -e '.checks.kv.status == "ok"' > /dev/null 2>&1; then
    print_success "KV namespace check passed"
  else
    print_error "KV namespace check failed"
  fi
}

# Test 2: Push Notifications - Subscribe
test_push_subscribe() {
  print_header "TEST 2: Push Notifications - Subscribe"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL/api/push/subscribe" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":\"$TEST_USER_ID\",\"topics\":[\"new_events\",\"chat_messages\"],\"platform\":\"web\"}" \
    2>/dev/null || echo "000")
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "201" ]; then
    print_success "Push subscribe returns 201"
  else
    print_error "Push subscribe failed (HTTP $HTTP_CODE)"
    return
  fi
  
  if echo "$BODY" | jq -e '.success == true' > /dev/null 2>&1; then
    print_success "Success flag is true"
  else
    print_error "Success flag is not true"
  fi
  
  SUBSCRIPTION_ID=$(echo "$BODY" | jq -r '.subscription_id' 2>/dev/null)
  if [ -n "$SUBSCRIPTION_ID" ] && [ "$SUBSCRIPTION_ID" != "null" ]; then
    print_success "Subscription ID returned: $SUBSCRIPTION_ID"
    export SUBSCRIPTION_ID
  else
    print_error "No subscription ID returned"
  fi
}

# Test 3: Push Notifications - Get Subscription
test_push_get_subscription() {
  print_header "TEST 3: Push Notifications - Get Subscription"
  
  if [ -z "${SUBSCRIPTION_ID:-}" ]; then
    print_error "No subscription ID available (previous test failed)"
    return
  fi
  
  RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/api/push/subscription/$SUBSCRIPTION_ID" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "200" ]; then
    print_success "Get subscription returns 200"
  else
    print_error "Get subscription failed (HTTP $HTTP_CODE)"
    return
  fi
  
  if echo "$BODY" | jq -e ".subscription_id == \"$SUBSCRIPTION_ID\"" > /dev/null 2>&1; then
    print_success "Subscription ID matches"
  else
    print_error "Subscription ID mismatch"
  fi
}

# Test 4: Playlists - Get Empty List
test_playlists_get_empty() {
  print_header "TEST 4: Playlists - Get Empty List"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/api/playlists?user_id=$TEST_USER_ID" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "200" ]; then
    print_success "Get playlists returns 200"
  else
    print_error "Get playlists failed (HTTP $HTTP_CODE)"
    return
  fi
  
  if echo "$BODY" | jq -e '.playlists' > /dev/null 2>&1; then
    print_success "Playlists array present"
  else
    print_error "No playlists array in response"
  fi
}

# Test 5: Playlists - Save Playlist
test_playlists_save() {
  print_header "TEST 5: Playlists - Save Playlist"
  
  PLAYLIST_DATA="{
    \"id\": \"test_playlist_$TEST_USER_ID\",
    \"user_id\": \"$TEST_USER_ID\",
    \"name\": \"Verification Test Playlist\",
    \"description\": \"Automated test playlist\",
    \"tracks\": [
      {
        \"id\": \"track_1\",
        \"title\": \"Test Song\",
        \"artist\": \"Test Artist\",
        \"duration\": 180
      }
    ]
  }"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL/api/playlists/test_playlist_$TEST_USER_ID" \
    -H "Content-Type: application/json" \
    -d "$PLAYLIST_DATA" 2>/dev/null || echo "000")
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    print_success "Save playlist returns $HTTP_CODE"
  else
    print_error "Save playlist failed (HTTP $HTTP_CODE)"
    return
  fi
  
  if echo "$BODY" | jq -e '.success == true' > /dev/null 2>&1; then
    print_success "Success flag is true"
  else
    print_error "Success flag is not true"
  fi
}

# Test 6: Analytics - Summary
test_analytics_summary() {
  print_header "TEST 6: Analytics - Summary"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/api/analytics/summary?timeRange=7d" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "200" ]; then
    print_success "Analytics summary returns 200"
  else
    print_error "Analytics summary failed (HTTP $HTTP_CODE)"
    return
  fi
  
  if echo "$BODY" | jq -e 'has("total_users")' > /dev/null 2>&1; then
    print_success "Response has total_users field"
  else
    print_error "Missing total_users field"
  fi
}

# Test 7: Analytics - WebRTC Metrics
test_analytics_webrtc() {
  print_header "TEST 7: Analytics - WebRTC Metrics"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/api/analytics/webrtc?timeRange=24h" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  
  if [ "$HTTP_CODE" = "200" ]; then
    print_success "WebRTC metrics returns 200"
  else
    print_error "WebRTC metrics failed (HTTP $HTTP_CODE)"
  fi
}

# Test 8: Analytics - User Engagement
test_analytics_engagement() {
  print_header "TEST 8: Analytics - User Engagement"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" "$WORKER_URL/api/analytics/engagement?timeRange=7d" 2>/dev/null || echo "000")
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  
  if [ "$HTTP_CODE" = "200" ]; then
    print_success "User engagement returns 200"
  else
    print_error "User engagement failed (HTTP $HTTP_CODE)"
  fi
}

# Test 9: Error Handling - Invalid Request
test_error_handling() {
  print_header "TEST 9: Error Handling"
  
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WORKER_URL/api/push/subscribe" \
    -H "Content-Type: application/json" \
    -d '{"invalid":"data"}' 2>/dev/null || echo "000")
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')
  
  if [ "$HTTP_CODE" = "400" ]; then
    print_success "Invalid request returns 400"
  else
    print_error "Invalid request should return 400 (got $HTTP_CODE)"
  fi
  
  if echo "$BODY" | jq -e 'has("error")' > /dev/null 2>&1; then
    print_success "Error message present"
  else
    print_error "No error message in response"
  fi
}

# Test 10: CORS Headers
test_cors_headers() {
  print_header "TEST 10: CORS Headers"
  
  HEADERS=$(curl -s -I "$WORKER_URL/health" 2>/dev/null)
  
  if echo "$HEADERS" | grep -i "access-control-allow-origin" > /dev/null; then
    print_success "CORS allow-origin header present"
  else
    print_error "Missing CORS allow-origin header"
  fi
  
  if echo "$HEADERS" | grep -i "access-control-allow-methods" > /dev/null; then
    print_success "CORS allow-methods header present"
  else
    print_error "Missing CORS allow-methods header"
  fi
}

# Performance Test
test_performance() {
  print_header "TEST 11: Performance"
  
  print_info "Testing response time (5 requests)..."
  TOTAL_TIME=0
  
  for i in {1..5}; do
    START=$(date +%s%N)
    curl -s "$WORKER_URL/health" > /dev/null 2>&1
    END=$(date +%s%N)
    DURATION=$(( (END - START) / 1000000 ))
    TOTAL_TIME=$((TOTAL_TIME + DURATION))
  done
  
  AVG_TIME=$((TOTAL_TIME / 5))
  
  if [ $AVG_TIME -lt 500 ]; then
    print_success "Average response time: ${AVG_TIME}ms (< 500ms)"
  else
    print_error "Average response time: ${AVG_TIME}ms (> 500ms)"
  fi
}

# Summary
print_summary() {
  print_header "VERIFICATION SUMMARY"
  
  TOTAL=$((PASSED + FAILED))
  PASS_RATE=$((PASSED * 100 / TOTAL))
  
  echo ""
  echo -e "${BLUE}Total Tests:${NC}  $TOTAL"
  echo -e "${GREEN}Passed:${NC}       $PASSED"
  echo -e "${RED}Failed:${NC}       $FAILED"
  echo -e "${BLUE}Pass Rate:${NC}    ${PASS_RATE}%"
  echo ""
  
  if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║              ✅ ALL TESTS PASSED! ✅                          ║"
    echo "║                                                               ║"
    echo "║         Your deployment is production-ready! 🚀               ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 0
  else
    echo -e "${YELLOW}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║              ⚠️  SOME TESTS FAILED  ⚠️                        ║"
    echo "║                                                               ║"
    echo "║         Please review the errors above                        ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
  fi
}

# Main execution
main() {
  print_banner
  check_prerequisites
  
  test_health_check
  test_push_subscribe
  test_push_get_subscription
  test_playlists_get_empty
  test_playlists_save
  test_analytics_summary
  test_analytics_webrtc
  test_analytics_engagement
  test_error_handling
  test_cors_headers
  test_performance
  
  print_summary
}

# Run main function
main "$@"
