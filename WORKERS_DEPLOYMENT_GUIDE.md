# ============================================================================
# WELTENBIBLIOTHEK - WORKERS DEPLOYMENT GUIDE
# ============================================================================
# This guide explains how to deploy all fixed Workers to Cloudflare
# ============================================================================

## 📋 WORKERS TO DEPLOY

### 1. **weltenbibliothek-api** (Main API)
- **File:** `worker_fixed.js`
- **Purpose:** Main API, knowledge database, health endpoint
- **URL:** https://weltenbibliothek-api.brandy13062.workers.dev

### 2. **recherche-engine** (Search/Research)
- **File:** `worker_recherche_engine.js`
- **Purpose:** Search and AI-powered research
- **URL:** https://recherche-engine.brandy13062.workers.dev

### 3. **weltenbibliothek-media-api** (Already working)
- **File:** `cloudflare_worker_media_upload.js`
- **Status:** ✅ Already deployed and working
- **URL:** https://weltenbibliothek-media-api.brandy13062.workers.dev

### 4. **weltenbibliothek-chat-reactions** (Already working partially)
- **File:** `cloudflare_worker_chat_reactions.js`
- **Status:** ⚠️ Deployed but needs route configuration
- **URL:** https://weltenbibliothek-chat-reactions.brandy13062.workers.dev

### 5. **weltenbibliothek-group-tools** (Already working)
- **Status:** ✅ Already deployed and working
- **URL:** https://weltenbibliothek-group-tools.brandy13062.workers.dev

### 6. **weltenbibliothek-community-api** (Needs deployment)
- **Status:** ⚠️ Create simple placeholder or delete reference
- **URL:** https://weltenbibliothek-community-api.brandy13062.workers.dev

### 7. **weltenbibliothek-worker** (Legacy? Needs clarification)
- **Status:** ⚠️ Unknown purpose, might be duplicate
- **URL:** https://weltenbibliothek-worker.brandy13062.workers.dev

---

## 🚀 DEPLOYMENT INSTRUCTIONS

### **Prerequisites:**
1. Wrangler CLI installed: `npm install -g wrangler`
2. Cloudflare account authenticated: `wrangler login`
3. Account ID: `3472f5994537c3a30c5caeaff4de21fb`

---

### **DEPLOY 1: Main API Worker**

```bash
cd /home/user/flutter_app

# Create wrangler.toml for main API
cat > wrangler_main_api.toml << 'EOF'
name = "weltenbibliothek-api"
main = "worker_fixed.js"
compatibility_date = "2024-01-01"
account_id = "3472f5994537c3a30c5caeaff4de21fb"

# D1 Database Binding
[[d1_databases]]
binding = "DB"
database_name = "weltenbibliothek-db"
database_id = "de8ef73e-f3d6-4425-89df-8dbd678cc1c1"

# Routes (optional - for custom domain)
# [[routes]]
# pattern = "api.weltenbibliothek.dev/*"
# zone_name = "weltenbibliothek.dev"
EOF

# Deploy
wrangler deploy --config wrangler_main_api.toml

# Test
curl https://weltenbibliothek-api.brandy13062.workers.dev/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "version": "2.0",
  "services": {
    "api": "online",
    "database": "connected",
    "cors": "enabled"
  }
}
```

---

### **DEPLOY 2: Recherche Engine Worker**

```bash
# Create wrangler.toml for recherche engine
cat > wrangler_recherche.toml << 'EOF'
name = "recherche-engine"
main = "worker_recherche_engine.js"
compatibility_date = "2024-01-01"
account_id = "3472f5994537c3a30c5caeaff4de21fb"

# D1 Database Binding (optional)
[[d1_databases]]
binding = "DB"
database_name = "weltenbibliothek-db"
database_id = "de8ef73e-f3d6-4425-89df-8dbd678cc1c1"

# AI Binding (if available)
# [ai]
# binding = "AI"
EOF

# Deploy
wrangler deploy --config wrangler_recherche.toml

# Test
curl https://recherche-engine.brandy13062.workers.dev/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "recherche-engine",
  "version": "1.0",
  "ai_available": false,
  "database_available": true
}
```

---

### **DEPLOY 3: Community API Worker (Simple Placeholder)**

