'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Bell, Shield, Palette, Info, ChevronRight, Moon, Globe, Lock, Trash2 } from 'lucide-react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { useWorldStore } from '@/store/worldStore'
import { cn } from '@/lib/utils'
import toast from 'react-hot-toast'

interface ToggleProps {
  value: boolean
  onChange: (v: boolean) => void
  color: string
}
function Toggle({ value, onChange, color }: ToggleProps) {
  return (
    <button
      onClick={() => onChange(!value)}
      className={cn(
        'w-11 h-6 rounded-full transition-all duration-200 relative shrink-0',
        value ? 'bg-opacity-100' : 'bg-[#3A3A3A]'
      )}
      style={value ? { background: color } : undefined}
    >
      <div className={cn(
        'absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-all duration-200',
        value ? 'left-[22px]' : 'left-0.5'
      )} />
    </button>
  )
}

export default function EinstellungenPage() {
  const router = useRouter()
  const { currentWorld } = useWorldStore()

  const [notifications, setNotifications] = useState({
    push: false,
    chat: true,
    news: true,
    system: true,
  })
  const [privacy, setPrivacy] = useState({
    publicProfile: true,
    showOnline: false,
  })

  const worldColor = currentWorld === 'materie' ? '#2196F3' : '#9C27B0'
  const worldBg = currentWorld === 'materie' ? 'bg-materie-world' : 'bg-energie-world'

  const handleRequestPush = async () => {
    if (!('Notification' in window)) {
      toast.error('Push-Benachrichtigungen werden nicht unterstützt.')
      return
    }
    const result = await Notification.requestPermission()
    if (result === 'granted') {
      setNotifications(n => ({ ...n, push: true }))
      toast.success('Push-Benachrichtigungen aktiviert!')
    } else {
      toast.error('Berechtigung verweigert.')
    }
  }

  const Section = ({ title, children }: { title: string; children: React.ReactNode }) => (
    <div className="bg-[#1A1A1A]/60 border border-white/5 rounded-2xl overflow-hidden">
      <div className="px-4 py-3 border-b border-white/5">
        <p className="text-xs font-bold text-white/30 uppercase tracking-widest">{title}</p>
      </div>
      <div className="divide-y divide-white/5">{children}</div>
    </div>
  )

  const Row = ({
    icon,
    label,
    sublabel,
    right,
    onClick,
  }: {
    icon: React.ReactNode
    label: string
    sublabel?: string
    right?: React.ReactNode
    onClick?: () => void
  }) => (
    <div
      className={cn(
        'flex items-center gap-3 px-4 py-3.5',
        onClick && 'cursor-pointer hover:bg-white/5 transition-colors'
      )}
      onClick={onClick}
    >
      <div className="w-8 h-8 rounded-xl bg-white/5 flex items-center justify-center shrink-0">{icon}</div>
      <div className="flex-1">
        <p className="text-sm text-white font-medium">{label}</p>
        {sublabel && <p className="text-xs text-white/30">{sublabel}</p>}
      </div>
      {right ?? (onClick && <ChevronRight size={14} className="text-white/20" />)}
    </div>
  )

  return (
    <div className={cn('min-h-screen', worldBg)}>
      <WorldHeader world={currentWorld} title="EINSTELLUNGEN" showBack />

      <main className="pb-8 px-4 pt-4 space-y-4">

        {/* App */}
        <Section title="App">
          <Row
            icon={<Moon size={16} className="text-[#9C27B0]" />}
            label="Dark Mode"
            sublabel="Immer aktiv (Weltenbibliothek-Design)"
            right={
              <span className="text-xs px-2 py-0.5 rounded-full bg-[#9C27B0]/20 text-[#CE93D8]">
                Aktiv
              </span>
            }
          />
          <Row
            icon={<Globe size={16} className="text-[#2196F3]" />}
            label="Sprache"
            sublabel="Deutsch"
            right={<ChevronRight size={14} className="text-white/20" />}
          />
        </Section>

        {/* Notifications */}
        <Section title="Benachrichtigungen">
          <Row
            icon={<Bell size={16} className="text-[#FF9800]" />}
            label="Push-Benachrichtigungen"
            sublabel={notifications.push ? 'Aktiviert' : 'Tippe zum Aktivieren'}
            right={
              <Toggle
                value={notifications.push}
                onChange={v => { if (v) handleRequestPush(); else setNotifications(n => ({...n, push: false})) }}
                color={worldColor}
              />
            }
          />
          <Row
            icon={<Bell size={16} className="text-[#2196F3]" />}
            label="Chat-Benachrichtigungen"
            right={
              <Toggle
                value={notifications.chat}
                onChange={v => setNotifications(n => ({ ...n, chat: v }))}
                color={worldColor}
              />
            }
          />
          <Row
            icon={<Bell size={16} className="text-[#4CAF50]" />}
            label="News-Updates"
            right={
              <Toggle
                value={notifications.news}
                onChange={v => setNotifications(n => ({ ...n, news: v }))}
                color={worldColor}
              />
            }
          />
        </Section>

        {/* Privacy */}
        <Section title="Privatsphäre">
          <Row
            icon={<Shield size={16} className="text-[#4CAF50]" />}
            label="Öffentliches Profil"
            sublabel="Andere können dein Profil sehen"
            right={
              <Toggle
                value={privacy.publicProfile}
                onChange={v => setPrivacy(p => ({ ...p, publicProfile: v }))}
                color={worldColor}
              />
            }
          />
          <Row
            icon={<Shield size={16} className="text-white/40" />}
            label="Online-Status anzeigen"
            right={
              <Toggle
                value={privacy.showOnline}
                onChange={v => setPrivacy(p => ({ ...p, showOnline: v }))}
                color={worldColor}
              />
            }
          />
        </Section>

        {/* Account */}
        <Section title="Konto">
          <Row
            icon={<Lock size={16} className="text-white/40" />}
            label="Passwort ändern"
            onClick={() => router.push('/auth/reset-password')}
          />
          <Row
            icon={<Info size={16} className="text-[#2196F3]" />}
            label="Datenschutzerklärung"
            onClick={() => {}}
          />
          <Row
            icon={<Info size={16} className="text-white/40" />}
            label="Nutzungsbedingungen"
            onClick={() => {}}
          />
        </Section>

        {/* App Info */}
        <Section title="Über die App">
          <Row
            icon={<span className="text-base">🌍</span>}
            label="Weltenbibliothek"
            sublabel="Version 1.0.0 – Next.js + Supabase + Cloudflare"
          />
          <Row
            icon={<Palette size={16} className="text-[#9C27B0]" />}
            label="PWA-Status"
            sublabel="Installierbar als App"
            right={
              <span className="text-xs px-2 py-0.5 rounded-full bg-[#4CAF50]/20 text-[#4CAF50]">
                Aktiv
              </span>
            }
          />
        </Section>

        {/* Danger Zone */}
        <div className="bg-[#FF5252]/5 border border-[#FF5252]/20 rounded-2xl overflow-hidden">
          <div className="px-4 py-3 border-b border-[#FF5252]/10">
            <p className="text-xs font-bold text-[#FF5252]/60 uppercase tracking-widest">Gefahrenzone</p>
          </div>
          <button className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-[#FF5252]/10 transition-colors">
            <div className="w-8 h-8 rounded-xl bg-[#FF5252]/10 flex items-center justify-center shrink-0">
              <Trash2 size={16} className="text-[#FF5252]" />
            </div>
            <div className="flex-1 text-left">
              <p className="text-sm text-[#FF5252] font-medium">Konto löschen</p>
              <p className="text-xs text-[#FF5252]/40">Unwiderruflich – alle Daten werden gelöscht</p>
            </div>
          </button>
        </div>

      </main>
    </div>
  )
}
