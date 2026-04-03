-- ============================================================
-- WELTENBIBLIOTHEK – V10 FULL PRODUCTION SCHEMA
-- Datum: 2026-04-02
-- Enthält: Alle fehlenden Tabellen, RLS, Indizes, Trigger
-- ============================================================

-- ── EXTENSIONS ────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Für LIKE-Suche

-- ============================================================
-- TABELLEN (CREATE IF NOT EXISTS)
-- ============================================================

-- ── PROFILES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT UNIQUE,
  display_name  TEXT,
  avatar_url    TEXT,
  bio           TEXT,
  world         TEXT DEFAULT 'materie' CHECK (world IN ('materie','energie','both')),
  role          TEXT DEFAULT 'user' CHECK (role IN ('user','mod','moderator','admin','root-admin')),
  is_banned     BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── ARTICLES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS articles (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username        TEXT NOT NULL DEFAULT 'Anonym',
  title           TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,
  content         TEXT NOT NULL DEFAULT '',
  world           TEXT DEFAULT 'materie',
  category        TEXT,
  tags            TEXT[] DEFAULT '{}',
  image_url       TEXT,
  cover_image_url TEXT,
  is_published    BOOLEAN DEFAULT TRUE,
  view_count      INTEGER DEFAULT 0,
  like_count      INTEGER DEFAULT 0,
  comment_count   INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── LIKES ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(article_id, user_id)
);

-- ── BOOKMARKS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookmarks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(article_id, user_id)
);

-- ── COMMENTS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  content     TEXT NOT NULL,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── CHAT ROOMS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_rooms (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  description TEXT,
  world       TEXT DEFAULT 'materie',
  category    TEXT,
  icon        TEXT,
  color       TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── CHAT MESSAGES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username      TEXT NOT NULL DEFAULT 'Anonym',
  avatar_url    TEXT,
  content       TEXT NOT NULL DEFAULT '',
  message       TEXT DEFAULT '',
  message_type  TEXT DEFAULT 'text' CHECK (message_type IN ('text','image','voice','file','system')),
  is_deleted    BOOLEAN DEFAULT FALSE,
  deleted_at    TIMESTAMPTZ,
  is_edited     BOOLEAN DEFAULT FALSE,
  edited        BOOLEAN DEFAULT FALSE,
  edited_at     TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Safe column additions for existing installations
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS is_edited  BOOLEAN DEFAULT FALSE;
ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ── NOTIFICATIONS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type        TEXT NOT NULL CHECK (type IN ('like','comment','follow','mention','system','message','achievement')),
  title       TEXT NOT NULL DEFAULT '',
  message     TEXT NOT NULL DEFAULT '',
  data        JSONB DEFAULT '{}',
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── MESSAGE REACTIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS message_reactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id  UUID REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  emoji       TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);

-- ── VOICE PARTICIPANTS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS voice_participants (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  avatar_url  TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  is_muted    BOOLEAN DEFAULT FALSE,
  joined_at   TIMESTAMPTZ DEFAULT NOW(),
  left_at     TIMESTAMPTZ,
  UNIQUE(room_id, user_id)
);

