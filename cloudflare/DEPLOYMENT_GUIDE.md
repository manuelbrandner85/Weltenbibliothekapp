# CLOUDFLARE WORKER DEPLOYMENT - CORS PROXY

## 🚀 Schnell-Setup (5 Minuten)

### 1. Cloudflare Account & Login
```bash
npm install -g wrangler
wrangler login
```

### 2. API Token als Secret speichern
```bash
wrangler secret put PERPLEXITY_API_KEY
# Dann eingeben: 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
```

### 3. Worker deployen
```bash
cd cloudflare
wrangler deploy cors-proxy-worker.js
```

### 4. Worker URL erhalten
Nach dem Deployment bekommst du eine URL wie:
```
https://cors-proxy-worker.DEIN-USERNAME.workers.dev
```

---

## 📝 Flutter App Update

### web_search_service.dart ändern

**Zeile 14 ersetzen:**
```dart
// VORHER:
static const String _baseUrl = 'https://api.perplexity.ai/chat/completions';

// NACHHER:
static const String _baseUrl = 'https://cors-proxy-worker.DEIN-USERNAME.workers.dev';
```

**⚠️ WICHTIG**: `DEIN-USERNAME` durch deine tatsächliche Cloudflare Worker URL ersetzen!

---

## 🔧 Wrangler Config (Optional)

Falls du `wrangler.toml` verwenden willst:

```toml
name = "cors-proxy-worker"
main = "cors-proxy-worker.js"
compatibility_date = "2024-01-01"
workers_dev = true

[env.production]
name = "cors-proxy-worker"
route = "weltenbibliothek.com/api/*"
```

---

## 🧪 Testen

### Test-Request (cURL)
```bash
curl -X POST https://cors-proxy-worker.DEIN-USERNAME.workers.dev \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.1-sonar-large-128k-online",
    "messages": [
      {"role": "user", "content": "Test"}
    ]
  }'
```

### Flutter App Testen
1. Worker deployen
2. URL in `web_search_service.dart` eintragen
3. Flutter Web neu builden
4. Recherche starten

---

## 📊 Monitoring

### Logs anzeigen
```bash
wrangler tail cors-proxy-worker
```

### Logs in Browser
1. Cloudflare Dashboard öffnen
2. Workers → cors-proxy-worker
3. "Logs" Tab öffnen
4. Requests live beobachten

---

## 🔒 Security Features

- ✅ API Token nur im Cloudflare Environment
- ✅ CORS Headers für Flutter Web
- ✅ Request/Response Logging
- ✅ Error Handling mit Details
- ✅ OPTIONS Pre-flight Support

---

## ❓ Troubleshooting

### "Worker not found"
```bash
wrangler whoami  # Check Login
wrangler deploy cors-proxy-worker.js  # Erneut deployen
```

### "Secret not found"
```bash
wrangler secret list  # Secrets anzeigen
wrangler secret put PERPLEXITY_API_KEY  # Secret hinzufügen
```

### "CORS Error weiterhin"
1. Worker-URL prüfen
2. URL in Flutter App korrekt?
3. Cache leeren: `rm -rf build/web .dart_tool/build_cache`
4. Neu builden: `flutter build web --release`

---

## 🎯 Kosten

**Cloudflare Workers Free Tier:**
- ✅ 100.000 Requests/Tag KOSTENLOS
- ✅ Keine Kreditkarte nötig
- ✅ Perfekt für Entwicklung & Testing

---

## 📱 Next Steps

1. ✅ Worker deployen
2. ✅ URL in Flutter App eintragen
3. ✅ Neu builden
4. ✅ Testen
5. ✅ Fertig! 🎉
