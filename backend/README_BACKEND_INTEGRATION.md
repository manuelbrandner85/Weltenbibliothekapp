# 🚀 WELTENBIBLIOTHEK - BACKEND-INTEGRATION

## 📋 ÜBERSICHT

Die Weltenbibliothek Deep Research Engine nutzt ein **Client-Server-Architektur** für echte Multi-Source-Recherche:

- **Flutter-App (Client)**: UI, User-Interaktion, Ergebnisdarstellung
- **Python Backend (Server)**: WebSearch, Crawler, Datenverarbeitung

---

## 🏗️ ARCHITEKTUR

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (CLIENT)                    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  recherche_tab_mobile.dart                           │  │
│  │  → User gibt Suchbegriff ein                         │  │
│  │  → Zeigt Live-Progress                               │  │
│  │  → Rendert Ergebnisse                                │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                      │
│  ┌───────────────────▼──────────────────────────────────┐  │
│  │  backend_recherche_service.dart                      │  │
│  │  → HTTP-Requests an Backend                          │  │
│  │  → Polling für Live-Updates                          │  │
│  │  → Fallback zu Mock-Daten                            │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                      │
└──────────────────────┼──────────────────────────────────────┘
                       │ HTTP/REST
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  PYTHON BACKEND (SERVER)                    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  deep_research_api.py                                │  │
│  │  → HTTP API Server (Port 8080)                       │  │
│  │  → Request-Management                                │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                      │
│  ┌───────────────────▼──────────────────────────────────┐  │
│  │  DeepResearchEngine                                  │  │
│  │  → WebSearch Integration                             │  │
│  │  → Crawler Integration                               │  │
│  │  → Parallele Verarbeitung                            │  │
│  │  → Rate-Limiting                                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                       │
                       │ Tool Calls
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                   GENSPARK TOOLS                            │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │  WebSearch   │  │   Crawler    │  │  Summarize     │  │
│  │              │  │              │  │                 │  │
│  │ • Findet URLs│  │ • Liest HTML │  │ • Fasst zusammen│  │
│  │ • Filtert    │  │ • Extrahiert │  │ • Übersetzt     │  │
│  │ • Ranked     │  │ • Bereinigt  │  │ • Strukturiert  │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 SETUP & INSTALLATION

### **1. BACKEND STARTEN (Python)**

```bash
# Wechsle in Backend-Verzeichnis
cd /home/user/flutter_app/backend

# Mache Skript ausführbar
chmod +x deep_research_api.py

# Starte Backend-Server
python3 deep_research_api.py
```

**Output:**
```
============================================================
🌐 WELTENBIBLIOTHEK DEEP RESEARCH API
============================================================
Server: http://localhost:8080
Endpoints:
  POST /api/recherche/start
  GET  /api/recherche/status/{requestId}
============================================================
✅ Server läuft auf Port 8080
Drücke CTRL+C zum Beenden
```

### **2. FLUTTER-APP KONFIGURIEREN**

**Öffne:** `lib/screens/materie/recherche_tab_mobile.dart`

```dart
// Ändere Backend-URL auf lokalen Server
final _rechercheService = BackendRechercheService(
  baseUrl: 'http://localhost:8080',  // Lokaler Backend-Server
);
```

**Für Produktion:**
```dart
final _rechercheService = BackendRechercheService(
  baseUrl: 'https://api.weltenbibliothek.ai',  // Produktions-Server
);
```

### **3. FLUTTER-APP STARTEN**

```bash
# Im Flutter-Projekt-Verzeichnis
cd /home/user/flutter_app

# Web-Preview starten
flutter run -d web-server --web-port 5060
```

---

## 🌐 API-DOKUMENTATION

### **POST /api/recherche/start**

Startet eine neue Deep-Recherche.

**Request:**
```json
{
  "query": "Ukraine Krieg",
  "sources": [
    "reuters.com",
    "spiegel.de",
    "zeit.de",
    "bbc.com",
    "bundesregierung.de",
    "archive.org"
  ],
  "language": "de",
  "maxResults": 20,
  "includeSummary": true
}
```

**Response:**
```json
{
  "success": true,
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "quellen": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000_0",
      "title": "Reuters: Ukraine Krieg - Aktuelle Entwicklungen",
      "url": "https://www.reuters.com/world/ukraine-krieg",
      "sourceType": "news",
      "status": "pending"
    }
  ],
  "status": "running"
}
```

### **GET /api/recherche/status/{requestId}**

Holt den aktuellen Status einer laufenden Recherche.

