# 🌍 WELTENBIBLIOTHEK – GenSpark Claw AI Instruktionsdatei

> **Diese Datei ist die primäre Referenz für den GenSpark Claw AI-Assistenten.**
> Lies sie vollständig, bevor du irgendwelche Änderungen vornimmst.

---

# PROJEKTKONTEXT: Weltenbibliothek App

## Überblick
Du baust und wartest eine Flutter-App namens "Weltenbibliothek".
Die App wird NICHT über den Google Play Store verteilt, sondern als APK direkt an User weitergegeben (Sideloading).
Over-the-Air Updates laufen über Shorebird Code Push.

## Tech Stack
- **Framework:** Flutter (Dart)
- **Backend/Datenbank:** Supabase (PostgreSQL, Auth, Storage, Realtime)
- **OTA Updates:** Shorebird Code Push
- **CI/CD:** GitHub Actions (Repository: manuelbrandner85/Weltenbibliothekapp)
- **Verteilung:** Direkte APK-Weitergabe (kein Play Store)

---

## KRITISCHE REGELN FÜR SHOREBIRD & BUILD-NUMMERN

### Build-Nummer NIEMALS unnötig ändern!
- Die Build-Nummer in `pubspec.yaml` (z.B. `version: 1.0.0+1`) darf NUR geändert werden,
  wenn NATIVE Änderungen vorliegen (neues Plugin, Android-Permissions, Kotlin/Java-Code,
  Flutter-Version-Upgrade).
- Bei reinen Dart-Code-Änderungen (UI, Logik, Bugfixes, Features) bleibt die
  Build-Nummer IMMER gleich.
- Grund: Unsere User behalten ihre APK. Shorebird-Patches funktionieren nur gegen die
  exakte Release-Version. Neue Build-Nummer = User muss neue APK manuell installieren.

### Patch vs. Release Entscheidung
- **`shorebird patch`** → Standard für ALLE reinen Dart-Änderungen.
  User kriegt Update automatisch beim nächsten App-Start.
- **`shorebird release`** → NUR wenn native Änderungen unvermeidbar sind.
  Erfordert neue APK-Verteilung an alle User.

### Wenn du eine Änderung vorschlägst oder umsetzt:
1. Prüfe IMMER ob die Änderung rein Dart ist oder native Teile betrifft.
2. Wenn rein Dart → KEINE Änderung an `version:` in pubspec.yaml.
3. Wenn nativ nötig → WARNE MICH EXPLIZIT bevor du die Build-Nummer änderst,
   mit der Begründung warum ein neuer Release nötig ist.
4. Schlage immer den Weg vor, der KEINEN neuen Release erfordert, wenn möglich.

---

## SHOREBIRD WORKFLOW (GitHub Actions)

### Patch-Workflow (`shorebird_patch.yml`)
- Wird getriggert wenn Dart-Code sich ändert
- Führt `shorebird patch android --release-version <aktuelle-version>` aus
- Die `--release-version` muss IMMER mit der Version übereinstimmen,
  die die User aktuell auf ihren Geräten haben
- NIEMALS eine neue Release-Version im Patch-Workflow verwenden

### Release-Workflow (nur wenn nötig)
- Nur manuell triggern nach expliziter Absprache mit mir
- Erstellt neue APK mit `shorebird release android`
- Danach müssen BEIDE Versionen gepatcht werden (alte + neue),
  bis alle User die neue APK haben

---

## SUPABASE INTEGRATION

### Sicherheitsregeln
- API-Keys, Secrets, Passwörter NIEMALS hardcoden
- Alle sensiblen Werte gehören in Environment-Variablen oder `.env` Dateien
- `.env` Dateien MÜSSEN in `.gitignore` stehen
- Supabase `service_role` Key NIEMALS im Client-Code verwenden,
  nur `anon` Key + Row Level Security (RLS)

### Verbindung
- Supabase URL und anon Key werden über Dart Defines oder .env geladen
- Beispiel: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

---

## APP-INTERNES UPDATE-SYSTEM

