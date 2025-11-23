#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# 🚀 CLOUDFLARE TOKEN-BASED DEPLOYMENT
# ═══════════════════════════════════════════════════════════════
# Automated deployment using Cloudflare API Token
# NO BROWSER LOGIN REQUIRED!
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
print_banner() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                                                               ║"
  echo "║        🔐 TOKEN-BASED CLOUDFLARE DEPLOYMENT 🚀                ║"
  echo "║                                                               ║"
  echo "║              No Browser Login Required!                       ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
}

# Print functions
print_step() { echo -e "${BLUE}▶ ${NC}$1"; }
print_success() { echo -e "${GREEN}✅ ${NC}$1"; }
print_error() { echo -e "${RED}❌ ${NC}$1"; }
print_warning() { echo -e "${YELLOW}⚠️  ${NC}$1"; }
print_info() { echo -e "${CYAN}ℹ ${NC}$1"; }

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

# Check if token is provided as argument or environment variable
CLOUDFLARE_API_TOKEN="${1:-${CLOUDFLARE_API_TOKEN:-}}"

if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  print_error "Cloudflare API Token not provided!"
  echo ""
  print_info "Usage:"
  echo "  Method 1: $0 <YOUR_API_TOKEN>"
  echo "  Method 2: export CLOUDFLARE_API_TOKEN='<YOUR_API_TOKEN>' && $0"
  echo ""
  print_info "Get your token from: https://dash.cloudflare.com/profile/api-tokens"
  echo ""
  exit 1
fi

# ═══════════════════════════════════════════════════════════════
# STEP 0: Prerequisites
# ═══════════════════════════════════════════════════════════════

