#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# 🚀 WELTENBIBLIOTHEK - QUICK DEPLOYMENT SCRIPT
# ═══════════════════════════════════════════════════════════════
# One-command deployment für Cloudflare Workers API
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
print_banner() {
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║                                                               ║"
  echo "║           🌍 WELTENBIBLIOTHEK DEPLOYMENT 🚀                   ║"
  echo "║                                                               ║"
  echo "║              Cloudflare Workers API Setup                     ║"
  echo "║                    Version 2.0.0                              ║"
  echo "║                                                               ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo ""
}

# Print functions
print_step() {
  echo -e "${BLUE}▶ ${NC}$1"
}

print_success() {
  echo -e "${GREEN}✅ ${NC}$1"
}

print_error() {
  echo -e "${RED}❌ ${NC}$1"
}

print_warning() {
  echo -e "${YELLOW}⚠️  ${NC}$1"
}

print_info() {
  echo -e "${CYAN}ℹ ${NC}$1"
}

# ═══════════════════════════════════════════════════════════════
# STEP 0: Prerequisites Check
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
  
  # Check login
  if ! wrangler whoami &> /dev/null; then
    print_error "Not logged in to Cloudflare"
    echo ""
    print_info "Login to Cloudflare:"
    echo "  wrangler login"
    echo ""
    exit 1
  fi
  
  ACCOUNT_EMAIL=$(wrangler whoami 2>&1 | grep "logged in" | awk '{print $NF}' || echo "unknown")
  print_success "Logged in as: $ACCOUNT_EMAIL"
  
  # Check files
  if [ ! -f "wrangler.toml" ]; then
    print_error "wrangler.toml not found"
    exit 1
  fi
  print_success "Configuration files present"
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 1: Account ID Setup
# ═══════════════════════════════════════════════════════════════

