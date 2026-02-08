# WELTENBIBLIOTHEK v5.6 – EXPORT-FUNKTIONEN

**Release-Datum**: 2026-01-04
**Version**: v5.6
**Status**: ✅ Production-Ready

---

## 🎯 KERNFEATURE: MULTI-FORMAT EXPORT

v5.6 führt **umfassende Export-Funktionen** ein, mit denen Benutzer ihre Recherche-Ergebnisse in **4 verschiedenen Formaten** herunterladen können:

```javascript
function exportResearch(data, format) {
  if (format === "pdf") generatePDF(data);
  if (format === "md") generateMarkdown(data);
  if (format === "json") downloadJSON(data);
  if (format === "txt") generateText(data);
}
```

---

## ✨ EXPORT-FORMATE

### 1. 📄 PDF-EXPORT
**Verwendung**: Professionelle Dokumente mit Formatierung

**Features**:
- ✅ HTML-basierte PDF-Generierung
- ✅ Strukturierte Sections mit Farbkodierung
- ✅ Automatische Seitenumbrüche (page-break-inside: avoid)
- ✅ Responsive Design für Druck
- ✅ Browser-Druckdialog (Strg+P)

**Stil-Features**:
- Gradient-Header mit Titel
- Farbige Sections:
  - 🟢 **Fakten**: Grüner Hintergrund
  - 🟠 **Quellen**: Oranger Hintergrund
  - 🔴 **Analyse**: Rosa Hintergrund
- Linke Akzent-Linien (5px)
- Professional Layout mit Seitenkopf & Fußzeile

**Ausgabe**:
```
┌──────────────────────────────────┐
│ WELTENBIBLIOTHEK RECHERCHE       │
│ ================================ │
│ Thema: MK Ultra                  │
│ Datum: 2026-01-04 18:30:00       │
│                                  │
│ ━━━ FAKTEN ━━━                   │
│ [Strukturierte Fakten]           │
│                                  │
│ ━━━ QUELLEN ━━━                  │
│ [Referenzen]                     │
│                                  │
│ ━━━ ANALYSE ━━━                  │
│ [Vollständige Analyse]           │
│                                  │
│ Generiert von WELTENBIBLIOTHEK   │
└──────────────────────────────────┘
```

### 2. 📝 MARKDOWN-EXPORT
**Verwendung**: Notizen, Dokumentation, GitHub/Wikis

**Features**:
- ✅ GitHub-Flavored Markdown
- ✅ Strukturierte Hierarchie (H1, H2, H3)
- ✅ Bulletpoint-Listen
- ✅ Horizontal Rules (Trenner)
- ✅ Emoji-Icons

**Ausgabe**:
```markdown
# WELTENBIBLIOTHEK RECHERCHE

**Thema**: MK Ultra
**Datum**: 2026-01-04 18:30:00

---

## 📌 FAKTEN

### Belegbare Fakten
- CIA-Programm (1953-1973)
- LSD-Experimente ohne Einwilligung

### Beteiligte Akteure
- CIA
- Allen Dulles

---

## 🔗 QUELLEN

### Offizielle Quellen
- Wikipedia
- CIA-Akten (declassified)

### Alternative Quellen
- Investigative Journalisten
- Whistleblower-Berichte

---

## 📊 ANALYSE (Mainstream-Narrativ)

Das Programm wurde offiziell beendet...

---

## 👁️ ALTERNATIVE SICHT

Kritische Stimmen vermuten...

---

*Generiert von WELTENBIBLIOTHEK v5.6*
```

### 3. 💾 JSON-EXPORT
**Verwendung**: Maschinelle Weiterverarbeitung, APIs, Datenanalyse

**Features**:
- ✅ Vollständige Rohdaten
- ✅ Metadaten (Timestamp, Query, Version)
- ✅ Strukturierte JSON-Hierarchie
- ✅ Pretty-Print (2-Leerzeichen-Indentation)

