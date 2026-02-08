# 📋 WELTENBIBLIOTHEK v5.15 FINAL – KI-TRANSPARENZ-SYSTEM

## 🎯 Übersicht

**Version:** v5.15 FINAL  
**Build-Zeit:** 70.6s  
**Status:** ✅ PRODUCTION-READY  
**Live-URL:** https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai  
**Server:** Port 5060 (PID 367766)

---

## 🆕 NEUE FEATURES: KI-TRANSPARENZ-SYSTEM

### **Kern-Prinzip**

**KI DARF:**
- ✓ **Einordnen** (Kontext geben)
- ✓ **Vergleichen** (Perspektiven gegenüberstellen)
- ✓ **Strukturieren** (Daten organisieren)

**KI DARF NICHT:**
- ✗ **Fakten erfinden**
- ✗ **Quellen ersetzen**
- ✗ **Fehlende Daten verstecken**

---

## 🔧 IMPLEMENTIERUNG

### **1. Backend-Prompts mit KI-Regeln**

**Datei:** `lib/services/rabbit_hole_service.dart`

**Alle 6 Kaninchenbau-Ebenen** enthalten jetzt diese Transparenz-Regeln:

```dart
const kiRules = '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 KI-TRANSPARENZ-REGELN (STRIKT EINHALTEN):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ KI DARF:
  • Einordnen (Kontext geben)
  • Vergleichen (Perspektiven gegenüberstellen)
  • Strukturieren (Daten organisieren)

✗ KI DARF NICHT:
  • Fakten erfinden
  • Quellen ersetzen
  • Fehlende Daten verstecken

WENN KEINE QUELLEN: Klar kennzeichnen als "Keine Quellen verfügbar"
WENN UNSICHER: Explizit als "Spekulation" oder "Interpretation" markieren
IMMER: Belegte Fakten von Interpretationen trennen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
```

**Diese Regeln werden an jede Backend-API-Anfrage gesendet!**

---

### **2. UI-Warnung in Standard-Recherche**

**Datei:** `lib/screens/recherche_screen_v2.dart`

**Am Anfang der Ergebnisse** erscheint eine **klare KI-Transparenz-Warnung**:

```dart
// 🆕 KI-TRANSPARENZ-WARNUNG
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.amber[900]?.withOpacity(0.3),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.amber[700]!, width: 2),
  ),
  child: Row(
    children: [
      Icon(Icons.info_outline, color: Colors.amber[400], size: 20),
      Expanded(
        child: Column(
          children: [
            Text('KI-TRANSPARENZ'),
            Text(
              '✓ KI darf: Einordnen, Vergleichen, Strukturieren\n'
              '✗ KI darf NICHT: Fakten erfinden, Quellen ersetzen, fehlende Daten verstecken',
            ),
          ],
        ),
      ),
    ],
  ),
)
```

**Farbe:** Amber (gelb-orange) für maximale Aufmerksamkeit  
**Position:** Direkt über den Ergebnissen  
**Immer sichtbar:** Bei jedem Standard-Recherche-Ergebnis

---

### **3. Kaninchenbau: KI-Fallback-Kennzeichnung**

**Bereits implementiert (v5.14):**
- Orange "KI"-Badge bei Nodes ohne externe Quellen
- Trust-Score 0-40 bei KI-Fallback
- Explizite Warnung im Event-Log

**Beispiel:**
```
⚠️ Ebene 3: Nutze KI-Analyse (keine externen Quellen)
```

---

## 📊 WORKFLOW MIT KI-TRANSPARENZ

### **Standard-Recherche**

```
┌─────────────────────────┐
│  User gibt Query ein    │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Backend-API-Call       │
│  mit KI-Regeln          │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  UI zeigt KI-Warnung    │
│  (Amber-Box)            │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  Ergebnisse anzeigen    │
│  FAKTEN | QUELLEN       │
│  ANALYSE | SICHTWEISE   │
└─────────────────────────┘
```

---

### **Kaninchenbau (6 Ebenen)**

```
┌─────────────────────────┐
│  Ebene X starten        │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│  1. Externe Quellen     │
│     suchen              │
└───────────┬─────────────┘
            │
         ┌──┴──┐
         │     │
    Gefunden?  Nicht gefunden
         │     │
         ▼     ▼
┌────────────┐ ┌────────────┐
│ Verwende   │ │ KI-Fallback│
│ Quellen    │ │ + Warnung  │
│ Trust 50-  │ │ Trust 0-40 │
│ 100        │ │ + Badge    │
└────────────┘ └────────────┘
```

---

## ✅ VORTEILE

1. **Transparenz**: User weiß immer, wann KI verwendet wird
2. **Vertrauen**: Klare Regeln für KI-Nutzung
3. **Qualitätssicherung**: KI darf keine Fakten erfinden
4. **Quellenpriorität**: Externe Quellen immer bevorzugt
5. **Visuelle Kennzeichnung**: Amber-Warnung + Orange-Badge
6. **Backend-Kontrolle**: Regeln in jedem API-Prompt

---

## 📝 GEÄNDERTE DATEIEN

### **Backend-Service**
- `lib/services/rabbit_hole_service.dart`
  - Zeile 220-260: KI-Transparenz-Regeln in allen 6 Ebenen-Prompts

### **Frontend-UI**
- `lib/screens/recherche_screen_v2.dart`
  - Zeile 1180-1230: KI-Transparenz-Warnung in Standard-Recherche

