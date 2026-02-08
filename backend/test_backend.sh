#!/bin/bash
# Test-Skript für Backend-API

echo "🧪 WELTENBIBLIOTHEK BACKEND - TEST SUITE"
echo "=========================================="
echo ""

# Check if backend is running
echo "1️⃣  Checking Backend Status..."
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "   ✅ Backend läuft auf Port 8080"
else
    echo "   ❌ Backend nicht erreichbar"
    echo "   💡 Starte Backend mit: python3 deep_research_api.py"
    exit 1
fi

echo ""
echo "2️⃣  Testing POST /api/recherche/start..."

# Start recherche
REQUEST_ID=$(curl -s -X POST http://localhost:8080/api/recherche/start \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Ukraine Krieg",
    "sources": ["reuters.com", "spiegel.de", "bbc.com"],
    "language": "de",
    "maxResults": 5
  }' | grep -o '"requestId":"[^"]*"' | cut -d'"' -f4)

if [ -z "$REQUEST_ID" ]; then
    echo "   ❌ Fehler beim Starten der Recherche"
    exit 1
fi

echo "   ✅ Recherche gestartet"
echo "   📋 Request-ID: $REQUEST_ID"

echo ""
echo "3️⃣  Testing GET /api/recherche/status/{requestId}..."

# Wait 2 seconds
sleep 2

# Get status
STATUS=$(curl -s http://localhost:8080/api/recherche/status/$REQUEST_ID)

if [ -z "$STATUS" ]; then
    echo "   ❌ Fehler beim Abrufen des Status"
    exit 1
fi

echo "   ✅ Status abgerufen"
echo "   📊 Response:"
echo "$STATUS" | python3 -m json.tool

echo ""
echo "=========================================="
echo "✅ ALLE TESTS ERFOLGREICH!"
echo "=========================================="