**Ausgabe**:
```json
{
  "meta": {
    "query": "MK Ultra",
    "timestamp": "2026-01-04T18:30:00.000Z",
    "version": "WELTENBIBLIOTHEK v5.6"
  },
  "data": {
    "inhalt": "...",
    "structured": {
      "faktenbasis": {
        "facts": [...],
        "actors": [...],
        "organizations": [...]
      },
      "sichtweise1_offiziell": {
        "quellen": [...],
        "interpretation": "...",
        "argumentation": [...]
      },
      "sichtweise2_alternativ": {
        "quellen": [...],
        "interpretation": "...",
        "argumentation": [...]
      }
    }
  }
}
```

### 4. 📄 TEXT-EXPORT (TXT)
**Verwendung**: Einfache Textdateien ohne Formatierung

**Features**:
- ✅ Plain-Text (UTF-8)
- ✅ ASCII-Art-Rahmen
- ✅ Vollständiger Analyse-Inhalt
- ✅ Minimale Formatierung

**Ausgabe**:
```
============================================================
WELTENBIBLIOTHEK RECHERCHE
============================================================

Thema: MK Ultra
Datum: 2026-01-04 18:30:00

============================================================

[Vollständige Analyse als Fließtext]

============================================================
Generiert von WELTENBIBLIOTHEK v5.6
============================================================
```

---

## 🏗️ TECHNISCHE IMPLEMENTIERUNG

### Neue Komponente

**RechercheExporter** (`lib/utils/recherche_exporter.dart`):

```dart
class RechercheExporter {
  /// Hauptfunktion: Export in verschiedenen Formaten
  static void exportResearch({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String query,
    required String format,
  }) {
    switch (format) {
      case 'pdf': _generatePDF(data, query, filename); break;
      case 'md': _generateMarkdown(data, query, filename); break;
      case 'json': _downloadJSON(data, query, filename); break;
      case 'txt': _generateText(data, query, filename); break;
    }
  }
  
  /// Export-Dialog anzeigen
  static void showExportDialog(BuildContext context, {...}) {
    // AlertDialog mit 4 Export-Buttons
  }
}
```

### PDF-Generator (HTML-basiert)

```dart
static void _generatePDF(Map data, String query, String filename) {
  final htmlContent = _buildHTMLDocument(data, query);
  
  if (kIsWeb) {
    // HTML in neuem Fenster öffnen
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    
    // Hinweis: Browser-Druckfunktion (Strg+P) nutzen
  }
}
```

**HTML-Struktur**:
- Responsive CSS für Druck
- Farbige Sections
- Page-Break-Optimierung
- Professional Styling

### Markdown-Generator

```dart
static void _generateMarkdown(Map data, String query, String filename) {
  final buffer = StringBuffer();
  
  // Header mit Metadaten
  buffer.writeln('# WELTENBIBLIOTHEK RECHERCHE');
  buffer.writeln('**Thema**: $query');
  
  // Fakten-Section
  buffer.writeln('## 📌 FAKTEN');
  // Extrahiere aus structured.faktenbasis
  
  // Quellen-Section
  buffer.writeln('## 🔗 QUELLEN');
  // Extrahiere aus sichtweise1/2.quellen
  
  // Download
  _downloadFile(buffer.toString(), '$filename.md', 'text/markdown');
}
```

### JSON-Generator

```dart
static void _downloadJSON(Map data, String query, String filename) {
  final exportData = {
    'meta': {
      'query': query,
      'timestamp': DateTime.now().toIso8601String(),
      'version': 'WELTENBIBLIOTHEK v5.6',
    },
    'data': data,
  };
  
  final jsonString = JsonEncoder.withIndent('  ').convert(exportData);
  _downloadFile(jsonString, '$filename.json', 'application/json');
}
```

### File-Download-Helper (Web)

```dart
static void _downloadFile(String content, String filename, String mimeType) {
  if (kIsWeb) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
```

---

## 🎨 UI-INTEGRATION

### Export-Button im AppBar

