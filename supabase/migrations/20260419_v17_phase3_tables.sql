-- ============================================================
-- WELTENBIBLIOTHEK v17 – PHASE 3: Neue Tabellen für Supabase-Backend
-- Datum: 2026-04-19
-- Projekt: adtviduaftdquvfjpojb
--
-- ADDITIVE Migration – löscht KEINE bestehenden v16-Tabellen.
-- Fügt hinzu:
--   • user_profiles  (auth.users FK für Supabase Auth)
--   • research_sessions  (Tavily-Recherche-Ergebnisse)
--   • community_posts  (Social Posts, getrennt von articles)
--   • post_likes / post_comments  (für community_posts)
--   • map_locations  (Karte-Screen-Daten)
--   • conspiracy_connections / healing_methods / geopolitics_events
--     (leichtgewichtige Standalone-Tabellen für Flutter Tools)
--   • bookmarks  (user_profiles FK-kompatibel)
--   • RLS-Policies für alle neuen Tabellen
--   • Helper-Funktionen: increment_research_count, increment_likes, decrement_likes
--   • Chat-Room-Seed-Daten (beide Welten)
-- ============================================================

-- ── PHASE A: NEUE TABELLEN ───────────────────────────────────

-- ── USER PROFILES (auth.users FK) ────────────────────────────
-- Erweitert Supabase Auth – wird beim ersten Login automatisch angelegt.
CREATE TABLE IF NOT EXISTS user_profiles (
  id                      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username                TEXT UNIQUE,
  avatar_url              TEXT,
  world_type              TEXT NOT NULL DEFAULT 'materie' CHECK (world_type IN ('materie','energie','both')),
  is_admin                BOOLEAN NOT NULL DEFAULT FALSE,
  spiritual_level         INTEGER NOT NULL DEFAULT 1,
  meditation_minutes      INTEGER NOT NULL DEFAULT 0,
  practices_done          INTEGER NOT NULL DEFAULT 0,
  chakra_balance          JSONB NOT NULL DEFAULT '{}',
  daily_streak            INTEGER NOT NULL DEFAULT 0,
  total_articles_read     INTEGER NOT NULL DEFAULT 0,
  research_sessions_count INTEGER NOT NULL DEFAULT 0,
  bookmarked_topics       TEXT[] NOT NULL DEFAULT '{}',
  shared_findings         INTEGER NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: updated_at automatisch setzen
CREATE TRIGGER user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── RESEARCH SESSIONS (Tavily-Ergebnisse) ────────────────────
CREATE TABLE IF NOT EXISTS research_sessions (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  query      TEXT NOT NULL,
  answer     TEXT,
  results    JSONB NOT NULL DEFAULT '{}',
  source     TEXT NOT NULL DEFAULT 'tavily',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_research_sessions_user_id   ON research_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_research_sessions_created_at ON research_sessions(created_at DESC);

-- ── COMMUNITY POSTS (Social Feed) ────────────────────────────
CREATE TABLE IF NOT EXISTS community_posts (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username       TEXT NOT NULL DEFAULT 'Anonym',
  world_type     TEXT NOT NULL DEFAULT 'materie' CHECK (world_type IN ('materie','energie','both')),
  content        TEXT NOT NULL,
  tags           TEXT[] NOT NULL DEFAULT '{}',
  image_url      TEXT,
  media_urls     TEXT[] NOT NULL DEFAULT '{}',
  likes_count    INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_posts_world_type  ON community_posts(world_type);
CREATE INDEX IF NOT EXISTS idx_community_posts_user_id     ON community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_created_at  ON community_posts(created_at DESC);

-- ── POST LIKES (für community_posts) ─────────────────────────
CREATE TABLE IF NOT EXISTS post_likes (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);

-- ── POST COMMENTS (für community_posts) ──────────────────────
CREATE TABLE IF NOT EXISTS post_comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username   TEXT NOT NULL DEFAULT 'Anonym',
  content    TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id);

-- ── MAP LOCATIONS (Karte-Screen) ──────────────────────────────
CREATE TABLE IF NOT EXISTS map_locations (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title        TEXT NOT NULL,
  description  TEXT,
  latitude     DOUBLE PRECISION NOT NULL,
  longitude    DOUBLE PRECISION NOT NULL,
  category     TEXT,
  subcategory  TEXT,
  year_from    INTEGER,
  year_to      INTEGER,
  world_type   TEXT NOT NULL DEFAULT 'materie' CHECK (world_type IN ('materie','energie','both')),
  image_urls   TEXT[] NOT NULL DEFAULT '{}',
  video_urls   TEXT[] NOT NULL DEFAULT '{}',
  thumbnail_url TEXT,
  source_urls  TEXT[] NOT NULL DEFAULT '{}',
  created_by   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_map_locations_world_type  ON map_locations(world_type);
CREATE INDEX IF NOT EXISTS idx_map_locations_category    ON map_locations(category);
CREATE INDEX IF NOT EXISTS idx_map_locations_lat_lng     ON map_locations(latitude, longitude);

-- ── CONSPIRACY CONNECTIONS (Tool: Verbindungsnetz) ────────────
CREATE TABLE IF NOT EXISTS conspiracy_connections (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL,
  user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  title       TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conspiracy_connections_room_id ON conspiracy_connections(room_id, created_at DESC);

-- ── HEALING METHODS (Tool: Alternative Heilmethoden) ─────────
CREATE TABLE IF NOT EXISTS healing_methods (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL,
  user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  name        TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_healing_methods_room_id ON healing_methods(room_id, created_at DESC);

-- ── GEOPOLITICS EVENTS (Tool: Geopolitik-Kartierung) ─────────
CREATE TABLE IF NOT EXISTS geopolitics_events (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT NOT NULL,
  user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  title       TEXT NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geopolitics_events_room_id ON geopolitics_events(room_id, created_at DESC);

-- ── BOOKMARKS (user_profiles kompatibel) ─────────────────────
-- Achtung: v16 hat bereits bookmarks mit profiles FK.
-- Diese neue Tabelle verwendet auth.users FK.
-- Name: user_bookmarks (um Konflikt zu vermeiden)
CREATE TABLE IF NOT EXISTS user_bookmarks (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  article_id UUID NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, article_id)
);

CREATE INDEX IF NOT EXISTS idx_user_bookmarks_user_id    ON user_bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_user_bookmarks_article_id ON user_bookmarks(article_id);

-- ── PHASE B: RLS AKTIVIEREN ───────────────────────────────────

ALTER TABLE user_profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE research_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts        ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE map_locations          ENABLE ROW LEVEL SECURITY;
ALTER TABLE conspiracy_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE healing_methods        ENABLE ROW LEVEL SECURITY;
ALTER TABLE geopolitics_events     ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_bookmarks         ENABLE ROW LEVEL SECURITY;

-- ── PHASE C: RLS POLICIES ─────────────────────────────────────

-- user_profiles: Öffentlich lesbar, nur eigenes Profil editierbar
CREATE POLICY "user_profiles_public_read"
  ON user_profiles FOR SELECT USING (true);

CREATE POLICY "user_profiles_own_insert"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "user_profiles_own_update"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- research_sessions: Nur eigene Sessions les- und schreibbar
CREATE POLICY "research_sessions_own_read"
  ON research_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "research_sessions_own_insert"
  ON research_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- community_posts: Öffentlich lesbar, auth User können posten
CREATE POLICY "community_posts_public_read"
  ON community_posts FOR SELECT USING (true);

CREATE POLICY "community_posts_auth_insert"
  ON community_posts FOR INSERT
  WITH CHECK (auth.uid() = user_id OR auth.uid() IS NOT NULL);

CREATE POLICY "community_posts_own_update"
  ON community_posts FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "community_posts_own_delete"
  ON community_posts FOR DELETE
  USING (auth.uid() = user_id);

-- post_likes: Öffentlich lesbar, eigene Likes erstellen/löschen
CREATE POLICY "post_likes_public_read"
  ON post_likes FOR SELECT USING (true);

CREATE POLICY "post_likes_auth_insert"
  ON post_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "post_likes_own_delete"
  ON post_likes FOR DELETE
  USING (auth.uid() = user_id);

-- post_comments: Öffentlich lesbar, auth User können kommentieren
CREATE POLICY "post_comments_public_read"
  ON post_comments FOR SELECT USING (true);

CREATE POLICY "post_comments_auth_insert"
  ON post_comments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- map_locations: Öffentlich lesbar, auth User können erstellen
CREATE POLICY "map_locations_public_read"
  ON map_locations FOR SELECT USING (true);

CREATE POLICY "map_locations_auth_insert"
  ON map_locations FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- conspiracy_connections: Öffentlich lesbar, auth User können erstellen
CREATE POLICY "conspiracy_connections_public_read"
  ON conspiracy_connections FOR SELECT USING (true);

CREATE POLICY "conspiracy_connections_auth_insert"
  ON conspiracy_connections FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- healing_methods: Öffentlich lesbar, auth User können erstellen
CREATE POLICY "healing_methods_public_read"
  ON healing_methods FOR SELECT USING (true);

CREATE POLICY "healing_methods_auth_insert"
  ON healing_methods FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- geopolitics_events: Öffentlich lesbar, auth User können erstellen
CREATE POLICY "geopolitics_events_public_read"
  ON geopolitics_events FOR SELECT USING (true);

CREATE POLICY "geopolitics_events_auth_insert"
  ON geopolitics_events FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- user_bookmarks: Nur eigene Bookmarks les- und schreibbar
CREATE POLICY "user_bookmarks_own_read"
  ON user_bookmarks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "user_bookmarks_own_insert"
  ON user_bookmarks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_bookmarks_own_delete"
  ON user_bookmarks FOR DELETE
  USING (auth.uid() = user_id);

-- ── PHASE D: REALTIME-PUBLIKATION (neue Tabellen) ────────────

ALTER PUBLICATION supabase_realtime ADD TABLE community_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE post_likes;
ALTER PUBLICATION supabase_realtime ADD TABLE post_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE map_locations;

-- ── PHASE E: HELPER-FUNKTIONEN ────────────────────────────────

-- Inkrementiert research_sessions_count im Profil des Users
CREATE OR REPLACE FUNCTION public.increment_research_count(uid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_profiles
  SET research_sessions_count = research_sessions_count + 1,
      updated_at = NOW()
  WHERE id = uid;
END;
$$;

-- Inkrementiert likes_count in community_posts
CREATE OR REPLACE FUNCTION public.increment_likes(pid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE community_posts
  SET likes_count = likes_count + 1
  WHERE id = pid;
END;
$$;

-- Dekrementiert likes_count in community_posts (min 0)
CREATE OR REPLACE FUNCTION public.decrement_likes(pid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE community_posts
  SET likes_count = GREATEST(0, likes_count - 1)
  WHERE id = pid;
END;
$$;

-- Trigger: user_profile automatisch bei Auth-Registrierung anlegen
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, world_type)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'world_type', 'materie')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── PHASE F: CHAT-ROOM SEED-DATEN ────────────────────────────
-- Materie-Räume (5 Haupt-Räume + 2 Zusatz)

INSERT INTO chat_rooms (id, name, description, world, icon, color, is_active) VALUES
  ('materie-politik',       '🎭 Geopolitik & Weltordnung',    'Weltpolitik, geheime Agenden, Neue Weltordnung',                  'materie', '🎭', '#E53935', true),
  ('materie-geschichte',    '🏛️ Alternative Geschichte',      'Verborgene Geschichte, antike Hochkulturen, Tartaria',            'materie', '🏛️', '#FF6F00', true),
  ('materie-ufo',           '🛸 UFOs & Außerirdisches',       'Sichtungen, Kontakte, geheime Programme',                         'materie', '🛸', '#43A047', true),
  ('materie-verschwoerung', '👁️ Verschwörungen & Wahrheit',  'Deep State, Geheimgesellschaften, Symbolik',                       'materie', '👁️', '#8E24AA', true),
  ('materie-wissenschaft',  '🔬 Unterdrückte Technologie',   'Freie Energie, Tesla, verbotene Erfindungen',                     'materie', '🔬', '#1E88E5', true),
  ('materie-gesundheit',    '💊 Alternative Medizin',         'Natürliche Heilmethoden, unterdrückte Therapien',                 'materie', '💊', '#00897B', true),
  ('materie-medien',        '📺 Medienkritik & Propaganda',  'Mainstream-Narrative, Zensur, alternative Quellen',               'materie', '📺', '#F4511E', true),
  ('materie-finanzen',      '💰 Finanz & Wirtschaft',        'Zentralbanken, Schuldsystem, Kryptowährungen, NWO-Finanzen',      'materie', '💰', '#FDD835', true)
ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      description = EXCLUDED.description,
      icon = EXCLUDED.icon,
      color = EXCLUDED.color;

-- Energie-Räume (6 Haupt-Räume)
INSERT INTO chat_rooms (id, name, description, world, icon, color, is_active) VALUES
  ('energie-meditation',   '🧘 Meditation & Achtsamkeit',    'Gemeinsame Meditation & Atemtechniken',                           'energie', '🧘', '#7C4DFF', true),
  ('energie-traeume',      '🌌 Astralreisen & Träume',       'Außerkörperliche Erfahrungen & Luzide Träume',                    'energie', '🌌', '#5E35B1', true),
  ('energie-chakra',       '🔥 Kundalini & Chakren',         'Chakra-Heilung & Kundalini-Energie',                              'energie', '🔥', '#F57C00', true),
  ('energie-bewusstsein',  '🔮 Spiritualität & Mystik',      'Mystische Erfahrungen, Erleuchtung, Bewusstsein',                 'energie', '🔮', '#6A1B9A', true),
  ('energie-heilung',      '💫 Energieheilung & Reiki',      'Energiearbeit, Reiki, Fernheilung',                               'energie', '💫', '#00B0FF', true),
  ('energie-astrologie',   '⭐ Astrologie & Kosmologie',     'Horoskope, Planeteneinflüsse, Mondphasen',                        'energie', '⭐', '#FFB300', true),
  ('energie-kristalle',    '💎 Kristalle & Edelsteine',      'Heilkristalle, Energiearbeit mit Steinen',                        'energie', '💎', '#00BCD4', true),
  ('energie-kraftorte',    '🏔️ Kraftorte & Geomantie',      'Energetische Orte, Ley-Linien, Vortexe',                          'energie', '🏔️', '#558B2F', true)
ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name,
      description = EXCLUDED.description,
      icon = EXCLUDED.icon,
      color = EXCLUDED.color;
