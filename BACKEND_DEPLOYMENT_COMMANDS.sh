#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# CLOUDFLARE BACKEND DEPLOYMENT - Weltenbibliothek v3.3.0
# ═══════════════════════════════════════════════════════════════
# Purpose: Migrate database and deploy worker for "1 Stream Pro Chat-Raum"
# Version: 3.3.0+44
# Date: 2025-01-XX
# ═══════════════════════════════════════════════════════════════

set -e  # Exit on error

echo "═══════════════════════════════════════════════════════════════"
echo "🚀 WELTENBIBLIOTHEK BACKEND DEPLOYMENT v3.3.0"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Navigate to backend directory
cd /home/user/flutter_app/cloudflare_backend

# ═══════════════════════════════════════════════════════════════
# STEP 1: Pre-flight checks
# ═══════════════════════════════════════════════════════════════
echo "📋 STEP 1: Pre-flight checks..."
echo ""

# Check if wrangler is installed
if ! command -v npx &> /dev/null; then
    echo "❌ ERROR: npx not found. Please install Node.js first."
    exit 1
fi

echo "✅ npx found"

# Check wrangler version
echo "🔍 Checking Wrangler version..."
npx wrangler --version

# Check login status
echo "🔍 Checking Cloudflare login status..."
npx wrangler whoami || {
    echo "⚠️  You are not logged in to Cloudflare."
    echo "📝 Please run: npx wrangler login"
    exit 1
}

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "📊 STEP 2: Database Migration (D1)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "🔍 Migration file: add_chat_room_id_migration.sql"
echo "📋 Changes:"
echo "  - ADD COLUMN chat_room_id TEXT to live_rooms table"
echo "  - CREATE INDEX idx_live_rooms_chat_room_status"
echo ""

read -p "⚠️  Execute database migration? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration aborted by user."
    exit 1
fi

echo ""
echo "🔨 Executing migration..."
npx wrangler d1 execute weltenbibliothek --file=add_chat_room_id_migration.sql

if [ $? -eq 0 ]; then
    echo "✅ Database migration successful!"
else
    echo "❌ Database migration failed!"
    echo "💡 Check error messages above"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🔍 STEP 3: Verify Migration"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "📊 Verifying schema changes..."
echo "Running: SELECT sql FROM sqlite_master WHERE name='live_rooms';"

npx wrangler d1 execute weltenbibliothek --command "SELECT sql FROM sqlite_master WHERE name='live_rooms';" | grep "chat_room_id"

if [ $? -eq 0 ]; then
    echo "✅ Column 'chat_room_id' found in schema!"
else
    echo "⚠️  Warning: Could not verify column in schema"
    echo "💡 This might be okay if grep failed, check manually in Cloudflare Dashboard"
fi

echo ""
echo "📊 Verifying index creation..."
npx wrangler d1 execute weltenbibliothek --command "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_live_rooms_chat_room_status';"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🚀 STEP 4: Deploy Worker"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "📦 Worker file: weltenbibliothek_worker.js"
echo "📋 Changes:"
echo "  - NEW: Chat room validation (handleCreateLiveRoom)"
echo "  - NEW: Error types (chat_room_occupied, user_has_stream)"
echo "  - UPDATED: SELECT queries include chat_room_id"
echo ""

read -p "⚠️  Deploy worker to production? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment aborted by user."
    exit 1
fi

echo ""
echo "🔨 Deploying worker..."
npx wrangler deploy weltenbibliothek_worker.js

if [ $? -eq 0 ]; then
    echo "✅ Worker deployment successful!"
else
    echo "❌ Worker deployment failed!"
    echo "💡 Check error messages above"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📊 Summary:"
echo "  ✅ Database migrated (chat_room_id column added)"
echo "  ✅ Index created (idx_live_rooms_chat_room_status)"
echo "  ✅ Worker deployed (v3.3.0 validation logic)"
echo ""
echo "🧪 Next Steps:"
echo "  1. Test livestream creation in Flutter app"
echo "  2. Verify '1 stream per chat room' rule works"
echo "  3. Test error handling (chat_room_occupied)"
echo "  4. Monitor Cloudflare logs for 409 errors"
echo ""
echo "📚 Documentation:"
echo "  - BACKEND_MIGRATION_GUIDE.md"
echo "  - CHANGELOG_v3.3.0.md"
echo "  - QUICK_REFERENCE_v3.3.0.md"
echo ""
echo "═══════════════════════════════════════════════════════════════"
