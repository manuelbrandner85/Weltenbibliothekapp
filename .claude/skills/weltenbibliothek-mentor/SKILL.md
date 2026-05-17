---
name: weltenbibliothek-mentor
description: KI-Mentor System mit 4 Persönlichkeiten
globs: ["lib/services/mentor_*", "lib/screens/shared/mentor_*", "workers/api-worker.js"]
---

# KI-Mentor System

## Endpoints (Cloudflare Worker)
| Endpoint | Funktion |
|----------|----------|
| POST /api/mentor/chat | Chat mit KI-Mentor (Groq/Workers AI) |
| POST /api/mentor/factcheck | Google FactCheck + AI Verification |
| GET /api/mentor/youtube-search | Piped API primär, YT API v3 Fallback |
| POST /api/mentor/investigate | Tiefenrecherche (3 Depth-Stufen) |

## 4 Persönlichkeiten (welt-abhängig)
- Materie-Mentor: Analytisch, faktenbasiert, kritisch
- Energie-Mentor: Spirituell, einfühlsam, ganzheitlich
- Vorhang-Mentor: Strategisch, durchschauend, machtbewusst
- Ursprung-Mentor: Weise, naturverbunden, archaisch

## Supabase-Tabellen
- mentor_sessions (id, user_id, world, messages JSONB, created_at)
- Migration: 20260512_v58_mentor_sessions.sql
