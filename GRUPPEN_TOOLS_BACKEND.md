# 🛠️ GRUPPEN-TOOLS CLOUDFLARE BACKEND

## ✅ STATUS: BACKEND LIVE & FUNKTIONSFÄHIG!

**Cloudflare Worker URL**: https://weltenbibliothek-group-tools.brandy13062.workers.dev

---

## 📊 IMPLEMENTIERTE FEATURES

### **Cloudflare D1 Database**
- ✅ **19 Tabellen** für alle 18 Gruppen-Tools
- ✅ **Indexes** für optimale Performance
- ✅ **JSON-Support** für flexible Datenstrukturen
- ✅ **Timestamps** für alle Einträge
- ✅ **Likes & Comments** System

### **Cloudflare Worker API**
- ✅ **REST API** mit CORS-Support
- ✅ **GET & POST** Endpoints
- ✅ **6 ENERGIE-Tools** komplett implementiert
- ✅ **Error-Handling** & JSON-Response
- ✅ **Query-Parameter** Support

### **Flutter Service**
- ✅ **GroupToolsService** mit allen ENERGIE-Methoden
- ✅ **Type-Safe** API-Calls
- ✅ **Debug-Logging** für Entwicklung
- ✅ **Error-Handling** mit Fallbacks

---

## 🔮 ENERGIE-WELT TOOLS (6/6 IMPLEMENTIERT)

### **1. 🧘 Meditation Timer Sessions**
**Tabelle**: `meditation_sessions`

**GET**: `/api/tools/energie/meditation?room_id=meditation&limit=50`
```json
{
  "success": true,
  "sessions": [
    {
      "id": "med_1768862771754_e3e4ajdw8",
      "room_id": "meditation",
      "created_by": "user_manuel",
      "duration_minutes": 20,
      "session_start": "2026-01-19 22:46:11",
      "participants": "[\"user_manuel\",\"user_anna\"]",
      "notes": "Sehr friedliche Session"
    }
  ]
}
```

**POST**: `/api/tools/energie/meditation`
```json
{
  "room_id": "meditation",
  "created_by": "user_manuel",
  "duration_minutes": 20,
  "participants": ["user_manuel", "user_anna"],
  "notes": "Notizen zur Session"
}
```

**Flutter**:
```dart
final service = GroupToolsService();

// Sessions abrufen
final sessions = await service.getMeditationSessions(
  roomId: 'meditation',
  limit: 50,
);

// Neue Session erstellen
final sessionId = await service.createMeditationSession(
  roomId: 'meditation',
  userId: 'user_manuel',
  durationMinutes: 20,
  participants: ['user_manuel', 'user_anna'],
  notes: 'Sehr friedlich',
);
```

---

### **2. 🌙 Astrales Tagebuch**
**Tabelle**: `astral_journal`

**GET**: `/api/tools/energie/astral?room_id=astralreisen&limit=50`
**POST**: `/api/tools/energie/astral`

**Felder**:
- `title`: Titel der Astralreise
- `experience`: Beschreibung der Erfahrung
- `techniques_used`: Array von Techniken
- `success_level`: 1-5 Erfolgs-Rating
- `comments`: Array von Kommentaren
- `likes`: Anzahl Likes

**Flutter**:
```dart
// Einträge abrufen
final entries = await service.getAstralJournal(
  roomId: 'astralreisen',
);

// Neuer Eintrag
final entryId = await service.createAstralEntry(
  roomId: 'astralreisen',
  userId: 'user_manuel',
  username: 'Manuel',
  title: 'Erste erfolgreiche Projektion',
  experience: 'Konnte meinen Körper verlassen...',
  techniques: ['Rope-Technik', 'Vibrationen'],
  successLevel: 4,
);
```

---

### **3. 💎 Chakra Scans**
**Tabelle**: `chakra_scans`

**GET**: `/api/tools/energie/chakra?room_id=chakra&user_id=user_manuel`
**POST**: `/api/tools/energie/chakra`

**Felder**:
- `scanned_user_id`: Gescannter User
- `scanner_user_id`: Scannender User
- `scan_data`: JSON mit Chakra-Status
- `blockages`: Array von Blockaden
- `recommendations`: Empfehlungen

