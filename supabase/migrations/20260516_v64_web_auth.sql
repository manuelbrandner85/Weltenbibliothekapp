-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION v64 – Web-Auth-Tabellen
-- Erstellt Tabellen für das Web-Login-Gate:
--   • web_user_profiles  — Zugangsstatus für Web-User
--   • web_admin_notifications — Benachrichtigungen für Admins bei neuen Anträgen
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── web_user_profiles ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.web_user_profiles (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email           text NOT NULL,
  is_approved     boolean NOT NULL DEFAULT false,
  requested_at    timestamptz NOT NULL DEFAULT now(),
  approved_at     timestamptz,
  approved_by     uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT web_user_profiles_user_id_unique UNIQUE (user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_web_user_profiles_user_id
  ON public.web_user_profiles (user_id);
CREATE INDEX IF NOT EXISTS idx_web_user_profiles_is_approved
  ON public.web_user_profiles (is_approved);
CREATE INDEX IF NOT EXISTS idx_web_user_profiles_requested_at
  ON public.web_user_profiles (requested_at DESC);

-- updated_at Trigger
CREATE OR REPLACE FUNCTION public.update_web_user_profiles_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_web_user_profiles_updated_at ON public.web_user_profiles;
CREATE TRIGGER trg_web_user_profiles_updated_at
  BEFORE UPDATE ON public.web_user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_web_user_profiles_updated_at();

-- Row Level Security
ALTER TABLE public.web_user_profiles ENABLE ROW LEVEL SECURITY;

-- User kann eigenes Profil lesen
DROP POLICY IF EXISTS "web_user_profiles_select_own" ON public.web_user_profiles;
CREATE POLICY "web_user_profiles_select_own"
  ON public.web_user_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- User kann eigenes Profil anlegen
DROP POLICY IF EXISTS "web_user_profiles_insert_own" ON public.web_user_profiles;
CREATE POLICY "web_user_profiles_insert_own"
  ON public.web_user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins können alle Profile sehen und bearbeiten
-- (Nutzt profiles.role = 'root_admin' oder 'admin')
DROP POLICY IF EXISTS "web_user_profiles_admin_all" ON public.web_user_profiles;
CREATE POLICY "web_user_profiles_admin_all"
  ON public.web_user_profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'root_admin')
    )
  );

-- Realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'web_user_profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.web_user_profiles;
  END IF;
END $$;

-- Grants
GRANT SELECT, INSERT, UPDATE ON public.web_user_profiles TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.web_user_profiles TO authenticated;


-- ─── web_admin_notifications ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.web_admin_notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text NOT NULL,
  type        text NOT NULL DEFAULT 'access_request',
  message     text,
  is_read     boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_web_admin_notifications_is_read
  ON public.web_admin_notifications (is_read);
CREATE INDEX IF NOT EXISTS idx_web_admin_notifications_created_at
  ON public.web_admin_notifications (created_at DESC);

-- Row Level Security
ALTER TABLE public.web_admin_notifications ENABLE ROW LEVEL SECURITY;

-- Nur Admins können Admin-Benachrichtigungen sehen und bearbeiten
DROP POLICY IF EXISTS "web_admin_notifications_admin_all" ON public.web_admin_notifications;
CREATE POLICY "web_admin_notifications_admin_all"
  ON public.web_admin_notifications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'root_admin')
    )
  );

-- Jeder authentifizierte User kann Benachrichtigungen anlegen (für Zugriffsanträge)
DROP POLICY IF EXISTS "web_admin_notifications_insert_authenticated" ON public.web_admin_notifications;
CREATE POLICY "web_admin_notifications_insert_authenticated"
  ON public.web_admin_notifications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Anon darf ebenfalls inserieren (für Zugriffsanträge vor dem Login)
DROP POLICY IF EXISTS "web_admin_notifications_insert_anon" ON public.web_admin_notifications;
CREATE POLICY "web_admin_notifications_insert_anon"
  ON public.web_admin_notifications FOR INSERT
  WITH CHECK (true);

-- Grants
GRANT INSERT ON public.web_admin_notifications TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.web_admin_notifications TO authenticated;
