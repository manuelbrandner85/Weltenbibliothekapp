import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date): string {
  const d = new Date(date)
  return new Intl.DateTimeFormat('de-DE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(d)
}

export function formatRelativeTime(date: string | Date): string {
  const now = new Date()
  const d = new Date(date)
  const diff = now.getTime() - d.getTime()
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)

  if (minutes < 1) return 'Gerade eben'
  if (minutes < 60) return `vor ${minutes} Min.`
  if (hours < 24) return `vor ${hours} Std.`
  if (days < 7) return `vor ${days} Tag${days > 1 ? 'en' : ''}`
  return formatDate(date)
}

export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str
  return str.slice(0, maxLength) + '…'
}

export function slugify(str: string): string {
  return str
    .toLowerCase()
    .replace(/[äöü]/g, c => ({ ä: 'ae', ö: 'oe', ü: 'ue' }[c] || c))
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

export const WORLDS = {
  materie: {
    id: 'materie',
    name: 'MATERIE',
    subtitle: 'Wissen | Logik | Fakten',
    color: '#2196F3',
    darkColor: '#0D47A1',
    gradient: 'from-[#0D47A1] via-[#1976D2] to-[#2196F3]',
    gradientVertical: 'from-[#0D47A1] via-[#1A1A1A] to-black',
    glow: 'shadow-materie',
    icon: '🌍',
  },
  energie: {
    id: 'energie',
    name: 'ENERGIE',
    subtitle: 'Spiritualität | Mystik | Bewusstsein',
    color: '#9C27B0',
    darkColor: '#4A148C',
    gradient: 'from-[#4A148C] via-[#7B1FA2] to-[#9C27B0]',
    gradientVertical: 'from-[#4A148C] via-[#1A1A1A] to-black',
    glow: 'shadow-energie',
    icon: '✨',
  },
} as const

export type WorldId = keyof typeof WORLDS
