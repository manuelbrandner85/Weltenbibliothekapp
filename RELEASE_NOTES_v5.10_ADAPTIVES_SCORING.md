# WELTENBIBLIOTHEK v5.10 – ADAPTIVES SCORING-SYSTEM

## 🎯 ZUSAMMENFASSUNG

**Version**: v5.10  
**Fokus**: Intelligente Quellen-Bewertung mit User-Profil-Gewichtung  
**Status**: Production-Ready ✅  
**Release-Datum**: 2026-01-04

---

## 🚀 NEUE FUNKTIONEN

### **1. Adaptives Scoring-System**
   - **Formula**: `adaptedScore = trustScore × userWeight`
   - **Personalisierte Relevanz**: Quellen werden basierend auf User-Präferenzen höher/niedriger bewertet
   - **Dynamisches Ranking**: Sortierung passt sich automatisch an User-Profil an
   - **Transparente Berechnung**: Scoring-Breakdown zeigt alle Faktoren

### **2. Automatische Quellen-Typ-Erkennung**
   - **Web**: Standard-Webseiten
   - **Archive**: Archive.org, Wayback Machine
   - **Dokumente**: PDFs, Akten, Files
   - **Medien**: Videos, Audio, Podcasts
   - **Timeline**: Chronologische Events

### **3. Scoring-Report & Analytics**
   - **Durchschnitts-Scores**: Trust vs. Adaptiv
   - **Gewichtungs-Effekt**: Wie stark hat das Profil die Scores verändert?
   - **Top-Quellen**: Die 5 relevantesten Ergebnisse
   - **Debugging-Informationen**: Für Entwickler und Power-User

---

## 🔧 TECHNISCHE IMPLEMENTIERUNG

### **Scoring-Formula**

```dart
// Basis-Berechnung
double calculateAdaptedScore({
  required QuellenBewertung bewertung,
  required UserProfile userProfile,
  required String sourceType,
}) {
  final trustScore = bewertung.vertrauensScore.toDouble();
  final userWeight = userProfile.getSourceWeight(sourceType);
  final adaptedScore = trustScore * userWeight;
  return adaptedScore.clamp(0.0, 100.0);
}
```

### **Beispiel-Berechnung**

**Szenario**: Dokument mit hohem Trust-Score, Nutzer bevorzugt Dokumente

```
Trust-Score:      80/100
User-Gewichtung:  1.5x (Dokumente bevorzugt)
────────────────────────
Adaptiver Score:  120 → 100/100 (capped)
```

**Resultat**: Quelle wird als "Top-Quelle" behandelt

---

### **Scoring mit verschiedenen Gewichtungen**

| Quellen-Typ | Trust-Score | User-Gewichtung | Adaptiver Score | Effekt |
|-------------|-------------|-----------------|-----------------|--------|
| Dokument    | 80/100      | 1.5x            | 100/100 ↑       | +20    |
| Web         | 60/100      | 1.0x            | 60/100 →        | ±0     |
| Medien      | 50/100      | 0.5x            | 25/100 ↓        | -25    |

---

## 📊 ADAPTIVE SCORED SOURCE

### **Datenmodell**

```dart
class AdaptiveScoredSource {
  final QuellenBewertung bewertung;
  final String sourceType;
  final double trustScore;      // Original
  final double userWeight;      // User-Gewichtung
  final double adaptedScore;    // Angepasster Score
  
  // Helper
  double get scoreDifference;   // +/- Differenz
  bool get wasUpgraded;         // Score erhöht?
  bool get wasDowngraded;       // Score reduziert?
}
```

### **Beispiel-Instanz**

```json
{
  "sourceType": "documents",
  "trustScore": 80.0,
  "userWeight": 1.5,
  "adaptedScore": 100.0,
  "scoreDifference": +20.0,
  "wasUpgraded": true
}
```

---

## 🎨 VISUELLE DARSTELLUNG

### **Adaptive Scored Source Card**

