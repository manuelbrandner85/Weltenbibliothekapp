'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Search, MessageSquare, Flame, BookOpen, TrendingUp, ChevronRight, Zap } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { createClient } from '@/lib/supabase/client'

interface QuickCard {
  icon: React.ReactNode
  label: string
  desc: string
  href: string
  color: string
  bg: string
}

const quickCards: QuickCard[] = [
  { icon: <Search size={22}/>,       label: 'Recherche',  desc: 'AI-gestützte Suche',       href: '/materie/recherche',  color: '#2196F3', bg: 'rgba(33,150,243,0.15)' },
  { icon: <MessageSquare size={22}/>, label: 'Community',  desc: 'Live-Diskussionen',         href: '/materie/community',  color: '#4CAF50', bg: 'rgba(76,175,80,0.15)' },
  { icon: <Flame size={22}/>,         label: 'Tools',      desc: 'Analyse-Werkzeuge',         href: '/materie/tools',      color: '#FF5252', bg: 'rgba(255,82,82,0.15)' },
  { icon: <BookOpen size={22}/>,      label: 'Wissen',     desc: 'Artikel & Bibliothek',      href: '/materie/wissen',     color: '#FFB300', bg: 'rgba(255,179,0,0.15)' },
]

const chatRooms = [
  { id: 'politik',       name: 'Politik',       icon: '🏛️',  color: '#FF5252' },
  { id: 'geschichte',    name: 'Geschichte',    icon: '📜',  color: '#FF9800' },
  { id: 'ufo',           name: 'UFO & Aliens',  icon: '🛸',  color: '#2196F3' },
  { id: 'verschwoerung', name: 'Verschwörungen',icon: '🕵️', color: '#9C27B0' },
  { id: 'wissenschaft',  name: 'Wissenschaft',  icon: '🔬',  color: '#4CAF50' },
  { id: 'finanzen',      name: 'Finanzen',      icon: '💰',  color: '#FFD700' },
]

export function MaterieHomeTab() {
  const { profile } = useAuth()
  const router = useRouter()
  const [stats, setStats] = useState({ articles: 0, users: 0, messages: 0 })

  useEffect(() => {
    const supabase = createClient()
    Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }),
      supabase.from('chat_messages').select('id', { count: 'exact', head: true }),
    ]).then(([users, msgs]) => {
      setStats({
        articles: 1247,
        users: users.count ?? 0,
        messages: msgs.count ?? 0,
      })
    })
  }, [])

  return (
    <div className="px-4 py-4 space-y-6">

      {/* Welcome Banner */}
      <div
        className="rounded-2xl p-4 relative overflow-hidden"
        style={{ background: 'linear-gradient(135deg, rgba(13,71,161,0.6) 0%, rgba(25,118,210,0.4) 100%)', border: '1px solid rgba(33,150,243,0.3)' }}
      >
        <div className="absolute top-0 right-0 w-32 h-32 rounded-full opacity-10 blur-2xl" style={{ background: '#2196F3' }} />
        <p className="text-xs text-[#90CAF9] font-bold tracking-widest uppercase mb-1">Materie-Welt</p>
        <h2 className="text-xl font-black text-white leading-tight">
          {profile ? `Willkommen, ${profile.display_name || profile.username}` : 'Willkommen zurück'}
        </h2>
        <p className="text-sm text-white/60 mt-1">Erkunde Fakten, Analysen & alternative Perspektiven</p>

        {/* Stats row */}
        <div className="flex gap-4 mt-3">
          {[
            { val: stats.articles.toLocaleString(), label: 'Artikel' },
            { val: stats.users.toLocaleString(),   label: 'Nutzer' },
            { val: stats.messages.toLocaleString(), label: 'Nachrichten' },
          ].map(s => (
            <div key={s.label}>
              <p className="text-base font-black text-[#64B5F6]">{s.val}</p>
              <p className="text-[10px] text-white/40 uppercase tracking-wider">{s.label}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Quick Access Grid */}
      <div>
        <h3 className="text-xs font-bold text-white/40 uppercase tracking-widest mb-3">Schnellzugriff</h3>
        <div className="grid grid-cols-2 gap-3">
          {quickCards.map(card => (
            <button
              key={card.label}
              onClick={() => router.push(card.href)}
              className="flex items-center gap-3 p-3.5 rounded-xl border border-white/10 hover:border-white/20 active:scale-95 transition-all duration-200 text-left"
              style={{ background: card.bg }}
            >
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

      {/* Chat Rooms */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-xs font-bold text-white/40 uppercase tracking-widest">Chat-Räume</h3>
          <button onClick={() => router.push('/materie/community')} className="text-xs text-[#64B5F6] flex items-center gap-1">
            Alle <ChevronRight size={12}/>
          </button>
        </div>
        <div className="space-y-2">
          {chatRooms.map(room => (
            <button
              key={room.id}
              onClick={() => router.push(`/materie/community?room=${room.id}`)}
              className="w-full flex items-center gap-3 p-3 rounded-xl bg-surface/50 border border-white/5 hover:bg-surface/80 hover:border-white/15 active:scale-98 transition-all duration-200"
            >
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center text-lg shrink-0"
                style={{ background: `${room.color}20`, border: `1px solid ${room.color}40` }}
              >
                {room.icon}
              </div>
              <div className="flex-1 text-left">
                <p className="text-sm font-semibold text-white">{room.name}</p>
                <p className="text-xs text-white/30">Materie-Welt</p>
              </div>
              <ChevronRight size={16} className="text-white/20" />
            </button>
          ))}
        </div>
      </div>

      {/* Trending Topics */}
      <div>
        <div className="flex items-center gap-2 mb-3">
          <TrendingUp size={14} className="text-[#FF5252]" />
          <h3 className="text-xs font-bold text-white/40 uppercase tracking-widest">Trending</h3>
        </div>
        <div className="flex flex-wrap gap-2">
          {['Neue Weltordnung', 'Deep State', 'Chemtrails', '5G Netz', 'QAnon', 'Bilderberg', 'Mondlandung', 'Sandy Hook'].map(topic => (
            <button
              key={topic}
              onClick={() => router.push(`/materie/recherche?q=${encodeURIComponent(topic)}`)}
              className="px-3 py-1.5 rounded-full text-xs font-medium bg-[#1976D2]/20 text-[#64B5F6] border border-[#2196F3]/20 hover:bg-[#1976D2]/40 active:scale-95 transition-all"
            >
              #{topic}
            </button>
          ))}
        </div>
      </div>

      {/* Switch to Energie CTA */}
      <button
        onClick={() => router.push('/energie')}
        className="w-full flex items-center gap-3 p-4 rounded-2xl border border-[#9C27B0]/30 bg-[#4A148C]/20 hover:bg-[#4A148C]/30 active:scale-98 transition-all duration-200"
      >
        <Zap size={20} className="text-[#CE93D8]" />
        <div className="flex-1 text-left">
          <p className="text-sm font-bold text-[#CE93D8]">Zur Energie-Welt wechseln</p>
          <p className="text-xs text-white/30">Spiritualität · Mystik · Bewusstsein</p>
        </div>
        <ChevronRight size={16} className="text-[#9C27B0]/60" />
      </button>

    </div>
  )
}
