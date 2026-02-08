#!/bin/bash

echo "=== 📋 CLOUDFLARE WORKERS API-DETAILS ==="
echo ""

# Funktionierende Worker mit /health
online_workers=(
  "weltenbibliothek-api.brandy13062.workers.dev"
  "weltenbibliothek-api-v2.brandy13062.workers.dev"
  "weltenbibliothek-community-api.brandy13062.workers.dev"
  "chat-features-weltenbibliothek.brandy13062.workers.dev"
  "recherche-engine.brandy13062.workers.dev"
  "weltenbibliothek-media-api.brandy13062.workers.dev"
  "weltenbibliothek-voice.brandy13062.workers.dev"
  "api-backend.brandy13062.workers.dev"
)

for worker in "${online_workers[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Worker: $worker"
  echo ""
  
  # Hole Health-Daten
  health=$(curl -s --max-time 5 "https://$worker/health" 2>/dev/null)
  
  if [ -n "$health" ]; then
    echo "📊 Health Response:"
    echo "$health" | jq '.' 2>/dev/null || echo "$health"
    echo ""
    
    # Versuche Endpunkte/Features zu extrahieren
    endpoints=$(echo "$health" | jq -r '.endpoints // .features // empty' 2>/dev/null)
    if [ -n "$endpoints" ]; then
      echo "🔗 Verfügbare Endpunkte/Features:"
      echo "$endpoints"
      echo ""
    fi
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ API-Details abgeschlossen"

