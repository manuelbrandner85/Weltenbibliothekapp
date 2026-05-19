-- v96: notification_queue InvisibleAuth-kompatibel machen
-- Bisher hatte die Tabelle user_id UUID NOT NULL REFERENCES auth.users(id).
-- InvisibleAuth-User haben aber keinen auth.users-Row -- der Worker konnte
-- daher keine Push-Notifications fuer sie einreihen.
--
-- Loesung:
-- 1. user_id nullable machen (aber weiter FK auf auth.users).
-- 2. legacy_user_id TEXT-Spalte hinzufuegen (verweist auf
--    profiles.legacy_user_id fuer InvisibleAuth-User).
-- 3. CHECK: mindestens eines von beiden muss gesetzt sein.
-- 4. RLS-Policy erweitern: User darf eigene Zeilen lesen ueber
--    auth.uid()=user_id ODER legacy_user_id matched eigenes Profil.

-- Drop FK falls vorhanden + nullable machen
DO $$
BEGIN
  ALTER TABLE notification_queue
    DROP CONSTRAINT IF EXISTS notification_queue_user_id_fkey;
EXCEPTION WHEN undefined_table THEN
  NULL;
END $$;

ALTER TABLE notification_queue
  ALTER COLUMN user_id DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS legacy_user_id TEXT;

-- FK wiederherstellen, aber jetzt nullable
ALTER TABLE notification_queue
  ADD CONSTRAINT notification_queue_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
    DEFERRABLE INITIALLY DEFERRED;

-- CHECK: einer von beiden muss gesetzt sein
DO $$
BEGIN
  ALTER TABLE notification_queue
    DROP CONSTRAINT IF EXISTS notification_queue_user_ref_check;
  ALTER TABLE notification_queue
    ADD CONSTRAINT notification_queue_user_ref_check
      CHECK (user_id IS NOT NULL OR legacy_user_id IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN
  NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_notification_queue_legacy_user
  ON notification_queue(legacy_user_id)
  WHERE legacy_user_id IS NOT NULL;

-- Erweiterte RLS-Policy: legacy_user_id matched eigenes Profil
DROP POLICY IF EXISTS "notif_select_own_invisible" ON notification_queue;
CREATE POLICY "notif_select_own_invisible" ON notification_queue
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR (
      legacy_user_id IS NOT NULL
      AND legacy_user_id IN (
        SELECT legacy_user_id FROM profiles
        WHERE auth.uid() = id
      )
    )
  );

COMMENT ON COLUMN notification_queue.legacy_user_id IS
  'InvisibleAuth client-generierte ID. Nullable -- wenn user_id (UUID) '
  'gesetzt ist, ist legacy_user_id NULL und umgekehrt.';

-- ──────────────────────────────────────────────────────────────────────
-- push_subscriptions: ebenfalls InvisibleAuth-tauglich machen
-- ──────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  ALTER TABLE push_subscriptions
    ADD COLUMN IF NOT EXISTS legacy_user_id TEXT;
EXCEPTION WHEN undefined_table THEN
  -- Tabelle existiert nicht? -> ueberspringen
  NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_push_subs_legacy_user
  ON push_subscriptions(legacy_user_id)
  WHERE legacy_user_id IS NOT NULL;
