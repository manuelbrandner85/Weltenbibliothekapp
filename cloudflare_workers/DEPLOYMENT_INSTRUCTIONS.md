# 🚀 Weltenbibliothek - Complete Deployment Instructions

## 📋 Quick Navigation

1. [Prerequisites](#1-prerequisites)
2. [One-Command Deployment](#2-one-command-deployment-recommended)
3. [Manual Step-by-Step Deployment](#3-manual-step-by-step-deployment)
4. [Post-Deployment Configuration](#4-post-deployment-configuration)
5. [Troubleshooting](#5-troubleshooting)

---

## 1. Prerequisites

### Required Tools

**1. Node.js & npm**
```bash
# Check if installed
node --version  # Should be v16 or higher
npm --version

# Install if needed (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install (macOS)
brew install node
```

**2. Wrangler CLI**
```bash
# Install globally
npm install -g wrangler

# Verify installation
wrangler --version
```

**3. Cloudflare Account**
- Sign up at: https://dash.cloudflare.com/sign-up
- Free tier includes:
  - ✅ 100,000 requests/day
  - ✅ D1 Database (10 GB storage)
  - ✅ KV Namespace (1 GB storage)
  - ✅ Workers deployment

### Initial Setup

**1. Login to Cloudflare**
```bash
wrangler login
```
- Opens browser for authentication
- Authorizes Wrangler CLI access

**2. Verify Login**
```bash
wrangler whoami
```
Expected output:
```
 ⛅️ wrangler 3.x.x
-------------------
Getting User settings...
👋 You are logged in with an OAuth Token, associated with the email 'your@email.com'!
┌──────────────────────────┬──────────────────────────────────┐
│ Account Name             │ Account ID                        │
├──────────────────────────┼──────────────────────────────────┤
│ Your Account             │ abc123def456...                   │
└──────────────────────────┴──────────────────────────────────┘
```

---

## 2. One-Command Deployment (Recommended)

### Quick Deploy Script

**Execute the automated deployment script:**

```bash
cd /home/user/flutter_app/cloudflare_workers
./QUICK_DEPLOY.sh
```

**What it does:**
- ✅ Checks prerequisites (wrangler, login)
- ✅ Sets up Account ID automatically
- ✅ Creates D1 Database with schema
- ✅ Creates KV Namespace for playlists
- ✅ Configures secrets (JWT, VAPID)
- ✅ Deploys Worker to Cloudflare
- ✅ Runs health check
- ✅ Provides deployment summary

**Interactive Prompts:**
1. Confirm deployment start
2. Choose to set secrets now or later
3. View deployment results

**Expected Duration:** 3-5 minutes

---

## 3. Manual Step-by-Step Deployment

If you prefer manual control or automated script fails:

### Step 1: Get Your Account ID

```bash
# Method 1: From wrangler
wrangler whoami

# Method 2: From Cloudflare Dashboard
# Go to: https://dash.cloudflare.com
# Click on any domain → Copy Account ID from right sidebar
```

**Update wrangler.toml:**
```bash
# Replace YOUR_ACCOUNT_ID with actual ID
sed -i 's/YOUR_ACCOUNT_ID/your-actual-account-id/g' wrangler.toml
```

### Step 2: Create D1 Database

```bash
# Create database
wrangler d1 create weltenbibliothek_db

# Output will be:
# ✅ Successfully created DB 'weltenbibliothek_db'
# 
# [[d1_databases]]
# binding = "DATABASE"
# database_name = "weltenbibliothek_db"
# database_id = "abc-123-def-456"  ← COPY THIS ID
```

**Update wrangler.toml:**
```bash
# Replace placeholder with actual database ID
sed -i 's/YOUR_D1_DATABASE_ID/abc-123-def-456/g' wrangler.toml
```

**Apply Database Schema:**
```bash
wrangler d1 execute weltenbibliothek_db --file=database_schema_extended.sql
```

Expected output:
```
🌀 Executing on weltenbibliothek_db (abc-123-def-456):
🌀 To execute on your remote database, add a --remote flag to your wrangler command.
🚣 Executed 10 commands in 0.5 seconds
✅ Successfully applied database schema
```

### Step 3: Create KV Namespace

```bash
# Create KV namespace for playlists
wrangler kv:namespace create "PLAYLISTS_KV"

# Output will be:
# 🌀 Creating namespace with title "worker-PLAYLISTS_KV"
# ✅ Success!
# Add the following to your configuration file:
# [[kv_namespaces]]
# binding = "PLAYLISTS_KV"
# id = "xyz789abc123"  ← COPY THIS ID
```

**Update wrangler.toml:**
```bash
# Replace placeholder with actual KV namespace ID
sed -i 's/YOUR_PLAYLISTS_KV_ID/xyz789abc123/g' wrangler.toml
```

### Step 4: Configure Secrets

**Generate JWT Secret:**
```bash
# Generate random 256-bit secret
JWT_SECRET=$(openssl rand -base64 32)
echo $JWT_SECRET

# Set secret
echo "$JWT_SECRET" | wrangler secret put JWT_SECRET
```

**Generate VAPID Keys (for Push Notifications):**
```bash
# Install web-push utility
npm install -g web-push

# Generate VAPID key pair
npx web-push generate-vapid-keys

# Output:
# =======================================
# Public Key:
# BHxZvW8... (long string)
# 
# Private Key:
# nHzY3kL... (long string)
# =======================================
```

**Set VAPID Secrets:**
```bash
# Set public key
echo "BHxZvW8..." | wrangler secret put VAPID_PUBLIC_KEY

# Set private key
echo "nHzY3kL..." | wrangler secret put VAPID_PRIVATE_KEY
```

### Step 5: Deploy Worker

```bash
# Deploy to Cloudflare
wrangler deploy

# Or deploy to specific environment
wrangler deploy --env production
```

Expected output:
```
Total Upload: 25.67 KiB / gzip: 7.83 KiB
Uploaded weltenbibliothek-api (2.34 sec)
Published weltenbibliothek-api (0.45 sec)
  https://weltenbibliothek-api.your-account.workers.dev
Current Deployment ID: abc-123-def
```

### Step 6: Verify Deployment

**Test Health Endpoint:**
```bash
# Get your worker URL
WORKER_URL=$(wrangler deployments list | grep https | head -1 | awk '{print $1}')

# Test health check
curl $WORKER_URL/health | jq
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-11-23T14:00:00.000Z",
  "version": "2.0.0",
  "checks": {
    "api": {
      "status": "ok"
    },
    "database": {
      "status": "ok",
      "message": "D1 Database connected"
    },
    "kv": {
      "status": "ok",
      "message": "KV Namespace accessible"
    }
  }
}
```

---

## 4. Post-Deployment Configuration

### Update Flutter App

**1. Update API Base URL in Flutter:**
```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  // OLD:
  // final String baseUrl = 'http://localhost:8787';
  
  // NEW:
  final String baseUrl = 'https://weltenbibliothek-api.your-account.workers.dev';
}

// Update same in:
// - lib/services/push_notification_service.dart
// - lib/services/music_playlist_service.dart
```

**2. Rebuild Flutter App:**
```bash
cd /home/user/flutter_app
flutter clean
flutter pub get
flutter build web --release
```

### Set Up Monitoring

**1. UptimeRobot (Free)**
- Go to: https://uptimerobot.com
- Create new monitor:
  - Type: HTTP(s)
  - URL: `https://your-worker.workers.dev/health`
  - Monitoring Interval: 5 minutes
  - Alert Contacts: Your email

**2. Cloudflare Analytics**
- Dashboard: https://dash.cloudflare.com
- Navigate to: Workers & Pages → weltenbibliothek-api → Analytics
- View:
  - Requests per second
  - Success rate (2xx, 4xx, 5xx)
  - CPU time
  - Errors

### Configure Custom Domain (Optional)

**1. Add Route to wrangler.toml:**
```toml
route = "api.yourdomain.com/*"
```

**2. Deploy with Custom Domain:**
```bash
wrangler deploy
```

**3. Configure DNS:**
- Cloudflare Dashboard → DNS → Add Record
- Type: CNAME
- Name: api
- Content: weltenbibliothek-api.your-account.workers.dev
- Proxy: Enabled (orange cloud)

---

## 5. Troubleshooting

### Common Issues

#### Issue 1: "wrangler: command not found"

**Solution:**
```bash
# Install wrangler globally
npm install -g wrangler

# Or use npx
npx wrangler login
npx wrangler deploy
```

#### Issue 2: "Not logged in to Cloudflare"

**Solution:**
```bash
# Login via browser
wrangler login

# Or use API token
export CLOUDFLARE_API_TOKEN="your-api-token"
```

#### Issue 3: "Database ID not found in wrangler.toml"

**Solution:**
```bash
# Create database
wrangler d1 create weltenbibliothek_db

# Copy database_id from output
# Update wrangler.toml manually:
nano wrangler.toml
# Find: database_id = "YOUR_D1_DATABASE_ID"
# Replace with actual ID
```

#### Issue 4: Health Check Returns 503

**Possible Causes:**
1. Database not created or schema not applied
2. KV namespace not configured
3. Secrets not set

**Debug Steps:**
```bash
# Check logs
wrangler tail weltenbibliothek-api

# Verify database
wrangler d1 execute weltenbibliothek_db --command="SELECT COUNT(*) FROM push_subscriptions"

# Verify KV namespace
wrangler kv:namespace list

# List secrets
wrangler secret list
```

#### Issue 5: "Module not found" Error

**Solution:**
```bash
# Ensure main file is correct in wrangler.toml
# main = "api_endpoints_extended.js"

# Verify file exists
ls -la api_endpoints_extended.js

# Redeploy
wrangler deploy
```

#### Issue 6: CORS Errors in Flutter App

**Solution:**
```javascript
// In api_endpoints_extended.js, ensure CORS headers:
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',  // ✅ Essential
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-User-ID',
    },
  });
}
```

### Useful Debug Commands

```bash
# View recent deployments
wrangler deployments list

# Stream logs in real-time
wrangler tail weltenbibliothek-api

# Rollback to previous deployment
wrangler rollback weltenbibliothek-api

# Test specific endpoint
curl -X POST https://your-worker.workers.dev/api/push/subscribe \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test123","topics":["new_events"]}'

# Check database status
wrangler d1 execute weltenbibliothek_db \
  --command="SELECT name FROM sqlite_master WHERE type='table'"

# List KV keys
wrangler kv:key list --binding=PLAYLISTS_KV
```

---

## 6. Performance & Optimization

### Cache Strategy

**1. Enable Caching for Playlists:**
```javascript
// Cache playlists for 1 hour
await env.PLAYLISTS_KV.put(playlistId, JSON.stringify(playlist), {
  expirationTtl: 3600
});
```

**2. Use CDN Caching:**
```javascript
return new Response(data, {
  headers: {
    'Cache-Control': 'public, max-age=300',  // 5 minutes
  }
});
```

### Database Optimization

**1. Create Indexes:**
```sql
CREATE INDEX IF NOT EXISTS idx_user_activity ON user_activity_log(user_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_push_active ON push_subscriptions(is_active, user_id);
```

**2. Use Prepared Statements:**
```javascript
// ✅ Good
await env.DATABASE.prepare(
  'SELECT * FROM push_subscriptions WHERE user_id = ?'
).bind(userId).all();

// ❌ Bad (SQL Injection risk)
await env.DATABASE.prepare(
  `SELECT * FROM push_subscriptions WHERE user_id = '${userId}'`
).all();
```

---

## 7. Security Best Practices

### API Security

**1. Rate Limiting:**
```javascript
// Implement rate limiting per IP
const rateLimiter = new Map();

function checkRateLimit(ip) {
  const now = Date.now();
  const requests = rateLimiter.get(ip) || [];
  
  // Allow 100 requests per minute
  const recentRequests = requests.filter(time => now - time < 60000);
  
  if (recentRequests.length >= 100) {
    return false;
  }
  
  recentRequests.push(now);
  rateLimiter.set(ip, recentRequests);
  return true;
}
```

**2. Input Validation:**
```javascript
function validateUserId(userId) {
  if (!userId || typeof userId !== 'string') {
    throw new Error('Invalid user_id');
  }
  if (userId.length > 100) {
    throw new Error('user_id too long');
  }
  return userId.trim();
}
```

**3. Secure Headers:**
```javascript
headers: {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Strict-Transport-Security': 'max-age=31536000',
}
```

---

## 8. Quick Reference

### Environment Variables

| Variable | Description | How to Set |
|----------|-------------|------------|
| `JWT_SECRET` | Secret key for JWT tokens | `wrangler secret put JWT_SECRET` |
| `VAPID_PUBLIC_KEY` | Web Push public key | `wrangler secret put VAPID_PUBLIC_KEY` |
| `VAPID_PRIVATE_KEY` | Web Push private key | `wrangler secret put VAPID_PRIVATE_KEY` |

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check with component status |
| `/api/push/subscribe` | POST | Subscribe to push notifications |
| `/api/push/unsubscribe` | DELETE | Unsubscribe from notifications |
| `/api/push/topics/subscribe` | POST | Subscribe to specific topic |
| `/api/push/test` | POST | Send test notification |
| `/api/playlists` | GET | Get user playlists |
| `/api/playlists/:id` | POST | Save/update playlist |
| `/api/playlists/:id` | DELETE | Delete playlist |
| `/api/analytics/summary` | GET | Analytics summary |
| `/api/analytics/webrtc` | GET | WebRTC metrics |
| `/api/analytics/engagement` | GET | User engagement data |

### Useful Links

- **Cloudflare Dashboard:** https://dash.cloudflare.com
- **Workers Documentation:** https://developers.cloudflare.com/workers/
- **D1 Documentation:** https://developers.cloudflare.com/d1/
- **KV Documentation:** https://developers.cloudflare.com/kv/
- **Wrangler CLI Docs:** https://developers.cloudflare.com/workers/wrangler/

---

## 🎉 Success Checklist

After deployment, verify:

- [ ] Health endpoint returns 200 status
- [ ] Database check shows "ok"
- [ ] KV namespace check shows "ok"
- [ ] Can create push subscription
- [ ] Can save playlist
- [ ] Analytics endpoints return data
- [ ] Flutter app connects successfully
- [ ] Monitoring is set up (UptimeRobot)
- [ ] Logs are accessible via `wrangler tail`
- [ ] Custom domain configured (if applicable)

---

**Need Help?**

- Check MONITORING_GUIDE.md for observability setup
- Review DEPLOYMENT_GUIDE.md for advanced configuration
- Read COMPLETE_PROJECT_SUMMARY.md for architecture details

**Deployment successful? Great! Now monitor your application and iterate based on real-world usage!** 🚀

---

**Last Updated:** November 23, 2024  
**Version:** 2.0.0  
**Contact:** Your Weltenbibliothek Dev Team