### Shorebird Auto-Update
- `shorebird_code_push` Package ist integriert
- In `shorebird.yaml`: auto_update bleibt auf `true` (Standard)
- Patches werden automatisch im Hintergrund geladen und beim nächsten Start aktiviert

### Versions-Check für neue APK (wenn neuer Release nötig war)
- In Supabase existiert eine Tabelle `app_config` mit Feld `min_version`
- Beim App-Start wird geprüft ob die aktuelle App-Version >= min_version ist
- Falls nicht → User bekommt Dialog mit Download-Link für neue APK
- Download-Link wird ebenfalls aus `app_config` gelesen

---

## CODE-QUALITÄT & STIL

### Allgemein
- Sauberer, gut kommentierter Dart-Code
- Deutsche Kommentare für Geschäftslogik, Englisch für technische Kommentare
- Fehlerbehandlung mit try/catch und User-freundlichen Fehlermeldungen (Deutsch)
- Responsive Design für verschiedene Bildschirmgrößen

### Architektur
- Feature-basierte Ordnerstruktur
- State Management: [Riverpod/Bloc/Provider – was im Projekt bereits verwendet wird]
- Repository Pattern für Supabase-Zugriffe
- Separation of Concerns: UI ↔ Business Logic ↔ Data Layer

### Vor jedem Commit prüfen:
1. `flutter analyze` → keine Warnings
2. `dart format .` → Code formatiert
3. Keine hardcodierten Strings für User-facing Text
4. Keine sensiblen Daten im Code

---

## WORKFLOW BEI ÄNDERUNGEN

### Bevor du Code änderst:
1. Erkläre mir kurz was du ändern willst und warum
2. Sage mir ob es ein Patch oder Release wird
3. Warte auf mein OK bei größeren Änderungen

### Nach der Änderung:
1. Fasse zusammen was geändert wurde
2. Bestätige: "Patch-kompatibel ✓" oder "Neuer Release nötig ⚠️"
3. Wenn Patch: Sage mir den Befehl zum Auslösen des Patch-Workflows
4. Wenn Release: Erkläre mir die Schritte für die neue APK-Verteilung

---

## ZUSAMMENFASSUNG DER PRIORITÄTEN
1. **Build-Nummer stabil halten** → User soll nie neue APK brauchen wenn vermeidbar
2. **Sicherheit** → Keine Secrets im Code, RLS aktiv, .env geschützt
3. **OTA-first Denken** → Jede Lösung bevorzugt Patch über Release
4. **User-Erlebnis** → Updates unsichtbar, App läuft flüssig, deutsche UI

---

## 📌 Projektüberblick

**Weltenbibliothek** ist eine Flutter-App (Android/iOS/Web) – eine alternative Wissens- und
Bewusstseins-Plattform mit zwei Welten:

| Welt | Farbe | Themen |
|------|-------|--------|
| **Materie** | Rot `#E53935` | Geopolitik, Geschichte, UFOs, Verschwörungen, Forschung, Heilmethoden |
| **Energie** | Lila/Blau `#7C4DFF` | Spiritualität, Meditation, Kristalle, Chakren, Astrologie, Bewusstsein |

**Version**: 5.11.0+  
**Flutter**: 3.x, Dart 3.9.2  
**Repository**: https://github.com/manuelbrandner85/Weltenbibliothekapp  
**Entwickler-Branch**: `genspark_ai_developer`  

---

## 🏗️ Architektur (PFLICHT zu verstehen!)