**Response:**
```json
{
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "running",
  "progress": 0.6,
  "quellen": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000_0",
      "title": "Reuters: Ukraine Krieg",
      "url": "https://www.reuters.com/world/ukraine-krieg",
      "sourceType": "news",
      "status": "success",
      "content": "Vollständiger Artikel-Text...",
      "summary": "Zusammenfassung auf Deutsch...",
      "contentLength": 2500
    }
  ]
}
```

---

## 🔄 WORKFLOW

### **USER-PERSPEKTIVE**

1. User öffnet Recherche-Tab
2. User gibt Suchbegriff ein: "Ukraine Krieg"
3. User drückt "Suchen"
4. **Live-Progress wird angezeigt:**
   - ⏳ Suche URLs... (WebSearch)
   - 🔄 Lade Inhalte... (Crawler)
   - 1/6 Reuters ✓
   - 2/6 Spiegel ✓
   - 3/6 BBC ✓
   - ...
5. User sieht vollständige Ergebnisse mit Volltexten

### **TECHNISCHER ABLAUF**

**Flutter-App:**
```dart
// 1. User-Input
final suchbegriff = "Ukraine Krieg";

// 2. Backend-Request
final service = BackendRechercheService();
final ergebnis = await service.recherchieren(suchbegriff);

// 3. Live-Updates über Stream
service.ergebnisStream.listen((update) {
  setState(() {
    // UI aktualisieren
  });
});
```

**Backend:**
```python
# 1. WebSearch
urls = await websearch(query, sources)

# 2. Paralleles Crawling
for url in urls:
    content = await crawler(url)
    
# 3. Zusammenfassung
summary = await summarize(content, language="de")

# 4. Ergebnisse zurück an Flutter
return {
    'quellen': [...]
}
```

---

## 🎯 INTEGRATION MIT ECHTEN TOOLS

### **OPTION 1: Genspark WebSearch API**

**Aktueller Stand:** Mock-Daten
**Integration:**

```python
# In deep_research_api.py

async def _websearch(self, query, sources, max_results):
    """WebSearch mit Genspark API"""
    
    # VORHER (Mock):
    # urls = [{'title': f'{domain}: {query}', ...}]
    
    # NACHHER (Echt):
    from genspark_api import WebSearch
    
    results = await WebSearch.search(
        query=query,
        allowed_domains=sources,
        max_results=max_results,
        language='de',
    )
    
    return [
        {'title': r.title, 'url': r.url}
        for r in results
    ]
```

### **OPTION 2: Genspark Crawler API**

**Aktueller Stand:** Mock-Inhalte
**Integration:**

```python
# In deep_research_api.py

async def _crawl(self, url):
    """Crawler mit Genspark API"""
    
    # VORHER (Mock):
    # return {'text': 'Mock-Text...', 'summary': '...'}
    
    # NACHHER (Echt):
    from genspark_api import Crawler, Summarize
    
    # 1. Crawle Website
    content = await Crawler.fetch(url)
    
    # 2. Fasse zusammen auf Deutsch
    summary = await Summarize.summarize(
        text=content.text,
        language='de',
        max_length=200,
    )
    
    return {
        'text': content.text,
        'summary': summary,
    }
```

---

## 📊 PERFORMANCE & RATE-LIMITING

### **PARALLELE VERARBEITUNG**

```python
# Konfiguration in DeepResearchEngine
self.max_parallel = 5  # Max. 5 gleichzeitige Requests
self.rate_limit_delay = 1.0  # 1 Sekunde zwischen Requests
```

**Beispiel:**
- 20 Quellen
- Max 5 parallel
- 1s Delay pro Request

**Dauer:**
- Batch 1 (5 Quellen): 1s
- Batch 2 (5 Quellen): 1s
- Batch 3 (5 Quellen): 1s
- Batch 4 (5 Quellen): 1s

**Total:** ~4 Sekunden für 20 Quellen

### **OPTIMIERUNG**

1. **Caching:** Speichere bereits gecrawlte Inhalte
2. **CDN:** Nutze CDN für häufig angefragte Quellen
3. **Background Jobs:** Queue-System für große Recherchen
4. **Database:** Persistiere Ergebnisse in PostgreSQL

---

## 🧪 TESTING

### **1. Backend Testen**

```bash
# Starte Backend
python3 deep_research_api.py

# In anderem Terminal: Test-Request
curl -X POST http://localhost:8080/api/recherche/start \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Ukraine Krieg",
    "sources": ["reuters.com", "spiegel.de"],
    "language": "de",
    "maxResults": 5
  }'
```

