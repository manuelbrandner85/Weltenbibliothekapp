'use client'

import { useRouter } from 'next/navigation'
import { ArrowLeft, User, Bell } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { WorldId } from '@/types'

interface WorldHeaderProps {
  world: WorldId
  title?: string
  showBack?: boolean
  rightAction?: React.ReactNode
}

const worldConfig = {
  materie: {
    color:    '#2196F3',
    darkBg:   'rgba(13,71,161,0.3)',
    gradient: 'from-[#1976D2]/30 to-transparent',
  },
  energie: {
    color:    '#9C27B0',
    darkBg:   'rgba(74,20,140,0.3)',
    gradient: 'from-[#7B1FA2]/30 to-transparent',
  },
}

export function WorldHeader({ world, title, showBack = false, rightAction }: WorldHeaderProps) {
  const router = useRouter()
  const cfg = worldConfig[world]
  const worldName = world.toUpperCase()

  return (
    <header
      className={cn(
        'sticky top-0 z-40 px-4 pt-safe-top',
        'bg-[#0A0A0A]/90 backdrop-blur-xl border-b border-white/10'
      )}
    >
      <div
        className="absolute inset-0 pointer-events-none"
        style={{ background: `linear-gradient(to bottom, ${cfg.darkBg}, transparent)` }}
      />
      <div className="relative flex items-center gap-3 h-14">
        {/* Left: back button or portal back */}
        {showBack ? (
          <button
            onClick={() => router.back()}
            className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
          >
            <ArrowLeft size={18} className="text-white" />
          </button>
        ) : (
          <button
            onClick={() => router.push('/portal')}
            className="w-9 h-9 rounded-full border flex items-center justify-center transition-colors"
            style={{ borderColor: `${cfg.color}40`, background: `${cfg.color}15` }}
          >
            <span className="text-base">{world === 'materie' ? '🌍' : '✨'}</span>
          </button>
        )}

        {/* Title */}
        <div className="flex-1">
          <h1
            className="text-xl font-black tracking-[0.25em]"
            style={{ color: cfg.color }}
          >
            {title || worldName}
          </h1>
        </div>

        {/* Right actions */}
        <div className="flex items-center gap-2">
          {rightAction}
          <button
            onClick={() => router.push('/profil')}
            className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
          >
            <User size={18} className="text-white/80" />
          </button>
        </div>
      </div>
    </header>
  )
}
