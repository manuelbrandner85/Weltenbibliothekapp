'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Mail, ArrowLeft, CheckCircle, AlertCircle } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { cn } from '@/lib/utils'

export default function ResetPasswordPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  const handleReset = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const supabase = createClient()
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(
        email.toLowerCase().trim(),
        {
          redirectTo: `${window.location.origin}/auth/callback?next=/auth/update-password`,
        }
      )

      if (resetError) {
        setError(resetError.message)
        return
      }

      setSuccess(true)
    } catch {
      setError('Ein Fehler ist aufgetreten. Bitte versuche es erneut.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-background flex flex-col items-center justify-center px-4 py-8">
      <div className="fixed inset-0 bg-portal pointer-events-none" />

      <div className="relative w-full max-w-sm">
        {/* Back link */}
        <Link
          href="/auth/login"
          className="flex items-center gap-2 text-white/40 hover:text-white/70 transition-colors mb-8 text-sm"
        >
          <ArrowLeft size={16} />
          Zurück zum Login
        </Link>

        {/* Icon */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-full bg-[#1976D2]/20 border border-[#2196F3]/30 flex items-center justify-center mx-auto mb-4">
            <Mail size={28} className="text-[#64B5F6]" />
          </div>
          <h1 className="text-xl font-bold text-white">Passwort zurücksetzen</h1>
          <p className="text-white/40 text-sm mt-1">
            Wir senden dir einen Link zum Zurücksetzen
          </p>
        </div>

        {success ? (
          <div className="glass-card p-6 text-center">
            <CheckCircle size={40} className="text-[#4CAF50] mx-auto mb-4" />
            <h2 className="text-lg font-bold text-white mb-2">E-Mail gesendet!</h2>
            <p className="text-white/60 text-sm mb-6">
              Prüfe deinen Posteingang und klicke auf den Link, um dein Passwort zurückzusetzen.
            </p>
            <Link href="/auth/login" className="btn-materie w-full flex items-center justify-center">
              Zum Login
            </Link>
          </div>
        ) : (
          <div className="glass-card p-6">
            {error && (
              <div className="flex items-start gap-2 bg-error/10 border border-error/30 rounded-lg p-3 mb-4">
                <AlertCircle size={16} className="text-error mt-0.5 shrink-0" />
                <p className="text-error text-sm">{error}</p>
              </div>
            )}

            <form onSubmit={handleReset} className="space-y-4">
              <div>
                <label className="block text-white/50 text-xs font-medium mb-1.5 uppercase tracking-wider">
                  E-Mail-Adresse
                </label>
                <div className="relative">
                  <Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-white/30" />
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

              <button
                type="submit"
                disabled={loading || !email}
                className={cn(
                  'btn-materie w-full flex items-center justify-center gap-2',
                  (loading || !email) && 'opacity-50 cursor-not-allowed'
                )}
              >
                {loading ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  'Link senden'
                )}
              </button>
            </form>
          </div>
        )}
      </div>
    </div>
  )
}
