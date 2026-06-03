-- v115: Admin-Dashboard Feature-Ausbau
-- Erstellt / repariert die Tabellen fuer:
--   A) admin_bans        -- befristete Bans + Auto-Expiry via Cron
--   B) admin_warnings    -- 3-Strike-Verwarnungssystem
--   C) admin_user_notes  -- interne Admin-Notizen pro User
--
-- Hintergrund: Die v103-Migration definierte admin_bans + admin_warnings,
-- wurde aber nie vollstaendig angewendet (Tabellen fehlen in Prod). Der
-- Worker schreibt bereits in admin_bans -> diese Inserts schlugen silent
-- fehl. Diese Migration legt die Tabellen final an (idempotent).
--
-- Alle Tabellen: RLS aktiv. Admin/Mod (profiles.role) darf lesen+schreiben,
-- service_role (Worker) darf alles. User darf eigene Bans/Warnings sehen.

-- ════════════════════════════════════════════════════════════════════════
-- A) admin_bans -- befristete + permanente Bans
-- ════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.admin_bans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL UNIQUE,
  username        TEXT,
  banned_by       TEXT,
  reason          TEXT,
  is_permanent    BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_bans_user
  ON public.admin_bans(user_id);
-- Index fuer den Cron-Expiry-Scan: nur befristete, noch nicht abgelaufene.
CREATE INDEX IF NOT EXISTS idx_admin_bans_expires
  ON public.admin_bans(expires_at)
  WHERE is_permanent = FALSE AND expires_at IS NOT NULL;

ALTER TABLE public.admin_bans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_bans_read" ON public.admin_bans;
CREATE POLICY "admin_bans_read" ON public.admin_bans
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.uid()::text = user_id
  );

DROP POLICY IF EXISTS "admin_bans_write" ON public.admin_bans;
CREATE POLICY "admin_bans_write" ON public.admin_bans
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- B) admin_warnings -- Verwarnungen (3 = Auto-Ban)
-- ════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.admin_warnings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL,
  username        TEXT,
  warned_by       TEXT,
  reason          TEXT NOT NULL,
  acknowledged    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_warnings_user
  ON public.admin_warnings(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_warnings_created
  ON public.admin_warnings(created_at DESC);

ALTER TABLE public.admin_warnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_warnings_read" ON public.admin_warnings;
CREATE POLICY "admin_warnings_read" ON public.admin_warnings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
    OR auth.uid()::text = user_id
  );

DROP POLICY IF EXISTS "admin_warnings_write" ON public.admin_warnings;
CREATE POLICY "admin_warnings_write" ON public.admin_warnings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );

-- ════════════════════════════════════════════════════════════════════════
-- C) admin_user_notes -- interne Notizen (nur fuer Admins sichtbar)
-- ════════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.admin_user_notes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         TEXT NOT NULL,
  note            TEXT NOT NULL,
  author_username TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_user_notes_user
  ON public.admin_user_notes(user_id);

ALTER TABLE public.admin_user_notes ENABLE ROW LEVEL SECURITY;

-- Notizen sind INTERN: nur Admins/Mods, niemals der betroffene User.
DROP POLICY IF EXISTS "admin_user_notes_admin_only" ON public.admin_user_notes;
CREATE POLICY "admin_user_notes_admin_only" ON public.admin_user_notes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('admin','root_admin','root-admin','moderator')
    )
  );
