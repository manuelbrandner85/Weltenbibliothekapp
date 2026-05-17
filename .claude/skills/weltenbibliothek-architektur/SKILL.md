---
name: weltenbibliothek-architektur
description: Architektur-Regeln und 4-Welten-System
globs: ["lib/**", "workers/**", "supabase/**"]
---

# Weltenbibliothek Architektur

## 4 Welten
| Welt | Farbe | Themen |
|------|-------|--------|
| Materie | #E53935 Rot | Geopolitik, Geschichte, UFOs, Verschwörungen, Heilmethoden |
| Energie | #7C4DFF Lila | Spiritualität, Meditation, Kristalle, Chakren, Bewusstsein |
| Vorhang | #C9A84C Gold auf Schwarz | Geheimgesellschaften, Machtpsychologie, Enthüllungen |
| Ursprung | #00D4AA Cyan auf #050510 | Naturvölker, Kosmologie, ursprüngliches Wissen |

## Architektur-Grenzen (NIEMALS mischen!)
| Bereich | Zuständig |
|---------|-----------|
| Auth, Sessions, Profile, Rollen | NUR Supabase |
| Chat-Text, Realtime, Community | NUR Supabase |
| AI, Recherche, Mentor-Chat | NUR Cloudflare Worker |
| Voice/LiveKit Token | NUR Cloudflare Worker |
| Große Medien, Audio | NUR Cloudflare R2 |
| Rate-Limiting, Moderation | NUR Cloudflare Worker |

## Credentials-Regeln
- SUPABASE_URL + ANON_KEY → dart-define (Client OK)
- SERVICE_ROLE_KEY → NUR als Wrangler Secret
- GROQ/YOUTUBE/FCM Keys → NUR als Wrangler Secret
- .env MUSS in .gitignore

## Aktive URLs
- Supabase: https://zctufcfjsixfgmmwvnmv.supabase.co
- Worker: https://weltenbibliothek-api.brandy13062.workers.dev
- Cloudflare Account: 3472f5994537c3a30c5caeaff4de21fb

## Git-Workflow
- IMMER direkt auf main pushen
- Kein Feature-Branch, kein PR
- Commit: type(scope): beschreibung
- flutter analyze = 0 Fehler vor jedem Commit