```
Flutter App (Client)
       │
       ├── SUPABASE (PostgreSQL + Realtime)
       │     ├── Auth / Sessions / Tokens
       │     ├── profiles Tabelle (User-Daten, Rollen)
       │     ├── chat_messages (Echtzeit via Realtime)
       │     ├── chat_rooms, community_posts, notifications
       │     ├── tool_* Tabellen (7 Stück, siehe Migrationen)
       │     └── RLS auf ALLEN Tabellen (PFLICHT)
       │
       └── CLOUDFLARE WORKER (Edge API)
             ├── URL: https://weltenbibliothek-api.brandy13062.workers.dev
             ├── Chat API: GET/POST /api/chat/messages
             ├── Chat Edit: PUT /api/chat/messages/:id
             ├── Chat Delete: DELETE /api/chat/messages/:id
             ├── Voice/WebRTC: /voice/join, /voice/leave, /voice/signaling
             ├── AI/Recherche: /recherche, /ai/*
             ├── Admin: /admin/ban, /admin/kick, /admin/audit
             ├── Tools: /api/tools/:toolName (GET + POST)
             └── R2 Media: Bilder/Audio Upload
```

### Klare Zuständigkeiten (NICHT mischen!)

| Was | Wo |
|-----|----|
| Auth, Login, Sessions | **Nur Supabase** |
| User-Profile, Rollen | **Nur Supabase** |
| Chat-Text (Persistenz + Realtime) | **Supabase** (Realtime-Kanal) |
| AI / Recherche / Scraping | **Nur Cloudflare Worker** |
| Voice/WebRTC Koordination | **Nur Cloudflare Worker** |
| Große Medien / Audio | **Cloudflare R2** |
| Rate-Limiting, Moderation-Log | **Cloudflare Worker** |

---

## 🔑 Credentials & Secrets (SICHERHEITSREGELN)

### Was darf wo stehen?

| Secret | Client (Flutter) | Worker [vars] | Worker Secret |
|--------|-----------------|---------------|---------------|
| `SUPABASE_URL` | ✅ (dart-define) | ✅ | — |
| `SUPABASE_ANON_KEY` | ✅ (dart-define, public by design) | ✅ | — |
| `SUPABASE_SERVICE_ROLE_KEY` | ❌ VERBOTEN | ❌ | ✅ |
| `CLOUDFLARE_API_TOKEN` | ❌ VERBOTEN | ❌ | ✅ |

### Aktuelle Werte (öffentlich, da Anon-Key)

```
SUPABASE_URL      = https://adtviduaftdquvfjpojb.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdHZpZHVhZnRkcXV2Zmpwb2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzY3OTcsImV4cCI6MjA5MDcxMjc5N30.LPtmnjukb6o2CA16RDjoStqYb_1bipNULD4tgOfuD98
CLOUDFLARE_WORKER_URL = https://weltenbibliothek-api.brandy13062.workers.dev
CLOUDFLARE_ACCOUNT_ID = 3472f5994537c3a30c5caeaff4de21fb
```

### Flutter Build-Befehl (Produktion)

```bash
flutter build apk --release \
  --dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek-api.brandy13062.workers.dev \
  --dart-define=SUPABASE_URL=https://adtviduaftdquvfjpojb.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdHZpZHVhZnRkcXV2Zmpwb2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzY3OTcsImV4cCI6MjA5MDcxMjc5N30.LPtmnjukb6o2CA16RDjoStqYb_1bipNULD4tgOfuD98
```

---

## 📁 Projektstruktur

