#!/bin/bash

echo "=== 🧪 API-ENDPUNKT TESTS ==="
echo ""

# Teste alle kritischen API-Endpunkte
apis=(
  "https://weltenbibliothek-api.brandy13062.workers.dev/health"
  "https://weltenbibliothek-community-api.brandy13062.workers.dev/health"
  "https://chat-features-weltenbibliothek.brandy13062.workers.dev/health"
  "https://recherche-engine.brandy13062.workers.dev/health"
  "https://weltenbibliothek-group-tools.brandy13062.workers.dev/health"
  "https://weltenbibliothek-media-api.brandy13062.workers.dev/health"
)

for api in "${apis[@]}"; do
  echo "🔍 Testing: $api"
  response=$(curl -s -w "\n%{http_code}" --max-time 5 "$api" 2>/dev/null)
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | head -n -1)
  
  if [ "$http_code" = "200" ]; then
    echo "   ✅ Status: $http_code"
    echo "   Response: $(echo $body | head -c 100)..."
  elif [ "$http_code" = "404" ]; then
    echo "   ⚠️  Status: $http_code (Endpoint möglicherweise nicht vorhanden)"
  elif [ -z "$http_code" ]; then
    echo "   ❌ Keine Antwort (Timeout oder Fehler)"
  else
    echo "   ⚠️  Status: $http_code"
  fi
  echo ""
done

