#!/bin/bash
echo "═══════════════════════════════════════════════════════════════════"
echo "🔬 DEEP CODE QUALITY & ERROR ANALYSIS"
echo "═══════════════════════════════════════════════════════════════════"

# 1. Check for TODO/FIXME/HACK comments
echo -e "\n📋 1. CODE DEBT ANALYSIS (TODO/FIXME/HACK)"
echo "─────────────────────────────────────────────────────────────────"
grep -rn "TODO\|FIXME\|HACK\|XXX" lib/screens/materie/materie_live_chat_screen.dart lib/screens/energie/energie_live_chat_screen.dart 2>/dev/null | wc -l | xargs echo "Total code debt markers found:"

# 2. Check for print() statements (should use debugPrint)
echo -e "\n🐛 2. DEBUG PRINT ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
grep -rn "print(" lib/screens/materie/materie_live_chat_screen.dart lib/screens/energie/energie_live_chat_screen.dart 2>/dev/null | wc -l | xargs echo "print() calls found (should use debugPrint):"

# 3. Check for hardcoded strings (i18n issues)
echo -e "\n🌍 3. HARDCODED STRINGS ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
grep -rn "Text('.*')" lib/screens/materie/materie_live_chat_screen.dart 2>/dev/null | head -5
echo "..."
grep -rn "Text('.*')" lib/screens/materie/materie_live_chat_screen.dart 2>/dev/null | wc -l | xargs echo "Total hardcoded UI strings found:"

# 4. Check for memory leaks (missing dispose)
echo -e "\n💾 4. MEMORY LEAK ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
echo "Checking for Controllers without dispose()..."
grep -n "Controller\|Timer\|Subscription" lib/screens/materie/materie_live_chat_screen.dart | grep -v "dispose" | head -5

# 5. Check for error handling gaps
echo -e "\n⚠️ 5. ERROR HANDLING ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
grep -n "try {" lib/screens/materie/materie_live_chat_screen.dart | wc -l | xargs echo "Try-catch blocks found:"
grep -n "catch" lib/screens/materie/materie_live_chat_screen.dart | grep -v "rethrow" | wc -l | xargs echo "Catch blocks (not rethrowing):"

# 6. Check for async without await
echo -e "\n⏱️ 6. ASYNC/AWAIT ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
grep -n "Future<.*>.*async" lib/screens/materie/materie_live_chat_screen.dart | wc -l | xargs echo "Async functions defined:"
grep -n "await" lib/screens/materie/materie_live_chat_screen.dart | wc -l | xargs echo "Await calls found:"

# 7. Check for setState without mounted check
echo -e "\n🎯 7. SETSTATE SAFETY ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
grep -n "setState(" lib/screens/materie/materie_live_chat_screen.dart | wc -l | xargs echo "setState() calls found:"
grep -B 2 "setState(" lib/screens/materie/materie_live_chat_screen.dart | grep "if (mounted)" | wc -l | xargs echo "setState() with mounted check:"

# 8. Check for API error codes handling
echo -e "\n🌐 8. API ERROR HANDLING ANALYSIS"
echo "─────────────────────────────────────────────────────────────────"
grep -n "statusCode" lib/services/cloudflare_api_service.dart | wc -l | xargs echo "Status code checks found:"
grep -n "401\|403\|404\|500" lib/services/cloudflare_api_service.dart | wc -l | xargs echo "Specific error code handlers:"

echo -e "\n═══════════════════════════════════════════════════════════════════"
