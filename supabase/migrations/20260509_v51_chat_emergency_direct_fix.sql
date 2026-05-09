-- v51: Chat-Notfall-Fix — garantiert korrekte DB-State für Chat
-- Läuft als LETZTES, immer, unabhängig von früheren Migrationen.
-- Idempotent — kann beliebig oft ausgeführt werden.

-- ── 1. Tabelle sicherstellen ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id    TEXT NOT NULL,
  user_id    UUID,
  username   TEXT,
  content    TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS message              TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url           TEXT,
  ADD COLUMN IF NOT EXISTS avatar_emoji         TEXT,
  ADD COLUMN IF NOT EXISTS message_type         TEXT,
  ADD COLUMN IF NOT EXISTS media_url            TEXT,
  ADD COLUMN IF NOT EXISTS media_type           TEXT,
  ADD COLUMN IF NOT EXISTS reply_to_id          TEXT,
  ADD COLUMN IF NOT EXISTS reply_to_content     TEXT,
  ADD COLUMN IF NOT EXISTS reply_to_sender_name TEXT,
  ADD COLUMN IF NOT EXISTS edited_at            TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_deleted           BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deleted_at           TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_by           UUID,
  ADD COLUMN IF NOT EXISTS read_by              JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS reactions            JSONB DEFAULT '{}'::jsonb;

ALTER TABLE public.chat_messages ALTER COLUMN is_deleted SET DEFAULT FALSE;
UPDATE public.chat_messages SET is_deleted = FALSE WHERE is_deleted IS NULL;
UPDATE public.chat_messages SET content = COALESCE(content, message, '') WHERE content IS NULL OR content = '';

-- ── 2. ALLE FK-Constraints auf chat_messages entfernen ──────────────────────
DO $$
DECLARE fk RECORD;
BEGIN
  FOR fk IN
    SELECT constraint_name FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'chat_messages'
      AND constraint_type = 'FOREIGN KEY'
  LOOP
    EXECUTE format('ALTER TABLE public.chat_messages DROP CONSTRAINT %I', fk.constraint_name);
  END LOOP;
END $$;

-- ── 3. Alle 17 Chat-Räume (prefixed IDs) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  world      TEXT NOT NULL,
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chat_rooms
  ADD COLUMN IF NOT EXISTS is_active     BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS message_count BIGINT DEFAULT 0;

INSERT INTO public.chat_rooms (id, name, world, is_active) VALUES
  ('materie-politik',       'Politik',           'materie', true),
  ('materie-geschichte',    'Geschichte',        'materie', true),
  ('materie-ufo',           'UFOs & Aliens',     'materie', true),
  ('materie-verschwoerung', 'Verschwörungen',    'materie', true),
  ('materie-wissenschaft',  'Wissenschaft',      'materie', true),
  ('materie-tech',          'Technologie',       'materie', true),
  ('materie-gesundheit',    'Gesundheit',        'materie', true),
  ('materie-medien',        'Medien',            'materie', true),
  ('materie-finanzen',      'Finanzen',          'materie', true),
  ('energie-meditation',    'Meditation',        'energie', true),
  ('energie-traeume',       'Träume',            'energie', true),
  ('energie-chakra',        'Chakren',           'energie', true),
  ('energie-bewusstsein',   'Bewusstsein',       'energie', true),
  ('energie-heilung',       'Heilung',           'energie', true),
  ('energie-astrologie',    'Astrologie',        'energie', true),
  ('energie-kristalle',     'Kristalle',         'energie', true),
  ('energie-kraftorte',     'Kraftorte',         'energie', true)
ON CONFLICT (id) DO NOTHING;

-- ── 4. RLS aktivieren + alle alten Policies entfernen ───────────────────────
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'chat_messages'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.chat_messages', pol.policyname);
  END LOOP;
END $$;

-- ── 5. Frische RLS-Policies ──────────────────────────────────────────────────
CREATE POLICY "chat_select_all" ON public.chat_messages
  FOR SELECT USING (COALESCE(is_deleted, false) = false);

CREATE POLICY "chat_insert_auth_self" ON public.chat_messages
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_insert_anon" ON public.chat_messages
  FOR INSERT TO anon WITH CHECK (user_id IS NULL);

CREATE POLICY "chat_update_own" ON public.chat_messages
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_update_admin" ON public.chat_messages
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()
    AND p.role IN ('admin','root_admin','root-admin','moderator','content_editor','superadmin','root')))
  WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()
    AND p.role IN ('admin','root_admin','root-admin','moderator','content_editor','superadmin','root')));

CREATE POLICY "chat_delete_own" ON public.chat_messages
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "chat_delete_admin" ON public.chat_messages
  FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()
    AND p.role IN ('admin','root_admin','root-admin','moderator','content_editor','superadmin','root')));

-- ── 6. Realtime ──────────────────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  END IF;
END $$;

DO $$ BEGIN
  EXECUTE 'ALTER TABLE public.chat_messages REPLICA IDENTITY FULL';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ── 7. GRANTs ────────────────────────────────────────────────────────────────
GRANT SELECT ON public.chat_messages TO anon;
GRANT INSERT ON public.chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;
GRANT SELECT ON public.chat_rooms TO anon, authenticated;

-- ── 8. Diagnose ──────────────────────────────────────────────────────────────
DO $$
DECLARE pc INT; rc INT;
BEGIN
  SELECT COUNT(*) INTO pc FROM pg_policies WHERE schemaname='public' AND tablename='chat_messages';
  SELECT COUNT(*) INTO rc FROM public.chat_rooms;
  RAISE NOTICE '✅ v51 Chat-Emergency-Fix: % RLS-Policies, % Räume', pc, rc;
END $$;