```
Weltenbibliothekapp/
├── lib/
│   ├── main.dart                        # App-Einstiegspunkt
│   ├── config/
│   │   ├── api_config.dart              # ⭐ ALLE API-URLs hier – NIEMALS hardcoden!
│   │   ├── feature_flags.dart           # Feature Toggles
│   │   └── enhanced_app_themes.dart     # Themes für Materie/Energie
│   ├── models/                          # Dart-Modelle (profile, chat, feed, etc.)
│   ├── services/
│   │   ├── supabase_service.dart        # ⭐ Auth, Profile, Chat (Supabase)
│   │   ├── cloudflare_api_service.dart  # ⭐ Edge API, AI, Recherche (Cloudflare)
│   │   ├── hybrid_chat_service.dart     # Chat-Koordination (Supabase RT + Cloudflare)
│   │   ├── webrtc_voice_service.dart    # Voice/WebRTC
│   │   ├── offline_sync_service.dart    # Offline-Warteschlange
│   │   ├── storage_service.dart         # Hive lokaler Speicher
│   │   ├── profile_sync_service.dart    # Profil-Backend-Sync
│   │   └── ...
│   ├── screens/
│   │   ├── energie/
│   │   │   ├── energie_live_chat_screen.dart  # ⭐ Energie-Chat (Hauptscreen)
│   │   │   ├── energie_community_tab.dart     # Community-Feed Energie
│   │   │   └── ...
│   │   ├── materie/
│   │   │   ├── materie_live_chat_screen.dart  # ⭐ Materie-Chat (Hauptscreen)
│   │   │   ├── materie_community_tab.dart     # Community-Feed Materie
│   │   │   └── ...
│   │   └── shared/                      # Shared Screens (Profil, Voice, etc.)
│   └── widgets/                         # Wiederverwendbare UI-Komponenten
├── workers/
│   ├── api-worker.js                    # ⭐ Cloudflare Worker (Edge API)
│   └── wrangler.toml                    # Worker-Konfiguration
├── supabase/
│   ├── schema.sql                       # Produktions-Schema
│   └── migrations/                      # Alle SQL-Migrationen
│       ├── 20260402_v10_full_schema.sql
│       ├── 20260402_v11_chat_livestream_fix.sql
│       └── 20260402_v12_missing_tool_tables.sql  # ⚠️ Noch nicht in DB!
└── CLAUDE.md                            # Diese Datei
```

---

## 🗄️ Supabase-Schema (Produktiv)

### Vorhandene Tabellen (bereits in DB)

```sql
profiles          -- User-Daten (id, username, display_name, avatar_url, world, role)
chat_rooms        -- Räume (room_id, name, world, is_active)
chat_messages     -- Nachrichten (id, room_id, user_id, username, content, message, created_at)
community_posts   -- Posts (id, world, content, user_id, likes_count)
notifications     -- Push-Notifications
```

### Fehlende Tabellen (⚠️ NOCH NICHT in DB – Migration ausstehend!)

Diese 7 Tabellen sind in `supabase/migrations/20260402_v12_missing_tool_tables.sql` definiert
und müssen noch über den Supabase SQL-Editor ausgeführt werden:

```
tool_meditation_sessions  ← energie/astral
tool_kristalle            ← energie/crystals
tool_geopolitics_events   ← materie/geopolitics
tool_history_events       ← materie/history
tool_healing_methods      ← materie/healing
tool_network_connections  ← materie/network
tool_research_documents   ← materie/research
```

**SQL ausführen unter**: https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new

---

## ⚙️ Cloudflare Worker (workers/api-worker.js)

### Aktive Endpunkte

| Method | Path | Funktion |
|--------|------|---------|
| GET | `/api/chat/messages?room=ID` | Nachrichten abrufen |
| POST | `/api/chat/messages` | Nachricht senden |
| PUT | `/api/chat/messages/:id` | Nachricht bearbeiten |
| DELETE | `/api/chat/messages/:id` | Nachricht löschen |
| GET/POST | `/api/tools/:toolName` | Tool-Daten (7 Tools) |
| GET | `/voice/rooms` | Voice-Räume |
| POST | `/voice/join` | Voice beitreten |
| POST | `/voice/leave` | Voice verlassen |
| WS | `/voice/signaling` | WebRTC Signaling |
| POST | `/api/push/register` | Push-Registrierung |
| POST | `/recherche` | AI-Recherche |

### Worker deployen

```bash
cd workers
npx wrangler deploy
# oder dry-run:
npx wrangler deploy --dry-run
```

### Secrets setzen

```bash
cd workers
echo "SERVICE_ROLE_KEY" | npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
```

---

## 🔄 Git-Workflow (PFLICHT)

### Branch-Strategie

```
main                   ← Produktions-Branch (stable)
genspark_ai_developer  ← Dein Arbeits-Branch (IMMER dieser!)
```

### Workflow nach JEDER Änderung

