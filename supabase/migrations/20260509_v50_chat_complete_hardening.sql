-- v50: Chat-Komplett-Hardening
-- ============================================================
-- Garantiert dass Send/Edit/Delete für jeden authentifizierten User funktioniert.
-- Vollständig idempotent — kann beliebig oft ausgeführt werden.
-- Behebt das Symptom „Nachricht konnte nicht gesendet werden" definitiv.
--
-- WAS WIRD GEMACHT:
--  1. Stellt sicher, dass alle chat_messages-Spalten existieren
--  2. Entfernt FK-Constraint auf room_id (falls noch da)
--  3. Entfernt ALLE alten RLS-Policies (kompletter Reset)
--  4. Legt frische, saubere RLS-Policies an (Send/Edit/Delete + Admin-Override)
--  5. Stellt sicher, dass die Tabelle in der Realtime-Publication ist
--  6. Stellt alle 17 Chat-Räume sicher
--  7. Setzt vollständige GRANTs für anon + authenticated
-- ============================================================

-- ── 1. Tabellen-Schema sicherstellen ─────────────────────────────────────────
-- Falls die Tabelle bereits existiert, fehlende Spalten nachrüsten.
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id TEXT NOT NULL,
  user_id UUID,
  username TEXT,
  content TEXT NOT NULL,
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

-- Defensive: Falls is_deleted bereits existierte (ohne Default oder mit NULL-Werten),
-- Default + NOT-NULL-Constraint sauber setzen ohne bestehende NULL-Zeilen zu sprengen.
ALTER TABLE public.chat_messages ALTER COLUMN is_deleted SET DEFAULT FALSE;
UPDATE public.chat_messages SET is_deleted = FALSE WHERE is_deleted IS NULL;
ALTER TABLE public.chat_messages ALTER COLUMN is_deleted SET NOT NULL;

-- content NOT NULL ist Pflicht — falls historische Zeilen NULL haben, mit message befüllen
UPDATE public.chat_messages SET content = COALESCE(content, message, '')
  WHERE content IS NULL;

-- ── 2. FK-Constraint auf room_id entfernen (falls noch da) ───────────────────
DO $$
DECLARE
  fk_name TEXT;
BEGIN
  SELECT constraint_name INTO fk_name
  FROM information_schema.table_constraints
  WHERE table_schema = 'public'
    AND table_name = 'chat_messages'
    AND constraint_type = 'FOREIGN KEY'
    AND constraint_name LIKE '%room_id%'
  LIMIT 1;
  IF fk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.chat_messages DROP CONSTRAINT %I', fk_name);
  END IF;
END $$;

-- ── 3. Indexes ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS chat_messages_room_created_idx
  ON public.chat_messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS chat_messages_user_idx
  ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_not_deleted_idx
  ON public.chat_messages(is_deleted) WHERE is_deleted = FALSE;

-- ── 4. RLS aktivieren ────────────────────────────────────────────────────────
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ── 5. ALLE alten Policies entfernen (kompletter Reset) ──────────────────────
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'chat_messages'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.chat_messages', pol.policyname);
  END LOOP;
END $$;

-- ── 6. Frische, saubere RLS-Policies ─────────────────────────────────────────

-- SELECT: Jeder darf nicht-gelöschte Nachrichten lesen (anon + auth)
DROP POLICY IF EXISTS "chat_select_all" ON public.chat_messages;
CREATE POLICY "chat_select_all"
  ON public.chat_messages
  FOR SELECT
  USING (COALESCE(is_deleted, false) = false);

-- INSERT für authenticated: user_id MUSS = auth.uid() sein
-- (kein anonymes Posten als Logged-in-User mehr — verhindert Spoofing)
DROP POLICY IF EXISTS "chat_insert_auth_self" ON public.chat_messages;
CREATE POLICY "chat_insert_auth_self"
  ON public.chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- INSERT für anon: nur ohne user_id (echtes Anonym-Posting)
DROP POLICY IF EXISTS "chat_insert_anon" ON public.chat_messages;
CREATE POLICY "chat_insert_anon"
  ON public.chat_messages
  FOR INSERT
  TO anon
  WITH CHECK (user_id IS NULL);

-- UPDATE: User darf eigene Nachrichten bearbeiten
DROP POLICY IF EXISTS "chat_update_own" ON public.chat_messages;
CREATE POLICY "chat_update_own"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Admins/Moderatoren dürfen jede Nachricht bearbeiten
DROP POLICY IF EXISTS "chat_update_admin" ON public.chat_messages;
CREATE POLICY "chat_update_admin"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator',
                       'content_editor','superadmin','root')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator',
                       'content_editor','superadmin','root')
    )
  );

-- DELETE: User darf eigene Nachrichten hard-löschen
DROP POLICY IF EXISTS "chat_delete_own" ON public.chat_messages;
CREATE POLICY "chat_delete_own"
  ON public.chat_messages
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- DELETE: Admins/Moderatoren dürfen jede Nachricht löschen
DROP POLICY IF EXISTS "chat_delete_admin" ON public.chat_messages;
CREATE POLICY "chat_delete_admin"
  ON public.chat_messages
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator',
                       'content_editor','superadmin','root')
    )
  );

-- ── 7. Realtime-Publication ──────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname='supabase_realtime' AND tablename='chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  END IF;
END $$;

-- REPLICA IDENTITY FULL: nötig damit Realtime DELETE-Events das volle Row-Image liefern
DO $$ BEGIN
  EXECUTE 'ALTER TABLE public.chat_messages REPLICA IDENTITY FULL';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ── 8. Chat-Räume sicherstellen (idempotent) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  world TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chat_rooms
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
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

-- ── 9. GRANTs ────────────────────────────────────────────────────────────────
GRANT SELECT ON public.chat_messages TO anon;
GRANT INSERT ON public.chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;
GRANT SELECT ON public.chat_rooms TO anon, authenticated;

-- ── 10. Diagnose-Output ──────────────────────────────────────────────────────
DO $$
DECLARE
  policy_count INT;
  room_count INT;
BEGIN
  SELECT COUNT(*) INTO policy_count FROM pg_policies
  WHERE schemaname='public' AND tablename='chat_messages';
  SELECT COUNT(*) INTO room_count FROM public.chat_rooms;
  RAISE NOTICE '✅ v50 Chat-Hardening: % RLS-Policies aktiv, % Räume vorhanden', policy_count, room_count;
END $$;