check_prerequisites() {
  print_step "STEP 0: Checking Prerequisites"
  echo ""
  
  # Check wrangler
  if ! command -v wrangler &> /dev/null; then
    print_error "wrangler CLI not found"
    echo ""
    print_info "Install wrangler:"
    echo "  npm install -g wrangler"
    echo ""
    exit 1
  fi
  print_success "wrangler CLI found: $(wrangler --version 2>&1 | head -1)"
  
  # Check required files
  if [ ! -f "wrangler.toml" ]; then
    print_error "wrangler.toml not found"
    exit 1
  fi
  
  if [ ! -f "api_endpoints_extended.js" ]; then
    print_error "api_endpoints_extended.js not found"
    exit 1
  fi
  
  if [ ! -f "database_schema_extended.sql" ]; then
    print_error "database_schema_extended.sql not found"
    exit 1
  fi
  
  print_success "All required files present"
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 1: Verify Token
# ═══════════════════════════════════════════════════════════════

verify_token() {
  print_step "STEP 1: Verifying API Token"
  echo ""
  
  # Set environment variable for wrangler
  export CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN"
  
  # Test token by getting account info
  if wrangler whoami &> /dev/null; then
    ACCOUNT_EMAIL=$(wrangler whoami 2>&1 | grep "logged in" | awk '{print $NF}' || echo "N/A")
    print_success "Token verified successfully!"
    print_success "Account: $ACCOUNT_EMAIL"
  else
    print_error "Token verification failed!"
    print_warning "Please check your token has the correct permissions:"
    echo "  - Workers Scripts: Edit"
    echo "  - Workers KV Storage: Edit"
    echo "  - D1: Edit"
    echo ""
    exit 1
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 2: Get Account ID
# ═══════════════════════════════════════════════════════════════

get_account_id() {
  print_step "STEP 2: Getting Account ID"
  echo ""
  
  # Try to get account ID from whoami
  ACCOUNT_ID=$(wrangler whoami 2>&1 | grep -A1 "Account ID" | tail -1 | awk '{print $1}' | tr -d '│' | xargs)
  
  if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" == "Account" ]; then
    print_warning "Could not auto-detect Account ID"
    echo ""
    print_info "Please enter your Cloudflare Account ID manually:"
    echo "(Find it in Cloudflare Dashboard → Workers & Pages → Overview)"
    read -p "Account ID: " ACCOUNT_ID
  fi
  
  print_success "Account ID: $ACCOUNT_ID"
  
  # Update wrangler.toml
  if grep -q "YOUR_ACCOUNT_ID" wrangler.toml; then
    sed -i "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" wrangler.toml
    print_success "Updated wrangler.toml with Account ID"
  else
    print_info "Account ID already configured in wrangler.toml"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 3: Create D1 Database
# ═══════════════════════════════════════════════════════════════

create_d1_database() {
  print_step "STEP 3: Creating D1 Database"
  echo ""
  
  DB_NAME="weltenbibliothek_db"
  
  # Check if database exists
  if wrangler d1 list 2>&1 | grep -q "$DB_NAME"; then
    print_info "Database '$DB_NAME' already exists"
    DB_ID=$(wrangler d1 list 2>&1 | grep "$DB_NAME" | awk '{print $1}')
    print_success "Using existing database: $DB_ID"
  else
    print_info "Creating new D1 database..."
    DB_OUTPUT=$(wrangler d1 create "$DB_NAME" 2>&1)
    
    # Extract database ID
    DB_ID=$(echo "$DB_OUTPUT" | grep "database_id" | awk '{print $3}' | tr -d '"' | tr -d ',' | head -1)
    
    if [ -z "$DB_ID" ]; then
      print_error "Failed to create D1 database"
      echo "$DB_OUTPUT"
      exit 1
    fi
    
    print_success "Database created: $DB_ID"
  fi
  
  # Update wrangler.toml
  if grep -q "YOUR_D1_DATABASE_ID" wrangler.toml; then
    sed -i "s/YOUR_D1_DATABASE_ID/$DB_ID/g" wrangler.toml
    print_success "Updated wrangler.toml with Database ID"
  fi
  
  # Apply schema
  print_info "Applying database schema..."
  if wrangler d1 execute "$DB_NAME" --file=database_schema_extended.sql 2>&1 | grep -q "Success\|Executed"; then
    print_success "Database schema applied"
  else
    print_warning "Schema may have failed (check if tables already exist)"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 4: Create KV Namespace
# ═══════════════════════════════════════════════════════════════

create_kv_namespace() {
  print_step "STEP 4: Creating KV Namespace"
  echo ""
  
  KV_NAME="PLAYLISTS_KV"
  
  # Check if namespace exists
  if wrangler kv:namespace list 2>&1 | grep -q "$KV_NAME"; then
    print_info "KV Namespace '$KV_NAME' already exists"
    KV_ID=$(wrangler kv:namespace list 2>&1 | grep "$KV_NAME" | awk '{print $1}' | head -1)
    print_success "Using existing namespace: $KV_ID"
  else
    print_info "Creating new KV namespace..."
    KV_OUTPUT=$(wrangler kv:namespace create "$KV_NAME" 2>&1)
    
    # Extract KV ID
    KV_ID=$(echo "$KV_OUTPUT" | grep "id =" | awk '{print $3}' | tr -d '"' | tr -d ',' | head -1)
    
    if [ -z "$KV_ID" ]; then
      print_error "Failed to create KV namespace"
      echo "$KV_OUTPUT"
      exit 1
    fi
    
    print_success "KV Namespace created: $KV_ID"
  fi
  
  # Update wrangler.toml
  if grep -q "YOUR_PLAYLISTS_KV_ID" wrangler.toml; then
    sed -i "s/YOUR_PLAYLISTS_KV_ID/$KV_ID/g" wrangler.toml
    print_success "Updated wrangler.toml with KV Namespace ID"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 5: Configure Secrets
# ═══════════════════════════════════════════════════════════════

configure_secrets() {
  print_step "STEP 5: Configuring Secrets"
  echo ""
  
  print_warning "Secrets configuration required for production deployment"
  echo ""
  
  read -p "$(echo -e ${YELLOW}Do you want to configure secrets now? [y/N]:${NC} )" -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    
    # JWT Secret
    print_info "Generating JWT Secret..."
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || echo "")
    
    if [ -n "$JWT_SECRET" ]; then
      echo "$JWT_SECRET" | wrangler secret put JWT_SECRET
      print_success "JWT_SECRET configured"
    else
      print_warning "OpenSSL not available, skipping JWT_SECRET"
    fi
    
    echo ""
    print_info "For VAPID keys (Push Notifications):"
    echo "  Run: npx web-push generate-vapid-keys"
    echo "  Then: echo 'PUBLIC_KEY' | wrangler secret put VAPID_PUBLIC_KEY"
    echo "        echo 'PRIVATE_KEY' | wrangler secret put VAPID_PRIVATE_KEY"
    
  else
    print_info "Skipping secrets configuration"
    print_warning "Remember to configure secrets before production use!"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 6: Deploy Worker
# ═══════════════════════════════════════════════════════════════

deploy_worker() {
  print_step "STEP 6: Deploying Worker"
  echo ""
  
  print_info "Starting deployment to Cloudflare..."
  echo ""
  
  if wrangler deploy 2>&1; then
    echo ""
    print_success "Worker deployed successfully!"
  else
    echo ""
    print_error "Deployment failed"
    exit 1
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 7: Get Worker URL
# ═══════════════════════════════════════════════════════════════

get_worker_url() {
  print_step "STEP 7: Getting Worker URL"
  echo ""
  
  # Try to get URL from deployments
  WORKER_URL=$(wrangler deployments list 2>&1 | grep "https://" | head -1 | awk '{print $1}' || echo "")
  
  if [ -z "$WORKER_URL" ]; then
    # Fallback: construct URL from account
    WORKER_NAME=$(grep "^name = " wrangler.toml | awk -F'"' '{print $2}')
    print_warning "Could not auto-detect worker URL"
    print_info "Worker name: $WORKER_NAME"
    print_info "URL should be: https://${WORKER_NAME}.<account>.workers.dev"
  else
    print_success "Worker URL: $WORKER_URL"
    export WORKER_URL
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 8: Health Check
# ═══════════════════════════════════════════════════════════════

health_check() {
  print_step "STEP 8: Health Check"
  echo ""
  
  if [ -z "${WORKER_URL:-}" ]; then
    print_warning "Worker URL not available, skipping health check"
    print_info "Test manually: https://your-worker.workers.dev/health"
    echo ""
    return
  fi
  
  HEALTH_URL="${WORKER_URL}/health"
  print_info "Testing: $HEALTH_URL"
  echo ""
  
  # Wait a bit for deployment to propagate
  sleep 3
  
  if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s "$HEALTH_URL" 2>/dev/null || echo '{"status":"error"}')
    
    if echo "$RESPONSE" | grep -q '"status":"healthy"'; then
      print_success "Health check PASSED! ✅"
      echo ""
      echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
      print_warning "Health check returned unexpected response"
      echo ""
      echo "Response: $RESPONSE"
      echo ""
      print_info "This may be normal if deployment is still propagating (can take 30-60 seconds)"
    fi
  else
    print_warning "curl not available, test manually"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 9: Summary
# ═══════════════════════════════════════════════════════════════

print_summary() {
  print_step "DEPLOYMENT SUMMARY"
  echo ""
  
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                                                               ║${NC}"
  echo -e "${GREEN}║           ✅ DEPLOYMENT SUCCESSFUL! ✅                         ║${NC}"
  echo -e "${GREEN}║                                                               ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  print_success "Deployment Details:"
  echo ""
  
  if [ -n "${WORKER_URL:-}" ]; then
    echo "  🌐 Worker URL:        $WORKER_URL"
    echo "  🏥 Health Check:      ${WORKER_URL}/health"
    echo "  🔔 Push API:          ${WORKER_URL}/api/push/*"
    echo "  🎵 Playlists API:     ${WORKER_URL}/api/playlists/*"
    echo "  📊 Analytics API:     ${WORKER_URL}/api/analytics/*"
  else
    echo "  🌐 Worker deployed to Cloudflare Workers platform"
    echo "  Check URL in: wrangler deployments list"
  fi
  
  echo ""
  print_success "Next Steps:"
  echo ""
  echo "  1. Test health endpoint"
  echo "  2. Update Flutter app baseUrl"
  echo "  3. Configure monitoring (UptimeRobot)"
  echo "  4. Run verification tests"
  echo ""
  
  if [ -n "${WORKER_URL:-}" ]; then
    print_info "Verify deployment:"
    echo "  ./verify_deployment.sh $WORKER_URL"
    echo ""
  fi
  
  print_info "View logs:"
  echo "  wrangler tail weltenbibliothek-api"
  echo ""
  
  print_info "Rollback (if needed):"
  echo "  wrangler rollback weltenbibliothek-api"
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════

main() {
  print_banner
  
  # Confirmation
  echo -e "${YELLOW}This script will deploy your Weltenbibliothek API using the provided token.${NC}"
  echo ""
  read -p "$(echo -e ${YELLOW}Do you want to proceed? [y/N]:${NC} )" -n 1 -r
  echo
  echo ""
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
  fi
  
  # Execute steps
  check_prerequisites
  verify_token
  get_account_id
  create_d1_database
  create_kv_namespace
  configure_secrets
  deploy_worker
  get_worker_url
  health_check
  print_summary
  
  echo -e "${GREEN}🎉 Deployment Complete! 🎉${NC}"
  echo ""
}

# Run main function
main "$@"
