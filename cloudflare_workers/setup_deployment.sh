#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# WELTENBIBLIOTHEK - Automated Cloudflare Deployment Setup
# ═══════════════════════════════════════════════════════════════
# This script automates the complete Cloudflare Worker deployment
# ═══════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if wrangler is installed
check_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        print_error "Wrangler CLI not found!"
        echo "Install it with: npm install -g wrangler"
        exit 1
    fi
    print_success "Wrangler CLI found: $(wrangler --version)"
}

# Check if logged in
check_login() {
    if ! wrangler whoami &> /dev/null; then
        print_error "Not logged in to Cloudflare!"
        echo "Run: wrangler login"
        exit 1
    fi
    print_success "Logged in to Cloudflare"
}

# Create D1 Database
create_d1_database() {
    print_header "Step 1: Create D1 Database"
    
    read -p "Enter environment (production/staging/dev): " ENV
    DB_NAME="weltenbibliothek_db_${ENV}"
    
    print_info "Creating D1 database: $DB_NAME"
    
    # Create database
    DB_OUTPUT=$(wrangler d1 create "$DB_NAME" 2>&1)
    
    if echo "$DB_OUTPUT" | grep -q "database_id"; then
        DB_ID=$(echo "$DB_OUTPUT" | grep "database_id" | awk '{print $3}' | tr -d '"')
        print_success "Database created with ID: $DB_ID"
        echo "$DB_ID" > ".db_id_${ENV}.txt"
        
        # Apply schema
        print_info "Applying database schema..."
        wrangler d1 execute "$DB_NAME" --file=database_schema_extended.sql
        print_success "Schema applied successfully"
    else
        print_error "Failed to create database"
        echo "$DB_OUTPUT"
        exit 1
    fi
}

# Create KV Namespace
create_kv_namespace() {
    print_header "Step 2: Create KV Namespace"
    
    read -p "Enter environment (production/staging/dev): " ENV
    
    print_info "Creating KV namespace for $ENV..."
    
    if [ "$ENV" = "production" ]; then
        KV_OUTPUT=$(wrangler kv:namespace create "PLAYLISTS_KV" --env production 2>&1)
    else
        KV_OUTPUT=$(wrangler kv:namespace create "PLAYLISTS_KV" 2>&1)
    fi
    
    if echo "$KV_OUTPUT" | grep -q "id ="; then
        KV_ID=$(echo "$KV_OUTPUT" | grep "id =" | awk '{print $3}' | tr -d '"')
        print_success "KV Namespace created with ID: $KV_ID"
        echo "$KV_ID" > ".kv_id_${ENV}.txt"
    else
        print_error "Failed to create KV namespace"
        echo "$KV_OUTPUT"
        exit 1
    fi
}

# Configure Secrets
configure_secrets() {
    print_header "Step 3: Configure Secrets"
    
    read -p "Enter environment (production/staging/dev): " ENV
    
    print_info "Configuring secrets for $ENV environment..."
    
    # JWT Secret
    print_info "Setting JWT_SECRET..."
    read -sp "Enter JWT Secret (min 32 characters): " JWT_SECRET
    echo
    echo "$JWT_SECRET" | wrangler secret put JWT_SECRET --env "$ENV"
    print_success "JWT_SECRET configured"
    
    # VAPID Keys
    print_warning "VAPID Keys needed for Web Push Notifications"
    print_info "Generate with: npm install -g web-push && web-push generate-vapid-keys"
    
    read -p "Enter VAPID Public Key: " VAPID_PUBLIC
    echo "$VAPID_PUBLIC" | wrangler secret put VAPID_PUBLIC_KEY --env "$ENV"
    print_success "VAPID_PUBLIC_KEY configured"
    
    read -p "Enter VAPID Private Key: " VAPID_PRIVATE
    echo "$VAPID_PRIVATE" | wrangler secret put VAPID_PRIVATE_KEY --env "$ENV"
    print_success "VAPID_PRIVATE_KEY configured"
    
    # Optional Firebase
    read -p "Configure Firebase? (y/n): " CONFIGURE_FIREBASE
    if [ "$CONFIGURE_FIREBASE" = "y" ]; then
        read -p "Enter Firebase Project ID: " FB_PROJECT_ID
        echo "$FB_PROJECT_ID" | wrangler secret put FIREBASE_PROJECT_ID --env "$ENV"
        
        read -p "Enter Firebase API Key: " FB_API_KEY
        echo "$FB_API_KEY" | wrangler secret put FIREBASE_API_KEY --env "$ENV"
        
        print_success "Firebase secrets configured"
    fi
}

