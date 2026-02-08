# WELTENBIBLIOTHEK v5.13 – CLOUDFLARE WORKER DEPLOYMENT

## 📋 BACKEND-CODE: KANINCHENBAU-SYSTEM

Der Worker in `cloudflare_worker_rabbit_hole.js` implementiert die vollständige Kaninchenbau-Logik mit echten API-Calls.

---

## 🚀 DEPLOYMENT-SCHRITTE

### 1. Cloudflare Account Setup

```bash
# Installiere Wrangler CLI (falls noch nicht vorhanden)
npm install -g wrangler

# Login zu Cloudflare
wrangler login
```

### 2. Worker-Projekt erstellen

```bash
# Erstelle neues Worker-Projekt
mkdir weltenbibliothek-rabbit-hole-worker
cd weltenbibliothek-rabbit-hole-worker

# Initialisiere Worker
wrangler init
```

### 3. Code kopieren

```bash
# Kopiere den Worker-Code
cp /home/user/flutter_app/cloudflare_worker_rabbit_hole.js ./src/index.js
```

### 4. `wrangler.toml` konfigurieren

```toml
name = "weltenbibliothek-rabbit-hole-worker"
main = "src/index.js"
compatibility_date = "2024-01-01"

# Environment Variables (secrets)
[vars]
# Diese werden später als Secrets gesetzt

# KV Namespaces (optional für Caching)
# [[kv_namespaces]]
# binding = "RABBIT_HOLE_CACHE"
# id = "your-kv-namespace-id"
```

### 5. API-Key als Secret setzen

```bash
# Setze Gemini API Key
wrangler secret put GEMINI_API_KEY
# Gib deinen API-Key ein wenn gefragt

# Oder verwende andere KI-APIs:
# wrangler secret put OPENAI_API_KEY
# wrangler secret put ANTHROPIC_API_KEY
```

### 6. Deploy

```bash
# Teste lokal
wrangler dev

# Deploy to production
wrangler deploy
```

---

## 🔧 API-ENDPOINTS

### POST /api/rabbit-hole

**Vollständige 6-Ebenen-Recherche**

**Request:**
```json
{
  "topic": "MK Ultra",
  "config": {
    "maxDepth": 6
  }
}
```

**Response:**
```json
{
  "topic": "MK Ultra",
  "nodes": [
    {
      "level": 1,
      "title": "CIA-Programm MK-Ultra (1953-1973)",
      "content": "...",
      "sources": ["...", "..."],
      "key_findings": ["...", "..."],
      "trust_score": 85,
      "timestamp": "2025-06-07T22:30:00Z"
    },
    // ... weitere Ebenen
  ],
  "status": "completed",
  "start_time": "2025-06-07T22:30:00Z",
  "end_time": "2025-06-07T22:31:15Z",
  "max_depth": 6
}
```

### POST /api/recherche

**Einzelne Ebene recherchieren**

**Request:**
```json
{
  "query": "EBENE 2: BETEILIGTE AKTEURE\n\nThema: MK Ultra\n\nFOKUS:\n- Wer waren die Hauptakteure?",
  "level": 2,
  "context": [
    {
      "level": 1,
      "title": "CIA-Programm MK-Ultra",
      "content": "..."
    }
  ]
}
```

**Response:**
```json
{
  "title": "Sidney Gottlieb und Allen Dulles",
  "content": "...",
  "sources": ["...", "..."],
  "key_findings": ["...", "..."],
  "trust_score": 80
}
```

---

## 🔑 FUNKTIONS-ÜBERSICHT

### Ebenen-Funktionen

```javascript
// Ebene 1: Ereignis/Thema
async function extractEreignis(topic)

// Ebene 2: Beteiligte Akteure
async function extractActors(topic, previousNodes)

// Ebene 3: Organisationen & Netzwerke
async function extractOrganizations(actorsNode, previousNodes)

// Ebene 4: Geldflüsse & Interessen
async function extractMoneyFlows(orgsNode, previousNodes)

// Ebene 5: Historischer Kontext
async function fetchHistory(topic, previousNodes)

// Ebene 6: Metastrukturen & Narrative
async function extractMetastructures(previousNodes)
```

### Hilfsfunktionen

```javascript
// KI-API aufrufen
async function callAI(prompt, env)

// Trust-Score berechnen
function calculateTrustScore(sources)
```

---

## 🤖 KI-MODELL KONFIGURATION

### Standardmäßig: Gemini 2.0 Flash

