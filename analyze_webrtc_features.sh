#!/bin/bash

echo "=== 🔍 WEBRTC & DASHBOARD FEATURE ANALYSIS ==="
echo ""

# 1. WebRTC Services finden
echo "📡 1. WebRTC Services:"
find lib -name "*webrtc*" -o -name "*voice*" -o -name "*signaling*" 2>/dev/null | sort
echo ""

# 2. Dashboard Screens finden
echo "📊 2. Dashboard Screens:"
find lib/screens -name "*dashboard*" -o -name "*home*tab*.dart" 2>/dev/null | sort
echo ""

# 3. Cloudflare API Calls in WebRTC/Voice Services
echo "🌐 3. Cloudflare APIs in WebRTC/Voice:"
grep -r "workers.dev" lib/services/*webrtc* lib/services/*voice* lib/services/*signaling* 2>/dev/null | cut -d: -f2 | grep -o "https://[^'\"]*" | sort -u
echo ""

# 4. WebRTC Worker Test
echo "🧪 4. Testing WebRTC Workers:"
workers=(
  "weltenbibliothek-voice.brandy13062.workers.dev"
  "chat-features-weltenbibliothek.brandy13062.workers.dev"
)

for worker in "${workers[@]}"; do
  echo "   Testing: $worker"
  health=$(curl -s --max-time 5 "https://$worker/health" 2>/dev/null)
  if [ -n "$health" ]; then
    echo "   ✅ Response: $(echo $health | jq -c '.' 2>/dev/null || echo $health | head -c 80)"
  else
    echo "   ❌ No response"
  fi
  echo ""
done

# 5. Dashboard Features mit Backend
echo "📋 5. Dashboard Features mit Backend-Calls:"
grep -r "http\." lib/screens/*dashboard* lib/screens/*/home_tab*.dart 2>/dev/null | grep -o "https://[^'\"]*" | sort -u | head -10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Analysis Complete"

