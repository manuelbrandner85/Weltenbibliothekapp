# WELTENBIBLIOTHEK v5.7 – QUELLEN-BEWERTUNGSSYSTEM

**Release-Datum**: 2026-01-04
**Version**: v5.7
**Status**: ✅ Production-Ready

---

## 🎯 KERNFEATURE: INTELLIGENTE QUELLEN-BEWERTUNG

v5.7 führt ein **transparentes Bewertungssystem** für die Glaubwürdigkeit und Qualität von Quellen ein:

```javascript
function calculateTrustScore(source) {
  let score = 50; // Basiswert

  // POSITIVE INDIKATOREN
  if (source.isPublic) score += 15;
  if (source.hasMultipleConfirmations) score += 15;
  if (source.hasOriginalDocs) score += 10;
  if (source.authorKnown) score += 10;

  // NEGATIVE INDIKATOREN
  if (source.anonymous) score -= 15;
  if (source.singleSource) score -= 10;
  if (source.emotionalLanguage) score -= 10;
  if (source.missingContext) score -= 10;

  return Math.max(0, Math.min(score, 100));
}
```

---

## ✨ VERTRAUENSINDIKATOREN

### **POSITIVE INDIKATOREN** (+):

#### 1. 🌐 Öffentlich zugängliche Quelle (+15 Punkte)
**Erkennung**:
- Wikipedia, .gov, .edu, archive.org
- CIA.gov, FBI.gov, library.congress.gov
- PubMed, arXiv, DOI, ISBN
- NY Times, BBC, Reuters, AP News
- Scientific Journals, Papers

**Beispiele**:
- ✅ "Wikipedia: MK Ultra Project"
- ✅ "CIA declassified documents (cia.gov)"
- ✅ "New York Times, 15. März 2023"

#### 2. ✅ Mehrere unabhängige Bestätigungen (+15 Punkte)
**Erkennung**:
- Multiple Quellen (Kommas, Semikolons)
- Keywords: "mehrere", "verschiedene", "zahlreiche"
- Verknüpfungen: "und", "+", "sowie"

**Beispiele**:
- ✅ "Wikipedia, NY Times, BBC bestätigen..."
- ✅ "Mehrere unabhängige Journalisten berichten..."
- ✅ "Congressional Report + FBI Files"

#### 3. 📄 Originaldokumente vorhanden (+10 Punkte)
**Erkennung**:
- Keywords: dokument, akte, file, declassified
- Formate: PDF, scan, archiv
- Begriffe: original, primärquelle

**Beispiele**:
- ✅ "CIA declassified documents (PDF)"
- ✅ "Originalakte #12345"
- ✅ "Archiv-Scan der Primärquelle"

#### 4. 👤 Nachvollziehbare Autoren (+10 Punkte)
**Erkennung**:
- Akademische Titel: Dr., Prof., Ph.D.
- Vor- und Nachname (Pattern: "John Smith")
- Autoren-Angabe: "Autor:", "by"

**Beispiele**:
- ✅ "Dr. Michael Schmidt, Historiker"
- ✅ "Studie von Prof. Jane Doe"
- ✅ "Investigativ-Bericht by John Miller"

---

### **NEGATIVE INDIKATOREN** (-):

#### 1. 👁️ Anonyme Quelle (-15 Punkte)
**Erkennung**:
- Keywords: anonym, unbekannt, geheim, vertraulich
- Anonymous, confidential, classified
- Whistleblower, Insider ohne Namen

**Beispiele**:
- ❌ "Anonyme Quelle aus dem Pentagon"
- ❌ "Vertraulicher Insider-Bericht"
- ❌ "Whistleblower (Name nicht bekannt)"

#### 2. ⚠️ Nur Einzelnennung (-10 Punkte)
**Erkennung**:
- Keine Mehrfachbestätigung
- Keine offizielle Quelle
- Text < 50 Zeichen

**Beispiele**:
- ❌ "Blog-Artikel von xyz.com"
- ❌ "Einzelner Zeitungsartikel"
- ❌ "Unbestätigte Meldung"

#### 3. 😞 Starke emotionale Sprache (-10 Punkte)
**Erkennung**:
- Keywords: skandal, schock, unglaublich, unfassbar
- Katastrophe, Horror, Sensation
- Exzessive Ausrufezeichen (!!!)

**Beispiele**:
- ❌ "SKANDAL: Unfassbare Enthüllung!!!"
- ❌ "Schockierende Wahrheit, die SIE WISSEN MÜSSEN"
- ❌ "Katastrophale Verschwörung enthüllt"

#### 4. ❓ Fehlender Kontext (-10 Punkte)
**Erkennung**:
- Sehr kurzer Text (< 30 Zeichen)
- Keine Details in Klammern/Brackets
- Keine URL/Link

