# 🌐 Cloudflare Worker Deployment Guide

## 🚀 Complete Production Deployment für Weltenbibliothek API

---

## 📋 Voraussetzungen

### 1. Cloudflare Account
- [ ] Cloudflare Account erstellt
- [ ] Workers Plan aktiviert (Free oder Paid)
- [ ] Account ID notiert (Dashboard → Workers → Overview)

### 2. Wrangler CLI installiert
```bash
npm install -g wrangler

# Verify installation
wrangler --version

# Login to Cloudflare
wrangler login
```

### 3. Domain (Optional)
- [ ] Custom Domain verfügbar (z.B. `weltenbibliothek.com`)
- [ ] Domain zu Cloudflare hinzugefügt
- [ ] DNS konfiguriert

---

## 🔧 Setup-Schritte

### Step 1: D1 Database erstellen

```bash
# Create production database
wrangler d1 create weltenbibliothek_db_production

# Output example:
# [[d1_databases]]
# binding = "DATABASE"
# database_name = "weltenbibliothek_db_production"
# database_id = "abc123-def456-ghi789"

# Copy database_id and update wrangler.toml
```

**Erstelle Schema:**
```bash
# Apply database schema
wrangler d1 execute weltenbibliothek_db_production \
  --file=database_schema_extended.sql
```

**Verify:**
```bash
# List tables
wrangler d1 execute weltenbibliothek_db_production \
  --command="SELECT name FROM sqlite_master WHERE type='table';"
```

### Step 2: KV Namespace erstellen

```bash
# Create production KV namespace
wrangler kv:namespace create "PLAYLISTS_KV" --env production

# Output example:
# [[kv_namespaces]]
# binding = "PLAYLISTS_KV"
# id = "xyz789abc123def456"

# Copy id and update wrangler.toml
```

### Step 3: Secrets konfigurieren

```bash
# Set JWT secret
wrangler secret put JWT_SECRET --env production
# Enter: your-super-secret-jwt-key-here

# Set VAPID keys for Web Push (generate first)
# Generate VAPID keys: npm install -g web-push
# web-push generate-vapid-keys

wrangler secret put VAPID_PUBLIC_KEY --env production
# Enter: your-vapid-public-key

wrangler secret put VAPID_PRIVATE_KEY --env production
# Enter: your-vapid-private-key

# Optional: Firebase secrets
wrangler secret put FIREBASE_PROJECT_ID --env production
wrangler secret put FIREBASE_API_KEY --env production
```

**List secrets:**
```bash
wrangler secret list --env production
```

### Step 4: wrangler.toml konfigurieren

Update `wrangler.toml` mit den IDs aus Step 1-2:

```toml
# Replace placeholders:
account_id = "YOUR_ACCOUNT_ID"

[env.production]
[[env.production.d1_databases]]
database_id = "abc123-def456-ghi789"  # From Step 1

[[env.production.kv_namespaces]]
id = "xyz789abc123def456"  # From Step 2
```

### Step 5: Test Deployment (Development)

```bash
# Test locally first
cd cloudflare_workers
wrangler dev

# Test with remote resources
wrangler dev --remote

# Check endpoints:
# http://localhost:8787/api/push/test
# http://localhost:8787/api/playlists
# http://localhost:8787/api/analytics/summary
```

### Step 6: Deploy to Production

```bash
# Deploy to production environment
wrangler deploy --env production

# Output:
# Published weltenbibliothek-api-production (X.XX sec)
#   https://weltenbibliothek-api-production.YOUR_SUBDOMAIN.workers.dev
```

---

## 🌐 Custom Domain Setup

### Option A: Workers Route (Recommended)

1. **Go to Cloudflare Dashboard**:
   - Workers & Pages → YOUR_WORKER → Settings → Triggers

2. **Add Custom Domain**:
   - Click "Add Custom Domain"
   - Enter: `api.weltenbibliothek.com`
   - Cloudflare creates DNS record automatically

3. **Update wrangler.toml**:
   ```toml
   [env.production]
   route = "api.weltenbibliothek.com/*"
   ```

### Option B: Subdomain with DNS

1. **Create CNAME record**:
   ```
   Type: CNAME
   Name: api
   Target: weltenbibliothek-api-production.YOUR_SUBDOMAIN.workers.dev
   Proxy: Enabled (orange cloud)
   ```

2. **Add route in wrangler.toml**:
   ```toml
   [env.production]
   route = "api.weltenbibliothek.com/*"
   ```

3. **Redeploy**:
   ```bash
   wrangler deploy --env production
   ```

---

## 📊 Database Migrations

### Create Migration

```bash
# Create new migration
wrangler d1 migrations create weltenbibliothek_db_production add_new_table

# Edit generated file: migrations/XXXX_add_new_table.sql
# Add SQL statements

# Apply migration
wrangler d1 migrations apply weltenbibliothek_db_production
```

### Backup Database

```bash
# Export database
wrangler d1 export weltenbibliothek_db_production --output=backup.sql

# Import database
wrangler d1 execute weltenbibliothek_db_production --file=backup.sql
```

---

## 🔍 Monitoring & Debugging

### Real-time Logs

```bash
# Tail production logs
wrangler tail --env production

# Filter by status
wrangler tail --env production --status error

# Filter by method
wrangler tail --env production --method POST
```

### Analytics Dashboard

**Cloudflare Dashboard:**
1. Workers & Pages → YOUR_WORKER → Metrics
2. View:
   - Requests per second
   - CPU time
   - Errors
   - Success rate

### Debug Deployment Issues

```bash
# Check worker status
wrangler deployments list --env production

# View specific deployment
wrangler deployments view DEPLOYMENT_ID

# Rollback if needed
wrangler rollback --env production
```

