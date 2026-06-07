-- v124: Sensitive Admin Features -- Impersonation Audit + IP/Device Session Tracking
-- ----------------------------------------------------------------------------------
-- Erlaubt Root-Admins:
--   1) "View as User" -- read-only Snapshot eines Users (Aktivitaet, Progress).
--      Jeder Start schreibt einen admin_audit_log-Eintrag (action='impersonation_view').
--      Kein Login-Wechsel, kein Schreibrecht -- nur Anzeige.
--   2) IP/Device-Verknuepfung -- pseudonymer Fingerprint (SHA256 ueber IP+SECRET +
--      User-Agent) wird bei /api/activity/log mitgeschrieben. So sehen wir, welche
--      Profile am selben Geraet/Netzwerk angemeldet waren -- ohne Klar-IPs zu
--      speichern. Retention 90 Tage via Cron-Job.
-- ----------------------------------------------------------------------------------

-- ── profile_sessions ────────────────────────────────────────────────────────
-- Pseudonyme Fingerprints fuer Multi-Account-Erkennung.
-- ip_hash  = SHA256(real_ip + SESSION_TRACKING_SECRET) -- nicht rueckrechenbar.
-- ua_hash  = SHA256(user_agent + SESSION_TRACKING_SECRET).
-- (profile_id, ip_hash, ua_hash) ist UNIQUE -- jede Tripel-Kombination 1 Zeile.
CREATE TABLE IF NOT EXISTS public.profile_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id text NOT NULL,
  ip_hash text NOT NULL,
  ua_hash text NOT NULL,
  first_seen timestamptz NOT NULL DEFAULT now(),
  last_seen timestamptz NOT NULL DEFAULT now(),
  request_count integer NOT NULL DEFAULT 1,
  UNIQUE (profile_id, ip_hash, ua_hash)
);

CREATE INDEX IF NOT EXISTS profile_sessions_ip_hash_idx
  ON public.profile_sessions (ip_hash);
CREATE INDEX IF NOT EXISTS profile_sessions_profile_id_idx
  ON public.profile_sessions (profile_id);
CREATE INDEX IF NOT EXISTS profile_sessions_last_seen_idx
  ON public.profile_sessions (last_seen);

ALTER TABLE public.profile_sessions ENABLE ROW LEVEL SECURITY;

-- Nur service_role darf lesen/schreiben. Admin-Abfragen gehen ueber Worker.
DROP POLICY IF EXISTS profile_sessions_service_all ON public.profile_sessions;
CREATE POLICY profile_sessions_service_all
  ON public.profile_sessions
  FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

COMMENT ON TABLE public.profile_sessions IS
  'Pseudonyme Geraete/IP-Fingerprints fuer Multi-Account-Erkennung. '
  'Klartext-IPs werden NIE gespeichert. 90-Tage-Retention. '
  'Schreibzugriff nur via Service-Role (Worker /api/activity/log).';
