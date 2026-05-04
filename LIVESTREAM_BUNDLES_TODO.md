# 🎥 LiveStream High-End Roadmap — Status & offene Aufgaben

**Stand:** 2026-05-04, nach Session 3.

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
| B7 | Live-Karten-Pins Materie (Long-Press → Supabase Realtime → gepulster Avatar-Marker, 5 Min Expiry) | #90 | ✅ live |
| B8 | Live-Untertitel on-device via speech_to_text + DataChannel-Broadcast an alle Teilnehmer | #92 | ✅ live |
| B9 | Energie-Karten-Pins (Symmetrie zu B7, Lila-Akzent #9C27B0) | #92 | ✅ live |
| B11 | Spotlight — Host pinnt Teilnehmer für alle via DataChannel | #92 | ✅ live |
| B12 | Push-to-Talk — Long-Press Mic-Button, grüner Glow, auto Mic-Toggle | #92 | ✅ live |

**Bonus-Fixes in PR #92:**
- TURN/Mobilfunk: `turnserver.conf` wird jetzt im Deploy-Workflow hochgeladen → coturn startet → Mobilfunk-User (CGNAT) können sich verbinden
- Dart-Fixes: const-Konstruktor `_CaptionLine`, null-safety `displayName`, `use_build_context_synchronously`

---

## ✅ Patch-kompatibel erledigt (B10.1 + B10.2)

| # | Bundle | Status |
|---|---|---|
| B10.1 | Welt-Soundscape (Atmosphäre) | ✅ Patch — Dart WAV-Generator, `audioplayers` BytesSource |
| B10.2 | Heilfrequenz-Player (Energie-USP) | ✅ Patch — 10 Solfeggio-Frequenzen, BottomSheet-Picker |
| B10.4 | Co-Watch (gemeinsam YouTube) | ✅ Patch — webview_flutter bereits vorhanden, DataChannel-Sync |

**B10.1 Details:**
- `lib/services/soundscape_service.dart` — WAV-Generator (22050 Hz, 16-bit mono, 5s Loop)
- Materie: 40 Hz + 44 Hz Binaural-Mix (4 Hz Gamma-Beat)
- Energie: 432 Hz Naturstimmung
- 20ms Fade-In/Out an Loop-Grenzen (kein Knacken)
- 12% Volume Standard → sehr leise im Hintergrund
- Toggle-Icon (🎵) in `_TopBar` — Atmosphäre ein/aus

**B10.2 Details:**
- 10 Solfeggio-Frequenzen (174, 285, 396, 417, 432, 528, 639, 741, 852, 963 Hz)
- BottomSheet-Picker mit Glassmorphic-Design (Energie-Lila)
- Heilfrequenz-Icon (🧘) im TopBar — nur für Energie-Welt sichtbar
- Volume 10%, ReleaseMode.loop — läuft parallel zum Soundscape

---

## 🔴 Noch offen — Native Releases (B10.3–B10.8) — APK-Update nötig

Diese Features brauchen native Plugins oder Audio-Assets → kein OTA-Patch möglich.
**WARNUNG:** Build-Nummer in `pubspec.yaml` bumpen + neue APK verteilen!

Empfehlung: Alle B10.x-Features in EINEM einzigen Release-PR bündeln, einmalig neue APK rollen.

**B10.4 Details:**
- `lib/services/cowatch_service.dart` — DataChannel-Protokoll (load/play/pause/seek/close)
- `lib/widgets/cowatch_panel.dart` — YouTube IFrame Player API via WebView, Host-Badge, Sync-Overlay
- YouTube-URL-Parser: youtu.be, youtube.com/watch?v=, /embed/, Video-ID direkt
- Schwebender Panel (55% Bildschirmhöhe) über ControlBar mit Schließ-Button
- Co-Watch-Button 📺 in ControlBar, bei Host aktiv wenn Video läuft
- Remote-Teilnehmer sehen Video automatisch wenn Host lädt

---

### B10.3 — Picture-in-Picture (nächster Schritt)
- Wenn App minimiert → Mini-Window mit aktuellem Sprecher
- Native: Android PictureInPictureParams
- Package: `flutter_pip` oder nativer MethodChannel

### B10.4 — Co-Watch (gemeinsam Video)
- Synchronisierter Video-Player (YouTube Embed)
- LiveKit DataChannel für Sync-Events (play/pause/seek)

### B10.5 — Recording
- LiveKit Egress API (server-side)
- Cloudflare Worker proxied Egress-Request
- Bedarf: Server-Egress-Container neben LiveKit

### B10.6 — Virtuelle Hintergründe
- VideoTrackProcessor in livekit_client
- Hintergrund-Bilder pro Welt (Sternenhimmel, Aurora, etc.)

### B10.7 — 3D-Avatar
- Audio-Level → Mund-Animation (Ready Player Me oder ähnlich)

### B10.8 — Spatial Audio
- Stereo-Pan basierend auf Tile-Position im Grid

---

## 🎯 Architektur-Prinzipien

1. **Patch-First**: Immer prüfen ob Feature ohne Build-Nummer-Bump geht
2. **Welt-Identität**: Materie = blau/rot, Energie = lila/cyan
3. **WbDesign tokens**: Keine hardcoded colors für Welt-Akzente
4. **Service-Pattern**: `lib/services/live_map_pins_service.dart` und `live_caption_service.dart` als Vorlage
5. **DataChannel-Pattern**: `{type: 'xyz', ...}` in `livekit_call_service.dart` DataReceivedEvent

---

**Generiert:** 2026-05-04 von Claude (Sonnet 4.6, Session 3).
