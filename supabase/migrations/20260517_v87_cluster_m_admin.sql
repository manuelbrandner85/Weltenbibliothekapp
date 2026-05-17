-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v87 – Cluster M: Settings / Admin
--
-- M1 user_notification_prefs.quiet_hours_* — Quiet-Hours-Toggles
-- M3 reported_messages                     — Moderation-Queue
-- ═══════════════════════════════════════════════════════════════

-- M1 ──────────────────────────────────────────────────────────
-- user_notification_prefs gibt es ggf. schon — wir erweitern idempotent.
CREATE TABLE IF NOT EXISTS public.user_notification_prefs (
  user_id            text PRIMARY KEY,
  quiet_hours_enabled boolean NOT NULL DEFAULT false,
  quiet_start_hour    smallint NOT NULL DEFAULT 22  CHECK (quiet_start_hour BETWEEN 0 AND 23),
  quiet_end_hour      smallint NOT NULL DEFAULT 7   CHECK (quiet_end_hour BETWEEN 0 AND 23),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.user_notification_prefs
  ADD COLUMN IF NOT EXISTS quiet_hours_enabled boolean NOT NULL DEFAULT false;
ALTER TABLE public.user_notification_prefs
  ADD COLUMN IF NOT EXISTS quiet_start_hour smallint NOT NULL DEFAULT 22;
ALTER TABLE public.user_notification_prefs
  ADD COLUMN IF NOT EXISTS quiet_end_hour smallint NOT NULL DEFAULT 7;

ALTER TABLE public.user_notification_prefs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notif_prefs_own ON public.user_notification_prefs;
CREATE POLICY notif_prefs_own ON public.user_notification_prefs
  FOR ALL USING (true) WITH CHECK (true);


-- M3 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reported_messages (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id    text NOT NULL,
  room_id       text,
  reporter_id   text NOT NULL,
  reporter_name text,
  target_user   text,
  reason        text NOT NULL,           -- 'spam' | 'hate' | 'abuse' | 'misinfo' | 'other'
  notes         text,
  status        text NOT NULL DEFAULT 'open' CHECK (status IN ('open','reviewed','dismissed','actioned')),
  reviewed_by   text,
  reviewed_at   timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reported_status_time
  ON public.reported_messages (status, created_at DESC);

ALTER TABLE public.reported_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reports_read_admin ON public.reported_messages;
CREATE POLICY reports_read_admin ON public.reported_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('root_admin','root-admin','admin','moderator')
    )
  );

DROP POLICY IF EXISTS reports_insert_anyone ON public.reported_messages;
CREATE POLICY reports_insert_anyone ON public.reported_messages
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS reports_update_admin ON public.reported_messages;
CREATE POLICY reports_update_admin ON public.reported_messages
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('root_admin','root-admin','admin','moderator')
    )
  ) WITH CHECK (true);

COMMENT ON COLUMN public.user_notification_prefs.quiet_hours_enabled IS
  'Global Quiet-Hours für alle Push/In-App-Notif (M1).';
COMMENT ON TABLE public.reported_messages IS
  'Gemeldete Chat-Nachrichten / Moderation-Queue (M3).';
