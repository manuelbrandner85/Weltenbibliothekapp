'use client'

import { useRouter } from 'next/navigation'
import { Sparkles, MessageSquare, Map, BookOpen, ChevronRight, Globe } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'

const quickCards = [
  { icon: <Sparkles size={22}/>,      label: 'Spirit-Tools',  desc: 'Chakra, Meditation & Frequenzen', href: '/energie/spirit',    color: '#CE93D8', bg: 'rgba(156,39,176,0.15)' },
  { icon: <MessageSquare size={22}/>, label: 'Community',     desc: 'Spirituelle Diskussionen',         href: '/energie/community', color: '#E91E63', bg: 'rgba(233,30,99,0.15)' },
  { icon: <Map size={22}/>,           label: 'Karte',         desc: 'Kraftorte & Ley-Linien',           href: '/energie/karte',     color: '#FFD700', bg: 'rgba(255,215,0,0.15)' },
  { icon: <BookOpen size={22}/>,      label: 'Wissen',        desc: 'Spirituelle Bibliothek',           href: '/energie/wissen',    color: '#4CAF50', bg: 'rgba(76,175,80,0.15)' },
]

const spiritRooms = [
  { id: 'bewusstsein', name: 'Bewusstsein',   icon: '🧠', color: '#9C27B0' },
  { id: 'meditation',  name: 'Meditation',    icon: '🧘', color: '#7B1FA2' },
  { id: 'heilung',     name: 'Heilung',       icon: '💫', color: '#E91E63' },
  { id: 'träume',      name: 'Traumdeutung',  icon: '🌙', color: '#3F51B5' },
  { id: 'kristalle',   name: 'Kristalle',     icon: '💎', color: '#00BCD4' },
  { id: 'kraftorte',   name: 'Kraftorte',     icon: '🗺️', color: '#FFD700' },
]

const spiritTools = [
  { id: 'chakra',    name: 'Chakra-Check',           icon: '🌈', color: '#9C27B0' },
  { id: 'traum',     name: 'Traum-Analyse',           icon: '🌙', color: '#3F51B5' },
  { id: 'meditation',name: 'Meditation-Generator',    icon: '🧘', color: '#4CAF50' },
  { id: 'frequenz',  name: 'Heilfrequenzen',          icon: '🎵', color: '#FF9800' },
]

export function EnergieHomeTab() {
  const { profile } = useAuth()
  const router = useRouter()

  return (
    <div className="px-4 py-4 space-y-6">

      {/* Welcome Banner */}
      <div
        className="rounded-2xl p-4 relative overflow-hidden"
        style={{ background: 'linear-gradient(135deg, rgba(74,20,140,0.6) 0%, rgba(123,31,162,0.4) 100%)', border: '1px solid rgba(156,39,176,0.3)' }}
      >
        <div className="absolute top-0 right-0 w-32 h-32 rounded-full opacity-10 blur-2xl" style={{ background: '#9C27B0' }} />
        <p className="text-xs text-[#CE93D8] font-bold tracking-widest uppercase mb-1">Energie-Welt</p>
        <h2 className="text-xl font-black text-white leading-tight">
          {profile ? `Willkommen, ${profile.display_name || profile.username}` : 'Willkommen zurück'}
        </h2>
        <p className="text-sm text-white/60 mt-1">Erkunde Spiritualität, Mystik & Bewusstsein</p>

        {/* Energy symbols */}
        <div className="flex gap-3 mt-3">
          {['✨', '🌙', '🌟', '💫', '🔮'].map((sym, i) => (
            <span key={i} className="text-xl opacity-60">{sym}</span>
          ))}
        </div>
      </div>

      {/* Quick Access */}
      <div>
        <h3 className="text-xs font-bold text-white/40 uppercase tracking-widest mb-3">Schnellzugriff</h3>
        <div className="grid grid-cols-2 gap-3">
          {quickCards.map(card => (
            <button key={card.label} onClick={() => router.push(card.href)}
              className="flex items-center gap-3 p-3.5 rounded-xl border border-white/10 hover:border-white/20 active:scale-95 transition-all duration-200 text-left"
              style={{ background: card.bg }}>
              <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: `${card.color}25` }}>
                <span style={{ color: card.color }}>{card.icon}</span>
              </div>
              <div className="min-w-0">
                <p className="text-sm font-bold text-white truncate">{card.label}</p>
                <p className="text-[10px] text-white/40 truncate">{card.desc}</p>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Spirit Tools */}
      <div>
        <h3 className="text-xs font-bold text-white/40 uppercase tracking-widest mb-3">Spirit-Tools</h3>
        <div className="grid grid-cols-2 gap-2">
          {spiritTools.map(tool => (
            <button key={tool.id} onClick={() => router.push(`/energie/spirit?tool=${tool.id}`)}
              className="flex items-center gap-2 p-3 rounded-xl bg-surface/50 border border-white/5 hover:border-white/15 active:scale-95 transition-all">
              <span className="text-xl">{tool.icon}</span>
              <span className="text-sm font-medium text-white/80">{tool.name}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Spirit Rooms */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-xs font-bold text-white/40 uppercase tracking-widest">Spirit-Räume</h3>
          <button onClick={() => router.push('/energie/community')} className="text-xs text-[#CE93D8] flex items-center gap-1">
            Alle <ChevronRight size={12}/>
          </button>
        </div>
        <div className="space-y-2">
          {spiritRooms.map(room => (
            <button key={room.id} onClick={() => router.push(`/energie/community?room=${room.id}`)}
              className="w-full flex items-center gap-3 p-3 rounded-xl bg-surface/50 border border-white/5 hover:bg-surface/80 hover:border-white/15 active:scale-98 transition-all duration-200">
              <div className="w-10 h-10 rounded-xl flex items-center justify-center text-lg shrink-0"
                style={{ background: `${room.color}20`, border: `1px solid ${room.color}40` }}>
                {room.icon}
              </div>
              <div className="flex-1 text-left">
                <p className="text-sm font-semibold text-white">{room.name}</p>
                <p className="text-xs text-white/30">Energie-Welt</p>
              </div>
              <ChevronRight size={16} className="text-white/20" />
            </button>
          ))}
        </div>
      </div>

      {/* Tagesenergie */}
      <div className="rounded-2xl p-4 border border-[#9C27B0]/30 bg-[#4A148C]/10">
        <p className="text-xs text-[#CE93D8] font-bold uppercase tracking-widest mb-2">✨ Tagesenergie</p>
        <p className="text-sm text-white/70 leading-relaxed">
          Heute steht im Zeichen des inneren Bewusstseins. Die kosmischen Energien unterstützen tiefe Reflexion und spirituelles Wachstum. Nutze diese Zeit für Meditation und innere Einkehr.
        </p>
      </div>

      {/* Switch to Materie */}
      <button onClick={() => router.push('/materie')}
        className="w-full flex items-center gap-3 p-4 rounded-2xl border border-[#2196F3]/30 bg-[#0D47A1]/20 hover:bg-[#0D47A1]/30 active:scale-98 transition-all">
        <Globe size={20} className="text-[#64B5F6]" />
        <div className="flex-1 text-left">
          <p className="text-sm font-bold text-[#64B5F6]">Zur Materie-Welt wechseln</p>
          <p className="text-xs text-white/30">Wissen · Logik · Fakten</p>
        </div>
        <ChevronRight size={16} className="text-[#2196F3]/60" />
      </button>

    </div>
  )
}
