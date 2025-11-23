#!/bin/bash

# WebRTC Signaling Server - Cloudflare API Deployment
# Alternative deployment method using Cloudflare API

set -e

echo "🚀 WebRTC Signaling Server - API Deployment"
echo "==========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check for Cloudflare credentials
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${RED}❌ Missing Cloudflare credentials!${NC}"
    echo ""
    echo "Please set the following environment variables:"
    echo ""
    echo "export CLOUDFLARE_ACCOUNT_ID='your-account-id'"
    echo "export CLOUDFLARE_API_TOKEN='your-api-token'"
    echo ""
    echo "Get your credentials from:"
    echo "https://dash.cloudflare.com/profile/api-tokens"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Cloudflare credentials found${NC}"
echo ""

# Prepare deployment payload
echo -e "${YELLOW}📦 Preparing deployment payload...${NC}"

# Read worker script
WORKER_SCRIPT=$(cat /home/user/webrtc_signaling_worker.js)

# Create metadata JSON
METADATA='{
  "main_module": "webrtc_signaling_worker.js",
  "bindings": [
    {
      "type": "durable_object_namespace",
      "name": "WEBRTC_ROOMS",
      "class_name": "WebRTCRoom",
      "script_name": "weltenbibliothek-webrtc-signaling"
    }
  ],
  "compatibility_date": "2024-11-20",
  "compatibility_flags": [],
  "usage_model": "bundled"
}'

# Create form data
cat > /tmp/worker_upload.json <<EOF
{
  "metadata": $METADATA,
  "script": $(echo "$WORKER_SCRIPT" | jq -Rs .)
}
EOF

echo -e "${GREEN}✅ Payload prepared${NC}"
echo ""

# Deploy via API
echo -e "${YELLOW}📤 Deploying to Cloudflare...${NC}"

RESPONSE=$(curl -s -X PUT \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts/weltenbibliothek-webrtc-signaling" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/worker_upload.json)

echo "$RESPONSE" | jq .

# Check deployment status
if echo "$RESPONSE" | jq -e '.success' > /dev/null; then
    echo ""
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}🎉 WebRTC Signaling Server Deployed!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${YELLOW}🔌 WebSocket URL:${NC}"
    echo "   wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws"
    echo ""
    echo -e "${YELLOW}📍 Worker URL:${NC}"
    echo "   https://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Deployment failed!${NC}"
    echo ""
    echo "Error details:"
    echo "$RESPONSE" | jq .
    exit 1
fi

# Cleanup
rm /tmp/worker_upload.json

echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Test WebSocket: wscat -c wss://weltenbibliothek-webrtc-signaling.brandy13062.workers.dev/ws/test-room"
echo "2. Update Flutter app WebRTC service"
echo "3. Rebuild APK"
echo ""