### **Bereits vorhanden (v5.14)**
- `lib/widgets/rabbit_hole_visualization_card.dart`
  - Zeile 365-375: KI-Badge bei isFallback-Nodes

---

## 🚀 VOLLSTÄNDIGE FEATURE-LISTE v5.15 FINAL

1. ✅ **3 Recherche-Modi** (Standard, Kaninchenbau, International)
2. ✅ **Alles im Recherche-Tab** (keine Navigation)
3. ✅ **Echtes Status-Tracking** (Live-Progress)
4. ✅ **Strukturierte Ausgabe** (Fakten/Quellen/Analyse/Sichtweise)
5. ✅ **Media Validation** (nur erreichbare Medien)
6. ✅ **KI-Transparenz-System** 🆕 (klare Regeln + Warnung)
7. ✅ **Trust-Score 0-100** (Quellenqualität)
8. ✅ **Dunkles Theme** (konsistent)

---

## 🎯 USER-FLOW MIT KI-TRANSPARENZ

### **Beispiel: Standard-Recherche zu "MK Ultra"**

1. User gibt "MK Ultra" ein
2. Klickt "RECHERCHE STARTEN"
3. **SIEHT SOFORT:** Amber KI-Transparenz-Warnung
   ```
   🆕 KI-TRANSPARENZ
   ✓ KI darf: Einordnen, Vergleichen, Strukturieren
   ✗ KI darf NICHT: Fakten erfinden, Quellen ersetzen, fehlende Daten verstecken
   ```
4. Scrollt zu Ergebnissen:
   - **FAKTEN (belegt)** – Grün
   - **QUELLEN** – Blau, mit Trust-Score
   - **ANALYSE** – Lila (KI-Interpretation)
   - **ALTERNATIVE SICHTWEISE** – Orange

**User weiß jetzt:**
- Was sind belegte Fakten (Grün)
- Welche Quellen sind vertrauenswürdig (Trust-Score)
- Wo KI interpretiert (Analyse/Sichtweise)
- Was KI darf und was nicht (Amber-Warnung)

---

### **Beispiel: Kaninchenbau zu "MK Ultra"**

1. User wählt **Kaninchenbau-Modus**
2. Klickt "🕳️ KANINCHENBAU STARTEN"
3. **Ebene 1: Ereignis**
   - Backend sucht externe Quellen
   - ✅ 8 Quellen gefunden (Trust 85)
   - Keine KI nötig
4. **Ebene 3: Organisationen**
   - Backend sucht externe Quellen
   - ❌ Keine Quellen gefunden
   - ⚠️ Event-Log: "Nutze KI-Analyse (keine externen Quellen)"
   - Orange "KI"-Badge in UI
   - Trust-Score 35 (niedrig)
5. **Ebene 4: Geldflüsse**
   - Backend sucht externe Quellen
   - ✅ 5 Quellen gefunden (Trust 70)
   - Keine KI nötig

**User sieht:**
- Welche Ebenen auf echten Quellen basieren (kein Badge)
- Welche Ebenen KI-generiert sind (Orange Badge)
- Trust-Score reflektiert Quellenqualität

---

## 📈 TRUST-SCORE-SYSTEM

### **Externe Quellen**
- **75-100**: Offizielle Dokumente, Archive, wissenschaftliche Studien
- **50-74**: Journalistische Quellen, Wikipedia, Fachmedien
- **25-49**: Blogs, individuelle Berichte

### **KI-Fallback**
- **0-40**: KI-generierte Analyse ohne externe Quellen
- Immer gekennzeichnet mit Orange "KI"-Badge
- Immer mit Warnung im Event-Log

---

## 🛡️ SICHERHEITS-FEATURES

1. **Backend-Kontrolle**: KI-Regeln in jedem Prompt
2. **UI-Warnung**: Amber-Box bei jedem Ergebnis
3. **Visuelle Kennzeichnung**: Orange Badge bei KI-Fallback
4. **Trust-Score**: Niedriger Score bei KI-Nutzung
5. **Event-Log**: Explizite Warnungen bei Fallback
6. **Medien-Validation**: Nur erreichbare Medien anzeigen

---

## 📦 DEPLOYMENT-STATUS

- **Version**: v5.15 FINAL
- **Build-Zeit**: 70.6s
- **Bundle-Größe**: ~2.5 MB
- **Server**: Port 5060 (PID 367766)
- **Status**: ✅ PRODUCTION-READY
- **Live-URL**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai

---

## 🎯 FINALE ZUSAMMENFASSUNG

**Weltenbibliothek v5.15 FINAL** ist ein **vollständig transparentes Recherche-Tool** mit:

- ✅ **Klare KI-Regeln** (darf/darf nicht)
- ✅ **Visuelle Warnungen** (Amber-Box + Orange Badge)
- ✅ **Quellenpriorität** (externe Quellen zuerst)
- ✅ **Trust-Score-System** (0-100, reflektiert Qualität)
- ✅ **3 Recherche-Modi** (Standard/Kaninchenbau/International)
- ✅ **Strukturierte Ausgabe** (Fakten/Quellen/Analyse/Sichtweise)
- ✅ **Media-Validation** (nur erreichbare Medien)
- ✅ **Echtes Status-Tracking** (Live-Progress)

**User hat immer die Kontrolle und weiß genau, was KI ist und was nicht!**

---

*Made with 💻 by Claude Code Agent*  
*Weltenbibliothek-Worker v5.15 FINAL – KI-Transparenz-System*
