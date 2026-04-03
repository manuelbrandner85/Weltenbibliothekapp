// ============================================
// WELTENBIBLIOTHEK - TypeScript Types
// ============================================

export type WorldId = 'materie' | 'energie'

// --- User & Profile ---
export interface Profile {
  id: string
  username: string | null
  display_name: string | null
  avatar_url: string | null
  bio: string | null
  world_preference: WorldId | null
  role: 'user' | 'moderator' | 'admin'
  is_verified: boolean
  created_at: string
  updated_at: string
}

// --- Research / Recherche ---
export interface ResearchResult {
  id: string
  query: string
  world: WorldId
  official_perspective: string
  alternative_perspective: string
  sources: ResearchSource[]
  tags: string[]
  category: string
  created_at: string
  user_id: string | null
}

export interface ResearchSource {
  title: string
  url: string
  type: 'official' | 'alternative' | 'independent'
  credibility: number // 1-10
}

// --- Chat / Community ---
export interface ChatRoom {
  id: string
  name: string
  description: string
  world: WorldId
  category: string
  icon: string
  color: string
  message_count: number
  member_count: number
  is_active: boolean
  created_at: string
}

export interface ChatMessage {
  id: string
  room_id: string
  user_id: string
  content: string
  message_type: 'text' | 'image' | 'voice' | 'system'
  media_url: string | null
  edited_at: string | null
  deleted_at: string | null
  created_at: string
  profile: Pick<Profile, 'username' | 'display_name' | 'avatar_url' | 'role'>
}

// --- Content / Artikel ---
export interface Article {
  id: string
  title: string
  slug: string
  content: string
  excerpt: string
  world: WorldId
  category: string
  tags: string[]
  author_id: string
  cover_image_url: string | null
  view_count: number
  like_count: number
  is_published: boolean
  published_at: string | null
  created_at: string
  updated_at: string
  author?: Pick<Profile, 'username' | 'display_name' | 'avatar_url'>
}

// --- Kategorien ---
export interface Category {
  id: string
  name: string
  slug: string
  description: string
  icon: string
  color: string
  world: WorldId | 'both'
  article_count: number
}

// --- Achievements ---
export interface Achievement {
  id: string
  key: string
  name: string
  description: string
  icon: string
  world: WorldId | 'both'
  points: number
  unlocked_at?: string
}

// --- Notifications ---
export interface Notification {
  id: string
  user_id: string
  type: 'message' | 'like' | 'follow' | 'achievement' | 'system'
  title: string
  body: string
  data: Record<string, unknown>
  read_at: string | null
  created_at: string
}

// --- API Responses ---
export interface ApiResponse<T> {
  data: T | null
  error: string | null
  status: number
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  per_page: number
  has_more: boolean
}

// --- Navigation ---
export interface NavItem {
  id: string
  label: string
  icon: string
  href: string
  badge?: number
}

// --- Materie Tabs ---
export type MaterieTab = 'home' | 'recherche' | 'community' | 'tools' | 'wissen'

// --- Energie Tabs ---
export type EnergieTab = 'home' | 'spirit' | 'community' | 'tools' | 'wissen'
