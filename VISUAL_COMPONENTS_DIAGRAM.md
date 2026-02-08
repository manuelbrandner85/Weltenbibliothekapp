# 🎨 WELTENBIBLIOTHEK v4.2 - VISUELLE KOMPONENTEN-ÜBERSICHT

**Vollständige Architektur-Visualisierung**

---

## 🏗️ HAUPT-ARCHITEKTUR (DETAILLIERT)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         WELTENBIBLIOTHEK v4.2                            │
│                    Kritisches Recherche-Tool                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
        ┌───────────▼──────────┐       ┌───────────▼──────────┐
        │   FLUTTER APP        │       │  CLOUDFLARE WORKER    │
        │   (Frontend)         │◄─────►│  (Backend)            │
        └──────────────────────┘       └───────────────────────┘
                 │                                  │
                 │                                  │
        ┌────────▼────────┐              ┌─────────▼─────────┐
        │  UIStateManager │              │ RequestOrchestrator│
        └─────────────────┘              └────────────────────┘
```

---

## 📱 FLUTTER APP - KOMPONENTEN-BAUM

```
RechercheTool (Flutter App)
│
├── 📥 InputController
│   ├── TextField (Material Design 3)
│   │   ├── Decoration: OutlineInputBorder
│   │   ├── Label: "Suchbegriff eingeben"
│   │   └── MaxLength: 100
│   │
│   ├── Validation-Logic
│   │   ├── onChange: checkLength()
│   │   ├── errorText: "Mindestens 3 Zeichen"
│   │   └── Enable/Disable Button
│   │
│   └── Session-Management
│       ├── sessionId: UUID
│       ├── timestamp: ISO-8601
│       └── query: String
│
├── 🎛️ UIStateManager (State Machine)
│   │
│   ├── Enum SearchStatus {
│   │   ├── idle         → Colors.grey[400]
│   │   ├── loading      → Colors.blue
│   │   ├── sourcesFound → Colors.orange
│   │   ├── analysisReady→ Colors.purple
│   │   ├── done         → Colors.green
│   │   └── error        → Colors.red
│   │   }
│   │
│   ├── State-Variables
│   │   ├── searchStatus: SearchStatus = idle
│   │   ├── progress: double = 0.0
│   │   ├── phaseText: String = ""
│   │   ├── resultText: String = ""
│   │   └── errorMessage: String? = null
│   │
│   └── State-Transitions
│       ├── IDLE → LOADING (onClick: startRecherche)
│       ├── LOADING → SOURCES_FOUND (onResponse: results)
│       ├── SOURCES_FOUND → ANALYSIS_READY (onAnalyse)
│       ├── ANALYSIS_READY → DONE (onComplete)
│       └── ANY → ERROR (onError)
│
├── 🔗 NetworkController
│   │
│   ├── HTTP-Client (dart:http)
│   │   ├── BaseURL: https://weltenbibliothek-worker.brandy13062.workers.dev
│   │   ├── Method: GET
│   │   ├── Timeout: 30 seconds
│   │   └── Headers: { Accept: application/json }
│   │
│   ├── Request-Builder
│   │   ├── buildURL(query) → ?q=${encodeURIComponent(query)}
│   │   └── addHeaders()
│   │
│   ├── Response-Parser
│   │   ├── parseJSON(response.body)
│   │   ├── extractStatus()
│   │   ├── extractResults()
│   │   └── extractAnalyse()
│   │
│   └── Error-Handler
│       ├── HTTP 429 → "Zu viele Anfragen. Warte 60s"
│       ├── HTTP 4xx → "Ungültige Anfrage"
│       ├── HTTP 5xx → "Server-Fehler"
│       ├── Timeout → "Anfrage dauert zu lange"
│       └── Network → "Keine Verbindung zum Server"
│
└── 🎨 MediaRenderer
    │
    ├── AppBar
    │   ├── Title: "Recherche – Welt & Materie"
    │   ├── Status-Badge (rechts)
    │   │   ├── Container
    │   │   ├── Padding: 8x16
    │   │   ├── BorderRadius: 12
    │   │   ├── Color: searchStatus.color
    │   │   └── Text: searchStatus.name
    │   └── BackButton: Navigator.pop()
    │
    ├── Body → SingleChildScrollView
    │   │
    │   ├── Status-Card
    │   │   ├── Icon: searchStatus.icon
    │   │   ├── Color: searchStatus.color
    │   │   ├── Text: searchStatus.displayText
    │   │   └── Elevation: 2
    │   │
    │   ├── Input-Section (wenn idle/error)
    │   │   ├── TextField (controller)
    │   │   ├── ErrorText (wenn validation failed)
    │   │   └── SizedBox(height: 16)
    │   │
    │   ├── Progress-Section (wenn loading)
    │   │   ├── LinearProgressIndicator
    │   │   │   ├── Value: progress (0.0 - 1.0)
    │   │   │   └── Color: searchStatus.color
    │   │   ├── SizedBox(height: 8)
    │   │   └── Text(phaseText)
    │   │       ├── Style: italic
    │   │       └── Color: Colors.blue
    │   │
    │   ├── Result-Section (wenn done)
    │   │   ├── Card
    │   │   ├── Padding: 16
    │   │   └── SelectableText(resultText)
    │   │       ├── Style: monospace
    │   │       └── Selectable: true
    │   │
    │   └── Action-Button
    │       ├── ElevatedButton
    │       ├── Text: "Recherche starten"
    │       ├── Icon: Icons.search
    │       ├── onPressed: startRecherche()
    │       └── Enabled: queryLength >= 3 && !isSearching
    │
    └── Result-Formatter
        ├── Header: "🔍 RECHERCHE: ${query}"
        ├── Status-Line: "Status: ${status}"
        ├── Sources-Status: "✅ Web: ${web}, 📄 Docs: ${docs}"
        ├── Analyse-Content:
        │   ├── 🔍 ÜBERBLICK
        │   ├── 📄 GEFUNDENE FAKTEN
        │   ├── 👥 BETEILIGTE AKTEURE
        │   ├── 🏢 ORGANISATIONEN & STRUKTUREN
        │   ├── 💰 GELDFLÜSSE
        │   ├── 🧠 ANALYSE & NARRATIVE
        │   ├── 🕳️ ALTERNATIVE SICHTWEISEN
        │   └── ⚠️ WIDERSPRÜCHE & OFFENE PUNKTE
        └── Footer: "Timestamp: ${timestamp}"
