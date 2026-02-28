#!/bin/bash

# 🦞 OpenClaw AI Integration Test Script
# Weltenbibliothek v5.7.0

echo "🦞 OpenClaw AI Integration Test"
echo "================================"
echo ""

# Test 1: OpenClaw Gateway Erreichbarkeit
echo "📡 Test 1: OpenClaw Gateway Erreichbarkeit"
echo "URL: http://72.62.154.95:50074/"
echo ""

response=$(curl -s -o /dev/null -w "%{http_code}" http://72.62.154.95:50074/ --max-time 5)

if [ "$response" -eq 200 ]; then
    echo "✅ ERFOLG: OpenClaw Gateway ist erreichbar (HTTP $response)"
else
    echo "❌ FEHLER: OpenClaw Gateway nicht erreichbar (HTTP $response)"
    echo "   → Fallback auf Cloudflare AI wird aktiviert"
fi

echo ""
echo "---"
echo ""

# Test 2: Flutter App Status
echo "📱 Test 2: Flutter App Status"
echo "URL: https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai"
echo ""

app_response=$(curl -s -o /dev/null -w "%{http_code}" https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai --max-time 5)

if [ "$app_response" -eq 200 ]; then
    echo "✅ ERFOLG: Flutter App läuft (HTTP $app_response)"
else
    echo "❌ FEHLER: Flutter App nicht erreichbar (HTTP $app_response)"
fi

echo ""
echo "---"
echo ""

# Test 3: Cloudflare Backend (Fallback)
echo "☁️ Test 3: Cloudflare Backend (Fallback)"
echo "URL: https://weltenbibliothek-api-v3.brandy13062.workers.dev"
echo ""

cloudflare_response=$(curl -s -o /dev/null -w "%{http_code}" https://weltenbibliothek-api-v3.brandy13062.workers.dev --max-time 5)

if [ "$cloudflare_response" -eq 200 ] || [ "$cloudflare_response" -eq 404 ]; then
    echo "✅ ERFOLG: Cloudflare Backend erreichbar (HTTP $cloudflare_response)"
else
    echo "❌ FEHLER: Cloudflare Backend nicht erreichbar (HTTP $cloudflare_response)"
fi

echo ""
echo "---"
echo ""

# Zusammenfassung
echo "📊 Zusammenfassung"
echo "=================="
echo ""

if [ "$response" -eq 200 ] && [ "$app_response" -eq 200 ]; then
    echo "✅ Alle Systeme funktionieren optimal!"
    echo "   → OpenClaw AI ist aktiv"
    echo "   → Flutter App läuft"
    echo "   → Cloudflare Fallback verfügbar"
elif [ "$response" -ne 200 ] && [ "$app_response" -eq 200 ]; then
    echo "⚠️ OpenClaw nicht erreichbar, Fallback aktiv"
    echo "   → Flutter App läuft"
    echo "   → Cloudflare AI übernimmt"
else
    echo "❌ Es gibt Probleme mit der Integration"
    echo "   → Bitte Logs prüfen"
fi

echo ""
echo "🔍 Weitere Tests:"
echo "   • Öffne die App im Browser"
echo "   • Teste Recherche-Tool (Materie-Welt)"
echo "   • Teste Traum-Analyse (Energie-Welt)"
echo ""
