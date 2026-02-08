# 🌐 WELTENBIBLIOTHEK - CLOUDFLARE WORKER EDITION

## 🎯 MISSION

**ECHTE RECHERCHE-DATEN** - **KEINE MOCK-DATEN** - **KEINE APIs**

Die Weltenbibliothek ist eine Deep-Research-Plattform, die **echte Webseiten crawlt**, **KI-gestützt analysiert** und **professionell visualisiert**.

## ✨ HIGHLIGHTS

- ✅ **ECHTE DATEN** von DuckDuckGo, Wikipedia, Archive.org, Tagesschau, Zeit.de
- ✅ **KI-ANALYSE** mit Cloudflare AI (Llama 3.1)
- ✅ **FALLBACK-SYSTEM** - Alternative Interpretation wenn keine Quellen gefunden
- ✅ **KOSTENLOS** (Cloudflare Free Tier)
- ✅ **GLOBAL VERTEILT** (Edge Computing)
- ✅ **KEIN BACKEND** (Worker läuft bei Cloudflare)

## 🚀 SCHNELLSTART

### 1. Worker deployen (5 Minuten)

```bash
# Wrangler installieren
npm install -g wrangler

# Cloudflare Login
wrangler login

# Worker deployen
cd /home/user/flutter_app/cloudflare-worker
wrangler deploy

# Worker-URL kopieren (Beispiel)
# https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev
```

### 2. Flutter konfigurieren

```dart
// lib/services/backend_recherche_service.dart
BackendRechercheService({
  this.baseUrl = 'https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev',
});
```

### 3. Flutter neu bauen

```bash
cd /home/user/flutter_app
flutter build web --release
python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 &
```

### 4. Testen!

App öffnen → Suchbegriff eingeben → **RECHERCHE** → **ECHTE DATEN!** 🎉

## 📂 PROJEKT-STRUKTUR

```
flutter_app/
│
├── cloudflare-worker/              ← WORKER-CODE
│   ├── index.js                    ← Haupt-Worker (9.4 KB)
│   ├── wrangler.toml               ← Config
│   ├── package.json                ← Dependencies
│   ├── DEPLOYMENT.md               ← Deployment-Guide
│   ├── QUICK_START.md              ← 5-Min-Anleitung
│   └── .gitignore                  ← Git-Ignore
│
├── lib/                            ← FLUTTER APP
│   ├── services/
│   │   └── backend_recherche_service.dart  ← Worker-Integration
│   ├── screens/
│   │   └── materie/
│   │       └── recherche_tab_mobile.dart   ← 7-Tab-UI
│   ├── widgets/visualisierung/     ← Visualisierungs-Widgets
│   │   ├── netzwerk_graph_widget.dart
│   │   ├── machtindex_chart_widget.dart
│   │   ├── timeline_visualisierung_widget.dart
│   │   ├── mindmap_widget.dart
│   │   └── karte_widget.dart
│   └── models/
│       └── recherche_models.dart   ← Daten-Modelle
│
└── Dokumentation/                  ← GUIDES
    ├── CLOUDFLARE_WORKER_SETUP.md  ← Setup-Anleitung
    ├── ECHTE_DATEN_LÖSUNG.md       ← Lösungs-Übersicht
    ├── ARCHITEKTUR_ÜBERSICHT.md    ← System-Architektur
    ├── CHANGELOG_CLOUDFLARE.md     ← Changelog
    └── README_CLOUDFLARE_WORKER.md ← Diese Datei
```

## 🏗️ ARCHITEKTUR

### Drei-Ebenen-System

```
EBENE 1: ECHTZEIT-DATEN
  Cloudflare Worker crawlt 5 echte Quellen parallel:
  • DuckDuckGo (Suchmaschine)
  • Wikipedia (Enzyklopädie)
  • Archive.org (Archive)
  • Tagesschau (Nachrichten)
  • Zeit.de (Analysen)
  
  ↓ (5-10 Sekunden)
  
EBENE 2: KI-ANALYSE
  Cloudflare AI (Llama 3.1) analysiert und strukturiert:
  • Identifiziert Akteure & Machtstrukturen
  • Extrahiert Narrative & Medienberichte
  • Findet alternative Sichtweisen
  • Erstellt chronologische Zeitachse
  • Generiert Meta-Kontext
  
  ↓ (2-5 Sekunden)
  
EBENE 3: VISUALISIERUNG
  Flutter zeigt in 7-Tab-UI:
  • ÜBERSICHT (Mindmap, Hauptthemen)
  • MACHTANALYSE (Netzwerk-Graph, Machtindex)
  • NARRATIVE (Medienberichte, Frames)
  • TIMELINE (Chronologische Ereignisse)
  • KARTE (Geografische Standorte)
  • ALTERNATIVE (Gegenpositionen)
  • META (Kontext, Einordnung)
```

## 🎨 VISUALISIERUNGEN

| Widget | Beschreibung | Features |
|--------|--------------|----------|
| **Mindmap** | Hierarchische Themen | 4 Ebenen, Zoom/Pan |
| **Netzwerk-Graph** | Akteurs-Beziehungen | Sugiyama-Layout, Farb-Kodierung |
| **Machtindex-Chart** | Top 10 Rankings | Bar/Radar/Ranking-Modi |
| **Timeline** | Chronologie | 5 Kategorien, Relevanz-Balken |
| **Karte** | Geografische Standorte | OpenStreetMap, Marker nach Wichtigkeit |

