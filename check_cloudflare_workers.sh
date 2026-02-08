#!/bin/bash

echo "=== 🌐 CLOUDFLARE WORKERS INVENTORY ==="
echo ""
echo "🔍 Teste alle bekannten Cloudflare Workers..."
echo ""

# Liste aller Worker aus dem Code
workers=(
  "weltenbibliothek-api.brandy13062.workers.dev"
  "weltenbibliothek-api-v2.brandy13062.workers.dev"
  "weltenbibliothek-community-api.brandy13062.workers.dev"
  "chat-features-weltenbibliothek.brandy13062.workers.dev"
  "recherche-engine.brandy13062.workers.dev"
  "weltenbibliothek-group-tools.brandy13062.workers.dev"
  "weltenbibliothek-media-api.brandy13062.workers.dev"
  "weltenbibliothek-worker.brandy13062.workers.dev"
  "weltenbibliothek-auth.brandy13062.workers.dev"
  "weltenbibliothek-voice.brandy13062.workers.dev"
  "api-backend.brandy13062.workers.dev"
  "weltenbibliothek.manuel-brandner75.workers.dev"
)

echo "📋 Gefundene Workers im Code: ${#workers[@]}"
echo ""

for worker in "${workers[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Worker: $worker"
  
  # Teste /health endpoint
  echo "   Testing /health..."
  health_response=$(curl -s -w "\n%{http_code}" --max-time 5 "https://$worker/health" 2>/dev/null)
  health_code=$(echo "$health_response" | tail -1)
  health_body=$(echo "$health_response" | head -n -1)
  
  if [ "$health_code" = "200" ]; then
    echo "   ✅ /health: $health_code"
    # Zeige Version/Service-Info wenn vorhanden
    version=$(echo "$health_body" | grep -o '"version":"[^"]*"' | head -1)
    service=$(echo "$health_body" | grep -o '"service":"[^"]*"' | head -1)
    [ -n "$version" ] && echo "      $version"
    [ -n "$service" ] && echo "      $service"
  elif [ "$health_code" = "404" ]; then
    echo "   ⚠️  /health: 404 (nicht vorhanden)"
  else
    echo "   ❌ /health: Keine Antwort"
  fi
  
  # Teste Root endpoint
  echo "   Testing / (root)..."
  root_response=$(curl -s -w "\n%{http_code}" --max-time 5 "https://$worker/" 2>/dev/null)
  root_code=$(echo "$root_response" | tail -1)
  
  if [ "$root_code" = "200" ]; then
    echo "   ✅ /: $root_code"
  elif [ "$root_code" = "404" ]; then
    echo "   ⚠️  /: 404"
  else
    echo "   ❌ /: Keine Antwort"
  fi
  
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Worker-Check abgeschlossen"