```
┌─────────────────────────────────────────────────────────┐
│ ✓ CIA-Dokumente (Original-PDF)                          │
│                                                          │
│   [Trust: 80]  ↑  [Adaptiv: 100]                        │
│                                                          │
│   ╔════════════ SCORING-BREAKDOWN ══════════════╗       │
│   ║ Trust-Score           80.0/100               ║       │
│   ║ User-Gewichtung (documents)  × 1.5           ║       │
│   ║ ─────────────────────────────────────        ║       │
│   ║ Adaptiver Score      100.0/100               ║       │
│   ╚════════════════════════════════════════════╝       │
│                                                          │
│   ✓ Öffentlich zugänglich                               │
│   ✓ Originaldokumente                                    │
│   ✓ Nachvollziehbare Autoren                             │
└─────────────────────────────────────────────────────────┘
```

### **Scoring-Report Widget**

```
╔═══════════════════════════════════════════════════════╗
║ 📊 SCORING-REPORT                                     ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║ 📊 Quellen-Übersicht:                                 ║
║   Gesamt: 10                                          ║
║   Bewertet: 8                                         ║
║   Nicht bewertet: 2                                   ║
║                                                       ║
║ 📈 Durchschnittliche Scores:                          ║
║   Trust-Score: 65.0/100                               ║
║   Adaptiver Score: 75.5/100                           ║
║   Gewichtungs-Effekt: +10.5                           ║
║                                                       ║
║ 🏆 Top 5 Quellen:                                     ║
║   1. CIA-Dokumente (Original-PDF)                     ║
║      Score: 100↑   Gewichtung: Bevorzugt (1.5x)      ║
║   2. Scientific Journal Article                       ║
║      Score: 85→    Gewichtung: Standard (1.0x)       ║
║   ...                                                 ║
╚═══════════════════════════════════════════════════════╝
```

---

## 💡 ANWENDUNGSBEISPIELE

### **Beispiel 1: Investigativer Journalist**

**User-Profil**:
```json
{
  "interactionWeights": {
    "archive": 1.3,
    "documents": 1.5,
    "media": 1.2
  }
}
```

**Ergebnis**:
- Archiv-Dokumente: 80 × 1.3 = **104 → 100/100** ✅
- Web-Artikel: 70 × 1.0 = **70/100** →
- Social Media: 40 × 1.0 = **40/100** →

**Vorteil**: Primäre Quellen werden priorisiert

---

### **Beispiel 2: Schnelle Recherche**

**User-Profil**:
```json
{
  "interactionWeights": {
    "web": 1.5,
    "documents": 0.8
  }
}
```

**Ergebnis**:
- Web-Artikel: 65 × 1.5 = **97.5/100** ↑
- Dokument: 80 × 0.8 = **64/100** ↓

**Vorteil**: Web-Quellen für schnelle Info werden bevorzugt

---

## 🔄 INTEGRATION MIT BESTEHENDEN FEATURES

### **User-Profil-System (v5.9)**
```dart
// Gewichtungen aus Profil werden automatisch angewendet
final profile = await UserProfile.load();
final weight = profile.getSourceWeight('documents'); // 1.5
```

### **Quellen-Bewertungssystem (v5.7)**
```dart
// Trust-Score ist Basis für adaptiven Score
final trustScore = bewertung.vertrauensScore; // 80
final adaptedScore = trustScore * weight;      // 120 → 100
```

### **Sortierung (v5.7.2)**
```dart
// Sortierung jetzt nach adaptivem Score statt Trust-Score
sources.sort((a, b) => b.adaptedScore.compareTo(a.adaptedScore));
```

---

## 📈 VORTEILE DES ADAPTIVEN SCORINGS

1. **Personalisierung** - Jeder Nutzer sieht relevanteste Quellen zuerst
2. **Transparenz** - Scoring-Breakdown zeigt alle Faktoren
3. **Flexibilität** - Einfache Anpassung durch Profil-Änderung
4. **Nicht-invasiv** - Original Trust-Score bleibt unverändert
5. **Skalierbar** - Basis für ML-basierte Empfehlungen

---

## 🧪 TEST-SZENARIEN

### **Test 1: Gewichtungs-Effekt**
1. Erstelle Profil mit Dokumente-Gewichtung 1.5x
2. Suche nach "MK Ultra"
3. Prüfe dass Dokumente höher gerankt sind
4. Prüfe Scoring-Breakdown zeigt korrekte Berechnung

