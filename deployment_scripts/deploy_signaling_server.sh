#!/bin/bash

# WebRTC Signaling Server Deployment Script
# Deploys Cloudflare Worker with Durable Objects

set -e

echo "🚀 WebRTC Signaling Server Deployment"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ Wrangler CLI not found!${NC}"
    echo ""
    echo "📦 Installing Wrangler..."
    npm install -g wrangler
fi

echo -e "${GREEN}✅ Wrangler found${NC}"
echo ""

# Login to Cloudflare
echo -e "${YELLOW}🔐 Cloudflare Login${NC}"
echo "Please follow the instructions to login to Cloudflare..."
echo ""

wrangler login

echo ""
echo -e "${GREEN}✅ Logged in to Cloudflare${NC}"
echo ""

# Deploy Worker
echo -e "${YELLOW}📤 Deploying Worker...${NC}"
echo ""

cd /home/user
wrangler deploy

echo ""
echo -e "${GREEN}✅ Deployment successful!${NC}"
echo ""

# Get Worker URL
WORKER_URL=$(wrangler deployments list --name weltenbibliothek-webrtc-signaling 2>&1 | grep -oE 'https://[^ ]+' | head -1)

if [ -z "$WORKER_URL" ]; then
    WORKER_URL="https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}📍 Worker URL:${NC}"
echo "   $WORKER_URL"
echo ""
echo -e "${YELLOW}🔌 WebSocket URL:${NC}"
echo "   wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws"
echo ""
echo -e "${YELLOW}🏥 Health Check:${NC}"
echo "   $WORKER_URL/health"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Test WebSocket connection"
echo "2. Update Flutter app with new WebSocket URL"
echo "3. Rebuild APK with production signaling server"
echo ""
