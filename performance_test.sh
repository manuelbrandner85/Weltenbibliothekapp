#!/bin/bash
# ═══════════════════════════════════════════════════════════
# 📊 WELTENBIBLIOTHEK - PERFORMANCE TEST SUITE
# ═══════════════════════════════════════════════════════════

echo "🚀 Weltenbibliothek Performance Test Suite"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test Results
RESULTS_FILE="/home/user/flutter_app/performance_test_results.txt"
echo "Performance Test Results - $(date)" > "$RESULTS_FILE"
echo "===========================================" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# ───────────────────────────────────────────────────────────
# 📦 TEST 1: BUILD SIZE ANALYSIS
# ───────────────────────────────────────────────────────────
echo -e "${BLUE}📦 TEST 1: Build Size Analysis${NC}"
echo ""

if [ -d "build/web" ]; then
    WEB_SIZE=$(du -sh build/web | cut -f1)
    MAIN_DART_JS=$(du -sh build/web/main.dart.js 2>/dev/null | cut -f1 || echo "N/A")
    
    echo "Web Build Size:" >> "$RESULTS_FILE"
    echo "  Total: $WEB_SIZE" >> "$RESULTS_FILE"
    echo "  main.dart.js: $MAIN_DART_JS" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    
    echo -e "  ${GREEN}✓${NC} Web Build: $WEB_SIZE"
    echo -e "  ${GREEN}✓${NC} main.dart.js: $MAIN_DART_JS"
else
    echo -e "  ${RED}✗${NC} Web build not found"
    echo "Web Build: Not found" >> "$RESULTS_FILE"
fi

echo ""

# ───────────────────────────────────────────────────────────
# 🗂️ TEST 2: ASSET ANALYSIS
# ───────────────────────────────────────────────────────────
echo -e "${BLUE}🗂️ TEST 2: Asset Analysis${NC}"
echo ""

if [ -d "build/web/assets" ]; then
    ASSETS_SIZE=$(du -sh build/web/assets | cut -f1)
    ICON_COUNT=$(find build/web/assets -name "*.png" -o -name "*.jpg" -o -name "*.webp" | wc -l)
    
    echo "Assets:" >> "$RESULTS_FILE"
    echo "  Total Size: $ASSETS_SIZE" >> "$RESULTS_FILE"
    echo "  Image Count: $ICON_COUNT" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    
    echo -e "  ${GREEN}✓${NC} Assets Size: $ASSETS_SIZE"
    echo -e "  ${GREEN}✓${NC} Images: $ICON_COUNT"
else
    echo -e "  ${RED}✗${NC} Assets not found"
fi

echo ""

# ───────────────────────────────────────────────────────────
# 📊 TEST 3: CODE METRICS
# ───────────────────────────────────────────────────────────
echo -e "${BLUE}📊 TEST 3: Code Metrics${NC}"
echo ""

DART_FILES=$(find lib -name "*.dart" | wc -l)
TOTAL_LINES=$(find lib -name "*.dart" -exec wc -l {} + | tail -1 | awk '{print $1}')
SERVICES=$(find lib/services -name "*.dart" | wc -l)
SCREENS=$(find lib/screens -name "*.dart" | wc -l)
WIDGETS=$(find lib/widgets -name "*.dart" | wc -l)

echo "Code Metrics:" >> "$RESULTS_FILE"
echo "  Dart Files: $DART_FILES" >> "$RESULTS_FILE"
echo "  Total Lines: $TOTAL_LINES" >> "$RESULTS_FILE"
echo "  Services: $SERVICES" >> "$RESULTS_FILE"
echo "  Screens: $SCREENS" >> "$RESULTS_FILE"
echo "  Widgets: $WIDGETS" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

echo -e "  ${GREEN}✓${NC} Dart Files: $DART_FILES"
echo -e "  ${GREEN}✓${NC} Total Lines: $TOTAL_LINES"
echo -e "  ${GREEN}✓${NC} Services: $SERVICES"
echo -e "  ${GREEN}✓${NC} Screens: $SCREENS"
echo -e "  ${GREEN}✓${NC} Widgets: $WIDGETS"