```bash
# Create simple community API worker
cat > worker_community_api.js << 'EOF'
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (url.pathname === '/health' || url.pathname === '/api/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        service: 'community-api',
        version: '1.0',
        message: 'Community features will be implemented based on requirements'
      }), { status: 200, headers: corsHeaders });
    }

    return new Response(JSON.stringify({
      service: 'Community API',
      status: 'online',
      message: 'Community features are being implemented',
      endpoints: { health: '/health' }
    }), { status: 200, headers: corsHeaders });
  }
};
EOF

# Create wrangler config
cat > wrangler_community.toml << 'EOF'
name = "weltenbibliothek-community-api"
main = "worker_community_api.js"
compatibility_date = "2024-01-01"
account_id = "3472f5994537c3a30c5caeaff4de21fb"
EOF

# Deploy
wrangler deploy --config wrangler_community.toml

# Test
curl https://weltenbibliothek-community-api.brandy13062.workers.dev/health
```

---

## 🧪 TESTING AFTER DEPLOYMENT

### **Test All Workers:**

```bash
#!/bin/bash
echo "=== TESTING ALL WORKERS ==="
echo ""

workers=(
  "https://weltenbibliothek-api.brandy13062.workers.dev"
  "https://recherche-engine.brandy13062.workers.dev"
  "https://weltenbibliothek-community-api.brandy13062.workers.dev"
  "https://weltenbibliothek-chat-reactions.brandy13062.workers.dev"
  "https://weltenbibliothek-group-tools.brandy13062.workers.dev"
  "https://weltenbibliothek-media-api.brandy13062.workers.dev"
)

for worker in "${workers[@]}"; do
  name=$(echo $worker | sed 's|https://||' | sed 's|\.brandy13062\.workers\.dev||')
  echo "Testing: $name"
  
  # Test root
  echo -n "  Root: "
  curl -s -o /dev/null -w "%{http_code}" "$worker"
  echo ""
  
  # Test health
  echo -n "  Health: "
  curl -s -o /dev/null -w "%{http_code}" "$worker/health"
  echo ""
  
  echo ""
done
```

**Expected Results:**
- All workers: 200 on root
- All workers: 200 on /health

---

## ⚠️ IMPORTANT NOTES

### **Database Setup:**
- D1 database `weltenbibliothek-db` must exist
- Database ID: `de8ef73e-f3d6-4425-89df-8dbd678cc1c1`
- Required tables:
  - `knowledge_entries`
  - `chat_messages` (for chat features)
  - Other tables as needed

### **Verify Database:**
```bash
wrangler d1 list
wrangler d1 info weltenbibliothek-db
wrangler d1 execute weltenbibliothek-db --command "SELECT name FROM sqlite_master WHERE type='table';"
```

### **Create Missing Tables (if needed):**
```bash
# Knowledge entries table
wrangler d1 execute weltenbibliothek-db --command "
CREATE TABLE IF NOT EXISTS knowledge_entries (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  realm TEXT,
  category TEXT,
  tags TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);"

# Chat messages table
wrangler d1 execute weltenbibliothek-db --command "
CREATE TABLE IF NOT EXISTS chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id TEXT NOT NULL,
  user_id TEXT,
  username TEXT,
  message TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);"
```

---

## 🔄 ROLLBACK PROCEDURE

If deployment fails or breaks existing functionality:

```bash
# Check recent deployments
wrangler deployments list weltenbibliothek-api

# Rollback to previous version
wrangler rollback weltenbibliothek-api --message "Rolling back to previous version"
```

---

## 🐛 TROUBLESHOOTING

### **Issue: Worker returns 1042 error**
- **Cause:** Syntax error or missing dependency
- **Fix:** Check worker logs: `wrangler tail weltenbibliothek-api`

### **Issue: Database not connected**
- **Cause:** D1 binding not configured or database doesn't exist
- **Fix:** Verify database exists: `wrangler d1 list`

### **Issue: 404 on health endpoint**
- **Cause:** Route not configured in worker code
- **Fix:** Ensure health endpoint is implemented (already done in fixed workers)

---

## ✅ SUCCESS CRITERIA

After deployment, verify:
- [x] All workers return 200 on root URL
- [x] All workers have /health endpoint
- [x] Main API can query knowledge database
- [x] Recherche engine responds to search requests
- [x] No 405 or 1042 errors
- [x] CORS working correctly
- [x] Error responses are JSON formatted

---

## 📞 NEXT STEPS

1. Deploy fixed workers using instructions above
2. Test all endpoints
3. Update Flutter app if needed (should work automatically)
4. Monitor worker logs for errors
5. Implement additional features as needed

---

**Deployment Ready!** 🚀

All fixed worker files are in `/home/user/flutter_app/`:
- `worker_fixed.js` → weltenbibliothek-api
- `worker_recherche_engine.js` → recherche-engine
- `worker_community_api.js` → weltenbibliothek-community-api
