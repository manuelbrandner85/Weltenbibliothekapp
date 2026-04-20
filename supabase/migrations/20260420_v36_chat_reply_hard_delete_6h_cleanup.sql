-- ══════════════════════════════════════════════════════════════════════════
-- v36 — Chat: Reply-Spalten, Hard-Delete, 6h Auto-Cleanup
-- ══════════════════════════════════════════════════════════════════════════
-- User-Anforderungen (2026-04-20):
--  1. Gelöschte Nachrichten müssen dauerhaft gelöscht bleiben (hard delete,
--     nicht nur `is_deleted=true`).
--  2. Bearbeitete Nachrichten bleiben bearbeitet (war schon ok, aber wir
--     sorgen mit Realtime-UPDATE-Events dafür dass andere Clients sie sehen).
--  3. Telegram-Style Reply: echte Inline-Quote → braucht reply_to_id +
--     Snapshot-Spalten damit der Quote auch nach Delete/Edit des Originals
--     stehen bleibt.
--  4. Chat-Verlauf löscht sich automatisch nach 6h (physisch aus Supabase).
-- ══════════════════════════════════════════════════════════════════════════

-- 1) Reply-Spalten + deleted_at -------------------------------------------
ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS reply_to_id          UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reply_to_content     TEXT,
  ADD COLUMN IF NOT EXISTS reply_to_sender_name TEXT,
  ADD COLUMN IF NOT EXISTS deleted_at           TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_chat_messages_reply_to
  ON chat_messages(reply_to_id);

-- 2) Hard-Delete-Policy ----------------------------------------------------
-- User darf eigene Nachrichten physisch löschen. Admin via SECURITY DEFINER
-- Worker-Endpoint (SERVICE_ROLE), nicht über RLS.
DROP POLICY IF EXISTS "User kann eigene Nachrichten löschen" ON chat_messages;
CREATE POLICY "User kann eigene Nachrichten löschen" ON chat_messages
  FOR DELETE USING (auth.uid() = user_id);

-- 3) Realtime: DELETE-Events liefern, damit andere Clients die Message
--    sofort aus ihrer In-Memory-Liste entfernen können.
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
-- Idempotent: falls schon drin → no-op error, ignoriert in DO-Block:
DO $$
BEGIN
  EXECUTE 'ALTER TABLE chat_messages REPLICA IDENTITY FULL';
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- 4) 6h-Cleanup-Funktion ---------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_old_chat_messages()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  removed integer;
BEGIN
  DELETE FROM chat_messages
   WHERE created_at < NOW() - INTERVAL '6 hours';
  GET DIAGNOSTICS removed = ROW_COUNT;
  RETURN removed;
END;
$$;

COMMENT ON FUNCTION public.cleanup_old_chat_messages() IS
  'Löscht Chat-Nachrichten älter als 6h. Wird per pg_cron alle 15min ausgeführt.';

-- 5) pg_cron Job ----------------------------------------------------------
-- Setzt voraus, dass pg_cron-Extension im Supabase-Projekt aktiviert ist.
-- Aktivieren falls nötig: Dashboard → Database → Extensions → pg_cron.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Alten Job entfernen (idempotent).
    PERFORM cron.unschedule('cleanup-old-chat-messages')
      WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-chat-messages');

    PERFORM cron.schedule(
      'cleanup-old-chat-messages',
      '*/15 * * * *',
      $CRON$ SELECT public.cleanup_old_chat_messages(); $CRON$
    );
    RAISE NOTICE '✅ pg_cron Job "cleanup-old-chat-messages" registriert (alle 15min)';
  ELSE
    RAISE NOTICE '⚠️  pg_cron ist nicht aktiviert. Cleanup muss extern angestoßen werden.';
    RAISE NOTICE '    Aktivieren: Dashboard → Database → Extensions → pg_cron ON';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️  pg_cron Setup fehlgeschlagen: %. Manuelle Aktivierung nötig.', SQLERRM;
END $$;

-- 6) SELECT-Policy aktualisieren ------------------------------------------
-- Mit Hard-Delete wird is_deleted obsolet; wir behalten aber Backward-Compat
-- (alte soft-deleted Rows weiterhin ausblenden).
DROP POLICY IF EXISTS "Chat-Nachrichten sind lesbar" ON chat_messages;
CREATE POLICY "Chat-Nachrichten sind lesbar" ON chat_messages
  FOR SELECT USING (is_deleted = false OR is_deleted IS NULL);
