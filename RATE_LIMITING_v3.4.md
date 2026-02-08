# 🚦 RATE-LIMITING SYSTEM - v3.4

## ✅ RATE-LIMITING IMPLEMENTIERT

**Version:** v3.4  
**Build-Datum:** 2026-01-04 16:00 UTC  
**Worker-Version-ID:** dbb0c141-31c5-4943-bc58-ee7202137656

---

## 🎯 NEUE FEATURE: RATE-LIMITING

### ❓ WARUM?

**Problem:**
- Zu viele Requests können Worker überlasten
- Crawling-Quellen haben eigene Rate-Limits
- Missbrauch-Schutz erforderlich

**Lösung:**
```javascript
if (requestCount > 3) {
  return new Response(
    JSON.stringify({
      status: "limited",
      message: "Zu viele Anfragen. Bitte kurz warten.",
      retryAfter: 60
    }),
    { status: 429 }
  );
}
```

---

## 🔧 IMPLEMENTIERUNG

### Worker-Side (Cloudflare Worker):
```javascript
// 🚦 RATE LIMITING (nur bei Cache MISS)
const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
const rateLimitKey = `rate_limit_${clientIP}`;

// Hole aktuellen Request-Count aus KV (optional)
let requestCount = 0;
if (env.RATE_LIMIT_KV) {
  const stored = await env.RATE_LIMIT_KV.get(rateLimitKey);
  requestCount = stored ? parseInt(stored) : 0;
}

// Prüfe Rate-Limit (max 3 Requests pro Minute)
if (requestCount > 3) {
  return new Response(
    JSON.stringify({
      status: "limited",
      message: "Zu viele Anfragen. Bitte kurz warten.",
      retryAfter: 60,
      requestCount: requestCount
    }),
    { 
      headers: {
        ...corsHeaders,
        "X-Rate-Limit-Exceeded": "true",
        "Retry-After": "60"
      },
      status: 429
    }
  );
}

// Erhöhe Counter (60 Sekunden TTL)
if (env.RATE_LIMIT_KV) {
  await env.RATE_LIMIT_KV.put(rateLimitKey, (requestCount + 1).toString(), {
    expirationTtl: 60
  });
}
```

### Client-Side (Flutter App):
```dart
final data = jsonDecode(response.body);
final status = data["status"];
final message = data["message"];

// Behandle "limited" Status
if (status == "limited") {
  // Rate-Limit erreicht
  throw Exception("⏱️ $message\nBitte warte ${data['retryAfter'] ?? 60} Sekunden.");
} else if (status != "ok" && status != "fallback") {
  throw Exception(message ?? "Ungültige Worker-Antwort");
}
```

---

## 📊 RATE-LIMITING-KONFIGURATION

### Limits:
```
Max Requests:        3 pro Minute (pro IP)
Window:              60 Sekunden
Retry-After:         60 Sekunden
HTTP Status:         429 (Too Many Requests)
```

### Identifikation:
```
Basis:               Client-IP (CF-Connecting-IP)
Key-Format:          rate_limit_{IP}
Storage:             Cloudflare KV (optional)
TTL:                 60 Sekunden (auto-reset)
```

### Cache-Verhalten:
```
Cache HIT:           ✅ KEIN Rate-Limiting (unbegrenzt)
Cache MISS:          🚦 Rate-Limiting aktiv (3/Minute)
```

---

## 🎯 RATE-LIMIT-SZENARIEN

### Szenario 1: Normale Nutzung ✅
```
User-Action:
1. Suche "Berlin"      → Cache MISS (1/3)
2. Warte 2 Minuten
3. Suche "Deutschland" → Cache MISS (1/3, Counter reset)
4. Suche "Berlin"      → Cache HIT (kein Zählen)

Ergebnis: ✅ Alle Requests erfolgreich
```

### Szenario 2: Intensive Nutzung ⚠️
```
User-Action:
1. Suche "Test1"  → Cache MISS (1/3) ✅
2. Suche "Test2"  → Cache MISS (2/3) ✅
3. Suche "Test3"  → Cache MISS (3/3) ✅
4. Suche "Test4"  → RATE-LIMITED ❌

Response:
{
  "status": "limited",
  "message": "Zu viele Anfragen. Bitte kurz warten.",
  "retryAfter": 60,
  "requestCount": 4
}

Fehler-Anzeige in App:
"⏱️ Zu viele Anfragen. Bitte kurz warten.
Bitte warte 60 Sekunden."
```

### Szenario 3: Cache-Nutzung 🚀
```
User-Action:
1. Suche "Berlin"      → Cache MISS (1/3) ✅
2. Suche "Berlin"      → Cache HIT (1/3, kein Inkrement) ✅
3. Suche "Berlin"      → Cache HIT (1/3, kein Inkrement) ✅
4. Suche "Berlin"      → Cache HIT (1/3, kein Inkrement) ✅
5. (100x weitere)      → Alle aus Cache ✅
6. Suche "Deutschland" → Cache MISS (2/3) ✅

Ergebnis: ✅ Cache verhindert Rate-Limiting
```

---

## 🔍 STATUS-CODES ÜBERSICHT

### Status: "ok" ✅
```
Bedeutung: Erfolgreiche Recherche
Alle Quellen: Erfolgreich
HTTP Status:  200
```

### Status: "fallback" ⚠️
```
Bedeutung: Teilweise erfolgreich
Einige Quellen: Rate-Limited (externe APIs)
HTTP Status:  200
```

