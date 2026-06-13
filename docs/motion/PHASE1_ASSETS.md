# Phase 1 - Cinematic-Assets (Higgsfield) - Ausfuehrungs-Spec

> Status: BEREIT ZUR GENERIERUNG. Higgsfield-MCP ist verbunden, wird aber erst
> in einer **neuen Session** sichtbar. In der neuen Session: diese Datei lesen,
> dann die 6 Assets generieren, komprimieren und integrieren.

## Kontext

App: Weltenbibliothek (spirituell-investigativ, 4 Welten). Zielgruppe alle
Altersgruppen, oft schwache Geraete -> **Performance/Akku haben Vorrang**.
Umfang bewusst schlank gewaehlt (Restraint): **1 Video-Loop + 5 Stills**.
Bestehende Assets: assets/videos/ enthaelt bereits Intro + 2 Welt-Uebergaenge
(~6,5 MB). Neue Assets duerfen die APK nur minimal vergroessern.

## Welt-Paletten (aus lib/theme/wb_cinematic_tokens.dart, Dark-Theme)

| Welt     | Thema                       | Primary    | Deep       |
|----------|-----------------------------|------------|------------|
| materie  | Recherche/OSINT/Fakten      | #3B82F6 Blau   | #0A2452 |
| energie  | Meditation/Chakren          | #A855F7 Violett| #3B0D6E |
| vorhang  | Machtpsychologie            | #C9A84C Gold   | #1A1500 |
| ursprung | Bewusstsein/Hermetik        | #00D4AA Tuerkis| #002B22 |
| BG-Void  | -                           | #000004 Near-Black       |

Look: tief, kosmisch, Premium-Jewel-Tone, vertrauenswuerdig. KEIN "warmes
Abendlicht". Alle Stills mit Negativraum + dunkleren Raendern oben/unten fuer
Text-Lesbarkeit. Alle Videos stumm, nahtloser Loop, KEIN Text im Bild.

## Asset-Liste + Higgsfield-Prompts

### 1. Portal-Ambient-Loop (Video, 9:16, ~5 s, nahtlos, stumm)
Ziel-Datei: `assets/videos/portal_ambient_loop.mp4`
Fallback-Still: `assets/images/portal_ambient_fallback.webp`
Prompt:
> Cinematic vertical loop, a vast dark cosmic library floating in deep space,
> near-black background (#000004). Four luminous orbs slowly pulsing in distinct
> jewel colors - sapphire blue, violet, gold, emerald teal - connected by faint
> threads of light. Slow drifting dust particles, subtle volumetric glow,
> premium and trustworthy mood, seamless loop, no text, shallow depth of field,
> 4-6 seconds.

### 2. Welt-Still materie (Bild, 9:16)
Ziel-Datei: `assets/images/world_materie.webp`
Prompt:
> Vertical abstract atmosphere, deep navy (#0A2452) to near-black, cool
> sapphire-blue (#3B82F6) light, faint constellation and data-thread motifs,
> investigative and clear, premium, generous negative space, no text.

### 3. Welt-Still energie (Bild, 9:16)
Ziel-Datei: `assets/images/world_energie.webp`
Prompt:
> Vertical abstract atmosphere, deep violet (#3B0D6E) to black, glowing amethyst
> (#A855F7) aura, soft flowing energy, calm and spiritual, premium, generous
> negative space, no text.

### 4. Welt-Still vorhang (Bild, 9:16)
Ziel-Datei: `assets/images/world_vorhang.webp`
Prompt:
> Vertical abstract atmosphere, near-black (#1A1500), dramatic gold (#C9A84C)
> light through a subtle curtain motif, mysterious and powerful, premium,
> generous negative space, no text.

### 5. Welt-Still ursprung (Bild, 9:16)
Ziel-Datei: `assets/images/world_ursprung.webp`
Prompt:
> Vertical abstract atmosphere, deep teal-black (#002B22), luminous emerald
> (#00D4AA) glow, subtle sacred-geometry gateway hint, transcendent and vast,
> premium, generous negative space, no text.

### 6. Onboarding-Mood-Still (Bild, 9:16)
Ziel-Datei: `assets/images/onboarding_mood.webp`
Prompt:
> Vertical premium cosmic scene, all four jewel colors (blue, violet, gold,
> teal) harmonized around a single bright point of light, inviting and
> trustworthy, deep space, generous negative space for a headline, no text.

## Ziel-Specs + Komprimierung (nach Generierung)

Video-Loop (ffmpeg):
```bash
ffmpeg -i raw_loop.mp4 -an -vf "scale=720:1280:flags=lanczos" \
  -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 27 \
  -movflags +faststart portal_ambient_loop.mp4
# Ziel: < 1,5 MB. Falls groesser: crf 29-30 oder Laenge kuerzen.
```
Fallback-Still aus Loop (mittlerer Frame):
```bash
ffmpeg -i portal_ambient_loop.mp4 -vf "select=eq(n\,60)" -vframes 1 \
  -c:v libwebp -quality 80 portal_ambient_fallback.webp
```
Stills (jeweils):
```bash
cwebp -q 80 -resize 1280 0 raw_still.png -o world_xxx.webp
# Ziel: < 150 KB pro Still.
```

## Integration in Flutter (Phase 1 Abschluss)

1. Neue Pfade in `pubspec.yaml` unter `flutter: assets:` ergaenzen
   (assets/images/ ist bereits gelistet; assets/videos/ Eintraege einzeln).
2. Adaptive Anzeige - **Pflicht** (Akku/Schwachgeraete):
   - Auf schwachen Geraeten / Reduce-Motion / Akkusparmodus / Ladefehler ->
     statt Loop das Standbild zeigen. Nie leerer Screen, nie Ruckeln.
   - Geraete-Tier ueber bestehendes System pruefen (siehe lib/core/ und
     widgets/cinematic/cinematic_settings.dart). Falls kein DeviceTier
     existiert: in Phase 5 (Qualitaetssystem) nachruesten, vorerst konservativ
     defaulten (Still bevorzugen).
3. Portal-Loop als Hintergrund im Portal-Home (screens/portal_home_screen.dart),
   Welt-Stills als Backdrop/Empty-State pro Welt, Onboarding-Still im Erststart.
4. Build-Nummer in pubspec NICHT aendern (reine Asset/Dart-Aenderung).
   Shorebird: ⚠️ Neuer Release noetig, sobald neue Assets gebundelt werden
   (Assets sind nicht patchbar via OTA).

## Naechste Phasen (nach Asset-Integration)

- Phase 3: Audit wb_cinematic_tokens mit Taste-Skills (impeccable, taste-skill).
- Phase 4: flutter_animate einfuehren, Spring/Staggered an Schluesselscreens.
- Phase 5: Adaptives Qualitaetssystem (DeviceTier + ReduceMotion), 60/120 FPS.
