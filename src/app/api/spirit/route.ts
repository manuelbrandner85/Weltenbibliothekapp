import { NextRequest, NextResponse } from 'next/server'

// Weltenbibliothek – Spirit Tools API

type SpiritTool = 'chakra' | 'traum' | 'meditation' | 'frequenz' | 'synchron' | 'energie'

function chakraAnalysis(input: string): string {
  return `
**🌈 Chakra-Analyse**

Basierend auf deiner Beschreibung: „${input.slice(0, 80)}…"

**Energie-Zustand:**
🔴 Wurzelchakra (Muladhara): Gute Erdung – deine Grundsicherheit ist stabil
🟠 Sakralchakra (Svadhisthana): Leichte Blockade – kreative Energie braucht Freiraum
🟡 Solarplexuschakra (Manipura): Aktiviert – deine Willenskraft ist präsent
🟢 Herzchakra (Anahata): Öffnung empfohlen – mehr Selbstliebe kultivieren
🔵 Halschakra (Vishuddha): Balanced – du drückst dich klar aus
🟣 Stirnchakra (Ajna): Intensiv aktiv – deine Intuition meldet sich
⚪ Kronenchakra (Sahasrara): In Entwicklung – spirituelle Verbindung wächst

**Empfehlung:** Fokussiere diese Woche auf dein Herzchakra. Übe 10 Minuten täglich Atem-Meditation mit grüner Visualisierung.
  `.trim()
}

function dreamAnalysis(input: string): string {
  return `
**🌙 Traum-Analyse**

Trauminhalt: „${input.slice(0, 80)}…"

**Symbolik:**
✨ Dein Traum zeigt intensive emotionale Verarbeitung aktueller Lebenssituationen.

**Kern-Symbole erkannt:**
• Transformation: Hinweis auf bevorstehende Veränderungen in deinem Leben
• Tieferes Selbst: Dein Unterbewusstsein verarbeitet ungelöste Themen
• Energie: Die vorhandene Dynamik weist auf inneres Wachstum hin

**Jungianische Interpretation:**
Der Traum aktiviert den Archetyp des Wandels. Dein inneres Kind sucht Ausdruck und Verarbeitung.

**Empfehlung:** Schreibe den Traum detailliert auf. Meditiere 5 Minuten über das stärkste Symbol. Was fühlt es für dich in deinem Wachleben?
  `.trim()
}

function meditationGenerator(input: string): string {
  return `
**🧘 Deine persönliche Meditation**

Intention: „${input.slice(0, 60)}…"

**Geführte Meditation (10 Minuten):**

*Setze oder lege dich bequem. Schließe die Augen.*

1. **Ankunft (2 Min):** Atme dreimal tief ein und aus. Spüre deinen Körper, die Stellen wo er Kontakt mit dem Boden hat. Du bist hier. Du bist sicher.

2. **Reinigung (3 Min):** Stelle dir vor, wie goldenes Licht von oben durch deinen Scheitel einströmt. Es fließt durch jeden Teil deines Körpers und reinigt alles, was du loslassen möchtest.

3. **Intention (3 Min):** Bringe deine Intention „${input.slice(0, 40)}" in dein Herzchakra. Spüre, wie sie sich in deinem Herzzentrum ausbreitet wie Wärme.

4. **Integration (2 Min):** Lass das Licht wieder abklingen. Komme langsam zurück. Bewege deine Finger und Zehen. Öffne die Augen.

**Frequenz-Empfehlung:** 528 Hz (Heilfrequenz)
  `.trim()
}

function frequencyGuide(input: string): string {
  return `
**🎵 Heilfrequenz-Empfehlung**

Kontext: „${input.slice(0, 60)}…"

**Empfohlene Frequenzen:**

| Frequenz | Wirkung | Empfehlung |
|----------|---------|------------|
| **174 Hz** | Schmerzlinderung, Sicherheit | ⭐⭐⭐ |
| **285 Hz** | Zellregeneration, Heilung | ⭐⭐⭐⭐ |
| **396 Hz** | Befreiung von Angst und Schmerz | ⭐⭐⭐⭐⭐ |
| **417 Hz** | Auflösung negativer Energie | ⭐⭐⭐ |
| **432 Hz** | Harmonie, Naturresonanz | ⭐⭐⭐⭐⭐ |
| **528 Hz** | DNA-Reparatur, Transformation | ⭐⭐⭐⭐⭐ |
| **639 Hz** | Verbindung, Beziehungen | ⭐⭐⭐⭐ |
| **741 Hz** | Ausdruck, Lösungen | ⭐⭐⭐ |
| **852 Hz** | Intuition, geistiges Erwachen | ⭐⭐⭐⭐ |
| **963 Hz** | Göttliches Bewusstsein | ⭐⭐⭐ |

**Beste Empfehlung für dich:** 528 Hz – Transformation und Heilung
Höre täglich 20-30 Minuten mit Kopfhörern. Suchbegriff: "528 Hz Healing Frequency" auf YouTube.
  `.trim()
}

