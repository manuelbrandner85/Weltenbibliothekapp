# WELTENBIBLIOTHEK v5.9 – USER-PROFIL-SYSTEM

## 🎯 ZUSAMMENFASSUNG

**Version**: v5.9  
**Fokus**: Personalisierte Recherche-Einstellungen mit User-Profilen  
**Status**: Production-Ready ✅  
**Release-Datum**: 2026-01-04

---

## 🌟 NEUE FUNKTIONEN

### **1. User-Profil-System**
   - **Personalisierte Einstellungen**: Speichert Nutzer-Präferenzen persistent
   - **Recherche-Tiefe**: Oberflächlich (2), Mittel (3), Tief (5)
   - **Bevorzugte Quellen**: Web, Archive, Dokumente, Medien, Timeline
   - **Bevorzugte Sichtweise**: Neutral, Offiziell, Systemkritisch
   - **Interaktions-Gewichtungen**: Algorithmus-Feintuning (0.5-2.0)

### **2. Vordefinierte Profile**
   - **Standard-Profil**: Ausgewogene Einstellungen für allgemeine Recherche
   - **Tiefe Recherche**: Für Power-User mit Archiv- und Dokument-Fokus
   - **Schnelle Übersicht**: Für rasche Informationssuche mit Web-Fokus

### **3. Profil-UI-Integration**
   - **Profil-Badge**: Zeigt aktuelles Profil in der AppBar
   - **Einstellungs-Dialog**: Umfassende UI für alle Profil-Optionen
   - **Echtzeit-Anwendung**: Filter werden sofort aktualisiert

---

## 🔧 TECHNISCHE IMPLEMENTIERUNG

### **Datenmodell**

```dart
class UserProfile {
  final String preferredDepth;                // "oberflächlich", "mittel", "tief"
  final List<String> preferredSources;        // ["web", "archive", "documents", "media"]
  final String preferredView;                 // "neutral", "offiziell", "systemkritisch"
  final Map<String, double> interactionWeights; // {"media": 1.2, "documents": 1.5, ...}
}
```

### **Persistenz mit SharedPreferences**

```dart
// Profil speichern
await profile.save();

// Profil laden
final profile = await UserProfile.load();

// Profil zurücksetzen
await UserProfile.clear();
```

### **Profil-Manager (Singleton)**

```dart
final manager = UserProfileManager();

// Aktuelles Profil abrufen
final profile = await manager.getCurrentProfile();

// Profil aktualisieren
await manager.updateProfile(newProfile);

// Gewichtung anpassen
await manager.updateInteractionWeight('documents', 1.5);
```

---

## 📊 PROFIL-BEISPIELE

### **Beispiel 1: Standard-Profil**

```json
{
  "preferredDepth": "mittel",
  "preferredSources": ["web", "documents"],
  "preferredView": "neutral",
  "interactionWeights": {}
}
```

**Anwendungsfall**: Allgemeine Recherche, ausgewogene Informationssuche

---

### **Beispiel 2: Tiefe Recherche-Profil**

```json
{
  "preferredDepth": "tief",
  "preferredSources": ["archive", "documents"],
  "preferredView": "systemkritisch",
  "interactionWeights": {
    "media": 1.2,
    "documents": 1.5,
    "analysis": 1.3
  }
}
```

**Anwendungsfall**: Power-User, umfassende Analysen, kritische Perspektive

---

### **Beispiel 3: Schnelle Übersicht-Profil**

```json
{
  "preferredDepth": "oberflächlich",
  "preferredSources": ["web"],
  "preferredView": "neutral",
  "interactionWeights": {
    "web": 1.5,
    "timeline": 1.2
  }
}
```

**Anwendungsfall**: Schnelle Information, Überblick, Zeitersparnis

---

## 🎨 VISUELLE DARSTELLUNG

### **Profil-Badge in der AppBar**

```
┌─────────────────────────────────────┐
│ WELTENBIBLIOTHEK v5.9       👤 ▼    │
│                         Tiefe        │
│                        Recherche     │
└─────────────────────────────────────┘
```

### **Profil-Einstellungs-Dialog**

```
╔════════════════════════════════════════════════╗
║ 👤 BENUTZER-PROFIL                             ║
╠════════════════════════════════════════════════╣
║                                                ║
║ Recherche-Tiefe                                ║
║  ○ Oberflächlich  - Schnelle Übersicht        ║
║  ● Mittel         - Standard-Recherche        ║
║  ○ Tief           - Ausführliche Analyse      ║
║                                                ║
║ Bevorzugte Quellen                             ║
║  [✓] Web    [✓] Archive    [✓] Dokumente      ║
║  [ ] Medien [ ] Timeline                       ║
║                                                ║
║ Bevorzugte Sichtweise                          ║
║  ● Neutral          - Ausgewogene Darstellung  ║
║  ○ Offiziell        - Mainstream-Perspektive   ║
║  ○ Systemkritisch   - Kritische Perspektive    ║
║                                                ║
║ Erweiterte Gewichtungen (Optional)             ║
║  Media:      ══════●═══  1.2                   ║
║  Documents:  ═══════●══  1.5                   ║
║  Analysis:   ══════●═══  1.3                   ║
║                                                ║
║ Vordefinierte Profile                          ║
║  [⚖️ Standard-Profil]                           ║
║  [🔍 Tiefe Recherche]                           ║
║  [⚡ Schnelle Übersicht]                        ║
║                                                ║
║        [Abbrechen]    [Speichern]              ║
╚════════════════════════════════════════════════╝
```

---

## 💡 ANWENDUNGSFÄLLE

### **Use Case 1: Investigativer Journalist**

