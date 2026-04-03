-- ============================================================
-- WELTENBIBLIOTHEK – Supabase Produktions-Schema
-- Zielarchitektur v2.0 (2026-04-02)
-- ============================================================
-- Supabase übernimmt: Auth, Profile, Community, Chat, Notifications
-- Cloudflare übernimmt: Voice/WebRTC, AI/Recherche, Edge-API, Moderation-Log
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- EXTENSIONS
-- ────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Für Volltextsuche

-- ────────────────────────────────────────────────────────────
-- PROFILES (User-Stammdaten, verknüpft mit auth.users)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT UNIQUE NOT NULL,
  display_name  TEXT,
  bio           TEXT,
  avatar_url    TEXT,
  world         TEXT NOT NULL DEFAULT 'materie' CHECK (world IN ('materie', 'energie')),
  role          TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'moderator', 'admin', 'root_admin')),
  is_banned     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_world ON profiles(world);

-- ────────────────────────────────────────────────────────────
-- CHAT ROOMS (Raumkonfiguration)
-- ────────────────────────────────────────────────────────────
-- Tabelle existiert bereits, Erweiterung prüfen:
ALTER TABLE chat_rooms
  ADD COLUMN IF NOT EXISTS max_members   INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS message_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS member_count  INTEGER NOT NULL DEFAULT 0;

-- ────────────────────────────────────────────────────────────
-- CHAT MESSAGES (Echtzeit-Chat via Supabase Realtime)
-- ────────────────────────────────────────────────────────────
-- Tabelle existiert bereits, Erweiterung prüfen:
ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS user_id     UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS username    TEXT NOT NULL DEFAULT 'Anonym',
  ADD COLUMN IF NOT EXISTS avatar_url  TEXT,
  ADD COLUMN IF NOT EXISTS is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS edited_at   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_chat_messages_room_created
  ON chat_messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user
  ON chat_messages(user_id);

-- ────────────────────────────────────────────────────────────
-- ARTICLES (Community-Artikel/Beiträge)
-- ────────────────────────────────────────────────────────────
ALTER TABLE articles
  ADD COLUMN IF NOT EXISTS user_id     UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS username    TEXT NOT NULL DEFAULT 'Anonym',
  ADD COLUMN IF NOT EXISTS title       TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS content     TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS world       TEXT NOT NULL DEFAULT 'materie' CHECK (world IN ('materie', 'energie')),
  ADD COLUMN IF NOT EXISTS category    TEXT,
  ADD COLUMN IF NOT EXISTS tags        TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS image_url   TEXT,
  ADD COLUMN IF NOT EXISTS likes_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS comments_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_articles_world_created
  ON articles(world, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_user
  ON articles(user_id);

-- ────────────────────────────────────────────────────────────
-- COMMENTS (Kommentare zu Artikeln)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  username    TEXT NOT NULL DEFAULT 'Anonym',
  content     TEXT NOT NULL,
  is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_article ON comments(article_id, created_at);
CREATE INDEX IF NOT EXISTS idx_comments_user ON comments(user_id);

-- ────────────────────────────────────────────────────────────
-- LIKES (Likes auf Artikel)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS likes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(article_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_article ON likes(article_id);
CREATE INDEX IF NOT EXISTS idx_likes_user ON likes(user_id);

-- ────────────────────────────────────────────────────────────
-- BOOKMARKS (Gespeicherte Artikel)
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookmarks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  article_id  UUID REFERENCES articles(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(article_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON bookmarks(user_id);

-- ────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ────────────────────────────────────────────────────────────
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS type        TEXT NOT NULL DEFAULT 'info',
  ADD COLUMN IF NOT EXISTS title       TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS message     TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS is_read     BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS data        JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON notifications(user_id, is_read, created_at DESC);

-- ────────────────────────────────────────────────────────────
-- RESEARCH RESULTS (Recherche-Ergebnisse für Supabase Storage)
-- ────────────────────────────────────────────────────────────
ALTER TABLE research_results
  ADD COLUMN IF NOT EXISTS user_id     UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS query       TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS results     JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS world       TEXT DEFAULT 'materie',
  ADD COLUMN IF NOT EXISTS created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- Jede Tabelle muss geschützt sein!
-- ============================================================

-- PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles sind öffentlich lesbar" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "User kann eigenes Profil updaten" ON profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "User-Profil wird bei Registrierung erstellt" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- CHAT ROOMS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chat-Räume sind öffentlich lesbar" ON chat_rooms
  FOR SELECT USING (true);

CREATE POLICY "Nur Admins können Chat-Räume erstellen" ON chat_rooms
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('admin', 'root_admin')
    )
  );

-- CHAT MESSAGES
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chat-Nachrichten sind lesbar" ON chat_messages
  FOR SELECT USING (is_deleted = false);

CREATE POLICY "Auth-User können Nachrichten senden" ON chat_messages
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND is_banned = true
    )
  );