```

---

## ☁️ CLOUDFLARE WORKER - KOMPONENTEN-BAUM

```
Cloudflare Worker v4.2
│
├── 🎛️ RequestOrchestrator
│   │
│   ├── Request-Handler (fetch)
│   │   ├── Parse URL: new URL(request.url)
│   │   ├── Extract Query: url.searchParams.get("q")
│   │   └── Validate Query: if (!query) → 400 Error
│   │
│   ├── CORS-Handler (OPTIONS)
│   │   ├── Headers:
│   │   │   ├── Access-Control-Allow-Origin: *
│   │   │   ├── Access-Control-Allow-Methods: GET, POST, OPTIONS
│   │   │   └── Access-Control-Allow-Headers: Content-Type
│   │   └── Return: new Response(null, { headers })
│   │
│   ├── 💾 Cache-Manager
│   │   ├── cacheKey: new Request(request.url)
│   │   ├── cache: caches.default
│   │   ├── Check: await cache.match(cacheKey)
│   │   ├── HIT? → Return with X-Cache-Status: HIT
│   │   └── MISS? → Continue to Rate-Limiter
│   │
│   ├── 🚦 Rate-Limiter (KV-based)
│   │   ├── clientIP: request.headers.get("CF-Connecting-IP")
│   │   ├── rateLimitKey: `rate_limit_${clientIP}`
│   │   ├── requestCount: await env.RATE_LIMIT_KV.get(rateLimitKey)
│   │   ├── if (requestCount > 3):
│   │   │   └── Return HTTP 429 + Retry-After: 60
│   │   └── else:
│   │       └── await env.RATE_LIMIT_KV.put(key, count+1, {ttl: 60})
│   │
│   └── Response-Formatter
│       ├── Build JSON Response:
│       │   ├── status: "ok" | "fallback" | "limited" | "error"
│       │   ├── message: String?
│       │   ├── query: String
│       │   ├── results: { web, documents, media }
│       │   ├── analyse: { inhalt, mitDaten, fallback, timestamp }
│       │   └── sourcesStatus: { web, documents, media }
│       │
│       └── Cache Response:
│           ├── Headers: Cache-Control: public, max-age=3600
│           ├── Store: await cache.put(cacheKey, response.clone())
│           └── Return: Response with X-Cache-Status: MISS
│
├── 🕷️ SourceCrawler (Sequenziell)
│   │
│   ├── 🌐 fetchWeb(query, env)
│   │   │
│   │   ├── Source 1: DuckDuckGo HTML
│   │   │   ├── URL: https://html.duckduckgo.com/html/?q=${query}
│   │   │   ├── Timeout: 15s (AbortController)
│   │   │   ├── User-Agent: "RechercheTool/1.0"
│   │   │   ├── MaxChars: 3000
│   │   │   └── try/catch:
│   │   │       ├── if (!res.ok) throw Error
│   │   │       └── catch → console.error, continue
│   │   │
│   │   ├── Wait: 800ms (Rate-Limit-Schutz)
│   │   │
│   │   ├── Source 2: Wikipedia (via Jina)
│   │   │   ├── URL: https://r.jina.ai/https://de.wikipedia.org/wiki/${query}
│   │   │   ├── Timeout: 15s (AbortController)
│   │   │   ├── User-Agent: "RechercheTool/1.0"
│   │   │   ├── MaxChars: 6000
│   │   │   └── try/catch:
│   │   │       ├── if (!res.ok) throw Error
│   │   │       └── catch → console.error, continue
│   │   │
│   │   └── Return: Array<{source, type, content, charCount}>
│   │
│   ├── 📦 fetchDocs(query, env)
│   │   │
│   │   ├── Source: Internet Archive
│   │   │   ├── URL: https://archive.org/advancedsearch.php
│   │   │   ├── Query: ?q=${query}&output=json&rows=5
│   │   │   ├── Timeout: 15s (AbortController)
│   │   │   └── try/catch:
│   │   │       ├── if (!res.ok) throw Error
│   │   │       ├── parse JSON: data.response.docs
│   │   │       └── catch → return []
│   │   │
│   │   └── Return: Array<{source, type, title, identifier, mediatype}>
│   │
│   ├── 🎬 fetchMedia(query, env)
│   │   │
│   │   ├── Source: Internet Archive (Media)
│   │   │   ├── URL: https://archive.org/advancedsearch.php
│   │   │   ├── Query: ?q=${query}&mediatype=(movies OR audio)&output=json&rows=3
│   │   │   ├── Timeout: 15s (AbortController)
│   │   │   └── try/catch:
│   │   │       ├── if (!res.ok) throw Error
│   │   │       ├── parse JSON: data.response.docs
│   │   │       └── catch → return []
│   │   │
│   │   └── Return: Array<{source, type, title, identifier, mediatype}>
│   │
│   └── 🔄 Crawling-Workflow
│       ├── 1️⃣ results.web = await fetchWeb(query, env)
│       ├── 2️⃣ if (results.web.length < 3):
│       │       results.documents = await fetchDocs(query, env)
│       ├── 3️⃣ if (results.documents.length > 0):
│       │       results.media = await fetchMedia(query, env)
│       └── 4️⃣ Continue to AI-Analyzer
│
├── 🤖 CloudflareAI_Analyzer
│   │
│   ├── 🧠 analyzeWithAI(query, results, env)
│   │   │
│   │   ├── Input-Processing
│   │   │   ├── Extract: results.web (type: text)
│   │   │   ├── Join: textContent = content.join("\n\n")
│   │   │   └── Truncate: .slice(0, 8000)
│   │   │
│   │   ├── Prompt-Builder
│   │   │   ├── System: "Du bist ein kritischer Recherche-Analyst der WELTENBIBLIOTHEK"
│   │   │   ├── Context: `Analysiere folgende Informationen zum Thema "${query}":`
│   │   │   ├── Content: ${textContent}
│   │   │   └── Structure: 8-Punkte-Schema
│   │   │       ├── 🔍 ÜBERBLICK
│   │   │       ├── 📄 GEFUNDENE FAKTEN
│   │   │       ├── 👥 BETEILIGTE AKTEURE
│   │   │       ├── 🏢 ORGANISATIONEN & STRUKTUREN
│   │   │       ├── 💰 GELDFLÜSSE (FALLS VORHANDEN)
│   │   │       ├── 🧠 ANALYSE & NARRATIVE
│   │   │       ├── 🕳️ ALTERNATIVE SICHTWEISEN
│   │   │       └── ⚠️ WIDERSPRÜCHE & OFFENE PUNKTE
│   │   │
│   │   ├── AI-Execution
│   │   │   ├── Model: @cf/meta/llama-3.1-8b-instruct
│   │   │   ├── Parameters:
│   │   │   │   ├── prompt: <structured_prompt>
│   │   │   │   └── max_tokens: 2000
│   │   │   └── await env.AI.run(model, params)
│   │   │
│   │   └── Return: {
│   │       ├── inhalt: aiResponse.response
│   │       ├── mitDaten: true
│   │       ├── fallback: false
│   │       └── timestamp: new Date().toISOString()
│   │       }
│   │
│   └── 🆘 cloudflareAIFallback(query, env)
│       │
│       ├── Input: Nur Query (keine Primärdaten)
│       │
│       ├── Prompt-Builder
│       │   ├── Warning: "Zum Thema "${query}" konnten KEINE externen Primärquellen abgerufen werden"
│       │   └── Structure: Theoretische Einordnung
│       │       ├── 🔍 THEMATISCHER KONTEXT
│       │       ├── ❓ TYPISCHE FRAGESTELLUNGEN
│       │       ├── 👥 RELEVANTE AKTEURE & ORGANISATIONEN
│       │       ├── 🕳️ ALTERNATIVE PERSPEKTIVEN
│       │       ├── 🚫 WISSENSLÜCKEN
│       │       └── 📚 EMPFOHLENE QUELLEN
│       │
│       ├── AI-Execution
│       │   ├── Model: @cf/meta/llama-3.1-8b-instruct
│       │   ├── Parameters:
│       │   │   ├── prompt: <fallback_prompt>
│       │   │   └── max_tokens: 1500
│       │   └── await env.AI.run(model, params)
│       │
│       └── Return: {
│           ├── inhalt: "⚠️ THEORETISCHE EINORDNUNG OHNE PRIMÄRDATEN\n\n" + aiResponse.response
│           ├── mitDaten: false
│           ├── fallback: true
│           └── timestamp: new Date().toISOString()
│           }
│
└── 📊 Analytics-Logger (Optional)
    ├── Log Query
    ├── Log Response-Time
    ├── Log Success-Rate
    └── Log Error-Types