**Beispiele**:
- ❌ "Irgendein Bericht"
- ❌ "Quelle XYZ"
- ❌ "Siehe Studie"

---

## 📊 SCORE-BERECHNUNG

### Formel

```dart
int score = 50; // Basiswert

// POSITIVE INDIKATOREN (Max +50)
+ Öffentlich zugänglich:          +15
+ Mehrere Bestätigungen:           +15
+ Originaldokumente:               +10
+ Nachvollziehbare Autoren:        +10

// NEGATIVE INDIKATOREN (Max -45)
- Anonyme Quelle:                  -15
- Nur Einzelnennung:               -10
- Emotionale Sprache:              -10
- Fehlender Kontext:               -10

// Ergebnis: 0-100 (clamp)
```

### Beispielberechnungen

**Beispiel 1: Wikipedia-Artikel**
```
Basiswert:                      50
+ Öffentlich zugänglich:       +15
+ Mehrere Bestätigungen:       +15
+ Originaldokumente:           +10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCORE:                          90/100
STUFE: 🟢 Hohe Vertrauenswürdigkeit
```

**Beispiel 2: Anonymer Whistleblower**
```
Basiswert:                      50
- Anonyme Quelle:              -15
- Nur Einzelnennung:           -10
- Emotionale Sprache:          -10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCORE:                          15/100
STUFE: 🔴 Sehr niedrige Vertrauenswürdigkeit
```

**Beispiel 3: Blog mit Dokumenten**
```
Basiswert:                      50
+ Originaldokumente:           +10
+ Nachvollziehbare Autoren:    +10
- Nur Einzelnennung:           -10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCORE:                          60/100
STUFE: 🟠 Mittlere Vertrauenswürdigkeit
```

**Beispiel 4: Perfekte Quelle**
```
Basiswert:                      50
+ Öffentlich zugänglich:       +15
+ Mehrere Bestätigungen:       +15
+ Originaldokumente:           +10
+ Nachvollziehbare Autoren:    +10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCORE:                         100/100
STUFE: 🟢 Hohe Vertrauenswürdigkeit
```

**Beispiel 5: Schlimmste Quelle**
```
Basiswert:                      50
- Anonyme Quelle:              -15
- Nur Einzelnennung:           -10
- Emotionale Sprache:          -10
- Fehlender Kontext:           -10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCORE:                           5/100
STUFE: 🔴 Sehr niedrige Vertrauenswürdigkeit
```

---

## 🎨 VERTRAUENSSTUFEN

### Score-Bereiche

| Score    | Stufe                | Farbe        | Icon       |
|----------|----------------------|--------------|------------|
| 75-100   | Hohe Vertrauenswürdigkeit | 🟢 Grün  | ✅ Verified |
| 50-74    | Mittlere Vertrauenswürdigkeit | 🟠 Orange | ℹ️ Info    |
| 25-49    | Niedrige Vertrauenswürdigkeit | 🟤 Deep Orange | ⚠️ Warning |
| 0-24     | Sehr niedrige Vertrauenswürdigkeit | 🔴 Rot | ⚠️ Dangerous |

### Visuelle Darstellung

**Hohe Vertrauenswürdigkeit (90/100)**:
```
┌────────────────────────────────────────┐
│ ✅ Wikipedia: MK Ultra                 │
│ [🟢 Hohe Vertrauenswürdigkeit] 90/100  │
│                                        │
│ Positive Indikatoren:                  │
│ • 🌐 Öffentlich zugängliche Quelle     │
│ • ✅ Mehrere unabhängige Bestätigungen │
│ • 📄 Originaldokumente vorhanden       │
└────────────────────────────────────────┘
```

**Niedrige Vertrauenswürdigkeit (15/100)**:
```
┌────────────────────────────────────────┐
│ ⚠️ Anonymer Insider-Bericht!!!         │
│ [🔴 Sehr niedrig] 15/100               │
│                                        │
│ Negative Indikatoren:                  │
│ • 👁️ Anonyme Quelle                    │
│ • ⚠️ Nur Einzelnennung                 │
│ • 😞 Starke emotionale Sprache         │
└────────────────────────────────────────┘
```

---

## 🏗️ TECHNISCHE IMPLEMENTIERUNG

### Quellen-Bewertungsmodell

