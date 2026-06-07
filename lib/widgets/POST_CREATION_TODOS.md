# Post-Erstellung: offene Platzhalter (Stand 2026-06-07)

Sammelpunkt der `TODO`-Marker rund um den Post-Editor (create_post_dialog_v2.dart + post_creation_services.dart). Damit nichts in den 2000-Zeilen-Dateien untergeht.

## Aktive Platzhalter

### Bild-Editor (post_creation_services.dart)
- **Crop** — `post_creation_services.dart:401`
  - Aktuell: Funktion existiert als Stub.
  - Wenn implementiert: `package:image_cropper` einbinden, zugeschnittenes Bild als XFile zurueckgeben.
- **Filter** — `post_creation_services.dart:407`
  - Aktuell: Stub.
  - Wenn implementiert: `package:image` (color matrices) oder `package:flutter_image_filters`.
- **Text-Overlay** — `post_creation_services.dart:412`
  - Aktuell: Stub.
  - Wenn implementiert: Canvas-basiert (`Canvas.drawParagraph`), Bild als Layer + Text-Overlay rendern.

### Dialog-Save (create_post_dialog_v2.dart)
- **Poll-/Mention-/Schedule-Daten persistieren** — `create_post_dialog_v2.dart:523`
  - Aktuell: UI ist vorhanden, beim `_submit()` werden die Daten nicht in das Post-Insert geschrieben.
  - Wenn implementiert: `poll`, `mentions`, `scheduled_at` ins `community_posts`-Insert aufnehmen + Worker-Endpoint /api/community/posts erweitern.
- **Crop-Aufruf** — `create_post_dialog_v2.dart:1803` (TODO)
- **Text-Overlay-Aufruf** — `create_post_dialog_v2.dart:1813` (TODO)
  - Beide haengen am Bild-Editor (oben).

### Daily-Path Widget
- **Navigation zum Modul** — `daily_path_widget.dart:243`
  - Wenn `activity.moduleCode != null` ist, sollte Tap das passende Vorhang-/Ursprung-Lesson oeffnen statt nur den Aktivitaetstyp anzuzeigen.

## Erledigt 2026-06-07

- ✅ Stille `catch(_){}`-Bloecke in 65 Dateien laut gemacht (debugPrint mit Kontext).
- ✅ Account-Loeschen-Dialog: DSGVO-Hinweis (24h Loeschung, 30 Tage Backup, 90 Tage Audit-Log).
- ✅ `vorhang_chat_tab.dart` (tot) geloescht.
- ✅ `edge_confidence_aggregate` View angelegt (war Tabellen-Ref ohne Tabelle).

## Hinweis fuer naechste Iteration

Wenn der Post-Editor weiter ausgebaut wird:
- Crop ist am dringendsten (Avatar/Header-Posts wirken sonst beschnitten falsch).
- Filter und Text-Overlay sind nice-to-have und nur dann sinnvoll wenn die Community sie nachfragt.
