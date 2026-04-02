'use client'

import { useState, useEffect, Suspense } from 'react'
import Link from 'next/link'
import { useRouter, useSearchParams } from 'next/navigation'
import { Mail, Lock, Eye, EyeOff, AlertCircle, Globe, Zap } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import toast from 'react-hot-toast'
import { cn } from '@/lib/utils'

function LoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirectTo = searchParams.get('redirect') || '/portal'

  const [email, setEmail]               = useState('')
  const [password, setPassword]         = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading]           = useState(false)
  const [checking, setChecking]         = useState(true)
  const [error, setError]               = useState('')

  // Already logged in? → redirect
  useEffect(() => {
    const supabase = createClient()
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        router.replace(redirectTo)
      } else {
        setChecking(false)
      }
    })
  }, [router, redirectTo])

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const supabase = createClient()
      const { error: loginError } = await supabase.auth.signInWithPassword({
        email: email.toLowerCase().trim(),
        password,
      })

      if (loginError) {
        if (loginError.message.includes('Invalid login credentials')) {
          setError('E-Mail oder Passwort falsch.')
        } else if (loginError.message.includes('Email not confirmed')) {
          setError('Bitte bestätige zuerst deine E-Mail-Adresse.')
        } else {
          setError(loginError.message)
        }
        return
      }

      toast.success('Willkommen zurück!')
      router.replace(redirectTo)
    } catch {
      setError('Ein unerwarteter Fehler ist aufgetreten.')
    } finally {
      setLoading(false)
    }
  }

  if (checking) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-materie border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center px-4 py-8">
      {/* Background gradient */}
      <div className="fixed inset-0 bg-portal pointer-events-none" />
      <div className="fixed inset-0 bg-gradient-to-b from-[#0D47A1]/20 via-transparent to-[#4A148C]/10 pointer-events-none" />

      <div className="relative w-full max-w-sm">
        {/* Logo / Header */}
        <div className="text-center mb-8">
          <div className="relative inline-block mb-4">
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-materie to-energie flex items-center justify-center shadow-materie mx-auto">
              <span className="text-4xl">🌍</span>
            </div>
            <div className="absolute -inset-1 rounded-full border border-materie/30 animate-pulse-soft" />
          </div>
          <h1 className="text-2xl font-extrabold text-white tracking-wider">WELTENBIBLIOTHEK</h1>
          <p className="text-text-secondary text-sm mt-1">Die alternative Wissensplattform</p>
        </div>

        {/* Login Card */}
        <div className="glass-card p-6">
          <h2 className="text-lg font-semibold text-white mb-6 text-center">Anmelden</h2>

          {error && (
            <div className="flex items-start gap-2 bg-error/10 border border-error/30 rounded-lg p-3 mb-4">
              <AlertCircle size={16} className="text-error mt-0.5 shrink-0" />
              <p className="text-error text-sm">{error}</p>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            {/* Email */}
            <div>
              <label className="block text-text-secondary text-xs font-medium mb-1.5 uppercase tracking-wider">
                E-Mail
              </label>
              <div className="relative">
                <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-hint" />
                <input
                  type="email"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  placeholder="deine@email.de"
                  required
                  autoComplete="email"
                  className={cn(
                    'input-dark pl-9',
                    error && 'border-error/50'
                  )}
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <label className="block text-text-secondary text-xs font-medium mb-1.5 uppercase tracking-wider">
                Passwort
              </label>
              <div className="relative">
                <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-hint" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                  className={cn(
                    'input-dark pl-9 pr-10',
                    error && 'border-error/50'
                  )}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(v => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-text-hint hover:text-text-secondary transition-colors"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {/* Forgot password */}
            <div className="text-right">
              <Link
                href="/auth/reset-password"
                className="text-xs text-text-secondary hover:text-materie-light transition-colors"
              >
                Passwort vergessen?
              </Link>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading || !email || !password}
              className={cn(
                'btn-materie w-full flex items-center justify-center gap-2 mt-2',
                (loading || !email || !password) && 'opacity-50 cursor-not-allowed'
              )}
            >
              {loading ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <>
                  <Globe size={16} />
                  Einloggen
                </>
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="section-divider" />

          {/* Register link */}
          <p className="text-center text-text-secondary text-sm">
            Noch kein Konto?{' '}
            <Link
              href="/auth/register"
              className="text-materie-light hover:text-materie font-medium transition-colors"
            >
              Jetzt registrieren
            </Link>
          </p>
        </div>

        {/* Worlds preview */}
        <div className="mt-6 grid grid-cols-2 gap-3">
          <div className="glass-card p-3 text-center border-materie/20">
            <Globe size={20} className="text-materie mx-auto mb-1" />
            <p className="text-xs font-bold text-materie tracking-wider">MATERIE</p>
            <p className="text-xs text-text-hint">Wissen & Fakten</p>
          </div>
          <div className="glass-card p-3 text-center border-energie/20">
            <Zap size={20} className="text-energie mx-auto mb-1" />
            <p className="text-xs font-bold text-energie tracking-wider">ENERGIE</p>
            <p className="text-xs text-text-hint">Spiritualität</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[#2196F3] border-t-transparent rounded-full animate-spin" />
      </div>
    }>
      <LoginForm />
    </Suspense>
  )
}
