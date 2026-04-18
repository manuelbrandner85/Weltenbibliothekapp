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

-- ============================================================
-- PHASE E: PUSH + VOICE + GAMIFICATION (5)
-- ============================================================

-- ── PUSH SUBSCRIPTIONS ───────────────────────────────────────
-- user_id als UUID, KEIN FK (auth.users existiert nicht in dieser App)
CREATE TABLE push_subscriptions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  endpoint    TEXT NOT NULL,
  p256dh      TEXT NOT NULL DEFAULT '',
  auth_key    TEXT NOT NULL DEFAULT '',
  platform    TEXT NOT NULL DEFAULT 'web' CHECK (platform IN ('web','android','ios')),
  fcm_token   TEXT,
  device_info JSONB NOT NULL DEFAULT '{}',
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, endpoint)
);

-- ── NOTIFICATION QUEUE ───────────────────────────────────────
CREATE TABLE notification_queue (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  data          JSONB NOT NULL DEFAULT '{}',
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','failed')),
  attempts      INTEGER NOT NULL DEFAULT 0,
  last_error    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at  TIMESTAMPTZ
);

-- ── VOICE PARTICIPANTS ───────────────────────────────────────
CREATE TABLE voice_participants (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  avatar_url  TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  is_muted    BOOLEAN NOT NULL DEFAULT FALSE,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  left_at     TIMESTAMPTZ,
  UNIQUE(room_id, user_id)
);