setup_account_id() {
  print_step "STEP 1: Cloudflare Account ID Setup"
  echo ""
  
  # Get account ID
  print_info "Fetching your Cloudflare Account ID..."
  ACCOUNT_ID=$(wrangler whoami 2>&1 | grep "Account ID" | awk '{print $NF}' | head -1)
  
  if [ -z "$ACCOUNT_ID" ]; then
    print_warning "Could not auto-detect Account ID"
    echo ""
    read -p "Enter your Cloudflare Account ID: " ACCOUNT_ID
  fi
  
  print_success "Account ID: $ACCOUNT_ID"
  
  # Update wrangler.toml
  if grep -q "YOUR_ACCOUNT_ID" wrangler.toml; then
    sed -i "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" wrangler.toml
    print_success "Updated wrangler.toml with Account ID"
  else
    print_info "Account ID already set in wrangler.toml"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 2: D1 Database Setup
# ═══════════════════════════════════════════════════════════════

setup_d1_database() {
  print_step "STEP 2: D1 Database Setup"
  echo ""
  
  DB_NAME="weltenbibliothek_db"
  
  # Check if database already exists
  if wrangler d1 list 2>&1 | grep -q "$DB_NAME"; then
    print_info "Database '$DB_NAME' already exists"
    DB_ID=$(wrangler d1 list 2>&1 | grep "$DB_NAME" | awk '{print $1}')
    print_success "Using existing database: $DB_ID"
  else
    print_info "Creating D1 database: $DB_NAME"
    DB_OUTPUT=$(wrangler d1 create "$DB_NAME" 2>&1)
    echo "$DB_OUTPUT"
    
    DB_ID=$(echo "$DB_OUTPUT" | grep "database_id" | awk '{print $3}' | tr -d '"' | tr -d ',')
    
    if [ -z "$DB_ID" ]; then
      print_error "Failed to create D1 database"
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
  if [ -f "database_schema_extended.sql" ]; then
    print_info "Applying database schema..."
    if wrangler d1 execute "$DB_NAME" --file=database_schema_extended.sql 2>&1; then
      print_success "Database schema applied successfully"
    else
      print_warning "Schema application may have failed (check if already exists)"
    fi
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 3: KV Namespace Setup
# ═══════════════════════════════════════════════════════════════

setup_kv_namespace() {
  print_step "STEP 3: KV Namespace Setup"
  echo ""
  
  KV_NAME="PLAYLISTS_KV"
  
  # Check if KV namespace already exists
  if wrangler kv:namespace list 2>&1 | grep -q "$KV_NAME"; then
    print_info "KV Namespace '$KV_NAME' already exists"
    KV_ID=$(wrangler kv:namespace list 2>&1 | grep "$KV_NAME" | awk '{print $1}')
    print_success "Using existing namespace: $KV_ID"
  else
    print_info "Creating KV namespace: $KV_NAME"
    KV_OUTPUT=$(wrangler kv:namespace create "$KV_NAME" 2>&1)
    echo "$KV_OUTPUT"
    
    KV_ID=$(echo "$KV_OUTPUT" | grep "id =" | awk '{print $3}' | tr -d '"' | tr -d ',')
    
    if [ -z "$KV_ID" ]; then
      print_error "Failed to create KV namespace"
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
# STEP 4: Secrets Configuration
# ═══════════════════════════════════════════════════════════════

setup_secrets() {
  print_step "STEP 4: Secrets Configuration"
  echo ""
  
  print_warning "You need to set the following secrets manually:"
  echo ""
  echo "  1. JWT_SECRET         - Secret key for JWT tokens"
  echo "  2. VAPID_PUBLIC_KEY   - Web Push VAPID public key"
  echo "  3. VAPID_PRIVATE_KEY  - Web Push VAPID private key"
  echo ""
  
  print_info "Generate secrets:"
  echo ""
  echo "  # Generate JWT Secret (256-bit)"
  echo "  openssl rand -base64 32"
  echo ""
  echo "  # Generate VAPID Keys"
  echo "  npx web-push generate-vapid-keys"
  echo ""
  
  read -p "$(echo -e ${YELLOW}Do you want to set secrets now? [y/N]:${NC} )" -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    
    # JWT Secret
    read -p "Enter JWT_SECRET (or press Enter to generate): " JWT_SECRET
    if [ -z "$JWT_SECRET" ]; then
      JWT_SECRET=$(openssl rand -base64 32)
      print_info "Generated JWT_SECRET: $JWT_SECRET"
    fi
    echo "$JWT_SECRET" | wrangler secret put JWT_SECRET
    print_success "JWT_SECRET configured"
    
    echo ""
    
    # VAPID Keys
    print_info "For VAPID keys, run: npx web-push generate-vapid-keys"
    print_warning "Skipping VAPID configuration for now..."
    print_info "You can add them later with:"
    echo "  echo 'YOUR_PUBLIC_KEY' | wrangler secret put VAPID_PUBLIC_KEY"
    echo "  echo 'YOUR_PRIVATE_KEY' | wrangler secret put VAPID_PRIVATE_KEY"
    
  else
    print_info "Skipping secrets configuration"
    print_warning "Remember to set secrets before production deployment!"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 5: Deploy Worker
# ═══════════════════════════════════════════════════════════════

deploy_worker() {
  print_step "STEP 5: Deploying Worker to Cloudflare"
  echo ""
  
  print_info "Starting deployment..."
  
  if wrangler deploy 2>&1; then
    print_success "Worker deployed successfully!"
    echo ""
    
    # Get worker URL
    WORKER_URL=$(wrangler deployments list 2>&1 | grep "https://" | head -1 | awk '{print $1}')
    
    if [ -z "$WORKER_URL" ]; then
      WORKER_URL="https://weltenbibliothek-api.YOUR_ACCOUNT.workers.dev"
    fi
    
    print_success "Worker URL: $WORKER_URL"
    
  else
    print_error "Deployment failed"
    exit 1
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 6: Health Check
# ═══════════════════════════════════════════════════════════════

health_check() {
  print_step "STEP 6: Health Check"
  echo ""
  
  # Get worker URL from deployments
  WORKER_URL=$(wrangler deployments list 2>&1 | grep "https://" | head -1 | awk '{print $1}')
  
  if [ -z "$WORKER_URL" ]; then
    print_warning "Could not determine worker URL automatically"
    read -p "Enter your worker URL: " WORKER_URL
  fi
  
  HEALTH_URL="${WORKER_URL}/health"
  
  print_info "Testing health endpoint: $HEALTH_URL"
  echo ""
  
  if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s "$HEALTH_URL" 2>/dev/null || echo '{"status":"error"}')
    
    if echo "$RESPONSE" | grep -q '"status":"healthy"'; then
      print_success "Health check PASSED!"
      echo ""
      echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    else
      print_error "Health check FAILED"
      echo ""
      echo "Response: $RESPONSE"
    fi
  else
    print_warning "curl not found, skipping health check"
    print_info "Test manually: $HEALTH_URL"
  fi
  
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# STEP 7: Summary
# ═══════════════════════════════════════════════════════════════

print_summary() {
  print_step "DEPLOYMENT SUMMARY"
  echo ""
  
  WORKER_URL=$(wrangler deployments list 2>&1 | grep "https://" | head -1 | awk '{print $1}' || echo "https://weltenbibliothek-api.workers.dev")
  
  echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                                                               ║${NC}"
  echo -e "${GREEN}║              ✅ DEPLOYMENT SUCCESSFUL! ✅                     ║${NC}"
  echo -e "${GREEN}║                                                               ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  print_success "API Endpoints:"
  echo ""
  echo "  Health Check:       $WORKER_URL/health"
  echo "  Push Notifications: $WORKER_URL/api/push/*"
  echo "  Playlists:          $WORKER_URL/api/playlists/*"
  echo "  Analytics:          $WORKER_URL/api/analytics/*"
  echo ""
  
  print_success "Next Steps:"
  echo ""
  echo "  1. Test API endpoints with Postman/curl"
  echo "  2. Update Flutter app baseUrl to: $WORKER_URL"
  echo "  3. Set up monitoring (UptimeRobot, Sentry)"
  echo "  4. Configure custom domain (optional)"
  echo ""
  
  print_info "Useful Commands:"
  echo ""
  echo "  # Stream logs"
  echo "  wrangler tail weltenbibliothek-api"
  echo ""
  echo "  # List deployments"
  echo "  wrangler deployments list"
  echo ""
  echo "  # Rollback (if needed)"
  echo "  wrangler rollback weltenbibliothek-api"
  echo ""
  
  print_success "Documentation:"
  echo "  - DEPLOYMENT_GUIDE.md"
  echo "  - MONITORING_GUIDE.md"
  echo "  - COMPLETE_PROJECT_SUMMARY.md"
  echo ""
}

# ═══════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════

main() {
  print_banner
  
  # Confirmation
  echo -e "${YELLOW}This script will deploy your Weltenbibliothek API to Cloudflare Workers.${NC}"
  echo ""
  read -p "$(echo -e ${YELLOW}Do you want to proceed? [y/N]:${NC} )" -n 1 -r
  echo
  echo ""
  
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
  fi
  
  # Execute deployment steps
  check_prerequisites
  setup_account_id
  setup_d1_database
  setup_kv_namespace
  setup_secrets
  deploy_worker
  health_check
  print_summary
  
  echo -e "${GREEN}🎉 Deployment Complete! 🎉${NC}"
  echo ""
}

# Run main function
main "$@"
