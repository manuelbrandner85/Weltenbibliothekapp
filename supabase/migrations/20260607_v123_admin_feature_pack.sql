-- v123: Admin Feature Pack -- Shadow-ban, Temp-Mute, Feature Flags, Announcements, Undo

-- 1. profiles: shadow_banned + muted_until
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS shadow_banned bool NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS muted_until timestamptz NULL;

-- 2. feature_flags: kill-switch / maintenance / banner per world
CREATE TABLE IF NOT EXISTS public.feature_flags (
  key        text PRIMARY KEY,
  enabled    bool NOT NULL DEFAULT false,
  world      text NULL,  -- NULL = all worlds
  value      text NULL,  -- optional string payload (e.g. banner text)
  updated_by text NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
-- Public read (clients read flags at startup)
DROP POLICY IF EXISTS feature_flags_public_read ON public.feature_flags;
CREATE POLICY feature_flags_public_read ON public.feature_flags
  FOR SELECT USING (true);
-- Only admins write (enforced via Worker service_role)
DROP POLICY IF EXISTS feature_flags_admin_write ON public.feature_flags;
CREATE POLICY feature_flags_admin_write ON public.feature_flags
  FOR ALL USING (false) WITH CHECK (false);

-- Seed essential flags so clients can query them reliably
INSERT INTO public.feature_flags (key, enabled, world) VALUES
  ('maintenance', false, null),
  ('banner_materie', false, 'materie'),
  ('banner_energie', false, 'energie'),
  ('banner_vorhang', false, 'vorhang'),
  ('banner_ursprung', false, 'ursprung')
ON CONFLICT (key) DO NOTHING;

-- 3. scheduled_announcements
CREATE TABLE IF NOT EXISTS public.scheduled_announcements (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title      text NOT NULL,
  body       text NOT NULL,
  run_at     timestamptz NOT NULL,
  world      text NULL,  -- NULL = all worlds
  push       bool NOT NULL DEFAULT false,
  sent       bool NOT NULL DEFAULT false,
  created_by text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.scheduled_announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS scheduled_announcements_admin_read ON public.scheduled_announcements;
CREATE POLICY scheduled_announcements_admin_read ON public.scheduled_announcements
  FOR SELECT USING (true);
DROP POLICY IF EXISTS scheduled_announcements_admin_write ON public.scheduled_announcements;
CREATE POLICY scheduled_announcements_admin_write ON public.scheduled_announcements
  FOR ALL USING (false) WITH CHECK (false);

-- 4. admin_audit_log: add undo_payload column for rollback support
ALTER TABLE public.admin_audit_log
  ADD COLUMN IF NOT EXISTS undo_payload jsonb NULL;

-- Grant anon read on feature_flags (needed for client startup check)
GRANT SELECT ON public.feature_flags TO anon;
GRANT SELECT ON public.feature_flags TO authenticated;
-- Scheduled announcements: worker reads/writes via service_role
GRANT ALL ON public.scheduled_announcements TO service_role;
GRANT SELECT ON public.scheduled_announcements TO anon;
GRANT SELECT ON public.scheduled_announcements TO authenticated;