```javascript
const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${apiKey}`;
```

### Alternative KI-Modelle

**OpenAI:**
```javascript
const response = await fetch('https://api.openai.com/v1/chat/completions', {
  headers: {
    'Authorization': `Bearer ${env.OPENAI_API_KEY}`,
  },
  body: JSON.stringify({
    model: 'gpt-4-turbo',
    messages: [{ role: 'user', content: prompt }],
  }),
});
```

**Anthropic Claude:**
```javascript
const response = await fetch('https://api.anthropic.com/v1/messages', {
  headers: {
    'x-api-key': env.ANTHROPIC_API_KEY,
    'anthropic-version': '2023-06-01',
  },
  body: JSON.stringify({
    model: 'claude-3-5-sonnet-20241022',
    messages: [{ role: 'user', content: prompt }],
  }),
});
```

---

## 📊 TRUST-SCORE BERECHNUNG

### Basis-Score: 50

### Positive Faktoren:
- **5+ Quellen**: +20
- **3-4 Quellen**: +10
- **2 Quellen**: +5
- **Official/Declassified**: +10 pro Quelle
- **.gov/.edu Domain**: +8 pro Quelle
- **Academic/Journal**: +8 pro Quelle
- **Archive/Library**: +5 pro Quelle

### Negative Faktoren:
- **Blog/Forum**: -5 pro Quelle
- **Anonymous**: -10 pro Quelle

### Ergebnis: Clamped auf 0-100

---

## 🔄 KONTEXTUELLE PROMPTS

Jede Ebene erhält:
1. **Spezifische Fragen** für diese Ebene
2. **Kontext** aus allen vorherigen Ebenen
3. **JSON-Schema** für strukturierte Antworten

**Beispiel Ebene 2:**
```
Thema: "MK Ultra"

KONTEXT:
Ebene 1: CIA-Programm MK-Ultra (1953-1973)

FOKUS:
- Wer waren die Hauptakteure?
- Welche Rollen hatten sie?
- Welche Motivationen hatten sie?
- Welche Verbindungen bestehen zwischen ihnen?
```

---

## 🧪 TESTING

### Lokal testen

```bash
# Starte lokalen Server
wrangler dev

# Teste mit curl
curl -X POST http://localhost:8787/api/rabbit-hole \
  -H "Content-Type: application/json" \
  -d '{"topic": "MK Ultra", "config": {"maxDepth": 3}}'
```

### Production testen

```bash
curl -X POST https://weltenbibliothek-worker.brandy13062.workers.dev/api/rabbit-hole \
  -H "Content-Type: application/json" \
  -d '{"topic": "Panama Papers"}'
```

---

## ⚡ PERFORMANCE-OPTIMIERUNGEN

### 1. Caching mit KV

```javascript
// Cache Ergebnisse für wiederholte Anfragen
const cached = await env.RABBIT_HOLE_CACHE.get(topic);
if (cached) {
  return JSON.parse(cached);
}

const result = await rabbitHole(topic, config);

// Cache für 1 Stunde
await env.RABBIT_HOLE_CACHE.put(topic, JSON.stringify(result), {
  expirationTtl: 3600,
});
```

### 2. Parallel-Requests

```javascript
// Ebenen 5 und 6 können parallel laufen
const [history, meta] = await Promise.all([
  fetchHistory(topic, nodes),
  extractMetastructures(nodes),
]);
```

### 3. Streaming-Responses

```javascript
// Stream einzelne Ebenen während Berechnung
const stream = new TransformStream();
const writer = stream.writable.getWriter();

// Schreibe Ebenen sobald fertig
for (const level of levels) {
  const node = await exploreLevel(level);
  await writer.write(JSON.stringify(node) + '\n');
}
```

---

## 🛡️ SICHERHEIT

### Rate-Limiting

```javascript
// Begrenze Anfragen pro IP
const ip = request.headers.get('CF-Connecting-IP');
const rateLimitKey = `rate-limit:${ip}`;
const count = await env.KV.get(rateLimitKey) || 0;

if (count > 10) {
  return new Response('Rate limit exceeded', { status: 429 });
}

await env.KV.put(rateLimitKey, count + 1, { expirationTtl: 60 });
```

### Input-Validierung

```javascript
// Validiere Topic-Länge
if (!topic || topic.length < 3 || topic.length > 200) {
  return new Response('Invalid topic', { status: 400 });
}

// Sanitize Input
const sanitized = topic.replace(/[<>]/g, '');
```

---

## 📝 MONITORING

### Cloudflare Analytics Dashboard

- Request-Count
- Error-Rate
- Response-Time
- Bandwidth

### Custom Logging

```javascript
console.log('Rabbit Hole started', {
  topic,
  timestamp: new Date().toISOString(),
});

console.log('Rabbit Hole completed', {
  topic,
  duration: Date.now() - startTime,
  levels: nodes.length,
});
```

---

## 🎓 FAZIT

Der Worker implementiert:
- ✅ Vollständige 6-Ebenen-Logik
- ✅ Kontextuelle Prompt-Generierung
- ✅ Trust-Score-Berechnung
- ✅ Strukturierte JSON-Antworten
- ✅ CORS-Support
- ✅ Error-Handling
- ✅ Modular erweiterbar

**Deployment-Zeit**: ~5 Minuten  
**Globale Verfügbarkeit**: Cloudflare Edge Network  
**Kosten**: Free Tier ausreichend für Testing

---

**Made with 💻 by Claude Code Agent**  
**Weltenbibliothek-Worker v5.13** 🌍📚