```dart
appBar: AppBar(
  actions: [
    // 🆕 v5.6 Export-Button
    if (_status == RechercheStatus.done && _analyseData != null)
      IconButton(
        icon: const Icon(Icons.download),
        onPressed: () {
          RechercheExporter.showExportDialog(
            context,
            data: _analyseData!,
            query: _queryController.text,
          );
        },
        tooltip: 'Export',
      ),
    // Filter-Button, Status-Badge...
  ],
)
```

### Export-Dialog

```
┌──────────────────────────────┐
│ 📥 Export                    │
├──────────────────────────────┤
│ Wähle ein Export-Format:     │
│                              │
│ [📄 PDF-Dokument]            │
│ [📝 Markdown (.md)]          │
│ [💾 JSON-Daten]              │
│ [📄 Text-Datei (.txt)]       │
│                              │
│              [Abbrechen]     │
└──────────────────────────────┘
```

**Features**:
- ✅ 4 farbige Buttons (Rot, Blau, Grün, Grau)
- ✅ Icons für jedes Format
- ✅ Klarer Beschriftungstext
- ✅ Abbrechen-Button

### Erfolgs/Fehler-Nachrichten

**Erfolg**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('✅ Export erfolgreich: recherche_MK_Ultra_2026-01-04.md'),
    backgroundColor: Colors.green,
  ),
);
```

**Fehler**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('❌ Export fehlgeschlagen: [Fehlerdetails]'),
    backgroundColor: Colors.red,
  ),
);
```

---

## 📊 DATEINAME-GENERIERUNG

### Automatische Benennung

```dart
final timestamp = DateTime.now()
    .toIso8601String()
    .split('.')[0]
    .replaceAll(':', '-');

final filename = 'recherche_${query.replaceAll(' ', '_')}_$timestamp';
// Beispiel: recherche_MK_Ultra_2026-01-04T18-30-00
```

**Vorteile**:
- ✅ Eindeutige Namen (Timestamp)
- ✅ Lesbare Queries (Leerzeichen → Underscore)
- ✅ Sortierbar (ISO-8601-Format)
- ✅ Dateisystem-kompatibel (keine Sonderzeichen)

### Format-Endungen

- PDF: `.html` (wird als PDF gedruckt)
- Markdown: `.md`
- JSON: `.json`
- Text: `.txt`

---

## 🔄 DATENEXTRAKTION

### Strukturierte Daten (v5.4 Integration)

```dart
final structured = data['structured'] as Map<String, dynamic>?;

// Fakten aus strukturierten Daten
if (structured != null && structured.containsKey('faktenbasis')) {
  final fb = structured['faktenbasis'];
  // Extrahiere: facts, actors, organizations, financial_flows
}

// Quellen aus Sichtweisen
if (structured.containsKey('sichtweise1_offiziell')) {
  final view1 = structured['sichtweise1_offiziell'];
  // Extrahiere: quellen, interpretation, argumentation
}
```

### Fallback auf Fließtext

```dart
final inhalt = data['inhalt'] as String? ?? '';

if (inhalt.isNotEmpty) {
  // Vollständige Analyse als Fallback
  buffer.writeln(inhalt);
}
```

---

## 🧪 TESTING

### Test-Szenario 1: PDF-Export
1. Recherche starten (z.B. "MK Ultra")
2. Export-Button klicken
3. "PDF-Dokument" wählen
4. **Erwartung**: Neues Browser-Fenster mit HTML-Dokument öffnet sich
5. Strg+P drücken → PDF speichern

### Test-Szenario 2: Markdown-Export
1. Recherche starten
2. Export-Button klicken
3. "Markdown (.md)" wählen
4. **Erwartung**: Download-Dialog, Datei `recherche_MK_Ultra_2026-01-04.md` gespeichert
5. Datei öffnen → Strukturiertes Markdown sichtbar

### Test-Szenario 3: JSON-Export
1. Recherche starten
2. Export-Button klicken
3. "JSON-Daten" wählen
4. **Erwartung**: JSON-Datei mit `meta` und `data` heruntergeladen
5. JSON validieren → Pretty-Print mit 2-Leerzeichen

