'use client'

import { useState, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { Sparkles, ChevronRight, Loader2 } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { cn } from '@/lib/utils'

const SPIRIT_TOOLS = [
  { id: 'chakra',     name: 'Chakra-Check',        icon: '🌈', color: '#9C27B0', desc: 'Analysiere deinen Chakra-Zustand und erhalte Empfehlungen', placeholder: 'Beschreibe dein aktuelles Befinden…' },
  { id: 'traum',      name: 'Traum-Analyse',        icon: '🌙', color: '#3F51B5', desc: 'Symbolische & spirituelle Traumdeutung',                    placeholder: 'Beschreibe deinen Traum…' },
  { id: 'meditation', name: 'Meditation-Generator', icon: '🧘', color: '#4CAF50', desc: 'Personalisierte Meditations-Skripte',                        placeholder: 'Dein Thema oder Ziel…' },
  { id: 'frequenz',   name: 'Heilfrequenzen',       icon: '🎵', color: '#FF9800', desc: 'Solfeggio-Frequenzen & Binaurale Beats',                    placeholder: 'Was möchtest du heilen oder stärken?' },
  { id: 'synchron',   name: 'Synchronizitäten',     icon: '🔮', color: '#E91E63', desc: 'Deute bedeutungsvolle Zufälle und Zeichen',                  placeholder: 'Beschreibe deine Erfahrung…' },
  { id: 'energie',    name: 'Energie-Analyse',      icon: '💫', color: '#00BCD4', desc: 'Analysiere und stärke deine persönliche Energie',           placeholder: 'Beschreibe deinen Energiezustand…' },
]

function SpiritContent() {
  const searchParams = useSearchParams()
  const initialTool = searchParams.get('tool') || ''
  const [activeTool, setActiveTool] = useState(initialTool)
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<string | null>(null)

  const tool = SPIRIT_TOOLS.find(t => t.id === activeTool)

  const handleAnalyze = async () => {
    if (!input.trim() || !activeTool) return
    setLoading(true)
    setResult(null)
    try {
      const res = await fetch('/api/spirit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: activeTool, input: input.trim() }),
      })
      const data = await res.json()
      setResult(data.result || 'Keine spirituelle Antwort erhalten.')
    } catch {
      setResult('Fehler bei der Analyse. Bitte versuche es erneut.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-energie-world">
      <WorldHeader world="energie" title="SPIRIT TOOLS" showBack={!!activeTool} />
      <main className="pb-24">
        {!activeTool ? (
          <div className="px-4 py-4 space-y-3">
            <p className="text-xs text-white/30 uppercase tracking-widest font-bold mb-4">KI-gestützte Spirit-Werkzeuge</p>
            {SPIRIT_TOOLS.map(t => (
              <button key={t.id} onClick={() => setActiveTool(t.id)}
                className="w-full flex items-center gap-4 p-4 rounded-2xl bg-surface/50 border border-white/5 hover:bg-surface/80 hover:border-white/15 active:scale-98 transition-all text-left">
                <div className="w-14 h-14 rounded-2xl flex items-center justify-center text-2xl shrink-0"
                  style={{ background: `${t.color}20`, border: `1px solid ${t.color}40` }}>
                  {t.icon}
                </div>
                <div className="flex-1">
                  <p className="font-bold text-white">{t.name}</p>
                  <p className="text-xs text-white/40 mt-0.5">{t.desc}</p>
                </div>
                <ChevronRight size={16} className="text-white/20 shrink-0" />
              </button>
            ))}
          </div>
        ) : (
          <div className="px-4 py-4 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl"
                style={{ background: `${tool!.color}20`, border: `1px solid ${tool!.color}40` }}>
                {tool!.icon}
              </div>
              <div>
                <h2 className="font-bold text-white">{tool!.name}</h2>
                <p className="text-xs text-white/40">{tool!.desc}</p>
              </div>
            </div>

            <textarea
              value={input}
              onChange={e => setInput(e.target.value)}
              placeholder={tool!.placeholder}
              rows={5}
              className="w-full bg-[#1A1A1A] border border-white/10 rounded-xl px-4 py-3 text-white text-sm placeholder-white/30 focus:outline-none focus:border-[#9C27B0]/50 resize-none"
            />

            <button onClick={handleAnalyze} disabled={loading || !input.trim()}
              className={cn('w-full py-3 rounded-xl font-semibold text-sm transition-all flex items-center justify-center gap-2 text-white active:scale-98',
                loading || !input.trim() ? 'opacity-50 cursor-not-allowed bg-white/10' : '')}
              style={!(loading || !input.trim()) ? { background: `linear-gradient(135deg, ${tool!.color}cc, ${tool!.color}88)` } : undefined}>
              {loading ? <><Loader2 size={16} className="animate-spin"/>Channeling…</> : <><Sparkles size={16}/>{tool!.name} aktivieren</>}
            </button>

            {result && (
              <div className="rounded-2xl border p-4 animate-fade-in" style={{ background: 'rgba(74,20,140,0.2)', borderColor: `${tool!.color}40` }}>
                <p className="text-xs uppercase tracking-widest font-bold mb-3" style={{ color: tool!.color }}>✨ Spirituelle Antwort</p>
                <p className="text-sm text-white/80 leading-relaxed whitespace-pre-wrap">{result}</p>
              </div>
            )}

            <button onClick={() => { setActiveTool(''); setInput(''); setResult(null) }}
              className="w-full py-2.5 rounded-xl text-sm text-white/50 hover:text-white/80 border border-white/10 transition-colors">
              Anderes Tool wählen
            </button>
          </div>
        )}
      </main>
      <BottomTabBar world="energie" />
    </div>
  )
}

export default function SpiritPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-energie-world flex items-center justify-center"><div className="w-8 h-8 border-2 border-[#9C27B0] border-t-transparent rounded-full animate-spin" /></div>}>
      <SpiritContent />
    </Suspense>
  )
}
