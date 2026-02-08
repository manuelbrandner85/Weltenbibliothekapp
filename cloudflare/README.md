# 🌐 Cloudflare Worker Setup - Weltenbibliothek Research Backend

## 📋 Übersicht

Dieser Cloudflare Worker bietet die Backend-Funktionalität für die Internet-Recherche in der Weltenbibliothek App.

## ✨ Features

### 1. **AI-Integration (Perplexity API)**
- **Model**: llama-3.1-sonar-large-128k-online
- **Features**: Real-time web search mit KI-Analyse
- **Fokus**: Alternative & unabhängige Quellen priorisiert

### 2. **Web Scraping**
- **Endpoint**: `/api/scrape`
- **Features**: Extraktion von Titel & Content
- **Use Case**: Volltext-Analyse von Quellen

### 3. **KV Storage (Caching)**
- **Namespace**: `RESEARCH_CACHE`
- **TTL**: 1 Stunde
- **Use Case**: Search History & Query Caching

### 4. **Source Analysis**
- **Kategorisierung**: Mainstream / Alternative / Unabhängig
- **Bias Detection**: Erkennung von Quellen-Bias
- **Credibility Score**: Bewertung der Quellen-Vielfalt

## 📂 Dateien

```
cloudflare/
├── worker.js          # Hauptlogik
├── wrangler.toml      # Konfiguration
└── README.md          # Diese Datei
```

## 🚀 Deployment

### **Voraussetzungen**
```bash
# Cloudflare CLI installieren
npm install -g wrangler

# Authentifizierung
wrangler login
```

### **1. KV Namespace erstellen**
```bash
# Production KV
wrangler kv:namespace create "RESEARCH_CACHE"

# Preview KV (für Development)
wrangler kv:namespace create "RESEARCH_CACHE" --preview
```

**Output:**
```
🌀 Creating namespace with title "weltenbibliothek-research-RESEARCH_CACHE"
✨ Success!
Add the following to your configuration file in your kv_namespaces array:
{ binding = "RESEARCH_CACHE", id = "abc123..." }
```

**Füge die IDs in `wrangler.toml` ein!**

### **2. Worker deployen**
```bash
cd cloudflare/

# Development Preview
wrangler dev

# Production Deployment
wrangler deploy
```

### **3. Routes konfigurieren**
```bash
# Route hinzufügen (in Cloudflare Dashboard oder via CLI)
wrangler route add "weltenbibliothek.ai/api/*" --zone weltenbibliothek.ai
```

## 🔧 Konfiguration

### **Environment Variables**
In `wrangler.toml`:
```toml
[vars]
PERPLEXITY_API_KEY = "sk-or-v1-..."
ENVIRONMENT = "production"
```

### **Secrets (Sensitive Data)**
```bash
# API Key als Secret speichern
wrangler secret put PERPLEXITY_API_KEY
# Eingabe: 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
```

## 📡 API Endpoints

### **1. POST /api/research**
Internet-Recherche durchführen

**Request:**
```json
{
  "query": "COVID-19 alternative Quellen"
}
```

**Response:**
```json
{
  "query": "COVID-19 alternative Quellen",
  "summary": "KI-generierte Zusammenfassung...",
  "sources": [
    {
      "title": "The Intercept Article",
      "url": "https://theintercept.com/...",
      "snippet": "",
      "sourceType": "alternative",
      "timestamp": "2024-01-21T..."
    }
  ],
  "followUpQuestions": [
    "Was sind alternative Perspektiven zu...?"
  ],
  "timestamp": "2024-01-21T..."
}
```

### **2. POST /api/scrape**
URL scrapen

**Request:**
```json
{
  "url": "https://example.com/article"
}
```

**Response:**
```json
{
  "url": "https://example.com/article",
  "title": "Article Title",
  "content": "Extracted content...",
  "timestamp": "2024-01-21T..."
}
```

