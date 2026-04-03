'use client'

import { useState, useEffect, useCallback } from 'react'
import { BookOpen, ChevronRight, Search, Tag, Loader2 } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

interface Article {
  id: string
  title: string
  excerpt: string
  category: string
  tags: string[]
  color: string
  readTime: string
  view_count: number
  like_count: number
}

const CATEGORIES = [
  { id: 'chakra',       name: 'Chakra-System',    icon: '🌈', color: '#9C27B0' },
  { id: 'meditation',   name: 'Meditation',       icon: '🧘', color: '#7B1FA2' },
  { id: 'heilkräuter',  name: 'Heilkräuter',      icon: '🌿', color: '#4CAF50' },
  { id: 'numerologie',  name: 'Numerologie',      icon: '🔢', color: '#FF9800' },
  { id: 'astrologie',   name: 'Astrologie',       icon: '⭐', color: '#FFD700' },
  { id: 'traumdeutung', name: 'Traumdeutung',     icon: '🌙', color: '#3F51B5' },
  { id: 'kraftorte',    name: 'Kraftorte',        icon: '🗺️', color: '#FFD700' },
  { id: 'heilsteine',   name: 'Heilsteine',       icon: '💎', color: '#00BCD4' },
]

const CATEGORY_COLORS: Record<string, string> = {
  chakra: '#9C27B0', meditation: '#7B1FA2', 'heilkräuter': '#4CAF50',
  numerologie: '#FF9800', astrologie: '#FFD700', traumdeutung: '#3F51B5',
  kraftorte: '#FFD700', heilsteine: '#00BCD4', default: '#9C27B0',
}

function estimateReadTime(content: string): string {
  const words = (content || '').split(/\s+/).length
  const minutes = Math.max(1, Math.ceil(words / 200))
  return `${minutes} Min`
}

export default function EnergieWissenPage() {
  const router = useRouter()
  const [search, setSearch] = useState('')
  const [articles, setArticles] = useState<Article[]>([])
  const [categoryCounts, setCategoryCounts] = useState<Record<string, number>>({})
  const [loading, setLoading] = useState(true)
  const [activeCategory, setActiveCategory] = useState<string | null>(null)

  const loadArticles = useCallback(async (query: string, category: string | null) => {
    setLoading(true)
    const supabase = createClient()

    let q = supabase
      .from('articles')
      .select('id, title, excerpt, content, category, tags, view_count, like_count, published_at, is_published')
      .eq('world', 'energie')
      .eq('is_published', true)
      .order('published_at', { ascending: false })
      .limit(20)

    if (category) {
      q = q.eq('category', category)
    }

    if (query.trim().length >= 2) {
      q = q.or(`title.ilike.%${query}%,excerpt.ilike.%${query}%`)
    }

    const { data, error } = await q

    if (!error && data) {
      const mapped: Article[] = data.map((a: any) => ({
        id: a.id,
        title: a.title,
        excerpt: a.excerpt || '',
        category: a.category || 'Spiritualität',
        tags: a.tags || [],
        color: CATEGORY_COLORS[a.category?.toLowerCase()] || CATEGORY_COLORS.default,
        readTime: estimateReadTime(a.content || a.excerpt || ''),
        view_count: a.view_count || 0,
        like_count: a.like_count || 0,
      }))
      setArticles(mapped)
    } else {
      setArticles([])
    }
    setLoading(false)
  }, [])

  // Load category counts once
  useEffect(() => {
    const supabase = createClient()
    supabase
      .from('articles')
      .select('category')
      .eq('world', 'energie')
      .eq('is_published', true)
      .then(({ data }) => {
        if (data) {
          const counts: Record<string, number> = {}
          data.forEach((a: any) => {
            const cat = a.category?.toLowerCase() || 'default'
            counts[cat] = (counts[cat] || 0) + 1
          })
          setCategoryCounts(counts)
        }
      })
  }, [])

  // Load on mount and when filter changes
  useEffect(() => {
    const timer = setTimeout(() => {
      loadArticles(search, activeCategory)
    }, search ? 400 : 0)
    return () => clearTimeout(timer)
  }, [search, activeCategory, loadArticles])

  const handleCategoryClick = (catId: string) => {
    setActiveCategory(prev => prev === catId ? null : catId)
  }

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
            {search && (
              <button
                onClick={() => setSearch('')}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-white/30 hover:text-white/60"
              >
                ✕
              </button>
            )}
          </div>
        </div>

        <div className="px-4 py-4 space-y-6">

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
                  onClick={() => handleCategoryClick(cat.id)}
                  className={`flex items-center gap-2.5 p-3 rounded-xl border active:scale-95 transition-all text-left ${
                    activeCategory === cat.id
                      ? 'border-white/30 bg-white/10'
                      : 'bg-[#1A1A1A]/60 border-white/5 hover:border-white/15'
                  }`}
                >
                  <span className="text-xl">{cat.icon}</span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{cat.name}</p>
                    <p className="text-[10px] text-white/30">
                      {categoryCounts[cat.id] ?? 0} Artikel
                    </p>
                  </div>
                  <ChevronRight
                    size={12}
                    className={`shrink-0 transition-colors ${activeCategory === cat.id ? 'text-[#CE93D8]' : 'text-white/20'}`}
                  />
                </button>
              ))}
            </div>
          </div>

          {/* Articles */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <BookOpen size={14} className="text-[#CE93D8]" />
              <h2 className="text-xs font-bold text-white/40 uppercase tracking-widest">
                {activeCategory
                  ? CATEGORIES.find(c => c.id === activeCategory)?.name || 'Artikel'
                  : search ? `Suche: „${search}"` : 'Neueste Artikel'}
              </h2>
              {activeCategory && (
                <button
                  onClick={() => setActiveCategory(null)}
                  className="ml-auto text-[10px] text-[#CE93D8] hover:text-white transition-colors"
                >
                  Filter entfernen
                </button>
              )}
            </div>

            {loading ? (
              <div className="flex justify-center py-12">
                <Loader2 size={28} className="animate-spin text-[#9C27B0]/60" />
              </div>
            ) : articles.length === 0 ? (
              <div className="rounded-2xl p-6 bg-[#1A1A1A]/60 border border-white/5 text-center">
                <p className="text-3xl mb-3">✨</p>
                <p className="text-white/60 font-medium text-sm">
                  {search ? `Keine Artikel für „${search}" gefunden.` : 'Noch keine Artikel veröffentlicht.'}
                </p>
                <p className="text-white/30 text-xs mt-1">Die spirituelle Bibliothek wächst kontinuierlich.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {articles.map(article => (
                  <button
                    key={article.id}
                    onClick={() => router.push(`/energie/wissen/${article.id}`)}
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
                        {article.excerpt && (
                          <p className="text-xs text-white/40 mt-1 line-clamp-2">{article.excerpt}</p>
                        )}
                        <div className="flex items-center gap-3 mt-2">
                          {article.tags?.slice(0, 3).map(tag => (
                            <span key={tag} className="text-[10px] px-2 py-0.5 rounded-full bg-white/5 text-white/30">
                              #{tag}
                            </span>
                          ))}
                          <span className="text-[10px] text-white/20 ml-auto">
                            👁 {article.view_count} · ♥ {article.like_count}
                          </span>
                        </div>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

        </div>
      </main>
      <BottomTabBar world="energie" />
    </div>
  )
}