---

## ⚡ Performance Optimization

### Enable Caching

Add to worker code:
```javascript
// Cache GET requests for 5 minutes
const cache = caches.default;
const cacheKey = new Request(request.url, request);

// Try cache first
let response = await cache.match(cacheKey);
if (response) return response;

// Process request...
response = await handleRequest(request);

// Cache successful responses
if (response.status === 200) {
  response.headers.set('Cache-Control', 'public, max-age=300');
  await cache.put(cacheKey, response.clone());
}

return response;
```

### Enable Rate Limiting

Update `wrangler.toml`:
```toml
[env.production.vars]
ENABLE_RATE_LIMITING = "true"
RATE_LIMIT_REQUESTS = "60"  # per minute per IP
```

Add to worker code:
```javascript
// Simple rate limiting with KV
const rateLimitKey = `rate_limit_${clientIP}`;
const count = await env.PLAYLISTS_KV.get(rateLimitKey);

if (count && parseInt(count) > 60) {
  return new Response('Rate limit exceeded', { status: 429 });
}

await env.PLAYLISTS_KV.put(rateLimitKey, 
  (parseInt(count || 0) + 1).toString(),
  { expirationTtl: 60 }
);
```

---

## 🧪 Testing Checklist

### Pre-Deployment Tests

- [ ] All endpoints tested locally (`wrangler dev`)
- [ ] Database queries work correctly
- [ ] KV operations work correctly
- [ ] Secrets are properly set
- [ ] CORS headers configured
- [ ] Error handling works

### Post-Deployment Tests

```bash
# Test production endpoints
PROD_URL="https://api.weltenbibliothek.com"

# Health check
curl $PROD_URL/health

# Push Notifications
curl -X POST $PROD_URL/api/push/subscribe \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test123","topics":["new_events"]}'

# Playlists
curl $PROD_URL/api/playlists \
  -H "X-User-ID: test123"

# Analytics
curl "$PROD_URL/api/analytics/summary?timeRange=7d"
```

---

## 🔐 Security Checklist

### Production Security

- [ ] JWT_SECRET set and strong (32+ characters)
- [ ] VAPID keys generated and secured
- [ ] Rate limiting enabled
- [ ] Input validation implemented
- [ ] SQL injection prevention (parameterized queries)
- [ ] CORS properly configured
- [ ] Secrets not committed to git
- [ ] Production and development environments separated

### Environment Variables

**Never commit these to git:**
```
JWT_SECRET
VAPID_PUBLIC_KEY
VAPID_PRIVATE_KEY
FIREBASE_API_KEY
DATABASE_ID
KV_NAMESPACE_ID
```

---

## 📈 Scaling Considerations

### Free Tier Limits (Cloudflare Workers)

- **Requests**: 100,000 per day
- **CPU Time**: 10ms per request
- **D1 Database**: 5GB storage, 100,000 reads/day
- **KV Storage**: 1GB, 100,000 reads/day

### Paid Plan ($5/month)

- **Requests**: 10,000,000 per month
- **CPU Time**: 50ms per request
- **D1 Database**: 25 million rows read/day
- **KV Storage**: Unlimited

### Optimization Tips

1. **Use KV for frequently accessed data** (playlists, user preferences)
2. **Use D1 for relational data** (analytics, subscriptions)
3. **Cache responses** where possible
4. **Batch database queries** to reduce D1 reads
5. **Use indexes** on frequently queried columns
6. **Monitor usage** in Cloudflare Dashboard

---

## 🆘 Troubleshooting

### Common Issues

#### Issue: "Database not found"
```bash
# Verify database exists
wrangler d1 list

# Verify binding in wrangler.toml
# Check database_id matches
```

#### Issue: "KV namespace not found"
```bash
# Verify KV namespace
wrangler kv:namespace list

# Verify binding in wrangler.toml
# Check id matches
```

#### Issue: "Secret not found"
```bash
# List secrets
wrangler secret list --env production

# Re-add missing secret
wrangler secret put SECRET_NAME --env production
```

#### Issue: "Route not working"
```bash
# Verify route in Cloudflare Dashboard
# Workers & Pages → YOUR_WORKER → Settings → Triggers

# Check DNS records
# Ensure CNAME or Route is configured

# Redeploy
wrangler deploy --env production
```

---

## 📚 Resources

### Documentation
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [D1 Database Docs](https://developers.cloudflare.com/d1/)
- [KV Storage Docs](https://developers.cloudflare.com/kv/)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler/)

### Tools
- [Wrangler CLI](https://github.com/cloudflare/workers-sdk)
- [Web Push VAPID Generator](https://www.npmjs.com/package/web-push)
- [Postman Collection](https://www.postman.com/) - For API testing

---

## ✅ Deployment Checklist

**Before First Deployment:**
- [ ] Wrangler CLI installed and logged in
- [ ] D1 database created and schema applied
- [ ] KV namespace created
- [ ] All secrets configured
- [ ] wrangler.toml updated with correct IDs
- [ ] Local testing completed (`wrangler dev`)

**Deployment:**
- [ ] Deploy to production (`wrangler deploy --env production`)
- [ ] Verify deployment URL works
- [ ] Test all API endpoints
- [ ] Configure custom domain (optional)
- [ ] Set up monitoring and alerts

**Post-Deployment:**
- [ ] Monitor logs for first 24 hours
- [ ] Check analytics dashboard
- [ ] Verify database operations
- [ ] Test Flutter app integration
- [ ] Document production URL for team

---

**🎉 Ready for Production Deployment!**

Follow this guide step-by-step for a successful Cloudflare Worker deployment.

**Support:** If issues arise, check Cloudflare Workers Community or GitHub Issues.
