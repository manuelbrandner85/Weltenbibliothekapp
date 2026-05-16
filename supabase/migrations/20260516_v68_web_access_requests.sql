-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION v68 – web_access_requests (name-only access system)
-- Ersetzt das alte Supabase-Auth-basierte System durch ein simples
-- Name-only-Zugangsmodell ohne E-Mail/Passwort für reguläre User.
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── web_access_requests ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.web_access_requests (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name    text NOT NULL,
  status          text NOT NULL DEFAULT 'pending',   -- pending | approved | rejected
  requested_at    timestamptz NOT NULL DEFAULT now(),
  approved_at     timestamptz,
  rejected_at     timestamptz,
  last_login_at   timestamptz,
  CONSTRAINT web_access_requests_name_unique UNIQUE (display_name),
  CONSTRAINT web_access_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_web_access_requests_status
  ON public.web_access_requests (status);
CREATE INDEX IF NOT EXISTS idx_web_access_requests_display_name
  ON public.web_access_requests (lower(display_name));
CREATE INDEX IF NOT EXISTS idx_web_access_requests_requested_at
  ON public.web_access_requests (requested_at DESC);

-- Row Level Security
ALTER TABLE public.web_access_requests ENABLE ROW LEVEL SECURITY;

-- Anon darf lesen (für Login-Status-Check)
DROP POLICY IF EXISTS "web_access_requests_select_anon" ON public.web_access_requests;
CREATE POLICY "web_access_requests_select_anon"
  ON public.web_access_requests FOR SELECT
  TO anon
  USING (true);

-- Anon darf Antrag stellen
DROP POLICY IF EXISTS "web_access_requests_insert_anon" ON public.web_access_requests;
CREATE POLICY "web_access_requests_insert_anon"
  ON public.web_access_requests FOR INSERT
  TO anon
  WITH CHECK (true);

-- Anon darf last_login_at aktualisieren
DROP POLICY IF EXISTS "web_access_requests_update_anon" ON public.web_access_requests;
CREATE POLICY "web_access_requests_update_anon"
  ON public.web_access_requests FOR UPDATE
  TO anon
  USING (true)
  WITH CHECK (true);

-- Service-Role und authenticated dürfen alles (Admin-Aktionen)
DROP POLICY IF EXISTS "web_access_requests_service_all" ON public.web_access_requests;
CREATE POLICY "web_access_requests_service_all"
  ON public.web_access_requests FOR ALL
  TO authenticated
  USING (true);

-- Grants
GRANT SELECT, INSERT, UPDATE ON public.web_access_requests TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.web_access_requests TO authenticated;