**Flutter**:
```dart
// Scans abrufen
final scans = await service.getChakraScans(
  roomId: 'chakra',
  userId: 'user_manuel',
);

// Neuer Scan
final scanId = await service.createChakraScan(
  roomId: 'chakra',
  scannedUserId: 'user_anna',
  scannedUsername: 'Anna',
  scannerUserId: 'user_manuel',
  scannerUsername: 'Manuel',
  scanData: {
    'wurzel': 'offen',
    'sakral': 'blockiert',
    'solarplexus': 'ausgeglichen',
  },
  blockages: ['Sakralchakra: Emotionale Blockade'],
  recommendations: 'Orange Kleidung tragen, Tanzen',
);
```

---

### **4. 💠 Kristall-Bibliothek**
**Tabelle**: `crystal_library`

**GET**: `/api/tools/energie/crystals?room_id=kristalle&search=amethyst`
**POST**: `/api/tools/energie/crystals`

**Felder**:
- `crystal_name`: Name des Kristalls
- `crystal_type`: Typ/Kategorie
- `properties`: Array von Eigenschaften
- `uses`: Anwendungsmöglichkeiten
- `image_url`: Bild-URL
- `experiences`: JSON mit Erfahrungen
- `likes`: Anzahl Likes

**Flutter**:
```dart
// Kristalle abrufen
final crystals = await service.getCrystals(
  roomId: 'kristalle',
  search: 'Amethyst',
);

// Neuer Kristall
final crystalId = await service.addCrystal(
  roomId: 'kristalle',
  userId: 'user_manuel',
  username: 'Manuel',
  crystalName: 'Amethyst',
  crystalType: 'Quarz',
  properties: ['Beruhigend', 'Spirituell', 'Intuition'],
  uses: 'Meditation, Schlaf, Drittes Auge',
  imageUrl: 'https://...',
);
```

---

### **5. 🎵 Heilfrequenzen Sessions**
**Tabelle**: `frequency_sessions`

**GET**: `/api/tools/energie/frequency?room_id=frequenzen`
**POST**: `/api/tools/energie/frequency`

**Felder**:
- `frequency_hz`: Frequenz (z.B. "528 Hz")
- `duration_minutes`: Session-Dauer
- `participants`: Array von Teilnehmern
- `effects_reported`: Array von berichteten Effekten

**Flutter**:
```dart
// Sessions abrufen
final sessions = await service.getFrequencySessions(
  roomId: 'frequenzen',
);

// Neue Session
final sessionId = await service.createFrequencySession(
  roomId: 'frequenzen',
  userId: 'user_manuel',
  frequencyHz: '528 Hz',
  durationMinutes: 30,
  participants: ['user_manuel', 'user_anna'],
);
```

---

### **6. 💫 Gruppen-Traumtagebuch**
**Tabelle**: `dream_journal`

**GET**: `/api/tools/energie/dreams?room_id=traumarbeit`
**POST**: `/api/tools/energie/dreams`

**Felder**:
- `dream_title`: Traum-Titel
- `dream_description`: Traum-Beschreibung
- `symbols`: Array von Symbolen
- `lucid`: Boolean - war es ein Klartraum?
- `ai_interpretation`: KI-Deutung (optional)
- `comments`: Array von Kommentaren
- `likes`: Anzahl Likes

**Flutter**:
```dart
// Träume abrufen
final dreams = await service.getDreams(
  roomId: 'traumarbeit',
);

// Neuer Traum
final dreamId = await service.createDream(
  roomId: 'traumarbeit',
  userId: 'user_manuel',
  username: 'Manuel',
  title: 'Flug über die Stadt',
  description: 'Ich konnte fliegen und sah die Stadt von oben...',
  symbols: ['Fliegen', 'Stadt', 'Freiheit'],
  lucid: true,
);
```

---

## 🌍 MATERIE-WELT TOOLS (0/6 IMPLEMENTIERT)

**Tabellen vorhanden** für:
1. 🎭 Geopolitik-Kartierung → `geopolitics_map`
2. 🏛️ Geschichte-Zeitleiste → `history_timeline`
3. 🛸 UFO-Sichtungen → `ufo_sightings`
4. 👁️ Verbindungsnetz → `connection_network`
5. 🔬 Forschungs-Archiv → `research_archive`
6. 🌿 Heilmethoden → `healing_methods`

