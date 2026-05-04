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
- **Vollautomatisch**: Feuert bei JEDEM Push auf `main`. Kein manuelles Triggern nötig.
- Zusätzlich manuell triggerbar via `workflow_dispatch` (Eingabe `source_branch`).
- **Patcht IMMER nur die neueste Release-Version** (`--release-version=latest`).
  Ein einziger `shorebird patch android`-Aufruf, keine Schleife, kein Resolver.
- Schreibt Patch-Changelog automatisch in `app_config.patch_changelog` (Supabase)
- Legt Eintrag in `update_history` (type=patch) an
- NIEMALS neue Dart-Dependencies oder native Änderungen patchen → dann neuer Release nötig

### ⚠️ STRATEGIE: Patches nur an `latest`, ältere APKs via ReleaseUpdateScreen (verbindlich)

Seit v5.37+ gilt das **"latest-only"-Modell**:

1. **Shorebird OTA-Patches gehen ausschließlich an die neueste Release-Version.**
   `shorebird_patch.yml` nutzt `--release-version=latest` — kein Multi-Version-Loop,
   kein Parsing von `shorebird releases list`, kein `gh release list`-Fallback.
2. **User auf älteren APKs werden über den in-App `ReleaseUpdateScreen` zum
   APK-Download geleitet** — gesteuert über `app_config.min_version` in Supabase.
   Bei jedem neuen Release setzt `build_apk.yml` `min_version` auf die vorher
   installierte Version, sodass ältere User spätestens beim nächsten App-Start den
   Fullscreen-Update-Gate sehen und die neue APK in der App downloaden können.
   - **≥ v5.35.0**: `ReleaseUpdateScreen` ist in der App enthalten (seit Commit
     `d912e58`, v5.35.0-Release) → User sieht den Fullscreen-Dialog mit
     In-App-Download-Button und installiert die neue APK direkt in der App
     (PackageInstaller). Keystore ist ab v5.34.0 persistent → saubere Upgrades
     ohne Deinstallation.
   - **< v5.34.0**: alter Debug-Keystore → Signatur-Mismatch. In-App-Install
     schlägt nach 2 Versuchen fehl, Notausgang-Anleitung (Deinstall + Neuinstall)
     greift. Für diese User bleibt nur der manuelle Einmal-Wechsel.
3. **Build-Nummer MUSS strikt aufsteigend sein** (`pubspec.yaml`: `5.X.Y+<buildNumber>`).
   Android lehnt Installs mit gleichem oder niedrigerem `versionCode` ab.
   `build_apk.yml` enthält einen Pre-Check der `pubspec.yaml`-Build-Nummer gegen den
   letzten Release-Tag vergleicht und fehlschlägt wenn die Nummer nicht steigt.

Warum das funktioniert:
- Seit v5.34.0 teilen alle APKs denselben persistenten Release-Keystore → APK-Updates
  laufen ohne Deinstallation (kein Signatur-Mismatch mehr, siehe Regel 3 unten).
- Der `ReleaseUpdateScreen` kann die neue APK direkt via `PackageInstaller` ausrollen —
  für den User gleicher Aufwand wie ein OTA-Patch, nur ein Tap mehr.
- Keine Fragilität mehr durch Shorebird-CLI-Versions-Drift, Release-ID-Formate
  (`<semver>+<buildNumber>`) oder Engine-Snapshot-Kompatibilität bei alten Releases.

Warum das alte Multi-Version-Patching verworfen wurde (kurz):
- `shorebird releases list` existiert in CLI 1.6.92 nicht (nur `get-apks`-Subcommand)
- Shorebird erwartet Release-IDs als `<semver>+<buildNumber>`, GitHub-Tags sind nur `vX.Y.Z`
- Engine-Drift bei alten Releases lässt Patches silent auf dem Gerät verworfen werden
- Mehrere fehlgeschlagene Runs zeigten: der Debug-Aufwand rechtfertigt nicht den Nutzen,
  wenn der `ReleaseUpdateScreen` dasselbe Ziel zuverlässig erreicht

### Release-Workflow (nur wenn nötig)
- Nur manuell triggern nach expliziter Absprache mit mir
- Erstellt neue APK mit `shorebird release android`
- Patch geht danach automatisch an die NEUE Release-Version (latest)
- User auf der alten APK kriegen über `min_version`-Bump den `ReleaseUpdateScreen` und
  laden die neue APK in der App herunter — kein paralleles Patchen der alten Version nötig

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

## APP-INTERNES UPDATE-SYSTEM (vollautomatisch ab v5.36.0)

### Shorebird Auto-Update (OTA-Patches)
- `shorebird_code_push` Package ist integriert
- In `shorebird.yaml`: auto_update bleibt auf `true` (Standard)
- Patches werden automatisch im Hintergrund geladen und beim nächsten Start aktiviert
- **Patch-Benachrichtigung: prominenter Fullscreen-Dialog** (`PatchReadyDialog`)
  ersetzt die alte kleine SnackBar. User sieht: "Update bereit! Bitte App schließen
  und neu starten." mit großem "App jetzt schließen"-Button + "Später"-Option.
- Stream-basiert: `UpdateService.onPatchReady` feuert ein Event sobald ein Patch
  heruntergeladen ist — UpdateGate hört zu und zeigt sofort den Dialog.
- Debug-Build-Schutz: Bei `APP_VERSION='0.0.0'` (lokaler Debug-Build ohne
  `--dart-define`) wird der Release-Check komplett übersprungen.

### Versions-Check für neue APK (vollautomatisch)
- In Supabase existiert eine Tabelle `app_config` mit Feldern `latest_version`,
  `min_version`, `apk_download_url`, `changelog`, `release_notes_url`
- Beim App-Start wird geprüft ob die aktuelle App-Version >= min_version ist
- Falls nicht → User sieht Fullscreen `ReleaseUpdateScreen` mit In-App-Download
- Tabelle wird per **UPSERT** aus CI aktualisiert (nicht mehr PATCH):
  HTTP POST mit Header `Prefer: resolution=merge-duplicates,return=representation`.
  Das erstellt die Zeile automatisch falls sie fehlt (frische DB / erster Release).
- `min_version` und `changelog` werden **automatisch aus Git generiert** —
  `supabase/release/current.json` ist deprecated und wird nicht mehr gelesen.
  - `min_version` = letzter GitHub-Release-Tag (per `gh release list`)
  - `changelog` = `git log <letzter-Tag>..HEAD`, chore/ci/Merge gefiltert

