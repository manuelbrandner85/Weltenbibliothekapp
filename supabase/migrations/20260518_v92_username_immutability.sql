-- ══════════════════════════════════════════════════════════════════════════════
-- v92 — USERNAME IMMUTABILITY + CHANGE-REQUEST-FLOW
-- ══════════════════════════════════════════════════════════════════════════════
-- Anforderung: Username ist nach erstem Anlegen IMMUTABLE.
-- User kann alle anderen Profil-Felder unter seinem Username updaten,
-- aber Username-Aenderungen muessen via Admin-Approval gehen.
-- Ausnahme: root_admin darf alles, immer.

-- ── 1. Username-Change-Request Tabelle ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.username_change_requests (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id          UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  legacy_user_id      TEXT,  -- fallback fuer InvisibleAuth-User
  current_username    TEXT NOT NULL,
  requested_username  TEXT NOT NULL,
  reason              TEXT,
  status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  decided_by_username TEXT,
  decided_at          TIMESTAMPTZ,
  decision_note       TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- pro User max 1 pending Request gleichzeitig
  CONSTRAINT one_pending_per_user
    UNIQUE (profile_id, status)
    DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX IF NOT EXISTS idx_username_change_status
  ON public.username_change_requests (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_username_change_legacy
  ON public.username_change_requests (legacy_user_id) WHERE legacy_user_id IS NOT NULL;

ALTER TABLE public.username_change_requests ENABLE ROW LEVEL SECURITY;

-- User kann seine eigenen Requests lesen
DROP POLICY IF EXISTS username_requests_read_own ON public.username_change_requests;
CREATE POLICY username_requests_read_own ON public.username_change_requests
  FOR SELECT USING (
    profile_id = auth.uid()
    OR legacy_user_id IS NOT NULL  -- permissiv waehrend InvisibleAuth-Phase
    OR auth.role() = 'service_role'
  );

-- Schreiben nur via Service-Role (Worker)
DROP POLICY IF EXISTS username_requests_write_service ON public.username_change_requests;
CREATE POLICY username_requests_write_service ON public.username_change_requests
  FOR ALL USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ── 2. Trigger: enforce_username_immutability ──────────────────────────────
-- BEFORE UPDATE auf profiles. Wenn username sich aendert UND der ausfuehrende
-- User KEIN root_admin ist UND es kein Service-Role-Aufruf ist UND es keinen
-- approved Change-Request fuer dieses User-Profil + diesen neuen Username
-- gibt → REJECT.
CREATE OR REPLACE FUNCTION public.enforce_username_immutability()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_caller_role TEXT;
  v_has_approval BOOLEAN;
BEGIN
  -- Username unveraendert? Nichts zu tun.
  IF OLD.username IS NULL OR NEW.username IS NULL THEN
    RETURN NEW;
  END IF;
  IF OLD.username = NEW.username THEN
    RETURN NEW;
  END IF;

  -- Service-Role darf alles
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Caller-Role ermitteln (eigene Profil-Zeile)
  SELECT role INTO v_caller_role
  FROM public.profiles
  WHERE id = auth.uid();

  -- Root-Admin darf alles
  IF v_caller_role = 'root_admin' THEN
    RETURN NEW;
  END IF;

  -- Sonst: pruefen ob ein approved Change-Request existiert
  SELECT EXISTS (
    SELECT 1 FROM public.username_change_requests
    WHERE profile_id = NEW.id
      AND requested_username = NEW.username
      AND status = 'approved'
      AND decided_at > NOW() - INTERVAL '7 days'
  ) INTO v_has_approval;

  IF NOT v_has_approval THEN
    RAISE EXCEPTION 'Username-Aenderung erfordert Admin-Approval. '
                    'Stelle einen Antrag via /api/profile/username-change-request.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_username_immutable ON public.profiles;
CREATE TRIGGER profiles_username_immutable
  BEFORE UPDATE OF username ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_username_immutability();

-- ── 3. Komfort-View: pending Requests fuer Admin-Dashboard ────────────────
CREATE OR REPLACE VIEW public.username_change_requests_pending
  WITH (security_invoker = true) AS
SELECT
  r.id,
  r.profile_id,
  r.legacy_user_id,
  r.current_username,
  r.requested_username,
  r.reason,
  r.created_at,
  p.avatar_url,
  p.role AS profile_role
FROM public.username_change_requests r
LEFT JOIN public.profiles p ON p.id = r.profile_id
WHERE r.status = 'pending'
ORDER BY r.created_at DESC;

GRANT SELECT ON public.username_change_requests_pending TO authenticated, anon;

-- ── 4. Kommentare ──────────────────────────────────────────────────────────
COMMENT ON TABLE public.username_change_requests IS
  'Antraege auf Username-Aenderung. Workflow: User stellt Antrag -> Admin '
  'approved/rejected -> Trigger enforce_username_immutability erlaubt '
  'die UPDATE auf profiles.username innerhalb von 7 Tagen nach Approval.';

COMMENT ON FUNCTION public.enforce_username_immutability() IS
  'Verbietet UPDATE auf profiles.username sofern nicht: (a) Service-Role, '
  '(b) root_admin, (c) approved Change-Request <7 Tage alt fuer den neuen Namen.';
