import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// Weltenbibliothek – Recherche API
// Provides dual-perspective research results (official + alternative)
// Falls back to structured placeholder if AI worker is unavailable

const CATEGORY_MAP: Record<string, string> = {
  mondlandung: 'Raumfahrt',
  'mond-landung': 'Raumfahrt',
  '9/11': 'Geschichte',
  '11. september': 'Geschichte',
  chemtrails: 'Umwelt',
  bilderberg: 'Geopolitik',
  'deep state': 'Geopolitik',
  'neue weltordnung': 'Geopolitik',
  nwo: 'Geopolitik',
  covid: 'Gesundheit',
  corona: 'Gesundheit',
  '5g': 'Technologie',
  ufo: 'Ufologie',
  aliens: 'Ufologie',
  illuminati: 'Verschwörungen',
  freimauer: 'Verschwörungen',
  jfk: 'Geschichte',
  qanon: 'Politik',
  default: 'Allgemein',
}

function detectCategory(query: string): string {
  const q = query.toLowerCase()
  for (const [key, val] of Object.entries(CATEGORY_MAP)) {
    if (q.includes(key)) return val
  }
  return CATEGORY_MAP.default
}

function generateTags(query: string): string[] {
  const words = query.split(/\s+/).filter(w => w.length > 3)
  return words.slice(0, 5).map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
}

function generateResult(query: string) {
  const category = detectCategory(query)
  const tags = generateTags(query)

  return {
    query,
    officialPerspective: `Die offizielle Perspektive zu „${query}" basiert auf etablierten Quellen und institutionellen Berichten. Regierungen, Wissenschaftsbehörden und Mainstream-Medien vertreten eine konsensbasierte Darstellung, die auf überprüfbaren Fakten und peer-reviewten Studien aufgebaut ist. Die anerkannte wissenschaftliche Gemeinschaft hat dieses Thema mehrfach untersucht und kommt zu klar definierten Schlussfolgerungen.`,
    alternativePerspective: `Kritische Forscher und unabhängige Journalisten zeigen bei „${query}" Ungereimtheiten auf, die in der offiziellen Darstellung nicht ausreichend erklärt werden. Alternative Quellen hinterfragen Hintergründe, Motive und mögliche Interessenkonflikte. Viele Bürger weltweit zweifeln an der offiziellen Version und fordern mehr Transparenz sowie eine unabhängige Untersuchung.`,
    sources: [
      { title: `Wikipedia: ${query}`, url: `https://de.wikipedia.org/wiki/${encodeURIComponent(query)}`, type: 'official' },
      { title: `DuckDuckGo Suche: ${query}`, url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`, type: 'alternative' },
    ],
    tags,
    category,
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { query } = body

    if (!query || typeof query !== 'string' || query.trim().length < 2) {
      return NextResponse.json({ error: 'Ungültige Suchanfrage' }, { status: 400 })
    }

    const trimmedQuery = query.trim()

    // Check Supabase cache
    try {
      const supabase = createClient()
      const { data: cached } = await supabase
        .from('research_results')
        .select('*')
        .ilike('query', trimmedQuery)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (cached) {
        return NextResponse.json({
          query: cached.query,
          officialPerspective: cached.official_perspective,
          alternativePerspective: cached.alternative_perspective,
          sources: cached.sources || [],
          tags: cached.tags || [],
          category: cached.category || 'Allgemein',
        })
      }
    } catch {
      // Cache lookup failed – continue
    }

    // Try Cloudflare Worker AI (optional – graceful fallback)
    const workerUrl = process.env.CLOUDFLARE_WORKER_URL
    if (workerUrl) {
      try {
        const controller = new AbortController()
        const timeout = setTimeout(() => controller.abort(), 8000)
        const res = await fetch(`${workerUrl}/api/recherche`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: trimmedQuery }),
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

    // Fallback: generate structured response
    const result = generateResult(trimmedQuery)

    // Cache in Supabase
    try {
      const supabase = createClient()
      await supabase.from('research_results').insert({
        query: result.query,
        world: 'materie',
        official_perspective: result.officialPerspective,
        alternative_perspective: result.alternativePerspective,
        sources: result.sources,
        tags: result.tags,
        category: result.category,
      })
    } catch {
      // Cache write failed – ignore
    }

    return NextResponse.json(result)
  } catch {
    return NextResponse.json({ error: 'Interner Serverfehler' }, { status: 500 })
  }
}