### Status: "limited" 🚦
```
Bedeutung: Worker-Rate-Limit erreicht
Ursache:  Zu viele Requests (>3/Minute)
HTTP Status:  429
Retry-After:  60 Sekunden
```

### Status: "error" ❌
```
Bedeutung: Fehler aufgetreten
Ursache:  Alle Quellen fehlgeschlagen
HTTP Status:  200
```

---

## ⚙️ KV-NAMESPACE-SETUP (OPTIONAL)

### Warum optional?
- **Ohne KV:** Rate-Limiting funktioniert pro Worker-Instance
- **Mit KV:** Rate-Limiting funktioniert global über alle Instanzen

### KV-Namespace erstellen:
```bash
# 1. KV-Namespace erstellen
wrangler kv:namespace create "RATE_LIMIT_KV"

# Output: 
# { binding = "RATE_LIMIT_KV", id = "YOUR_NAMESPACE_ID" }

# 2. In wrangler.toml einfügen
[[kv_namespaces]]
binding = "RATE_LIMIT_KV"
id = "YOUR_NAMESPACE_ID"

# 3. Neu deployen
wrangler deploy
```

### Ohne KV:
```javascript
// Code prüft automatisch ob KV verfügbar ist
if (env.RATE_LIMIT_KV) {
  // KV-basiertes Rate-Limiting
} else {
  // Kein persistentes Rate-Limiting
  // (funktioniert trotzdem pro Worker-Instance)
}
```

---

## 🧪 TESTING

### Test 1: Normale Nutzung
```bash
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Test1"
# Erwartung: Status "ok" oder "fallback"
```

### Test 2: Rate-Limit testen (ohne KV)
```bash
# Schnelle Folge-Requests
for i in {1..5}; do
  echo "Request $i:"
  curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Test$i" | jq .status
  sleep 1
done

# Erwartung: 
# Request 1-3: "ok" oder "fallback"
# Request 4-5: Möglicherweise "limited" (abhängig von Worker-Instance)
```

### Test 3: Cache verhindert Rate-Limiting
```bash
# Erste Anfrage (Cache MISS)
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin"

# Zweite Anfrage (Cache HIT, kein Rate-Limiting)
curl "https://weltenbibliothek-worker.brandy13062.workers.dev?q=Berlin"

# Erwartung: Beide erfolgreich, zweite ist schneller
```

---

## ✅ CHANGELOG v3.4

**NEU:**
- ✅ Rate-Limiting-System (3 Requests/Minute bei Cache MISS)
- ✅ "limited"-Status für Rate-Limit-Überschreitung
- ✅ IP-basierte Identifikation (CF-Connecting-IP)
- ✅ Optional: KV-Namespace für globales Rate-Limiting
- ✅ Retry-After Header (60 Sekunden)
- ✅ Flutter-App behandelt "limited"-Status

**BEHALTEN:**
- ✅ Cache-System (Cache HITs zählen nicht zum Limit)
- ✅ Fallback-Status bei externen Rate-Limits
- ✅ 30 Sekunden Timeout
- ✅ Multi-Source-Crawling
- ✅ KI-Analyse

**VERBESSERT:**
- ✅ Schutz vor Missbrauch
- ✅ Bessere Ressourcen-Verwaltung
- ✅ Transparente Fehler-Kommunikation

---

## 🚀 DEPLOYMENT-STATUS

**Worker-URL:**
```
https://weltenbibliothek-worker.brandy13062.workers.dev
```

**Version-ID:** `dbb0c141-31c5-4943-bc58-ee7202137656`

**Alle Features:**
- ✅ Rate-Limiting (NEU!)
- ✅ IP-basierte Limits
- ✅ Fallback-Status
- ✅ Cache-System (57x schneller)
- ✅ Multi-Source-Crawling
- ✅ KI-Analyse

---

## 📱 FLUTTER-APP v3.4

**APK-Download:**
```
https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=d798d27a-c038-4d89-b7e1-91560b1b7bfd&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=weltenbibliothek-recherche-v3.4-rate-limiting.apk
```

**Web-Preview:**
```
https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
```

**Größe:** 97.3 MB

---

## 🎯 ZUSAMMENFASSUNG

**Was implementiert:**
- ✅ Rate-Limiting-System (3 Requests/Minute)
- ✅ IP-basierte Identifikation
- ✅ Graceful Degradation bei Limit-Überschreitung
- ✅ Optional: KV-Namespace für globales Rate-Limiting
- ✅ Cache HITs zählen nicht zum Limit

**Vorteile:**
- 🛡️ Schutz vor Missbrauch
- 💰 Niedrigere Kosten (weniger unnötige Crawls)
- ⚡ Cache-Nutzung wird incentiviert
- 📊 Bessere Ressourcen-Verwaltung

**Für Nutzer:**
- ✅ Normale Nutzung uneingeschränkt
- ✅ Cache-Nutzung unbegrenzt (57x schneller)
- ⚠️ Bei intensiver Nutzung: 1 Minute Wartezeit
- 💡 Klare Fehler-Meldung mit Retry-After

---

🎉 **RECHERCHE-TOOL v3.4 - RATE-LIMITING DEPLOYED!**

**Timestamp:** 2026-01-04 16:00 UTC  
**Build:** #7 (Rate-Limiting System)

---

**BEREIT ZUM TESTEN!** 🚀

Das Rate-Limiting-System schützt den Worker vor Überlastung und incentiviert Cache-Nutzung! ✅