CREATE POLICY "User kann eigene Nachrichten bearbeiten" ON chat_messages
  FOR UPDATE USING (auth.uid() = user_id);

-- ARTICLES
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Veröffentlichte Artikel sind öffentlich" ON articles
  FOR SELECT USING (is_published = true);

CREATE POLICY "Auth-User können Artikel erstellen" ON articles
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() = user_id
  );

CREATE POLICY "User kann eigene Artikel bearbeiten" ON articles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "User kann eigene Artikel löschen" ON articles
  FOR DELETE USING (auth.uid() = user_id);

-- COMMENTS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kommentare sind öffentlich lesbar" ON comments
  FOR SELECT USING (is_deleted = false);

CREATE POLICY "Auth-User können kommentieren" ON comments
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "User kann eigene Kommentare bearbeiten" ON comments
  FOR UPDATE USING (auth.uid() = user_id);

-- LIKES
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes sind öffentlich zählbar" ON likes
  FOR SELECT USING (true);

CREATE POLICY "Auth-User können liken" ON likes
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "User kann eigene Likes entfernen" ON likes
  FOR DELETE USING (auth.uid() = user_id);

-- BOOKMARKS
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User sieht nur eigene Bookmarks" ON bookmarks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Auth-User können bookmarken" ON bookmarks
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "User kann eigene Bookmarks löschen" ON bookmarks
  FOR DELETE USING (auth.uid() = user_id);

-- NOTIFICATIONS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User sieht nur eigene Notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System kann Notifications erstellen" ON notifications
  FOR INSERT WITH CHECK (true); -- Nur via Service Role Key

CREATE POLICY "User kann eigene Notifications als gelesen markieren" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- RESEARCH RESULTS
ALTER TABLE research_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User sieht eigene Research-Ergebnisse" ON research_results
  FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Auth-User können Recherche-Ergebnisse speichern" ON research_results
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-Update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER articles_updated_at
  BEFORE UPDATE ON articles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-Profile bei Registrierung erstellen
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Likes-Counter auf articles aktualisieren
CREATE OR REPLACE FUNCTION update_article_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE articles SET likes_count = likes_count + 1 WHERE id = NEW.article_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE articles SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.article_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER articles_likes_count
  AFTER INSERT OR DELETE ON likes
  FOR EACH ROW EXECUTE FUNCTION update_article_likes_count();

-- Comments-Counter auf articles
CREATE OR REPLACE FUNCTION update_article_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE articles SET comments_count = comments_count + 1 WHERE id = NEW.article_id;
  ELSIF TG_OP = 'UPDATE' AND NEW.is_deleted = true AND OLD.is_deleted = false THEN
    UPDATE articles SET comments_count = GREATEST(0, comments_count - 1) WHERE id = NEW.article_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER articles_comments_count
  AFTER INSERT OR UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_article_comments_count();

-- ============================================================
-- STORAGE BUCKETS – Konfiguration (via Supabase Dashboard)
-- ============================================================
-- Bucket: avatars  (public: true)  → Profilbilder
-- Bucket: media    (public: true)  → Community-Bilder, Post-Bilder
-- 
-- Storage Policies (via Dashboard setzen):
-- avatars: User kann eigene Datei hochladen (path = user_id/*)
-- media: Auth-User können hochladen, alle können lesen

-- ============================================================
-- REALTIME – Tabellen für Subscriptions aktivieren
-- (via Supabase Dashboard → Database → Replication → Tabellen auswählen)
-- ============================================================
-- Aktiviere Realtime für:
-- ✅ chat_messages
-- ✅ notifications
-- ✅ profiles (presence)

-- ============================================================
-- HINWEIS: D1-Migration
-- ============================================================
-- Bestehende D1-Daten (26 User, 38 Chat-Messages, 5 Chat-Rooms)
-- können via Insert-Statements migriert werden.
-- Backup-SQLs sind in: docs/backups/d1/
