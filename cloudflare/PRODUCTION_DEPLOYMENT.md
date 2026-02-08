# 🚀 PRODUCTION DEPLOYMENT - Weltenbibliothek Backend

## ⚡ QUICK START (10 Minuten bis Production-Ready)

### 1️⃣ Cloudflare Account & Wrangler Setup
```bash
# Wrangler CLI installieren
npm install -g wrangler

# Login bei Cloudflare
wrangler login
```

### 2️⃣ Worker Deployment
```bash
cd /home/user/flutter_app/cloudflare

# Worker mit neuem Namen deployen
wrangler deploy production-worker.js --name api-backend
```

**✅ Nach Deployment bekommst du die URL:**
```
https://api-backend.DEIN-USERNAME.workers.dev
```

### 3️⃣ API Token konfigurieren
```bash
# Secret für Perplexity API Token setzen
wrangler secret put PERPLEXITY_API_KEY --name api-backend

# Eingeben: <DEIN_GÜLTIGER_PERPLEXITY_TOKEN>
```

**⚠️ KRITISCH**: Verwende einen **gültigen** Perplexity API Token!
- Der alte Token ist ungültig (401 Error)
- Neuen Token holen: https://www.perplexity.ai/settings/api

### 4️⃣ KV Namespace für Rate Limiting (Optional)
```bash
# KV Namespace erstellen
wrangler kv:namespace create RATE_LIMIT_KV --name api-backend

# Ausgabe kopieren (z.B. id = "abc123...")
# In wrangler.toml eintragen (siehe unten)
```

---

## 📝 wrangler.toml Konfiguration

Erstelle `cloudflare/wrangler.toml`:

```toml
name = "api-backend"
main = "production-worker.js"
compatibility_date = "2024-01-20"
workers_dev = true

# Rate Limiting KV (Optional - für Production empfohlen)
[[kv_namespaces]]
binding = "RATE_LIMIT_KV"
id = "DEINE_KV_NAMESPACE_ID_HIER"

# Production Environment
[env.production]
name = "api-backend"
route = "api-backend.weltenbibliothek.workers.dev/*"
```

---

## 🧪 TESTEN

### Test 1: Health Check
```bash
curl https://api-backend.DEIN-USERNAME.workers.dev/health
```

**Erwartete Antwort:**
```json
{
  "status": "ok",
  "service": "Weltenbibliothek Research API",
  "version": "1.0.0",
  "timestamp": "2025-01-21T..."
}
```

### Test 2: Research Request
```bash
curl -X POST https://api-backend.DEIN-USERNAME.workers.dev/api/research \
  -H "Content-Type: application/json" \
  -d '{"query": "9/11 Verschwörungstheorien"}'
```

**Erwartete Antwort:**
```json
{
  "query": "9/11 Verschwörungstheorien",
  "summary": "...",
  "sources": [
    {
      "title": "...",
      "url": "...",
      "snippet": "",
      "sourceType": "alternative"
    }
  ],
  "timestamp": "2025-01-21T..."
}
```

---

## 🔧 Flutter App Update

### backend_recherche_service.dart
```dart
// ZEILE 13 ERSETZEN:
static const String _backendUrl = 'https://api-backend.DEIN-USERNAME.workers.dev';
```

**⚠️ WICHTIG**: `DEIN-USERNAME` durch deine tatsächliche Worker-URL ersetzen!

---

## 📊 MONITORING & LOGS

### Live Logs anzeigen
```bash
wrangler tail api-backend
```

### Logs in Cloudflare Dashboard
1. https://dash.cloudflare.com
2. Workers & Pages → api-backend
3. "Logs" Tab → Real-time Logs
4. Requests, Errors & Performance

---

## 🔒 SECURITY FEATURES

### ✅ Implemented
- **CORS Headers** für Flutter Web
- **API Token** nur im Worker (nicht im Client-Code)
- **Rate Limiting** (100 req/min per IP)
- **Request Logging** für Monitoring
- **Error Handling** mit Details
- **Input Validation** für Query

### 🛡️ Production Best Practices
- API Token als Cloudflare Secret
- KV Storage für Rate Limiting
- Request/Response Logging
- Error Tracking

---

## 💰 KOSTEN

### Cloudflare Workers Free Tier:
- ✅ **100.000 Requests/Tag KOSTENLOS**
- ✅ **1 Million Requests/Monat KOSTENLOS**
- ✅ Keine Kreditkarte für Free Tier

### Perplexity API:
- 💵 Pay-per-use (Check Pricing: https://www.perplexity.ai/settings/api)
- 💡 Free Tier verfügbar (Limited Requests)

---

## 🔥 DEPLOYMENT CHECKLIST

- [ ] Wrangler installiert & eingeloggt
- [ ] Worker deployed
- [ ] **GÜLTIGEN** Perplexity API Token holen
- [ ] API Token als Secret gesetzt
- [ ] Health Check erfolgreich
- [ ] Test-Request erfolgreich
- [ ] Worker-URL in Flutter App eingetragen
- [ ] Flutter App neu gebuild
- [ ] Live-Test in App erfolgreich

---

## ❓ TROUBLESHOOTING

### "401 Authorization Required"
**Problem**: Perplexity API Token ungültig  
**Lösung**: 
```bash
# Neuen Token holen von https://www.perplexity.ai/settings/api
wrangler secret put PERPLEXITY_API_KEY --name api-backend
# Neuen Token eingeben
```

### "Service Configuration Error"
**Problem**: PERPLEXITY_API_KEY Secret nicht gesetzt  
**Lösung**:
```bash
wrangler secret list --name api-backend  # Check Secrets
wrangler secret put PERPLEXITY_API_KEY --name api-backend  # Secret setzen
```

### "CORS Error"
**Problem**: Worker-URL falsch in Flutter App  
**Lösung**:
1. Worker-URL prüfen: `wrangler deployments list --name api-backend`
2. URL in `backend_recherche_service.dart` korrigieren
3. Flutter neu builden: `flutter build web --release`

### "Rate Limit Exceeded"
**Problem**: Zu viele Requests  
**Lösung**: 
- Warte 1 Minute
- KV Namespace für persistentes Rate Limiting einrichten

---

## 🎯 NEXT STEPS

1. **Worker deployen** (5 Min)
2. **Gültigen API Token holen** (2 Min)
3. **Token als Secret setzen** (1 Min)
4. **Health Check testen** (1 Min)
5. **Worker-URL in Flutter eintragen** (1 Min)
6. **Flutter App neu builden** (2 Min)
7. **Live testen** ✅

**Total: ~12 Minuten bis Production-Ready! 🚀**

---

## 📞 SUPPORT

### Cloudflare Workers Docs
https://developers.cloudflare.com/workers/

### Perplexity API Docs
https://docs.perplexity.ai/

### Wrangler CLI Docs
https://developers.cloudflare.com/workers/wrangler/
