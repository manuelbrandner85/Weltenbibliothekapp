-- ⚠️ MANUELL IM SUPABASE DASHBOARD AUSFÜHREN (falls CI nicht greift):
-- https://supabase.com/dashboard/project/zctufcfjsixfgmmwvnmv/sql/new
--
-- Teil A: Admin-Rolle in profiles sicherstellen
-- Teil B: web_access_requests Tabelle (idempotent, ergänzt v68)

-- ═══════ Teil A: Admin-Rolle in profiles sicherstellen ═════════════════════
UPDATE public.profiles
   SET role = 'root_admin'
 WHERE lower(username) = 'weltenbibliothek'
   AND (role IS NULL OR role != 'root_admin');

-- ═══════ Teil B: Web-Access-Tabelle (idempotent) ═══════════════════════════
-- Alte Auth-basierte Tabellen entfernen (RLS+Policies cascaden mit)
DROP TABLE IF EXISTS public.web_admin_notifications CASCADE;
DROP TABLE IF EXISTS public.web_user_profiles CASCADE;

CREATE TABLE IF NOT EXISTS public.web_access_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name  text NOT NULL,
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_at  timestamptz NOT NULL DEFAULT now(),
  approved_at   timestamptz,
  rejected_at   timestamptz,
  last_login_at timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_web_access_name_status
  ON public.web_access_requests (lower(display_name), status);
CREATE INDEX IF NOT EXISTS idx_web_access_status
  ON public.web_access_requests (status);

ALTER TABLE public.web_access_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "web_access_select" ON public.web_access_requests;
CREATE POLICY "web_access_select" ON public.web_access_requests
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "web_access_insert" ON public.web_access_requests;
CREATE POLICY "web_access_insert" ON public.web_access_requests
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "web_access_update" ON public.web_access_requests;
CREATE POLICY "web_access_update" ON public.web_access_requests
  FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "web_access_delete" ON public.web_access_requests;
CREATE POLICY "web_access_delete" ON public.web_access_requests
  FOR DELETE USING (true);

GRANT SELECT, INSERT, UPDATE ON public.web_access_requests TO anon;
GRANT ALL ON public.web_access_requests TO authenticated;
GRANT ALL ON public.web_access_requests TO service_role;