-- ── USER ACHIEVEMENTS ────────────────────────────────────────
CREATE TABLE user_achievements (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id    TEXT NOT NULL,
  achievement_name  TEXT NOT NULL,
  xp_earned         INTEGER NOT NULL DEFAULT 0,
  unlocked_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- ── USER STATS ───────────────────────────────────────────────
CREATE TABLE user_stats (
  user_id           UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  total_xp          INTEGER NOT NULL DEFAULT 0,
  level             INTEGER NOT NULL DEFAULT 1,
  articles_read     INTEGER NOT NULL DEFAULT 0,
  articles_written  INTEGER NOT NULL DEFAULT 0,
  chat_messages     INTEGER NOT NULL DEFAULT 0,
  login_streak      INTEGER NOT NULL DEFAULT 0,
  last_active       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PHASE F: TOOLS ENERGIE (7)
-- Endpunkte in Worker (workers/api-worker.js toolTableMap)
-- ============================================================

-- ── tool_meditation_sessions ── Endpunkt: energie/astral
CREATE TABLE tool_meditation_sessions (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id          TEXT NOT NULL,
  user_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username         TEXT NOT NULL DEFAULT 'Anonym',
  title            TEXT NOT NULL,
  experience       TEXT,
  techniques_used  TEXT[] NOT NULL DEFAULT '{}',
  success_level    INTEGER NOT NULL DEFAULT 5 CHECK (success_level BETWEEN 1 AND 10),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_kristalle ── Endpunkt: energie/crystals
CREATE TABLE tool_kristalle (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id      TEXT NOT NULL,
  user_id      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username     TEXT NOT NULL DEFAULT 'Anonym',
  crystal_name TEXT NOT NULL,
  crystal_type TEXT,
  properties   TEXT[] NOT NULL DEFAULT '{}',
  uses         TEXT[] NOT NULL DEFAULT '{}',
  image_url    TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_chakra_readings ── Endpunkt: energie/chakra
CREATE TABLE tool_chakra_readings (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id      TEXT NOT NULL,
  user_id      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username     TEXT NOT NULL DEFAULT 'Anonym',
  chakra_name  TEXT NOT NULL,
  energy_level INTEGER NOT NULL DEFAULT 50 CHECK (energy_level BETWEEN 0 AND 100),
  note         TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_heilfrequenz ── Endpunkt: energie/heilfrequenz
CREATE TABLE tool_heilfrequenz (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id          TEXT NOT NULL,
  user_id          UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username         TEXT NOT NULL DEFAULT 'Anonym',
  frequency        DOUBLE PRECISION NOT NULL,
  name             TEXT NOT NULL,
  description      TEXT,
  duration_seconds INTEGER NOT NULL DEFAULT 60,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_traeume ── Endpunkt: energie/traeume
CREATE TABLE tool_traeume (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  dream_title TEXT NOT NULL,
  dream_text  TEXT NOT NULL,
  symbols     TEXT[] NOT NULL DEFAULT '{}',
  mood        TEXT,
  clarity     INTEGER NOT NULL DEFAULT 5 CHECK (clarity BETWEEN 1 AND 10),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_bewusstsein_journal ── Endpunkt: energie/bewusstsein
CREATE TABLE tool_bewusstsein_journal (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id      TEXT NOT NULL,
  user_id      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username     TEXT NOT NULL DEFAULT 'Anonym',
  entry_title  TEXT NOT NULL,
  entry_text   TEXT NOT NULL,
  mood         TEXT,
  energy_level INTEGER NOT NULL DEFAULT 5 CHECK (energy_level BETWEEN 1 AND 10),
  tags         TEXT[] NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_group_meditation ── Endpunkt: energie/group_meditation
CREATE TABLE tool_group_meditation (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id        TEXT NOT NULL,
  user_id        UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username       TEXT NOT NULL DEFAULT 'Anonym',
  session_title  TEXT NOT NULL,
  intention      TEXT,
  duration_mins  INTEGER NOT NULL DEFAULT 15,
  participants   INTEGER NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PHASE G: TOOLS MATERIE (10)
-- Endpunkte in Worker (workers/api-worker.js toolTableMap)
-- ============================================================

-- ── tool_geopolitics_events ── Endpunkt: materie/geopolitics
CREATE TABLE tool_geopolitics_events (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id            TEXT NOT NULL,
  user_id            UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username           TEXT NOT NULL DEFAULT 'Anonym',
  event_title        TEXT NOT NULL,
  event_description  TEXT,
  tags               TEXT[] NOT NULL DEFAULT '{}',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_history_events ── Endpunkt: materie/history
CREATE TABLE tool_history_events (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id            TEXT NOT NULL,
  user_id            UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username           TEXT NOT NULL DEFAULT 'Anonym',
  event_title        TEXT NOT NULL,
  event_description  TEXT,
  event_year         INTEGER,
  civilization       TEXT,
  category           TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_healing_methods ── Endpunkt: materie/healing
CREATE TABLE tool_healing_methods (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id             TEXT NOT NULL,
  user_id             UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username            TEXT NOT NULL DEFAULT 'Anonym',
  method_name         TEXT NOT NULL,
  method_description  TEXT,
  category            TEXT NOT NULL DEFAULT 'alternative',
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_network_connections ── Endpunkt: materie/network
CREATE TABLE tool_network_connections (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id                 TEXT NOT NULL,
  user_id                 UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username                TEXT NOT NULL DEFAULT 'Anonym',
  connection_title        TEXT NOT NULL,
  connection_description  TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_research_documents ── Endpunkt: materie/research
CREATE TABLE tool_research_documents (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id               TEXT NOT NULL,
  user_id               UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username              TEXT NOT NULL DEFAULT 'Anonym',
  document_title        TEXT NOT NULL,
  document_description  TEXT,
  document_type         TEXT NOT NULL DEFAULT 'research',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_ufo_sightings ── Endpunkt: materie/ufo
CREATE TABLE tool_ufo_sightings (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT NOT NULL,
  user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username      TEXT NOT NULL DEFAULT 'Anonym',
  title         TEXT NOT NULL,
  description   TEXT,
  location      TEXT,
  sighting_date TEXT,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  object_type   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_connections ── Endpunkt: materie/connections
CREATE TABLE tool_connections (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id           TEXT NOT NULL,
  user_id           UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username          TEXT NOT NULL DEFAULT 'Anonym',
  connection_title  TEXT NOT NULL,
  description       TEXT,
  from_node         TEXT,
  to_node           TEXT,
  connection_type   TEXT NOT NULL DEFAULT 'related',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_artefakte ── Endpunkt: materie/artefakte
CREATE TABLE tool_artefakte (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  name        TEXT NOT NULL,
  description TEXT,
  category    TEXT,
  image_url   TEXT,
  metadata    JSONB NOT NULL DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_news ── Endpunkt: materie/news
CREATE TABLE tool_news (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  headline    TEXT NOT NULL,
  content     TEXT,
  source_url  TEXT,
  category    TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── tool_patente ── Endpunkt: materie/patente
CREATE TABLE tool_patente (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT NOT NULL,
  user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username      TEXT NOT NULL DEFAULT 'Anonym',
  patent_number TEXT,
  title         TEXT NOT NULL,
  description   TEXT,
  category      TEXT,
  filed_date    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
