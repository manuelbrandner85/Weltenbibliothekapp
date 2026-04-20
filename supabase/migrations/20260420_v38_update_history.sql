-- Phase 1f: update_history Tabelle
-- Speichert jeden veröffentlichten Release und OTA-Patch als Eintrag.
-- Wird von build_apk.yml (type=release) und shorebird_patch.yml (type=patch)
-- per INSERT befüllt. Read-only für alle eingeloggten User.

CREATE TABLE IF NOT EXISTS public.update_history (
  id            uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  type          text          NOT NULL CHECK (type IN ('release', 'patch')),
  version       text          NOT NULL,   -- APP_VERSION (z.B. '5.36.0')
  patch_number  int,                      -- Shorebird-Patch-Nummer (nur bei type=patch)
  changelog     text,                     -- Changelog-Text
  published_at  timestamptz   NOT NULL DEFAULT now(),
  github_run_url text                     -- Link zum CI-Run
);

ALTER TABLE public.update_history ENABLE ROW LEVEL SECURITY;

-- Lesen für alle eingeloggten User
DROP POLICY IF EXISTS "update_history_read_authenticated" ON public.update_history;
CREATE POLICY "update_history_read_authenticated"
  ON public.update_history
  FOR SELECT
  TO authenticated
  USING (true);

-- Anon darf auch lesen (Splash / vor Login)
DROP POLICY IF EXISTS "update_history_read_anon" ON public.update_history;
CREATE POLICY "update_history_read_anon"
  ON public.update_history
  FOR SELECT
  TO anon
  USING (true);

-- Schreiben nur via SERVICE_ROLE (CI-Workflows)
-- SERVICE_ROLE umgeht RLS automatisch → keine zusätzliche Policy nötig.

CREATE INDEX IF NOT EXISTS update_history_published_at_idx
  ON public.update_history (published_at DESC);
