# Phase 3 - Design-System-Audit (wb_cinematic_tokens)

> Audit des bestehenden Token-Systems gegen Premium-/High-End-Standards
> (Leitplanken: impeccable, high-end-visual-design, emil-design-eng).
> Fokus: Typografie + Spacing + Tiefe + Farbe. Nur additive Fixes -- nichts
> Bestehendes gebrochen.

## Bewertung: solide Basis

`lib/theme/wb_cinematic_tokens.dart` ist bereits ein echtes Design-System
(ThemeExtension, Welt-Paletten dark+light, lerp-Animation). Das ist weit ueber
dem AI-Durchschnitt. Staerken:

- Konsistenter 4er-Spacing-Rhythmus (`WBSpace` 4/8/12/16/20/24/32/48).
- Radien-Skala (`WBRadius` 12/16/20/24/pill).
- Motion-Hierarchie (`WBMotion` Curves + Durations) -- selten so sauber.
- Welt-Identitaet ueber Paletten + `context.wb`, theme-aware Textfarben
  (`onBg`/`onBgSecondary`/`onBgHint`).

## Befunde + Massnahmen

### [BEHOBEN] 1. Tiefen-/Schattensystem fehlte
Premium-Tiefe braucht definierte, gestapelte Schatten (Ambient + Kontakt),
nicht ad-hoc-`boxShadow` pro Screen (war im Portal hart eingebaut).
-> **Neu: `WBElevation`** (`low` / `card` / `high` + `glow(color)`).
Jede Stufe: weicher Ambient- + enger Kontaktschatten. `glow()` fuer farbige
Welt-Akzent-Tiefe. Ad-hoc-Schatten koennen schrittweise darauf migriert werden.

### [BEHOBEN] 2. Typo-Skala mit Luecken
Sprung von `body` 14 direkt auf `title` 22 -- keine Zwischenstufe fuer
Abschnitts-Ueberschriften/Buttons. Ausserdem `body` ohne Zeilenhoehe (schlechte
Lesbarkeit langer Texte).
-> **Neu: `WBType.subtitle` (17) + `WBType.button` (14)**; `body` bekam
`height: 1.45`.

### [DOKUMENTIERT] 3. Display-Stile sind Dark-Theme-hart
`WBType.title/hero/body` setzen `Colors.white` fest -> im Light-Theme unsichtbar.
`context.onBg` existiert, aber `WBType` ist statisch/theme-unbewusst.
-> Hinweis im Code ergaenzt: fuer Light `.copyWith(color: context.onBg)`.
Echte Loesung (theme-aware Factory) ist groesser -> bewusst spaeter.

### [OFFEN] 4. Ad-hoc-Werte in Screens statt Tokens
Viele Screens (z.B. portal_home) nutzen rohe `Color(0x...)`/`borderRadius:18`
statt `context.wb` / `WBRadius`. Konsolidierung ist wertvoll, aber gross und
risikobehaftet -> schrittweise im Zuge weiterer Phasen, nicht in einem Rutsch.

### [OFFEN] 5. Opacity-/Scrim-Token fuer Text-ueber-Medien
Mit den neuen Cinematic-Backdrops braucht es einen Standard-Scrim-Gradient
(oben/unten abdunkeln) als Token, damit Text auf Bildern ueberall gleich
lesbar ist. -> In Phase 1 (Asset-Integration) als Token ergaenzen.

## Empfohlene Reihenfolge
1. `WBElevation` schrittweise in bestehende Karten ziehen (ersetzt ad-hoc-Schatten).
2. Scrim-Token mit der Backdrop-Integration (Phase 1).
3. Theme-aware `WBType` (Light-Fix) wenn Light-Mode aktiv beworben wird.
4. Token-Konsolidierung der Screens als laufende Hygiene.
