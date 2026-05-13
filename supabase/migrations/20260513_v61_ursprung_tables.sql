-- ══════════════════════════════════════════════════════════════════════════════
-- v61 — URSPRUNG TABLES (Module + Progress + Gateway + Patterns + RV)
-- ══════════════════════════════════════════════════════════════════════════════
-- Basis für AUFGABE 5A + 5C-Tabellen aus CIA Gateway / Quanten-Code System.

-- ── 1. URSPRUNG_MODULES ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ursprung_modules (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_code           TEXT UNIQUE NOT NULL,
  branch                TEXT NOT NULL,
  branch_order          INTEGER NOT NULL,
  title                 TEXT NOT NULL,
  subtitle              TEXT,
  theory_content        TEXT NOT NULL,
  cia_source            TEXT,
  cia_source_url        TEXT,
  case_study            TEXT,
  exercise_description  TEXT NOT NULL,
  exercise_duration_minutes INTEGER DEFAULT 15,
  audio_frequency_hz    REAL,
  test_questions        JSONB,
  xp_reward             INTEGER DEFAULT 50,
  is_boss_module        BOOLEAN DEFAULT false,
  prerequisites         TEXT[],
  youtube_search_query  TEXT,
  gateway_wave          TEXT,
  focus_level           TEXT,
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ursprung_modules_branch ON public.ursprung_modules (branch, branch_order);
CREATE INDEX IF NOT EXISTS idx_ursprung_modules_code   ON public.ursprung_modules (module_code);

-- ── 2. USER_URSPRUNG_PROGRESS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_ursprung_progress (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id             UUID NOT NULL REFERENCES public.ursprung_modules(id) ON DELETE CASCADE,
  module_code           TEXT,
  theory_read           BOOLEAN DEFAULT false,
  case_study_read       BOOLEAN DEFAULT false,
  exercise_completed    BOOLEAN DEFAULT false,
  exercise_notes        TEXT,
  test_score            INTEGER,
  test_passed           BOOLEAN DEFAULT false,
  completed_at          TIMESTAMPTZ,
  UNIQUE(user_id, module_id)
);

CREATE INDEX IF NOT EXISTS idx_user_ursprung_user   ON public.user_ursprung_progress (user_id);
CREATE INDEX IF NOT EXISTS idx_user_ursprung_module ON public.user_ursprung_progress (module_id);
CREATE INDEX IF NOT EXISTS idx_user_ursprung_code   ON public.user_ursprung_progress (module_code);

-- ── 3. GATEWAY SESSIONS ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ursprung_gateway_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  focus_level_reached   TEXT NOT NULL,
  duration_minutes      INTEGER NOT NULL,
  notes                 TEXT,
  biometric_before      JSONB,
  biometric_after       JSONB,
  created_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ursprung_gateway_user ON public.ursprung_gateway_sessions (user_id, created_at DESC);

-- ── 4. PATTERNS (Manifestation) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ursprung_patterns (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category              TEXT NOT NULL,
  goal_text             TEXT NOT NULL,
  present_tense         TEXT NOT NULL,
  senses                JSONB NOT NULL,
  emotion               TEXT NOT NULL,
  emotion_intensity     INTEGER NOT NULL,
  target_date           DATE,
  status                TEXT DEFAULT 'active' CHECK (status IN ('active', 'manifested', 'released', 'modified')),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  manifested_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_ursprung_patterns_user ON public.ursprung_patterns (user_id, created_at DESC);

-- ── 5. RV TARGETS ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rv_targets (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_number         TEXT UNIQUE NOT NULL,
  target_name           TEXT NOT NULL,
  target_category       TEXT NOT NULL,
  target_description    TEXT NOT NULL,
  target_image_url      TEXT,
  gestalt_keywords      TEXT[],
  sensory_keywords      TEXT[],
  inserted_at           TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rv_targets_category ON public.rv_targets (target_category);

-- ── 6. RV SESSIONS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rv_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id             UUID NOT NULL REFERENCES public.rv_targets(id) ON DELETE CASCADE,
  stage1_response       JSONB,
  stage2_response       JSONB,
  stage3_sketch_url     TEXT,
  score_percent         INTEGER,
  session_mode          TEXT DEFAULT 'guided',
  duration_seconds      INTEGER,
  created_at            TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rv_sessions_user ON public.rv_sessions (user_id, created_at DESC);

-- ── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.ursprung_modules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ursprung_modules_select_all" ON public.ursprung_modules;
CREATE POLICY "ursprung_modules_select_all" ON public.ursprung_modules FOR SELECT USING (true);

ALTER TABLE public.user_ursprung_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "uup_select_own" ON public.user_ursprung_progress;
CREATE POLICY "uup_select_own" ON public.user_ursprung_progress FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "uup_insert_own" ON public.user_ursprung_progress;
CREATE POLICY "uup_insert_own" ON public.user_ursprung_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "uup_update_own" ON public.user_ursprung_progress;
CREATE POLICY "uup_update_own" ON public.user_ursprung_progress FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE public.ursprung_gateway_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ugs_select_own" ON public.ursprung_gateway_sessions;
CREATE POLICY "ugs_select_own" ON public.ursprung_gateway_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "ugs_insert_own" ON public.ursprung_gateway_sessions;
CREATE POLICY "ugs_insert_own" ON public.ursprung_gateway_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

ALTER TABLE public.ursprung_patterns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "up_select_own" ON public.ursprung_patterns;
CREATE POLICY "up_select_own" ON public.ursprung_patterns FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "up_insert_own" ON public.ursprung_patterns;
CREATE POLICY "up_insert_own" ON public.ursprung_patterns FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "up_update_own" ON public.ursprung_patterns;
CREATE POLICY "up_update_own" ON public.ursprung_patterns FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE public.rv_targets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rvt_select_all" ON public.rv_targets;
CREATE POLICY "rvt_select_all" ON public.rv_targets FOR SELECT USING (true);

ALTER TABLE public.rv_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rvs_select_own" ON public.rv_sessions;
CREATE POLICY "rvs_select_own" ON public.rv_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "rvs_insert_own" ON public.rv_sessions;
CREATE POLICY "rvs_insert_own" ON public.rv_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ── GRANTS ──────────────────────────────────────────────────────────────────
GRANT SELECT ON public.ursprung_modules TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_ursprung_progress TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.ursprung_gateway_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.ursprung_patterns TO authenticated;
GRANT SELECT ON public.rv_targets TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.rv_sessions TO authenticated;
