'use client'

import { useEffect, useState } from 'react'
import { X, Download } from 'lucide-react'

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

export function PWAInstallBanner() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null)
  const [showBanner, setShowBanner] = useState(false)
  const [isIOS, setIsIOS] = useState(false)
  const [dismissed, setDismissed] = useState(false)

  useEffect(() => {
    // Check if already installed
    const isStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as Navigator & { standalone?: boolean }).standalone === true

    if (isStandalone) return

    // Check if previously dismissed
    const dismissedAt = localStorage.getItem('pwa-banner-dismissed')
    if (dismissedAt) {
      const diff = Date.now() - Number(dismissedAt)
      if (diff < 1000 * 60 * 60 * 24 * 7) return // 7 days
    }

    // iOS detection
    const ua = navigator.userAgent
    const iOS = /iphone|ipad|ipod/i.test(ua)
    if (iOS) {
      setIsIOS(true)
      setTimeout(() => setShowBanner(true), 3000)
      return
    }

    // Android / Chrome: listen for beforeinstallprompt
    const handler = (e: Event) => {
      e.preventDefault()
      setDeferredPrompt(e as BeforeInstallPromptEvent)
      setTimeout(() => setShowBanner(true), 3000)
    }

    window.addEventListener('beforeinstallprompt', handler)
    return () => window.removeEventListener('beforeinstallprompt', handler)
  }, [])

  const handleInstall = async () => {
    if (!deferredPrompt) return
    await deferredPrompt.prompt()
    const { outcome } = await deferredPrompt.userChoice
    if (outcome === 'accepted') {
      setShowBanner(false)
    }
    setDeferredPrompt(null)
  }

  const handleDismiss = () => {
    setShowBanner(false)
    setDismissed(true)
    localStorage.setItem('pwa-banner-dismissed', String(Date.now()))
  }

  if (!showBanner || dismissed) return null

  return (
    <div className="fixed bottom-24 left-4 right-4 z-50 animate-slide-up">
      <div className="bg-[#1A1A1A] border border-white/10 rounded-2xl p-4 shadow-card flex items-center gap-3">
        {/* Icon */}
        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#1976D2] to-[#7B1FA2] flex items-center justify-center shrink-0">
          <span className="text-2xl">🌍</span>
        </div>

        {/* Text */}
        <div className="flex-1 min-w-0">
          <p className="text-sm font-bold text-white">App installieren</p>
          {isIOS ? (
            <p className="text-xs text-white/50 mt-0.5">
              Tippe auf <span className="inline-block">⬆️</span> → „Zum Home-Bildschirm"
            </p>
          ) : (
            <p className="text-xs text-white/50 mt-0.5">Weltenbibliothek als PWA hinzufügen</p>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2 shrink-0">
          {!isIOS && (
            <button
              onClick={handleInstall}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1976D2] text-white text-xs font-semibold hover:bg-[#2196F3] transition-colors active:scale-95"
            >
              <Download size={12} />
              Installieren
            </button>
          )}
          <button
            onClick={handleDismiss}
            className="w-7 h-7 rounded-lg bg-white/10 flex items-center justify-center hover:bg-white/20 transition-colors"
          >
            <X size={14} className="text-white/60" />
          </button>
        </div>
      </div>
    </div>
  )
}
