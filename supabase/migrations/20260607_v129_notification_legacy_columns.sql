-- v129 (2026-06-07): KRITISCHER FIX Benachrichtigungs-System.
--
-- Problem (Audit 2026-06-07):
--   Der Cron-Dispatcher in api-worker.js (dispatchPushQueue) liest die Queue mit
--     select=id,user_id,legacy_user_id,title,body,data,attempts
--     &or=(scheduled_at.is.null,scheduled_at.lte.<now>)
--   Aber notification_queue hatte WEDER legacy_user_id NOCH scheduled_at.
--   -> PostgREST antwortet mit HTTP 400 (column does not exist)
--   -> der Cron liest IMMER eine leere Liste
--   -> KEIN einziger Push wurde je versendet (99 Zeilen blieben fuer immer
--      'pending', processed_at=NULL).
--
--   Zusaetzlich: notifications (In-App-Center) hatte nur user_id (uuid), keine
--   legacy_user_id. InvisibleAuth-User (ohne UUID) konnten dort gar nicht
--   gespeichert werden -> nur 1 einziger User bekam je interne Notifications.
--
-- Fix: die vom Worker-Code (v96/v104) erwarteten Spalten nachruesten. Die
-- Worker-Logik war immer korrekt -- nur das Schema fehlte auf dieser DB.
--
-- Idempotent (IF NOT EXISTS), keine Daten werden veraendert.

-- ── notification_queue ──────────────────────────────────────────────────
ALTER TABLE notification_queue
  ADD COLUMN IF NOT EXISTS legacy_user_id text;
ALTER TABLE notification_queue
  ADD COLUMN IF NOT EXISTS scheduled_at timestamptz;

-- Lookup-Index fuer den Dispatch (legacy-User) + Faelligkeits-Filter.
CREATE INDEX IF NOT EXISTS idx_notif_queue_legacy
  ON notification_queue (legacy_user_id)
  WHERE legacy_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notif_queue_scheduled
  ON notification_queue (scheduled_at)
  WHERE scheduled_at IS NOT NULL;

-- ── notifications (In-App-Center) ───────────────────────────────────────
ALTER TABLE notifications
  ADD COLUMN IF NOT EXISTS legacy_user_id text;

CREATE INDEX IF NOT EXISTS idx_notifications_legacy
  ON notifications (legacy_user_id, created_at DESC)
  WHERE legacy_user_id IS NOT NULL;
