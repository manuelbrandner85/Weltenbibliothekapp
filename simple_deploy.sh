#!/bin/bash
# Weltenbibliothek - Simple Deployment (ohne Docker)
# Baut und deployed Backend + Flutter App direkt

set -e  # Exit on error

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   🚀 WELTENBIBLIOTHEK - SIMPLE DEPLOYMENT                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_DIR="/home/user/flutter_app"
BACKEND_DIR="$PROJECT_DIR/backend"
FLUTTER_DIR="$PROJECT_DIR"

# ============================================================================
# STEP 1: BACKEND DEPENDENCIES
# ============================================================================

echo -e "${BLUE}📦 STEP 1: Backend Dependencies${NC}"
echo "----------------------------------------"

cd "$BACKEND_DIR"

if [ -f "requirements.txt" ]; then
    echo -e "${BLUE}📥 Installing Python dependencies...${NC}"
    pip3 install --quiet -r requirements.txt
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Dependencies installed${NC}"
    else
        echo -e "${RED}❌ Dependency installation failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  No requirements.txt found${NC}"
fi

echo ""

# ============================================================================
# STEP 2: BACKEND START
# ============================================================================

echo -e "${BLUE}📦 STEP 2: Backend Server${NC}"
echo "----------------------------------------"

# Stop alte Backend-Prozesse
echo -e "${BLUE}🛑 Stopping old backend processes...${NC}"
pkill -f "deep_research_api.py" 2>/dev/null || true
sleep 1

# Starte neuen Backend-Server
echo -e "${BLUE}🚀 Starting Backend Server...${NC}"
cd "$BACKEND_DIR"
python3 deep_research_api.py > backend.log 2>&1 &
BACKEND_PID=$!

echo -e "   PID: ${BACKEND_PID}"
echo -e "   Log: $BACKEND_DIR/backend.log"

# Wait for backend
echo -e "${BLUE}⏳ Waiting for backend (max 10s)...${NC}"
for i in {1..10}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is healthy!${NC}"
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

echo ""

# ============================================================================
# STEP 3: FLUTTER BUILD
# ============================================================================

echo -e "${BLUE}📦 STEP 3: Flutter Build${NC}"
echo "----------------------------------------"

cd "$FLUTTER_DIR"

# Clean
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
rm -rf build/web .dart_tool/build_cache

# Build
echo -e "${BLUE}🔨 Building Flutter Web (Release)...${NC}"
flutter build web --release \
  --dart-define=flutter.inspector.structuredErrors=false \
  --dart-define=debugShowCheckedModeBanner=false

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter Web Build erfolgreich${NC}"
    WEB_SIZE=$(du -sh "build/web" | cut -f1)
    echo -e "   Size: ${WEB_SIZE}"
else
    echo -e "${RED}❌ Flutter Build fehlgeschlagen${NC}"
    exit 1
fi

echo ""

# ============================================================================
# STEP 4: FLUTTER SERVE
# ============================================================================

echo -e "${BLUE}📦 STEP 4: Flutter Web Server${NC}"
echo "----------------------------------------"

# Stop alte Web-Server
echo -e "${BLUE}🛑 Stopping old web server...${NC}"
lsof -ti:5060 | xargs -r kill -9 2>/dev/null || true
sleep 1

# Starte neuen Web-Server
echo -e "${BLUE}🌐 Starting Web Server...${NC}"
cd "$FLUTTER_DIR/build/web"

python3 -c "
import http.server, socketserver
class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()
with socketserver.TCPServer(('0.0.0.0', 5060), CORSRequestHandler) as httpd:
    print('${GREEN}✅ Web Server running on port 5060${NC}')
    httpd.serve_forever()
" > web_server.log 2>&1 &
WEB_PID=$!

echo -e "   PID: ${WEB_PID}"
echo -e "   Log: $FLUTTER_DIR/build/web/web_server.log"

# Wait for web server
echo -e "${BLUE}⏳ Waiting for web server (max 5s)...${NC}"
for i in {1..5}; do
    if curl -s http://localhost:5060 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Web server is running!${NC}"
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   ✅ DEPLOYMENT COMPLETE                                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}🌐 Backend API:${NC}"
echo "   http://localhost:8080"
echo "   Health: http://localhost:8080/health"
echo "   PID: ${BACKEND_PID}"
echo ""
echo -e "${GREEN}📱 Flutter Web:${NC}"
echo "   http://localhost:5060"
echo "   Preview: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai"
echo "   PID: ${WEB_PID}"
echo ""
echo -e "${BLUE}📊 Processes:${NC}"
ps aux | grep -E "(deep_research_api|python3.*5060)" | grep -v grep || echo "   (none)"
echo ""
echo -e "${YELLOW}💡 Logs:${NC}"
echo "   Backend: tail -f $BACKEND_DIR/backend.log"
echo "   Web: tail -f $FLUTTER_DIR/build/web/web_server.log"
echo ""
echo -e "${YELLOW}🛑 Stop Services:${NC}"
echo "   kill ${BACKEND_PID} ${WEB_PID}"
echo ""