**Status**: Endpoints vorhanden als Placeholder - TODO Implementierung

---

## ✨ SPIRIT-WELT TOOLS (0/6 IMPLEMENTIERT)

**Tabellen vorhanden** für:
1. 🔮 Tarot-Lesungen → `tarot_readings`
2. 😇 Engel-Kontakte → `angel_contacts`
3. ⚡ Ritual-Bibliothek → `ritual_library`
4. 👻 Paranormale Events → `paranormal_events`
5. 🦅 Schamanische Reisen → `shamanic_journeys`
6. 🕉️ Praxis-Challenges → `practice_challenges` + `practice_progress`

**Status**: Endpoints vorhanden als Placeholder - TODO Implementierung

---

## 📋 VERWENDUNG

### **1. Service initialisieren**:
```dart
import 'package:weltenbibliothek/services/group_tools_service.dart';

final toolsService = GroupToolsService();
```

### **2. Daten abrufen**:
```dart
final sessions = await toolsService.getMeditationSessions(
  roomId: 'meditation',
  limit: 50,
);

for (final session in sessions) {
  print('Session: ${session['notes']}');
  print('Dauer: ${session['duration_minutes']} Minuten');
}
```

### **3. Daten erstellen**:
```dart
final sessionId = await toolsService.createMeditationSession(
  roomId: 'meditation',
  userId: 'user_manuel',
  durationMinutes: 20,
  participants: ['user_manuel', 'user_anna'],
  notes: 'Sehr friedliche Session',
);

if (sessionId != null) {
  print('✅ Session erstellt: $sessionId');
} else {
  print('❌ Fehler beim Erstellen');
}
```

---

## 🚀 NÄCHSTE SCHRITTE

### **Phase 1: ENERGIE-Tools UI** (JETZT)
1. ✅ Backend implementiert
2. ✅ Flutter Service erstellt
3. 🚧 **TODO**: UI-Screens für jedes Tool
4. 🚧 **TODO**: Tool-Dialoge mit Funktionen
5. 🚧 **TODO**: Integration in Live-Chat

### **Phase 2: MATERIE-Tools**
1. 🚧 Backend-Endpoints implementieren
2. 🚧 Flutter Service erweitern
3. 🚧 UI-Screens erstellen

### **Phase 3: SPIRIT-Tools**
1. 🚧 Backend-Endpoints implementieren
2. 🚧 Flutter Service erweitern
3. 🚧 UI-Screens erstellen

---

## 🔧 TECHNISCHE DETAILS

### **Cloudflare D1 Database**:
- **Name**: weltenbibliothek-group-tools-db
- **ID**: 32509575-ccfd-48db-a947-89fce95856b1
- **Region**: ENAM (Eastern North America)
- **Tabellen**: 19
- **Größe**: ~0.32 MB

### **Cloudflare Worker**:
- **Name**: weltenbibliothek-group-tools
- **URL**: https://weltenbibliothek-group-tools.brandy13062.workers.dev
- **Version**: 3d74a634-51cd-4792-b22e-7bce582004cc
- **Size**: 16.40 KiB (2.38 KiB gzip)

### **API-Features**:
- ✅ CORS aktiviert für alle Origins
- ✅ JSON Request/Response
- ✅ Error-Handling mit HTTP Status Codes
- ✅ Query-Parameter für Filtering
- ✅ Pagination mit `limit` Parameter

---

## 📚 WEITERE DOKUMENTATIONEN

- `/home/user/flutter_app/ALLE_WELTEN_6_RÄUME.md` - Übersicht aller Chat-Räume
- `/home/user/cloudflare-workers/group-tools/schema.sql` - Komplettes DB-Schema
- `/home/user/cloudflare-workers/group-tools/src/index.js` - Worker-Code
- `/home/user/flutter_app/lib/services/group_tools_service.dart` - Flutter Service

---

**🎉 BACKEND IST LIVE UND FUNKTIONSFÄHIG!**

**Teste die API**: https://weltenbibliothek-group-tools.brandy13062.workers.dev/
