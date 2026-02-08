# 🔄 SEQUENZIELLES RECHERCHE-SYSTEM v4.0

## 🎯 NEUE ARCHITEKTUR

### Ablauf-Schema

```
┌─────────────────┐
│ 1. VALIDIERUNG  │
│ ────────────── │
│ ✓ Min 3 Zeichen │
│ ✓ Max 100 Zeichen│
│ ✓ Keine Sonderz.│
└────────┬────────┘
         │
┌────────▼────────┐
│ 2. SESSION      │
│ ────────────── │
│ + Session-ID    │
│ + Timestamp     │
│ + Status: active│
└────────┬────────┘
         │
┌────────▼────────────────────────────────┐
│ 3. SEQUENZIELLES CRAWLING               │
│ ────────────────────────────────────── │
│                                         │
│ Phase 1: DuckDuckGo                     │
│ ├─ Status: "Suche im Web..."            │
│ ├─ Crawl → Result                       │
│ └─ UI Update ✅                          │
│                                         │
│ Phase 2: Wikipedia                      │
│ ├─ Status: "Suche in Wikipedia..."      │
│ ├─ Crawl → Result                       │
│ └─ UI Update ✅                          │
│                                         │
│ Phase 3: Internet Archive               │
│ ├─ Status: "Suche im Archiv..."         │
│ ├─ Crawl → Result                       │
│ └─ UI Update ✅                          │
│                                         │
└────────┬────────────────────────────────┘
         │
┌────────▼────────┐
│ 4. ANALYSE      │
│ ────────────── │
│ Status: "KI..."  │
│ ├─ Prüfe Daten  │
│ ├─ KI-Analyse   │
│ └─ UI Update ✅  │
└────────┬────────┘
         │
┌────────▼────────┐
│ 5. FERTIG       │
│ ────────────── │
│ Status: "Fertig"│
│ ├─ Cache PUT    │
│ └─ UI Final ✅   │
└─────────────────┘
```

---

## 💡 NEUE KONZEPTE

### 1. Eingabe-Validierung
```dart
bool validateQuery(String query) {
  if (query.length < 3) return false;      // Zu kurz
  if (query.length > 100) return false;    // Zu lang
  if (query.trim().isEmpty) return false;  // Nur Leerzeichen
  return true;
}
```

### 2. Recherche-Session
```javascript
const session = {
  id: crypto.randomUUID(),
  query: "Berlin",
  status: "crawling",
  phase: "duckduckgo",
  progress: {
    current: 1,
    total: 4,
    percentage: 25
  },
  results: [],
  timestamp: Date.now()
}
```

### 3. Sequenzielles Crawling
```javascript
// NACHEINANDER statt PARALLEL
for (const source of sources) {
  // Status-Update senden
  updateProgress({
    phase: source.name,
    status: `Suche in ${source.name}...`
  });
  
  // Crawlen
  const result = await crawlSource(source);
  
  // Zwischenergebnis speichern
  session.results.push(result);
  
  // UI updaten
  notifyUI(session);
}
```

### 4. Live-UI-Updates
```dart
StreamBuilder<RechercheSsession>(
  stream: rechercheService.sessionStream,
  builder: (context, snapshot) {
    final session = snapshot.data;
    
    return Column(
      children: [
        // Progress-Indicator
        LinearProgressIndicator(
          value: session.progress.percentage / 100
        ),
        
        // Status-Text
        Text("Phase: ${session.phase}"),
        Text("Status: ${session.status}"),
        
        // Zwischenergebnisse
        ...session.results.map((r) => ResultCard(r))
      ]
    );
  }
)
```

### 5. Intelligenter Fallback
```javascript
// NUR bei echten Problemen
if (successfulSources.length === 0) {
  // ALLE Quellen fehlgeschlagen
  status = "error";
  message = "Keine Quellen erreichbar";
} else if (successfulSources.length < sources.length) {
  // TEILWEISE erfolgreich
  status = "ok";  // KEIN Fallback!
  message = `${successfulSources.length}/${sources.length} Quellen erfolgreich`;
}
```

---

## 🔧 IMPLEMENTIERUNGS-PLAN

### Phase 1: Flutter App (Frontend)
1. ✅ Eingabe-Validierung
2. ✅ Progress-UI mit LinearProgressIndicator
3. ✅ Live-Status-Updates
4. ✅ Zwischenergebnis-Anzeige

### Phase 2: Cloudflare Worker (Backend)
1. ✅ Sequenzielles Crawling
2. ✅ Session-Management
3. ✅ Progress-Tracking
4. ✅ Intelligenter Fallback

### Phase 3: Testing & Deployment
1. ✅ Manuelle Tests
2. ✅ Performance-Tests
3. ✅ APK bauen
4. ✅ Worker deployen

---

## 📊 ERWARTETE VERBESSERUNGEN

### User Experience
- ✅ **Transparenz**: User sieht live, was passiert
- ✅ **Feedback**: Jede Phase wird angezeigt
- ✅ **Zwischenergebnisse**: Sofort sichtbar
- ✅ **Keine Überraschungen**: Klare Fortschrittsanzeige

### Technisch
- ✅ **Besseres Error-Handling**: Einzelne Fehler stoppen nicht alles
- ✅ **Debugging**: Einfacher zu debuggen (Phase-weise)
- ✅ **Monitoring**: Besseres Tracking möglich
- ✅ **Fallback nur wenn nötig**: Nicht bei jedem kleinen Problem

---

## 🎯 ZIEL

**Weltenbibliothek v4.0**: Transparente, sequenzielle Recherche mit Live-Feedback!

**Start der Implementierung...**
