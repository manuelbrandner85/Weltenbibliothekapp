-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v84 – Cluster J: Ursprung-Tools
--
-- J2 rv_daily_targets:    Remote-Viewing Daily-Target-Pool
-- J2 rv_target_guesses:   User-Versuche
-- J4 manifestation_goals: Reality-Architect Manifestations-Tracker
-- ═══════════════════════════════════════════════════════════════

-- J2 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rv_daily_targets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  active_date  date NOT NULL UNIQUE,
  image_url    text NOT NULL,            -- Ziel-Bild (R2 oder external)
  hint         text,                     -- optional Hinweis fürs Review
  categories   text[] NOT NULL DEFAULT '{}',
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rv_targets_date
  ON public.rv_daily_targets (active_date DESC);

ALTER TABLE public.rv_daily_targets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rv_targets_read ON public.rv_daily_targets;
CREATE POLICY rv_targets_read ON public.rv_daily_targets
  FOR SELECT USING (active_date <= now()::date);

CREATE TABLE IF NOT EXISTS public.rv_target_guesses (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_id    uuid REFERENCES public.rv_daily_targets(id) ON DELETE CASCADE,
  user_id      text NOT NULL,
  username     text,
  guess_text   text,                     -- Beschreibung
  guess_sketch text,                     -- optionaler Sketch (base64 SVG/PNG)
  match_score  smallint,                 -- Self-Rating 0-100 nach Reveal
  submitted_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rv_guesses_target_user
  ON public.rv_target_guesses (target_id, user_id);

ALTER TABLE public.rv_target_guesses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rv_guesses_all ON public.rv_target_guesses;
CREATE POLICY rv_guesses_all ON public.rv_target_guesses
  FOR ALL USING (true) WITH CHECK (true);


-- J4 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.manifestation_goals (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  username     text,
  title        text NOT NULL,
  description  text,
  target_date  date,
  reminder_30d boolean NOT NULL DEFAULT true,
  reminder_90d boolean NOT NULL DEFAULT true,
  reviewed_at  timestamptz,
  manifested   boolean,                  -- NULL = noch offen, true/false nach review
  notes        text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_manifest_user_time
  ON public.manifestation_goals (user_id, created_at DESC);

ALTER TABLE public.manifestation_goals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS manifest_own ON public.manifestation_goals;
CREATE POLICY manifest_own ON public.manifestation_goals
  FOR ALL USING (true) WITH CHECK (true);

COMMENT ON TABLE public.rv_daily_targets IS 'Remote-Viewing Daily-Targets (J2).';
COMMENT ON TABLE public.manifestation_goals IS 'Manifestations-Ziele + Tracking (J4).';