### Test-Szenario 4: Text-Export
1. Recherche starten
2. Export-Button klicken
3. "Text-Datei (.txt)" wählen
4. **Erwartung**: Plain-Text-Datei mit ASCII-Rahmen

---

## 🌐 WEB-KOMPATIBILITÄT

### Browser-Support

**✅ Vollständig unterstützt**:
- Chrome/Chromium
- Firefox
- Safari
- Edge

**File-Download**:
```dart
if (kIsWeb) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
```

**PDF-Generierung (Web-only)**:
- HTML-Dokument wird in neuem Tab geöffnet
- Benutzer nutzt Browser-Druckfunktion (Strg+P)
- "Als PDF speichern" im Druckdialog wählen

---

## 📱 MOBILE/DESKTOP SUPPORT

**Web-Plattform**:
- ✅ Vollständig funktionsfähig
- ✅ Browser-Download-Manager
- ✅ Native Druckfunktion

**Android/iOS** (zukünftig):
```dart
// Für native Plattformen:
// - path_provider: Lokale Dateipfade
// - share_plus: System-Share-Dialog
// - pdf: Native PDF-Generierung
```

---

## 🔐 DATEN-SICHERHEIT

### Lokale Verarbeitung
- ✅ Keine Server-Uploads
- ✅ Export erfolgt client-seitig
- ✅ Daten bleiben im Browser

### HTML-Escaping (PDF)
```dart
static String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
```

### UTF-8-Encoding
```dart
final bytes = utf8.encode(content);
// Korrekte Umlaute und Sonderzeichen
```

---

## 🎯 USE CASES

### Use Case 1: Wissenschaftliche Dokumentation
**Format**: PDF + Markdown

**Workflow**:
1. Recherche durchführen
2. PDF für formale Dokumentation exportieren
3. Markdown für Lab-Notizen exportieren
4. In LaTeX/Word integrieren

### Use Case 2: Datenanalyse
**Format**: JSON

**Workflow**:
1. Mehrere Recherchen durchführen
2. JSON-Exporte sammeln
3. Mit Python/R analysieren
4. Statistiken und Trends erkennen

### Use Case 3: Archivierung
**Format**: Alle Formate

**Workflow**:
1. Wichtige Recherche durchführen
2. Alle 4 Formate exportieren
3. In Archiv-System ablegen
4. Langzeit-Verfügbarkeit sicherstellen

### Use Case 4: Präsentationen
**Format**: Markdown → HTML/PDF

**Workflow**:
1. Recherche durchführen
2. Markdown exportieren
3. Mit reveal.js/marp konvertieren
4. Präsentation halten

---

## 🔄 INTEGRATION MIT BESTEHENDEN FEATURES

### v5.5.1 Strukturierte Darstellung
✅ **Vollständig kompatibel**:
- Export nutzt strukturierte Daten aus `RechercheResultCard`
- Fakten, Quellen, Analyse werden korrekt extrahiert

### v5.5 Filter-System
✅ **Filter-aware Export**:
- Export enthält **ungefilterte Rohdaten** (`_rawData`)
- Filter-Status wird NICHT exportiert
- Benutzer erhält vollständige Informationen

### v5.4 Strukturierte JSON-Extraktion
✅ **Direkte Integration**:
- JSON-Export enthält `structured`-Objekt
- Alle Extraktionen nutzen strukturierte Daten

### v5.1 Timeline
✅ **Timeline-Export**:
- Timeline-Daten in JSON enthalten
- Markdown/Text: Timeline als Bulletpoint-Liste
- PDF: Timeline in separater Section

---

## 📖 API-REFERENZ

### RechercheExporter

**Hauptmethoden**:

