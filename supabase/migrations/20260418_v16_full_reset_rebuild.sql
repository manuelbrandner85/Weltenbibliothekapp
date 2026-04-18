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

-- ============================================================
-- PHASE H: INDIZES
-- ============================================================

-- Core
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_world    ON profiles(world);
CREATE INDEX idx_profiles_role     ON profiles(role);

CREATE INDEX idx_articles_world       ON articles(world);
CREATE INDEX idx_articles_category    ON articles(category);
CREATE INDEX idx_articles_published   ON articles(is_published);
CREATE INDEX idx_articles_created_at  ON articles(created_at DESC);
CREATE INDEX idx_articles_user_id     ON articles(user_id);
CREATE INDEX idx_articles_title_trgm  ON articles USING GIN (title gin_trgm_ops);

CREATE INDEX idx_comments_article_id  ON comments(article_id);
CREATE INDEX idx_comments_user_id     ON comments(user_id);

CREATE INDEX idx_likes_article_id  ON likes(article_id);
CREATE INDEX idx_likes_user_id     ON likes(user_id);

CREATE INDEX idx_bookmarks_user_id     ON bookmarks(user_id);
CREATE INDEX idx_bookmarks_article_id  ON bookmarks(article_id);

CREATE INDEX idx_chat_rooms_world  ON chat_rooms(world);
CREATE INDEX idx_chat_rooms_active ON chat_rooms(is_active);

CREATE INDEX idx_chat_messages_room_id     ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_created_at  ON chat_messages(created_at DESC);
CREATE INDEX idx_chat_messages_is_deleted  ON chat_messages(is_deleted);
CREATE INDEX idx_chat_messages_user_id     ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_reply_to    ON chat_messages(reply_to_id);
CREATE INDEX idx_chat_messages_read_by     ON chat_messages USING GIN (read_by);

CREATE INDEX idx_message_reactions_message_id ON message_reactions(message_id);

CREATE INDEX idx_notifications_user_id  ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created  ON notifications(created_at DESC);

-- Push / Voice / Gamification
CREATE INDEX idx_push_subscriptions_user_id ON push_subscriptions(user_id);
CREATE INDEX idx_push_subscriptions_active  ON push_subscriptions(is_active) WHERE is_active = TRUE;

CREATE INDEX idx_notification_queue_pending
  ON notification_queue(status, created_at) WHERE status = 'pending';

CREATE INDEX idx_voice_participants_room    ON voice_participants(room_id, is_active);
CREATE INDEX idx_voice_participants_user    ON voice_participants(user_id);

CREATE INDEX idx_user_achievements_user_id  ON user_achievements(user_id);

-- Tools (alle: room_id + created_at DESC)
CREATE INDEX idx_tool_meditation_sessions_room   ON tool_meditation_sessions(room_id, created_at DESC);
CREATE INDEX idx_tool_kristalle_room             ON tool_kristalle(room_id, created_at DESC);
CREATE INDEX idx_tool_chakra_readings_room       ON tool_chakra_readings(room_id, created_at DESC);
CREATE INDEX idx_tool_heilfrequenz_room          ON tool_heilfrequenz(room_id, created_at DESC);
CREATE INDEX idx_tool_traeume_room               ON tool_traeume(room_id, created_at DESC);
CREATE INDEX idx_tool_bewusstsein_journal_room   ON tool_bewusstsein_journal(room_id, created_at DESC);
CREATE INDEX idx_tool_group_meditation_room      ON tool_group_meditation(room_id, created_at DESC);

CREATE INDEX idx_tool_geopolitics_events_room    ON tool_geopolitics_events(room_id, created_at DESC);
CREATE INDEX idx_tool_history_events_room        ON tool_history_events(room_id, created_at DESC);
CREATE INDEX idx_tool_history_events_year        ON tool_history_events(event_year);
CREATE INDEX idx_tool_healing_methods_room       ON tool_healing_methods(room_id, created_at DESC);
CREATE INDEX idx_tool_network_connections_room   ON tool_network_connections(room_id, created_at DESC);
CREATE INDEX idx_tool_research_documents_room    ON tool_research_documents(room_id, created_at DESC);
CREATE INDEX idx_tool_ufo_sightings_room         ON tool_ufo_sightings(room_id, created_at DESC);
CREATE INDEX idx_tool_connections_room           ON tool_connections(room_id, created_at DESC);
CREATE INDEX idx_tool_artefakte_room             ON tool_artefakte(room_id, created_at DESC);
CREATE INDEX idx_tool_news_room                  ON tool_news(room_id, created_at DESC);
CREATE INDEX idx_tool_patente_room               ON tool_patente(room_id, created_at DESC);

