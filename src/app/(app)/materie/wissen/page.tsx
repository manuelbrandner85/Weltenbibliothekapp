'use client'

import { useState } from 'react'
import { BookOpen, ChevronRight, Search, Tag } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { useRouter } from 'next/navigation'

const CATEGORIES = [
  { id: 'geopolitik',   name: 'Geopolitik',     icon: '🌐', color: '#4CAF50',  count: 142 },
  { id: 'medien',       name: 'Medienkritik',   icon: '📺', color: '#FF5252',  count: 89 },
  { id: 'forschung',    name: 'Forschung',      icon: '🔬', color: '#9C27B0',  count: 67 },
  { id: 'finanzen',     name: 'Finanzsystem',   icon: '💰', color: '#FFD700',  count: 54 },
  { id: 'ueberwachung', name: 'Überwachung',    icon: '👁️', color: '#FF9800',  count: 43 },
  { id: 'gesundheit',   name: 'Gesundheit',     icon: '💊', color: '#E91E63',  count: 38 },
  { id: 'tech',         name: 'Technologie',    icon: '💻', color: '#00BCD4',  count: 29 },
  { id: 'geschichte',   name: 'Geschichte',     icon: '📜', color: '#8BC34A',  count: 77 },
]

const FEATURED = [
  {
    id: '1',
    title: 'Die verborgene Geschichte der Fed',
    excerpt: 'Wie das US-Zentralbanksystem die globale Wirtschaftspolitik seit 1913 kontrolliert...',
    category: 'Finanzsystem',
    tags: ['Federal Reserve', 'Bankensystem', 'Dollar'],
    color: '#FFD700',
    readTime: '8 Min',
  },
  {
    id: '2',
    title: 'Operation Mockingbird',
    excerpt: 'Wie die CIA westliche Medien infiltrierte und bis heute Narrative kontrolliert...',
    category: 'Medienkritik',
    tags: ['CIA', 'Medien', 'Propaganda'],
    color: '#FF5252',
    readTime: '12 Min',
  },
  {
    id: '3',
    title: 'Die 5G-Kontroverse',
    excerpt: 'Technische Fakten, gesundheitliche Risiken und die Lobby-Interessen dahinter...',
    category: 'Technologie',
    tags: ['5G', 'Strahlung', 'Telecom'],
    color: '#00BCD4',
    readTime: '6 Min',
  },
]

export default function MaterieWissenPage() {
  const router = useRouter()
  const [search, setSearch] = useState('')

  return (
    <div className="min-h-screen bg-materie-world">
      <WorldHeader world="materie" title="WISSEN" showBack />
      <main className="pb-24">
        {/* Search */}
        <div className="px-4 py-3 sticky top-14 z-30 bg-[#0A0A0A]/90 backdrop-blur-xl border-b border-white/5">
          <div className="relative">
            <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#64B5F6]" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Artikel suchen…"
              className="w-full bg-[#1A1A1A] border border-[#2196F3]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-white/20 focus:outline-none focus:border-[#2196F3]/50"
            />
          </div>
        </div>

        <div className="px-4 py-4 space-y-6">
          {/* Featured Articles */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <BookOpen size={14} className="text-[#64B5F6]" />
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
                      <span
                        className="text-[10px] font-bold uppercase tracking-wider"
                        style={{ color: article.color }}
                      >
                        {article.category} · {article.readTime}
                      </span>
                      <h3 className="text-sm font-bold text-white mt-0.5 leading-tight">{article.title}</h3>
                      <p className="text-xs text-white/40 mt-1 line-clamp-2">{article.excerpt}</p>
                      {/* Tags */}
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
              <Tag size={14} className="text-[#64B5F6]" />
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

          {/* Coming Soon Banner */}
          <div className="rounded-2xl p-4 border border-[#2196F3]/20 bg-[#0D47A1]/10 text-center">
            <p className="text-[#64B5F6] font-bold text-sm">📚 Bibliothek wird befüllt</p>
            <p className="text-white/30 text-xs mt-1">
              Weitere Artikel folgen kontinuierlich. Trage selbst zur Wissenssammlung bei.
            </p>
          </div>
        </div>
      </main>
      <BottomTabBar world="materie" />
    </div>
  )
}