**Profil**: Tiefe Recherche  
**Einstellungen**:
- Tiefe: 5 (Tief)
- Quellen: Archive, Dokumente
- Sichtweise: Systemkritisch
- Gewichtungen: Dokumente 1.5x, Analyse 1.3x

**Vorteil**: Fokus auf primäre Quellen und kritische Analysen

---

### **Use Case 2: Student / Schnelle Hausaufgaben**

**Profil**: Schnelle Übersicht  
**Einstellungen**:
- Tiefe: 2 (Oberflächlich)
- Quellen: Web
- Sichtweise: Neutral
- Gewichtungen: Web 1.5x

**Vorteil**: Rasche Informationen, kein Overload

---

### **Use Case 3: Allgemeine Interessierte**

**Profil**: Standard  
**Einstellungen**:
- Tiefe: 3 (Mittel)
- Quellen: Web, Dokumente
- Sichtweise: Neutral
- Gewichtungen: Keine (alle gleich)

**Vorteil**: Ausgewogene Darstellung, keine Voreingenommenheit

---

## 🔄 INTEGRATION MIT BESTEHENDEN FEATURES

### **Automatische Filter-Anpassung**

```dart
// Beim Laden des Profils werden Filter aktualisiert
final profile = await UserProfile.load();
_filter = RechercheFilter(
  enabledSources: profile.preferredSources.toSet(),
  maxDepth: profile.depthLevel,
);
```

### **Profil-basierte Recherche-Optimierung**

```dart
// Gewichtungen werden in zukünftigen Empfehlungsalgorithmen verwendet
final weight = profile.getSourceWeight('documents'); // 1.5
// Dokumente werden 50% höher gewichtet
```

---

## 📈 VORTEILE

1. **Personalisierung** - Jeder Nutzer kann sein ideales Research-Profil definieren
2. **Zeitersparnis** - Keine manuelle Filter-Anpassung bei jeder Recherche
3. **Konsistenz** - Einstellungen bleiben über Sessions hinweg erhalten
4. **Flexibilität** - Einfacher Wechsel zwischen verschiedenen Profilen
5. **Skalierbarkeit** - Basis für zukünftige ML-basierte Empfehlungen

---

## 🧪 TEST-SZENARIEN

### **Test 1: Profil erstellen und speichern**
1. Öffne Profil-Dialog über Badge
2. Wähle "Tiefe Recherche"
3. Speichere Einstellungen
4. Prüfe dass Badge sich aktualisiert

### **Test 2: Profil-basierte Filter**
1. Erstelle Profil mit nur "Dokumente" als Quelle
2. Starte Recherche
3. Prüfe dass nur Dokumente angezeigt werden

### **Test 3: Profil-Persistenz**
1. Erstelle benutzerdefiniertes Profil
2. Schließe App
3. Öffne App neu
4. Prüfe dass Profil geladen wurde

---

## 🌐 LIVE-DEPLOYMENT

- **Web-App URL**: https://5060-i6i6g94lpb9am6y5rb4gp-0e616f0a.sandbox.novita.ai
- **Worker API**: https://weltenbibliothek-worker.brandy13062.workers.dev
- **Version**: v5.9
- **Status**: Production-Ready ✅

---

## 📝 ZUSAMMENFASSUNG DER ÄNDERUNGEN

### **Neu in v5.9**
- ✅ `UserProfile` Model mit Persistenz
- ✅ `UserProfileManager` Singleton
- ✅ `UserProfileSettingsDialog` UI-Komponente
- ✅ `UserProfileBadge` Widget für AppBar
- ✅ Vordefinierte Profile (Standard, Tief, Schnell)
- ✅ Integration mit Filter-System
- ✅ Automatische Filter-Anpassung bei Profil-Änderung

### **Code-Änderungen**
- **Neu**: `lib/models/user_profile.dart` (8.6 KB)
- **Neu**: `lib/widgets/user_profile_settings.dart` (13.4 KB)
- **Erweitert**: `lib/screens/recherche_screen_hybrid.dart`
  - Profil-Laden beim Init
  - Profil-Badge in AppBar
  - Profil-Dialog-Integration
  - Filter-Synchronisation

---

## 🎯 NÄCHSTE SCHRITTE

### **Empfohlene Erweiterungen**
1. **ML-Empfehlungen**: Profil-Vorschläge basierend auf Nutzungsverhalten
2. **Mehrere Profile**: Nutzer können mehrere Profile erstellen und wechseln
3. **Import/Export**: Profil-Sharing zwischen Nutzern
4. **Cloud-Sync**: Profil-Synchronisation über Geräte hinweg

---

## 📚 DOKUMENTATION

### **Technische Dokumentation**
- `lib/models/user_profile.dart` – Profil-Modell und Manager
- `lib/widgets/user_profile_settings.dart` – Profil-UI
- `lib/screens/recherche_screen_hybrid.dart` – Integration

### **API-Referenz**
- `UserProfile.load()` – Profil aus SharedPreferences laden
- `UserProfile.save()` – Profil speichern
- `UserProfileManager.getCurrentProfile()` – Aktuelles Profil abrufen
- `UserProfileManager.updateProfile(profile)` – Profil aktualisieren

---

## 🏆 PROJEKTSTATUS

✅ **WELTENBIBLIOTHEK v5.9 ist vollständig implementiert und production-ready!**

### **Alle Features v5.0 – v5.9**
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
- ✅ **v5.9: User-Profil-System** ← NEU

---

**Möchtest du das User-Profil-System jetzt in der Web-App testen?** 🚀

**Empfohlene Test-Schritte:**
1. Klicke auf das Profil-Badge in der AppBar
2. Wähle eines der vordefinierten Profile
3. Passe Gewichtungen an (optional)
4. Speichere das Profil
5. Führe eine Recherche durch und beobachte die Filter-Anpassung
