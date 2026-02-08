# WELTENBIBLIOTHEK v5.4 – Strukturierte JSON-Extraktion

## 📅 Release-Datum
04. Januar 2026

## 🎯 Version
**v5.4 STRUCTURED JSON** (Cloudflare Worker)

---

## ✨ NEUE FEATURES v5.4

### 📦 Strukturierte JSON-Extraktion
**Problem gelöst:** KI-Textausgabe ist schwer maschinell zu parsen.

**Lösung:** Automatische Extraktion strukturierter Daten aus KI-Analyse:

```json
{
  "analyse": {
    "inhalt": "...",  // Vollständiger Text (wie bisher)
    "structured": {   // NEU: Maschinenlesbare Daten
      "faktenbasis": {
        "facts": [
          {
            "statement": "MKULTRA wurde 1953 gegründet",
            "source": "[1]"
          }
        ],
        "actors": ["CIA", "Allen Dulles"],
        "organizations": ["CIA", "MKULTRA"],
        "financial_flows": [],
        "timeline": []
      },
      "sichtweise1_offiziell": {
        "interpretation": "Die offizielle Erklärung...",
        "sources": ["CIA (offizielle Dokumente)", "US-Regierung"],
        "argumentation": "..."
      },
      "sichtweise2_alternativ": {
        "interpretation": "Alternative Interpretation...",
        "sources": ["Investigative Journalisten", "Whistleblower"],
        "argumentation": "..."
      },
      "vergleich": {
        "gemeinsamkeiten": [],
        "unterschiede": [],
        "offene_punkte": ["Warum wurde MKULTRA aufgelöst?"]
      }
    }
  }
}
```

---

## 🏗️ TECHNISCHE DETAILS

### Extraktion-Workflow
1. **KI generiert Text** mit strukturierter Markdown-Formatierung
2. **Regex-Patterns** extrahieren Sektionen:
   - `**FAKTE (BELEGBAR MIT QUELLENANGABE)**`
   - `**BETEILIGTE AKTEURE**`
   - `**ORGANISATIONEN & STRUKTUREN**`
   - `**GELDFLÜSSE (FALLS VORHANDEN)**`
   - `**ANALYSE & INTERPRETATION**`
   - `**ALTERNATIVE SICHTWEISEN (SYSTEMKRITISCH)**`
   - `**WIDERSPRÜCHE & OFFENE PUNKTE**`
3. **JSON-Objekt** wird generiert und in `analyse.structured` zurückgegeben

### Flexible Regex-Patterns
- **Case-insensitive**: Funktioniert mit `**FAKTE**`, `**Fakte**`, `**fakte**`
- **Variationen**: Unterstützt verschiedene Schreibweisen (z.B. "Geldflüsse", "Geldflüße")
- **Robustheit**: Funktioniert auch bei leicht abweichender KI-Formatierung

---

## 📊 DATENSTRUKTUR

### Faktenbasis (Identisch für beide Sichtweisen)
```json
{
  "facts": [
    {"statement": "Fakt", "source": "[1]"}
  ],
  "actors": ["Person 1", "Person 2"],
  "organizations": ["Org 1", "Org 2"],
  "financial_flows": [
    {"description": "Geldfluss", "source": "[2]"}
  ],
  "timeline": ["Ereignis 1953", "Ereignis 1973"]
}
```

### Sichtweisen (Getrennte Interpretationen)
```json
{
  "sichtweise1_offiziell": {
    "interpretation": "Text der offiziellen Interpretation",
    "sources": ["Quelle 1", "Quelle 2"],
    "argumentation": "Argumentationskette"
  },
  "sichtweise2_alternativ": {
    "interpretation": "Text der alternativen Interpretation",
    "sources": ["Quelle 3", "Quelle 4"],
    "argumentation": "Alternative Argumentationskette"
  }
}
```

### Vergleich
```json
{
  "gemeinsamkeiten": ["Beide akzeptieren Fakt X"],
  "unterschiede": ["Sichtweise 1 interpretiert Y als Z"],
  "offene_punkte": ["Warum wurde X nicht geklärt?"]
}
```

---

## 🔧 INTEGRATION

