'use client'

import { useState } from 'react'
import { Shield, Image, Network, Eye, ChevronRight, Loader2 } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { cn } from '@/lib/utils'

const TOOLS = [
  {
    id: 'propaganda',
    icon: <Shield size={24}/>,
    name: 'Propaganda-Detektor',
    desc: 'Analysiert Nachrichtentexte auf Manipulation, Framing und Propaganda-Techniken',
    color: '#FF5252',
    placeholder: 'Füge hier einen Nachrichtentext ein…',
    action: 'Analysieren',
  },
  {
    id: 'faktencheck',
    icon: <Eye size={24}/>,
    name: 'Fakten-Check',
    desc: 'Prüft Aussagen und Behauptungen mit alternativen Quellen',
    color: '#2196F3',
    placeholder: 'Aussage oder Behauptung eingeben…',
    action: 'Prüfen',
  },
  {
    id: 'netzwerk',
    icon: <Network size={24}/>,
    name: 'Netzwerk-Analyse',
    desc: 'Deckt Verbindungen zwischen Personen, Organisationen und Ereignissen auf',
    color: '#9C27B0',
    placeholder: 'Person, Organisation oder Ereignis eingeben…',
    action: 'Analysieren',
  },
  {
    id: 'forensics',
    icon: <Image size={24}/>,
    name: 'Image Forensics',
    desc: 'Erkennt Bildfälschungen, Deepfakes und EXIF-Manipulation',
    color: '#FF9800',
    placeholder: 'Bild-URL eingeben…',
    action: 'Analysieren',
  },
]

export default function ToolsPage() {
  const [activeTool, setActiveTool] = useState<string | null>(null)
  const [input, setInput] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<string | null>(null)

  const tool = TOOLS.find(t => t.id === activeTool)

  const handleAnalyze = async () => {
    if (!input.trim() || !activeTool) return
    setLoading(true)
    setResult(null)
    try {
      const res = await fetch('/api/tools', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ tool: activeTool, input: input.trim() }),
      })
      const data = await res.json()
      setResult(data.result || 'Keine Antwort erhalten.')
    } catch {
      setResult('Fehler bei der Analyse. Bitte versuche es erneut.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-materie-world">
      <WorldHeader world="materie" title="ANALYSE-TOOLS" showBack={!!activeTool} />
      <main className="pb-24">
        {!activeTool ? (
          <div className="px-4 py-4 space-y-3">
            <p className="text-xs text-white/30 uppercase tracking-widest font-bold mb-4">KI-gestützte Analyse-Werkzeuge</p>
            {TOOLS.map(t => (
              <button key={t.id} onClick={() => setActiveTool(t.id)}
                className="w-full flex items-center gap-4 p-4 rounded-2xl bg-surface/50 border border-white/5 hover:bg-surface/80 hover:border-white/15 active:scale-98 transition-all text-left">
                <div className="w-14 h-14 rounded-2xl flex items-center justify-center shrink-0" style={{ background: `${t.color}20`, border: `1px solid ${t.color}40` }}>
                  <span style={{ color: t.color }}>{t.icon}</span>
                </div>
                <div className="flex-1">
                  <p className="font-bold text-white">{t.name}</p>
                  <p className="text-xs text-white/40 mt-0.5 leading-relaxed">{t.desc}</p>
                </div>
                <ChevronRight size={16} className="text-white/20 shrink-0" />
              </button>
            ))}
          </div>
        ) : (
          <div className="px-4 py-4 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ background: `${tool!.color}20`, border: `1px solid ${tool!.color}40` }}>
                <span style={{ color: tool!.color }}>{tool!.icon}</span>
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
              rows={6}
              className="w-full bg-[#1A1A1A] border border-white/10 rounded-xl px-4 py-3 text-white text-sm placeholder-white/30 focus:outline-none focus:border-white/30 resize-none"
            />

            <button onClick={handleAnalyze} disabled={loading || !input.trim()}
              className={cn('w-full py-3 rounded-xl font-semibold text-sm transition-all flex items-center justify-center gap-2',
                'text-white active:scale-98',
                loading || !input.trim() ? 'opacity-50 cursor-not-allowed bg-white/10' : ''
              )}
              style={!(loading || !input.trim()) ? { background: `linear-gradient(135deg, ${tool!.color}cc, ${tool!.color}88)` } : undefined}
            >
              {loading ? <><Loader2 size={16} className="animate-spin" />Analysiere…</> : tool!.action}
            </button>

            {result && (
              <div className="rounded-2xl bg-[#0D0D0D] border border-white/10 p-4 animate-fade-in">
                <p className="text-xs text-white/30 uppercase tracking-widest font-bold mb-3">Analyse-Ergebnis</p>
                <p className="text-sm text-white/80 leading-relaxed whitespace-pre-wrap">{result}</p>
              </div>
            )}

            <button onClick={() => { setActiveTool(null); setInput(''); setResult(null) }}
              className="w-full py-2.5 rounded-xl text-sm text-white/50 hover:text-white/80 border border-white/10 transition-colors">
              Anderes Tool wählen
            </button>
          </div>
        )}
      </main>
      <BottomTabBar world="materie" />
    </div>
  )
}
