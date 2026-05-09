-- v52: Chat INSERT Nuclear Fix — reines SQL, KEIN PL/pgSQL
-- Explizit ALLE je erstellten INSERT-Policy-Namen droppen + eine einzige
-- permissive Policy ohne TO-Klausel anlegen (gilt für anon UND authenticated).

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ── Alle je erstellten INSERT-Policies (alle bekannten Namen) droppen ─────────
DROP POLICY IF EXISTS "chat_insert_allow_all"              ON public.chat_messages;
DROP POLICY IF EXISTS "chat_insert_auth_self"              ON public.chat_messages;
DROP POLICY IF EXISTS "chat_insert_authenticated"          ON public.chat_messages;
DROP POLICY IF EXISTS "chat_insert_anon"                   ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert"               ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_own_insert"           ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_anon_insert"          ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_auth_insert"          ON public.chat_messages;
DROP POLICY IF EXISTS "Anyone can insert chat messages"    ON public.chat_messages;
DROP POLICY IF EXISTS "Public insert chat_messages"        ON public.chat_messages;
DROP POLICY IF EXISTS "chat_anon_insert"                   ON public.chat_messages;
DROP POLICY IF EXISTS "chat_auth_insert"                   ON public.chat_messages;

-- ── Eine einzige permissive INSERT-Policy — kein TO (gilt für ALLE Rollen) ───
CREATE POLICY "chat_insert_allow_all" ON public.chat_messages
  FOR INSERT WITH CHECK (true);

-- ── GRANTs sicherstellen ─────────────────────────────────────────────────────
GRANT SELECT, INSERT ON public.chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_messages TO authenticated;