**Expected Output:**
```json
{
  "success": true,
  "requestId": "...",
  "quellen": [...],
  "status": "running"
}
```

### **2. Status Abfragen**

```bash
# Request-ID aus vorherigem Response verwenden
curl http://localhost:8080/api/recherche/status/550e8400-...
```

### **3. Flutter-App Testen**

```bash
# Flutter-App mit Backend-Verbindung
flutter run -d web-server --web-port 5060
```

**Test-Szenarien:**
1. Suchbegriff eingeben → "Ukraine Krieg"
2. Live-Progress beobachten
3. Ergebnisse prüfen
4. Volltexte expandieren
5. Quellen-Tabs durchgehen

---

## 🚀 DEPLOYMENT

### **BACKEND DEPLOYMENT (Docker)**

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY backend/deep_research_api.py .
COPY backend/requirements.txt .

RUN pip install -r requirements.txt

EXPOSE 8080

CMD ["python3", "deep_research_api.py"]
```

```bash
# Build
docker build -t weltenbibliothek-backend .

# Run
docker run -p 8080:8080 weltenbibliothek-backend
```

### **FLUTTER DEPLOYMENT (Web)**

```bash
# Build für Web
flutter build web --release

# Deploy auf Server (z.B. Nginx)
cp -r build/web/* /var/www/weltenbibliothek/
```

---

## 🔒 SICHERHEIT

### **1. API-KEY AUTHENTICATION**

```python
# Backend: API-Key Validation
def validate_api_key(request):
    api_key = request.headers.get('X-API-Key')
    if api_key != os.getenv('API_KEY'):
        return {'error': 'Unauthorized'}, 401
```

```dart
// Flutter: API-Key senden
final response = await http.post(
  uri,
  headers: {
    'X-API-Key': 'your-secret-key',
  },
);
```

### **2. RATE LIMITING**

```python
# Pro Client: 10 Requests/Minute
from ratelimit import limits

@limits(calls=10, period=60)
def handle_request():
    ...
```

### **3. CORS**

```python
# Backend: CORS-Headers
self.send_header('Access-Control-Allow-Origin', 'https://weltenbibliothek.ai')
self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
```

---

## 📈 MONITORING

### **BACKEND LOGS**

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
)

logger = logging.getLogger(__name__)
logger.info(f"Recherche gestartet: {query}")
```

### **METRIKEN**

```python
# Prometheus-Metriken
from prometheus_client import Counter, Histogram

recherche_counter = Counter('recherchen_total', 'Anzahl Recherchen')
recherche_duration = Histogram('recherche_dauer_sekunden', 'Dauer')

@recherche_duration.time()
def recherchieren():
    recherche_counter.inc()
    ...
```

---

## 💡 NEXT STEPS

### **PHASE 1: MOCK → ECHT** ✅ AKTUELL
- ✅ Backend-API implementiert
- ✅ Flutter-Integration vorbereitet
- ⏳ **TODO:** Echte WebSearch-API anbinden
- ⏳ **TODO:** Echte Crawler-API anbinden

### **PHASE 2: OPTIMIERUNG**
- [ ] Caching-Layer
- [ ] Database-Persistenz
- [ ] Background-Jobs
- [ ] CDN-Integration

### **PHASE 3: PRODUKTION**
- [ ] Docker-Container
- [ ] CI/CD Pipeline
- [ ] Monitoring & Logging
- [ ] Skalierung

---

## 🆘 TROUBLESHOOTING

### **Problem: Backend nicht erreichbar**

```bash
# Check: Läuft Backend?
ps aux | grep deep_research_api.py

# Check: Port 8080 frei?
lsof -i :8080

# Check: Firewall?
sudo ufw allow 8080
```

### **Problem: CORS-Fehler**

```python
# Backend: Prüfe CORS-Headers
self.send_header('Access-Control-Allow-Origin', '*')
```

### **Problem: Timeout**

```dart
// Flutter: Erhöhe Timeout
final response = await http.post(
  uri,
).timeout(const Duration(seconds: 60));
```

---

## 📞 SUPPORT

Bei Fragen oder Problemen:
- **Dokumentation:** `/home/user/flutter_app/backend/README_BACKEND_INTEGRATION.md`
- **Logs:** Backend-Terminal für Live-Logs
- **Testing:** `curl` Requests an Backend-API

---

**🎉 WELTENBIBLIOTHEK BACKEND-INTEGRATION - READY!**