-- ── TOOL TABLES (Inline-Tools) ────────────────────────────────
CREATE TABLE IF NOT EXISTS tool_artefakte (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  name        TEXT NOT NULL,
  description TEXT,
  category    TEXT,
  image_url   TEXT,
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_chakra_readings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  chakra_name TEXT NOT NULL,
  energy_level INTEGER DEFAULT 50 CHECK (energy_level BETWEEN 0 AND 100),
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_connections (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id         TEXT,
  user_id         UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username        TEXT NOT NULL DEFAULT 'Anonym',
  connection_title TEXT NOT NULL,
  description     TEXT,
  from_node       TEXT,
  to_node         TEXT,
  connection_type TEXT DEFAULT 'related',
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_heilfrequenz (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  frequency   FLOAT NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  duration_seconds INTEGER DEFAULT 60,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_news (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  headline    TEXT NOT NULL,
  content     TEXT,
  source_url  TEXT,
  category    TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_patente (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT,
  user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username      TEXT NOT NULL DEFAULT 'Anonym',
  patent_number TEXT,
  title         TEXT NOT NULL,
  description   TEXT,
  category      TEXT,
  filed_date    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_traeume (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  dream_title TEXT NOT NULL,
  dream_text  TEXT NOT NULL,
  symbols     TEXT[],
  mood        TEXT,
  clarity     INTEGER DEFAULT 5 CHECK (clarity BETWEEN 1 AND 10),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_ufo_sightings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  title       TEXT NOT NULL,
  description TEXT,
  location    TEXT,
  sighting_date TEXT,
  latitude    FLOAT,
  longitude   FLOAT,
  object_type TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_group_meditation (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id       TEXT,
  user_id       UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username      TEXT NOT NULL DEFAULT 'Anonym',
  session_title TEXT NOT NULL,
  intention     TEXT,
  duration_mins INTEGER DEFAULT 15,
  participants  INTEGER DEFAULT 1,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tool_bewusstsein_journal (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id     TEXT,
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  entry_title TEXT NOT NULL,
  entry_text  TEXT NOT NULL,
  mood        TEXT,
  energy_level INTEGER DEFAULT 5 CHECK (energy_level BETWEEN 1 AND 10),
  tags        TEXT[],
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── USER ACHIEVEMENTS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_achievements (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id  TEXT NOT NULL,
  achievement_name TEXT NOT NULL,
  xp_earned       INTEGER DEFAULT 0,
  unlocked_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- ── USER STATS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_stats (
  user_id         UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  total_xp        INTEGER DEFAULT 0,
  level           INTEGER DEFAULT 1,
  articles_read   INTEGER DEFAULT 0,
  articles_written INTEGER DEFAULT 0,
  chat_messages   INTEGER DEFAULT 0,
  login_streak    INTEGER DEFAULT 0,
  last_active     TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- INDIZES (Performance)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_articles_world ON articles(world);
CREATE INDEX IF NOT EXISTS idx_articles_category ON articles(category);
CREATE INDEX IF NOT EXISTS idx_articles_published ON articles(is_published);
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON articles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_user_id ON articles(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at ASC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_is_deleted ON chat_messages(is_deleted);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_likes_article_id ON likes(article_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_article_id ON comments(article_id);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_world ON profiles(world);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- ============================================================
-- RLS (Row Level Security)
-- ============================================================

-- PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles_public_select"   ON profiles;
DROP POLICY IF EXISTS "profiles_owner_update"    ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own"      ON profiles;
CREATE POLICY "profiles_public_select"  ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_owner_update"   ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own"     ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ARTICLES
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "articles_public_read"   ON articles;
DROP POLICY IF EXISTS "articles_auth_insert"   ON articles;
DROP POLICY IF EXISTS "articles_owner_update"  ON articles;
DROP POLICY IF EXISTS "articles_owner_delete"  ON articles;
CREATE POLICY "articles_public_read"  ON articles FOR SELECT USING (is_published = true);
CREATE POLICY "articles_auth_insert"  ON articles FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);
CREATE POLICY "articles_owner_update" ON articles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "articles_owner_delete" ON articles FOR DELETE USING (auth.uid() = user_id);

-- LIKES
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "likes_public_select" ON likes;
DROP POLICY IF EXISTS "likes_auth_insert"   ON likes;
DROP POLICY IF EXISTS "likes_owner_delete"  ON likes;
CREATE POLICY "likes_public_select" ON likes FOR SELECT USING (true);
CREATE POLICY "likes_auth_insert"   ON likes FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);
CREATE POLICY "likes_owner_delete"  ON likes FOR DELETE USING (auth.uid() = user_id);

-- BOOKMARKS
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "bookmarks_owner_select" ON bookmarks;
DROP POLICY IF EXISTS "bookmarks_auth_insert"  ON bookmarks;
DROP POLICY IF EXISTS "bookmarks_owner_delete" ON bookmarks;
CREATE POLICY "bookmarks_owner_select" ON bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bookmarks_auth_insert"  ON bookmarks FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);
CREATE POLICY "bookmarks_owner_delete" ON bookmarks FOR DELETE USING (auth.uid() = user_id);

-- COMMENTS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "comments_public_select" ON comments;
DROP POLICY IF EXISTS "comments_auth_insert"   ON comments;
DROP POLICY IF EXISTS "comments_owner_update"  ON comments;
DROP POLICY IF EXISTS "comments_owner_delete"  ON comments;
CREATE POLICY "comments_public_select" ON comments FOR SELECT USING (is_deleted = false);
CREATE POLICY "comments_auth_insert"   ON comments FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);
CREATE POLICY "comments_owner_update"  ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "comments_owner_delete"  ON comments FOR DELETE USING (auth.uid() = user_id);

-- CHAT ROOMS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "chat_rooms_public_select" ON chat_rooms;
DROP POLICY IF EXISTS "chat_rooms_admin_insert"  ON chat_rooms;
CREATE POLICY "chat_rooms_public_select" ON chat_rooms FOR SELECT USING (true);
CREATE POLICY "chat_rooms_admin_insert"  ON chat_rooms FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM profiles WHERE role IN ('admin','root-admin'))
);

-- CHAT MESSAGES
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "chat_messages_select"      ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert"      ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_soft_delete" ON chat_messages;
CREATE POLICY "chat_messages_select"      ON chat_messages FOR SELECT USING (is_deleted = false);
-- ✅ FIX v5.11: Erlaube auch anonyme Inserts (user_id = NULL) damit der Cloudflare Worker
--    auch ohne Service-Role-Key Nachrichten einfügen kann.
--    Authentifizierte Nutzer dürfen user_id setzen (muss zur eigenen UUID passen).
--    Anonyme Nutzer (kein Auth-User) dürfen nur wenn user_id NULL ist.
CREATE POLICY "chat_messages_insert" ON chat_messages FOR INSERT WITH CHECK (
  (auth.uid() IS NULL AND user_id IS NULL)          -- Anonym (Worker ohne Service-Key)
  OR (auth.uid() IS NOT NULL AND auth.uid() = user_id)  -- Eingeloggt: eigene UUID
  OR (auth.uid() IS NOT NULL AND user_id IS NULL)    -- Eingeloggt aber kein user_id gesetzt
);
CREATE POLICY "chat_messages_soft_delete" ON chat_messages FOR UPDATE USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM profiles WHERE role IN ('admin','root-admin','mod','moderator')));

-- NOTIFICATIONS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notifications_owner_select"     ON notifications;
DROP POLICY IF EXISTS "notifications_owner_update"     ON notifications;
DROP POLICY IF EXISTS "notifications_system_insert"    ON notifications;
CREATE POLICY "notifications_owner_select"  ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_owner_update"  ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "notifications_system_insert" ON notifications FOR INSERT WITH CHECK (true);  -- Trigger/Edge-Function darf inserieren

-- MESSAGE REACTIONS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reactions_public_select" ON message_reactions;
DROP POLICY IF EXISTS "reactions_auth_insert"   ON message_reactions;
DROP POLICY IF EXISTS "reactions_owner_delete"  ON message_reactions;
CREATE POLICY "reactions_public_select" ON message_reactions FOR SELECT USING (true);
CREATE POLICY "reactions_auth_insert"   ON message_reactions FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);
CREATE POLICY "reactions_owner_delete"  ON message_reactions FOR DELETE USING (auth.uid() = user_id);

-- VOICE PARTICIPANTS
ALTER TABLE voice_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "voice_public_select" ON voice_participants;
DROP POLICY IF EXISTS "voice_auth_insert"   ON voice_participants;
DROP POLICY IF EXISTS "voice_owner_update"  ON voice_participants;
CREATE POLICY "voice_public_select" ON voice_participants FOR SELECT USING (true);
CREATE POLICY "voice_auth_insert"   ON voice_participants FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);
CREATE POLICY "voice_owner_update"  ON voice_participants FOR UPDATE USING (auth.uid() = user_id);

-- TOOL TABLES: öffentliches Lesen, Auth-Insert, Owner-Update/Delete
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['tool_artefakte','tool_chakra_readings','tool_connections',
    'tool_heilfrequenz','tool_news','tool_patente','tool_traeume',
    'tool_ufo_sightings','tool_group_meditation','tool_bewusstsein_journal']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', t);
    EXECUTE format('DROP POLICY IF EXISTS "tool_public_select" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "tool_auth_insert" ON %I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "tool_owner_delete" ON %I;', t);
    EXECUTE format('CREATE POLICY "tool_public_select" ON %I FOR SELECT USING (true);', t);
    EXECUTE format('CREATE POLICY "tool_auth_insert" ON %I FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);', t);
    EXECUTE format('CREATE POLICY "tool_owner_delete" ON %I FOR DELETE USING (auth.uid() = user_id);', t);
  END LOOP;
END $$;

-- USER ACHIEVEMENTS
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "achievements_owner_select" ON user_achievements;
DROP POLICY IF EXISTS "achievements_system_insert" ON user_achievements;
CREATE POLICY "achievements_owner_select"  ON user_achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "achievements_system_insert" ON user_achievements FOR INSERT WITH CHECK (true);

-- USER STATS
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "stats_public_select"  ON user_stats;
DROP POLICY IF EXISTS "stats_owner_update"   ON user_stats;
DROP POLICY IF EXISTS "stats_system_insert"  ON user_stats;
CREATE POLICY "stats_public_select"  ON user_stats FOR SELECT USING (true);
CREATE POLICY "stats_owner_update"   ON user_stats FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "stats_system_insert"  ON user_stats FOR INSERT WITH CHECK (true);

-- ============================================================
-- STORAGE POLICIES (avatars + media)
-- ============================================================
DROP POLICY IF EXISTS "avatars_public_read"    ON storage.objects;
DROP POLICY IF EXISTS "avatars_auth_insert"    ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_update"   ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_delete"   ON storage.objects;
DROP POLICY IF EXISTS "media_public_read"      ON storage.objects;
DROP POLICY IF EXISTS "media_auth_insert"      ON storage.objects;
DROP POLICY IF EXISTS "media_owner_delete"     ON storage.objects;

CREATE POLICY "avatars_public_read"  ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "avatars_auth_insert"  ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() IS NOT NULL);
CREATE POLICY "avatars_owner_update" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "avatars_owner_delete" ON storage.objects FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "media_public_read"    ON storage.objects FOR SELECT USING (bucket_id = 'media');
CREATE POLICY "media_auth_insert"    ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'media' AND auth.uid() IS NOT NULL);
CREATE POLICY "media_owner_delete"   ON storage.objects FOR DELETE USING (bucket_id = 'media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- REALTIME AKTIVIEREN
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE voice_participants;

-- ============================================================
-- TRIGGER: Auto-Profile bei Registration
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, display_name, world)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'world', 'materie')
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_stats (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- TRIGGER: Notification bei Like
-- ============================================================
CREATE OR REPLACE FUNCTION notify_on_like() RETURNS TRIGGER AS $$
DECLARE article_author_id UUID;
BEGIN
  SELECT user_id INTO article_author_id FROM articles WHERE id = NEW.article_id;
  IF article_author_id IS NOT NULL AND article_author_id != NEW.user_id THEN
    INSERT INTO notifications (user_id, type, title, message, data)
    VALUES (
      article_author_id,
      'like',
      'Neues Like ❤️',
      'Jemand hat deinen Artikel geliked',
      jsonb_build_object('article_id', NEW.article_id, 'from_user_id', NEW.user_id)
    )
    ON CONFLICT DO NOTHING;
    -- Artikel like_count aktualisieren
    UPDATE articles SET like_count = like_count + 1 WHERE id = NEW.article_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_like_notify ON likes;
CREATE TRIGGER on_like_notify
  AFTER INSERT ON likes
  FOR EACH ROW EXECUTE FUNCTION notify_on_like();

-- Trigger für Unlike (Decrement)
CREATE OR REPLACE FUNCTION on_unlike() RETURNS TRIGGER AS $$
BEGIN
  UPDATE articles SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.article_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_like_delete ON likes;
CREATE TRIGGER on_like_delete
  AFTER DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION on_unlike();

-- ============================================================
-- TRIGGER: Notification bei Kommentar
-- ============================================================
CREATE OR REPLACE FUNCTION notify_on_comment() RETURNS TRIGGER AS $$
DECLARE article_author_id UUID;
BEGIN
  SELECT user_id INTO article_author_id FROM articles WHERE id = NEW.article_id;
  IF article_author_id IS NOT NULL AND article_author_id != NEW.user_id THEN
    INSERT INTO notifications (user_id, type, title, message, data)
    VALUES (
      article_author_id,
      'comment',
      'Neuer Kommentar 💬',
      NEW.username || ' hat deinen Artikel kommentiert',
      jsonb_build_object('article_id', NEW.article_id, 'comment_id', NEW.id)
    )
    ON CONFLICT DO NOTHING;
    -- Artikel comment_count aktualisieren
    UPDATE articles SET comment_count = comment_count + 1 WHERE id = NEW.article_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_comment_notify ON comments;
CREATE TRIGGER on_comment_notify
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment();

-- ============================================================
-- TRIGGER: Updated_at automatisch setzen
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_articles_updated_at ON articles;
CREATE TRIGGER set_articles_updated_at BEFORE UPDATE ON articles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_comments_updated_at ON comments;
CREATE TRIGGER set_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- INITIAL DATA: Standard Chat-Rooms
-- ============================================================
INSERT INTO chat_rooms (id, name, description, world, category, icon, color, is_active) VALUES
  ('materie-politik',     'Politik',          'Macht & Kontrolle',          'materie', 'politik',     '🏛️',  '#E53935', TRUE),
  ('materie-wirtschaft',  'Wirtschaft',       'Finanzsystem & Wirtschaft',  'materie', 'wirtschaft',  '💰',  '#FDD835', TRUE),
  ('materie-wissenschaft','Wissenschaft',     'Forschung & Technologie',    'materie', 'wissenschaft','🔬',  '#1E88E5', TRUE),
  ('materie-gesellschaft','Gesellschaft',     'Soziale Strukturen',         'materie', 'gesellschaft','🌍',  '#43A047', TRUE),
  ('materie-geschichte',  'Geschichte',       'Verborgene Geschichte',      'materie', 'geschichte',  '📜',  '#8E24AA', TRUE),
  ('materie-medien',      'Medien',           'Propaganda & Narrative',     'materie', 'medien',      '📺',  '#F4511E', TRUE),
  ('materie-ufos',        'UFOs & Anomalien', 'Unerklärliche Phänomene',   'materie', 'anomalien',   '🛸',  '#00ACC1', TRUE),
  ('materie-finanzen',    'Finanzen',         'Wirtschaft & Finanzsystem',  'materie', 'finanzen',    '💰',  '#FFD700', TRUE),
  ('energie-meditation',  'Meditation',       'Stille & innerer Frieden',   'energie', 'meditation',  '🧘',  '#7B1FA2', TRUE),
  ('energie-chakren',     'Chakren',          'Energiezentren aktivieren',  'energie', 'chakren',     '🌈',  '#E91E63', TRUE),
  ('energie-kristalle',   'Kristalle',        'Heilende Steine',            'energie', 'kristalle',   '💎',  '#00BCD4', TRUE),
  ('energie-astrologie',  'Astrologie',       'Sterne & Planeten',          'energie', 'astrologie',  '⭐', '#FF9800', TRUE),
  ('energie-bewusstsein', 'Bewusstsein',      'Höhere Wahrnehmung',        'energie', 'bewusstsein', '🧠',  '#4CAF50', TRUE),
  ('energie-traumdeutung','Traumdeutung',     'Symbole entschlüsseln',     'energie', 'traumdeutung','🌙',  '#3F51B5', TRUE)
ON CONFLICT (id) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  is_active   = EXCLUDED.is_active;

-- ============================================================
-- FERTIG
-- ============================================================
-- Führe dieses Script im Supabase SQL Editor aus:
-- https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql/new
