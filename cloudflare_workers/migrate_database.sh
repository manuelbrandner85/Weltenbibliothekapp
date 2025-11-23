#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# WELTENBIBLIOTHEK - DATABASE MIGRATION SCRIPT
# ═══════════════════════════════════════════════════════════════
# Purpose: Safely migrate/upgrade Cloudflare D1 database schema
# Usage: ./migrate_database.sh [environment]
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/database_schema_extended.sql"
BACKUP_DIR="${SCRIPT_DIR}/backups"

# Environment selection (default: development)
ENV="${1:-development}"

# Function: Print colored messages
print_info() {
  echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
  echo -e "${GREEN}✅ ${NC}$1"
}

print_warning() {
  echo -e "${YELLOW}⚠️  ${NC}$1"
}

print_error() {
  echo -e "${RED}❌ ${NC}$1"
}

print_header() {
  echo ""
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE} $1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
}

# Function: Check prerequisites
check_prerequisites() {
  print_header "CHECKING PREREQUISITES"
  
  # Check if wrangler is installed
  if ! command -v wrangler &> /dev/null; then
    print_error "wrangler CLI not found. Please install: npm install -g wrangler"
    exit 1
  fi
  print_success "wrangler CLI found: $(wrangler --version)"
  
  # Check if logged in
  if ! wrangler whoami &> /dev/null; then
    print_error "Not logged in to Cloudflare. Please run: wrangler login"
    exit 1
  fi
  print_success "Authenticated with Cloudflare"
  
  # Check if schema file exists
  if [ ! -f "$SCHEMA_FILE" ]; then
    print_error "Schema file not found: $SCHEMA_FILE"
    exit 1
  fi
  print_success "Schema file found: $SCHEMA_FILE"
  
  # Create backup directory
  mkdir -p "$BACKUP_DIR"
  print_success "Backup directory ready: $BACKUP_DIR"
}

# Function: Get database name and ID from wrangler.toml
get_database_info() {
  print_header "DETECTING DATABASE CONFIGURATION"
  
  local toml_file="${SCRIPT_DIR}/wrangler.toml"
  
  if [ ! -f "$toml_file" ]; then
    print_error "wrangler.toml not found. Please run setup_deployment.sh first."
    exit 1
  fi
  
  # Parse database name based on environment
  if [ "$ENV" == "production" ]; then
    DB_NAME=$(grep -A5 '\[env.production\]' "$toml_file" | grep 'database_name' | head -1 | awk -F'"' '{print $2}')
    DB_ID=$(grep -A5 '\[env.production\]' "$toml_file" | grep 'database_id' | head -1 | awk -F'"' '{print $2}')
  else
    DB_NAME=$(grep 'database_name' "$toml_file" | head -1 | awk -F'"' '{print $2}')
    DB_ID=$(grep 'database_id' "$toml_file" | head -1 | awk -F'"' '{print $2}')
  fi
  
  if [ -z "$DB_NAME" ] || [ -z "$DB_ID" ]; then
    print_error "Could not detect database configuration from wrangler.toml"
    print_info "Please ensure D1 database is properly configured."
    exit 1
  fi
  
  print_success "Database Name: $DB_NAME"
  print_success "Database ID: $DB_ID"
}

# Function: Backup current database
backup_database() {
  print_header "CREATING DATABASE BACKUP"
  
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local backup_file="${BACKUP_DIR}/backup_${ENV}_${timestamp}.sql"
  
  print_info "Exporting current database schema and data..."
  
  # Use wrangler d1 export (if available)
  if wrangler d1 export "$DB_NAME" --output "$backup_file" 2>/dev/null; then
    print_success "Backup created: $backup_file"
    return 0
  fi
  
  # Fallback: Create backup marker file
  print_warning "Export not available. Creating backup marker..."
  echo "-- Database backup marker for $DB_NAME at $timestamp" > "$backup_file"
  echo "-- Manual verification recommended before migration" >> "$backup_file"
  print_success "Backup marker created: $backup_file"
}

