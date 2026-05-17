-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v76 – admin_audit_log Tabelle
-- Persistenter Audit-Trail für Admin-Aktionen, insbesondere
-- LiveKit-Moderation (kick / mute / unmute), Bans, Promotions.
-- Bisher: nur edited/deleted chat_messages wurden retrospektiv als
-- "Audit-Log" interpretiert (siehe Worker /api/admin/audit).
-- Jetzt: echte, durchsuchbare Action-History.
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_username  text NOT NULL,
  action          text NOT NULL,         -- e.g. 'livekit_kick' / 'livekit_mute' / 'livekit_unmute' / 'ban' / 'promote'
  target_identity text,                  -- LiveKit identity, ggf. != username
  target_username text,                  -- best-effort lookup
  room_name       text,                  -- LiveKit room (nur bei livekit_*)
  world           text,                  -- materie/energie/vorhang/ursprung (wenn ableitbar)
  details         jsonb DEFAULT '{}'::jsonb,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Indexe für die häufigsten Queries: nach world filtern, nach Zeit
-- sortieren, nach admin_username filtern.
CREATE INDEX IF NOT EXISTS idx_admin_audit_world_time
  ON public.admin_audit_log (world, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_admin
  ON public.admin_audit_log (admin_username, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_action
  ON public.admin_audit_log (action, created_at DESC);

-- RLS: nur Admin-Rollen dürfen lesen. Schreiben passiert ausschließlich
-- vom Worker mit SERVICE_ROLE — RLS umgeht der Service-Key automatisch.
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_audit_read ON public.admin_audit_log;
CREATE POLICY admin_audit_read ON public.admin_audit_log
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('root_admin', 'root-admin', 'admin', 'moderator')
    )
  );

-- Insert/Update/Delete via service_role only (kein Policy → blockiert
-- für alle anderen Rollen).

COMMENT ON TABLE public.admin_audit_log IS
  'Persistenter Audit-Trail für Admin/Moderator-Aktionen. Schreiben nur via SERVICE_ROLE (Worker).';
