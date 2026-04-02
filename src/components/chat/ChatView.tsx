'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import { useSearchParams } from 'next/navigation'
import { Send, ChevronLeft, Hash, Users, Loader2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/useAuth'
import { cn, formatRelativeTime } from '@/lib/utils'
import type { WorldId } from '@/types'

interface Message {
  id: string
  content: string
  created_at: string
  user_id: string
  profile: { username: string | null; display_name: string | null; role: string }
}

interface Room {
  id: string
  name: string
  icon: string
  color: string
  description: string
}

const MATERIE_ROOMS: Room[] = [
  { id: 'politik',        name: 'Politik',        icon: '🏛️',  color: '#FF5252',  description: 'Weltpolitik & Geopolitik' },
  { id: 'geschichte',     name: 'Geschichte',     icon: '📜',  color: '#FF9800',  description: 'Verborgene Geschichte' },
  { id: 'ufo',            name: 'UFO & Aliens',   icon: '🛸',  color: '#2196F3',  description: 'Außerirdisches & UAP' },
  { id: 'verschwoerung',  name: 'Verschwörungen', icon: '🕵️', color: '#9C27B0',  description: 'Theorien & Fakten' },
  { id: 'wissenschaft',   name: 'Wissenschaft',   icon: '🔬',  color: '#4CAF50',  description: 'Alternative Wissenschaft' },
  { id: 'finanzen',       name: 'Finanzen',       icon: '💰',  color: '#FFD700',  description: 'Wirtschaft & Finanzen' },
  { id: 'medien',         name: 'Medien',         icon: '📺',  color: '#E91E63',  description: 'Medienkritik' },
  { id: 'tech',           name: 'Technologie',    icon: '💻',  color: '#00BCD4',  description: 'Tech & Überwachung' },
]

const ENERGIE_ROOMS: Room[] = [
  { id: 'bewusstsein', name: 'Bewusstsein',  icon: '🧠', color: '#9C27B0', description: 'Bewusstseinsforschung' },
  { id: 'meditation',  name: 'Meditation',   icon: '🧘', color: '#7B1FA2', description: 'Meditationserfahrungen' },
  { id: 'heilung',     name: 'Heilung',      icon: '💫', color: '#E91E63', description: 'Energetische Heilung' },
  { id: 'träume',      name: 'Traumdeutung', icon: '🌙', color: '#3F51B5', description: 'Träume & Symbolik' },
  { id: 'kristalle',   name: 'Kristalle',    icon: '💎', color: '#00BCD4', description: 'Kristallenergie' },
  { id: 'kraftorte',   name: 'Kraftorte',    icon: '🗺️', color: '#FFD700', description: 'Heilige Orte & Ley-Linien' },
  { id: 'chakra',      name: 'Chakras',      icon: '🌈', color: '#FF9800', description: 'Chakra-System' },
  { id: 'astrologie',  name: 'Astrologie',   icon: '⭐', color: '#4CAF50', description: 'Planetare Einflüsse' },
]

interface ChatViewProps {
  world: WorldId
}

export function ChatView({ world }: ChatViewProps) {
  const searchParams = useSearchParams()
  const { user, profile } = useAuth()

  const rooms = world === 'materie' ? MATERIE_ROOMS : ENERGIE_ROOMS
  const defaultRoomId = searchParams.get('room') || rooms[0].id
  const [activeRoom, setActiveRoom] = useState<Room>(
    rooms.find(r => r.id === defaultRoomId) || rooms[0]
  )
  const [view, setView] = useState<'rooms' | 'chat'>(
    searchParams.get('room') ? 'chat' : 'rooms'
  )
  const [messages, setMessages] = useState<Message[]>([])
  const [newMessage, setNewMessage] = useState('')
  const [sending, setSending] = useState(false)
  const [loadingMessages, setLoadingMessages] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)
  const supabase = createClient()

  const activeColor = world === 'materie' ? '#2196F3' : '#9C27B0'

  // Load messages for active room
  const loadMessages = useCallback(async () => {
    setLoadingMessages(true)
    const roomKey = `${world}-${activeRoom.id}`

    const { data } = await supabase
      .from('chat_messages')
      .select(`
        id, content, created_at, user_id,
        profile:profiles(username, display_name, role)
      `)
      .eq('room_id', roomKey)
      .is('deleted_at', null)
      .order('created_at', { ascending: true })
      .limit(50)

    if (data) {
      setMessages(data as unknown as Message[])
    }
    setLoadingMessages(false)
  }, [activeRoom.id, world, supabase])

  useEffect(() => {
    if (view !== 'chat') return
    loadMessages()

    // Realtime subscription
    const channel = supabase
      .channel(`chat-${world}-${activeRoom.id}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'chat_messages',
          filter: `room_id=eq.${world}-${activeRoom.id}`,
        },
        async (payload) => {
          const { data: msg } = await supabase
            .from('chat_messages')
            .select(`id, content, created_at, user_id, profile:profiles(username, display_name, role)`)
            .eq('id', payload.new.id)
            .single()
          if (msg) {
            setMessages(prev => [...prev, msg as unknown as Message])
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [view, activeRoom.id, world, loadMessages, supabase])

  // Auto-scroll to bottom
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const sendMessage = async () => {
    if (!newMessage.trim() || !user || sending) return
    setSending(true)

    const content = newMessage.trim()
    setNewMessage('')

    const { error } = await supabase.from('chat_messages').insert({
      room_id: `${world}-${activeRoom.id}`,
      user_id: user.id,
      content,
      message_type: 'text',
    })

    if (error) {
      setNewMessage(content) // restore on error
    }
    setSending(false)
  }

  const openRoom = (room: Room) => {
    setActiveRoom(room)
    setView('chat')
    setMessages([])
  }

  if (view === 'rooms') {
    return (
      <div className="px-4 py-4 space-y-2">
        <p className="text-xs text-white/30 uppercase tracking-widest font-bold mb-4">Chat-Räume</p>
        {rooms.map(room => (
          <button
            key={room.id}
            onClick={() => openRoom(room)}
            className="w-full flex items-center gap-3 p-3.5 rounded-xl bg-[#1A1A1A]/60 border border-white/5 hover:bg-[#1A1A1A]/80 hover:border-white/15 active:scale-[0.98] transition-all text-left"
          >
            <div
              className="w-11 h-11 rounded-xl flex items-center justify-center text-xl shrink-0"
              style={{ background: `${room.color}20`, border: `1px solid ${room.color}40` }}
            >
              {room.icon}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-white text-sm">{room.name}</p>
              <p className="text-xs text-white/30 truncate">{room.description}</p>
            </div>
            <Hash size={14} className="text-white/20 shrink-0" />
          </button>
        ))}
      </div>
    )
  }

  return (
    <div className="flex flex-col h-[calc(100vh-160px)]">
      {/* Room header */}
      <div
        className="flex items-center gap-3 px-4 py-3 border-b border-white/10"
        style={{ background: `${activeColor}10` }}
      >
        <button
          onClick={() => setView('rooms')}
          className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center hover:bg-white/20 transition-colors shrink-0"
        >
          <ChevronLeft size={16} className="text-white" />
        </button>
        <div
          className="w-9 h-9 rounded-xl flex items-center justify-center text-lg shrink-0"
          style={{ background: `${activeRoom.color}25` }}
        >
          {activeRoom.icon}
        </div>
        <div className="flex-1">
          <p className="font-bold text-white text-sm">{activeRoom.name}</p>
          <p className="text-[10px] text-white/30">{activeRoom.description}</p>
        </div>
        <Users size={14} className="text-white/20" />
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-3 space-y-3">
        {loadingMessages ? (
          <div className="flex justify-center py-8">
            <Loader2 size={24} className="animate-spin text-white/30" />
          </div>
        ) : messages.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-3xl mb-3">{activeRoom.icon}</p>
            <p className="text-white/40 text-sm">Noch keine Nachrichten.</p>
            <p className="text-white/20 text-xs mt-1">Starte die Unterhaltung!</p>
          </div>
        ) : (
          messages.map(msg => {
            const isOwn = msg.user_id === user?.id
            const displayName = msg.profile?.display_name || msg.profile?.username || 'Anonym'

            return (
              <div
                key={msg.id}
                className={cn('flex gap-2', isOwn ? 'flex-row-reverse' : 'flex-row')}
              >
                {/* Avatar */}
                <div
                  className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 mt-1"
                  style={{ background: isOwn ? `${activeColor}40` : '#2A2A2A' }}
                >
                  {displayName.charAt(0).toUpperCase()}
                </div>
                {/* Bubble */}
                <div className={cn('max-w-[75%]', isOwn ? 'items-end' : 'items-start')}>
                  {!isOwn && (
                    <p className="text-[10px] text-white/30 mb-0.5 px-1">{displayName}</p>
                  )}
                  <div
                    className={cn(
                      'px-3 py-2 rounded-2xl text-sm leading-relaxed',
                      isOwn
                        ? 'text-white rounded-tr-sm'
                        : 'bg-[#2A2A2A] text-white/90 rounded-tl-sm'
                    )}
                    style={isOwn ? { background: `${activeColor}90` } : undefined}
                  >
                    {msg.content}
                  </div>
                  <p className="text-[9px] text-white/20 mt-0.5 px-1">
                    {formatRelativeTime(msg.created_at)}
                  </p>
                </div>
              </div>
            )
          })
        )}
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div className="px-4 py-3 border-t border-white/10 bg-[#0A0A0A]/80">
        {!user ? (
          <div className="text-center py-2">
            <p className="text-white/40 text-sm">Bitte anmelden um zu chatten</p>
          </div>
        ) : (
          <div className="flex items-end gap-2">
            <textarea
              value={newMessage}
              onChange={e => setNewMessage(e.target.value)}
              onKeyDown={e => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault()
                  sendMessage()
                }
              }}
              placeholder="Nachricht schreiben…"
              rows={1}
              className="flex-1 bg-[#1A1A1A] border border-white/10 rounded-xl px-3 py-2.5 text-white text-sm placeholder-white/20 focus:outline-none focus:border-white/20 resize-none max-h-28 overflow-y-auto"
              style={{ scrollbarWidth: 'none' }}
            />
            <button
              onClick={sendMessage}
              disabled={!newMessage.trim() || sending}
              className={cn(
                'w-10 h-10 rounded-xl flex items-center justify-center transition-all shrink-0',
                newMessage.trim() ? 'active:scale-90' : 'opacity-30'
              )}
              style={{
                background: newMessage.trim() ? activeColor : '#2A2A2A'
              }}
            >
              {sending ? (
                <Loader2 size={16} className="animate-spin text-white" />
              ) : (
                <Send size={16} className="text-white" />
              )}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