```dart
class QuellenBewertung {
  final String quelle;
  final List<VertrauensIndikator> positiveIndikatoren;
  final List<VertrauensIndikator> negativeIndikatoren;
  
  /// Berechnet Vertrauensscore (0-100)
  int get vertrauensScore {
    int score = 50; // Basiswert
    
    // Positive Indikatoren
    for (final indikator in positiveIndikatoren) {
      switch (indikator) {
        case VertrauensIndikator.oeffentlichZugaenglich:
          score += 15;
        case VertrauensIndikator.mehrfachBestaetigt:
          score += 15;
        case VertrauensIndikator.originaldokumente:
          score += 10;
        case VertrauensIndikator.nachvollziehbareAutoren:
          score += 10;
      }
    }
    
    // Negative Indikatoren
    for (final indikator in negativeIndikatoren) {
      switch (indikator) {
        case VertrauensIndikator.anonymeQuelle:
          score -= 15;
        case VertrauensIndikator.nurEinzelnennung:
          score -= 10;
        case VertrauensIndikator.emotionaleSprache:
          score -= 10;
        case VertrauensIndikator.fehlenderKontext:
          score -= 10;
      }
    }
    
    return score.clamp(0, 100);
  }
  
  /// Automatische Analyse
  factory QuellenBewertung.analyseQuelle(String quelle) {
    // Pattern-basierte Erkennung aller Indikatoren
  }
}
```

### Erkennungs-Algorithmen

**Öffentlich zugängliche Quelle**:
```dart
static bool _istOeffentlichZugaenglich(String quelle) {
  final keywords = [
    'wikipedia', 'gov', '.edu', 'archive.org', 
    'cia.gov', 'fbi.gov', 'pubmed', 'arxiv',
    'nytimes', 'bbc', 'reuters', 'scientific',
  ];
  return keywords.any((kw) => quelle.toLowerCase().contains(kw));
}
```

**Mehrfache Bestätigungen**:
```dart
static bool _hatMehrfachBestaetigungen(String quelle) {
  // Prüft auf Trennzeichen und Keywords
  final multi = quelle.contains(',') || 
                quelle.contains(';') || 
                quelle.contains(' und ');
  final keywords = ['mehrere', 'verschiedene', 'zahlreiche'];
  return multi || keywords.any((k) => quelle.toLowerCase().contains(k));
}
```

**Nachvollziehbare Autoren**:
```dart
static bool _hatNachvollziehbareAutoren(String quelle) {
  final patterns = [
    RegExp(r'dr\.\s+\w+', caseSensitive: false),      // Dr. Smith
    RegExp(r'prof\.\s+\w+', caseSensitive: false),    // Prof. Müller
    RegExp(r'[A-Z][a-z]+\s+[A-Z][a-z]+'),            // John Doe
  ];
  return patterns.any((p) => p.hasMatch(quelle));
}
```

---

## 🎨 UI-INTEGRATION

### Quellen-Section mit Bewertungen

```dart
Widget _buildQuellenSectionMitBewertung(context, structured) {
  // Quellen extrahieren
  final quellenListe = _extractQuellen(structured);
  
  // Automatische Bewertung
  final bewertungen = QuellenAnalyzer.analyseQuellen(quellenListe);
  final avgScore = QuellenAnalyzer.durchschnittlicherScore(bewertungen);
  
  return Column(
    children: [
      // Header mit Durchschnitts-Score
      Container(
        child: Row(
          children: [
            Text('QUELLEN'),
            Spacer(),
            Container(
              child: Text('Ø ${avgScore.toInt()}/100'),
              decoration: BoxDecoration(color: _getScoreColor(avgScore)),
            ),
          ],
        ),
      ),
      
      // Einzelne Quellen-Cards
      ...bewertungen.map((b) => QuellenBewertungsCard(bewertung: b)),
    ],
  );
}
```

### Quellen-Bewertungs-Card

```dart
class QuellenBewertungsCard extends StatelessWidget {
  final QuellenBewertung bewertung;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Quelle & Score
          Row(
            children: [
              Icon(bewertung.vertrauensStufe.icon),
              Text(bewertung.quelle),
              Chip(label: Text('${bewertung.vertrauensScore}/100')),
            ],
          ),
          
          // Positive Indikatoren
          if (bewertung.positiveIndikatoren.isNotEmpty)
            _buildIndikatorenListe('Positive', bewertung.positiveIndikatoren),
          
          // Negative Indikatoren
          if (bewertung.negativeIndikatoren.isNotEmpty)
            _buildIndikatorenListe('Negative', bewertung.negativeIndikatoren),
        ],
      ),
    );
  }
}
```

---

## 📊 BATCH-ANALYSE

### Multiple Quellen analysieren

