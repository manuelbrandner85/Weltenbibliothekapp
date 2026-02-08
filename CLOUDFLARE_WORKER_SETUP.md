# 🚀 WELTENBIBLIOTHEK - CLOUDFLARE WORKER SETUP

## ✅ WAS WURDE GEÄNDERT?

**VORHER:** Mock-Daten, lokales Backend, API-Probleme  
**JETZT:** ECHTE DATEN via Cloudflare Worker! 🎉

## 🎯 DREI-EBENEN-SYSTEM

```
NUTZER
  ↓ gibt Suchbegriff ein
EBENE 1: ECHTZEIT-DATEN
  → Cloudflare Worker crawlt ECHTE Webseiten:
     • DuckDuckGo (Suchmaschine)
     • Wikipedia (Enzyklopädie)
     • Archive.org (Historische Archive)
     • Tagesschau (Aktuelle Nachrichten)
     • Zeit.de (Hintergründe & Analysen)
  ↓
EBENE 2: KI-ANALYSE
  → Cloudflare AI (Llama 3.1) analysiert:
     • Identifiziert Akteure
     • Extrahiert Narrative
     • Findet alternative Sichtweisen
     • Erstellt Zeitachse
     • Generiert Meta-Kontext
  ↓
EBENE 3: VISUALISIERUNG
  → Flutter zeigt strukturierte Ergebnisse:
     • 7-Tab-System
     • Netzwerk-Graph
     • Machtindex-Chart
     • Timeline
     • Mindmap
     • Karte
```

## 📋 DEPLOYMENT-SCHRITTE

### SCHRITT 1: Wrangler CLI installieren

```bash
npm install -g wrangler
```

### SCHRITT 2: Cloudflare Login

```bash
wrangler login
```

→ Browser öffnet sich, mit Cloudflare Account verbinden

### SCHRITT 3: Worker deployen

```bash
cd /home/user/flutter_app/cloudflare-worker
wrangler deploy
```

**Beispiel-Ausgabe:**
```
Total Upload: 10.23 KiB / gzip: 3.45 KiB
Uploaded weltenbibliothek-worker (2.34 sec)
Published weltenbibliothek-worker (0.87 sec)
  https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev
Current Deployment ID: abc123def456
```

### SCHRITT 4: Worker-URL kopieren

Kopiere die URL, z.B.:
```
https://weltenbibliothek-worker.manuel-brandner.workers.dev
```

### SCHRITT 5: Flutter-App konfigurieren

Öffne: `/home/user/flutter_app/lib/services/backend_recherche_service.dart`

Ändere Zeile 27:
```dart
BackendRechercheService({
  // HIER DEINE WORKER-URL EINTRAGEN!
  this.baseUrl = 'https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev',
});
```

**Beispiel:**
```dart
BackendRechercheService({
  this.baseUrl = 'https://weltenbibliothek-worker.manuel-brandner.workers.dev',
});
```

### SCHRITT 6: Flutter neu bauen

