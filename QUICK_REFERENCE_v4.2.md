# 🚀 WELTENBIBLIOTHEK v4.2 - QUICK REFERENCE

**Schnellzugriff auf alle wichtigen Befehle und URLs**

---

## 🌐 URLS & ENDPOINTS

```
Flutter Web-App
└── https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai

Cloudflare Worker
└── https://weltenbibliothek-worker.brandy13062.workers.dev

API-Endpoint
└── GET https://weltenbibliothek-worker.brandy13062.workers.dev?q=<query>
```

---

## 📱 FLUTTER COMMANDS

### Development
```bash
# Analyse (Syntax-Check)
cd /home/user/flutter_app && flutter analyze

# Code-Formatierung
cd /home/user/flutter_app && dart format .

# Dependencies installieren
cd /home/user/flutter_app && flutter pub get

# Clean build
cd /home/user/flutter_app && flutter clean
```

### Web-Build & Server
```bash
# Web-Build (Release)
cd /home/user/flutter_app && flutter build web --release

# Web-Server starten (Python)
cd /home/user/flutter_app && python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &

# Port prüfen
lsof -i :5060

# Server stoppen
lsof -ti:5060 | xargs -r kill -9
```

### Android APK Build
```bash
# APK Build (Release)
cd /home/user/flutter_app && flutter build apk --release

# APK Location
/home/user/flutter_app/build/app/outputs/flutter-apk/app-release.apk

# APK Info
cd /home/user/flutter_app && ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

## ☁️ CLOUDFLARE WORKER COMMANDS

### Development
```bash
# Worker deployen
cd /home/user/flutter_app/cloudflare-worker && wrangler deploy

# Worker-Logs anzeigen
cd /home/user/flutter_app/cloudflare-worker && wrangler tail

# Worker-Status prüfen
curl -I https://weltenbibliothek-worker.brandy13062.workers.dev
```

### KV-Namespace Management
```bash
# KV-Namespace erstellen
cd /home/user/flutter_app/cloudflare-worker && wrangler kv namespace create "RATE_LIMIT_KV"

# KV-Keys auflisten
cd /home/user/flutter_app/cloudflare-worker && wrangler kv key list --namespace-id=784db5aeeecf4ba5bc57266c19e63678

# KV-Key löschen
cd /home/user/flutter_app/cloudflare-worker && wrangler kv key delete --namespace-id=784db5aeeecf4ba5bc57266c19e63678 "rate_limit_<IP>"
```

---

## 🧪 TESTING COMMANDS

### Worker-Tests
```bash
# Cache-Test
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" | jq '.status'

# Rate-Limit-Test (5x schnell)
for i in {1..5}; do
  curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Test$i" | jq '.status'
done

# Fallback-Test (seltener Begriff)
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=xzqwpmnbvcxz123" | jq '.status, .message'

# Error-Test (fehlende Query)
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev" | jq '.status, .message'
```

### Response-Inspection
```bash
# Vollständige Response
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" | jq '.'

# Nur Status
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" | jq '.status'

# Nur Analyse
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" | jq '.analyse.inhalt'

# Quellen-Status
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" | jq '.sourcesStatus'

# Cache-Status prüfen
curl -I "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" | grep "X-Cache-Status"
```

---

## 🔍 DEBUGGING COMMANDS

### Flutter-Logs
```bash
# Web-Server-Logs
tail -f /tmp/web_server.log

# Flutter-Logs (wenn vorhanden)
tail -f /home/user/flutter_app/flutter.log
```

### Network-Debugging
```bash
# Port-Status
netstat -tulpn | grep :5060

# Prozess auf Port finden
lsof -i :5060

# Local-Verbindung testen
curl -I http://localhost:5060

# Response-Time messen
time curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" > /dev/null
```

---

## 📊 MONITORING COMMANDS

### Performance
```bash
# Response-Time-Tracking
for i in {1..10}; do
  time curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Test$i" > /dev/null
done

