#!/bin/bash

# 🚀 Weltenbibliothek - Automated Deployment Script
# Deploys Flutter Web App + Cloudflare Worker

set -e  # Exit on error

echo "════════════════════════════════════════════════════════"
echo "🚀 WELTENBIBLIOTHEK - AUTOMATED DEPLOYMENT"
echo "════════════════════════════════════════════════════════"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/user/flutter_app"
PORT=5060

# Step 1: Git Status Check
echo -e "${BLUE}📊 Step 1: Git Status Check${NC}"
cd "$PROJECT_DIR"
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}⚠️  Uncommitted changes detected${NC}"
    git status -s
    echo ""
    read -p "Commit changes? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Commit message: " commit_msg
        git add -A
        git commit -m "$commit_msg"
        echo -e "${GREEN}✅ Changes committed${NC}"
    fi
else
    echo -e "${GREEN}✅ Git status clean${NC}"
fi
echo ""

# Step 2: Flutter Analyze
echo -e "${BLUE}📊 Step 2: Flutter Analyze${NC}"
flutter analyze --no-fatal-infos
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter analyze passed${NC}"
else
    echo -e "${RED}❌ Flutter analyze failed${NC}"
    exit 1
fi
echo ""

# Step 3: Kill existing server
echo -e "${BLUE}🔧 Step 3: Stop Existing Server${NC}"
lsof -ti:$PORT | xargs -r kill -9 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Server stopped${NC}"
echo ""

# Step 4: Clean build
echo -e "${BLUE}🧹 Step 4: Clean Build Cache${NC}"
rm -rf build/web .dart_tool/build_cache
echo -e "${GREEN}✅ Cache cleared${NC}"
echo ""

# Step 5: Flutter build
echo -e "${BLUE}🔨 Step 5: Build Flutter Web${NC}"
flutter build web --release
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter build successful${NC}"
else
    echo -e "${RED}❌ Flutter build failed${NC}"
    exit 1
fi
echo ""

# Step 6: Start server
echo -e "${BLUE}🌐 Step 6: Start Web Server${NC}"
cd build/web
python3 -m http.server $PORT --bind 0.0.0.0 > /tmp/weltenbibliothek_server.log 2>&1 &
SERVER_PID=$!
sleep 3

# Check if server is running
if curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT | grep -q "200"; then
    echo -e "${GREEN}✅ Web server started (PID: $SERVER_PID)${NC}"
else
    echo -e "${RED}❌ Web server failed to start${NC}"
    exit 1
fi
echo ""

# Step 7: Generate deployment info
echo -e "${BLUE}📝 Step 7: Generate Deployment Info${NC}"
cd "$PROJECT_DIR"

cat > DEPLOYMENT_INFO.txt << EOF
═══════════════════════════════════════════════════════════
🚀 WELTENBIBLIOTHEK - DEPLOYMENT INFO
═══════════════════════════════════════════════════════════

Deployment Date: $(date '+%Y-%m-%d %H:%M:%S')
Git Commit: $(git rev-parse --short HEAD)
Git Branch: $(git branch --show-current)

Flutter Version: $(flutter --version | head -1)
Dart Version: $(dart --version 2>&1 | head -1)

Server Info:
- Port: $PORT
- PID: $SERVER_PID
- Log: /tmp/weltenbibliothek_server.log

Build Info:
- Build Mode: Release
- Web Target: build/web
- Cache: Cleared

Status:
✅ Flutter Analyze: Passed
✅ Build: Successful
✅ Server: Running

Next Steps:
1. Test the app at the URL above
2. Deploy Cloudflare Worker (optional):
   cd cloudflare/
   wrangler deploy
3. Monitor logs:
   tail -f /tmp/weltenbibliothek_server.log

═══════════════════════════════════════════════════════════
EOF

cat DEPLOYMENT_INFO.txt
echo ""

# Step 8: Display URLs
echo -e "${BLUE}📡 Step 8: Access URLs${NC}"
echo -e "${GREEN}Local URL:${NC} http://localhost:$PORT"
echo -e "${GREEN}Public URL:${NC} https://5060-i6i6g94lpb9am6y5rb4gp-2e77fc33.sandbox.novita.ai"
echo ""

# Step 9: Optional - Deploy Cloudflare Worker
echo -e "${BLUE}☁️  Step 9: Cloudflare Worker Deployment (Optional)${NC}"
read -p "Deploy Cloudflare Worker? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v wrangler &> /dev/null; then
        cd "$PROJECT_DIR/cloudflare"
        echo -e "${YELLOW}📦 Deploying Cloudflare Worker...${NC}"
        wrangler deploy
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Cloudflare Worker deployed${NC}"
        else
            echo -e "${RED}❌ Cloudflare Worker deployment failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Wrangler CLI not installed${NC}"
        echo "Install with: npm install -g wrangler"
    fi
else
    echo -e "${YELLOW}⏭️  Skipping Cloudflare deployment${NC}"
fi
echo ""

# Final Summary
echo "════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}Quick Actions:${NC}"
echo "  View logs: tail -f /tmp/weltenbibliothek_server.log"
echo "  Stop server: kill $SERVER_PID"
echo "  Restart: ./deploy.sh"
echo ""
echo -e "${GREEN}🎉 Happy Testing!${NC}"
