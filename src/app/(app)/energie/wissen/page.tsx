'use client'

import { useState } from 'react'
import { BookOpen, ChevronRight, Search, Tag } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'

const CATEGORIES = [
  { id: 'chakra',       name: 'Chakra-System',    icon: '🌈', color: '#9C27B0', count: 48 },
  { id: 'meditation',   name: 'Meditation',       icon: '🧘', color: '#7B1FA2', count: 62 },
  { id: 'heilkräuter',  name: 'Heilkräuter',      icon: '🌿', color: '#4CAF50', count: 35 },
  { id: 'numerologie',  name: 'Numerologie',      icon: '🔢', color: '#FF9800', count: 27 },
  { id: 'astrologie',   name: 'Astrologie',       icon: '⭐', color: '#FFD700', count: 41 },
  { id: 'traumdeutung', name: 'Traumdeutung',     icon: '🌙', color: '#3F51B5', count: 33 },
  { id: 'kraftorte',    name: 'Kraftorte',        icon: '🗺️', color: '#FFD700', count: 22 },
  { id: 'heilsteine',   name: 'Heilsteine',       icon: '💎', color: '#00BCD4', count: 18 },
]

const FEATURED = [
  {
    id: '1',
    title: 'Das Chakra-System verstehen',
    excerpt: 'Eine umfassende Einführung in die sieben Hauptchakren und ihre Bedeutung für Körper, Geist und Seele...',
    category: 'Chakra',
    tags: ['Chakra', 'Energie', 'Heilung'],
    color: '#9C27B0',
    readTime: '10 Min',
  },
  {
    id: '2',
    title: 'Ley-Linien: Energienetze der Erde',
    excerpt: 'Entdecke das unsichtbare Energienetz der Erde und seine Verbindung zu antiken Kultstätten...',
    category: 'Kraftorte',
    tags: ['Ley-Linien', 'Geomantie', 'Stonehenge'],
    color: '#FFD700',
    readTime: '8 Min',
  },
  {
    id: '3',
    title: 'Heilfrequenzen: 432 Hz & Solfeggio',
    excerpt: 'Wissenschaftliche Grundlagen und spirituelle Bedeutung heilender Klangfrequenzen...',
    category: 'Klang',
    tags: ['432 Hz', 'Solfeggio', 'Heilung'],
    color: '#E91E63',
    readTime: '6 Min',
  },
]

export default function EnergieWissenPage() {
  const [search, setSearch] = useState('')

  return (
    <div className="min-h-screen bg-energie-world">
      <WorldHeader world="energie" title="WISSEN" showBack />
      <main className="pb-24">
        {/* Search */}
        <div className="px-4 py-3 sticky top-14 z-30 bg-[#0A0A0A]/90 backdrop-blur-xl border-b border-white/5">
          <div className="relative">
            <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#CE93D8]" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Spirituelles Wissen suchen…"
              className="w-full bg-[#1A1A1A] border border-[#9C27B0]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-white/20 focus:outline-none focus:border-[#9C27B0]/50"
            />
          </div>
        </div>

        <div className="px-4 py-4 space-y-6">
          {/* Featured */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <BookOpen size={14} className="text-[#CE93D8]" />
              <h2 className="text-xs font-bold text-white/40 uppercase tracking-widest">Empfohlen</h2>
            </div>
            <div className="space-y-3">
              {FEATURED.map(article => (
                <button
                  key={article.id}
                  className="w-full text-left p-4 rounded-2xl bg-[#1A1A1A]/60 border border-white/5 hover:border-white/15 active:scale-[0.98] transition-all"
                >
                  <div className="flex items-start gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 mt-0.5"
                      style={{ background: `${article.color}20`, border: `1px solid ${article.color}40` }}
                    >
                      <BookOpen size={18} style={{ color: article.color }} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <span className="text-[10px] font-bold uppercase tracking-wider" style={{ color: article.color }}>
                        {article.category} · {article.readTime}
                      </span>
                      <h3 className="text-sm font-bold text-white mt-0.5 leading-tight">{article.title}</h3>
                      <p className="text-xs text-white/40 mt-1 line-clamp-2">{article.excerpt}</p>
                      <div className="flex flex-wrap gap-1 mt-2">
                        {article.tags.map(tag => (
                          <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-white/5 text-white/30">
                            #{tag}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Categories */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <Tag size={14} className="text-[#CE93D8]" />
              <h2 className="text-xs font-bold text-white/40 uppercase tracking-widest">Kategorien</h2>
            </div>
            <div className="grid grid-cols-2 gap-2">
              {CATEGORIES.map(cat => (
                <button
                  key={cat.id}
                  className="flex items-center gap-2.5 p-3 rounded-xl bg-[#1A1A1A]/60 border border-white/5 hover:border-white/15 active:scale-95 transition-all text-left"
                >
                  <span className="text-xl">{cat.icon}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{cat.name}</p>
                    <p className="text-[10px] text-white/30">{cat.count} Artikel</p>
                  </div>
                  <ChevronRight size={12} className="text-white/20 shrink-0" />
                </button>
              ))}
            </div>
          </div>

          <div className="rounded-2xl p-4 border border-[#9C27B0]/20 bg-[#4A148C]/10 text-center">
            <p className="text-[#CE93D8] font-bold text-sm">✨ Spirituelle Bibliothek</p>
            <p className="text-white/30 text-xs mt-1">
              Neue Inhalte werden regelmäßig hinzugefügt.
            </p>
          </div>
        </div>
      </main>
      <BottomTabBar world="energie" />
    </div>
  )
}