# Success-Rate
for i in {1..20}; do
  status=$(curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Test$i" | jq -r '.status')
  echo "Request $i: $status"
done
```

### Cache-Hit-Rate
```bash
# Cache-Hit-Rate messen (10 identische Requests)
for i in {1..10}; do
  cache_status=$(curl -I "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin" 2>&1 | grep "X-Cache-Status" | awk '{print $2}')
  echo "Request $i: Cache-Status = $cache_status"
done
```

---

## 🛠️ MAINTENANCE COMMANDS

### Cleanup
```bash
# Flutter-Build-Cache löschen
cd /home/user/flutter_app && rm -rf build/ .dart_tool/

# Web-Server stoppen
pkill -f "python3 -m http.server" || true

# Alle Flutter-Prozesse beenden
pkill -f "flutter" || true
```

### Restart
```bash
# Kompletter Restart (Web-Server)
lsof -ti:5060 | xargs -r kill -9 && \
cd /home/user/flutter_app && \
flutter build web --release && \
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

---

## 📦 VERSION-INFO

```bash
# Flutter-Version
flutter --version

# Dart-Version
dart --version

# Wrangler-Version
wrangler --version

# Git-Version
git --version

# Python-Version
python3 --version
```

---

## 🔑 WICHTIGE KONFIGURATIONEN

### Worker-Bindings
```
RATE_LIMIT_KV: 784db5aeeecf4ba5bc57266c19e63678
AI: @cf/meta/llama-3.1-8b-instruct
ENVIRONMENT: production
```

### Rate-Limiting
```
Max Requests: 3 pro Minute
TTL: 60 Sekunden
Key-Format: rate_limit_<IP>
```

### Cache-System
```
TTL: 3600 Sekunden (1 Stunde)
Cache-API: caches.default
Header: Cache-Control: public, max-age=3600
```

### Timeouts
```
Flutter HTTP: 30 Sekunden
Worker AbortController: 15 Sekunden
Cloudflare Worker: 10 Minuten (max)
```

---

## 🎯 KOMPONENTEN-STATUS

```
✅ InputController         (Validation: 3-100 chars)
✅ RequestOrchestrator     (Cache, Rate-Limit, CORS)
✅ SourceCrawler           (Web, Archive, Docs, Media)
✅ MediaRenderer           (Markdown, SelectableText)
✅ NetworkAnalyzer         (Actor/Org Mapping)
✅ TimelineBuilder         (Event Sequencing)
✅ NarrativeAnalyzer       (Media/Framing Analysis)
✅ AlternativeViewEngine   (Counter-Narratives)
✅ CloudflareAI_Fallback   (Llama 3.1 8B)
✅ UIStateManager          (State Machine: 6 States)
```

---

## 🔄 DATENFLUSS (KURZ)

```
1. User Input (3-100 chars)
2. Flutter → Worker GET ?q=<query>
3. Worker → Cache-Check (HIT? → Return)
4. Worker → Rate-Limit-Check (>3? → HTTP 429)
5. Worker → Sequential Crawling:
   - Web (IMMER)
   - Docs (wenn web < 3)
   - Media (wenn docs > 0)
6. Worker → KI-Analyse (Llama 3.1 8B)
7. Worker → Cache-Store (1h TTL)
8. Worker → Return JSON
9. Flutter → Parse & Render
10. User → Selectable Result
```

---

## 📱 UI-STATE-ÜBERSICHT

```
IDLE          → Grau, 0%, "Bereit"
LOADING       → Blau, 10%, "Verbinde..."
SOURCES_FOUND → Orange, 50%, "Quellen gefunden"
ANALYSIS_READY→ Lila, 90%, "Analyse fertig"
DONE          → Grün, 100%, "Abgeschlossen"
ERROR         → Rot, 0%, "Fehler aufgetreten"
```

---

## 🧠 8-PUNKTE-ANALYSE

```
1. 🔍 ÜBERBLICK
2. 📄 GEFUNDENE FAKTEN
3. 👥 BETEILIGTE AKTEURE
4. 🏢 ORGANISATIONEN & STRUKTUREN
5. 💰 GELDFLÜSSE (FALLS VORHANDEN)
6. 🧠 ANALYSE & NARRATIVE
7. 🕳️ ALTERNATIVE SICHTWEISEN
8. ⚠️ WIDERSPRÜCHE & OFFENE PUNKTE
```

---

## 🚨 TROUBLESHOOTING

### Problem: Web-Server startet nicht
```bash
# Port prüfen
lsof -i :5060

# Port freigeben
lsof -ti:5060 | xargs -r kill -9

# Neu starten
cd /home/user/flutter_app && python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

### Problem: Worker antwortet nicht
```bash
# Status prüfen
curl -I https://weltenbibliothek-worker.brandy13062.workers.dev

# Neu deployen
cd /home/user/flutter_app/cloudflare-worker && wrangler deploy
```

### Problem: Rate-Limit blockiert
```bash
# KV-Key löschen (ersetze <IP> mit deiner IP)
cd /home/user/flutter_app/cloudflare-worker && \
wrangler kv key delete --namespace-id=784db5aeeecf4ba5bc57266c19e63678 "rate_limit_<IP>"

# Oder warte 60 Sekunden
```

---

## 📚 DOKUMENTATION

```
/home/user/flutter_app/
├── README.md
├── ARCHITECTURE_v4.2_COMPLETE.md
├── VISUAL_COMPONENTS_DIAGRAM.md
├── QUICK_REFERENCE.md (diese Datei)
├── COMPLETE_CHANGELOG.md
├── FINAL_v3.5_PRODUCTION_READY.md
├── ABORT_CONTROLLER_15S_TIMEOUT.md
├── KV_RATE_LIMITING_SUCCESS.md
└── APP_ARCHITECTURE.md
```

---

**🎉 WELTENBIBLIOTHEK v4.2 - Quick Reference Card**

*Alles was du brauchst auf einen Blick!*
