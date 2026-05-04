# 🎥 LiveStream High-End Roadmap — Status & offene Aufgaben

**Stand:** 2026-05-04, nach Session 4.

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
| B10.1 | Welt-Soundscape (Atmosphäre) — Dart WAV-Generator, `audioplayers` BytesSource | #93 | ✅ live |
| B10.2 | Heilfrequenz-Player (Energie-USP) — 10 Solfeggio-Frequenzen, BottomSheet-Picker | #93 | ✅ live |
| B10.4 | Co-Watch — synchronisierter YouTube-Player via LiveKit DataChannel + WebView | #94 | ✅ live |
| B10.5 | In-Call Text-Chat via DataChannel + Unread-Badge | #95 | ✅ live |
| UI-Fixes | Verständliche Button-Labels + Mehr-Optionen-Menü + Mikrofon-Default AN | #96 | 🔄 CI läuft |

**UI-Fixes (PR #96) Details:**
- TopBar: 5 icon-only Buttons → 2 sichtbar beschriftet (Ansicht, Untertitel) + "Mehr"-Menü
- "Mehr"-BottomSheet: Atmosphäre / Heilfrequenz / Nur-Audio — je mit Beschreibungstext
- ControlBar: PTT-Label → "Sprechtaste", Kamera-Labels korrekt, "Wechseln" → "Drehen", "Stop/Teilen" → "Teilen stoppen/Bildschirm"
- Pre-Join: **Mikrofon jetzt standardmäßig AN** — User kann als Zuhörer deaktivieren
- Pre-Join: Neuer Mikrofon-Toggle mit Label "Mit Mikrofon beitreten" / "Als Zuhörer beitreten"

---

## 🔴 Noch offen — Native Releases (B10.3, B10.6–B10.8) — APK-Update nötig

Diese Features brauchen native Plugins oder Audio-Assets → kein OTA-Patch möglich.
**WARNUNG:** Build-Nummer in `pubspec.yaml` bumpen + neue APK verteilen!

### B10.3 — Picture-in-Picture (nächster Schritt)
- Wenn App minimiert → Mini-Window mit aktuellem Sprecher
- Native: Android PictureInPictureParams
- Package: `flutter_pip` oder nativer MethodChannel

### B10.6 — Virtuelle Hintergründe
- VideoTrackProcessor in livekit_client
- Hintergrund-Bilder pro Welt (Sternenhimmel, Aurora, etc.)

### B10.7 — 3D-Avatar
- Audio-Level → Mund-Animation (Ready Player Me oder ähnlich)

### B10.8 — Spatial Audio
- Stereo-Pan basierend auf Tile-Position im Grid

### Recording (Server-seitig)
- LiveKit Egress API (server-side)
- Cloudflare Worker proxied Egress-Request
- Bedarf: Server-Egress-Container neben LiveKit

---

## 🎯 Architektur-Prinzipien

1. **Patch-First**: Immer prüfen ob Feature ohne Build-Nummer-Bump geht
2. **Welt-Identität**: Materie = blau/rot, Energie = lila/cyan
3. **WbDesign tokens**: Keine hardcoded colors für Welt-Akzente
4. **Service-Pattern**: `lib/services/live_map_pins_service.dart` und `live_caption_service.dart` als Vorlage
5. **DataChannel-Pattern**: `{type: 'xyz', ...}` in `livekit_call_service.dart` DataReceivedEvent
6. **TopBar-Pattern**: Wichtige Features sichtbar beschriftet (`_TopBarBtn`), seltene in "Mehr"-Sheet (`_MoreOptionTile`)
7. **Pre-Join-Pattern**: `initialMicEnabled` + `audioOnly` unabhängig voneinander → Pre-Join gibt exakte Wünsche weiter

---

**Aktualisiert:** 2026-05-04 von Claude (Sonnet 4.6, Session 4).