```

---

## 🔄 SEQUENZIELLES CRAWLING-FLUSSDIAGRAMM

```
START
  │
  ├─→ 1️⃣ PHASE 1: WEB-QUELLEN (IMMER)
  │   │
  │   ├─→ fetchWeb(query, env)
  │   │   │
  │   │   ├─→ DuckDuckGo HTML (15s timeout)
  │   │   │   ├─ SUCCESS → results.web.push(data)
  │   │   │   └─ ERROR → console.error, continue
  │   │   │
  │   │   ├─→ Wait 800ms
  │   │   │
  │   │   └─→ Wikipedia via Jina (15s timeout)
  │   │       ├─ SUCCESS → results.web.push(data)
  │   │       └─ ERROR → console.error, continue
  │   │
  │   ├─→ results.web = [...]
  │   │
  │   ├─→ 🔍 CHECK: results.web.length >= 3?
  │   │   │
  │   │   ├─ YES (>=3) → SKIP Phase 2
  │   │   │              └─→ GO TO Phase 4 (AI)
  │   │   │
  │   │   └─ NO (<3) → CONTINUE to Phase 2
  │
  ├─→ 2️⃣ PHASE 2: DOKUMENTE (NUR WENN WEB < 3)
  │   │
  │   ├─→ fetchDocs(query, env)
  │   │   │
  │   │   └─→ Archive.org Search (15s timeout)
  │   │       ├─ SUCCESS → results.documents = [...]
  │   │       └─ ERROR → results.documents = []
  │   │
  │   ├─→ 🔍 CHECK: results.documents.length > 0?
  │   │   │
  │   │   ├─ YES (>0) → CONTINUE to Phase 3
  │   │   │
  │   │   └─ NO (=0) → SKIP Phase 3
  │   │                └─→ GO TO Phase 4 (AI)
  │
  ├─→ 3️⃣ PHASE 3: MEDIEN (NUR WENN DOCS > 0)
  │   │
  │   ├─→ fetchMedia(query, env)
  │   │   │
  │   │   └─→ Archive.org Media (15s timeout)
  │   │       ├─ SUCCESS → results.media = [...]
  │   │       └─ ERROR → results.media = []
  │   │
  │   └─→ CONTINUE to Phase 4
  │
  └─→ 4️⃣ PHASE 4: KI-ANALYSE
      │
      ├─→ 🔍 CHECK: hasData?
      │   │         hasData = results.web.length > 0 ||
      │   │                   results.documents.length > 0 ||
      │   │                   results.media.length > 0
      │   │
      │   ├─ YES → analyzeWithAI(query, results, env)
      │   │        │
      │   │        ├─→ Collect text-content (max 8000 chars)
      │   │        ├─→ Build 8-Punkte-Prompt
      │   │        ├─→ Execute Llama 3.1 8B (2000 tokens)
      │   │        └─→ Return: {inhalt, mitDaten: true, fallback: false}
      │   │
      │   └─ NO → cloudflareAIFallback(query, env)
      │            │
      │            ├─→ Build Theoretische-Einordnung-Prompt
      │            ├─→ Execute Llama 3.1 8B (1500 tokens)
      │            └─→ Return: {inhalt, mitDaten: false, fallback: true}
      │
      └─→ RESPONSE-BUILDING
          │
          ├─→ status: hasData ? "ok" : "fallback"
          ├─→ message: hasData ? null : "Keine externen Quellen..."
          ├─→ query: query
          ├─→ results: { web, documents, media }
          ├─→ analyse: { inhalt, mitDaten, fallback, timestamp }
          ├─→ sourcesStatus: { web: X, documents: Y, media: Z }
          │
          ├─→ CACHE-STORE (1h TTL)
          │
          └─→ RETURN HTTP 200 + JSON
