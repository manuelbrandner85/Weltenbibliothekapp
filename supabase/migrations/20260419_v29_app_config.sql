-- ============================================================================
-- Migration v29: App-Update-Config (Release-Update-Dialog)
-- ============================================================================
-- Steuert den In-App Release-Update-Dialog. Gibt an welche Version die
-- neueste ist und wo User die APK herunterladen können.
--
-- Verwendet von: lib/services/update_service.dart
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.app_config (
  id              uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  platform        text          NOT NULL UNIQUE CHECK (platform IN ('android', 'ios')),
  latest_version  text          NOT NULL,   -- z.B. '5.31.0' (Semver ohne Build-Nummer)
  min_version     text          NOT NULL,   -- Unterhalb davon = Force-Update
  apk_download_url text         NOT NULL,   -- Direktlink zur APK im GitHub Release
  changelog       text,                     -- Optional: Kurzer Changelog für Dialog
  release_notes_url text,                   -- Optional: Link zu ausführlichen Notes
  updated_at      timestamptz   NOT NULL DEFAULT now()
);

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Lesen erlaubt für alle eingeloggten User (public-read-only Config)
DROP POLICY IF EXISTS "app_config_read_authenticated" ON public.app_config;
CREATE POLICY "app_config_read_authenticated"
  ON public.app_config
  FOR SELECT
  TO authenticated
  USING (true);

-- Anon (während Splash / vor Login) darf auch lesen
DROP POLICY IF EXISTS "app_config_read_anon" ON public.app_config;
CREATE POLICY "app_config_read_anon"
  ON public.app_config
  FOR SELECT
  TO anon
  USING (true);

-- Schreiben: nur via SERVICE_ROLE (Worker / Admin)
-- -> keine Client-Policy für INSERT/UPDATE/DELETE nötig,
--    SERVICE_ROLE umgeht RLS automatisch.

-- Trigger: updated_at automatisch pflegen
CREATE OR REPLACE FUNCTION public.app_config_touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS app_config_touch_updated_at_trigger ON public.app_config;
CREATE TRIGGER app_config_touch_updated_at_trigger
  BEFORE UPDATE ON public.app_config
  FOR EACH ROW
  EXECUTE FUNCTION public.app_config_touch_updated_at();

-- Initial-Seed: aktuelle Android-Version
INSERT INTO public.app_config (platform, latest_version, min_version, apk_download_url, changelog)
VALUES (
  'android',
  '5.30.1',
  '5.30.0',
  'https://github.com/manuelbrandner85/Weltenbibliothekapp/releases/latest',
  'Recherche-Tab im Home-Dashboard-Stil, Stabilitätsverbesserungen.'
)
ON CONFLICT (platform) DO NOTHING;
