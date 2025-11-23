# 🔐 Token-Based Cloudflare Deployment Guide

## 🎯 Overview

Dieser Guide zeigt Ihnen, wie Sie mit einem **Cloudflare API Token** deployen können, **ohne Browser-Login**. Perfekt für:
- ✅ CI/CD Pipelines
- ✅ Automatisierte Deployments
- ✅ Headless Server
- ✅ Scripts und Automation

---

## 📋 Prerequisites

### 1. Cloudflare API Token erstellen

**Schritt-für-Schritt:**

1. **Login zu Cloudflare Dashboard:**
   - https://dash.cloudflare.com

2. **Navigate zu API Tokens:**
   - Klicke auf dein Profil (oben rechts)
   - Wähle "API Tokens"
   - Oder direkt: https://dash.cloudflare.com/profile/api-tokens

3. **Create Token:**
   - Klicke "Create Token"
   - Wähle **"Edit Cloudflare Workers"** Template
   - **ODER** Custom Token mit diesen Permissions:

**Required Permissions:**
```
Account
├── Workers Scripts: Edit
├── Workers KV Storage: Edit
└── D1: Edit

Zone (Optional - für Custom Domains)
└── Workers Routes: Edit
```

4. **Generate & Copy Token:**
   - Klicke "Continue to summary"
   - Klicke "Create Token"
   - **⚠️ WICHTIG:** Kopiere den Token SOFORT!
   - Token Format: `<long-alphanumeric-string>`

5. **Token sicher speichern:**
   ```bash
   # Niemals committen!
   # Speichere in .env oder password manager
   ```

---

## 🚀 Deployment mit Token

### **Method 1: Direct Token Pass (Empfohlen für Testing)**

```bash
cd /home/user/flutter_app/cloudflare_workers

# Deploy mit Token als Argument
./DEPLOY_WITH_TOKEN.sh <YOUR_API_TOKEN>
```

**Beispiel:**
```bash
./DEPLOY_WITH_TOKEN.sh 0UgxzEEYIBQjY7pOyL4npKzsl1OGVM_aDbQK6iJg
```

---

### **Method 2: Environment Variable (Empfohlen für Production)**

```bash
# Set environment variable
export CLOUDFLARE_API_TOKEN="<YOUR_API_TOKEN>"

# Deploy
cd /home/user/flutter_app/cloudflare_workers
./DEPLOY_WITH_TOKEN.sh
```

**Oder in einem Schritt:**
```bash
CLOUDFLARE_API_TOKEN="<YOUR_TOKEN>" ./DEPLOY_WITH_TOKEN.sh
```

---

### **Method 3: .env File (Empfohlen für Entwicklung)**

**Erstelle `.env` Datei:**
```bash
cd /home/user/flutter_app/cloudflare_workers

# Create .env file
cat > .env <<EOF
CLOUDFLARE_API_TOKEN=<YOUR_API_TOKEN>
CLOUDFLARE_ACCOUNT_ID=<YOUR_ACCOUNT_ID>
EOF

# Set permissions (wichtig!)
chmod 600 .env
```

**Add to .gitignore:**
```bash
echo ".env" >> .gitignore
```

**Deploy mit .env:**
```bash
# Load environment variables
source .env

# Deploy
./DEPLOY_WITH_TOKEN.sh
```

---

## 📊 Was das Script macht

Das `DEPLOY_WITH_TOKEN.sh` Script führt folgende Schritte aus:

### **STEP 0: Prerequisites Check**
- ✅ Prüft ob wrangler CLI installiert ist
- ✅ Prüft ob alle Dateien vorhanden sind

### **STEP 1: Token Verification**
- ✅ Verifiziert den API Token
- ✅ Zeigt Account-Email an

### **STEP 2: Account ID**
- ✅ Holt automatisch die Account ID
- ✅ Updated wrangler.toml

### **STEP 3: D1 Database**
- ✅ Erstellt D1 Database
- ✅ Wendet Schema an
- ✅ Updated wrangler.toml mit Database ID

### **STEP 4: KV Namespace**
- ✅ Erstellt KV Namespace
- ✅ Updated wrangler.toml mit KV ID

