# 🎥 LiveStream High-End Roadmap — Status & offene Aufgaben

**Stand:** 2026-05-04, vor Übergabe an neue Session.

---

## ✅ Bereits gemergt auf `main` (OTA-Patches)

| # | Bundle | PR | Status |
|---|---|---|---|
| B1 | High-End-Audio (Geräuschunterdrückung, Echo-Cancel, Auto-Gain, HighPass, Typing-Filter) + Audio-Only-Modus | #84 | ✅ live |
| B2 | Auto-Speaker-Pin + Verbindungs-Qualität-Indikator (Discord-style farbiger Dot) | #85 | ✅ live |
| B3 | Aktiver-Sprecher Aura-Glow in WB-Welt-Farben (Materie rot↔blau, Energie lila↔cyan) | #86 | ✅ live |
| B4 | Floating Reactions via DataChannel + pro Welt eigene Emoji-Sets + Bottom-Sheet-Picker | #87 | ✅ live |
| B5 | Pre-Join Lobby (Avatar-Preview, Mic-Permission, Audio-Only-Toggle, dynamischer Beitreten-Button) | #88 | ✅ live |
| B6 | Layout-Toggle Gallery ↔ Speaker-View (Großer Hauptsprecher + scrollbarer Strip) | #89 | ✅ live |

---

## 🟡 In Arbeit (offen für neue Session)

### B7 — Live-Karten-Pins (Materie-USP) — PR #90 — **CI failed, Fix gepusht**

**Branch:** `claude/livestream-b7-live-map-pins`

**Was es ist:**
Long-Press auf die Materie-Geopolitik-Karte → Modal "Live-Pin senden" → broadcast via Supabase Realtime → Pin erscheint bei ALLEN Materie-User der Welt sofort als gepulster Avatar-Marker (Auto-Expiry nach 5 Min, keine DB-Persistenz).

**Status:** PR #90 erste CI gescheitert wegen `latlong2.Path` shadowed `Flutter.Path` im CustomPainter. Fix `hide Path` ist als Commit `f60c0f0` auf der PR-Branch — wartet auf neuen CI-Run.

**Nächster Schritt in neuer Session:**
1. Status prüfen: `mcp__github__pull_request_read get_check_runs PR #90`
2. Wenn grün → mergen mit:
   - title: `feat(livestream-b7): Live-Karten-Pins Materie-USP (#90)`
   - body: Service Realtime-Channel + Pin-Marker-Layer + Long-Press im Materie-Karten-Tab. Pure Patch ✓.
3. Wenn weiterer CI-Fehler → Logs prüfen + fixen

---

## ⏳ Noch zu bauen — Patch-kompatibel ✓ (kein neues APK)

### B8 — AI Live-Untertitel + Auto-Übersetzung

**Wirkung:** ⭐⭐⭐⭐⭐ Premium-Feel, einzigartig

**Ansatz:**
- LiveKit lokalen Audio-Track abgreifen (oder via WebRTC TrackProcessor)
- Audio-Chunks an Cloudflare Worker `/api/transcribe` schicken
- Worker nutzt Whisper API (OpenAI/Groq) → Text zurück
- Optional: Worker übersetzt via OpenAI/DeepL bei Bedarf
- UI: Schwebende Caption-Bar am unteren Bildschirmrand mit "Sprecher: <text>"
- Toggle in TopBar zum Ein-/Ausschalten

**Architektur:**
- `lib/services/live_caption_service.dart` (Audio-Capture + WebSocket zu Worker)
- `lib/widgets/live_caption_overlay.dart` (Floating-Banner unten)
- Worker: `workers/api-worker.js` neuer Endpoint `/api/transcribe`
- Sprache wählbar im Pre-Join-Lobby (DE/EN/ES default DE)

**Risiken:**
- Audio-Track-Capture aus livekit_client unklar (livekit_client.LocalAudioTrack hat kein einfaches `onData`)
- Whisper-API-Costs (User-Limit nötig — z.B. 30 Min/Tag pro User)
- Latenz (1-3s typisch) — User-Erwartung managen

**Geschätzt:** 8-12h Arbeit (1 großer PR oder 2 PRs: Server + Client)

---

### B9 (war ehemals B7.5) — Energie-Karten-Tab Live-Pins (Symmetrie)

Gleiche Funktion wie B7 aber für Energie-Welt:
- Service unterstützt schon `world: 'energie'`
- Nur Energie-Karten-Tab um `LivePinsLayer(world: 'energie', accent: WbDesign.energieAccent)` ergänzen
- Long-Press-Handler kopieren aus materie_karte_tab_pro.dart (~30 Zeilen)
- Klein: ~30 Min Arbeit

**Datei:** `lib/screens/energie/energie_karte_tab_pro.dart`

---

### B11 — Spotlight (Host pinnt für ALLE)

- Long-Press auf Tile → "Für alle pinnen" Option
- Broadcast via DataChannel mit `{type:'spotlight', identity}`
- Empfangende Geräte setzen ihren `_pinnedIdentity` auf den broadcasteten Identity
- Service hat `_pinnedIdentity` und `_autoSpeakerFocus = false` Override-Logik schon