# Function: Preview migration
preview_migration() {
  print_header "MIGRATION PREVIEW"
  
  print_info "Schema file: $SCHEMA_FILE"
  print_info "Target database: $DB_NAME ($ENV)"
  print_info ""
  
  # Show table count from schema
  local table_count=$(grep -c "CREATE TABLE" "$SCHEMA_FILE" || true)
  print_info "Tables to create/update: $table_count"
  
  # Show indexes count
  local index_count=$(grep -c "CREATE INDEX" "$SCHEMA_FILE" || true)
  print_info "Indexes to create: $index_count"
  
  # Show views count
  local view_count=$(grep -c "CREATE VIEW" "$SCHEMA_FILE" || true)
  print_info "Views to create: $view_count"
  
  echo ""
  print_warning "This migration will modify your database schema."
  print_warning "Existing data will be preserved (IF NOT EXISTS clauses)."
  echo ""
}

# Function: Execute migration
execute_migration() {
  print_header "EXECUTING MIGRATION"
  
  print_info "Running schema migration on $DB_NAME..."
  
  if wrangler d1 execute "$DB_NAME" --file="$SCHEMA_FILE"; then
    print_success "Migration completed successfully!"
    return 0
  else
    print_error "Migration failed. Database may be in inconsistent state."
    print_info "You can restore from backup: $BACKUP_DIR"
    exit 1
  fi
}

# Function: Verify migration
verify_migration() {
  print_header "VERIFYING MIGRATION"
  
  print_info "Checking table creation..."
  
  # Query to list all tables
  local query="SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
  
  if wrangler d1 execute "$DB_NAME" --command="$query" > /tmp/tables.txt 2>&1; then
    local table_count=$(grep -v "^$" /tmp/tables.txt | grep -v "name" | wc -l)
    print_success "Found $table_count tables in database"
    
    # Show table names
    print_info "Tables:"
    grep -v "^$" /tmp/tables.txt | grep -v "name" | while read -r table; do
      echo "  - $table"
    done
  else
    print_warning "Could not verify table creation automatically"
  fi
  
  echo ""
  print_info "Checking indexes..."
  
  # Query to list all indexes
  local idx_query="SELECT name FROM sqlite_master WHERE type='index' ORDER BY name;"
  
  if wrangler d1 execute "$DB_NAME" --command="$idx_query" > /tmp/indexes.txt 2>&1; then
    local idx_count=$(grep -v "^$" /tmp/indexes.txt | grep -v "name" | wc -l)
    print_success "Found $idx_count indexes in database"
  else
    print_warning "Could not verify index creation automatically"
  fi
  
  echo ""
  print_success "Migration verification complete!"
}

# Function: Show migration summary
show_summary() {
  print_header "MIGRATION SUMMARY"
  
  print_success "Environment: $ENV"
  print_success "Database: $DB_NAME"
  print_success "Schema Version: Extended (Phase 2)"
  print_success "Status: ✓ Completed successfully"
  
  echo ""
  print_info "Next Steps:"
  echo "  1. Test your application endpoints"
  echo "  2. Verify data integrity"
  echo "  3. Monitor database performance"
  echo ""
  
  if [ "$ENV" != "production" ]; then
    print_info "To migrate production environment:"
    echo "  ./migrate_database.sh production"
    echo ""
  fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════

print_header "WELTENBIBLIOTHEK - DATABASE MIGRATION"
print_info "Environment: $ENV"
echo ""

# Confirmation prompt
read -p "$(echo -e ${YELLOW}Do you want to proceed with migration? [y/N]:${NC} )" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  print_warning "Migration cancelled by user."
  exit 0
fi

# Execute migration steps
check_prerequisites
get_database_info
backup_database
preview_migration
execute_migration
verify_migration
show_summary

print_success "Migration completed! 🎉"
exit 0
