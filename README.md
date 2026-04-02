# 🌍 Weltenbibliothek v5.6.0

**Die alternative Wissens- und Bewusstseins-Plattform mit zwei Welten: Materie & Energie**

[![Version](https://img.shields.io/badge/version-5.6.0-blue.svg)](https://github.com/manuelbrandner85/Weltenbibliothekapp)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2.svg)](https://dart.dev)

---

## 🏗️ Architektur (Zielzustand v2.0)

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

| Ressource | Typ | Status |
|-----------|-----|--------|
| `weltenbibliothek` | Worker (Pages) | ✅ Aktiv |
| `weltenbibliothek-db` | D1 Database | ✅ Aktiv |
| `weltenbibliothek-media` | R2 Bucket | ✅ Aktiv |

### Supabase – Aktive Ressourcen

| Ressource | Typ | Status |
|-----------|-----|--------|
| `profiles` | Tabelle | ✅ Mit RLS |
| `articles` | Tabelle | ✅ Mit RLS |
| `chat_rooms` | Tabelle | ✅ Mit RLS |
| `chat_messages` | Tabelle | ✅ Mit RLS |
| `notifications` | Tabelle | ✅ Mit RLS |
| `avatars` | Storage Bucket | ✅ Public |
| `media` | Storage Bucket | ✅ Public |

---

## 🚀 Build & Deployment

### Voraussetzungen
- Flutter SDK ≥ 3.x, Dart ≥ 3.9.2
- Cloudflare Account, Supabase Project

### Flutter Build (dart-define für Secrets)

```bash
flutter build apk \
  --dart-define=CLOUDFLARE_WORKER_URL=https://weltenbibliothek.brandy13062.workers.dev \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

> ⚠️ **Niemals Tokens im Quellcode** – ausschließlich via `--dart-define` oder Wrangler Secrets.

### Cloudflare Worker Deploy

```bash
cd cloudflare-worker
wrangler secret put PRIMARY_TOKEN   # Worker-to-Worker Auth
wrangler secret put ADMIN_TOKEN     # Admin-Aktionen
wrangler deploy
```

---

## 📁 Projektstruktur

```
lib/
├── config/
│   ├── api_config.dart          # Zentrale URL-Konfiguration (NO TOKENS)
│   └── feature_flags.dart       # Feature Toggles
├── services/
│   ├── supabase_service.dart    # Auth, Profile, Community, Chat, Storage
│   ├── cloudflare_api_service.dart  # Edge-API, AI, Recherche
│   └── ...
├── screens/                     # UI-Screens
└── widgets/                     # Wiederverwendbare Widgets

cloudflare-worker/               # Worker-Code (Archiv-Version v3.2)
cloudflare-workers/              # Security-Headers Worker
supabase/
└── schema.sql                   # DB-Schema inkl. RLS-Policies
docs/
├── backups/d1/                  # D1-SQL-Dumps (Backup vor Cleanup)
└── archive/                     # Veraltete Docs (nicht für Produktion)
```

---

## 🔐 Sicherheitsregeln

1. **Kein Token im Client-Code** – `--dart-define` oder serverseitige Secrets
2. **Cloudflare API Token** – nur als Wrangler Secret (`wrangler secret put`)
3. **Supabase Service Role Key** – nur auf Server-Seite (Worker-Secret)
4. **Supabase Anon Key** – darf im Client sein (durch RLS abgesichert)
5. **RLS auf allen Supabase-Tabellen** – Pflicht
6. **`.env` ist in `.gitignore`** – niemals committen

---

## 📋 Verbotene Doppelzuständigkeiten

| Bereich | Darf NUR in... |
|---------|---------------|
| Auth / Sessions / Rollen | Supabase |
| User-Profile / Community | Supabase |
| Chat-Text-Persistenz | Supabase Realtime |
| Edge-API / AI / Recherche | Cloudflare Worker |
| Voice-State / WebRTC-Koordination | Cloudflare Durable Objects |
| Große Medien / Video-Assets | Cloudflare R2 |

---

## 🗺️ Roadmap

- [ ] Supabase RLS vollständig aktivieren (alle Tabellen)
- [ ] Voice-Rooms auf Cloudflare Durable Objects migrieren
- [ ] D1-Duplikate (weltenbibliothek-chat, weltenbibliothek-community) nach Backup löschen
- [ ] 20 KV-Namespaces auf 8 reduzieren
- [ ] Staging-R2-Buckets prüfen und ggf. löschen
