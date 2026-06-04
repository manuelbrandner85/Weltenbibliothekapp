# 🌍 Weltenbibliothek

Flutter-App (Android, APK-Sideloading) — Supabase + Cloudflare Worker + Shorebird OTA + LiveKit.
Repo: https://github.com/manuelbrandner85/Weltenbibliothekapp

## 🔗 Endpoints

- **Supabase:** `https://adtviduaftdquvfjpojb.supabase.co`
- **Cloudflare Worker:** `https://weltenbibliothek-api.brandy13062.workers.dev`
- **Cloudflare Account-ID:** `3472f5994537c3a30c5caeaff4de21fb`

## 🔨 Build

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek-api.brandy13062.workers.dev \
  --dart-define=LIVEKIT_URL=wss://livekit-wb.srv1438024.hstgr.cloud
```

## 📜 Kernregeln (verbindlich)

1. **Build-Nummer in `pubspec.yaml`** nur bei nativen Änderungen (Plugin/Permission/Kotlin/Flutter-Upgrade) ändern — bei reinen Dart-Änderungen niemals.
2. **Secrets** (`SERVICE_ROLE_KEY`, `GROQ_API_KEY`, `FCM_*`, `CLOUDFLARE_API_TOKEN`) ausschließlich als Wrangler/GitHub-Secrets — niemals im Client, niemals in `wrangler.toml [vars]`. `SUPABASE_ANON_KEY` darf via dart-define in den Client. GitHub-Secret-Werte beim Setzen **ohne Whitespace** prüfen.
3. **Git:** direkt auf `main` pushen. Keine Feature-Branches, keine PRs.
4. **`flutter analyze` = 0 Errors** vor jedem Commit. `dart format .` vorher.
5. **OTA-first:** `shorebird patch` ist Default für jede Dart/UI/Logik-Änderung; `shorebird release` nur nach expliziter Absprache. Pro Commit angeben: ✓ "Patch-kompatibel" oder ⚠️ "Neuer Release nötig".
6. **RLS Pflicht** auf allen Supabase-Tabellen. `service_role`-Key nur im Worker, nicht im Client.
7. **Deutsche UI-Texte**, englische technische Code-Kommentare. User-freundliche Fehler-SnackBars statt rohe Exception-Texte.
8. **NIEMALS Named Dart 3 Record Types** in lib/ verwenden — diese crashen dart2js (Flutter Web Build).
   - VERBOTEN: `({String name, int count})` als Typannotation, Feldtyp, Rückgabetyp oder Generics.
   - ERLAUBT: Positionale Records `(String, int)` mit `.$1`/`.$2` (kompilieren problemlos).
   - ERLAUBT: Named Parameter `{String? foo}` in Methodensignaturen (sind keine Records).
   - FIX: Statt Record-Typ immer eine plain Dart class mit `final`-Feldern und `const`-Konstruktor anlegen.
   - CI-Guard in `build_web.yml` fängt Verstösse automatisch ab (schlägt fehl bevor dart2js startet).

## 🔀 Commits

Format: `type(scope): beschreibung` — `type` ∈ {`feat`, `fix`, `refactor`, `style`, `chore`}.

**WICHTIG · Cloudflare-Pages-Deploy:** Commit-Titel und -Body NUR mit
ASCII-Zeichen. UTF-8-Sonderzeichen wie `·` `—` `→` `…` werden durch die
wrangler-action-Pipeline korrumpiert und die CF-Pages-API rejected den
Deploy mit "Invalid commit message, it must be a valid UTF-8 string"
(Code 8000111) — obwohl der Flutter-Build und Upload erfolgreich waren.
Stattdessen ASCII-Pendants: `-`, `--`, `->`, `...`. Emoji `✓` `⚠️`
funktionieren komischerweise, aber sicherheitshalber durch `[OK]` /
`[!]` ersetzen.

## 🧰 Skills

Detaillierte Instruktionen in `.claude/skills/` (142 installiert, via `npx skills add` + SessionStart-Hook auto-verlinkt):

- **Flutter/Dart:** widget-test, integration-test, responsive-layout, fix-layout, architecture, json-serialization, unit-test, static-analysis, resolve-conflicts, fix-runtime-errors
- **Backend:** supabase, postgres-best-practices, cloudflare, wrangler, durable-objects, workers-best-practices
- **Voice:** livekit-agents
- **Security:** code-maturity-assessor, differential-review, semgrep, codeql, insecure-defaults (+ ~50 weitere Audit/Fuzzing-Skills)
- **Projekt:** shorebird-ota, weltenbibliothek-architektur, weltenbibliothek-gamification, weltenbibliothek-mentor, weltenbibliothek-update-system

## ⚠️ Offene TODOs (Stand 2026-06-04)

### ✅ Erledigt (Session 2026-06-04)
- **Ein-Profil (TEIL 1A):** Doppeltes lokales Profil (`sp_materie_profile` + `sp_energie_profile`) auf einen Unified-Store reduziert. Mirror-Funktionen + Multi-Source-Rollen-Logik entfernt, Einmal-Migration beim Start.
- **Dashboard-Split (TEIL 1B):** `world_admin_dashboard.dart` (11.8k Zeilen) via `part`/`part of` in per-Tab/per-Sheet-Dateien zerlegt (476 Zeilen Hauptdatei).
- **Security-Fixes (TEIL 2/3):** Username-basierte Privilege-Escalation entfernt, `/api/admin/dashboard` HMAC-gated, Self-Protection in ban/warn, `?? false`-Fixes, CSV ohne user_id.

### 🔴 Kritisch
1. **Auth-Refactor: InvisibleAuth → Supabase Anonymous Auth.** App nutzt aktuell client-generierte `user_<ts>_<rand>` IDs ohne echte Server-Validation. `/auth/*`-Worker-Endpoints existieren nicht (Code-Theater). Konsequenz: Username-basierte Impersonation möglich, RLS `auth.uid()=user_id` nicht anwendbar. Plan: `supabase.auth.signInAnonymously()`, JWT durchreichen, RLS härten.
2. **RLS-Härtung:** Audit 2026-06-04: ALLE public-Tabellen haben jetzt RLS aktiviert (kein `rls_enabled=false` mehr). Rest-Risiko: viele `USING (true)`-Policies auf sensiblen per-User-Tabellen (`spirit_readings`, `biometric_data_cache`, `manifestation_goals`, `bookmark_collections`, `user_annotations`, `vorhang_lesson_notes`, `web_access_requests` u.a.). **Echt blockiert von #1:** Client (z.B. `spirit_reading_service`) liest diese direkt mit Anon-Key unter InvisibleAuth — `auth.uid()=user_id` würde die App für alle brechen. Erst nach Anon-Auth härtbar.

### 🟠 Wichtig
1. **Worker-Quota:** Free-Plan 100k/Tag wurde erschöpft (Cron-Drossel auf `*/5` seit v644c80f). Mittelfristig Workers Paid ($5/Monat) oder Worker modularisieren.
2. **LiveKit 3D-Avatar (B10.7)** noch nicht implementiert.
3. **LiveKit Egress Runner** für Recording auf VPS deployen.
4. **Mentor-Worker-Secrets:** `GROQ_API_KEY`, `YOUTUBE_API_KEY`, `GOOGLE_FACTCHECK_API_KEY` setzen (Fallback Workers-AI funktioniert).
5. **`/api/vorhang/modules` Payload 264 KB** — Mobile-Performance, evtl. Markdown lazy laden.

### 🟡 Sollte
1. info-level Analyzer-Issues: `use_build_context_synchronously`, `unused_field`, `deprecated_member_use`.
2. 31 TODO/FIXME-Marker im Code.
3. Worker-Datei monolithisch → modularisieren.
4. ~~Admin-Endpoints `/admin/migrate-v*` hardcoded String-Tokens~~ — Audit 2026-06-04: keine `migrate-v*`-Endpoints mehr im Worker vorhanden (erledigt/entfernt).

### 🟢 Nice-to-have
1. **iOS-Build:** `ios/`-Verzeichnis fehlt. Setup auf Mac mit Xcode: `flutter create --platforms=ios .` im Projekt-Root. Danach in `ios/Runner/Info.plist`:
   - `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` (Apple Watch HR/HRV-Sync)
   - `NSMicrophoneUsageDescription`, `NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`
   - Xcode-Capabilities: HealthKit + Background-Modes `audio`/`voip` (LiveKit). Apple Watch syncen dann automatisch via HealthKit.
2. APK-Build lokal (Sandbox-Container hat kein Android SDK).