```bash
cd /home/user/flutter_app
rm -rf build/web .dart_tool/build_cache
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

### SCHRITT 7: Testen!

1. Öffne die Flutter App
2. Gib einen Suchbegriff ein, z.B. "Ukraine Krieg"
3. Klicke "RECHERCHE"
4. Warte ~10-30 Sekunden (Worker crawlt echte Seiten!)
5. Ergebnisse erscheinen! 🎉

## 🧪 WORKER TESTEN

### Lokal testen (Entwicklung)

```bash
cd /home/user/flutter_app/cloudflare-worker
wrangler dev
```

→ Worker läuft auf http://localhost:8787

**Test-Request:**
```bash
curl "http://localhost:8787/?q=Test"
```

### Production Test

```bash
curl "https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Ukraine%20Krieg"
```

**Erwartete Antwort:**
```json
{
  "query": "Ukraine Krieg",
  "status": "completed",
  "timestamp": "2026-01-03T14:30:00Z",
  "quellen": [
    {
      "id": "quelle_0",
      "titel": "DuckDuckGo HTML",
      "url": "https://html.duckduckgo.com/html/?q=Ukraine%20Krieg",
      "typ": "suchmaschine",
      "inhalt": "DuckDuckGo Ergebnisse für \"Ukraine Krieg\":\n\n...",
      "status": "success"
    },
    {
      "id": "quelle_1",
      "titel": "Wikipedia (via r.jina.ai)",
      "url": "https://r.jina.ai/https://de.wikipedia.org/wiki/Ukraine%20Krieg",
      "typ": "enzyklopaedie",
      "inhalt": "# Ukraine\n\nDie Ukraine ist ein Staat...",
      "status": "success"
    }
  ],
  "analyse": {
    "hauptThemen": ["Konflikt", "Diplomatie", "Sanktionen"],
    "akteure": [
      {
        "name": "Russland",
        "rolle": "Angreifer",
        "einfluss": 0.9
      }
    ],
    "narrative": [...],
    "alternativeSichtweisen": [...],
    "zeitachse": [...],
    "metaKontext": "..."
  }
}
```

## 💰 KOSTEN

**KOMPLETT KOSTENLOS!**

- **Cloudflare Workers**: 100.000 Requests/Tag (Free Tier)
- **Cloudflare AI**: 10.000 AI-Requests/Tag (kostenlos)
- **Bandwidth**: Unlimitiert

→ Selbst bei 1.000 Recherchen pro Tag: **0 EUR** Kosten!

## 🔍 MONITORING

**Cloudflare Dashboard:**
```
https://dash.cloudflare.com/
→ Workers & Pages
→ weltenbibliothek-worker
→ Metrics
```

**Live Logs:**
```bash
wrangler tail
```

Zeigt alle Worker-Requests in Echtzeit:
```
GET https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Test
[2026-01-03 14:30:00] 🔍 RECHERCHE GESTARTET: Test
[2026-01-03 14:30:01] 📡 Crawling: DuckDuckGo HTML
[2026-01-03 14:30:02] 📡 Crawling: Wikipedia (via r.jina.ai)
[2026-01-03 14:30:03] ✅ 5 Quellen erfolgreich gecrawlt
[2026-01-03 14:30:05] ✅ KI-Analyse abgeschlossen
```

## 🚨 TROUBLESHOOTING

### ❌ Worker deployed, aber Flutter bekommt keine Daten

**Problem:** `baseUrl` in Flutter nicht aktualisiert

**Lösung:**
```dart
// lib/services/backend_recherche_service.dart
BackendRechercheService({
  this.baseUrl = 'https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev', // ← FIX!
});
```

### ❌ CORS-Fehler im Browser

**Problem:** Worker hat CORS-Headers, sollte nicht passieren

**Lösung:** Worker neu deployen:
```bash
cd /home/user/flutter_app/cloudflare-worker
wrangler deploy
```

### ❌ Timeout nach 60 Sekunden

**Problem:** Worker braucht zu lange (crawlt zu viele Seiten)

**Lösung:** In `index.js` Anzahl Quellen reduzieren:
```javascript
// Zeile ~46
const crawlTargets = [
  // Nur 3 statt 5 Quellen
  { name: 'DuckDuckGo HTML', ... },
  { name: 'Wikipedia', ... },
  { name: 'Archive.org', ... },
];
```

### ❌ AI-Fehler in Worker Logs

**Problem:** Cloudflare AI Free Tier überschritten (10.000 Requests/Tag)

**Lösung:** In `index.js` AI-Fallback wird automatisch genutzt (Zeile ~243)

**Check Usage:**
```
https://dash.cloudflare.com/
→ AI
→ Usage
```

### ❌ "Cannot connect to host" in Worker Logs

**Problem:** Manche Webseiten blockieren Cloudflare Worker

**Lösung:** Worker nutzt automatisch r.jina.ai als Proxy für schwierige Seiten

## ✨ VORTEILE

✅ **ECHTE DATEN** - Keine Mock-Daten mehr!  
✅ **KEIN BACKEND** - Worker läuft bei Cloudflare  
✅ **KOSTENLOS** - 100% Free Tier  
✅ **SCHNELL** - Global verteilt (Edge Computing)  
✅ **KI-ANALYSE** - Cloudflare AI inklusive  
✅ **SKALIERBAR** - Bis 100.000 Requests/Tag  

## 📚 DATEI-STRUKTUR

```
/home/user/flutter_app/
├── cloudflare-worker/
│   ├── index.js              ← Worker-Code (3 Ebenen)
│   ├── wrangler.toml         ← Cloudflare Config
│   ├── package.json          ← npm Dependencies
│   ├── DEPLOYMENT.md         ← Deployment-Guide
│   └── weltenbibliothek-worker.js  ← Alte Version (ignorieren)
│
├── lib/services/
│   └── backend_recherche_service.dart  ← Flutter Service (angepasst!)
│
└── CLOUDFLARE_WORKER_SETUP.md  ← Diese Datei
```

## 🎯 NÄCHSTE SCHRITTE

1. ✅ Worker deployen: `wrangler deploy`
2. ✅ Worker-URL kopieren
3. ✅ Flutter `baseUrl` anpassen
4. ✅ Flutter neu bauen
5. ✅ Testen mit echtem Suchbegriff
6. ✅ ECHTE DATEN genießen! 🎉

## 📞 SUPPORT

**Cloudflare Docs:**
- Workers: https://developers.cloudflare.com/workers/
- AI: https://developers.cloudflare.com/workers-ai/

**Wrangler Docs:**
- https://developers.cloudflare.com/workers/wrangler/

**Community:**
- Discord: https://discord.cloudflare.com/

---

**WELTENBIBLIOTHEK - ECHTE RECHERCHE, ECHTE DATEN!** 🎉