**Geschätzt:** 2-3h

---

### B12 — Push-to-Talk

- Mic-Button im ControlBar bekommt Long-Press-Handler
- Beim Halten: Mic an, beim Loslassen: Mic aus
- Visueller Indikator (Mic-Button glüht stark während gehalten)
- Toggle "PTT-Modus" in Pre-Join oder Settings

**Geschätzt:** 2h

---

## 🔴 Native Releases (B10) — APK-Update nötig

Diese Features brauchen native Plugins oder Audio-Assets → kein OTA-Patch möglich.
**WARNUNG:** Build-Nummer in `pubspec.yaml` bumpen + neue APK verteilen!

### B10.1 — Welt-Soundscape (Atmosphäre)
- Materie: Sci-Fi-Drone Loop (~10s seamless, MP3/OGG)
- Energie: Tibet-Schale + Naturklänge Loop
- Toggle in TopBar "Atmosphäre"
- Sehr leise abspielen (10-15% Volume) während Call läuft
- **Assets nötig:** 2x Audio-Files in `assets/sounds/`
- Package: `audioplayers` (schon im Projekt? prüfen)

### B10.2 — Heilfrequenz-Player (Energie-USP)
- Solfeggio-Frequenzen (174, 285, 396, 417, 432, 528, 639, 741, 852, 963 Hz)
- Sinus-Wellen dynamisch generieren ODER Asset-Loops
- Picker im Energie-LiveKit-Screen "Frequenz wählen"
- Volume-Slider
- Package: `flutter_synth` oder `audioplayers` mit Tone-Files

### B10.3 — Picture-in-Picture
- Wenn App minimiert → Mini-Window mit aktuellem Sprecher
- Native: iOS PiPController, Android PictureInPictureParams
- Package: `flutter_pip` oder native Channel

### B10.4 — Co-Watch (gemeinsam Video)
- Synchronisierter Video-Player (YouTube/Vimeo Embed)
- LiveKit DataChannel für Sync-Events (play/pause/seek)
- Komplex — eigenes größeres Projekt

### B10.5 — Recording (Anruf aufzeichnen)
- LiveKit Egress API (server-side)
- Cloudflare Worker proxied Egress-Request
- Recording-Files in R2 oder Supabase Storage
- Bedarf: Server-Egress-Container neben LiveKit

### B10.6 — Virtuelle Hintergründe
- Native MediaPipe oder ML Kit für Background-Segmentation
- VideoTrackProcessor in livekit_client
- Hintergrund-Bilder pro Welt (Sternenhimmel, Aurora, etc.)

### B10.7 — 3D-Avatar (statt Camera)
- Ready Player Me Avatar oder Lipsync-3D-Model
- Audio-Level → Mund-Animation
- Spielerisch — sehr aufwendig

### B10.8 — Spatial Audio
- Native AudioEngine mit Stereo-Pan basierend auf Tile-Position
- Plattform-spezifisch (iOS AVAudioEngine, Android OpenSL ES)

---

## 📋 So fortfahren in neuer Session

### Schritt 1 — Aufholen
```bash
cd /home/user/Weltenbibliothekapp
git checkout main
git pull origin main
git log --oneline -10  # Übersicht der letzten Commits
```

### Schritt 2 — B7 abschließen (höchste Priorität)
1. PR #90 CI-Status prüfen via MCP `mcp__github__pull_request_read`
2. Wenn grün → mergen
3. Wenn rot → Logs lesen + fixen

### Schritt 3 — B8 (AI-Untertitel) starten
Größtes Patch-Bundle das noch übrig ist. Beschreibung oben.

### Schritt 4 — B9 (Energie-Pins) als kleine Beilage

### Schritt 5 — B11 (Spotlight) + B12 (PTT)

### Schritt 6 — B10 als ein einziger Release-PR
Build-Nummer bumpen, alle native Features bündeln, einmalig neue APK rollen.

---

## 🎯 Architektur-Prinzipien für neue Session

1. **Patch-First**: Immer prüfen ob Feature ohne Build-Nummer-Bump geht
2. **Welt-Identität**: Materie = blau/rot, Energie = lila/cyan
3. **WbDesign tokens**: Keine hardcoded colors für Welt-Akzente
4. **Konflikte vermeiden**: Pro Bundle ein PR, sequentiell mergen statt Stacking
5. **Lokal validieren**: Bei Multi-Datei-Änderungen `dart analyze` lokal vor Push

---

## 📞 Kontaktpunkte für die neue Session

- **PR-Branch B7 (Live-Pins):** `claude/livestream-b7-live-map-pins`, neuester Commit `f60c0f0`
- **Service-Pattern:** `lib/services/live_map_pins_service.dart` ist Vorlage für Realtime-Broadcast-Features
- **Reactions-Pattern:** `lib/widgets/livekit_reactions_overlay.dart` ist Vorlage für Floating-Animationen
- **Welt-Akzent:** `WbDesign.accent('materie')` = Blau, `WbDesign.accent('energie')` = Lila

---

**Generiert:** 2026-05-04 von Claude (Sonnet 4.6 Session) zur Übergabe.