### Signatur-Mismatch-Schutz (ReleaseUpdateScreen)
- Wenn Installation nach >= 2 Versuchen fehlschlägt (wahrscheinlich Signatur-Mismatch
  mit alter Debug-Key-APK): `PopScope canPop:true` + "App trotzdem weiter nutzen"-Button
  + klare "Deinstallieren & Neuinstallieren"-Anleitung. Verhindert Endlosschleife.

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
3. Wenn Patch: Patch läuft **vollautomatisch** sobald der Commit auf `main` landet (lib/**-Änderung)
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
│   │   ├── livekit_call_service.dart    # 🎥 LiveKit Video-Gruppencall (ersetzt WebRTC)
│   │   ├── offline_sync_service.dart    # Offline-Warteschlange
│   │   ├── storage_service.dart         # SQLite lokaler Speicher (via SqliteStorageService)
│   │   ├── sqlite_storage_service.dart  # ⭐ SQLite KV-Store + in-memory cache (Hive-Ersatz)
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
│   │   ├── shared/                      # Shared Screens (Profil, Voice, etc.)
│   │   └── release_update_screen.dart   # ⭐ Fullscreen-Update-Gate (In-App-APK-Download)
│   └── widgets/                         # Wiederverwendbare UI-Komponenten
│       ├── update_gate.dart             # ⭐ Update-Koordinator (Stream-basiert, Stack-Overlay)
│       ├── patch_ready_dialog.dart      # ⭐ Prominenter OTA-Patch-Dialog + Changelog (v5.36.0+)
│       ├── patch_download_indicator.dart # Dezenter Download-Fortschritts-Banner
│       ├── update_success_banner.dart   # Grüner Erfolgs-Banner nach Patch/Version-Update
│       └── update_dialogs.dart          # Legacy ReleaseUpdateDialog (PatchReadyBanner entfernt)
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
- [x] **Vollautomatisches Update-System (Release + Patch)** — v5.36.0+
- [x] `supabase/release/current.json` eliminiert — min_version + changelog automatisch aus Git
- [x] Prominenter Patch-Ready-Dialog (`PatchReadyDialog`) statt SnackBar-Banner
- [x] Stream-basierte Patch-Benachrichtigung (`UpdateService.onPatchReady`)
- [x] Signatur-Mismatch-Schutz im ReleaseUpdateScreen (Notausgang nach 2 fehlgeschlagenen Installs)
- [x] APP_VERSION 0.0.0 Debug-Schutz (keine Force-Updates in lokalen Debug-Builds)
- [x] Supabase `app_config` UPSERT statt PATCH (erstellt Zeile auch bei frischer DB)
- [x] **UPSERT-409-Fix**: `?on_conflict=platform` in sync_app_config.yml + build_apk.yml
      (PostgREST UPSERT auf UNIQUE-Spalte statt PK)
- [x] **Phase 1a (V4) Offline-Schutz**: connectivity_plus-Check vor Supabase/Shorebird-Calls;
      5s Timeout auf Supabase `maybeSingle()`
- [x] **Phase 1b (V1) Patch-Changelog**: `app_config.patch_changelog` Spalte; CI schreibt
      git-generierten Changelog; `PatchReadyDialog` zeigt "Was ist neu"-Box via FutureBuilder
- [x] **Phase 1c (V2) Patch-Download-Indikator**: `PatchDownloadStatus`-Stream in UpdateService;
      `PatchDownloadIndicator`-Overlay in UpdateGate (dezenter Banner mit LinearProgress)
- [x] **Phase 1d (V3) Update-Bestätigung**: `UpdateConfirmationService` vergleicht
      SharedPreferences mit aktueller Version/Patch; grüner `UpdateSuccessBanner` nach Neustart
- [x] **Phase 1e (V5) Resumable APK-Download**: HEAD-Request für Content-Length; Range-Header
      + FileMode.append für Resume; deleteOnError:false für Teildatei-Erhalt
- [x] **Phase 1f (V7) Update-History**: `update_history` Tabelle in Supabase; CI-INSERTs in
      build_apk.yml (type=release) + shorebird_patch.yml (type=patch);
      `UpdateHistoryScreen` im Profil unter "Update-Verlauf"-Button
- [x] SQL-Migrationen: `20260420_v37_patch_changelog.sql` + `20260420_v38_update_history.sql`
      → `apply_migrations.yml` CI-Workflow (SUPABASE_ACCESS_TOKEN) führt sie bei jedem
      Push auf main automatisch aus (idempotent, kein manueller SQL-Editor nötig)
- [x] **Phase 2 (V6) Auto-Restart via MethodChannel**: `MainActivity.kt` — MethodChannel
      `weltenbibliothek/restart`; AlarmManager schedulet Relaunch in 500 ms, dann
      `System.exit(0)` nach 50 ms. `RestartService.dart` — Dart-Seite mit Fallback
      (MissingPluginException → SystemNavigator.pop). `PatchReadyDialog` Button-Label
      "App neu starten". Version 5.37.0 (nativer Release nötig).
- [x] **Phase 3 – APK-Dateigröße + bessere Fehlermeldungen**: `ApkDownloadService.getApkFileSize()`
      public; `ReleaseUpdateScreen` zeigt "~102 MB" am Download-Button via FutureBuilder;
      `_friendlyError()` parst DioException-Typen → nutzerfreundliche deutsche Fehlertexte.
- [x] **Phase 4 – Auto-Retry-Countdown nach 404**: Bei 404-Fehler startet 60s Timer.periodic
      im `ReleaseUpdateScreen`; zeigt CircularProgressIndicator-Countdown; Ablauf triggert
      automatischen Retry; "Sofort"-Button unterbricht Countdown.
- [x] **Phase 5 – Patch-Nummer in Profil**: `UpdateService.getCurrentPatchNumber()`;
      `_VersionInfoCard` in `profile_settings_screen.dart` zeigt aktuelle App-Version
      und installierten Shorebird-Patch (z.B. "v5.37.0 · Patch #4").
- [x] **Phase 6 – Update-History Screen verbessert**: Pull-to-Refresh via `RefreshIndicator`;
      animierte Skeleton-Cards (`_SkeletonCard` + `SingleTickerProviderStateMixin`, 900ms Puls);
      Leer-Zustand mit Icon + erklärendem Text; Fehler-Zustand mit cloud_off + Retry-Button.
- [x] **apply_migrations.yml**: Eigenständiger CI-Workflow; läuft bei JEDEM Push auf main
      (kein paths-Filter); nutzt Supabase Management REST API mit `SUPABASE_ACCESS_TOKEN`;
      wendet v37 + v38 Migrationen idempotent an.
      HTTP-Erfolgs-Check akzeptiert 200, 201 und 204 (Supabase gibt je nach Query 201 zurück).
- [x] **Race-Condition-Fix (sync_app_config)**: GitHub Release Existence Check vor UPSERT;
      `sync_app_config.yml` überspringt UPSERT wenn APK-Release noch nicht existiert.
- [x] **Auto-Patch bei JEDEM main-Push**: `shorebird_patch.yml` feuert bei JEDEM Push auf `main`
      (kein paths-Filter). Kein manuelles Triggern nötig. Doppelte Patches sind harmlos.
- [x] **Hive→sqflite Migration (vollständig)**: Hive komplett entfernt. Alle lokalen Daten
      laufen über `SqliteStorageService` (single `kv_store` table + in-memory cache für sync reads).
      Betrifft: `storage_service.dart`, `spirit_journal_service.dart`, `synchronicity_service.dart`,
      `daily_spirit_practice_service.dart`, `unified_knowledge_service.dart`,
      `unified_storage_service.dart` (×2), `supabase_service.dart`, `admin_state.dart`,
      `materie_live_chat_screen.dart`. Alle 6 Model-Dateien (@HiveType/@HiveField entfernt),
      alle 5 `.g.dart`-Dateien gelöscht. pubspec.yaml: hive/hive_flutter/hive_generator entfernt.
- [x] **Paket A+B+C (Chat-Bugs + Realtime-Stream + In-App Push-Stack, PR #28)**:
      15 Chat-Bug-Fixes (_fullRoomId in offline queue, user-revalidation gegen Account-
      Wechsel, Scroll addPostFrameCallback). `CommunityService.streamPosts()` via
      Supabase Realtime. `PushNotificationManager` mit Auto-Register auf
      `onAuthStateChange`, 30s-Polling, flutter_local_notifications, Deep-Link via
      `appNavigatorKey`. Worker `/api/push/subscribe` + `/pending` + `/dispatch`.
      Supabase-Trigger `trg_enqueue_chat_notification` (v39).
- [x] **FCM Background Push-Delivery (PR #28)**: `firebase_core` + `firebase_messaging`
      in pubspec. Gradle: `google-services` Plugin wird nur angewandt wenn
      `android/app/google-services.json` existiert (CI injiziert aus
      `GOOGLE_SERVICES_JSON_BASE64` Secret). `PushNotificationManager` holt FCM-Token,
      registriert ihn, handled onMessage/onMessageOpenedApp/onBackgroundMessage.
      Worker: FCM HTTP v1 Sender mit RS256-JWT-Signing via Web Crypto, Cron-Trigger
      `* * * * *` drained `notification_queue` einmal pro Minute. Neuer
      `deploy_worker.yml` Workflow setzt `FCM_SERVICE_ACCOUNT` + `SUPABASE_SERVICE_ROLE_KEY`
      als Worker-Secrets und deployt automatisch bei jeder `workers/**` Änderung.
      Migration v40 entfernt den doppelten v13-Trigger. Fail-safe: ohne Firebase-Config
      fällt die App auf In-App-Polling zurück — kein Crash.
- [x] **Komplett-Audit-Bundles 1+2A+3+4+5+6 (2026-04-27)**:
  - **Bundle 1 — 10 Crash-Fixes** (PR #46): try-catch um Supabase-likes/bookmarks,
    mounted-Checks in Live-Chat-Screens, OfflineSync-User-Validation-Race,
    ArticleLikeButton Memory-Cache-Initial-State, CommunityInteractionService.isLiked()
    liefert echten Cache-Wert (statt immer false), SqliteStorageService refresh-API,
    OfflineSyncService dispose robust, community_service Future.wait eagerError:false,
    PushNotificationManager fcmBackgroundHandler echtes Logging.
  - **Bundle 2A — Design-Tokens** (PR #47): `lib/config/wb_design.dart` zentrales
    Token-System im Home-Tab-Stil — bgEnergie/bgMaterie/bgNeutral, surfaces, akzent-
    paletten pro Welt, Text-Hierarchie, Spacings, Radien, Hero/Action-Tile-Gradients,
    pre-composed Decorations (`card`, `statBanner`, `heroBanner`).
  - **Bundle 3 — 6 Sync-Fixes** (PR #48): updateProfile/getComments try-catch,
    Slug-Generation thread-safe (microsecondsSinceEpoch%1000000), getMessages
    `.reversed.toList()` → `order(ascending:true)`, getLikeCount 5s→10s Timeout,
    Worker `encodeURIComponent(userId)` an 4 Stellen.
  - **Bundle 4 — 3 UX-Items** (PR #49): hardcoded "MANUEL" → echter Username aus
    Supabase user_metadata, AvatarUploadException + uploadAvatarOrThrow für
    nutzerlesbare Fehler, ConnectivityHelper für schnellen Online-Check.
  - **Bundle 6 — Push-Notification-Settings** (PR #50): `PushPreferencesService`
    mit 8 Toggles + Master-Switch in SharedPreferences, `PushPreferencesScreen`
    im Home-Tab-Stil, PushNotificationManager filtert eingehende Notifs nach
    Type-Pref vor Anzeige (In-App-Center bleibt unberührt).
- [x] **PR #44 + #45 — Patch-Stack-Verbesserungen** (2026-04-27):
  - patch_changelog parst Squash-Merge-Body (vorher nur Commit-Title)
  - PushNotificationManager Subscribe-Retry mit exp.Backoff, periodischer
    Health-Check via /api/push/debug, Heal-on-Resume, forceResubscribe() API.
- [x] **LiveKit-Migration Phase 1-5 abgeschlossen** (v5.39.0+, 2026-04-29):
  - **PR #55 (Phase 1/2)**: flutter_webrtc entfernt, livekit_client+flutter_background,
    Worker `/api/livekit/token`, `LiveKitCallService` + `livekit_call_provider.dart`,
    `api_config.dart` LiveKit-URLs, `docs/LIVEKIT_SERVER_SETUP.md` (12-Phasen-Guide)
  - **PR #56 (Phase 4/5)**: `lib/screens/shared/livekit_group_call_screen.dart` —
    Vollbild-UI im Welt-Stil (TopBar, _ControlBar 6 Buttons, _StatusView,
    Avatar-Hero im Welt-Gradient, PopScope). Voice-Buttons in beiden Chat-Screens
    öffnen direkt den LiveKitGroupCallScreen.
  - **GitHub Release v5.39.0** wurde automatisch gebaut und veröffentlicht ✓
- [x] **PR #63 — Benutzerfreundlicher Changelog im Update-Dialog** (2026-05-02):
  - Commit-Typ (feat/fix/style/perf) → passendes Icon + Farbe
  - Technische Präfixe automatisch entfernt, Beschreibungen groß geschrieben
  - Scrollbar bei vielen Einträgen, Lade-Skeleton, leerer Zustand sauber ausgeblendet
  - Token-Generierung auf **Supabase Edge Function** migriert (`livekit-token`) —
    HMAC-SHA256-JWT, 4h TTL, Supabase Auth-Validierung. Deployed und ACTIVE auf Supabase.
    LiveKit-Secrets (API-Key/Secret/URL) automatisch via CI gesetzt.
- [x] **PR #64 — LiveKit Komplett-Rebuild + community_posts-Fix** (2026-05-02, Patch ✓):
  - **`livekit_group_call_screen.dart` vollständig neu geschrieben** (1154 Zeilen):
    `_AnimatedBackground` (3 rotierende Glow-Orbe via dart:math),
    `_ParticipantGrid` (responsiv: 1=Solo, 2=nebeneinander, 3-6=2col, 7+=3col),
    `_ParticipantTile` (Pulse-Animation bei Mic aktiv, Glow-Ring, Mic-Status-Badge),
    `_TopBar` (BackdropFilter.blur, Teilnehmer-Badge, Timer in grün/tabular-digits),
    `_ControlBar` (BackdropFilter.blur, 5 deutsche Buttons: Mikrofon/Kamera/Bildschirm/Hand/Auflegen),
    `_CtrlBtn` (AnimatedContainer mit Glow-BoxShadow für active/danger States),
    `_StatusView` (Connecting-Spinner, Error-Retry, Disconnect-Retry),
    Bestätigungsdialog mit BackdropFilter-Hintergrund
  - Stabilitäts-Fixes: Room-Events korrekt, Speakerphone nach Connect, Teilnehmer-Counter,
    Listener-Cleanup in leaveRoom()/dispose()
  - **v42 Migration `community_posts`** — Tabelle fehlte komplett in DB.
    Angelegt mit 15 Spalten, 3 Indexes, updated_at-Trigger, 4 RLS-Policies,
    Realtime-Publication, anon/authenticated Grants. apply_migrations.yml aktualisiert.

- [x] **Chat+LiveKit Tief-Audit (2026-05-03, 7 Bundles, Patch ✓)**:
  - **Bundle 1 — Worker Auth**: `verifyAuth()` Supabase-JWT-Middleware im Worker,
    Chat-Endpunkte (GET/POST/PUT/DELETE) verlangen `X-Supabase-Auth` Header,
    `_authedHeaders` in `CloudflareApiService`
  - **Bundle 2 — Supabase Realtime**: `SupabaseChatService._channels: Map<String, RealtimeChannel>`
    statt Singleton; `subscribeToRoom/Full()` Map-basiert; DELETE-Filter prüft `room_id`;
    `sendMessage()` speichert `media_url`+`avatar_emoji`; Pagination mit `beforeId`
  - **Bundle 3 — LiveKit Token-Refresh**: `_scheduleTokenRefresh()`, `_refreshToken()`,
    `_jwtExpEpoch()` — Token wird 5min vor Ablauf automatisch erneuert (kein
    "Authentifizierung erforderlich" mehr nach 4h)
  - **Bundle 4 — Memory/Dispose-Fixes**: `ValueNotifier<int>` für Duration,
    `ValueNotifier<Set<String>>` für Speakers; `_cancelTokenRefresh()` in leaveRoom/dispose;
    `_cameraIndex = 0` Reset; `LocalTrackUnpublishedEvent` für ScreenShare-Stop
  - **Bundle 5 — Gray-Box-Fix + UI**: `sendMessage()` übergibt `mediaUrl`+`avatarEmoji`
    korrekt; Bubble-Conditions prüfen camelCase+snake_case; Button-Labels deutsch;
    Grid `childAspectRatio: 0.85`; Tile-Fallbacks 'Du'/'Mitglied'
  - **Bundle 6 — Auto-Refresh/Pagination**: Auto-Refresh-Timer entfernt;
    `count=exact` für CountOption; Pagination Tie-Break via `beforeId`;
    `getMessages` → `order(ascending:true)` statt `.reversed`
  - **Bundle 7 — Defensive API**: `setRemoteVolume()` versucht `subscribed` setter,
    Fallback dynamic; `setAttributes` mit Spread; Track-Toggle ohne `dispose()`
  - **Bundle P — Push Quick-Wins**: FCM Background-Filter nach PushPrefs,
    `_seenIds` Ringbuffer (200), Logout → `unsubscribeCurrent()`, Queue-Cleanup >7 Tage
  - **LiveKit empty_timeout: 1s** — Raum schließt sofort wenn letzter User geht
  - **Profil Cloud-Sync entfernt** aus `profile_settings_screen.dart`
  - **CI Fixes**: Soft-Skip für `LIVEKIT_API_SECRET` in 3 Workflows;
    `wrangler secret bulk` (jq-basiert) statt sequentieller `secret put` Calls
    (Wrangler 3.x Versions-Drift-Bug vermieden)

- [x] **PR #71 — LiveKit Join-Fix + Release-APK + Chat-Ownership + Community Pill-Switcher** (2026-05-03, Patch ✓):
  - **LiveKit `node_ip: 72.62.154.95`** in `livekit.yaml` — ohne explizite externe IP advertised LiveKit interne Docker-IPs als ICE-Kandidaten → Media-Streams konnten nicht aufgebaut werden. Fix: `rtc.node_ip` + `use_external_ip: true` in `infra/livekit-wb/livekit.yaml`.
  - **Token-Endpoint → Cloudflare Worker** (`/api/livekit/token`) — war Supabase Edge Function, die möglicherweise fehlende Secrets hatte. Worker ist immer aktiv + hat LIVEKIT_API_KEY/SECRET als Wrangler-Secrets. `api_config.dart: livekitTokenUrl` umgestellt.
  - **`deploy_livekit_wb.yml`**: Caddyfile-Pfad via `docker inspect` + python3-JSON-Parsing (statt Pfad-Raten); `caddy validate` vor `reload`; Re-Deploy-Trigger-Kommentar in README erzwingt Container-Neustart.
  - **`build-apk.yml`**: `--debug` → `--release` mit Keystore-Signing aus `ANDROID_KEYSTORE_*` Secrets. Gilt dauerhaft — IMMER Release-APK, nie Debug.
  - **Chat edit/delete Ownership-Fix**: `cloudflare_api_service.dart editChatMessage/deleteChatMessage` sendeten `username`/`userId` nicht im Body → Worker-Ownership-Check (`existingMsg.username !== username`) wurde silent übersprungen. Behoben.
  - **Community Pill-Switcher**: Glassmorphischer AnimatedAlign-Switcher (260ms easeOutCubic) ersetzt 2px-TabBar-Indikator in `community_tab_modern.dart` (Materie, Blau) + `energie_community_tab_modern.dart` (Energie, Lila). Mit HapticFeedback + Unread-Badge + AnimatedSwitcher-Subtitle.

- [x] **PR #65 — WB eigene LiveKit-Instanz, getrennt von Mensaena** (2026-05-02, Patch ✓):
  - Umstellung von „shared LiveKit mit Mensaena" auf vollständig eigenständige
    WB-Instanz auf demselben Hostinger-VPS — eigene Subdomain, eigene Container,
    eigene Keys. Mensaena darf NICHT angefasst werden.
  - **Neue URL**: `wss://livekit-wb.srv1438024.hstgr.cloud:7892` (ersetzt
    `wss://livekit.srv1438024.hstgr.cloud` aus dem alten Shared-Setup)
  - **Infra (`infra/livekit-wb/`)**: livekit.yaml (nur WB-Key, Port 7980 intern,
    UDP 60001-65000 disjunkt von Mensaena, KEIN TURN), traefik.yml (Ports
    7891/7892, ACME raus, mounted-cert), dynamic.yml (Routing), docker-compose.yml
    (eigener Container `livekit-weltenbibliothek`, read-only Cert-Mount), README.md
    (Mensaena-Safety-Liste)
  - **Neuer Workflow `deploy_livekit_wb.yml`**: SSH-Deploy mit Pre/Post-Mensaena-
    Health-Check, Port-Konflikt-Check, Cert-Pfad-Lookup, fail-rot wenn Mensaena
    nicht mehr healthy ist
  - **`deploy_worker.yml` aufgeräumt**: Der gefährliche Step der Mensaena's
    livekit.yaml überschrieben hat ist KOMPLETT ENTFERNT. Mensaena bleibt jetzt
    vollständig unangetastet.
  - Trennung: `/docker/livekit-wb/` (WB) vs `/docker/livekit/` (Mensaena),
    Container-Name `livekit-weltenbibliothek`, eigenes Network `livekit-wb-net`,
    keine Port-Überschneidungen mit Mensaena (80/443 + 50000-60000 UDP + 7880/7881)

- [x] **PR #97 — B10.3 Picture-in-Picture (PiP)** (2026-05-04, nativer Release nötig):
  - PiP-Modus für Android via `LiveKitMiniBar`-Widget + `MainActivity.kt` `enterPictureInPictureMode()`

- [x] **PR #98 — ControlBar Redesign: Icon-Fix + 4-Button-Layout** (2026-05-04, Patch ✓):
  - Chinese-Character-Bug gefixt: kaputte `_rounded` Icon-Varianten ersetzt
  - ControlBar auf 4 Buttons: Mikrofon (PTT), Kamera, Mehr⋯, Auflegen

- [x] **PR #99 — B10.6 Raumstimmung + B10.8 Spatial Audio** (2026-05-04, Patch ✓):
  - 5 Themes (standard/netzwerk/kosmos/mandala/kristall), welt-gefiltert, via TopBar auswählbar
  - `AudioFeedbackService` mit `ValueNotifier<RoomTheme>` + synthetisierten WAV-Tönen
  - Spatial Audio visual-only (livekit_client 2.5.4 hat kein `setVolume()` im Flutter SDK)

- [x] **PR #100 — Recording + ControlBar 4-Button-Finale** (2026-05-04, Patch ✓):
  - **Recording**: `RecordingService` + Worker-Endpoints `/api/livekit/recording/start|stop`
    - Admin-JWT (roomAdmin), LiveKit Egress API (`StartRoomCompositeEgress`/`StopEgress`)
    - R2/S3-Output wenn `LIVEKIT_EGRESS_S3_*` Secrets gesetzt, sonst lokale Datei
    - Blinkender REC-Badge in TopBar, Aufnahme-Tile im Optionen-Sheet
    - ⚠️ Benötigt LiveKit Egress Runner Container auf dem VPS
  - **ControlBar finale Lösung** (4 Buttons, immer sichtbar):
    - Mikrofon | Kamera | Optionen | Auflegen
    - `_SmartMehrButton`: `Icons.tune_rounded`, zeigt Mini-Dots für aktive Features
      (Kamera=grün, Bildschirm=blau, Hand=gelb, Co-Watch=lila), Zahl-Badge für Chat
    - Alle Sekundär-Aktionen im Optionen-Sheet: Chat, Hand, Bildschirm, Reaktion,
      Co-Watch, Aufnahme, Kamera drehen, Raumstimmung, Spatial Audio

- [x] **PR #103 — v44 Migration idempotent (ALTER PUBLICATION)** (2026-05-04, Patch ✓):
  - `apply_migrations.yml` schlug mit HTTP 400 fehl: `voice_sessions` war bereits in `supabase_realtime`
  - Fix: `DO $$`-Block prüft `pg_publication_tables` vor `ALTER PUBLICATION ADD TABLE`

- [x] **PR #104 — Community-Posts schreiben/bearbeiten/löschen** (2026-05-04, Patch ✓):
  - `createPost/editPost/deletePost` riefen nicht-existente Cloudflare-Worker-Endpoints auf
  - Kein JWT, camelCase-Felder, fehlender `user_id` → silent fails
  - Fix: Alle Write-Ops direkt via Supabase Client (Auth+RLS automatisch)
  - `streamPosts()` war bereits korrekt (Supabase Realtime)

- [x] **PR #105 — TURN-Relay für Mobilfunk/CGNAT** (2026-05-04, Patch ✓):
  - Mobilfunk-User (CGNAT/symmetrisches NAT) konnten LiveKit nicht joinen
  - `livekit.yaml` hatte kein `rtc.ice_servers` → kein TURN im Join-Response
  - `coturn`-Container möglicherweise nie deployed (kein trigger seit Hinzufügung)
  - Fix Server: `rtc.ice_servers` mit coturn-Creds in `livekit.yaml`
    → triggert `deploy_livekit_wb.yml` → coturn deployed + Ports 3478/61001-62000 geöffnet
  - Fix Client: Cloudflare STUN als Fallback, Timeout 60s→90s

- [x] **PR #102 — Kaninchenbau-Tools + LiveStream ControlBar-Finale** (2026-05-04, Patch ✓):
  - **6 Materie-Tools komplett neu** mit echten kostenlosen APIs:
    - UFO Sichtungen: NASA Fireballs + OpenSky ADS-B (3 Tabs)
    - Geopolitik: GDELT + USGS Erdbeben + flutter_map CartoDB Dark
    - Geschichte: Wikidata SPARQL + Library of Congress; `timeline_tile` entfernt (Dart 3
      inkompatibel) → Inline-Widget mit `IntrinsicHeight+Row`
    - Verschwörungen: Wikidata SPARQL + graphview FruchtermanReingold
    - Forschungs-Archiv: CrossRef 165M+ DOIs + Unpaywall Open-Access PDFs
    - Gesundheit: OpenFDA FAERS + Retraction Watch + CMS Open Payments → `CriticalHealthScreen`
  - **LiveStream ControlBar finale UI**: `Chat | Mikrofon | Kamera | Auflegen` (4 Buttons)
    - Chat-Button mit rotem Unread-Badge (oben rechts)
    - TopBar `⋮ Mehr`-Sheet: alle sekundären Aktionen (scrollbar, `isScrollControlled:true`)
    - Entfernt: `_SmartMehrButton`, `_ActiveFeature`, `_showMoreActions`, `features_labelOffset`
  - `CrossRefWork` Modell-Klasse in `free_api_service.dart`
  - `lib/screens/materie/critical_health_screen.dart` (neu)

- [x] **PR #101 — B8-B12 + B10.6/8 + Recording + 4-Bug-Fixes** (2026-05-04, Patch ✓):
  - **4 Merge-Konflikt-Bereinigungen** in `livekit_group_call_screen.dart`:
    - Duplikate Imports entfernt (cowatch, incall, livekit, live_caption, etc.)
    - Orphan `child: SafeArea(` Fragment vor korrektem AnimatedBuilder-child entfernt
    - ViewMode-Label-Duplikat, Caption-Icon-Duplikat, Mic/Kamera-Label-Duplikate bereinigt
  - **Bug 1 — Chat schreiben/bearbeiten/löschen**: v44-Migration erstellt alle App-Räume
    idempotent (`ON CONFLICT DO NOTHING`) — behebt FK-Constraint-Fehler bei room_id;
    `apply_migrations.yml` läuft v44 automatisch bei jedem main-Push
  - **Bug 2 — Profilbild-Upload**: Worker `/api/avatar/upload` unterstützt jetzt JSON+base64
    (Flutter-Client sendet `{user_id, image_data: base64}`, Worker dekodiert via `atob()`);
    speichert URL direkt in `profiles.avatar_url` via PATCH
  - **Bug 3 — Push wenn jemand live geht**: `voice_sessions` Tabelle in Supabase (v44 Migration);
    Supabase-Trigger `trg_voice_session_joined` schreibt in `notification_queue`;
    `VoiceSessionService` (neu) meldet join/leave via Worker `/api/voice/session/join|leave`;
    `livekit_call_service.dart` ruft join/leave automatisch auf
  - **Bug 4 — Live-Banner wie Telegram**: `live_room_banner.dart` (neues Widget);
    Supabase Realtime-Abo auf `voice_sessions` für die aktive Welt;
    Blinkender roter Punkt, Teilnehmer-Namen, "Beitreten"-Button;
    In Materie- und Energie-Chat-Screen eingebunden direkt unter `ChatStatusBanner`
  - **Worker**: `/api/voice/sessions?world=X` (GET aktive Sessions),
    `/api/voice/session/join` (POST), `/api/voice/session/leave` (POST)

### ⚠️ Noch ausstehend / bekannte Probleme

1. **SQL-Migrationen**: `apply_migrations.yml` läuft automatisch bei jedem main-Push.
   - `supabase/migrations/20260402_v12_missing_tool_tables.sql` (7 Tool-Tabellen) — noch manuell via SQL-Editor nötig, da nicht in apply_migrations.yml enthalten
   - v37-v44 werden automatisch per CI angewendet (v44 = Chat-Räume + voice_sessions)

2. **info-level Issues** (keine Errors/Warnings):
   - `use_build_context_synchronously` in mehreren Screens
   - `unused_field` Warnungen (nicht kritisch)
   - `deprecated_member_use` (Radio-Widgets, alte APIs)

3. **🎥 LiveKit vollständig implementiert** (v5.39.0+, PR #55+56+64+71+97+98+99+100+101+102+105):
   - flutter_webrtc entfernt, livekit_client + flutter_background als Dependencies
   - **Token-Endpoint: Cloudflare Worker** `/api/livekit/token` (HMAC-SHA256-JWT, 4h TTL)
   - `LiveKitCallService` — join/leave, Track-Toggles, Token-Refresh, VoiceSession-Tracking
   - `livekit_group_call_screen.dart` — animierter Hintergrund (5 Themes via B10.6),
     responsives Grid, **ControlBar: `Chat | Mikrofon | Kamera | Auflegen`** (4 Buttons)
   - Chat-Button mit Unread-Badge, TopBar `⋮ Mehr`-Sheet für alle sekundären Aktionen
   - Optionen-Sheet (via TopBar): Hand, Bildschirm, Reaktion, Co-Watch, Aufnahme, Ansicht, Untertitel, Raumstimmung, Spatial Audio
   - Recording: `RecordingService` + Worker `/api/livekit/recording/start|stop` (Egress API)
   - Live-Banner: `live_room_banner.dart` via Supabase Realtime `voice_sessions`
   - LiveKit-Server: `livekit-weltenbibliothek` auf Hostinger VPS, eigene Instanz
   - **Noch ausstehend: B10.7 3D-Avatar** (braucht Assets + evtl. neues Package)
   - **Recording-Voraussetzung**: LiveKit Egress Runner Container auf VPS nötig

4. **Push-Notifications wenn jemand live geht**: Supabase-Trigger `trg_voice_session_joined`
   schreibt in `notification_queue` — wird via FCM/In-App zugestellt (v44 Migration)

5. **Profile Avatar Upload**: Worker `/api/avatar/upload` fixed — unterstützt JSON+base64.
   Supabase Storage-Bucket `avatars` muss existieren (public, keine RLS auf GET).

6. **Community Likes/Favorites** – Like-State wird aus `CommunityInteractionService`
   Cache geladen (nicht mehr immer false); echter DB-Load bei erstem Aufruf via isLiked()

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
**Status (Bundle-5-Audit, 2026-04-27):** noch in `screens/{materie,energie}/home_tab_v5.dart`
für `getRecentArticles()` und `getTrendingTopics()` in Verwendung. Komplett-Entfernung
ist eingeplant aber nicht-trivial (Stats-Migration zu direktem Supabase ist in
Bundle 1 bereits erfolgt). Bis zur Vollmigration: Service akzeptiert, aber bei
neuen Features lieber direkt Supabase / CloudflareApiService nutzen.

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
| `livekit_call_service.dart` | 🎥 LiveKit Video-Gruppencall (ersetzt WebRTC seit v5.39.0) |
| `offline_sync_service.dart` | Offline-Queue für Nachrichten |
| `storage_service.dart` | SQLite lokaler Speicher (Profile, Favoriten) — via SqliteStorageService |
| `sqlite_storage_service.dart` | SQLite KV-Store + in-memory cache — Hive-Ersatz (box/key/value) |
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
  - **Trigger: VOLLAUTOMATISCH** bei JEDEM Push auf `main` (kein paths-Filter).
    Doppelte Patches (gleicher Code) sind harmlos — Shorebird ignoriert sie auf dem Gerät.
    Zusätzlich manuell via `workflow_dispatch` triggerbar (Eingabe: release_version, source_branch).
  - Läuft `shorebird patch android --allow-asset-diffs --release-version latest` →
    sendet Dart-AOT-Diff an Shorebird, User bekommt Update beim nächsten App-Start automatisch.
  - Schreibt `patch_changelog` in Supabase `app_config` + Eintrag in `update_history`.
  - Einschränkung: KEINE neuen Dart-Dependencies, KEINE nativen Änderungen (dann neuer Release nötig)

### ⚠️ Shorebird OTA-Patch Konfiguration — NICHT ÄNDERN (verbindlich)

> Diese Konfiguration ist das Ergebnis eines stundenlangen Debuggings nach "Patch uploaded,
> aber auf Gerät nicht aktiv"-Problem. Jede Abweichung davon hat den Patch silent kaputt
> gemacht. Bevor du auch nur EIN Flag hinzufügst/entfernst: lies diesen Abschnitt.
>
> Letzter funktionierender Patch: Run #15 auf Commit `fe09bad` (Shorebird CLI 1.6.92,
> Flutter 3.41.6 rev `76ca3dff01`). Aktuell funktionierender Patch: v5.34.0 auf dem Gerät
> zeigte `cur=2 nxt=2 chk=upToDate` nach Fix.

**PFLICHT-Einstellungen in `.github/workflows/shorebird_patch.yml`:**

1. **Shorebird CLI pinnen auf exakt die Version, mit der der Release gebaut wurde:**
   ```yaml
   - uses: shorebirdtech/setup-shorebird@v1
     with:
       shorebird-version: 1.6.92
   ```
   Ohne Pin driftet `setup-shorebird@v1` auf die neueste CLI und damit auf einen anderen
   Flutter-Engine-Snapshot. Patch wird dann zwar uploaded, aber vom Client auf dem Gerät
   still verworfen, weil die Engine-Bytes nicht zum registrierten Release passen.
   → Wenn ein neuer Release mit neuerer Shorebird-CLI gebaut wird, MUSS dieser Pin
   mitgezogen werden.

2. **Nur `--allow-asset-diffs`, niemals `--allow-native-diffs`:**
   ```bash
   shorebird patch android --allow-asset-diffs --release-version="latest" -- \
     --target-platform=android-arm64,android-arm \
     --dart-define=APP_VERSION=... \
     --dart-define=SUPABASE_URL=... \
     --dart-define=SUPABASE_ANON_KEY=... \
     --dart-define=CLOUDFLARE_WORKER_URL=...
   ```
   - `--allow-asset-diffs` ist nötig weil MaterialIcons.otf bei jedem Build neu
     tree-geshaked wird sobald neue Icons im Dart-Code stehen.
   - `--allow-native-diffs` **maskiert** Engine-Drift (CLI-Mismatch) statt ihn zu fixen:
     Shorebird nimmt den Patch an, Gerät lehnt ihn später still ab. NIEMALS setzen.

3. **`--release-version="latest"` direkt an Shorebird geben, keinen eigenen Resolver bauen.**
   Shorebird löst "latest" korrekt gegen die jüngste registrierte Release-Version auf.
   Custom-Resolver (parsen von `shorebird releases list`) hat in der Vergangenheit auf
   nicht-existente Versionen gezeigt.

4. **Kein `pubspec.yaml` mit der Release-Version synchronisieren.**
   Die App-Version im Patch-Build ist unerheblich — Shorebird matcht am Engine-Snapshot-Hash,
   nicht am `version:` Feld.

5. **Kein `--verbose | tee`.** Verschluckt manchmal Exit-Codes und hat in der Vergangenheit
   grüne Runs produziert, die in Wahrheit gefailt sind.

6. **Concurrency-Gruppe mit `cancel-in-progress: true`:** Shorebird nimmt den zuletzt
   hochgeladenen Patch als aktiv — ältere laufende Jobs würden neuere überschreiben wenn
   sie später fertig werden.
   ```yaml
   concurrency:
     group: shorebird-patch-${{ github.ref }}
     cancel-in-progress: true
   ```

7. **`SUPABASE_ANON_KEY` ist ein echter JWT mit Payload
   `{"iss":"supabase","ref":"adtviduaftdquvfjpojb","role":"anon",...}`.**
   Nicht kürzen, nicht "verkürzen", nicht durch Platzhalter ersetzen — sonst bootet die App
   nicht mehr gegen Supabase.

**Debug-Banner (`lib/widgets/ota_debug_banner.dart`):**
Falls je wieder ein Patch "silent fail" verhält, temporär wieder in `update_gate.dart`
einsetzen — zeigt `v=<APP_VERSION> sb=<ON|OFF> cur=<N> nxt=<N> chk=<status>` oben rechts
und macht sichtbar ob Shorebird den Patch installiert hat. Nach erfolgreichem Test WIEDER
ENTFERNEN (user-facing Diagnose-Overlay).
- **Neuer Release (nur bei nativen Änderungen, nach Absprache):**
  - Workflow: `.github/workflows/build_apk.yml`
  - Trigger: Nur manuell (`workflow_dispatch`) — Push-Trigger ist abgeschaltet, damit Dart-only Commits keinen fehlschlagenden Release-Build auslösen
  - Läuft `shorebird release android --artifact=apk` → registriert Release auf Shorebird-Server + erstellt GitHub Release mit APK
- Download (volle APK): GitHub Releases → neueste Version

---

## 🔐 Signing-Keystore & APK-Update-Kompatibilität (verbindlich)

> **PROBLEM, das diese Regel verhindert:**
> Wenn der Release-Build mit dem Android-**Debug-Key** signiert wird, erzeugt jeder
> CI-Runner einen neuen Key → zwei APKs mit gleicher applicationId, aber verschiedenen
> Signaturen. Android blockiert das Update dann mit **"App nicht installiert"**.
> Der einzige "Ausweg" wäre Deinstallation — aber dadurch verliert der User alle lokalen
> Daten UND die App, aus der er hätte updaten sollen.

### Regel 1 — Release-Builds IMMER mit persistentem Keystore signieren

- Der Keystore `android/app/weltenbibliothek.jks` liegt **NIEMALS im Repo** (`.gitignore`).
- CI holt ihn aus GitHub-Secrets (base64-dekodiert in `build_apk.yml`).
- `android/app/build.gradle.kts` lädt `key.properties` und nutzt den Release-Signing-Config.
  Fällt der Keystore (lokal) weg, bleibt der Build debug-signiert — das darf nur auf
  Entwickler-Maschinen passieren, **nie in CI**.
- Nötige GitHub-Secrets (einmalig einzurichten):
  - `ANDROID_KEYSTORE_BASE64` — base64-Encode des `.jks`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS` (z.B. `weltenbibliothek`)
  - `ANDROID_KEY_PASSWORD`
- Keystore erzeugen: `./scripts/generate_release_keystore.sh`
  → gibt die 4 Secrets am Ende für Copy&Paste aus.

### Regel 2 — Keystore darf NIE verloren gehen

- Ohne den Original-Keystore kannst du nie wieder Over-the-Top-Updates über eine installierte
  APK ausrollen. Alle User müssten die App deinstallieren, bevor sie die neue Version
  installieren.
- Backup-Pflicht: Keystore + Passwörter in Passwort-Manager **und** Offline-Kopie.

### Regel 3 — Bei Signing-Key-Mismatch (Legacy-APK im Feld)

Wenn eine bereits verteilte APK mit dem falschen Key signiert ist (z.B. alte Debug-Builds),
und die neue APK ist mit dem persistenten Release-Key signiert → User auf der alten Version
**können nicht per APK-Update migrieren**. Workaround:

1. Alte User per **Shorebird-OTA-Patch** auf dem alten Release halten und neue Dart-Fixes so
   ausliefern (kein APK-Install, kein Signing-Problem).
2. `app_config` in Supabase auf `latest_version = <installierte alte Version>` setzen, damit
   kein "App nicht installiert"-Loop durch den Update-Dialog entsteht.
3. Neue APK-Releases laufen ab sofort sauber, weil ab jetzt alle mit dem gleichen Release-Key
   signiert sind → zukünftige User können problemlos upgraden.
4. Alte User, die wirklich auf die neue APK müssen, bekommen eine Anleitung: Deinstallieren
   → Neuinstall der neuen APK (Datenverlust akzeptiert, Einmal-Wechsel).

### Regel 4 — Release-Flow (100% vollautomatisch ab v5.36.0)

Der Release-Flow ist vollständig automatisiert. Der Entwickler macht NUR EINE Sache:

1. **`pubspec.yaml` Version bumpen** (z.B. `5.35.0+20260420` → `5.36.0+20260421`).

Alles andere generiert der CI selbst:
- `min_version` kommt aus dem **letzten GitHub-Release** (`gh release list --limit 1`).
- `changelog` kommt aus **Git-Commits seit dem letzten Tag** (`git log <tag>..HEAD`),
  chore/ci/Merge-Commits werden gefiltert.
- `supabase/release/current.json` ist **deprecated** und wird nicht mehr gelesen.

Der Version-Bump wird per normalem PR auf `main` gemerged. **Kein Tag-Push nötig** — der
Workflow erstellt den Tag `vX.Y.Z` selbst via `softprops/action-gh-release@v2`, sobald er
merkt dass für die aktuelle `pubspec.yaml`-Version noch kein Release existiert.

**Trigger-Wege** (alle drei funktionieren):
- **Merge auf `main` mit pubspec.yaml-Bump** (Standard): Pre-Check-Job vergleicht Version
  mit bestehenden GitHub-Releases, baut automatisch wenn noch keiner existiert. Kein
  manueller Tag-Push erforderlich.
- **Manuell getaggter Commit**: `git tag -a vX.Y.Z && git push origin vX.Y.Z` —
  funktioniert weiterhin, falls ein spezifischer Commit released werden soll.
- **workflow_dispatch**: Actions-UI → "Build & Release APK" → Run workflow (auch auf
  Feature-Branches nutzbar).

**STANDING RULE: CLAUDE.md IMMER AKTUALISIEREN** (ab v5.36.0, verbindlich):

Nach JEDER erfolgreichen Code-Änderung MUSS CLAUDE.md aktualisiert werden.
Das umfasst:
- Neue/geänderte Features in "Erledigt" eintragen
- Geänderte Architektur/Flows dokumentieren
- Neue Dateien in der Projektstruktur ergänzen
- Bekannte Fallstricke aktualisieren
- Veraltete Informationen entfernen/korrigieren

CLAUDE.md ist die EINZIGE Wahrheitsquelle für KI-Assistenten.
Wenn CLAUDE.md nicht aktuell ist, machen zukünftige Sessions Fehler.
Diese Regel gilt für JEDE Änderung — nicht nur für große Refactorings.

---

**Auto-Merge durch Claude** — STANDING RULE (ab v5.35.0, verbindlich):
ICH MERGE JEDEN EIGENEN PR SELBST auf `main`, sobald CI grün ist. Kein Nachfragen beim
Entwickler, kein Warten auf manuelle Freigabe. Ablauf jedes Mal identisch:

1. Änderung committen + pushen.
2. Draft-PR erstellen (oder vorhandenen nutzen).
3. Via `update_pull_request(draft:false)` ready-for-review setzen.
4. Auf CI warten (`pull_request_read(method:get_check_runs)` bis alle Checks completed).
5. Konflikte mit `main` auflösen (merge main in Branch, push).
6. Via `merge_pull_request(merge_method:"squash")` mergen.

Dann feuert der Auto-Trigger in `build_apk.yml` den Release (wenn pubspec.yaml gebumpt).

Regeln für Auto-Merge:
- IMMER auto-mergen, sobald CI grün — nicht nur Release-PRs, sondern jeder von mir
  gepushte PR (Features, Fixes, Docs, CI-Changes).
- Nur wenn alle required CI-Checks auf `success` / `neutral` stehen (nicht `in_progress`
  oder `failure`).
- Niemals force-mergen wenn CI rot ist — dann Ursache fixen, pushen, warten, dann mergen.
- Draft-PRs werden vorher via `update_pull_request(draft:false)` ready-for-review gesetzt.
- Merge-Konflikte mit main werden automatisch aufgelöst (merge main in Branch, HEAD bevorzugen
  wenn HEAD-Version eindeutig neuer ist — z.B. bei `.github/workflows/**`).

Danach läuft `.github/workflows/build_apk.yml` vollautomatisch:

1. Pre-Check ermittelt automatisch `prev_version` (= letzter Release-Tag) und
   `changelog` (= `git log <tag>..HEAD`, gefiltert).
2. Keystore aus Secrets dekodieren (`ANDROID_KEYSTORE_*`) → persistent-signierte APK.
3. `shorebird release android --artifact=apk` → registriert Release auf Shorebird-Server.
4. APK in GitHub Release veröffentlichen unter fixem URL-Schema
   `.../releases/download/vX.Y.Z/weltenbibliothek-vX.Y.Z-universal.apk`.
5. Release-Notes kommen aus dem **automatisch generierten Changelog**.
6. **`public.app_config` in Supabase wird per PostgREST-UPSERT gesetzt** (POST mit
   `Prefer: resolution=merge-duplicates`, nutzt `SUPABASE_SERVICE_ROLE_KEY`, umgeht RLS).
   Erstellt die Zeile automatisch falls sie fehlt. Felder:
   - `platform` = `"android"` (UPSERT-Key via UNIQUE constraint)
   - `latest_version` = Tag-Version (ohne `v`)
   - `min_version` = letzter veröffentlichter Tag
   - `changelog` = aus Git generiert
   - `apk_download_url`, `release_notes_url` aus Tag abgeleitet
7. User auf älterer Version sehen beim nächsten App-Start den `ReleaseUpdateScreen` und
   können direkt in der App herunterladen + installieren (Android `PackageInstaller`).
   Bei wiederholter Installation-Failure (Signatur-Mismatch): Notausgang nach 2 Versuchen.

**Erforderliche GitHub-Secrets (vollständige Liste — IMMER zuerst prüfen!):**
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD` (persistenter Keystore, siehe Regel 1)
- `SHOREBIRD_TOKEN` (Shorebird Code Push)
- `SUPABASE_SERVICE_ROLE_KEY` (PostgREST auf `app_config` + `update_history`, RLS-bypass)
- `SUPABASE_ACCESS_TOKEN` (Supabase Management REST API — für `apply_migrations.yml`)
- `GITHUB_TOKEN` (automatisch von GitHub Actions bereitgestellt, kein manuelles Einrichten)
- `GOOGLE_SERVICES_JSON_BASE64` (base64-Encode der google-services.json aus Firebase
  Console; wird von `build_apk.yml` und `shorebird_patch.yml` in `android/app/` dekodiert)
- `CLOUDFLARE_API_TOKEN` (Wrangler Deploy-Token — für `deploy_worker.yml`)
- `FCM_SERVICE_ACCOUNT_JSON` (Firebase Service-Account JSON als String — für
  Background-Push-Versand an FCM HTTP v1 API; optional)

**Firebase Cloud Messaging (FCM) Setup — einmalige manuelle Schritte:**

Damit Push-Benachrichtigungen auch bei **geschlossener App** zugestellt werden, müssen
folgende Schritte einmal ausgeführt werden (danach läuft alles automatisch):

1. **Firebase-Projekt erstellen** → https://console.firebase.google.com/
   - "Add project" → Name z.B. "Weltenbibliothek"
   - Analytics optional (nicht nötig für FCM)
2. **Android App hinzufügen** (innerhalb des Projekts):
   - Package name: `com.myapp.mobile` (siehe `android/app/build.gradle.kts`)
   - `google-services.json` herunterladen → **NICHT** ins Repo committen
3. **GitHub Secret `GOOGLE_SERVICES_JSON_BASE64`** setzen:
   ```bash
   base64 -w 0 google-services.json | pbcopy   # macOS
   base64 -w 0 google-services.json | xclip    # Linux
   ```
   Dann unter Settings → Secrets → Actions als `GOOGLE_SERVICES_JSON_BASE64` einfügen.
4. **Firebase Service-Account generieren** (für Worker-Dispatcher):
   - Firebase Console → Project Settings → Service Accounts
   - "Generate new private key" → JSON downloaden
   - **NICHT** ins Repo committen
5. **GitHub Secret `FCM_SERVICE_ACCOUNT_JSON`** setzen:
   - Inhalt der Service-Account-JSON (ohne Formatierung ändern) als Secret einfügen.
6. **Cloudflare Worker-Secret (automatisch via `deploy_worker.yml`)**: Sobald
   `CLOUDFLARE_API_TOKEN` + `FCM_SERVICE_ACCOUNT_JSON` als GitHub-Secrets vorhanden
   sind, setzt der Worker-Deploy-Job das Worker-Secret `FCM_SERVICE_ACCOUNT`
   automatisch bei jedem Push auf `main`.

Nach diesem Setup:
- Neue APK-Builds enthalten die google-services.json und können FCM-Tokens holen.
- Der Cron-Trigger `* * * * *` im Worker drained `notification_queue` jede Minute
  und sendet Pushes via FCM HTTP v1 API.
- Chat-Nachrichten lösen über den Supabase-Trigger `trg_enqueue_chat_notification`
  automatisch Push-Zeilen aus → Empfänger bekommt den Push auch bei geschlossener App.

Fallback bei fehlenden FCM-Secrets: Die App läuft weiter, aber Push-Delivery
funktioniert nur während die App offen ist (30s-Polling von `/api/push/pending`).

**KI-Standing-Rule — Secrets zuerst prüfen:**
Bevor ein neuer Workflow oder ein neuer API-Call gebaut wird, IMMER die obige Liste
durchgehen und sicherstellen dass das benötigte Secret vorhanden ist. Kein Workflow
darf scheitern weil ein Secret vergessen wurde. Bei fehlendem Secret: dem User sagen
welches Secret wo (Settings → Secrets → Actions) einzurichten ist — nicht einfach
`exit 0` als Workaround nutzen.

**Warum `app_config` dennoch automatisch safe ist:**
Seit v5.34.0 wird jede APK mit demselben persistenten Release-Keystore signiert
(siehe Regel 1). Damit ist die "Signing-Key-Mismatch"-Gefahr (siehe Regel 3), die früher
ein manuelles Gate erforderlich hat, systematisch ausgeschlossen. Der automatische
`app_config`-Update ist nur dann gefährlich, wenn ein Release den Keystore WECHSELT —
in diesem Fall muss der Workflow temporär deaktiviert werden und `app_config` bleibt auf
der alten Version, bis alle User migriert sind.

**Checkliste bei Keystore-Wechsel (Ausnahmefall):**

- [ ] Step `📢 Supabase app_config updaten` im `build_apk.yml` temporär auskommentieren
      bevor Tag gepusht wird.
- [ ] Neue APK via alternativer Distribution an Power-User geben, Feedback einholen.
- [ ] Erst wenn verifiziert: manuell per Supabase-SQL-Editor `app_config` updaten.
- [ ] Step wieder aktivieren.

**Im Zweifelsfall (Dart-only Änderung):** Statt Release besser `shorebird patch` nehmen —
kein APK-Reinstall nötig, keine `app_config`-Änderung, User kriegen Patch beim nächsten
App-Start automatisch.

### Regel 5 — app_config-Sync ist eigener Workflow (Fallback zu Step 11)

Der eingebettete Step 11 in `build_apk.yml` („📢 Supabase app_config updaten") hatte
in der Vergangenheit silent Failures (z.B. weil `SUPABASE_SERVICE_ROLE_KEY` fehlte,
aber der APK-Build davor bereits erfolgreich war → GitHub-Release da, app_config aber
noch auf alter Version → In-App-Update-Dialog bleibt aus).

Deshalb gibt es zusätzlich **`.github/workflows/sync_app_config.yml`**:

- Eigenständiger, schneller Job (keine Flutter-Toolchain nötig, <1 min).
- Trigger automatisch auf jedem `main`-Push der `pubspec.yaml` ODER
  `supabase/release/current.json` ändert.
- Läuft **parallel** zum großen Release-Build — wenn Step 11 failt, zieht dieser
  Workflow den `app_config`-State trotzdem nach.
- Idempotent: PATCH auf dieselbe Version ist no-op für User.
- Zusätzlich manuell via `workflow_dispatch` triggerbar (z.B. nach Secret-Fix).

**Claude-Standing-Rule für Releases (ab v5.36.0, verbindlich):**

Nach jedem Release führe ich den End-to-End-Check ohne Nachfragen durch:

1. GitHub-Release existiert (Tag `vX.Y.Z`, APK attached) — prüfen via
   `mcp__github__list_releases`.
2. `sync_app_config`-Workflow ist auf dem gleichen Commit grün gelaufen.
3. Supabase `app_config`-Row zeigt neue `latest_version` — prüfen via Supabase MCP
   `execute_sql` (read-only SELECT).

Fails einer der drei Schritte, fixe ich **automatisch ohne Rückfrage**:

- Release fehlt → Build-Workflow neu dispatchen.
- sync_app_config grün aber app_config alt → Workflow neu dispatchen (nicht
  SQL-Editor-Update empfehlen).
- Secret `SUPABASE_SERVICE_ROLE_KEY` fehlt → dem User die Einrichtung ansagen,
  andere Release-Teile laufen weiter.