### **Test 2: Profil-Vergleich**
1. Teste mit Standard-Profil (alle 1.0x)
2. Teste mit Tiefe-Recherche-Profil (Dokumente 1.5x)
3. Vergleiche Ranking-Unterschiede

### **Test 3: Scoring-Report**
1. Führe Recherche durch
2. Generiere Scoring-Report
3. Prüfe Durchschnitts-Scores und Gewichtungs-Effekt

---

## 🌐 LIVE-DEPLOYMENT

- **Web-App URL**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
- **Worker API**: https://weltenbibliothek-worker.brandy13062.workers.dev
- **Version**: v5.10
- **Status**: Production-Ready ✅

---

## 📝 ZUSAMMENFASSUNG DER ÄNDERUNGEN

### **Neu in v5.10**
- ✅ `AdaptiveScoring` Utility-Klasse
- ✅ `calculateAdaptedScore()` Funktion
- ✅ `AdaptiveScoredSource` Modell
- ✅ `ScoringReport` für Analytics
- ✅ `SourceTypeDetector` für automatische Typ-Erkennung
- ✅ `AdaptiveScoredSourceCard` UI-Widget
- ✅ `ScoringReportWidget` für Debugging

### **Code-Änderungen**
- **Neu**: `lib/utils/adaptive_scoring.dart` (9.3 KB)
- **Neu**: `lib/widgets/adaptive_scoring_card.dart` (11.9 KB)

---

## 🎯 NÄCHSTE SCHRITTE

### **Empfohlene Erweiterungen**
1. **ML-basierte Gewichtungen**: Automatische Anpassung basierend auf Click-Verhalten
2. **Relevanz-Scoring**: Kombiniert Trust + User-Präferenz + Kontext
3. **A/B-Testing**: Vergleich verschiedener Scoring-Algorithmen
4. **Feedback-Loop**: Nutzer-Feedback zur Score-Optimierung

---

## 📚 DOKUMENTATION

### **Technische Dokumentation**
- `lib/utils/adaptive_scoring.dart` – Scoring-Algorithmen
- `lib/widgets/adaptive_scoring_card.dart` – UI-Komponenten
- `lib/models/user_profile.dart` – Profil mit Gewichtungen

### **API-Referenz**
- `AdaptiveScoring.calculateAdaptedScore()` – Score-Berechnung
- `AdaptiveScoring.scoreMultipleSources()` – Batch-Scoring
- `AdaptiveScoring.sortByAdaptedScore()` – Sortierung
- `AdaptiveScoring.generateReport()` – Analytics-Report

---

## 🏆 PROJEKTSTATUS

✅ **WELTENBIBLIOTHEK v5.10 ist vollständig implementiert und production-ready!**

### **Alle Features v5.0 – v5.10**
- ✅ v5.0: Hybrid-SSE-System
- ✅ v5.1: Timeline-Integration
- ✅ v5.2: Fakten-Trennung
- ✅ v5.3: Neutrale Perspektiven
- ✅ v5.4: Strukturierte JSON-Extraktion
- ✅ v5.5: Filter-System
- ✅ v5.5.1: Strukturierte Darstellung
- ✅ v5.6: Export-Funktionen
- ✅ v5.6.1: UX-Verbesserungen
- ✅ v5.7: Quellen-Bewertungssystem
- ✅ v5.7.1: Sekundärquellen-Erkennung
- ✅ v5.7.2: Quellen-Sortierung
- ✅ v5.8: Robustes Fehlerhandling
- ✅ v5.9: User-Profil-System
- ✅ **v5.10: Adaptives Scoring-System** ← NEU

---

**Möchtest du das adaptive Scoring-System jetzt testen?** 🚀

**Test-Workflow:**
1. Erstelle User-Profil mit Gewichtungen (z.B. Dokumente 1.5x)
2. Führe Recherche durch (z.B. "MK Ultra")
3. Beobachte wie Dokumente höher gerankt werden
4. Prüfe Scoring-Breakdown in Quellen-Cards
5. Vergleiche mit Standard-Profil (alle 1.0x)
