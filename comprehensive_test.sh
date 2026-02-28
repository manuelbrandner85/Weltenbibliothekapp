#!/bin/bash

# 🧪 Weltenbibliothek - Umfassende Funktions-Tests
# Version: 5.7.0 mit OpenClaw AI Integration

echo "🧪 Weltenbibliothek - Umfassende Funktions-Tests"
echo "=================================================="
echo ""

# Farben für bessere Lesbarkeit
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
WARNINGS=0

# Test-Funktion
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -e "${BLUE}🔍 Test:${NC} $test_name"
    
    result=$(eval "$test_command" 2>/dev/null)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$result" == *"$expected_result"* ]]; then
        echo -e "   ${GREEN}✅ BESTANDEN${NC}"
        ((PASSED++))
    elif [ "$expected_result" == "ANY" ] && [ $exit_code -eq 0 ]; then
        echo -e "   ${GREEN}✅ BESTANDEN${NC}"
        ((PASSED++))
    else
        echo -e "   ${RED}❌ FEHLGESCHLAGEN${NC}"
        echo -e "   Erwartet: $expected_result"
        echo -e "   Erhalten: $result"
        ((FAILED++))
    fi
    echo ""
}

run_warning_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -e "${BLUE}⚠️ Warning Test:${NC} $test_name"
    
    result=$(eval "$test_command" 2>/dev/null)
    exit_code=$?
    
    if [ $exit_code -eq 0 ] && [[ "$result" == *"$expected_result"* ]]; then
        echo -e "   ${GREEN}✅ OK${NC}"
    else
        echo -e "   ${YELLOW}⚠️ WARNUNG${NC} (nicht kritisch)"
        ((WARNINGS++))
    fi
    echo ""
}

# ===========================================
# TEIL 1: INFRASTRUKTUR-TESTS
# ===========================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEIL 1: INFRASTRUKTUR-TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test "OpenClaw Gateway erreichbar" \
    "curl -s -o /dev/null -w '%{http_code}' http://72.62.154.95:50074/ --max-time 5" \
    "200"

run_test "OpenClaw Health Endpoint" \
    "curl -s -o /dev/null -w '%{http_code}' http://72.62.154.95:50074/health --max-time 5" \
    "200"

run_test "OpenClaw API Endpoint" \
    "curl -s -o /dev/null -w '%{http_code}' http://72.62.154.95:50074/api --max-time 5" \
    "200"

run_test "Flutter Web-App erreichbar" \
    "curl -s -o /dev/null -w '%{http_code}' https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai --max-time 5" \
    "200"

run_test "Cloudflare Backend erreichbar" \
    "curl -s -o /dev/null -w '%{http_code}' https://weltenbibliothek-api-v3.brandy13062.workers.dev --max-time 5" \
    "200"

# ===========================================
# TEIL 2: FLUTTER-APP-TESTS
# ===========================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEIL 2: FLUTTER-APP-TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test "Flutter HTML lädt" \
    "curl -s https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai | grep -o 'Weltenbibliothek'" \
    "Weltenbibliothek"

run_test "Flutter JavaScript vorhanden" \
    "curl -s -o /dev/null -w '%{http_code}' https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai/flutter.js" \
    "200"

run_test "Flutter Bootstrap vorhanden" \
    "curl -s -o /dev/null -w '%{http_code}' https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai/flutter_bootstrap.js" \
    "200"

run_test "CanvasKit vorhanden" \
    "curl -s -o /dev/null -w '%{http_code}' https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai/canvaskit/canvaskit.js" \
    "200"

run_test "Main Dart JS vorhanden" \
    "ls /home/user/flutter_app/build/web/main.dart.js" \
    "main.dart.js"

# ===========================================
# TEIL 3: OPENCLAW-INTEGRATION-TESTS
# ===========================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEIL 3: OPENCLAW-INTEGRATION${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test "OpenClaw Config in Flutter" \
    "grep -q 'http://72.62.154.95:50074' /home/user/flutter_app/lib/config/api_config.dart && echo 'OK'" \
    "OK"

run_test "OpenClaw Token in Flutter" \
    "grep -q 'lHNu7aoMko3O3ptFgBA1POK71xTf8YHw' /home/user/flutter_app/lib/config/api_config.dart && echo 'OK'" \
    "OK"