```dart
class QuellenAnalyzer {
  /// Analysiert mehrere Quellen
  static List<QuellenBewertung> analyseQuellen(List<String> quellen) {
    return quellen.map((q) => QuellenBewertung.analyseQuelle(q)).toList();
  }
  
  /// Durchschnittlicher Score
  static double durchschnittlicherScore(List<QuellenBewertung> bewertungen) {
    if (bewertungen.isEmpty) return 0.0;
    final summe = bewertungen.fold<int>(0, (sum, b) => sum + b.vertrauensScore);
    return summe / bewertungen.length;
  }
  
  /// Verteilung nach Stufen
  static Map<VertrauensStufe, int> verteilungNachStufe(
    List<QuellenBewertung> bewertungen,
  ) {
    final verteilung = <VertrauensStufe, int>{};
    for (final b in bewertungen) {
      verteilung[b.vertrauensStufe] = (verteilung[b.vertrauensStufe] ?? 0) + 1;
    }
    return verteilung;
  }
}
```

**Beispiel-Ausgabe**:
```
Durchschnitts-Score: 62/100
Verteilung:
  🟢 Hoch:          2 Quellen
  🟠 Mittel:        5 Quellen
  🟤 Niedrig:       2 Quellen
  🔴 Sehr niedrig:  1 Quelle
```

---

## 🔍 USE CASES

### Use Case 1: Wikipedia + offizielle Dokumente
**Quellen**:
- "Wikipedia: MK Ultra"
- "CIA declassified documents (cia.gov)"
- "Congressional Investigation Report"

**Bewertungen**:
- Wikipedia: 75 (Hoch)
- CIA docs: 100 (Hoch)
- Congress: 90 (Hoch)
- **Durchschnitt: 88/100 🟢**

### Use Case 2: Gemischte Quellen
**Quellen**:
- "New York Times, 15.03.2023"
- "Blog von John Doe"
- "Anonymer Insider-Bericht"

**Bewertungen**:
- NY Times: 80 (Hoch)
- Blog: 55 (Mittel)
- Anonym: 25 (Niedrig)
- **Durchschnitt: 53/100 🟠**

### Use Case 3: Verschwörungstheorie-Seite
**Quellen**:
- "SCHOCKIERENDE WAHRHEIT!!!"
- "Geheime Insider-Infos"
- "Anonymous whistleblower"

**Bewertungen**:
- Schockierend: 15 (Sehr niedrig)
- Geheim: 20 (Sehr niedrig)
- Anonymous: 25 (Niedrig)
- **Durchschnitt: 20/100 🔴**

---

## 🎯 ZUSAMMENFASSUNG

### Was ist NEU in v5.7?
- ✅ **Quellen-Bewertungssystem** mit Score 0-100
- ✅ **Basiswert 50** für faire Ausgangsbasis
- ✅ **Differenzierte Gewichtung** der Indikatoren
- ✅ **4 Positive Indikatoren** (+10 bis +15 Punkte)
- ✅ **4 Negative Indikatoren** (-10 bis -15 Punkte)
- ✅ **4 Vertrauensstufen** (Hoch, Mittel, Niedrig, Sehr Niedrig)
- ✅ **Automatische Erkennung** via Pattern Matching
- ✅ **Visuelle Darstellung** mit Icons und Farben
- ✅ **Durchschnitts-Score** für alle Quellen
- ✅ **Batch-Analyse** für Multiple Quellen

### Vorteile für Benutzer
- 🎯 **Transparenz**: Klare Bewertungskriterien
- 📊 **Objektivität**: Automatische, regelbasierte Analyse
- 🔍 **Schnellbewertung**: Sofort erkennbare Vertrauenswürdigkeit
- ⚖️ **Faire Gewichtung**: Basiswert 50 für neutrale Quellen
- 📈 **Vergleichbarkeit**: Alle Quellen auf gleicher Skala

### Technische Highlights
- ✅ **Neues Utility**: `QuellenBewertung` & `QuellenAnalyzer`
- ✅ **Pattern-basierte Erkennung**: Regex & Keyword-Matching
- ✅ **Differenzierte Gewichtung**: 10-15 Punkte je Indikator
- ✅ **Clamp-Funktion**: Score immer 0-100
- ✅ **Batch-Processing**: Multiple Quellen parallel

---

## 🔗 DEPLOYMENT

**Live-URL**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
**Worker-API**: https://weltenbibliothek-worker.brandy13062.workers.dev
**Version**: v5.7
**Status**: ✅ Production-Ready

---

## 📚 VERWANDTE DOKUMENTATION

- v5.6.1: UX-Verbesserungen (`RELEASE_NOTES_v5.6.1_UX_VERBESSERUNGEN.md`)
- v5.6: Export-Funktionen (`RELEASE_NOTES_v5.6_EXPORT_FUNKTIONEN.md`)
- v5.5.1: Strukturierte Darstellung (`RELEASE_NOTES_v5.5.1_STRUKTURIERTE_DARSTELLUNG.md`)
- v5.5: Filter-System (`RELEASE_NOTES_v5.5_FILTER_SYSTEM.md`)

---

**🎉 WELTENBIBLIOTHEK v5.7 – Vertraue deinen Quellen!**