### Flutter-Integration
```dart
// Standard-Request
final response = await http.get(
  Uri.parse('https://weltenbibliothek-worker.brandy13062.workers.dev?q=MK Ultra')
);
final data = jsonDecode(response.body);

// Zugriff auf strukturierte Daten
final facts = data['analyse']['structured']['faktenbasis']['facts'];
final view1 = data['analyse']['structured']['sichtweise1_offiziell'];
final view2 = data['analyse']['structured']['sichtweise2_alternativ'];

// UI-Darstellung
ListView.builder(
  itemCount: facts.length,
  itemBuilder: (context, index) {
    final fact = facts[index];
    return ListTile(
      title: Text(fact['statement']),
      subtitle: Text('Quelle: ${fact['source']}'),
    );
  },
);
```

---

## ⚙️ DEPLOYMENT

### Cloudflare Worker Version
- **Version-ID**: `8293d4fa-df1e-47af-9925-b0c8c585c984`
- **Upload-Größe**: 27.49 KiB (gzip: 6.26 KiB)
- **Deployed**: 04.01.2026
- **Status**: ✅ Production-Ready

### Worker-URL
```
https://weltenbibliothek-worker.brandy13062.workers.dev
```

---

## 📈 VORTEILE

### Für Entwickler
- **Maschinenlesbar**: Einfache Verarbeitung in Flutter/JavaScript
- **Typsicher**: Klare JSON-Struktur
- **Filterbar**: Nur benötigte Daten abrufen

### Für UX
- **Strukturierte Anzeige**: Fakten in Listenform
- **Getrennte Tabs**: Sichtweise 1 vs. Sichtweise 2
- **Quellen-Links**: Direkte Quellenangaben je Fakt

### Für Transparenz
- **Faktenbasis = Identisch**: Beide Sichtweisen nutzen dieselben Fakten
- **Quellen getrennt**: Klar welche Quelle welche Sichtweise stützt
- **Vergleich möglich**: Gemeinsamkeiten & Unterschiede sichtbar

---

## 🚨 WICHTIGER HINWEIS

### KI-Variabilität
Die Extraktion ist **best-effort** und funktioniert am besten, wenn die KI:
- Die erwarteten Überschriften nutzt
- Bullet-Points (`*`) für Listen verwendet
- Klare Quellenangaben macht (`Quelle: [1]`)

**Fallback**: Falls Extraktion fehlschlägt, ist `structured` leer, aber `inhalt` enthält den vollständigen Text.

### Cache-Verhalten
- **Standard-Modus**: Cache 1 Stunde (3600s)
- **Live-Modus**: Kein Cache, immer frische Extraktion
- **Cache-Purge**: Bei Deployment kann alter Cache noch aktiv sein

---

## 📋 VOLLSTÄNDIGE FEATURE-LISTE (v1.0 → v5.4)

| Version | Feature | Beschreibung |
|---------|---------|--------------|
| **v5.4** | 📦 Strukturierte JSON-Extraktion | Maschinenlesbare Daten aus KI-Text |
| **v5.3** | ⚖️ Neutrale Perspektiven | Keine Bewertung durch Tool |
| **v5.2** | 🔀 Fakten-Trennung | FAKTEN → ANALYSE → ALTERNATIVE |
| **v5.1** | 📅 Timeline-Extraktion | KI-basierte chronologische Events |
| **v5.0** | ⚡ Hybrid-SSE | Cache (57x Speedup) + Live-Updates |
| **v4.2** | 🎯 8-Punkte-Analyse | Strukturierte Recherche |

---

## 🎯 NEXT STEPS

### Optionale Verbesserungen
1. **Prompt-Optimierung**: KI stärker auf Formatierung trainieren
2. **Post-Processing**: NLP-basierte Entitätserkennung als Fallback
3. **Validierung**: Schema-Validierung für extrahierte Daten
4. **Flutter-UI**: Strukturierte Anzeige in App implementieren

### Test-Empfehlungen
```bash
# Test strukturierte Extraktion
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=MK%20Ultra" \
  | jq '.analyse.structured.faktenbasis.facts[:3]'

# Test Live-Modus (kein Cache)
curl -s "https://weltenbibliothek-worker.brandy13062.workers.dev?q=MK%20Ultra&live=true"
```

---

## ✅ PRODUCTION-STATUS

**WELTENBIBLIOTHEK v5.4** ist deployed und production-ready:

✅ Strukturierte JSON-Extraktion implementiert  
✅ Flexible Regex-Patterns für Robustheit  
✅ Backward-compatible (Text in `inhalt` bleibt erhalten)  
✅ Debug-Informationen verfügbar (`debug_extraction`)  
✅ Cache-System funktioniert (Standard + Live-Modus)

---

**Entwickelt für transparente, neutrale Wissens-Dokumentation.**  
**WELTENBIBLIOTHEK – Fakten, Analyse, Alternative Perspektiven.**
