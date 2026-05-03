-- v43: Chat-Nachrichten RLS-Fix — anonyme Zugriffe erlauben
-- Problem: Wenn nur die 001_initial_schema.sql Policies aktiv sind, können
--          anonyme Nutzer (Supabase anon-Rolle) weder Nachrichten lesen noch senden.
-- Fix:     Moderne Policies setzen die anon + authenticated korrekt behandeln.

-- ── Sicherstellen dass RLS aktiv ist ────────────────────────────────────────
ALTER TABLE IF EXISTS public.chat_messages ENABLE ROW LEVEL SECURITY;

-- ── Alte Policies entfernen (alle bekannten Namen) ───────────────────────────
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

-- ── SELECT: Alle Rollen dürfen nicht-gelöschte Nachrichten lesen ─────────────
-- (kein TO → gilt für anon + authenticated + service_role)
CREATE POLICY "chat_messages_select"
  ON public.chat_messages
  FOR SELECT
  USING (COALESCE(is_deleted, false) = false);

-- ── INSERT: Anon + Authenticated erlaubt, Owner-Constraint ──────────────────
-- Anon (kein Session-User): user_id muss NULL sein
-- Authenticated (echte Session): user_id muss eigene UUID sein ODER NULL sein
CREATE POLICY "chat_messages_insert"
  ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    (auth.uid() IS NULL AND (user_id IS NULL))
    OR (auth.uid() IS NOT NULL AND auth.uid() = user_id)
    OR (auth.uid() IS NOT NULL AND user_id IS NULL)
  );

-- ── UPDATE: Nur eigene Nachrichten oder Moderatoren/Admins ──────────────────
CREATE POLICY "chat_messages_update"
  ON public.chat_messages
  FOR UPDATE
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (
      SELECT id FROM public.profiles
      WHERE role IN ('admin', 'root_admin', 'root-admin', 'moderator', 'content_editor')
    )
  );

-- ── is_deleted Spalte ergänzen falls fehlend ────────────────────────────────
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- ── Sicherstellen dass alle Nachrichten-Spalten vorhanden sind ──────────────
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS avatar_emoji TEXT;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS reply_to_id TEXT;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS reply_to_content TEXT;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS reply_to_sender_name TEXT;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text';
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE IF EXISTS public.chat_messages
  ADD COLUMN IF NOT EXISTS thread_root_id UUID;