```bash
# 1. Änderungen committen
git add -A
git commit -m "type(scope): beschreibung"

# 2. Mit Remote synchronisieren
git fetch origin main
git rebase origin/main

# 3. Pushen
git push origin genspark_ai_developer

# 4. PR aktualisieren (PR #1 existiert bereits)
gh pr edit 1 --body "Neue Beschreibung..."
# oder neuen PR erstellen wenn #1 gemerged:
gh pr create --base main --head genspark_ai_developer --title "..." --body "..."
```

### Commit-Konventionen

```
feat(chat): neue Funktion
fix(materie): Fehler behoben
refactor(worker): Code-Umstrukturierung
style(energie): UI-Änderung
chore(deps): Dependencies aktualisiert
```

---

## ✅ Aktueller Status & Offene Aufgaben

### ✅ Erledigt (April 2026)

- [x] Chat POST-Endpoint `/api/chat/messages` vollständig implementiert
- [x] Supabase Realtime-Chat in beiden Welten (Energie + Materie)
- [x] Avatar-Picker in beiden Chat-Screens
- [x] Thread-Reply, Pinned Messages, Message-Reactions
- [x] WebRTC Voice-Integration (Cloudflare Durable Objects)
- [x] `_showAvatarPicker` Scope-Bug behoben (war in `/* */` Block)
- [x] `offline_sync_service.dart` – editChatMessage/deleteChatMessage Parameter korrigiert
- [x] 113 unused openclaw_dashboard imports entfernt
- [x] 0 Flutter-Analyzer Errors, 0 Warnings
- [x] `SUPABASE_SERVICE_ROLE_KEY` als Cloudflare Secret gesetzt
- [x] Tool-Table-Mappings im Worker (alle 7 Tools)
- [x] SQL-Migrations für 7 fehlende Tool-Tabellen erstellt

### ⚠️ Noch ausstehend / bekannte Probleme

1. **SQL-Migration ausführen**: `supabase/migrations/20260402_v12_missing_tool_tables.sql`
   → Im Supabase SQL-Editor ausführen (7 Tool-Tabellen fehlen noch in der DB)

2. **544 info-level Issues** (keine Errors/Warnings):
   - `use_build_context_synchronously` in mehreren Screens
   - `unused_field` Warnungen (nicht kritisch)
   - `deprecated_member_use` (Radio-Widgets, alte APIs)

3. **Voice/WebRTC** noch nicht vollständig getestet auf Produktion

4. **Push-Notifications** (Cloudflare-basiert, nicht Firebase) – Registrierung funktioniert,
   Delivery-Test aussteht

5. **Profile Avatar Upload** – Supabase Storage-Integration teilweise, braucht Produktionstest

6. **Community Likes/Favorites** – implementiert, aber Like-State aus Datenbank laden
   (derzeit immer `false` als Initialwert)

7. **APK Build** – Kein Android SDK in Sandbox verfügbar, Build lokal oder via CI/CD nötig

---

## 🛠️ Häufige Aufgaben

### Flutter Analyse ausführen

```bash
export PATH="$PATH:/home/user/flutter/bin"
flutter analyze
# Nur Errors:
flutter analyze 2>&1 | grep "^  error"
```

### Worker lokal testen (dry-run)

```bash
cd workers
wrangler deploy --dry-run
```

### Supabase-Tabellen prüfen

```bash
# Über Cloudflare Worker (benötigt SERVICE_ROLE_KEY):
curl https://weltenbibliothek-api.brandy13062.workers.dev/health
```

### Neuen Screen hinzufügen

1. Datei in `lib/screens/energie/` oder `lib/screens/materie/` anlegen
2. Import in `lib/main.dart` hinzufügen (falls als Route nötig)
3. Route in `portal_home_screen.dart` oder World-Screen registrieren
4. `flutter analyze` ausführen – 0 Errors sicherstellen
5. Commit & Push

---

## 🎨 UI/Design-Regeln

### Farben

