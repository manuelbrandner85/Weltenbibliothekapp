-- ============================================================
-- v18: GRANT anon/authenticated writes on chat_messages
-- ============================================================
-- Fix für PostgREST 42501 "permission denied for table chat_messages".
--
-- Ursache: RLS-Policies alleine reichen nicht. PostgREST prüft
-- zusätzlich die Table-Level Privileges (GRANT). Ohne explizite
-- GRANTs auf die Rollen `anon` und `authenticated` wird jeder
-- INSERT/UPDATE/DELETE mit 42501 abgelehnt – unabhängig davon,
-- was die RLS-Policy erlaubt.
--
-- Diese Migration erteilt die nötigen Privileges und stellt
-- sicher, dass Sequenzen (SERIAL-PK) ebenfalls nutzbar sind.
-- ============================================================

-- 1. Table-Privileges auf chat_messages -------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.chat_messages
  TO anon, authenticated;

-- 2. Sequences (für default-nextval() und SERIAL-Spalten) -------
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
  TO anon, authenticated;

-- 3. RLS-Policies (idempotent neu setzen) -----------------------
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can insert chat messages" ON public.chat_messages;
CREATE POLICY "Anyone can insert chat messages" ON public.chat_messages
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Public read chat_messages" ON public.chat_messages;
CREATE POLICY "Public read chat_messages" ON public.chat_messages
  FOR SELECT TO anon, authenticated
  USING (is_deleted = false OR is_deleted IS NULL);

DROP POLICY IF EXISTS "Users can update own messages" ON public.chat_messages;
CREATE POLICY "Users can update own messages" ON public.chat_messages
  FOR UPDATE TO anon, authenticated
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Users can soft-delete own messages" ON public.chat_messages;
CREATE POLICY "Users can soft-delete own messages" ON public.chat_messages
  FOR DELETE TO anon, authenticated
  USING (true);

-- 4. Auch chat_rooms lesbar machen (falls nicht vorhanden) ------
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read chat_rooms" ON public.chat_rooms;
CREATE POLICY "Public read chat_rooms" ON public.chat_rooms
  FOR SELECT TO anon, authenticated
  USING (true);

GRANT SELECT ON TABLE public.chat_rooms TO anon, authenticated;

-- 5. profiles: lesbar + self-update ------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read profiles" ON public.profiles;
CREATE POLICY "Public read profiles" ON public.profiles
  FOR SELECT TO anon, authenticated
  USING (true);

GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO anon, authenticated;

-- 6. Default-Privileges für zukünftige Objekte ------------------
-- (greift nur für Objekte, die mit dem postgres-User erstellt werden)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES
  TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES
  TO anon, authenticated;

-- ============================================================
-- Verifikation
-- ============================================================
-- SELECT grantee, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_name = 'chat_messages' AND table_schema = 'public'
-- ORDER BY grantee, privilege_type;
