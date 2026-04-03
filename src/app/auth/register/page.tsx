'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { Mail, Lock, Eye, EyeOff, User, AlertCircle, CheckCircle } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import toast from 'react-hot-toast'
import { cn } from '@/lib/utils'

export default function RegisterPage() {
  const router = useRouter()

  const [username, setUsername]         = useState('')
  const [email, setEmail]               = useState('')
  const [password, setPassword]         = useState('')
  const [confirmPassword, setConfirm]   = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading]           = useState(false)
  const [error, setError]               = useState('')
  const [success, setSuccess]           = useState(false)

  const passwordStrength = (() => {
    if (!password) return 0
    let score = 0
    if (password.length >= 8) score++
    if (/[A-Z]/.test(password)) score++
    if (/[0-9]/.test(password)) score++
    if (/[^A-Za-z0-9]/.test(password)) score++
    return score
  })()

  const strengthColors = ['bg-error', 'bg-warning', 'bg-warning', 'bg-success', 'bg-success']
  const strengthLabels = ['', 'Schwach', 'Mittel', 'Gut', 'Stark']

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    if (password !== confirmPassword) {
      setError('Passwörter stimmen nicht überein.')
      return
    }
    if (password.length < 8) {
      setError('Passwort muss mindestens 8 Zeichen lang sein.')
      return
    }
    if (username.length < 3) {
      setError('Benutzername muss mindestens 3 Zeichen lang sein.')
      return
    }

    setLoading(true)

    try {
      const supabase = createClient()

      // Check if username already taken
      const { data: existingUser } = await supabase
        .from('profiles')
        .select('id')
        .eq('username', username.toLowerCase().trim())
        .maybeSingle()

      if (existingUser) {
        setError('Dieser Benutzername ist bereits vergeben.')
        return
      }

      // Register with Supabase Auth
      const { data, error: signUpError } = await supabase.auth.signUp({
        email: email.toLowerCase().trim(),
        password,
        options: {
          data: {
            username: username.toLowerCase().trim(),
            display_name: username,
          },
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      })

      if (signUpError) {
        if (signUpError.message.includes('already registered')) {
          setError('Diese E-Mail ist bereits registriert. Bitte einloggen.')
        } else {
          setError(signUpError.message)
        }
        return
      }

      if (data.user) {
        setSuccess(true)
        toast.success('Konto erstellt! Bitte E-Mail bestätigen.')
      }
    } catch {
      setError('Ein unerwarteter Fehler ist aufgetreten.')
    } finally {
      setLoading(false)
    }
  }

  if (success) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center px-4">
        <div className="fixed inset-0 bg-portal pointer-events-none" />
        <div className="relative w-full max-w-sm">
          <div className="glass-card p-8 text-center">
            <CheckCircle size={48} className="text-success mx-auto mb-4" />
            <h2 className="text-xl font-bold text-white mb-2">Fast geschafft!</h2>
            <p className="text-text-secondary text-sm mb-6">
              Wir haben dir eine Bestätigungs-E-Mail geschickt. Bitte bestätige deine Adresse, um die Weltenbibliothek zu betreten.
            </p>
            <Link href="/auth/login" className="btn-materie w-full flex items-center justify-center">
              Zum Login
            </Link>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center px-4 py-8">
      <div className="fixed inset-0 bg-portal pointer-events-none" />
      <div className="fixed inset-0 bg-gradient-to-b from-[#0D47A1]/20 via-transparent to-[#4A148C]/10 pointer-events-none" />

      <div className="relative w-full max-w-sm">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-materie to-energie flex items-center justify-center shadow-materie mx-auto mb-3">
            <span className="text-3xl">🌍</span>
          </div>
          <h1 className="text-xl font-extrabold text-white tracking-wider">WELTENBIBLIOTHEK</h1>
          <p className="text-text-secondary text-sm mt-1">Konto erstellen</p>
        </div>

        <div className="glass-card p-6">
          {error && (
            <div className="flex items-start gap-2 bg-error/10 border border-error/30 rounded-lg p-3 mb-4">
              <AlertCircle size={16} className="text-error mt-0.5 shrink-0" />
              <p className="text-error text-sm">{error}</p>
            </div>
          )}

          <form onSubmit={handleRegister} className="space-y-4">
            {/* Username */}
            <div>
              <label className="block text-text-secondary text-xs font-medium mb-1.5 uppercase tracking-wider">
                Benutzername
              </label>
              <div className="relative">
                <User size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-hint" />
                <input
                  type="text"
                  value={username}
                  onChange={e => setUsername(e.target.value.replace(/[^a-zA-Z0-9_]/g, ''))}
                  placeholder="dein_name"
                  required
                  minLength={3}
                  maxLength={30}
                  autoComplete="username"
                  className="input-dark pl-9"
                />
              </div>
            </div>

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
                  className="input-dark pl-9"
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
                  placeholder="Mindestens 8 Zeichen"
                  required
                  minLength={8}
                  autoComplete="new-password"
                  className="input-dark pl-9 pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(v => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-text-hint hover:text-text-secondary"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              {/* Strength indicator */}
              {password && (
                <div className="mt-1.5 flex gap-1">
                  {[1, 2, 3, 4].map(i => (
                    <div
                      key={i}
                      className={cn(
                        'h-1 flex-1 rounded-full transition-colors',
                        i <= passwordStrength ? strengthColors[passwordStrength] : 'bg-surface-light'
                      )}
                    />
                  ))}
                  <span className="text-xs text-text-secondary ml-1">{strengthLabels[passwordStrength]}</span>
                </div>
              )}
            </div>

            {/* Confirm Password */}
            <div>
              <label className="block text-text-secondary text-xs font-medium mb-1.5 uppercase tracking-wider">
                Passwort bestätigen
              </label>
              <div className="relative">
                <Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-hint" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={e => setConfirm(e.target.value)}
                  placeholder="Passwort wiederholen"
                  required
                  autoComplete="new-password"
                  className={cn(
                    'input-dark pl-9',
                    confirmPassword && password !== confirmPassword && 'border-error/50'
                  )}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || !email || !password || !username}
              className={cn(
                'btn-materie w-full flex items-center justify-center gap-2 mt-2',
                (loading || !email || !password || !username) && 'opacity-50 cursor-not-allowed'
              )}
            >
              {loading ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                'Konto erstellen'
              )}
            </button>
          </form>

          <div className="section-divider" />

          <p className="text-center text-text-secondary text-sm">
            Bereits registriert?{' '}
            <Link href="/auth/login" className="text-materie-light hover:text-materie font-medium transition-colors">
              Einloggen
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