```dart
// Materie (Rot)
Color materieColor = Color(0xFFE53935);
Color materieDark  = Color(0xFF1A0000);

// Energie (Lila)
Color energieColor = Color(0xFF7C4DFF);
Color energieDark  = Color(0xFF0D0D1A);

// Gemeinsam
Color cardBg    = Color(0xFF1A1A2E);
Color textLight = Colors.white;
Color textMuted = Colors.grey;
```

### Widget-Struktur

- **Chat-Screens**: `_buildMessageBubble()`, `_buildMessageInput()`, `_buildRoomSelector()`
- **Community-Tabs**: `_buildFeedCard()`, `_buildFavoritesSection()`
- **Realtime**: `_subscribeToRoom()` → Supabase RealtimeChannel

---

## 🚨 Bekannte Fallstricke (WICHTIG!)

### 1. Kommentarblöcke mit `/* */`
Dart-Analyzer-Fehler können entstehen wenn Code **innerhalb** eines `/* */` Blocks liegt,
der eigentlich **außerhalb** sein soll. Immer prüfen ob Methoden-Definitionen wirklich
outside von `/* */` Blöcken stehen!

### 2. `_MaterieLiveChatScreenState` hat zwei Instanzen im alten Code
Die Klasse beginnt bei Zeile 70. Es gibt einen auskommentierten `/* */` Block
(ehemals Zeilen 1403-1594), der alten Code enthält. Dieser darf KEINE aktiven
Methoden enthalten.

### 3. `editChatMessage()` und `deleteChatMessage()` in CloudflareApiService
Beide Methoden haben **required** Parameter: `roomId`, `username`, `newMessage`/`messageId`.
Immer alle übergeben! (war ein Bug in offline_sync_service.dart)

### 4. `openclaw_dashboard_service.dart`
Dieser Service ist in **keiner** Datei mehr nötig. Falls er wieder importiert wird → sofort entfernen!

### 5. HybridChatService vs. SupabaseChatService
- `HybridChatService`: Kapselt Cloudflare API + Supabase als Fallback
- `SupabaseChatService`: Direkt Supabase Realtime (für schnelle Aktualisierungen)
- Beide Chat-Screens nutzen BEIDE Services parallel

### 6. User-ID Format
Supabase `user_id` ist immer UUID. Alte Code-Pfade können `user_XXXX` strings haben.
Im Worker wird das abgefangen:
```js
const isUUID = /^[0-9a-f]{8}-...-[0-9a-f]{12}$/i.test(rawUserId);
const user_id = isUUID ? rawUserId : null;
```

---

## 📱 App-Screens Übersicht

### Portal (Startseite)
- `portal_home_screen.dart` – Weltauswahl (Materie / Energie)

### Materie-Welt (`lib/screens/materie/`)
- `materie_live_chat_screen.dart` – ⭐ Haupt-Chat (Räume: politik, geschichte, ufos, etc.)
- `materie_community_tab.dart` – Community-Feed
- `materie_karte_tab.dart` – Karte
- `geopolitik_map_screen.dart`, `history_timeline_screen.dart` – Tools
- `ufo_sightings_screen.dart`, `conspiracy_network_screen.dart` – Tools
- `research_archive_screen.dart`, `alternative_healing_screen.dart` – Tools

### Energie-Welt (`lib/screens/energie/`)
- `energie_live_chat_screen.dart` – ⭐ Haupt-Chat (Räume: meditation, astralreisen, etc.)
- `energie_community_tab.dart` – Community-Feed
- `energie_karte_tab.dart` – Karte
- `crystal_library_screen.dart`, `chakra_scan_screen.dart` – Tools
- `meditation_timer_screen.dart`, `dream_journal_screen.dart` – Tools

### Shared
- `profile_settings_screen.dart` – Profil-Einstellungen
- `modern_voice_chat_screen.dart` – Voice-Chat UI
- `world_admin_dashboard.dart` – Admin-Panel

---

## 🔧 Services-Übersicht