## 💻 TECHNOLOGIE

### Frontend
- **Flutter** 3.35.4 (Web)
- **Material Design** 3
- **Packages**: fl_chart, flutter_map, http, provider

### Backend
- **Cloudflare Worker** (JavaScript)
- **Cloudflare AI** (Llama 3.1 8B)
- **Edge Runtime** (Global verteilt)

### Datenquellen
- **DuckDuckGo** (HTML-Parsing)
- **Wikipedia** (via r.jina.ai)
- **Archive.org** (JSON-API)
- **Tagesschau** (via r.jina.ai)
- **Zeit.de** (via r.jina.ai)

## 💰 KOSTEN

**100% KOSTENLOS bei normaler Nutzung!**

| Service | Free Tier | Pro Recherche | Max/Tag (kostenlos) |
|---------|-----------|---------------|---------------------|
| Cloudflare Workers | 100.000 Req/Tag | 1 Request | 100.000 |
| Cloudflare AI | 10.000 Req/Tag | 1 AI-Call | 10.000 |
| Bandwidth | Unlimitiert | ~50 KB | ∞ |

→ Bis **10.000 Recherchen/Tag** komplett kostenlos!

## 📚 DOKUMENTATION

| Datei | Beschreibung |
|-------|--------------|
| **QUICK_START.md** | 5-Minuten-Schnellstart |
| **CLOUDFLARE_WORKER_SETUP.md** | Vollständige Setup-Anleitung |
| **ECHTE_DATEN_LÖSUNG.md** | Lösungs-Übersicht & Details |
| **ARCHITEKTUR_ÜBERSICHT.md** | System-Architektur & Datenfluss |
| **DEPLOYMENT.md** | Worker-Deployment-Guide |
| **CHANGELOG_CLOUDFLARE.md** | Version 3.0.0 Änderungen |

## 🧪 TESTING

### Worker lokal testen

```bash
cd cloudflare-worker
wrangler dev

# Test-Request
curl "http://localhost:8787/?q=Test"
```

### Worker production testen

```bash
curl "https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev/?q=Ukraine%20Krieg"
```

**Erwartete Antwort:**
```json
{
  "query": "Ukraine Krieg",
  "status": "completed",
  "quellen": [
    {
      "id": "quelle_0",
      "titel": "DuckDuckGo HTML",
      "inhalt": "Echte Suchergebnisse...",
      "status": "success"
    }
  ],
  "analyse": {
    "hauptThemen": [...],
    "akteure": [...],
    "narrative": [...],
    ...
  }
}
```

## 🔍 MONITORING

### Cloudflare Dashboard

```
https://dash.cloudflare.com/
→ Workers & Pages
→ weltenbibliothek-worker
→ Metrics
```

### Live Logs

```bash
wrangler tail
```

## 🚨 TROUBLESHOOTING

### Problem: Worker deployed, aber keine Daten in Flutter

**Lösung:** `baseUrl` in Flutter aktualisieren:
```dart
BackendRechercheService({
  this.baseUrl = 'https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev',
});
```

### Problem: CORS-Fehler

**Lösung:** Worker neu deployen:
```bash
wrangler deploy
```

### Problem: Timeout nach 60 Sekunden

**Lösung:** In `index.js` Anzahl Quellen reduzieren (Zeile ~46)

### Problem: AI-Fehler in Logs

**Lösung:** Check Cloudflare AI Usage:
```
https://dash.cloudflare.com/ → AI → Usage
```

## 🎯 ROADMAP

### v3.1.0 (geplant)
- [ ] Mehr Datenquellen (Reuters, BBC, Guardian)
- [ ] Bildsuche & Medien-Analyse
- [ ] PDF-Export der Recherche-Ergebnisse
- [ ] Custom Domain Support

### v3.2.0 (geplant)
- [ ] Real-time Collaboration
- [ ] Recherche-Historie speichern
- [ ] Erweiterte Filter & Suche
- [ ] Mobile App (Android/iOS)

## 📞 SUPPORT

- **Cloudflare Workers**: https://developers.cloudflare.com/workers/
- **Cloudflare AI**: https://developers.cloudflare.com/workers-ai/
- **Wrangler**: https://developers.cloudflare.com/workers/wrangler/
- **Community**: https://discord.cloudflare.com/

## 📄 LIZENZ

MIT License - Manuel Brandner

## 🙏 CREDITS

- **Cloudflare** - Worker & AI Platform
- **Flutter** - UI Framework
- **DuckDuckGo** - Privacy-freundliche Suche
- **Wikipedia** - Freies Wissen
- **Archive.org** - Digitale Bibliothek
- **r.jina.ai** - Crawler-Proxy

---

## 🎉 START JETZT!

```bash
# 1. Worker deployen
cd cloudflare-worker && wrangler deploy

# 2. URL kopieren
# https://weltenbibliothek-worker.DEIN-USERNAME.workers.dev

# 3. Flutter anpassen
# lib/services/backend_recherche_service.dart → baseUrl

# 4. Testen!
# App öffnen → Recherche starten → ECHTE DATEN! 🎉
```

**WELTENBIBLIOTHEK - ECHTE RECHERCHE, ECHTE DATEN!** 📚🔍✨
