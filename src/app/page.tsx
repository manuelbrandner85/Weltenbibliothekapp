'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

// Root page: redirect based on auth state
export default function RootPage() {
  const router = useRouter()

  useEffect(() => {
    const supabase = createClient()
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        router.replace('/portal')
      } else {
        router.replace('/auth/login')
      }
    })
  }, [router])

  return (
    <div className="min-h-screen bg-background flex items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        {/* Portal loading animation */}
        <div className="relative w-24 h-24">
          <div className="absolute inset-0 rounded-full border-2 border-materie/40 animate-rotate-slow" />
          <div className="absolute inset-2 rounded-full border border-energie/30 animate-counter-rotate" />
          <div className="absolute inset-4 rounded-full bg-gradient-to-br from-materie/20 to-energie/20 animate-pulse-soft" />
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-2xl">🌍</span>
          </div>
        </div>
        <p className="text-text-secondary text-sm animate-pulse-soft">Weltenbibliothek lädt…</p>
      </div>
    </div>
  )
}