function synchronAnalysis(input: string): string {
  return `
**🔮 Synchronizitäten-Deutung**

Erfahrung: „${input.slice(0, 80)}…"

**Quantenfeld-Perspektive:**
✨ Synchronizitäten sind keine Zufälle – sie sind bedeutungsvolle Koinzidenzen, die auf eine tiefere Verbindung zwischen innerer Welt und äußerer Realität hinweisen.

**Analyse deiner Erfahrung:**
🌀 Energetische Signatur: Hoch – starke Resonanz im Morphogenfeld
🔗 Verbindungsmuster: Dein Unterbewusstsein zieht Informationen an, die zu deinem aktuellen inneren Zustand passen
⚡ Intensität: Diese Synchronizität hat eine Botschaft für dich

**Jung'sche Interpretation:**
Carl Gustav Jung beschrieb Synchronizitäten als "bedeutungsvolle Zufälle" – das kollektive Unbewusste kommuniziert durch symbolische Ereignisse.

**Deine Botschaft:**
Die Situation spiegelt einen unbewussten Prozess in dir wider. Achte auf wiederkehrende Symbole, Zahlen oder Themen in den nächsten 7 Tagen.

**Empfehlung:** Führe ein Synchronizitäts-Tagebuch. Notiere täglich auffällige Koinzidenzen und suche nach Mustern.
  `.trim()
}

function energieAnalysis(input: string): string {
  return `
**💫 Energie-Analyse**

Zustandsbeschreibung: „${input.slice(0, 80)}…"

**Aurica-Scan (Energiefeld-Analyse):**
🟡 Solar Plexus: Leichte Überaktivität – Willenskraft und Kontrolle im Fokus
💙 Halsbereich: Kommunikations-Energie sucht Ausdruck
💜 Kronenchakra: Öffnung zu höheren Frequenzen erkennbar
🌊 Emotionale Schicht: Transformationsprozess aktiv

**Energetische Blockaden erkannt:**
• Alte Glaubensmuster begrenzen den freien Energiefluss
• Emotionale Ablagerungen im Sakralbereich
• Mentale Überbelastung schwächt das Aura-Feld

**Stärkungs-Protokoll:**
1. Erdungsübung: 10 Minuten barfuß auf natürlichem Boden
2. Atemarbeit: 4-7-8 Methode (3x täglich)  
3. Kristall-Support: Schwarzer Turmalin für Schutz, Rosenquarz für Herzöffnung
4. Klangbad: 432 Hz oder 528 Hz Frequenz täglich 20 Min.
5. Intention setzen: "Meine Energie fließt frei und kraftvoll"

**Positive Prognose:** In 7-14 Tagen deutliche Energie-Steigerung bei konsequenter Praxis.
  `.trim()
}

const HANDLERS: Record<SpiritTool, (input: string) => string> = {
  chakra: chakraAnalysis,
  traum: dreamAnalysis,
  meditation: meditationGenerator,
  frequenz: frequencyGuide,
  synchron: synchronAnalysis,
  energie: energieAnalysis,
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { tool, input } = body

    if (!tool || !input || typeof input !== 'string') {
      return NextResponse.json({ error: 'Ungültige Anfrage' }, { status: 400 })
    }

    // Try Cloudflare Worker (optional)
    const workerUrl = process.env.CLOUDFLARE_WORKER_URL
    if (workerUrl) {
      try {
        const controller = new AbortController()
        const timeout = setTimeout(() => controller.abort(), 8000)
        const res = await fetch(`${workerUrl}/api/spirit`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ tool, input }),
          signal: controller.signal,
        })
        clearTimeout(timeout)
        if (res.ok) {
          const data = await res.json()
          return NextResponse.json(data)
        }
      } catch {
        // Worker unavailable – use fallback
      }
    }

    const handler = HANDLERS[tool as SpiritTool]
    if (!handler) {
      return NextResponse.json({ error: 'Unbekanntes Tool' }, { status: 400 })
    }

    return NextResponse.json({ result: handler(input.trim()) })
  } catch {
    return NextResponse.json({ error: 'Interner Serverfehler' }, { status: 500 })
  }
}
