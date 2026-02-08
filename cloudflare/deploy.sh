#!/bin/bash

# ============================================================================
# PRODUCTION DEPLOYMENT SCRIPT - Weltenbibliothek Backend
# ============================================================================

set -e  # Exit on error

echo "🚀 WELTENBIBLIOTHEK BACKEND DEPLOYMENT"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ Wrangler CLI nicht gefunden!${NC}"
    echo ""
    echo "Installation:"
    echo "  npm install -g wrangler"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Wrangler CLI gefunden${NC}"
echo ""

# Check if logged in
if ! wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  Nicht bei Cloudflare eingeloggt!${NC}"
    echo ""
    echo "Führe Login durch:"
    wrangler login
    echo ""
fi

echo -e "${GREEN}✅ Cloudflare Login aktiv${NC}"
echo ""

# Deploy Worker
echo "📦 Deploying Worker..."
cd /home/user/flutter_app/cloudflare

wrangler deploy production-worker.js --name api-backend

echo ""
echo -e "${GREEN}✅ Worker deployed!${NC}"
echo ""

# Get Worker URL
echo "🔗 Worker URL:"
WORKER_URL=$(wrangler deployments list --name api-backend 2>/dev/null | grep -oP 'https://[^\s]+' | head -1)

if [ -z "$WORKER_URL" ]; then
    echo -e "${YELLOW}   Kann nicht automatisch ermittelt werden.${NC}"
    echo "   Prüfe: https://dash.cloudflare.com → Workers"
else
    echo -e "${GREEN}   $WORKER_URL${NC}"
fi

echo ""

# Check if API Token is set
echo "🔑 Prüfe API Token..."
if wrangler secret list --name api-backend 2>/dev/null | grep -q "PERPLEXITY_API_KEY"; then
    echo -e "${GREEN}✅ PERPLEXITY_API_KEY ist gesetzt${NC}"
else
    echo -e "${YELLOW}⚠️  PERPLEXITY_API_KEY nicht gefunden!${NC}"
    echo ""
    echo "Setze API Token:"
    echo "  wrangler secret put PERPLEXITY_API_KEY --name api-backend"
    echo ""
    echo "⚠️  WICHTIG: Verwende einen GÜLTIGEN Perplexity API Token!"
    echo "   Hol dir einen Token: https://www.perplexity.ai/settings/api"
    echo ""
fi

echo ""

# Test Health Check
echo "🧪 Teste Health Check..."
if [ ! -z "$WORKER_URL" ]; then
    HEALTH_RESPONSE=$(curl -s "$WORKER_URL/health" | head -10)
    
    if echo "$HEALTH_RESPONSE" | grep -q '"status":"ok"'; then
        echo -e "${GREEN}✅ Health Check erfolgreich!${NC}"
        echo "   Response: $HEALTH_RESPONSE"
    else
        echo -e "${RED}❌ Health Check fehlgeschlagen!${NC}"
        echo "   Response: $HEALTH_RESPONSE"
    fi
else
    echo -e "${YELLOW}⚠️  Überspringe Health Check (URL nicht verfügbar)${NC}"
fi

echo ""
echo "============================================"
echo "🎉 DEPLOYMENT ABGESCHLOSSEN!"
echo "============================================"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo ""
echo "1. API Token setzen (falls nicht bereits geschehen):"
echo "   wrangler secret put PERPLEXITY_API_KEY --name api-backend"
echo ""
echo "2. Worker-URL in Flutter App eintragen:"
echo "   Datei: lib/services/backend_recherche_service.dart"
echo "   Zeile 13: static const String _backendUrl = '$WORKER_URL';"
echo ""
echo "3. Flutter App neu builden:"
echo "   cd /home/user/flutter_app"
echo "   flutter build web --release"
echo ""
echo "4. Testen!"
echo ""
