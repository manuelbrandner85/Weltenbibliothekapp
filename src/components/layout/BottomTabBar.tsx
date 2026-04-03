'use client'

import { useRouter, usePathname } from 'next/navigation'
import { Home, Search, MessageSquare, Map, BookOpen, Sparkles, Flame } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { WorldId } from '@/types'

interface Tab {
  id: string
  label: string
  icon: React.ReactNode
  href: string
}

const materieTabs: Tab[] = [
  { id: 'home',       label: 'Home',      icon: <Home size={22} />,          href: '/materie' },
  { id: 'recherche',  label: 'Recherche', icon: <Search size={22} />,        href: '/materie/recherche' },
  { id: 'community',  label: 'Community', icon: <MessageSquare size={22} />, href: '/materie/community' },
  { id: 'tools',      label: 'Tools',     icon: <Flame size={22} />,         href: '/materie/tools' },
  { id: 'wissen',     label: 'Wissen',    icon: <BookOpen size={22} />,      href: '/materie/wissen' },
]

const energieTabs: Tab[] = [
  { id: 'home',      label: 'Home',       icon: <Home size={22} />,          href: '/energie' },
  { id: 'spirit',    label: 'Spirit',     icon: <Sparkles size={22} />,      href: '/energie/spirit' },
  { id: 'community', label: 'Community',  icon: <MessageSquare size={22} />, href: '/energie/community' },
  { id: 'map',       label: 'Karte',      icon: <Map size={22} />,           href: '/energie/karte' },
  { id: 'wissen',    label: 'Wissen',     icon: <BookOpen size={22} />,      href: '/energie/wissen' },
]

interface BottomTabBarProps {
  world: WorldId
}

export function BottomTabBar({ world }: BottomTabBarProps) {
  const router = useRouter()
  const pathname = usePathname()
  const tabs = world === 'materie' ? materieTabs : energieTabs
  const activeColor = world === 'materie' ? 'text-[#2196F3]' : 'text-[#9C27B0]'
  const activeBg = world === 'materie' ? 'bg-[#2196F3]/15' : 'bg-[#9C27B0]/15'

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-[#0A0A0A]/95 backdrop-blur-xl border-t border-white/10 pb-safe">
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto">
        {tabs.map(tab => {
          const isActive = pathname === tab.href || (tab.href !== `/${world}` && pathname.startsWith(tab.href))
          return (
            <button
              key={tab.id}
              onClick={() => router.push(tab.href)}
              className={cn(
                'flex flex-col items-center justify-center gap-0.5 px-3 py-1.5 rounded-xl transition-all duration-200 min-w-[56px]',
                isActive ? `${activeColor} ${activeBg}` : 'text-white/40 hover:text-white/60'
              )}
            >
              <span className={cn('transition-transform', isActive && 'scale-110')}>{tab.icon}</span>
              <span className={cn('text-[9px] font-semibold tracking-wider uppercase', isActive ? '' : 'opacity-70')}>
                {tab.label}
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