### **STEP 5: Secrets Configuration**
- ✅ Generiert JWT Secret
- ✅ Konfiguriert Secrets (optional)

### **STEP 6: Worker Deployment**
- ✅ Deployed Worker zu Cloudflare

### **STEP 7: Worker URL**
- ✅ Holt Worker URL automatisch

### **STEP 8: Health Check**
- ✅ Testet Health Endpoint
- ✅ Verifiziert Deployment

### **STEP 9: Summary**
- ✅ Zeigt Deployment-Details
- ✅ Gibt Next Steps

---

## ✅ Expected Output

```bash
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        🔐 TOKEN-BASED CLOUDFLARE DEPLOYMENT 🚀                ║
║                                                               ║
║              No Browser Login Required!                       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

▶ STEP 0: Checking Prerequisites
✅ wrangler CLI found: wrangler 3.x.x
✅ All required files present

▶ STEP 1: Verifying API Token
✅ Token verified successfully!
✅ Account: your-email@example.com

▶ STEP 2: Getting Account ID
✅ Account ID: abc123def456...

▶ STEP 3: Creating D1 Database
✅ Database created: xyz789...
✅ Database schema applied

▶ STEP 4: Creating KV Namespace
✅ KV Namespace created: def456...

▶ STEP 5: Configuring Secrets
✅ JWT_SECRET configured

▶ STEP 6: Deploying Worker
✅ Worker deployed successfully!

▶ STEP 7: Getting Worker URL
✅ Worker URL: https://weltenbibliothek-api.your-account.workers.dev

▶ STEP 8: Health Check
✅ Health check PASSED! ✅

{
  "status": "healthy",
  "timestamp": "2024-11-23T14:00:00.000Z",
  "version": "2.0.0",
  "checks": {
    "api": { "status": "ok" },
    "database": { "status": "ok" },
    "kv": { "status": "ok" }
  }
}

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           ✅ DEPLOYMENT SUCCESSFUL! ✅                         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

🎉 Deployment Complete! 🎉
```

---

## 🔒 Security Best Practices

### **1. Token Storage**

**❌ NEVER:**
- Commit tokens to Git
- Share tokens in chat/email
- Store in plain text files (tracked by Git)
- Hard-code in scripts

**✅ ALWAYS:**
- Use environment variables
- Store in `.env` files (with `.gitignore`)
- Use secret managers (1Password, LastPass)
- Rotate tokens regularly

### **2. Token Permissions**

**Principle of Least Privilege:**
- Only give necessary permissions
- Use scoped tokens (not Global API Key)
- Set expiration dates
- Monitor token usage

### **3. .gitignore Configuration**

```bash
# Add to your .gitignore
.env
.env.local
.env.*.local
*.key
*.pem
secrets/
```

### **4. Token Rotation**

```bash
# Rotate tokens every 90 days
# Steps:
1. Create new token in Cloudflare Dashboard
2. Update environment variables
3. Test with new token
4. Revoke old token
```

---

## 🛠️ Troubleshooting

### Issue 1: "Token verification failed"

**Ursache:** Token ungültig oder falsche Permissions

**Lösung:**
```bash
# 1. Prüfe Token-Format (keine Leerzeichen, vollständig kopiert)
echo "$CLOUDFLARE_API_TOKEN" | wc -c  # Sollte > 30 sein

# 2. Erstelle neuen Token mit korrekten Permissions
# 3. Test Token:
export CLOUDFLARE_API_TOKEN="new-token"
wrangler whoami
```

### Issue 2: "Database creation failed"

**Ursache:** Account hat kein D1 Zugriff oder Limit erreicht

**Lösung:**
```bash
# Prüfe D1 Quota
wrangler d1 list

# Free Tier Limits:
# - 10 GB Storage
# - 5 Millionen Rows

# Falls Limit erreicht: Alte DBs löschen
wrangler d1 delete old-database-name
```

### Issue 3: "KV namespace creation failed"

**Ursache:** Account Limit oder Token-Permissions

**Lösung:**
```bash
# Prüfe KV Namespaces
wrangler kv:namespace list

# Free Tier Limits:
# - 1 GB Storage
# - 100k Reads/Tag
# - 1k Writes/Tag
```

### Issue 4: "Deployment timeout"

