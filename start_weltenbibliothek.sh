#!/bin/bash
# Weltenbibliothek - Quick Start Script
# Startet Backend + Flutter App

set -e  # Exit on error

echo "============================================================"
echo "🌐 WELTENBIBLIOTHEK - DEEP RESEARCH ENGINE"
echo "============================================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if backend is already running
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Backend läuft bereits auf Port 8080${NC}"
else
    echo -e "${BLUE}🚀 Starte Backend-Server...${NC}"
    cd /home/user/flutter_app/backend
    python3 deep_research_api.py > backend.log 2>&1 &
    BACKEND_PID=$!
    echo "   → PID: $BACKEND_PID"
    echo "   → Log: /home/user/flutter_app/backend/backend.log"
    
    # Wait for backend to start
    echo -e "${BLUE}⏳ Warte auf Backend (max 10s)...${NC}"
    for i in {1..10}; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo -e "${GREEN}   ✅ Backend bereit!${NC}"
            break
        fi
        sleep 1
        echo -n "."
    done
    echo ""
fi

echo ""
echo -e "${BLUE}📱 Starte Flutter App...${NC}"
cd /home/user/flutter_app

# Clean previous builds
rm -rf build/web .dart_tool/build_cache

# Build & Serve
flutter build web --release && \
cd build/web && \
python3 -c "
import http.server, socketserver
class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()
with socketserver.TCPServer(('0.0.0.0', 5060), CORSRequestHandler) as httpd:
    print('${GREEN}✅ Flutter App läuft auf Port 5060${NC}')
    print('${GREEN}🌐 URL: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai${NC}')
    print('')
    print('${YELLOW}Drücke CTRL+C zum Beenden${NC}')
    httpd.serve_forever()
"

# Cleanup on exit
trap "echo ''; echo '🛑 Beende Services...'; kill $BACKEND_PID 2>/dev/null; echo '✅ Beendet'" EXIT
