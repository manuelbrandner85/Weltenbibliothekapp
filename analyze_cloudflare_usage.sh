#!/bin/bash
# Forensic Analysis: Find ALL Cloudflare endpoint usage in Flutter app

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   🔍 FORENSIC CODE ANALYSIS: CLOUDFLARE ENDPOINTS         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Find all .workers.dev URLs
echo "📡 WORKER ENDPOINTS IN CODE:"
echo "─────────────────────────────────────────────────────────────"
grep -r "\.workers\.dev" lib/ --include="*.dart" -n | \
  sed 's/.*https:\/\//  /' | \
  sed 's/\.workers\.dev.*/\.workers\.dev/' | \
  sort -u
echo ""

# Find all brandy13062.workers.dev URLs (your specific subdomain)
echo "🎯 BRANDY13062 WORKERS:"
echo "─────────────────────────────────────────────────────────────"
grep -r "brandy13062\.workers\.dev" lib/ --include="*.dart" -n | \
  sed 's/.*https:\/\//  /' | \
  sort -u
echo ""

# Find R2 bucket references
echo "🪣 R2 BUCKET REFERENCES:"
echo "─────────────────────────────────────────────────────────────"
grep -ri "r2\.cloudflarestorage\|r2\.dev" lib/ --include="*.dart" -n || echo "  (None found)"
echo ""

# Find D1 database references
echo "🗄️  D1 DATABASE REFERENCES:"
echo "─────────────────────────────────────────────────────────────"
grep -ri "d1\|database" lib/ --include="*.dart" -n | grep -i cloudflare | head -10 || echo "  (None found)"
echo ""

# Find all API service files
echo "📂 API SERVICE FILES:"
echo "─────────────────────────────────────────────────────────────"
find lib/services -name "*api*.dart" -o -name "*cloudflare*.dart" | while read file; do
  echo "  📄 $file"
done
echo ""

# Analyze cloudflare_api_service.dart specifically
echo "🔎 ANALYZING cloudflare_api_service.dart:"
echo "─────────────────────────────────────────────────────────────"
if [ -f "lib/services/cloudflare_api_service.dart" ]; then
  echo "  Base URLs found:"
  grep -E "static String get (baseUrl|reactionsApiUrl|mediaApiUrl)" lib/services/cloudflare_api_service.dart | \
    sed 's/.*=> //g' | \
    sed "s/[';]//g" | \
    sed 's/^/    /'
else
  echo "  ❌ File not found"
fi
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ CODE ANALYSIS COMPLETE                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
