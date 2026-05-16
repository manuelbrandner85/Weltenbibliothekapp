# 🌟 Weltenbibliothek 6.0 — QUANTEN-ERWACHEN

Die größte Erweiterung seit dem Launch. Zwei neue Welten, ein KI-Mentor mit
vier Persönlichkeiten, fünf interaktive Bewusstseinstools, ein Gamification-
System, eine geheime Bibliothek mit Primärquellen und ein personalisierter
Tagespfad — alles in einer Version.

---

## 🆕 ZWEI NEUE WELTEN

### 🎭 VORHANG — Die Psychologie der Macht
**30 Module in 6 Branches**, gebaut auf Robert Greene, Robert Cialdini,
Sun Tzu, Niccolò Machiavelli, Chris Voss und C.G. Jung.

- Branch 1 — **Machtpsychologie**: 48 Gesetze, Cialdini, Dunkle Triade, Soft Power, BOSS
- Branch 2 — **Manipulationserkennung**: Gaslighting, Love Bombing, DARVO, Sekten-Taktiken, BOSS
- Branch 3 — **Verhandlung & Überzeugung**: Harvard-Konzept, Voss-Taktiken, Reframing, BOSS
- Branch 4 — **Körpersprache & Nonverbales**: Ekman-Mikroexpressionen, Power-Posen, BOSS
- Branch 5 — **Strategisches Denken**: Sun Tzu, Spieltheorie, OODA-Loop, BOSS
- Branch 6 — **Schattenarbeit**: Jung'scher Schatten, Projektion, goldener Schatten, BOSS

### 🌀 URSPRUNG — Bewusstseinstechniken aus CIA-Akten
**25 Module + 5 interaktive Tools**, basierend auf den deklassifizierten
Dokumenten des US-Militärs (Gateway Process, STAR GATE, Monroe-Institut).

#### 5 interaktive Tools
- **Gateway-Kammer** — Geführte Sessions in Focus 10, 12, 15, 21 mit
  Hemi-Sync-Audiosignalen, optional mit HRV-Tracking
- **Frequenz-Generator** — Binaurale Beats (1–40 Hz Delta/Theta/Alpha/Gamma)
  + Solfeggio-Frequenzen (432 Hz, 528 Hz, 7.83 Hz Schumann)
- **Atemmeister** — Vier CIA/Gateway-Atemtechniken (Resonant Tuning,
  4-7-8, Box-Breathing, Wim-Hof-Style)
- **Realitäts-Architekt** — Manifestation nach CIA-Patterning mit
  visuellen Ankerpunkten und Resonanz-Trainings
- **Remote-Viewing-Trainer** — CRV Stages I–VI mit 50 strukturierten
  Targets (Wikidata + History/Geography Locations)

---

## 🧠 KI-MENTOR — 4 PERSÖNLICHKEITEN

Pro Welt ein eigener Mentor mit eigenem Tonfall, eigenem Wissensschatz
und eigenem System-Prompt:

| Welt | Mentor | Charakter |
|---|---|---|
| **Vorhang** | Der Stratege | Eiskalt-analytisch, Machiavelli-inspiriert |
| **Ursprung** | Der Alchemist | Mystisch, hermetisch, verbindet Wissenschaft + Mystik |
| **Energie** | Der Heiler | Empathisch, Chakren, Meditation, sanft |
| **Materie** | Der Forscher | Wissenschaftlich-faktisch, interdisziplinär |

**Power-User-Features:** Faktencheck (Google Fact Check API), YouTube-Recherche
(Piped + YT Data v3), Tiefenrecherche in 3 Stufen (basic / deep / expert).
LLM-Stack: Groq Llama 3.3 70B → Cloudflare Workers AI Llama 3.1 8B Fallback.

---

## 🎮 GAMIFICATION — OCTALYSIS-FRAMEWORK

- **Skill-Tree**: 5 Skills pro Welt mit Prerequisites, freischaltbar via XP
- **Artefakte**: 20+ Artefakte in 4 Seltenheiten, ausrüstbar im Avatar
- **Schicksalskarten**: 60-Karten-Pool, eine pro Tag, mit 3D-Flip-Animation
- **Guilds**: Gilden mit bis zu 12 Mitgliedern, gemeinsame Challenges
- **Avatar**: 5 Evolution-Stufen, balanciert über Welt-Aktivitäten
- **Streak**: Tagesstreak mit 1× Freeze pro Woche
- **Level-Formel**: `level = sqrt(totalXP / 100)`

---

## 💓 BIOMETRIE — HRV-TRACKING + WIRKUNGS-SCORE

