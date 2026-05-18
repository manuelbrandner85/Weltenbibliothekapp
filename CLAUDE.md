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

## ⚠️ Offene TODOs (Stand 2026-05-17)

### 🔴 Kritisch
1. **Auth-Refactor: InvisibleAuth → Supabase Anonymous Auth.** App nutzt aktuell client-generierte `user_<ts>_<rand>` IDs ohne echte Server-Validation. `/auth/*`-Worker-Endpoints existieren nicht (Code-Theater). Konsequenz: Username-basierte Impersonation möglich, RLS `auth.uid()=user_id` nicht anwendbar. Plan: `supabase.auth.signInAnonymously()`, JWT durchreichen, RLS härten.
2. **RLS-Härtung:** 11 Tabellen ohne RLS, 28 mit `USING (true)`, `chat_messages` GRANT-ALL TO anon. Blockiert von #1.

### 🟠 Wichtig
1. **Worker-Quota:** Free-Plan 100k/Tag wurde erschöpft (Cron-Drossel auf `*/5` seit v644c80f). Mittelfristig Workers Paid ($5/Monat) oder Worker modularisieren.
2. **LiveKit 3D-Avatar (B10.7)** noch nicht implementiert.
3. **LiveKit Egress Runner** für Recording auf VPS deployen.
4. **Mentor-Worker-Secrets:** `GROQ_API_KEY`, `YOUTUBE_API_KEY`, `GOOGLE_FACTCHECK_API_KEY` setzen (Fallback Workers-AI funktioniert).
5. **`/api/vorhang/modules` Payload 264 KB** — Mobile-Performance, evtl. Markdown lazy laden.

### 🟡 Sollte
1. info-level Analyzer-Issues: `use_build_context_synchronously`, `unused_field`, `deprecated_member_use`.
2. 31 TODO/FIXME-Marker im Code.
3. Worker-Datei 6560 Zeilen monolithisch → modularisieren.
4. Admin-Endpoints `/admin/migrate-v*` nutzen hardcoded String-Tokens — auf JWT migrieren.

### 🟢 Nice-to-have
1. iOS-Build: `ios/`-Verzeichnis fehlt; HealthKit + Audio Background-Modes.
2. APK-Build lokal (Sandbox-Container hat kein Android SDK).
