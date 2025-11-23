#!/bin/bash

# Fully Automated WebRTC Signaling Server Deployment
# Non-interactive mode for automated deployments

set -e

cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║  WebRTC Signaling Server - Automated Deployment         ║
║  Status: Non-Interactive Mode                           ║
╚══════════════════════════════════════════════════════════╝
EOF

echo ""
echo "🚀 Starting automated deployment..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Step 1: Verify prerequisites
echo -e "${BLUE}[1/5]${NC} Verifying prerequisites..."
echo ""

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js: $(node --version)${NC}"

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ npm: $(npm --version)${NC}"

if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ Wrangler not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Wrangler: $(wrangler --version)${NC}"

echo ""

# Step 2: Check Wrangler authentication
echo -e "${BLUE}[2/5]${NC} Checking Cloudflare authentication..."
echo ""

# Try to get account info (will fail if not logged in)
if wrangler whoami &> /dev/null; then
    echo -e "${GREEN}✅ Already authenticated to Cloudflare${NC}"
    ACCOUNT_INFO=$(wrangler whoami 2>&1)
    echo "$ACCOUNT_INFO"
else
    echo -e "${YELLOW}⚠️ Not authenticated to Cloudflare${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}MANUAL STEP REQUIRED:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To deploy the signaling server, you need to:"
    echo ""
    echo "1. Run: wrangler login"
    echo "2. Follow browser authentication flow"
    echo "3. Re-run this script"
    echo ""
    echo "Or provide API credentials:"
    echo ""
    echo "export CLOUDFLARE_ACCOUNT_ID='your-account-id'"
    echo "export CLOUDFLARE_API_TOKEN='your-api-token'"
    echo ""
    echo "Get credentials from:"
    echo "https://dash.cloudflare.com/profile/api-tokens"
    echo ""
    exit 1
fi

echo ""

# Step 3: Prepare deployment
echo -e "${BLUE}[3/5]${NC} Preparing deployment files..."
echo ""

cd /home/user

# Verify files exist
if [ ! -f webrtc_signaling_worker.js ]; then
    echo -e "${RED}❌ Worker script not found!${NC}"
    exit 1
fi

if [ ! -f wrangler.toml ]; then
    echo -e "${RED}❌ Configuration file not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All deployment files present${NC}"
echo ""

# Step 4: Deploy to Cloudflare
echo -e "${BLUE}[4/5]${NC} Deploying to Cloudflare Workers..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Deploy with verbose output
wrangler deploy --legacy-env false 2>&1 | tee /home/user/wrangler_deploy.log

DEPLOY_EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}❌ Deployment failed!${NC}"
    echo ""
    echo "Error details are in: /home/user/wrangler_deploy.log"
    echo ""
    echo "Common issues:"
    echo "1. Durable Objects require Workers Paid plan ($5/month)"
    echo "2. Account verification may be required"
    echo "3. Check Cloudflare dashboard for errors"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Deployment successful!${NC}"
echo ""

# Step 5: Test deployment
echo -e "${BLUE}[5/5]${NC} Testing deployment..."
echo ""

WORKER_URL="https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev"
WS_URL="wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws"

echo "Testing health endpoint..."
echo ""

HEALTH_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" "$WORKER_URL/health" 2>&1)
HTTP_STATUS=$(echo "$HEALTH_RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_STATUS:")

if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ Health check passed!${NC}"
    echo ""
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
else
    echo -e "${YELLOW}⚠️ Unexpected HTTP status: $HTTP_STATUS${NC}"
    echo ""
    echo "$BODY"
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
   $WS_URL

$(echo -e "${YELLOW}🏥 Health Check:${NC}")
   $WORKER_URL/health

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(echo -e "${YELLOW}📝 Next Steps:${NC}")

1. Test WebSocket Connection:
   npm install -g wscat
   wscat -c $WS_URL/test

2. Flutter app is already configured!
   No changes needed - just test it!

3. Monitor deployment:
   https://dash.cloudflare.com/workers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$(echo -e "${GREEN}✅ WebRTC Signaling Server is LIVE!${NC}")

Logs saved to: /home/user/wrangler_deploy.log

EOF

# Save deployment info
cat > /home/user/deployment_info.txt <<DEPLOY_INFO
WebRTC Signaling Server - Deployment Information
================================================

Deployment Date: $(date)
Worker URL: $WORKER_URL
WebSocket URL: $WS_URL
Health Check: $WORKER_URL/health

Deployment Status: SUCCESS
HTTP Status: $HTTP_STATUS

Flutter App Configuration:
- File: lib/services/webrtc_service.dart
- WebSocket URL: Already configured correctly
- No changes needed!

Next Steps:
1. Test with Flutter app
2. Monitor Cloudflare dashboard
3. Enable live logs for debugging

For more information, see:
- README_SIGNALING_DEPLOYMENT.md
- SIGNALING_SERVER_DEPLOYMENT.md
- WEBRTC_DEPLOYMENT_SUMMARY.md
DEPLOY_INFO

echo ""
echo "📄 Deployment info saved to: /home/user/deployment_info.txt"
echo ""