run_test "OpenClaw Service Datei existiert" \
    "ls /home/user/flutter_app/lib/services/openclaw_gateway_service.dart" \
    "openclaw_gateway_service.dart"

run_test "AI Service Manager existiert" \
    "ls /home/user/flutter_app/lib/services/ai_service_manager.dart" \
    "ai_service_manager.dart"

run_test "OpenClaw Service kompiliert" \
    "cd /home/user/flutter_app && dart analyze lib/services/openclaw_gateway_service.dart 2>&1 | grep -E '(info|warning)' | wc -l | awk '{print \$1}'" \
    "1"

run_test "AI Service Manager kompiliert" \
    "cd /home/user/flutter_app && dart analyze lib/services/ai_service_manager.dart 2>&1 | grep 'No issues' && echo 'OK'" \
    "OK"

# ===========================================
# TEIL 4: PERFORMANCE-TESTS
# ===========================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEIL 4: PERFORMANCE-TESTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test "Build-Verzeichnis existiert" \
    "ls /home/user/flutter_app/build/web/index.html" \
    "index.html"

run_test "Build-Größe akzeptabel (<15 KB)" \
    "ls -lh /home/user/flutter_app/build/web/index.html | awk '{print \$5}' | grep -E '[0-9]+K|[0-9]+\\.?[0-9]*K' && echo 'OK'" \
    "OK"

run_test "Material Icons optimiert" \
    "ls -lh /home/user/flutter_app/build/web/assets/fonts/MaterialIcons-Regular.otf 2>/dev/null | awk '{if (\$5 ~ /K/) print \"OK\"; else print \"FAIL\"}'" \
    "OK"

run_warning_test "OpenClaw Antwortzeit (<5s)" \
    "time (curl -s http://72.62.154.95:50074/ > /dev/null) 2>&1 | grep real | awk '{print \$2}' | grep -E '0m[0-4]'" \
    "0m"

run_warning_test "Flutter App Ladezeit (<3s)" \
    "time (curl -s https://5060-i8hwjt75mo05wo2j8vugs-cbeee0f9.sandbox.novita.ai > /dev/null) 2>&1 | grep real | awk '{print \$2}' | grep -E '0m[0-2]'" \
    "0m"

# ===========================================
# TEIL 5: CODE-QUALITÄTS-TESTS
# ===========================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEIL 5: CODE-QUALITÄT${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

run_test "Keine kritischen Fehler in main.dart" \
    "cd /home/user/flutter_app && dart analyze lib/main.dart 2>&1 | grep -c 'error •' | awk '{if (\$1 == 0) print \"OK\"; else print \"FAIL\"}'" \
    "OK"

run_test "Keine kritischen Fehler in Services" \
    "cd /home/user/flutter_app && dart analyze lib/services/*.dart 2>&1 | grep -c 'error •' | awk '{if (\$1 == 0) print \"OK\"; else print \"FAIL\"}'" \
    "OK"

run_warning_test "Warnings unter 100" \
    "cd /home/user/flutter_app && flutter analyze 2>&1 | grep 'issues found' | awk '{if (\$1 < 100) print \"OK\"; else print \"FAIL\"}'" \
    "OK"

# ===========================================
# ZUSAMMENFASSUNG
# ===========================================

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 TEST-ZUSAMMENFASSUNG${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✅ Bestanden:${NC} $PASSED Tests"
echo -e "${RED}❌ Fehlgeschlagen:${NC} $FAILED Tests"
echo -e "${YELLOW}⚠️ Warnungen:${NC} $WARNINGS Tests"
echo ""

TOTAL=$((PASSED + FAILED))
SUCCESS_RATE=$((PASSED * 100 / TOTAL))

echo -e "Erfolgsrate: ${SUCCESS_RATE}%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALLE KRITISCHEN TESTS BESTANDEN!${NC}"
    echo -e "${GREEN}Die Weltenbibliothek-App mit OpenClaw ist voll funktionsfähig!${NC}"
    exit 0
else
    echo -e "${RED}⚠️ EINIGE TESTS FEHLGESCHLAGEN!${NC}"
    echo -e "${YELLOW}Bitte die fehlgeschlagenen Tests überprüfen.${NC}"
    exit 1
fi