### **3. GET /api/history**
Suchhistorie abrufen

**Query Parameters:**
- `userId` (optional): User ID
- `limit` (optional): Anzahl Einträge (default: 10)

**Response:**
```json
{
  "history": [
    {
      "query": "...",
      "timestamp": "..."
    }
  ]
}
```

### **4. POST /api/analyze**
Quellen analysieren

**Request:**
```json
{
  "sources": [
    { "url": "...", "sourceType": "mainstream" },
    { "url": "...", "sourceType": "alternative" }
  ]
}
```

**Response:**
```json
{
  "total": 10,
  "mainstream": 3,
  "alternative": 5,
  "independent": 2,
  "bias": "alternative_heavy",
  "credibility": 85
}
```

### **5. GET /health**
Health Check

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-21T...",
  "version": "1.0.0"
}
```

## 🔍 Source Categorization

### **Alternative Quellen**
```javascript
wikileaks.org
theintercept.com
propublica.org
bellingcat.com
archive.org
substack.com
telegram.org
odysee.com
bitchute.com
rumble.com
```

### **Mainstream Quellen**
```javascript
cnn.com
bbc.com
nytimes.com
washingtonpost.com
reuters.com
foxnews.com
```

### **Unabhängig**
Alle anderen Domains

## 📊 Monitoring

### **Cloudflare Dashboard**
- **Analytics**: Anfragen, Errors, Latency
- **Logs**: Real-time Logs für Debugging
- **Metrics**: CPU Time, Requests pro Sekunde

### **CLI Logs**
```bash
# Live Logs anzeigen
wrangler tail
```

## 🛡️ Security

### **Rate Limiting**
Implementiere Rate Limiting in Cloudflare Dashboard:
- **Rule**: "Weltenbibliothek API Rate Limit"
- **Match**: `api.weltenbibliothek.ai/api/*`
- **Limit**: 100 requests / minute / IP

### **API Key Protection**
- API Key als Secret speichern (siehe oben)
- Niemals im Code hardcoden
- Rotation alle 90 Tage

## 🐛 Debugging

### **Common Errors**

**1. "PERPLEXITY_API_KEY not defined"**
```bash
# Lösung: Secret setzen
wrangler secret put PERPLEXITY_API_KEY
```

**2. "KV Namespace not found"**
```bash
# Lösung: Namespace ID in wrangler.toml prüfen
wrangler kv:namespace list
```

**3. "CORS Error"**
- Prüfe CORS_HEADERS in worker.js
- Stelle sicher OPTIONS Requests werden behandelt

## 📈 Performance

### **Caching Strategy**
- **Search Results**: 1 Stunde (KV)
- **Scraping Results**: 24 Stunden (KV)
- **API Responses**: Edge Caching (Cloudflare)

### **Optimization Tips**
1. **Minimize Response Size**: Nur notwendige Daten senden
2. **Use KV wisely**: Häufige Queries cachen
3. **Parallel Requests**: Scraping parallel durchführen
4. **Compression**: Gzip/Brotli für Responses

## 🔄 Updates

### **Worker Updates**
```bash
# Code ändern in worker.js
# Dann:
wrangler deploy
```

### **Configuration Updates**
```bash
# wrangler.toml ändern
# Dann:
wrangler deploy
```

## 📞 Support

Bei Problemen:
1. **Logs prüfen**: `wrangler tail`
2. **Dashboard checken**: cloudflare.com/dashboard
3. **Dokumentation**: developers.cloudflare.com/workers

## 🎯 Next Steps

1. ✅ **Worker deployen**
2. ✅ **KV Namespace erstellen**
3. ✅ **Secrets konfigurieren**
4. ✅ **Routes einrichten**
5. ✅ **Testing durchführen**
6. ✅ **Flutter App anbinden**

---

**Version**: 1.0.0  
**Last Updated**: 21. Januar 2026  
**Status**: Production Ready
