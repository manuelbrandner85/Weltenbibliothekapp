'use client'

import { useState } from 'react'
import { MapPin, Filter, ChevronRight, Search, Navigation } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'

const KRAFTORTE = [
  { id: '1', name: 'Stonehenge',           country: 'England',      icon: '🗿', type: 'Megalith',    lat: 51.18, lng: -1.83,  color: '#FFD700', desc: 'Prähistorische Megalithanlage – stärkster Ley-Linien-Knotenpunkt Europas' },
  { id: '2', name: 'Externsteine',         country: 'Deutschland',  icon: '🪨', type: 'Kraftstein',  lat: 51.87, lng: 8.92,   color: '#FF9800', desc: 'Germanisches Heiligtum im Teutoburger Wald' },
  { id: '3', name: 'Machu Picchu',         country: 'Peru',         icon: '🏛️', type: 'Tempel',     lat: -13.16, lng: -72.54, color: '#4CAF50', desc: 'Heilige Inka-Stätte auf 2430m Höhe' },
  { id: '4', name: 'Mount Shasta',         country: 'USA',          icon: '🏔️', type: 'Berg',        lat: 41.41, lng: -122.19, color: '#2196F3', desc: 'Spiritueller Kraftberg Nordamerikas' },
  { id: '5', name: 'Glastonbury',          country: 'England',      icon: '🌀', type: 'Chakra-Punkt', lat: 51.14, lng: -2.71,  color: '#9C27B0', desc: 'Herz-Chakra der Erde' },
  { id: '6', name: 'Chichén Itzá',         country: 'Mexiko',       icon: '🔺', type: 'Pyramide',    lat: 20.68, lng: -88.56,  color: '#FF5252', desc: 'Maya-Pyramide mit astronomischer Präzision' },
  { id: '7', name: 'Lake Titicaca',        country: 'Peru/Bolivien',icon: '💧', type: 'Wasserkraft',  lat: -15.84, lng: -69.33, color: '#00BCD4', desc: 'Höchster schiffbarer See der Welt – Solar-Plexus der Erde' },
  { id: '8', name: 'Sedona',              country: 'USA',           icon: '🔴', type: 'Vortex',      lat: 34.87, lng: -111.76, color: '#FF5252', desc: '4 starke Energievortexe in der roten Felsenlandschaft' },
]

const TYPES = ['Alle', 'Megalith', 'Tempel', 'Berg', 'Vortex', 'Chakra-Punkt', 'Pyramide']

export default function EnergieKartePage() {
  const [search, setSearch] = useState('')
  const [activeType, setActiveType] = useState('Alle')

  const filtered = KRAFTORTE.filter(k => {
    const matchSearch = !search || k.name.toLowerCase().includes(search.toLowerCase()) || k.country.toLowerCase().includes(search.toLowerCase())
    const matchType = activeType === 'Alle' || k.type === activeType
    return matchSearch && matchType
  })

  return (
    <div className="min-h-screen bg-energie-world">
      <WorldHeader world="energie" title="KARTE" showBack />
      <main className="pb-24">

        {/* Map placeholder */}
        <div
          className="h-48 relative overflow-hidden flex items-center justify-center"
          style={{ background: 'linear-gradient(135deg, #1a237e 0%, #4A148C 50%, #0A0A0A 100%)' }}
        >
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-4 left-8 w-2 h-2 bg-[#FFD700] rounded-full animate-pulse-soft" />
            <div className="absolute top-12 right-16 w-2 h-2 bg-[#9C27B0] rounded-full animate-pulse-soft" style={{ animationDelay: '0.5s' }} />
            <div className="absolute bottom-8 left-1/3 w-2 h-2 bg-[#2196F3] rounded-full animate-pulse-soft" style={{ animationDelay: '1s' }} />
            <div className="absolute top-1/2 right-8 w-2 h-2 bg-[#4CAF50] rounded-full animate-pulse-soft" style={{ animationDelay: '1.5s' }} />
            <div className="absolute bottom-4 right-1/3 w-2 h-2 bg-[#FF9800] rounded-full animate-pulse-soft" style={{ animationDelay: '0.8s' }} />
          </div>
          <div className="text-center relative z-10">
            <MapPin size={32} className="text-[#CE93D8] mx-auto mb-2" />
            <p className="text-white font-bold text-sm">Weltweite Kraftorte-Karte</p>
            <p className="text-white/40 text-xs mt-1">Interaktive Karte in Entwicklung</p>
          </div>
        </div>

        {/* Search + filter */}
        <div className="px-4 py-3 sticky top-14 z-30 bg-[#0A0A0A]/90 backdrop-blur-xl border-b border-white/5 space-y-2">
          <div className="relative">
            <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#CE93D8]" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Kraftort suchen…"
              className="w-full bg-[#1A1A1A] border border-[#9C27B0]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-white/20 focus:outline-none focus:border-[#9C27B0]/50"
            />
          </div>
          <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' }}>
            {TYPES.map(t => (
              <button
                key={t}
                onClick={() => setActiveType(t)}
                className={`shrink-0 text-xs px-3 py-1.5 rounded-full font-medium transition-all ${
                  activeType === t
                    ? 'bg-[#9C27B0] text-white'
                    : 'bg-[#1A1A1A] text-white/40 border border-white/10 hover:border-white/20'
                }`}
              >
                {t}
              </button>
            ))}
          </div>
        </div>

        <div className="px-4 py-4 space-y-3">
          <p className="text-xs text-white/30 uppercase tracking-widest font-bold">{filtered.length} Kraftorte gefunden</p>
          {filtered.map(k => (
            <button
              key={k.id}
              className="w-full flex items-start gap-3 p-4 rounded-2xl bg-[#1A1A1A]/60 border border-white/5 hover:border-white/15 active:scale-[0.98] transition-all text-left"
            >
              <div
                className="w-12 h-12 rounded-xl flex items-center justify-center text-2xl shrink-0"
                style={{ background: `${k.color}20`, border: `1px solid ${k.color}40` }}
              >
                {k.icon}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-white text-sm">{k.name}</h3>
                  <span
                    className="text-[10px] px-2 py-0.5 rounded-full shrink-0"
                    style={{ background: `${k.color}20`, color: k.color }}
                  >
                    {k.type}
                  </span>
                </div>
                <div className="flex items-center gap-1 mt-0.5">
                  <Navigation size={10} className="text-white/30" />
                  <p className="text-xs text-white/40">{k.country}</p>
                </div>
                <p className="text-xs text-white/50 mt-1 line-clamp-2">{k.desc}</p>
              </div>
              <ChevronRight size={14} className="text-white/20 mt-1 shrink-0" />
            </button>
          ))}
        </div>
      </main>
      <BottomTabBar world="energie" />
    </div>
  )
}
