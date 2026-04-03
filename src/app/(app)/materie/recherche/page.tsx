'use client'

import { useState, useRef, useEffect, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { Search, X, Loader2, AlertCircle, Globe, ChevronDown, ChevronUp, BookOpen, ExternalLink } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { createClient } from '@/lib/supabase/client'
import { cn } from '@/lib/utils'

interface SearchResult {
  query: string
  officialPerspective: string
  alternativePerspective: string
  sources: Array<{ title: string; url: string; type: string }>
  tags: string[]
  category: string
}

const EXAMPLE_QUERIES = [
  'Mondlandung', '9/11', 'Chemtrails', 'Bilderberg', 'Deep State',
  'Neue Weltordnung', 'COVID Ursprung', 'JFK Attentat', '5G Netz',
]

function RechercheContent() {
  const searchParams = useSearchParams()
  const initialQ = searchParams.get('q') || ''
  const [query, setQuery] = useState(initialQ)
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<SearchResult | null>(null)
  const [error, setError] = useState('')
  const [showOfficial, setShowOfficial] = useState(true)
  const [showAlternative, setShowAlternative] = useState(true)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (initialQ) handleSearch(initialQ)
  }, []) // eslint-disable-line

  const handleSearch = async (q?: string) => {
    const searchQuery = q || query
    if (!searchQuery.trim()) return

    setLoading(true)
    setError('')
    setResult(null)

    try {
      const supabase = createClient()

      // Check cache first
      const { data: cached } = await supabase
        .from('research_results')
        .select('*')
        .ilike('query', searchQuery.trim())
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (cached) {
        setResult({
          query: cached.query,
          officialPerspective: cached.official_perspective,
          alternativePerspective: cached.alternative_perspective,
          sources: cached.sources || [],
          tags: cached.tags || [],
          category: cached.category || 'Allgemein',
        })
        return
      }

      // Call Cloudflare AI via Worker
      const res = await fetch('/api/recherche', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: searchQuery.trim() }),
      })

      if (!res.ok) throw new Error('Recherche fehlgeschlagen')

      const data = await res.json()
      setResult(data)

    } catch (err) {
      setError('Die Recherche konnte nicht durchgeführt werden. Bitte versuche es erneut.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-materie-world">
      <WorldHeader world="materie" title="RECHERCHE" showBack />
      <main className="pb-24">

        {/* Search Bar */}
        <div className="sticky top-14 z-30 px-4 py-3 bg-[#0A0A0A]/90 backdrop-blur-xl border-b border-white/5">
          <div className="relative">
            <Search size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#64B5F6]" />
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleSearch()}
              placeholder="Thema, Ereignis oder Begriff eingeben…"
              className="w-full bg-[#1A1A1A] border border-[#2196F3]/30 rounded-xl pl-10 pr-10 py-3 text-white placeholder-white/30 focus:outline-none focus:border-[#2196F3]/60 focus:ring-1 focus:ring-[#2196F3]/30 text-sm"
            />
            {query && (
              <button onClick={() => { setQuery(''); setResult(null); inputRef.current?.focus() }}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-white/30 hover:text-white/60">
                <X size={16} />
              </button>
            )}
          </div>
          <button
            onClick={() => handleSearch()}
            disabled={loading || !query.trim()}
            className={cn(
              'mt-2 w-full py-2.5 rounded-xl font-semibold text-sm transition-all',
              'bg-[#1976D2] hover:bg-[#2196F3] text-white active:scale-98',
              (loading || !query.trim()) && 'opacity-50 cursor-not-allowed'
            )}
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <Loader2 size={16} className="animate-spin" /> Analysiere…
              </span>
            ) : 'Recherche starten'}
          </button>
        </div>

        <div className="px-4 py-4 space-y-4">

          {/* Example queries */}
          {!result && !loading && (
            <div>
              <p className="text-xs text-white/30 uppercase tracking-widest mb-3 font-bold">Beispiel-Themen</p>
              <div className="flex flex-wrap gap-2">
                {EXAMPLE_QUERIES.map(q => (
                  <button
                    key={q}
                    onClick={() => { setQuery(q); handleSearch(q) }}
                    className="px-3 py-1.5 rounded-full text-xs bg-[#1976D2]/20 text-[#64B5F6] border border-[#2196F3]/20 hover:bg-[#1976D2]/40 transition-all active:scale-95"
                  >
                    {q}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Loading */}
          {loading && (
            <div className="flex flex-col items-center gap-4 py-16">
              <div className="w-16 h-16 rounded-full border-2 border-[#2196F3]/20 border-t-[#2196F3] animate-spin" />
              <div className="text-center">
                <p className="text-white font-medium">Analysiere: „{query}"</p>
                <p className="text-white/40 text-sm mt-1">Durchsuche offizielle & alternative Quellen…</p>
              </div>
            </div>
          )}

          {/* Error */}
          {error && (
            <div className="flex items-start gap-3 bg-[#FF5252]/10 border border-[#FF5252]/30 rounded-xl p-4">
              <AlertCircle size={18} className="text-[#FF5252] mt-0.5 shrink-0" />
              <div>
                <p className="text-[#FF5252] font-medium text-sm">Fehler</p>
                <p className="text-white/60 text-sm mt-0.5">{error}</p>
              </div>
            </div>
          )}

          {/* Result */}
          {result && !loading && (
            <div className="space-y-4 animate-fade-in">
              {/* Query header */}
              <div className="flex items-center gap-2">
                <Globe size={16} className="text-[#64B5F6]" />
                <h2 className="text-base font-bold text-white">„{result.query}"</h2>
                <span className="text-xs px-2 py-0.5 rounded-full bg-[#2196F3]/20 text-[#64B5F6] ml-auto">{result.category}</span>
              </div>

              {/* Tags */}
              {result.tags.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {result.tags.map(t => (
                    <span key={t} className="text-xs px-2 py-0.5 rounded-full bg-white/5 text-white/40 border border-white/10">#{t}</span>
                  ))}
                </div>
              )}

              {/* Official Perspective */}
              <div className="rounded-2xl overflow-hidden border border-[#4CAF50]/30">
                <button
                  onClick={() => setShowOfficial(v => !v)}
                  className="w-full flex items-center gap-3 px-4 py-3 bg-[#4CAF50]/10 hover:bg-[#4CAF50]/15 transition-colors"
                >
                  <div className="w-8 h-8 rounded-lg bg-[#4CAF50]/20 flex items-center justify-center shrink-0">
                    <BookOpen size={16} className="text-[#4CAF50]" />
                  </div>
                  <div className="flex-1 text-left">
                    <p className="text-xs text-[#81C784] font-bold uppercase tracking-wider">Offizielle Perspektive</p>
                    <p className="text-xs text-white/30">Mainstream-Quellen</p>
                  </div>
                  {showOfficial ? <ChevronUp size={16} className="text-white/30" /> : <ChevronDown size={16} className="text-white/30" />}
                </button>
                {showOfficial && (
                  <div className="px-4 py-4 bg-[#0D0D0D]">
                    <p className="text-sm text-white/80 leading-relaxed">{result.officialPerspective}</p>
                  </div>
                )}
              </div>

              {/* Alternative Perspective */}
              <div className="rounded-2xl overflow-hidden border border-[#FF5252]/30">
                <button
                  onClick={() => setShowAlternative(v => !v)}
                  className="w-full flex items-center gap-3 px-4 py-3 bg-[#FF5252]/10 hover:bg-[#FF5252]/15 transition-colors"
                >
                  <div className="w-8 h-8 rounded-lg bg-[#FF5252]/20 flex items-center justify-center shrink-0">
                    <Search size={16} className="text-[#FF5252]" />
                  </div>
                  <div className="flex-1 text-left">
                    <p className="text-xs text-[#EF9A9A] font-bold uppercase tracking-wider">Alternative Perspektive</p>
                    <p className="text-xs text-white/30">Kritische Quellen</p>
                  </div>
                  {showAlternative ? <ChevronUp size={16} className="text-white/30" /> : <ChevronDown size={16} className="text-white/30" />}
                </button>
                {showAlternative && (
                  <div className="px-4 py-4 bg-[#0D0D0D]">
                    <p className="text-sm text-white/80 leading-relaxed">{result.alternativePerspective}</p>
                  </div>
                )}
              </div>

              {/* Sources */}
              {result.sources.length > 0 && (
                <div>
                  <p className="text-xs text-white/30 uppercase tracking-widest font-bold mb-2">Quellen</p>
                  <div className="space-y-2">
                    {result.sources.map((src, i) => (
                      <a key={i} href={src.url} target="_blank" rel="noopener noreferrer"
                        className="flex items-center gap-2 p-2.5 rounded-lg bg-white/5 border border-white/5 hover:border-white/15 transition-colors">
                        <ExternalLink size={14} className="text-white/30 shrink-0" />
                        <span className="text-xs text-white/60 truncate">{src.title}</span>
                        <span className={cn(
                          'text-[10px] px-1.5 py-0.5 rounded ml-auto shrink-0',
                          src.type === 'official' ? 'bg-[#4CAF50]/20 text-[#81C784]' : 'bg-[#FF5252]/20 text-[#EF9A9A]'
                        )}>{src.type}</span>
                      </a>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

        </div>
      </main>
      <BottomTabBar world="materie" />
    </div>
  )
}

export default function RecherchePage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-materie-world flex items-center justify-center"><div className="w-8 h-8 border-2 border-[#2196F3] border-t-transparent rounded-full animate-spin" /></div>}>
      <RechercheContent />
    </Suspense>
  )
}
