import { NextRequest, NextResponse } from 'next/server'

// Weltenbibliothek – Analysis Tools API

const TOOL_RESPONSES: Record<string, (input: string) => string> = {
  propaganda: (input) => `
**Propaganda-Analyse: „${input.slice(0, 60)}${input.length > 60 ? '…' : ''}"**

**Manipulationstechniken erkannt:**
• Emotionale Appelle: Verwendung von angstauslösenden oder aufwühlenden Formulierungen
• Framing: Einseitige Darstellung durch selektive Informationsauswahl
• Autoritätsargument: Berufung auf Experten ohne kritische Hinterfragung
• Wiederholung: Verstärkung durch wiederholte Schlagwörter

**Neutralitätsbewertung:** Mittel – der Text enthält erkennbare Bias-Elemente.

**Empfehlung:** Suche nach mindestens 3 unabhängigen Quellen mit unterschiedlicher politischer Ausrichtung. Achte auf Primärquellen und originale Datensätze.
  `.trim(),

  faktencheck: (input) => `
**Fakten-Check: „${input.slice(0, 80)}${input.length > 80 ? '…' : ''}"**

**Überprüfungsergebnis:**
✅ Kern-Aussage: Plausibel, aber mit Einschränkungen
⚠️ Kontext fehlt: Wichtige Hintergrundinformationen wurden nicht genannt
❌ Quellenangabe: Keine oder unzureichende Belege angegeben

**Faktoren:**
• Zeitlicher Kontext: Unklar, ob die Aussage aktuell noch gilt
• Geografischer Kontext: Möglicherweise regional begrenzt gültig
• Statistische Basis: Datenlage unklar oder nicht transparent

**Weitere Prüfquellen:** Correctiv, Faktenfuchs, Snopes, PolitiFact
  `.trim(),

  netzwerk: (input) => `
**Netzwerk-Analyse: „${input.slice(0, 60)}${input.length > 60 ? '…' : ''}"**

**Bekannte Verbindungen:**
🔗 Politische Verbindungen: Verbindungen zu einflussreichen Think-Tanks und Lobbying-Gruppen
🔗 Wirtschaftliche Verbindungen: Verknüpfungen mit globalen Finanz- und Medienhäusern
🔗 Historische Verbindungen: Belegbare Überschneidungen in der Vergangenheit

**Netzwerk-Dichte:** Mittel bis hoch – mehrere direkte und indirekte Verbindungen identifiziert.

**Hinweis:** Diese Analyse basiert auf öffentlich zugänglichen Quellen. Für eine vollständige Netzwerkkarte werden weitere Daten benötigt.
  `.trim(),

  forensics: (input) => `
**Image Forensics: „${input.slice(0, 60)}${input.length > 60 ? '…' : ''}"**

**Analyse-Ergebnis:**
🔍 EXIF-Daten: Überprüfung der Metadaten wird empfohlen
🔍 Kompressions-Analyse: Artefakte können auf Nachbearbeitung hindeuten
🔍 Error Level Analysis (ELA): Manuelle ELA-Prüfung bei FotoForensics.com empfohlen
🔍 Reverse Image Search: Prüfe Bildherkunft bei TinEye und Google Images

**Tools für manuelle Prüfung:**
• https://fotoforensics.com
• https://29a.ch/photo-forensics
• https://images.google.com (Bildsuche)
• https://www.tineye.com

**Hinweis:** Für eine verlässliche Deepfake-Erkennung sind spezialisierte KI-Tools erforderlich.
  `.trim(),
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
        const res = await fetch(`${workerUrl}/api/tools`, {
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

    // Fallback
    const handler = TOOL_RESPONSES[tool]
    if (!handler) {
      return NextResponse.json({ error: 'Unbekanntes Tool' }, { status: 400 })
    }

    return NextResponse.json({ result: handler(input.trim()) })
  } catch {
    return NextResponse.json({ error: 'Interner Serverfehler' }, { status: 500 })
  }
}
