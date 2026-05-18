-- ══════════════════════════════════════════════════════════════════════════════
-- MIGRATION v89 – USER-REPORTS (Bug + Content + Feedback + Voice-Memo)
--
-- Generische Reports-Tabelle für alles was User aus der App melden können:
-- • Bug-Reports (Fehler/Crash via ErrorReportingService)
-- • Content-Reports (Beleidigender Inhalt — getrennt von reported_messages
--   die nur Chat-Nachrichten meldet)
-- • Feedback (User-Wünsche, Verbesserungs-Vorschläge)
-- • Voice-Memo-Reports (Probleme mit LiveKit-Calls)
--
-- Admin-Dashboard Reports-Inbox liest hier mit SERVICE_ROLE via Worker.
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.user_reports (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       TEXT,                                    -- kann anonym sein
  username      TEXT,
  type          TEXT NOT NULL CHECK (type IN ('bug','content','feedback','voice')),
  severity      TEXT DEFAULT 'medium' CHECK (severity IN ('low','medium','high','critical')),
  title         TEXT NOT NULL,
  body          TEXT,
  target_id     TEXT,                                    -- z.B. message_id, room_id, module_code
  screenshot_url TEXT,
  context       JSONB DEFAULT '{}'::jsonb,              -- app_version, platform, etc.
  status        TEXT NOT NULL DEFAULT 'open'
                CHECK (status IN ('open','reviewing','resolved','dismissed')),
  reviewed_by   TEXT,
  reviewed_at   TIMESTAMPTZ,
  resolution_note TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_reports_status_time
  ON public.user_reports (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_reports_type_time
  ON public.user_reports (type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_reports_user
  ON public.user_reports (user_id);

-- RLS: User dürfen eigene Reports lesen + neue erstellen.
-- Admins lesen via SERVICE_ROLE im Worker (umgeht RLS).
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_reports_insert_anon" ON public.user_reports;
CREATE POLICY "user_reports_insert_anon" ON public.user_reports
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "user_reports_select_own" ON public.user_reports;
CREATE POLICY "user_reports_select_own" ON public.user_reports
  FOR SELECT TO authenticated
  USING (user_id = auth.uid()::text);

COMMENT ON TABLE public.user_reports IS
  'Generische User-Reports: Bug, Content, Feedback, Voice-Memo. Admin liest via Worker SERVICE_ROLE.';
