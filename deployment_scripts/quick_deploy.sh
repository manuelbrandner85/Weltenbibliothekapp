#!/bin/bash

# Quick Deploy Script - WebRTC Signaling Server
# One-command deployment to Cloudflare Workers

set -e

cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║  WebRTC Signaling Server - Quick Deploy                 ║
║  Cloudflare Workers + Durable Objects                   ║
╚══════════════════════════════════════════════════════════╝
EOF

echo ""
echo "🚀 Starting deployment process..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check Node.js
echo -e "${BLUE}[1/6]${NC} Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found! Please install Node.js first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
echo ""

# Install/Check Wrangler
echo -e "${BLUE}[2/6]${NC} Checking Wrangler CLI..."
if ! command -v wrangler &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Wrangler...${NC}"
    npm install -g wrangler
fi
echo -e "${GREEN}✅ Wrangler ready: $(wrangler --version)${NC}"
echo ""

# Login to Cloudflare
echo -e "${BLUE}[3/6]${NC} Cloudflare Login..."
echo -e "${YELLOW}Please follow the browser login flow...${NC}"
echo ""
wrangler login

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Login failed! Please try again.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Logged in successfully${NC}"
echo ""

# Create package.json if not exists
echo -e "${BLUE}[4/6]${NC} Preparing deployment files..."
cd /home/user

if [ ! -f package.json ]; then
    cat > package.json <<'PACKAGE'
{
  "name": "webrtc-signaling-server",
  "version": "1.0.0",
  "description": "WebRTC Signaling Server for Flutter App",
  "main": "webrtc_signaling_worker.js",
  "scripts": {
    "deploy": "wrangler deploy"
  },
  "keywords": ["webrtc", "signaling", "cloudflare"],
  "author": "",
  "license": "MIT"
}
PACKAGE
fi

echo -e "${GREEN}✅ Files prepared${NC}"
echo ""

# Deploy Worker
echo -e "${BLUE}[5/6]${NC} Deploying to Cloudflare..."
echo ""
wrangler deploy

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ Deployment failed!${NC}"
    echo ""
    echo "Possible issues:"
    echo "1. Durable Objects not enabled (needs Workers Paid plan)"
    echo "2. Account verification required"
    echo "3. Network connection issues"
    echo ""
    echo "Please check Cloudflare dashboard or try manual deployment."
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Deployment successful!${NC}"
echo ""

# Test deployment
echo -e "${BLUE}[6/6]${NC} Testing deployment..."
echo ""

WORKER_URL="https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev"

echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "$WORKER_URL/health")

if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "${GREEN}✅ Health check passed!${NC}"
    echo ""
    echo "$HEALTH_RESPONSE" | jq . 2>/dev/null || echo "$HEALTH_RESPONSE"
else
    echo -e "${YELLOW}⚠️ Unexpected health check response${NC}"
    echo "$HEALTH_RESPONSE"
fi

echo ""
echo ""

# Print success message
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$(echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(echo -e "${YELLOW}📍 Worker URL:${NC}")
   $WORKER_URL

$(echo -e "${YELLOW}🔌 WebSocket URL:${NC}")
   wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws

$(echo -e "${YELLOW}🏥 Health Check:${NC}")
   $WORKER_URL/health

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(echo -e "${YELLOW}📝 Next Steps:${NC}")

1. Test WebSocket Connection:
   wscat -c wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws/test

2. Flutter app is already configured with this URL!
   No changes needed to lib/services/webrtc_service.dart

3. Test the app:
   - Open web preview or APK
   - Start video call in a chat room
   - Check Cloudflare logs for signaling messages

4. Monitor your deployment:
   https://dash.cloudflare.com/workers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(echo -e "${GREEN}✅ Your WebRTC Signaling Server is live!${NC}")

For troubleshooting, see: /home/user/SIGNALING_SERVER_DEPLOYMENT.md

EOF