Apple HealthKit (iOS) + Android Health Connect Integration. Vor und nach
jeder Gateway- oder Atem-Session wird HRV (Herzraten-Variabilität) gemessen.
Daraus berechnet die App den **Wirkungs-Score** — eine prozentuale
Veränderung deiner physiologischen Kohärenz durch die Session.

Graceful Degradation: ohne Apple Watch / Fitness-Tracker läuft alles
normal weiter, nur ohne die Score-Anzeige.

---

## 🕸️ WISSENSGRAPH

Interaktiver Graph aller Konzepte über alle 4 Welten. Knoten = Konzepte,
Personen, Ereignisse, Orte, Artefakte, Theorien. Kanten zeigen Beziehungen:
related, causes, contradicts, supports, part_of, influenced_by.
**16 Starter-Knoten** über alle Welten als Seed.

---

## 📚 GEHEIME BIBLIOTHEK (ab Level 10)

Primärquellen-Datenbank mit **22 Originaltexten** zu den Modul-Inhalten,
sortiert in 6 Kategorien:

- **CIA** — Gateway-Process-Memo, CRV-Manual, STAR-GATE-Akten, Monroe Manual
- **Hermetik** — Kybalion, Smaragdtafel, Corpus Hermeticum
- **Alchemie** — Jung "Mysterium Coniunctionis", Aurora Consurgens, Atalanta Fugiens
- **Quantenphysik** — Bentov, Capra, Talbot, Bohm
- **Philosophie** — Greene, Cialdini, Sun Tzu, Machiavelli
- **Mystik** — Monroe-Trilogie, Marciniak

Mit Hero-Animation, direkten PDF-Links (z.B. CIA-Reading-Room),
verknüpften Modulen und Schwierigkeitsgrad-Badges.

---

## 🌅 AMBIENT — PERSONALISIERTER TAGESPFAD

Jeden Tag drei kuratierte Aktivitäten, abgestimmt auf:

- **Tageszeit** (morgens / mittags / abends / nachts)
- **Wetter** (Open-Meteo, Standort via Cloudflare-Header → kein Plugin nötig)
- **Streak** + **Level** + **dominante Welt**
- Optional: **Stimmung** über 5-Emoji-Picker

Plus ein täglicher Insight-Spruch und eine empfohlene Ambient-Frequenz.

---

## 🎬 ONBOARDING

Beim ersten Betreten von Vorhang und Ursprung erscheint jeweils ein
3-Slide-Intro, das den Charakter der Welt, die Modulanzahl und den
zuständigen Mentor vorstellt. Wird einmal gezeigt und dann automatisch
übersprungen.

---

## 🛠️ TECHNISCHE STICHPUNKTE

- **Tabellen neu**: mentor_sessions, user_skill_tree, artifacts,
  user_artifacts, user_titles, daily_destiny_cards, vorhang_modules,
  user_vorhang_progress, ursprung_modules, user_ursprung_progress,
  ursprung_gateway_sessions, ursprung_patterns, rv_targets, rv_sessions,
  biometric_readings, knowledge_graph_nodes, knowledge_graph_edges,
  user_graph_bookmarks, user_avatar, guilds, guild_members,
  guild_challenges, guild_challenge_progress, bibliothek_books
- **Worker-Endpoints neu**: /api/mentor/*, /api/gamification/*,
  /api/vorhang/*, /api/ursprung/*, /api/ambient/daily-path,
  /api/bibliothek/*, /api/livekit/token
- **Plugins neu (Phase 1–8)**: health, audioplayers, just_audio,
  livekit_client, flutter_background. **Phase 9+10 ohne neue Plugins**
  (Cloudflare-Location statt geolocator → patch-kompatibel).
- **Worker-Secrets erforderlich**: GROQ_API_KEY, YOUTUBE_API_KEY,
  GOOGLE_FACTCHECK_API_KEY (alle mit Fallbacks auf kostenlose Alternativen).

---

## 🎯 GETESTETE FUNKTIONEN

- ✅ Alle 4 Welten funktional + 55 Module (30 Vorhang + 25 Ursprung)
- ✅ 5 Ursprung-Tools mit Audio + HRV-Integration
- ✅ KI-Mentor in allen 4 Welten (mit Fallback zu Workers AI)
- ✅ Gamification trackt XP, Skills, Artefakte, Streak
- ✅ Biometrie misst HRV oder degradiert sauber
- ✅ Wissensgraph interaktiv (force-directed via graphview)
- ✅ Avatar evolves über 5 Stufen
- ✅ Guilds + Challenges
- ✅ Ambient Tagespfad mit Wetter + AI
- ✅ Bibliothek geöffnet ab Level 10, gesperrt darunter
- ✅ Onboarding bei erstem Welten-Besuch
- ✅ Offline-Fallback (SQLite-Cache + Resync bei Reconnect)