echo ""

# ───────────────────────────────────────────────────────────
# 🔍 TEST 4: DEPENDENCY ANALYSIS
# ───────────────────────────────────────────────────────────
echo -e "${BLUE}🔍 TEST 4: Dependency Analysis${NC}"
echo ""

if [ -f "pubspec.yaml" ]; then
    DEPS=$(grep -c "^  [a-z]" pubspec.yaml || echo "0")
    echo -e "  ${GREEN}✓${NC} Dependencies: $DEPS packages"
    
    echo "Dependencies: $DEPS packages" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
fi

echo ""

# ───────────────────────────────────────────────────────────
# ⚡ TEST 5: WEB LOAD TIME SIMULATION
# ───────────────────────────────────────────────────────────
echo -e "${BLUE}⚡ TEST 5: Web Load Time Estimation${NC}"
echo ""

if [ -f "build/web/main.dart.js" ]; then
    MAIN_JS_SIZE=$(stat -f%z build/web/main.dart.js 2>/dev/null || stat -c%s build/web/main.dart.js 2>/dev/null)
    
    # Estimate load time (assuming 10 Mbps connection)
    # Formula: (file_size_in_bytes * 8) / (10 * 1024 * 1024) seconds
    LOAD_TIME=$(echo "scale=2; ($MAIN_JS_SIZE * 8) / (10 * 1024 * 1024)" | bc 2>/dev/null || echo "N/A")
    
    if [ "$LOAD_TIME" != "N/A" ]; then
        echo -e "  ${GREEN}✓${NC} Estimated Load Time (10 Mbps): ${LOAD_TIME}s"
        echo "Web Load Time (10 Mbps): ${LOAD_TIME}s" >> "$RESULTS_FILE"
    else
        echo -e "  ${YELLOW}⚠${NC} Could not calculate load time"
    fi
else
    echo -e "  ${RED}✗${NC} main.dart.js not found"
fi

echo ""
echo "" >> "$RESULTS_FILE"

# ───────────────────────────────────────────────────────────
# 📈 TEST 6: FLUTTER ANALYZE SUMMARY
# ───────────────────────────────────────────────────────────
echo -e "${BLUE}📈 TEST 6: Code Quality Summary${NC}"
echo ""

echo "Running flutter analyze..."
ANALYZE_OUTPUT=$(flutter analyze --no-fatal-infos 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "^  error" || echo "0")
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "^warning" || echo "0")
INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | tail -1 | grep -oE "[0-9]+ issues" | grep -oE "[0-9]+" || echo "0")

echo "Code Quality:" >> "$RESULTS_FILE"
echo "  Errors: $ERROR_COUNT" >> "$RESULTS_FILE"
echo "  Warnings: $WARNING_COUNT" >> "$RESULTS_FILE"
echo "  Total Issues: $INFO_COUNT" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

if [ "$ERROR_COUNT" -eq "0" ]; then
    echo -e "  ${GREEN}✓${NC} Errors: $ERROR_COUNT (Clean!)"
else
    echo -e "  ${YELLOW}⚠${NC} Errors: $ERROR_COUNT"
fi

echo -e "  ${GREEN}✓${NC} Warnings: $WARNING_COUNT"
echo -e "  ${GREEN}✓${NC} Total Issues: $INFO_COUNT"

echo ""

# ───────────────────────────────────────────────────────────
# 📋 SUMMARY
# ───────────────────────────────────────────────────────────
echo "=========================================="
echo -e "${GREEN}✅ Performance Test Complete!${NC}"
echo "=========================================="
echo ""
echo "Results saved to: $RESULTS_FILE"
echo ""

# Display results file
echo "Full Report:"
echo "-------------------------------------------"
cat "$RESULTS_FILE"
