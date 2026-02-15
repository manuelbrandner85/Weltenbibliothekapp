#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# 🚀 CLOUDFLARE BACKEND v3.2 - DEPLOYMENT SCRIPT
# ═══════════════════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════════════════════"
echo "🚀 WELTENBIBLIOTHEK BACKEND v3.2 - DEPLOYMENT"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found!"
    echo ""
    echo "📦 Installing Wrangler..."
    npm install -g wrangler
    echo "✅ Wrangler installed!"
    echo ""
fi

# Check if logged in
echo "🔐 Checking Cloudflare login..."
if ! wrangler whoami &> /dev/null; then
    echo "❌ Not logged in to Cloudflare!"
    echo ""
    echo "🔑 Please login:"
    wrangler login
    echo ""
fi

# Get account ID
echo "📍 Your Cloudflare Account:"
wrangler whoami
echo ""

# Check if account_id is set in wrangler-v3.2.toml
ACCOUNT_ID=$(grep "account_id" wrangler-v3.2.toml | grep -v "^#" | cut -d'"' -f2)

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" == "" ]; then
    echo "⚠️  Account ID not set in wrangler-v3.2.toml!"
    echo ""
    echo "📝 Please edit wrangler-v3.2.toml and add your account_id:"
    echo "   account_id = \"YOUR_CLOUDFLARE_ACCOUNT_ID\""
    echo ""
    read -p "Press Enter after editing wrangler-v3.2.toml..."
fi

# Deploy
echo "🚀 Deploying Backend v3.2..."
echo ""
wrangler deploy -c wrangler-v3.2.toml

if [ $? -eq 0 ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "✅ DEPLOYMENT SUCCESSFUL!"
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "📍 Your Worker URL:"
    echo "   https://weltenbibliothek-backend-v3-2.YOUR-USERNAME.workers.dev"
    echo ""
    echo "🧪 Next Steps:"
    echo "   1. Copy your Worker URL"
    echo "   2. Run test suite:"
    echo "      ./test_backend_v3.2.sh <YOUR_WORKER_URL>"
    echo ""
    echo "📚 Documentation:"
    echo "   - BACKEND_V3.2_DEPLOYMENT.md"
    echo "   - FLUTTER_INTEGRATION_GUIDE.md"
    echo ""
else
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "❌ DEPLOYMENT FAILED"
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "   1. Check account_id in wrangler-v3.2.toml"
    echo "   2. Verify Cloudflare login: wrangler whoami"
    echo "   3. Check logs: wrangler tail -c wrangler-v3.2.toml"
    echo ""
fi