-- ============================================================
-- PHASE I: UPDATED_AT TRIGGER
-- ============================================================
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER articles_updated_at
  BEFORE UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER push_subscriptions_updated_at
  BEFORE UPDATE ON push_subscriptions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER user_stats_updated_at
  BEFORE UPDATE ON user_stats
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- PHASE J: RLS + POLICIES
-- Strategie: anon darf lesen (wo sinnvoll) + chat schreiben.
--           service_role bypasst RLS automatisch (Worker).
-- ============================================================

-- RLS auf allen Tabellen aktivieren
ALTER TABLE profiles                ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles                ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments                ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks               ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms              ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages           ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications           ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_subscriptions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_queue      ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_participants      ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements       ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stats              ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_meditation_sessions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_kristalle            ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_chakra_readings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_heilfrequenz         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_traeume              ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_bewusstsein_journal  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_group_meditation     ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_geopolitics_events   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_history_events       ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_healing_methods      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_network_connections  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_research_documents   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_ufo_sightings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_connections          ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_artefakte            ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_news                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE tool_patente              ENABLE ROW LEVEL SECURITY;

-- ── PUBLIC READ (anon + authenticated dürfen SELECT) ─────────
CREATE POLICY "public_read" ON profiles          FOR SELECT USING (true);
CREATE POLICY "public_read" ON articles          FOR SELECT USING (is_published = TRUE);
CREATE POLICY "public_read" ON comments          FOR SELECT USING (is_deleted = FALSE);
CREATE POLICY "public_read" ON likes             FOR SELECT USING (true);
CREATE POLICY "public_read" ON chat_rooms        FOR SELECT USING (is_active = TRUE);
CREATE POLICY "public_read" ON chat_messages     FOR SELECT USING (is_deleted = FALSE);
CREATE POLICY "public_read" ON message_reactions FOR SELECT USING (true);
CREATE POLICY "public_read" ON voice_participants FOR SELECT USING (true);
CREATE POLICY "public_read" ON user_achievements FOR SELECT USING (true);
CREATE POLICY "public_read" ON user_stats        FOR SELECT USING (true);

-- Tools: alle public lesbar (Welt-interne Daten)
CREATE POLICY "public_read" ON tool_meditation_sessions  FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_kristalle            FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_chakra_readings      FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_heilfrequenz         FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_traeume              FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_bewusstsein_journal  FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_group_meditation     FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_geopolitics_events   FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_history_events       FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_healing_methods      FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_network_connections  FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_research_documents   FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_ufo_sightings        FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_connections          FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_artefakte            FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_news                 FOR SELECT USING (true);
CREATE POLICY "public_read" ON tool_patente              FOR SELECT USING (true);

-- ── PRIVATE (nur service_role) ───────────────────────────────
-- bookmarks, notifications, push_subscriptions, notification_queue
-- → KEINE public Policy → nur service_role (bypasst RLS) kommt dran

-- ── ANON WRITE (Flutter direkt via anon-Key) ─────────────────
-- chat_messages: Flutter schreibt direkt (Realtime-UX)
CREATE POLICY "anon_insert" ON chat_messages FOR INSERT WITH CHECK (true);
-- message_reactions: Flutter schreibt direkt (reagieren/unreagieren)
CREATE POLICY "anon_insert" ON message_reactions FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_delete" ON message_reactions FOR DELETE USING (true);
-- likes: Flutter toggled direkt
CREATE POLICY "anon_insert" ON likes FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_delete" ON likes FOR DELETE USING (true);
-- voice_participants: join/leave direkt
CREATE POLICY "anon_insert" ON voice_participants FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_update" ON voice_participants FOR UPDATE USING (true);
CREATE POLICY "anon_delete" ON voice_participants FOR DELETE USING (true);
