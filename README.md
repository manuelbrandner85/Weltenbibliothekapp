# 🌍 Weltenbibliothek v5.11.0

**Die alternative Wissens- und Bewusstseins-Plattform mit zwei Welten: Materie & Energie**

[![Version](https://img.shields.io/badge/version-5.11.0-blue.svg)](https://github.com/manuelbrandner85/Weltenbibliothekapp)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2.svg)](https://dart.dev)
[![Analyzer](https://img.shields.io/badge/flutter%20analyze-0%20errors-brightgreen.svg)]()

> 🤖 **KI-Assistenten**: Lies zuerst [`CLAUDE.md`](./CLAUDE.md) – enthält alle Kontext-Informationen,
> Architektur, Credentials-Regeln, offene Aufgaben und Fallstricke.

---

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────┐
│  Flutter App (Android / iOS / Web)                       │
├────────────────────────┬────────────────────────────────┤
│  SUPABASE              │  CLOUDFLARE                     │
│  ✅ Auth / Sessions    │  ✅ Edge API / BFF              │
│  ✅ Profile / Rollen   │  ✅ AI / Recherche              │
│  ✅ Community-Posts    │  ✅ Voice-State (DO)            │
│  ✅ Kommentare/Likes   │  ✅ Rate-Limiting / Abuse       │
│  ✅ Chat-Text (RT)     │  ✅ R2 Medien-Storage           │
│  ✅ Storage (Avatare)  │  ✅ Turnstile / Schutz          │
└────────────────────────┴────────────────────────────────┘
```

### Cloudflare – Aktive Ressourcen

| Ressource | Typ | URL/ID |
|-----------|-----|--------|
| `weltenbibliothek-api` | Worker (Edge API) | `https://weltenbibliothek-api.brandy13062.workers.dev` |
| `weltenbibliothek-db` | D1 Database | Account: `3472f5994537c3a30c5caeaff4de21fb` |
| `weltenbibliothek-media` | R2 Bucket | Media-Storage |

### Supabase – Aktive Ressourcen

| Ressource | Typ | Status |
|-----------|-----|--------|
| `profiles` | Tabelle | ✅ Mit RLS |
| `chat_rooms` | Tabelle | ✅ Mit RLS |
| `chat_messages` | Tabelle | ✅ Mit RLS |
| `community_posts` | Tabelle | ✅ Mit RLS |
| `notifications` | Tabelle | ✅ Mit RLS |
| `avatars` | Storage Bucket | ✅ Public |
| `tool_*` (7 Tabellen) | Tool-Daten | ⚠️ Migration ausstehend |

---

## 🚀 Build & Deployment

### Flutter Build (Produktion)

```bash
flutter build apk --release \
  --dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek-api.brandy13062.workers.dev \
  --dart-define=SUPABASE_URL=https://adtviduaftdquvfjpojb.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdHZpZHVhZnRkcXV2Zmpwb2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzY3OTcsImV4cCI6MjA5MDcxMjc5N30.LPtmnjukb6o2CA16RDjoStqYb_1bipNULD4tgOfuD98
```

> ⚠️ **Niemals Service-Role-Key oder API-Tokens im Client-Code!**

### Cloudflare Worker Deploy

```bash
cd workers
npx wrangler deploy
# Secret setzen (einmalig):
echo "dein_key" | npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
```

### Supabase Migrations (ausstehend)

```
https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new
→ Inhalt von supabase/migrations/20260402_v12_missing_tool_tables.sql einfügen & ausführen
```

---

## 📁 Projektstruktur

```
lib/
├── config/
│   ├── api_config.dart              # ⭐ ALLE API-URLs (NIEMALS Tokens hardcoden!)
│   └── feature_flags.dart
├── services/
│   ├── supabase_service.dart        # Auth, Profile, Chat (Supabase)
│   ├── cloudflare_api_service.dart  # Edge API, AI (Cloudflare)
│   ├── hybrid_chat_service.dart     # Chat-Koordination
│   ├── webrtc_voice_service.dart    # Voice/WebRTC
│   └── offline_sync_service.dart   # Offline-Queue
├── screens/
│   ├── energie/                     # Energie-Welt Screens
│   │   └── energie_live_chat_screen.dart  # ⭐ Haupt-Chat Energie
│   ├── materie/                     # Materie-Welt Screens
│   │   └── materie_live_chat_screen.dart  # ⭐ Haupt-Chat Materie
│   └── shared/                      # Geteilte Screens
└── widgets/                         # UI-Komponenten

workers/
├── api-worker.js                    # ⭐ Cloudflare Edge API Worker
└── wrangler.toml                    # Worker-Konfiguration

supabase/
├── schema.sql                       # Produktions-Schema
└── migrations/                      # SQL-Migrationen (chronologisch)
```

---

## 🔐 Sicherheitsregeln

1. **Kein Token im Client-Code** – `--dart-define` oder Wrangler Secrets
2. **Cloudflare API Token** – nur als `wrangler secret put`
3. **Supabase Service Role Key** – nur im Cloudflare Worker als Secret
4. **Supabase Anon Key** – darf im Client sein (durch RLS abgesichert)
5. **RLS auf allen Supabase-Tabellen** – Pflicht
6. **`.env` ist in `.gitignore`** – niemals committen

---

## 📋 Architektur-Grenzen

| Bereich | Darf NUR in... |
|---------|---------------|
| Auth / Sessions / Rollen | Supabase |
| User-Profile / Community | Supabase |
| Chat-Text-Persistenz + Realtime | Supabase |
| Edge-API / AI / Recherche | Cloudflare Worker |
| Voice-State / WebRTC | Cloudflare Durable Objects |
| Große Medien / Audio | Cloudflare R2 |

---

## 🗺️ Roadmap

- [x] Chat POST/GET/PUT/DELETE Endpunkte vollständig implementiert
- [x] Supabase Realtime-Chat in Energie + Materie
- [x] Avatar-Picker in beiden Chat-Screens
- [x] 0 Flutter-Analyzer Errors/Warnings
- [ ] SQL-Migration für 7 Tool-Tabellen ausführen
- [ ] Community Likes aus Datenbank laden (statt static false)
- [ ] Voice-Rooms Produktionstest
- [ ] Push-Notifications Delivery-Test
- [ ] APK Release-Build + Play Store Upload
- [ ] Supabase RLS vollständig auf alle tool_* Tabellen
- [ ] Voice-Rooms auf Cloudflare Durable Objects migrieren

---

## 🤖 KI-Assistenten (GenSpark Claw)

**Vollständige Instruktionen in [`CLAUDE.md`](./CLAUDE.md)**

Enthält:
- Vollständige Architektur-Beschreibung
- Alle Credentials und wo sie hingehören
- Bekannte Bugs und Fallstricke
- Git-Workflow (Branch: `genspark_ai_developer`)
- Alle offenen Aufgaben mit Priorität
- Schnellstart-Befehle für neue Sessions
