-- ============================================================
-- Weltenbibliothek – Migration 001: Initial Schema
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username         TEXT UNIQUE,
  display_name     TEXT,
  avatar_url       TEXT,
  bio              TEXT,
  world_preference TEXT CHECK (world_preference IN ('materie', 'energie')) DEFAULT 'materie',
  role             TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'moderator', 'admin')),
  is_verified      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    LOWER(COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1))),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_public_read"
  ON public.profiles FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "profiles_own_update"
  ON public.profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id);

-- ============================================================
-- CHAT ROOMS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id            TEXT PRIMARY KEY, -- e.g. "materie-politik"
  name          TEXT NOT NULL,
  description   TEXT,
  world         TEXT NOT NULL CHECK (world IN ('materie', 'energie')),
  category      TEXT NOT NULL DEFAULT 'general',
  icon          TEXT DEFAULT '💬',
  color         TEXT DEFAULT '#2196F3',
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  message_count BIGINT NOT NULL DEFAULT 0,
  member_count  BIGINT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_rooms_public_read"
  ON public.chat_rooms FOR SELECT TO authenticated, anon
  USING (is_active = true);

-- Seed default chat rooms
INSERT INTO public.chat_rooms (id, name, description, world, category, icon, color) VALUES
  ('materie-politik',       'Politik',         'Weltpolitik & Geopolitik',          'materie', 'politik',       '🏛️', '#FF5252'),
  ('materie-geschichte',    'Geschichte',      'Verborgene Geschichte',              'materie', 'geschichte',    '📜',  '#FF9800'),
  ('materie-ufo',           'UFO & Aliens',    'Außerirdisches & UAP',               'materie', 'ufo',           '🛸',  '#2196F3'),
  ('materie-verschwoerung', 'Verschwörungen',  'Theorien & Fakten',                  'materie', 'verschwoerung', '🕵️','#9C27B0'),
  ('materie-wissenschaft',  'Wissenschaft',    'Alternative Wissenschaft',           'materie', 'wissenschaft',  '🔬',  '#4CAF50'),
  ('materie-finanzen',      'Finanzen',        'Wirtschaft & Finanzsystem',          'materie', 'finanzen',      '💰',  '#FFD700'),
  ('materie-medien',        'Medien',          'Medienkritik & Propaganda',          'materie', 'medien',        '📺',  '#E91E63'),
  ('materie-tech',          'Technologie',     'Tech & Überwachung',                 'materie', 'tech',          '💻',  '#00BCD4'),
  ('energie-bewusstsein',   'Bewusstsein',     'Bewusstseinsforschung',              'energie', 'bewusstsein',   '🧠',  '#9C27B0'),
  ('energie-meditation',    'Meditation',      'Meditationserfahrungen',             'energie', 'meditation',    '🧘',  '#7B1FA2'),
  ('energie-heilung',       'Heilung',         'Energetische Heilung',               'energie', 'heilung',       '💫',  '#E91E63'),
  ('energie-traeume',       'Traumdeutung',    'Träume & Symbolik',                  'energie', 'traeume',       '🌙',  '#3F51B5'),
  ('energie-kristalle',     'Kristalle',       'Kristallenergie',                    'energie', 'kristalle',     '💎',  '#00BCD4'),
  ('energie-kraftorte',     'Kraftorte',       'Heilige Orte & Ley-Linien',          'energie', 'kraftorte',     '🗺️', '#FFD700'),
  ('energie-chakra',        'Chakras',         'Chakra-System',                      'energie', 'chakra',        '🌈',  '#FF9800'),
  ('energie-astrologie',    'Astrologie',      'Planetare Einflüsse',               'energie', 'astrologie',    '⭐',  '#4CAF50')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- CHAT MESSAGES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content       TEXT NOT NULL CHECK (LENGTH(TRIM(content)) > 0),
  message_type  TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'voice', 'system')),
  media_url     TEXT,
  edited_at     TIMESTAMPTZ,
  deleted_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS chat_messages_room_id_idx ON public.chat_messages(room_id);
CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON public.chat_messages(created_at DESC);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_messages_authenticated_read"
  ON public.chat_messages FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "chat_messages_own_insert"
  ON public.chat_messages FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_messages_own_update"
  ON public.chat_messages FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "chat_messages_moderator_delete"
  ON public.chat_messages FOR UPDATE TO authenticated
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('moderator', 'admin')
    )
  );

-- ============================================================
-- RESEARCH RESULTS (Recherche Cache)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.research_results (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  query                   TEXT NOT NULL,
  world                   TEXT NOT NULL DEFAULT 'materie' CHECK (world IN ('materie', 'energie')),
  official_perspective    TEXT NOT NULL,
  alternative_perspective TEXT NOT NULL,
  sources                 JSONB DEFAULT '[]',
  tags                    TEXT[] DEFAULT '{}',
  category                TEXT DEFAULT 'Allgemein',
  user_id                 UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS research_results_query_idx ON public.research_results(LOWER(query));
CREATE INDEX IF NOT EXISTS research_results_world_idx ON public.research_results(world);

ALTER TABLE public.research_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "research_results_public_read"
  ON public.research_results FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY "research_results_authenticated_insert"
  ON public.research_results FOR INSERT TO authenticated
  WITH CHECK (true);

-- ============================================================
-- ARTICLES (Wissen)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.articles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title           TEXT NOT NULL,
  slug            TEXT UNIQUE NOT NULL,
  content         TEXT NOT NULL,
  excerpt         TEXT,
  world           TEXT NOT NULL CHECK (world IN ('materie', 'energie')),
  category        TEXT NOT NULL,
  tags            TEXT[] DEFAULT '{}',
  author_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  cover_image_url TEXT,
  view_count      BIGINT NOT NULL DEFAULT 0,
  like_count      BIGINT NOT NULL DEFAULT 0,
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  published_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS articles_world_idx    ON public.articles(world);
CREATE INDEX IF NOT EXISTS articles_category_idx ON public.articles(category);
CREATE INDEX IF NOT EXISTS articles_published_idx ON public.articles(is_published, published_at DESC);
CREATE INDEX IF NOT EXISTS articles_slug_idx     ON public.articles(slug);

ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "articles_public_read"
  ON public.articles FOR SELECT TO authenticated, anon
  USING (is_published = true);

CREATE POLICY "articles_admin_all"
  ON public.articles FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL DEFAULT 'system' CHECK (type IN ('message', 'like', 'follow', 'achievement', 'system')),
  title      TEXT NOT NULL,
  body       TEXT,
  data       JSONB DEFAULT '{}',
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications(user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_own_read"
  ON public.notifications FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "notifications_own_update"
  ON public.notifications FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);
