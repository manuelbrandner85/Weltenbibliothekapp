'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { User, Edit3, Save, X, LogOut, Shield, Star, Camera, ChevronRight, Globe, Zap } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { createClient } from '@/lib/supabase/client'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { useWorldStore } from '@/store/worldStore'
import { cn, formatDate } from '@/lib/utils'
import toast from 'react-hot-toast'

export default function ProfilPage() {
  const router = useRouter()
  const { user, profile, signOut, refreshProfile } = useAuth()
  const { currentWorld } = useWorldStore()

  const [editing, setEditing] = useState(false)
  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [saving, setSaving] = useState(false)

  const worldColor = currentWorld === 'materie' ? '#2196F3' : '#9C27B0'
  const worldBg = currentWorld === 'materie' ? 'bg-materie-world' : 'bg-energie-world'

  useEffect(() => {
    if (profile) {
      setDisplayName(profile.display_name || profile.username || '')
      setBio(profile.bio || '')
    }
  }, [profile])

  const handleSave = async () => {
    if (!user) return
    setSaving(true)
    const supabase = createClient()
    const { error } = await supabase
      .from('profiles')
      .update({
        display_name: displayName.trim(),
        bio: bio.trim(),
        updated_at: new Date().toISOString(),
      })
      .eq('id', user.id)

    if (error) {
      toast.error('Speichern fehlgeschlagen.')
    } else {
      toast.success('Profil gespeichert!')
      await refreshProfile()
      setEditing(false)
    }
    setSaving(false)
  }

  const handleSignOut = async () => {
    await signOut()
    router.replace('/auth/login')
  }

  if (!user || !profile) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[#2196F3] border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  const avatarLetter = (profile.display_name || profile.username || 'U').charAt(0).toUpperCase()

  return (
    <div className={cn('min-h-screen', worldBg)}>
      <WorldHeader world={currentWorld} title="PROFIL" showBack />

      <main className="pb-8 px-4 pt-4 space-y-4">

        {/* Avatar + Name Card */}
        <div
          className="rounded-2xl p-6 text-center relative overflow-hidden"
          style={{
            background: `linear-gradient(135deg, ${worldColor}30 0%, rgba(0,0,0,0.4) 100%)`,
            border: `1px solid ${worldColor}40`,
          }}
        >
          <div className="absolute inset-0 opacity-5"
            style={{ background: `radial-gradient(circle at 50% 0%, ${worldColor}, transparent 60%)` }}
          />

          {/* Avatar */}
          <div className="relative inline-block mb-4">
            <div
              className="w-24 h-24 rounded-full flex items-center justify-center text-4xl font-black mx-auto"
              style={{ background: `${worldColor}40`, border: `3px solid ${worldColor}60` }}
            >
              {profile.avatar_url ? (
                <img src={profile.avatar_url} alt={avatarLetter} className="w-full h-full rounded-full object-cover" />
              ) : (
                <span className="text-white">{avatarLetter}</span>
              )}
            </div>
            <div
              className="absolute bottom-0 right-0 w-8 h-8 rounded-full flex items-center justify-center"
              style={{ background: worldColor }}
            >
              <Camera size={14} className="text-white" />
            </div>
          </div>

          {editing ? (
            <div className="space-y-3">
              <input
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                placeholder="Anzeigename"
                className="w-full bg-[#1A1A1A] border border-white/10 rounded-xl px-4 py-2.5 text-white text-center font-bold text-lg focus:outline-none focus:border-white/30"
              />
              <textarea
                value={bio}
                onChange={e => setBio(e.target.value)}
                placeholder="Kurze Bio…"
                rows={3}
                className="w-full bg-[#1A1A1A] border border-white/10 rounded-xl px-4 py-2.5 text-white text-sm focus:outline-none focus:border-white/30 resize-none"
              />
              <div className="flex gap-2">
                <button
                  onClick={() => setEditing(false)}
                  className="flex-1 py-2 rounded-xl border border-white/10 text-white/50 text-sm hover:border-white/20 transition-colors flex items-center justify-center gap-1"
                >
                  <X size={14} /> Abbrechen
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="flex-1 py-2 rounded-xl text-white text-sm font-semibold transition-all flex items-center justify-center gap-1 active:scale-95"
                  style={{ background: worldColor }}
                >
                  {saving ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <><Save size={14} />Speichern</>}
                </button>
              </div>
            </div>
          ) : (
            <>
              <h2 className="text-2xl font-black text-white">
                {profile.display_name || profile.username}
              </h2>
              <p className="text-white/40 text-sm">@{profile.username}</p>
              {profile.bio && (
                <p className="text-white/60 text-sm mt-2 leading-relaxed">{profile.bio}</p>
              )}
              <div className="flex items-center justify-center gap-2 mt-2">
                {profile.role === 'admin' && (
                  <span className="text-xs px-2 py-0.5 rounded-full bg-[#FF5252]/20 text-[#FF5252] flex items-center gap-1">
                    <Shield size={10} /> Admin
                  </span>
                )}
                {profile.role === 'moderator' && (
                  <span className="text-xs px-2 py-0.5 rounded-full bg-[#FF9800]/20 text-[#FF9800] flex items-center gap-1">
                    <Shield size={10} /> Moderator
                  </span>
                )}
                {profile.is_verified && (
                  <span className="text-xs px-2 py-0.5 rounded-full bg-[#4CAF50]/20 text-[#4CAF50] flex items-center gap-1">
                    <Star size={10} /> Verifiziert
                  </span>
                )}
              </div>
              <button
                onClick={() => setEditing(true)}
                className="mt-4 flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-medium border border-white/10 text-white/50 hover:border-white/20 transition-colors mx-auto"
              >
                <Edit3 size={12} /> Bearbeiten
              </button>
            </>
          )}
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-2">
          {[
            { label: 'Mitglied seit', value: formatDate(profile.created_at) },
            { label: 'Welt', value: currentWorld === 'materie' ? '🌍 Materie' : '✨ Energie' },
            { label: 'Status', value: profile.role === 'admin' ? 'Admin' : profile.role === 'moderator' ? 'Mod' : 'Mitglied' },
          ].map(s => (
            <div key={s.label} className="bg-[#1A1A1A]/60 border border-white/5 rounded-xl p-3 text-center">
              <p className="text-sm font-bold text-white truncate">{s.value}</p>
              <p className="text-[10px] text-white/30 mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Account Info */}
        <div className="bg-[#1A1A1A]/60 border border-white/5 rounded-2xl overflow-hidden">
          <div className="px-4 py-3 border-b border-white/5">
            <p className="text-xs font-bold text-white/30 uppercase tracking-widest">Account</p>
          </div>
          <div className="divide-y divide-white/5">
            <div className="flex items-center gap-3 px-4 py-3.5">
              <User size={16} className="text-white/30 shrink-0" />
              <div className="flex-1">
                <p className="text-xs text-white/30">Benutzername</p>
                <p className="text-sm text-white font-medium">@{profile.username}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 px-4 py-3.5">
              <div className="w-4 h-4 shrink-0 flex items-center justify-center">
                <span className="text-sm">✉️</span>
              </div>
              <div className="flex-1">
                <p className="text-xs text-white/30">E-Mail</p>
                <p className="text-sm text-white font-medium">{user.email}</p>
              </div>
            </div>
          </div>
        </div>

        {/* World Switch */}
        <div className="bg-[#1A1A1A]/60 border border-white/5 rounded-2xl overflow-hidden">
          <div className="px-4 py-3 border-b border-white/5">
            <p className="text-xs font-bold text-white/30 uppercase tracking-widest">Welten</p>
          </div>
          <div className="divide-y divide-white/5">
            <button
              onClick={() => router.push('/materie')}
              className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-white/5 transition-colors"
            >
              <Globe size={16} className="text-[#64B5F6] shrink-0" />
              <div className="flex-1 text-left">
                <p className="text-sm text-white font-medium">Materie-Welt</p>
                <p className="text-xs text-white/30">Wissen · Logik · Fakten</p>
              </div>
              <ChevronRight size={14} className="text-white/20" />
            </button>
            <button
              onClick={() => router.push('/energie')}
              className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-white/5 transition-colors"
            >
              <Zap size={16} className="text-[#CE93D8] shrink-0" />
              <div className="flex-1 text-left">
                <p className="text-sm text-white font-medium">Energie-Welt</p>
                <p className="text-xs text-white/30">Spiritualität · Mystik</p>
              </div>
              <ChevronRight size={14} className="text-white/20" />
            </button>
          </div>
        </div>

        {/* Sign Out */}
        <button
          onClick={handleSignOut}
          className="w-full flex items-center justify-center gap-2 p-4 rounded-2xl border border-[#FF5252]/20 bg-[#FF5252]/5 text-[#FF5252] hover:bg-[#FF5252]/10 transition-colors active:scale-98 font-semibold text-sm"
        >
          <LogOut size={16} />
          Abmelden
        </button>

      </main>
    </div>
  )
}