# Update wrangler.toml
update_wrangler_toml() {
    print_header "Step 4: Update wrangler.toml"
    
    read -p "Enter environment (production/staging/dev): " ENV
    
    if [ ! -f ".db_id_${ENV}.txt" ] || [ ! -f ".kv_id_${ENV}.txt" ]; then
        print_error "Database or KV IDs not found. Run steps 1 and 2 first."
        exit 1
    fi
    
    DB_ID=$(cat ".db_id_${ENV}.txt")
    KV_ID=$(cat ".kv_id_${ENV}.txt")
    
    print_info "Updating wrangler.toml with IDs..."
    print_info "Database ID: $DB_ID"
    print_info "KV ID: $KV_ID"
    
    print_warning "Please manually update wrangler.toml with these IDs:"
    echo ""
    echo "[env.$ENV]"
    echo "[[env.$ENV.d1_databases]]"
    echo "database_id = \"$DB_ID\""
    echo ""
    echo "[[env.$ENV.kv_namespaces]]"
    echo "id = \"$KV_ID\""
    echo ""
}

# Test Deployment
test_deployment() {
    print_header "Step 5: Test Deployment"
    
    print_info "Starting local development server..."
    print_info "Press Ctrl+C to stop"
    
    wrangler dev
}

# Deploy to Production
deploy_production() {
    print_header "Step 6: Deploy to Production"
    
    read -p "Deploy to production? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" = "yes" ]; then
        print_info "Deploying to production..."
        wrangler deploy --env production
        print_success "Deployment complete!"
        
        # Get deployment URL
        DEPLOY_URL=$(wrangler deployments list --env production 2>&1 | grep "https://" | head -1 | awk '{print $1}')
        print_success "Worker URL: $DEPLOY_URL"
    else
        print_warning "Deployment cancelled"
    fi
}

# Main Menu
show_menu() {
    clear
    print_header "WELTENBIBLIOTHEK DEPLOYMENT SETUP"
    echo ""
    echo "Choose an option:"
    echo "1. Complete Setup (All Steps)"
    echo "2. Create D1 Database"
    echo "3. Create KV Namespace"
    echo "4. Configure Secrets"
    echo "5. Update wrangler.toml (Show IDs)"
    echo "6. Test Deployment (Local Dev)"
    echo "7. Deploy to Production"
    echo "8. Health Check"
    echo "9. Exit"
    echo ""
    read -p "Enter choice [1-9]: " CHOICE
}

# Health Check
health_check() {
    print_header "Health Check"
    
    read -p "Enter Worker URL: " WORKER_URL
    
    print_info "Checking $WORKER_URL/health..."
    
    RESPONSE=$(curl -s "$WORKER_URL/health" || echo "ERROR")
    
    if [ "$RESPONSE" = "ERROR" ]; then
        print_error "Health check failed - Worker not reachable"
    else
        print_success "Health check passed!"
        echo "Response: $RESPONSE"
    fi
}

# Complete Setup
complete_setup() {
    print_header "COMPLETE SETUP"
    print_warning "This will guide you through all setup steps"
    echo ""
    
    check_wrangler
    check_login
    create_d1_database
    create_kv_namespace
    configure_secrets
    update_wrangler_toml
    
    print_success "Setup complete!"
    print_info "Next steps:"
    echo "1. Update wrangler.toml with the IDs shown above"
    echo "2. Test with: wrangler dev"
    echo "3. Deploy with: wrangler deploy --env production"
}

# Main Loop
main() {
    while true; do
        show_menu
        
        case $CHOICE in
            1)
                complete_setup
                read -p "Press Enter to continue..."
                ;;
            2)
                check_wrangler
                check_login
                create_d1_database
                read -p "Press Enter to continue..."
                ;;
            3)
                check_wrangler
                check_login
                create_kv_namespace
                read -p "Press Enter to continue..."
                ;;
            4)
                check_wrangler
                check_login
                configure_secrets
                read -p "Press Enter to continue..."
                ;;
            5)
                update_wrangler_toml
                read -p "Press Enter to continue..."
                ;;
            6)
                check_wrangler
                check_login
                test_deployment
                ;;
            7)
                check_wrangler
                check_login
                deploy_production
                read -p "Press Enter to continue..."
                ;;
            8)
                health_check
                read -p "Press Enter to continue..."
                ;;
            9)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
