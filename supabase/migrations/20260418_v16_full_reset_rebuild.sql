-- ============================================================
-- WELTENBIBLIOTHEK v16 – FULL RESET + REBUILD
-- Datum: 2026-04-18
-- Projekt: adtviduaftdquvfjpojb
--
-- WARNUNG: Diese Migration LÖSCHT alles im public-Schema und
-- legt nur an, was Weltenbibliothek aktuell braucht.
--
-- Ausführen in:
-- https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new
--
-- Architektur-Entscheidungen:
-- * Keine User-Registration in der App → 2 System-Profile (1 pro Welt)
-- * profiles.id bleibt UUID, aber KEIN FK auf auth.users
-- * Chat-Schreiben läuft über Cloudflare Worker (Service-Role-Key)
-- * RLS-Policies erlauben anon Lesen, Schreiben nur service_role
-- ============================================================

-- ── PHASE A: WIPE ────────────────────────────────────────────
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA public TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;

-- ── PHASE B: EXTENSIONS ──────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── PHASE C: SHARED HELPERS ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ============================================================
-- PHASE D: CORE-TABELLEN (9)
-- ============================================================

-- ── PROFILES ─────────────────────────────────────────────────
-- Keine auth.users-FK: 2 System-Profile werden per Seed angelegt
CREATE TABLE profiles (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username      TEXT UNIQUE NOT NULL,
  display_name  TEXT,
  avatar_url    TEXT,
  avatar_emoji  TEXT,
  bio           TEXT,
  world         TEXT NOT NULL CHECK (world IN ('materie','energie','both')),
  role          TEXT NOT NULL DEFAULT 'system' CHECK (role IN ('user','mod','moderator','admin','root-admin','system')),
  is_banned     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── ARTICLES ─────────────────────────────────────────────────
CREATE TABLE articles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username        TEXT NOT NULL DEFAULT 'Anonym',
  title           TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,
  content         TEXT NOT NULL DEFAULT '',
  world           TEXT NOT NULL DEFAULT 'materie' CHECK (world IN ('materie','energie','both')),
  category        TEXT,
  tags            TEXT[] NOT NULL DEFAULT '{}',
  image_url       TEXT,
  cover_image_url TEXT,
  is_published    BOOLEAN NOT NULL DEFAULT TRUE,
  view_count      INTEGER NOT NULL DEFAULT 0,
  like_count      INTEGER NOT NULL DEFAULT 0,
  comment_count   INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── COMMENTS ─────────────────────────────────────────────────
CREATE TABLE comments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  content     TEXT NOT NULL,
  is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── LIKES ────────────────────────────────────────────────────
CREATE TABLE likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(article_id, user_id)
);

-- ── BOOKMARKS ────────────────────────────────────────────────
CREATE TABLE bookmarks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(article_id, user_id)
);

-- ── CHAT ROOMS ───────────────────────────────────────────────
CREATE TABLE chat_rooms (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  world       TEXT NOT NULL CHECK (world IN ('materie','energie','both')),
  category    TEXT,
  icon        TEXT,
  color       TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── CHAT MESSAGES ────────────────────────────────────────────
CREATE TABLE chat_messages (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username      TEXT NOT NULL DEFAULT 'Anonym',
  avatar_url    TEXT,
  avatar_emoji  TEXT,
  content       TEXT NOT NULL DEFAULT '',
  message       TEXT NOT NULL DEFAULT '',
  message_type  TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text','image','voice','file','system')),
  reply_to_id   UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  is_pinned     BOOLEAN NOT NULL DEFAULT FALSE,
  is_edited     BOOLEAN NOT NULL DEFAULT FALSE,
  edited_at     TIMESTAMPTZ,
  is_deleted    BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at    TIMESTAMPTZ,
  read_by       TEXT[] NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── MESSAGE REACTIONS ────────────────────────────────────────
CREATE TABLE message_reactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id  UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  emoji       TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);

-- ── NOTIFICATIONS ────────────────────────────────────────────
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('like','comment','follow','mention','system','message','achievement')),
  title       TEXT NOT NULL DEFAULT '',
  message     TEXT NOT NULL DEFAULT '',
  data        JSONB NOT NULL DEFAULT '{}',
  is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