**Ursache:** Netzwerk-Probleme oder große Dateien

**Lösung:**
```bash
# Retry deployment
./DEPLOY_WITH_TOKEN.sh

# Check file sizes
ls -lh api_endpoints_extended.js

# Should be < 1 MB for Workers
```

---

## 🔄 CI/CD Integration

### GitHub Actions

**`.github/workflows/deploy.yml`:**
```yaml
name: Deploy to Cloudflare

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install wrangler
        run: npm install -g wrangler
      
      - name: Deploy to Cloudflare
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        run: |
          cd cloudflare_workers
          ./DEPLOY_WITH_TOKEN.sh
```

**Setup GitHub Secrets:**
1. Go to: Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `CLOUDFLARE_API_TOKEN`
4. Value: Your token
5. Click "Add secret"

### GitLab CI/CD

**`.gitlab-ci.yml`:**
```yaml
deploy:
  stage: deploy
  image: node:18
  
  before_script:
    - npm install -g wrangler
  
  script:
    - cd cloudflare_workers
    - ./DEPLOY_WITH_TOKEN.sh
  
  only:
    - main
  
  variables:
    CLOUDFLARE_API_TOKEN: $CLOUDFLARE_API_TOKEN
```

**Setup GitLab Variables:**
1. Go to: Project → Settings → CI/CD → Variables
2. Click "Add variable"
3. Key: `CLOUDFLARE_API_TOKEN`
4. Value: Your token
5. Check "Mask variable" and "Protect variable"

---

## 📊 Monitoring After Deployment

### 1. Verify Deployment
```bash
# Get worker URL
WORKER_URL=$(wrangler deployments list | grep https | head -1 | awk '{print $1}')

# Run verification tests
./verify_deployment.sh $WORKER_URL
```

### 2. Check Logs
```bash
# Stream real-time logs
wrangler tail weltenbibliothek-api

# Filter for errors
wrangler tail weltenbibliothek-api --status error
```

### 3. Monitor Performance
```bash
# View analytics in dashboard
open https://dash.cloudflare.com

# Or via CLI
wrangler deployments list
```

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Deploy with token
./DEPLOY_WITH_TOKEN.sh <token>

# Or with env variable
export CLOUDFLARE_API_TOKEN="<token>"
./DEPLOY_WITH_TOKEN.sh

# Verify token
wrangler whoami

# List deployments
wrangler deployments list

# Rollback
wrangler rollback weltenbibliothek-api

# View logs
wrangler tail weltenbibliothek-api

# Test health
curl https://your-worker.workers.dev/health | jq
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `CLOUDFLARE_API_TOKEN` | API Token for authentication | ✅ Yes |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID (auto-detected) | ❌ Optional |

---

## 📚 Additional Resources

**Official Docs:**
- **API Tokens:** https://developers.cloudflare.com/fundamentals/api/get-started/create-token/
- **Wrangler Auth:** https://developers.cloudflare.com/workers/wrangler/ci-cd/
- **Workers CI/CD:** https://developers.cloudflare.com/workers/platform/deployments/

**Project Docs:**
- `DEPLOYMENT_INSTRUCTIONS.md` - Manual deployment
- `QUICK_DEPLOY.sh` - Interactive deployment
- `verify_deployment.sh` - Automated testing
- `MONITORING_GUIDE.md` - Observability setup

---

## ✅ Success Checklist

After token-based deployment:

- [ ] Token verified successfully
- [ ] Account ID detected
- [ ] D1 Database created
- [ ] Database schema applied
- [ ] KV Namespace created
- [ ] Worker deployed
- [ ] Health check passed
- [ ] Worker URL accessible
- [ ] Verification tests passed
- [ ] Monitoring configured

---

## 🎉 You're Done!

Your Weltenbibliothek API is now deployed using token-based authentication!

**Next Steps:**
1. Update Flutter app baseUrl
2. Set up UptimeRobot monitoring
3. Configure CI/CD pipeline (optional)
4. Document your worker URL

**Worker URL:** https://weltenbibliothek-api.<account>.workers.dev

---

**Last Updated:** November 23, 2024  
**Version:** 2.0.0  
**Status:** ✅ Token Deployment Ready