```

---

## 🎨 UI STATE-MACHINE FLUSSDIAGRAMM

```
┌──────────┐
│   IDLE   │ (Grau, 0%)
└────┬─────┘
     │ onClick: startRecherche()
     │
┌────▼─────────┐
│   LOADING    │ (Blau, 10%)
│ "Verbinde..."│
└────┬─────────┘
     │ HTTP GET → Worker
     │
┌────▼──────────────┐
│  SOURCES_FOUND    │ (Orange, 50%)
│ "Quellen gef..."  │
└────┬──────────────┘
     │ Parse: response.results
     │
┌────▼──────────────┐
│  ANALYSIS_READY   │ (Lila, 90%)
│ "Analyse fertig"  │
└────┬──────────────┘
     │ Parse: response.analyse
     │
┌────▼─────┐
│   DONE   │ (Grün, 100%)
│ "Fertig!"│
└──────────┘

     │ (bei Fehler)
     │
┌────▼─────┐
│  ERROR   │ (Rot, 0%)
│ "Fehler!"│
└──────────┘
```

---

## 🔐 RATE-LIMITING-ARCHITEKTUR

```
Rate-Limiting-System (KV-based)
│
├── Input: request.headers.get("CF-Connecting-IP")
│   └── clientIP: "192.168.1.100"
│
├── Key-Generation
│   └── rateLimitKey: `rate_limit_192.168.1.100`
│
├── KV-Lookup
│   ├── await env.RATE_LIMIT_KV.get(rateLimitKey)
│   └── requestCount: 0 | 1 | 2 | 3 | 4+
│
├── Decision-Logic
│   │
│   ├── if (requestCount <= 3):
│   │   ├── Allow Request
│   │   ├── Increment: await env.RATE_LIMIT_KV.put(key, count+1, {ttl: 60})
│   │   └── Continue to SourceCrawler
│   │
│   └── if (requestCount > 3):
│       ├── Block Request
│       ├── Return: HTTP 429
│       ├── Headers:
│       │   ├── X-Rate-Limit-Exceeded: true
│       │   └── Retry-After: 60
│       └── Body: {
│           ├── status: "limited"
│           ├── message: "Zu viele Anfragen. Bitte kurz warten."
│           ├── retryAfter: 60
│           └── requestCount: 4
│           }
│
└── Auto-Reset (TTL)
    └── Nach 60 Sekunden: KV-Key expires → requestCount = 0
