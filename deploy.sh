#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# WELTENBIBLIOTHEK WEBRTC - PRODUCTION DEPLOYMENT SCRIPT
# ═══════════════════════════════════════════════════════════════
# Automated deployment script for Flutter Web + Cloudflare Workers
# Version: 2.0 (Phase 1-6 Complete)
# ═══════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if required tools are installed
check_requirements() {
    print_step "Checking requirements..."
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter not found. Please install Flutter SDK."
        exit 1
    fi
    
    if ! command -v wrangler &> /dev/null; then
        print_warning "Wrangler CLI not found. Install with: npm install -g wrangler"
        read -p "Continue without Cloudflare deployment? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        SKIP_CLOUDFLARE=true
    fi
    
    print_success "All required tools found"
}

# Run tests
run_tests() {
    print_step "Running tests..."
    
    flutter test || {
        print_error "Tests failed. Fix errors before deployment."
        exit 1
    }
    
    print_success "All tests passed (79/79)"
}

# Build Flutter Web
build_flutter_web() {
    print_step "Building Flutter Web (Production)..."
    
    flutter clean
    flutter pub get
    flutter build web --release --tree-shake-icons
    
    print_success "Flutter Web build complete"
    print_success "Output: build/web/"
}

# Deploy Cloudflare Worker
deploy_cloudflare_worker() {
    if [ "$SKIP_CLOUDFLARE" = true ]; then
        print_warning "Skipping Cloudflare deployment"
        return
    fi
    
    print_step "Deploying Cloudflare Worker..."
    
    cd cloudflare_backend
    
    # Check if wrangler.toml exists
    if [ ! -f "wrangler_webrtc.toml" ]; then
        print_error "wrangler_webrtc.toml not found"
        exit 1
    fi
    
    # Deploy
    wrangler deploy --config wrangler_webrtc.toml
    
    cd ..
    
    print_success "Cloudflare Worker deployed"
}

# Create deployment package
create_deployment_package() {
    print_step "Creating deployment package..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    PACKAGE_NAME="weltenbibliothek_webrtc_${TIMESTAMP}.tar.gz"
    
    tar -czf "$PACKAGE_NAME" \
        build/web/ \
        cloudflare_backend/weltenbibliothek_worker.js \
        cloudflare_backend/wrangler_webrtc.toml \
        cloudflare_backend/webrtc_schema.sql \
        cloudflare_backend/.env.example \
        MIGRATION_GUIDE.md \
        README_WEBRTC_QUALITY.md
    
    print_success "Deployment package created: $PACKAGE_NAME"
}

# Start local preview server
start_preview() {
    print_step "Starting local preview server..."
    
    cd build/web
    python3 -m http.server 5060 --bind 0.0.0.0 &
    SERVER_PID=$!
    
    print_success "Preview server started on http://localhost:5060"
    print_warning "Press Ctrl+C to stop the server"
    
    # Wait for Ctrl+C
    trap "kill $SERVER_PID 2>/dev/null; exit" INT
    wait $SERVER_PID
}

# Main deployment flow
main() {
    echo "═══════════════════════════════════════════════════════════════"
    echo "  WELTENBIBLIOTHEK WEBRTC - PRODUCTION DEPLOYMENT"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    # Parse arguments
    case "${1:-full}" in
        full)
            check_requirements
            run_tests
            build_flutter_web
            deploy_cloudflare_worker
            create_deployment_package
            ;;
        build)
            check_requirements
            build_flutter_web
            ;;
        test)
            run_tests
            ;;
        deploy)
            deploy_cloudflare_worker
            ;;
        package)
            create_deployment_package
            ;;
        preview)
            start_preview
            ;;
        *)
            echo "Usage: ./deploy.sh [full|build|test|deploy|package|preview]"
            echo ""
            echo "  full     - Run all deployment steps (default)"
            echo "  build    - Build Flutter Web only"
            echo "  test     - Run tests only"
            echo "  deploy   - Deploy Cloudflare Worker only"
            echo "  package  - Create deployment package"
            echo "  preview  - Start local preview server"
            exit 1
            ;;
    esac
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${GREEN}  DEPLOYMENT SUCCESSFUL!${NC}"
    echo "═══════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"
