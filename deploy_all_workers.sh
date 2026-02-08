#!/bin/bash
# ============================================================================
# WELTENBIBLIOTHEK - DEPLOY ALL WORKERS
# ============================================================================
# This script deploys all fixed Workers to Cloudflare
# ============================================================================

set -e  # Exit on error

echo "🚀 WELTENBIBLIOTHEK - WORKERS DEPLOYMENT"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}❌ Error: wrangler CLI not found${NC}"
    echo "Install: npm install -g wrangler"
    exit 1
fi

echo -e "${GREEN}✅ Wrangler CLI found${NC}"
echo ""

# Function to deploy a worker
deploy_worker() {
    local name=$1
    local config=$2
    local url=$3
    
    echo "================================================"
    echo "Deploying: $name"
    echo "Config: $config"
    echo "================================================"
    
    if [ ! -f "$config" ]; then
        echo -e "${RED}❌ Error: Config file not found: $config${NC}"
        return 1
    fi
    
    echo "Running: wrangler deploy --config $config"
    if wrangler deploy --config "$config"; then
        echo -e "${GREEN}✅ Successfully deployed: $name${NC}"
        
        # Test deployment
        echo "Testing: $url"
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>&1)
        
        if [ "$http_code" = "200" ]; then
            echo -e "${GREEN}✅ Worker is responding (HTTP $http_code)${NC}"
        else
            echo -e "${YELLOW}⚠️  Worker deployed but returned HTTP $http_code${NC}"
        fi
        
        # Test health endpoint
        echo "Testing: $url/health"
        health_code=$(curl -s -o /dev/null -w "%{http_code}" "$url/health" 2>&1)
        
        if [ "$health_code" = "200" ]; then
            echo -e "${GREEN}✅ Health endpoint is working (HTTP $health_code)${NC}"
        else
            echo -e "${YELLOW}⚠️  Health endpoint returned HTTP $health_code${NC}"
        fi
        
    else
        echo -e "${RED}❌ Failed to deploy: $name${NC}"
        return 1
    fi
    
    echo ""
}

# Deploy workers
echo "Starting deployments..."
echo ""

# 1. Main API
deploy_worker \
    "weltenbibliothek-api" \
    "wrangler_main_api.toml" \
    "https://weltenbibliothek-api.brandy13062.workers.dev"

# 2. Recherche Engine
deploy_worker \
    "recherche-engine" \
    "wrangler_recherche.toml" \
    "https://recherche-engine.brandy13062.workers.dev"

# 3. Community API
deploy_worker \
    "weltenbibliothek-community-api" \
    "wrangler_community.toml" \
    "https://weltenbibliothek-community-api.brandy13062.workers.dev"

echo "================================================"
echo "📊 DEPLOYMENT SUMMARY"
echo "================================================"
echo ""

# Test all workers
workers=(
    "weltenbibliothek-api:https://weltenbibliothek-api.brandy13062.workers.dev"
    "recherche-engine:https://recherche-engine.brandy13062.workers.dev"
    "weltenbibliothek-community-api:https://weltenbibliothek-community-api.brandy13062.workers.dev"
    "weltenbibliothek-group-tools:https://weltenbibliothek-group-tools.brandy13062.workers.dev"
    "weltenbibliothek-media-api:https://weltenbibliothek-media-api.brandy13062.workers.dev"
    "weltenbibliothek-chat-reactions:https://weltenbibliothek-chat-reactions.brandy13062.workers.dev"
)

echo "Worker Status:"
echo ""

for worker_info in "${workers[@]}"; do
    IFS=':' read -r name url <<< "$worker_info"
    
    printf "%-35s " "$name"
    
    # Test root
    root_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>&1)
    
    # Test health
    health_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url/health" 2>&1)
    
    if [ "$root_code" = "200" ] && [ "$health_code" = "200" ]; then
        echo -e "${GREEN}✅ ONLINE (Root: $root_code, Health: $health_code)${NC}"
    elif [ "$root_code" = "200" ]; then
        echo -e "${YELLOW}⚠️  PARTIAL (Root: $root_code, Health: $health_code)${NC}"
    else
        echo -e "${RED}❌ OFFLINE (Root: $root_code, Health: $health_code)${NC}"
    fi
done

echo ""
echo "================================================"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE${NC}"
echo "================================================"
echo ""
echo "📝 Next steps:"
echo "1. Test workers manually with curl"
echo "2. Update Flutter app if needed (should work automatically)"
echo "3. Monitor worker logs: wrangler tail <worker-name>"
echo "4. Check Cloudflare Dashboard for analytics"
echo ""
echo "🔗 Cloudflare Dashboard:"
echo "https://dash.cloudflare.com/3472f5994537c3a30c5caeaff4de21fb"
echo ""