```dart
/// Export-Funktionen
static void exportResearch({
  required BuildContext context,
  required Map<String, dynamic> data,
  required String query,
  required String format, // 'pdf', 'md', 'json', 'txt'
})

/// Export-Dialog anzeigen
static void showExportDialog(
  BuildContext context, {
  required Map<String, dynamic> data,
  required String query,
})
```

**Generator-Methoden** (privat):

```dart
static void _generatePDF(Map data, String query, String filename)
static void _generateMarkdown(Map data, String query, String filename)
static void _downloadJSON(Map data, String query, String filename)
static void _generateText(Map data, String query, String filename)
```

**Helper-Methoden**:

```dart
static void _downloadFile(String content, String filename, String mimeType)
static String _buildHTMLDocument(Map data, String query)
static String _escapeHtml(String text)
```

---

## 🔍 DEBUGGING

### Export-Debug
```dart
debugPrint('Export Format: $format');
debugPrint('Query: $query');
debugPrint('Data Keys: ${data.keys}');
debugPrint('Filename: $filename');
```

### File-Download-Debug
```dart
debugPrint('Blob created: ${blob.size} bytes');
debugPrint('Object URL: $url');
debugPrint('Download triggered: $filename');
```

---

## 🎯 ZUSAMMENFASSUNG

### Was ist NEU in v5.6?
- ✅ **4 Export-Formate**: PDF, Markdown, JSON, Text
- ✅ **Export-Button** im AppBar (nur bei fertigen Ergebnissen)
- ✅ **Export-Dialog** mit farbigen Format-Buttons
- ✅ **Automatische Dateinamen-Generierung** (Query + Timestamp)
- ✅ **Strukturierte Datenextraktion** aus v5.4 Structured JSON
- ✅ **Erfolgs/Fehler-Benachrichtigungen** via SnackBar
- ✅ **Web-kompatible Downloads** (Blob + Anchor)

### Vorteile für Benutzer
- 📄 **Professionelle PDFs**: Für Dokumentation und Präsentationen
- 📝 **Markdown**: Für Notizen, Wikis, GitHub
- 💾 **JSON**: Für maschinelle Weiterverarbeitung
- 📄 **Plain Text**: Für einfache Archivierung
- 🔐 **Datenschutz**: Alles client-seitig, keine Server-Uploads

### Technische Highlights
- ✅ **Neues Utility**: `RechercheExporter`
- ✅ **HTML-basierte PDF-Generierung** (Web-kompatibel)
- ✅ **Intelligente Extraktion** aus strukturierten Daten
- ✅ **Pretty-Print JSON** (2-Leerzeichen-Indentation)
- ✅ **UTF-8-Encoding** für Umlaute und Sonderzeichen

---

## 🔗 DEPLOYMENT

**Live-URL**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
**Worker-API**: https://weltenbibliothek-worker.brandy13062.workers.dev
**Version**: v5.6
**Status**: ✅ Production-Ready

---

## 📚 VERWANDTE DOKUMENTATION

- v5.5.1: Strukturierte Darstellung (`RELEASE_NOTES_v5.5.1_STRUKTURIERTE_DARSTELLUNG.md`)
- v5.5: Filter-System (`RELEASE_NOTES_v5.5_FILTER_SYSTEM.md`)
- v5.4 UI: Perspektiven-Card (`RELEASE_NOTES_v5.4_UI_PERSPEKTIVEN.md`)
- v5.4: Strukturierte JSON-Extraktion (`RELEASE_NOTES_v5.4_STRUCTURED_JSON.md`)
- v5.3: Neutrale Perspektiven (`RELEASE_NOTES_v5.3_NEUTRAL.md`)
- v5.2: Fakten-Trennung (`RELEASE_NOTES_v5.2_FAKTEN_TRENNUNG.md`)
- v5.1: Timeline-Integration (`RELEASE_NOTES_v5.1_TIMELINE.md`)
- v5.0: Hybrid-SSE-System (`RELEASE_NOTES_v5.0_HYBRID.md`)

---

**🎉 WELTENBIBLIOTHEK v5.6 – Export deine Recherchen in jedem Format!**
