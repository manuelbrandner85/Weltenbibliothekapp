-- v49: Chat-Fix — FK-Constraint entfernen + vollständige RLS-Policies
--
-- Problem 1: chat_messages.room_id hat FK auf chat_rooms(id).
--   Wenn die Chat-Räume noch nicht in chat_rooms existieren (SUPABASE_ACCESS_TOKEN
--   fehlte bei Migrations-Run), schlägt jeder INSERT mit Code 23503 fehl.
--   Fix: FK-Constraint droppen → room_id bleibt TEXT, aber kein hard constraint mehr.
--
-- Problem 2: DELETE-Policy fehlte für normale User → soft-delete (=UPDATE) lief,
--   aber der Fehler "0 rows updated" wenn RLS fehlte.
-- Problem 3: Mehrfache überlappende UPDATE-Policies → bereinigen.

-- ── 1. FK-Constraint auf room_id entfernen ───────────────────────────────────
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'chat_messages'
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name LIKE '%room_id%'
  ) THEN
    -- Constraint-Name aus information_schema lesen und droppen
    EXECUTE (
      SELECT 'ALTER TABLE public.chat_messages DROP CONSTRAINT ' || constraint_name
      FROM information_schema.table_constraints
      WHERE table_name = 'chat_messages'
        AND constraint_type = 'FOREIGN KEY'
        AND constraint_name LIKE '%room_id%'
      LIMIT 1
    );
    RAISE NOTICE 'chat_messages room_id FK-Constraint entfernt';
  ELSE
    RAISE NOTICE 'chat_messages hat keinen room_id FK-Constraint (schon entfernt oder nie vorhanden)';
  END IF;
END $$;

-- ── 2. Sicherstellen dass alle Chat-Räume existieren (Fallback) ──────────────
-- Auch wenn die FK weg ist, wollen wir die Räume für die UI haben.
ALTER TABLE IF EXISTS public.chat_rooms
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

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

-- ── 3. RLS sicherstellen ──────────────────────────────────────────────────────
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ── 4. Alle alten Policies entfernen (kompletter Reset) ──────────────────────
DROP POLICY IF EXISTS "chat_messages_authenticated_read"   ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_own_insert"           ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_own_update"           ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_moderator_delete"     ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_select"               ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert"               ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_update"               ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_soft_delete"          ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_anon_select"          ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_anon_insert"          ON public.chat_messages;
DROP POLICY IF EXISTS "users_can_edit_own_messages"        ON public.chat_messages;
DROP POLICY IF EXISTS "users_can_delete_own_messages"      ON public.chat_messages;
DROP POLICY IF EXISTS "admins_can_delete_any_message"      ON public.chat_messages;
DROP POLICY IF EXISTS "admins_can_edit_any_message"        ON public.chat_messages;

-- ── 5. Neue, saubere Policies ─────────────────────────────────────────────────

-- SELECT: Alle Rollen dürfen nicht-gelöschte Nachrichten lesen
CREATE POLICY "chat_select_all"
  ON public.chat_messages
  FOR SELECT
  USING (COALESCE(is_deleted, false) = false);

-- INSERT: anon (user_id NULL) + authenticated (user_id = eigene UUID)
CREATE POLICY "chat_insert_authenticated"
  ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    (auth.uid() IS NULL AND user_id IS NULL)
    OR (auth.uid() IS NOT NULL AND auth.uid() = user_id)
    OR (auth.uid() IS NOT NULL AND user_id IS NULL)
  );

-- UPDATE: User darf eigene Nachrichten bearbeiten (inkl. soft-delete via is_deleted)
CREATE POLICY "chat_update_own"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: Admins/Moderatoren dürfen alle Nachrichten bearbeiten
CREATE POLICY "chat_update_admin"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'root_admin', 'root-admin', 'moderator',
                              'content_editor', 'superadmin', 'root')
    )
  );

-- DELETE: User darf eigene Nachrichten hard-löschen
CREATE POLICY "chat_delete_own"
  ON public.chat_messages
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- DELETE: Admins dürfen alle Nachrichten löschen
CREATE POLICY "chat_delete_admin"
  ON public.chat_messages
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'root_admin', 'root-admin', 'moderator',
                              'content_editor', 'superadmin', 'root')
    )
  );

-- GRANT für anon + authenticated (Supabase-Standard)
GRANT SELECT, INSERT ON public.chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;