```

---

## 💾 CACHE-SYSTEM-ARCHITEKTUR

```
Cache-System (Cloudflare Cache API)
│
├── Cache-Key-Generation
│   └── cacheKey: new Request(request.url, request)
│       └── Example: "https://worker.dev?q=Berlin"
│
├── Cache-Lookup
│   ├── const cache = caches.default
│   ├── cachedResponse = await cache.match(cacheKey)
│   │
│   ├── CACHE HIT?
│   │   ├── YES → Return cached response
│   │   │   ├── Add Header: X-Cache-Status: HIT
│   │   │   ├── Response-Time: 50-100ms
│   │   │   └── ⚡ 57x SCHNELLER
│   │   │
│   │   └── NO → Continue to Rate-Limiter
│   │       └── Add Header: X-Cache-Status: MISS
│   │
│   └── Cache-Storage (nach erfolgreicher Recherche)
│       ├── Headers: Cache-Control: public, max-age=3600
│       ├── TTL: 1 Stunde (3600s)
│       └── await cache.put(cacheKey, response.clone())
│
└── Cache-Invalidation
    ├── Automatisch nach 1h (TTL expired)
    └── Manuell: cache.delete(cacheKey)
```

---

## 📊 8-PUNKTE-ANALYSE-TEMPLATE

```
KI-ANALYSE-OUTPUT
│
├── 🔍 ÜBERBLICK
│   └── "Der <Thema> ist ein komplexes Thema, das..."
│       └── 2-3 Sätze Zusammenfassung
│
├── 📄 GEFUNDENE FAKTEN
│   ├── "* Fakt 1: ..."
│   ├── "* Fakt 2: ..."
│   └── "* Fakt 3: ..."
│
├── 👥 BETEILIGTE AKTEURE
│   ├── "* Person/Gruppe A (Rolle X)"
│   ├── "* Person/Gruppe B (Rolle Y)"
│   └── "* Person/Gruppe C (Rolle Z)"
│
├── 🏢 ORGANISATIONEN & STRUKTUREN
│   ├── "* Institution A"
│   ├── "* Institution B"
│   └── "* Machtstruktur: ..."
│
├── 💰 GELDFLÜSSE (FALLS VORHANDEN)
│   ├── "* Finanzierung durch X"
│   ├── "* Profiteure: Y, Z"
│   └── "* Wirtschaftliche Abhängigkeit: ..."
│
├── 🧠 ANALYSE & NARRATIVE
│   ├── "* Narrativ 1: ..."
│   ├── "* Narrativ 2: ..."
│   └── "* Mediale Darstellung: ..."
│
├── 🕳️ ALTERNATIVE SICHTWEISEN
│   ├── "* Alternative Interpretation 1: ..."
│   ├── "* Alternative Interpretation 2: ..."
│   └── "* Oft ausgelassen: ..."
│
└── ⚠️ WIDERSPRÜCHE & OFFENE PUNKTE
    ├── "* Ungereimtheit 1: ..."
    ├── "* Ungereimtheit 2: ..."
    └── "* Offene Frage: ..."
```

---

**🎉 WELTENBIBLIOTHEK v4.2 - Vollständige Architektur-Dokumentation**

*Kritische Recherche für alternative Sichtweisen*
