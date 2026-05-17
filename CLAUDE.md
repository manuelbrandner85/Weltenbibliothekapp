# 🌍 Weltenbibliothek – Claude Code Instruktionen

Flutter-App (Android, kein Play Store — Sideloading via APK) mit Supabase-Backend,
Cloudflare Worker (Edge API + AI), Shorebird OTA-Updates und LiveKit Voice/Video.
4 Welten: **Materie** (rot), **Energie** (lila), **Vorhang** (gold), **Ursprung** (cyan).
Repository: https://github.com/manuelbrandner85/Weltenbibliothekapp

---

## 🔗 Aktive Endpoints

- **Supabase:** `https://adtviduaftdquvfjpojb.supabase.co`
- **Cloudflare Worker:** `https://weltenbibliothek-api.brandy13062.workers.dev`
- **Cloudflare Account-ID:** `3472f5994537c3a30c5caeaff4de21fb`
- **LiveKit:** `wss://livekit-wb.srv1438024.hstgr.cloud:7892`

---

## 📜 Die 7 Kern-Regeln (verbindlich)

1. **Build-Nummer stabil halten** — `version:` in `pubspec.yaml` NUR ändern bei nativen
   Änderungen (Plugin, Permission, Kotlin, Flutter-Upgrade). Bei reinen Dart-Änderungen
   IMMER gleich lassen. Begründung: User behalten ihre APK, Shorebird-Patches matchen
   exakt eine Release-Version.
2. **OTA-first** — Default-Deployment für jede Dart/UI/Logik-Änderung ist `shorebird patch`.
   `shorebird release` nur nach expliziter Absprache. Bei jedem Commit angeben:
   **"Patch-kompatibel ✓"** oder **"Neuer Release nötig ⚠️"**.
3. **Secrets-Trennung** — `SUPABASE_ANON_KEY` darf in den Client (dart-define).
   `SERVICE_ROLE_KEY`, `GROQ_API_KEY`, `YOUTUBE_API_KEY`, `FCM_SERVICE_ACCOUNT`,
   `CLOUDFLARE_API_TOKEN` etc. **NIE** im Client und **NIE** in `wrangler.toml [vars]` —
   ausschließlich als Wrangler/GitHub-Secrets. `.env` in `.gitignore`.
4. **Git-Workflow** — Direkt auf `main` pushen. Kein Feature-Branch, kein PR-Workflow.
   Commit-Format: `type(scope): beschreibung` (feat/fix/refactor/style/chore).
   Stop-Hook prüft auf untracked Files vor Sessionende.
5. **`flutter analyze` = 0 Errors** vor jedem Commit. Vorher `dart format .` laufen lassen.
6. **RLS auf ALLEN Supabase-Tabellen** — `auth.uid() = user_id` Pattern. `service_role`-Key
   NIEMALS im Client-Code, nur im Worker.
7. **Deutsche UI** — User-facing Strings auf Deutsch, technische Code-Kommentare Englisch.
   User-freundliche Fehler-SnackBars statt rohe Exception-Texte.

---

## 📚 Details in installierten Skills

Tiefergehende Regeln, Architektur, Workflows und projektspezifisches Wissen findest du
in den Skills unter `.claude/skills/`:

- `shorebird-ota-workflow` — CI-Workflows, Patch vs Release Entscheidungsbaum,
  Pinning-Regeln, Signatur-Mismatch-Schutz
- `weltenbibliothek-architektur` — 4-Welten-System, Service-Grenzen Supabase ↔ Worker,
  Credentials-Matrix, Datei-Struktur
- `weltenbibliothek-gamification` — Octalysis XP-System, Vorhang-Module (30 Module,
  6 Branches), Supabase-Tabellen, Boss-Module
- `weltenbibliothek-mentor` — KI-Mentor mit 4 Persönlichkeiten, Worker-Endpoints,
  Groq/Workers-AI Fallback
- `weltenbibliothek-update-system` — OTA-Patch-Dialog, ReleaseUpdateScreen,
  Auto-Restart (MethodChannel), Debug-Schutz

138 externe Skills (Flutter/Dart, Supabase, Cloudflare, LiveKit, Flutter-Craft,
Trail of Bits, Superpowers): `npx skills list`. Historischer Kontext
(PR-Changelog #28–#168, FCM-Setup, Audio/Health-Plugin, Keystore-Regeln):
`docs/CHANGELOG.md`.

---

## ⚠️ Offene Aufgaben

1. **SQL-Migration `20260402_v12_missing_tool_tables.sql`** (7 Tool-Tabellen) noch nicht
   in `apply_migrations.yml` enthalten — bei Bedarf manuell via Supabase SQL-Editor.
2. **info-level Analyzer-Issues** (kein Error/Warning): `use_build_context_synchronously`,
   `unused_field`, `deprecated_member_use` (Radio-Widgets).
3. **LiveKit B10.7 — 3D-Avatar** noch nicht implementiert (braucht Assets + ggf. neues Package).
4. **Recording-Voraussetzung** — LiveKit Egress Runner Container auf VPS deployen.
5. **APK-Build lokal** — Sandbox hat kein Android SDK, Build läuft nur via CI.
6. **iOS-Build** — `ios/`-Verzeichnis fehlt; HealthKit + Audio Background-Modes in
   Info.plist nachziehen (Details in `docs/CHANGELOG.md`).
7. **Mentor-Worker-Secrets** — `GROQ_API_KEY`, `YOUTUBE_API_KEY`, `GOOGLE_FACTCHECK_API_KEY`
   als Wrangler-Secrets setzen (Fallback: Workers AI + Piped API).