| Service | Zweck |
|---------|-------|
| `supabase_service.dart` | Auth, Profile, Chat, Community (Supabase) |
| `cloudflare_api_service.dart` | Edge API, AI, Recherche, Voice (Cloudflare) |
| `hybrid_chat_service.dart` | Chat-Koordination (Cloudflare Primary, Supabase Fallback) |
| `webrtc_voice_service.dart` | WebRTC Voice-Rooms |
| `offline_sync_service.dart` | Offline-Queue für Nachrichten |
| `storage_service.dart` | Hive lokaler Speicher (Profile, Favoriten) |
| `profile_sync_service.dart` | Profile mit Backend synchronisieren |
| `avatar_upload_service.dart` | Avatar-Upload zu Supabase Storage |
| `favorites_service.dart` | Lokale Favoriten (Hive) |
| `group_tools_service.dart` | Tool-Daten (nutzt 7 Tool-Tabellen) |

---

## 🏃 Schnellstart für neue Session

```bash
# 1. In Projektverzeichnis wechseln
cd /home/user/webapp/Weltenbibliothekapp

# 2. Auf AI-Developer-Branch sicherstellen
git checkout genspark_ai_developer

# 3. Letzten Stand holen
git pull origin genspark_ai_developer

# 4. Flutter-Analyse (0 Errors = OK)
export PATH="$PATH:/home/user/flutter/bin"
flutter analyze 2>&1 | grep "^  error" | head -20

# 5. Änderungen vornehmen...

# 6. Committen & pushen
git add -A && git commit -m "fix/feat: beschreibung"
git fetch origin main && git rebase origin/main
git push origin genspark_ai_developer

# 7. PR aktualisieren
gh pr list --head genspark_ai_developer
gh pr edit <NR> --body "Neue Beschreibung"
```

---

*Letzte Aktualisierung: 2026-04-02 – GenSpark Claw Instruktionsdatei v1.0*

## APK-Build + OTA (Shorebird)

> **PATCH-FIRST REGEL (verbindlich):**
> Die App wird **nicht** über den Play Store verteilt, sondern als APK direkt an User (Sideloading).
> User behalten ihre installierte APK. Shorebird-Patches funktionieren nur gegen die **exakte
> Release-Version**, die auf dem Gerät liegt. Daher:
> 1. **`version:` in `pubspec.yaml` NIEMALS bei reinen Dart-Änderungen bumpen.**
>    Neue Build-Nummer = User muss neue APK manuell installieren → zu vermeiden.
> 2. **Standard-Deployment für alle Dart-/UI-/Logik-/Bugfix-Änderungen = OTA-Patch.**
> 3. Neuen Release NUR nach expliziter Absprache und nur bei unvermeidbaren
>    nativen Änderungen (neues Plugin, Android-Permissions, Kotlin/Java, Flutter-Upgrade).
> 4. Bei Commit-Zusammenfassung immer angeben: **"Patch-kompatibel ✓"** oder **"Neuer Release nötig ⚠️"**.

- Builds laufen via GitHub Actions über **Shorebird** (Code Push / OTA)
- `shorebird.yaml` enthält `app_id` (public, in VCS); Secret nur in GitHub Actions (`SHOREBIRD_TOKEN`)
- **OTA-Patch (Standard — reine Dart-Änderungen):**
  - Workflow: `.github/workflows/shorebird_patch.yml`
  - Trigger: Nur manuell (workflow_dispatch); `release_version: latest` per Default
  - Läuft `shorebird patch android` → sendet Dart-AOT-Diff an Shorebird, User bekommt Update beim nächsten App-Start automatisch
  - Einschränkung: KEINE neuen Dart-Dependencies, KEINE nativen Änderungen (dann neuer Release nötig)
- **Neuer Release (nur bei nativen Änderungen, nach Absprache):**
  - Workflow: `.github/workflows/build_apk.yml`
  - Trigger: Nur manuell (`workflow_dispatch`) — Push-Trigger ist abgeschaltet, damit Dart-only Commits keinen fehlschlagenden Release-Build auslösen
  - Läuft `shorebird release android --artifact=apk` → registriert Release auf Shorebird-Server + erstellt GitHub Release mit APK
- Download (volle APK): GitHub Releases → neueste Version
