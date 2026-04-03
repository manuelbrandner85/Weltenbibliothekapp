'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { Settings, Bell, User } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { useWorldStore } from '@/store/worldStore'
import { PWAInstallBanner } from '@/components/pwa/PWAInstallBanner'

// Particle type for portal animation
interface Particle {
  x: number; y: number; vx: number; vy: number
  size: number; opacity: number; color: string; life: number
}

export default function PortalPage() {
  const router = useRouter()
  const { profile } = useAuth()
  const { setWorld } = useWorldStore()
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const animFrameRef = useRef<number>(0)
  const particlesRef = useRef<Particle[]>([])
  const rotationRef = useRef(0)

  const [portalReady, setPortalReady] = useState(false)
  const [tapCount, setTapCount] = useState(0)
  const [showEasterEgg, setShowEasterEgg] = useState(false)
  const [portalColor, setPortalColor] = useState<'standard' | 'golden'>('standard')

  // Portal color config
  const portalColors = {
    standard: { c1: '#2196F3', c2: '#9C27B0', c3: '#1565C0' },
    golden:   { c1: '#FFD700', c2: '#FF8C00', c3: '#FFA500' },
  }
  const colors = portalColors[portalColor]

  // Initialize particles
  useEffect(() => {
    particlesRef.current = Array.from({ length: 120 }, (_, i) => ({
      x: Math.random() * window.innerWidth,
      y: Math.random() * window.innerHeight,
      vx: (Math.random() - 0.5) * 0.8,
      vy: -Math.random() * 1.5 - 0.3,
      size: Math.random() * 3 + 1,
      opacity: Math.random() * 0.7 + 0.1,
      color: i % 3 === 0 ? colors.c1 : i % 3 === 1 ? colors.c2 : '#FFFFFF',
      life: Math.random(),
    }))

    const timer = setTimeout(() => setPortalReady(true), 300)
    return () => clearTimeout(timer)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // Canvas particle animation
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const resize = () => {
      canvas.width = window.innerWidth
      canvas.height = window.innerHeight
    }
    resize()
    window.addEventListener('resize', resize)

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      rotationRef.current += 0.005

      particlesRef.current.forEach((p, i) => {
        p.x += p.vx
        p.y += p.vy
        p.life += 0.003
        p.opacity = Math.sin(p.life * Math.PI) * 0.7

        if (p.y < -10 || p.life >= 1) {
          particlesRef.current[i] = {
            x: Math.random() * canvas.width,
            y: canvas.height + 10,
            vx: (Math.random() - 0.5) * 0.8,
            vy: -Math.random() * 1.5 - 0.3,
            size: Math.random() * 3 + 1,
            opacity: 0,
            color: i % 3 === 0 ? colors.c1 : i % 3 === 1 ? colors.c2 : '#FFFFFF',
            life: 0,
          }
          return
        }

        ctx.beginPath()
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
        ctx.fillStyle = p.color + Math.floor(p.opacity * 255).toString(16).padStart(2, '0')
        ctx.fill()
      })

      animFrameRef.current = requestAnimationFrame(animate)
    }

    animate()

    return () => {
      cancelAnimationFrame(animFrameRef.current)
      window.removeEventListener('resize', resize)
    }
  }, [colors])

  // Handle portal tap (Easter Egg: 10x)
  const handlePortalTap = useCallback(() => {
    const newCount = tapCount + 1
    setTapCount(newCount)
    if (newCount >= 10) {
      setTapCount(0)
      setShowEasterEgg(true)
      setPortalColor(c => c === 'standard' ? 'golden' : 'standard')
      setTimeout(() => setShowEasterEgg(false), 3000)
    }
  }, [tapCount])

  const enterWorld = (world: 'materie' | 'energie') => {
    setWorld(world)
    router.push(`/${world}`)
  }

  return (
    <div className="relative min-h-screen bg-background overflow-hidden select-none">
      {/* Particle canvas */}
      <canvas ref={canvasRef} className="absolute inset-0 pointer-events-none z-0" />

      {/* Background nebula layers */}
      <div className="absolute inset-0 z-0">
        <div
          className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full opacity-20 animate-nebula-drift blur-3xl"
          style={{ background: `radial-gradient(circle, ${colors.c1}55 0%, transparent 70%)` }}
        />
        <div
          className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full opacity-15 animate-nebula-drift blur-3xl"
          style={{ background: `radial-gradient(circle, ${colors.c2}55 0%, transparent 70%)`, animationDelay: '2s' }}
        />
      </div>

      {/* Header */}
      <header className="relative z-20 flex items-center justify-between px-5 pt-safe-top pt-4 pb-2">
        <div>
          <p className="text-xs text-white/40 uppercase tracking-widest">Weltenbibliothek</p>
          {profile && (
            <p className="text-sm font-medium text-white/70">
              Willkommen, <span className="text-white">{profile.display_name || profile.username}</span>
            </p>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => router.push('/profil')}
            className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
          >
            <User size={18} className="text-white/80" />
          </button>
          <button
            onClick={() => router.push('/einstellungen')}
            className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors"
          >
            <Settings size={18} className="text-white/80" />
          </button>
        </div>
      </header>

      {/* Main portal area */}
      <main className="relative z-10 flex flex-col items-center justify-center min-h-[calc(100vh-80px)] px-6">

        {/* Easter Egg notification */}
        {showEasterEgg && (
          <div className="absolute top-20 left-1/2 -translate-x-1/2 glass-card px-4 py-2 text-center animate-bounce-in z-30">
            <p className="text-sm font-bold text-yellow-400">✨ Goldenes Portal aktiviert!</p>
          </div>
        )}

        {/* Portal title */}
        <div className="text-center mb-10 animate-fade-in">
          <h1 className="text-4xl font-black tracking-[0.3em] text-white mb-1">
            WELTEN
          </h1>
          <h1 className="text-4xl font-black tracking-[0.3em]"
            style={{ color: colors.c1 }}>
            BIBLIOTHEK
          </h1>
          <p className="text-white/40 text-sm mt-2 tracking-wider">Wähle deine Welt</p>
        </div>

        {/* Portal Circle */}
        <div
          className="relative w-56 h-56 mb-12 cursor-pointer"
          onClick={handlePortalTap}
        >
          {/* Outer pulse rings */}
          <div className="absolute -inset-8 rounded-full border border-white/5 animate-pulse-ring" />
          <div className="absolute -inset-4 rounded-full border border-white/8 animate-pulse-ring" style={{ animationDelay: '0.7s' }} />

          {/* Rotating rings */}
          <div
            className="absolute inset-0 rounded-full border-2 animate-rotate-slow"
            style={{ borderColor: `${colors.c1}60` }}
          />
          <div
            className="absolute inset-2 rounded-full border animate-counter-rotate"
            style={{ borderColor: `${colors.c2}40` }}
          />
          <div
            className="absolute inset-4 rounded-full border animate-rotate-slow"
            style={{ borderColor: `${colors.c1}30`, animationDuration: '15s' }}
          />

          {/* Dashed ring */}
          <div
            className="absolute inset-6 rounded-full border border-dashed border-white/10 animate-counter-rotate"
            style={{ animationDuration: '20s' }}
          />

          {/* Core glow */}
          <div
            className="absolute inset-8 rounded-full animate-pulse-soft"
            style={{
              background: `radial-gradient(circle, ${colors.c1}40 0%, ${colors.c2}20 50%, transparent 70%)`,
              boxShadow: `0 0 60px ${colors.c1}40, 0 0 100px ${colors.c2}20`,
            }}
          />

          {/* Center globe icon */}
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-6xl" style={{ filter: `drop-shadow(0 0 20px ${colors.c1})` }}>
              {portalColor === 'golden' ? '⭐' : '🌍'}
            </span>
          </div>

          {/* Tap progress dots */}
          {tapCount > 0 && (
            <div className="absolute -bottom-6 left-1/2 -translate-x-1/2 flex gap-1">
              {Array.from({ length: 10 }).map((_, i) => (
                <div
                  key={i}
                  className={`w-1.5 h-1.5 rounded-full transition-colors ${i < tapCount ? 'bg-yellow-400' : 'bg-white/20'}`}
                />
              ))}
            </div>
          )}
        </div>

        {/* World Selection Buttons */}
        <div className={`w-full max-w-sm space-y-4 transition-all duration-500 ${portalReady ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'}`}>

          {/* MATERIE Button */}
          <button
            onClick={() => enterWorld('materie')}
            className="w-full group relative overflow-hidden rounded-2xl p-px transition-all duration-300 active:scale-98 hover:scale-[1.02]"
            style={{ background: 'linear-gradient(135deg, #2196F3, #0D47A1)' }}
          >
            <div className="relative rounded-2xl bg-[#0D47A1]/80 backdrop-blur-sm px-6 py-5 flex items-center gap-4">
              {/* Glow effect on hover */}
              <div className="absolute inset-0 bg-gradient-to-r from-[#2196F3]/0 to-[#2196F3]/20 opacity-0 group-hover:opacity-100 transition-opacity rounded-2xl" />

              <div className="w-14 h-14 rounded-full bg-[#1976D2]/50 border border-[#2196F3]/40 flex items-center justify-center shrink-0">
                <span className="text-2xl">🌍</span>
              </div>
              <div className="flex-1 text-left">
                <p className="text-[10px] text-[#64B5F6] font-bold tracking-[0.3em] uppercase mb-0.5">Welt I</p>
                <h2 className="text-2xl font-black tracking-[0.2em] text-white">MATERIE</h2>
                <p className="text-xs text-[#90CAF9]/70 mt-0.5">Wissen · Logik · Fakten</p>
              </div>
              <div className="text-[#64B5F6]/60 group-hover:translate-x-1 transition-transform">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M9 18l6-6-6-6"/>
                </svg>
              </div>
            </div>
          </button>

          {/* ENERGIE Button */}
          <button
            onClick={() => enterWorld('energie')}
            className="w-full group relative overflow-hidden rounded-2xl p-px transition-all duration-300 active:scale-98 hover:scale-[1.02]"
            style={{ background: 'linear-gradient(135deg, #9C27B0, #4A148C)' }}
          >
            <div className="relative rounded-2xl bg-[#4A148C]/80 backdrop-blur-sm px-6 py-5 flex items-center gap-4">
              <div className="absolute inset-0 bg-gradient-to-r from-[#9C27B0]/0 to-[#9C27B0]/20 opacity-0 group-hover:opacity-100 transition-opacity rounded-2xl" />

              <div className="w-14 h-14 rounded-full bg-[#7B1FA2]/50 border border-[#9C27B0]/40 flex items-center justify-center shrink-0">
                <span className="text-2xl">✨</span>
              </div>
              <div className="flex-1 text-left">
                <p className="text-[10px] text-[#CE93D8] font-bold tracking-[0.3em] uppercase mb-0.5">Welt II</p>
                <h2 className="text-2xl font-black tracking-[0.2em] text-white">ENERGIE</h2>
                <p className="text-xs text-[#E1BEE7]/70 mt-0.5">Spiritualität · Mystik · Bewusstsein</p>
              </div>
              <div className="text-[#CE93D8]/60 group-hover:translate-x-1 transition-transform">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M9 18l6-6-6-6"/>
                </svg>
              </div>
            </div>
          </button>
        </div>

        {/* Bottom hint */}
        <p className="mt-8 text-white/20 text-xs text-center tracking-wider animate-pulse-soft">
          Tippe auf das Portal für Überraschungen
        </p>
      </main>

      {/* PWA Install Banner */}
      <PWAInstallBanner />
    </div>
  )
}
