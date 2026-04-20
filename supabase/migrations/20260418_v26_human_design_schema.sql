-- ============================================================
-- v26: Spirit-Tools Phase 6 – Human Design (Tool 3)
-- Step 3.1a: Schema (ohne Seed)
--
-- Zwei Tabellen:
--   - human_design_charts  (user-scoped)
--   - hd_meanings          (public: types, authorities, centers, gates, profiles)
-- ============================================================

-- 1. human_design_charts ----------------------------------------
CREATE TABLE IF NOT EXISTS public.human_design_charts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  -- Geburtsdaten
  birth_date DATE NOT NULL,
  birth_time TIME,
  birth_time_unknown BOOLEAN NOT NULL DEFAULT FALSE,
  birth_place TEXT,
  birth_latitude DOUBLE PRECISION,
  birth_longitude DOUBLE PRECISION,
  timezone_offset_hours DOUBLE PRECISION NOT NULL DEFAULT 0,
  -- Kern-Ergebnisse (kompakt)
  -- type: 'manifestor','generator','manifesting_generator','projector','reflector'
  type TEXT,
  -- authority: 'emotional','sacral','splenic','ego','self_projected','lunar','mental'
  authority TEXT,
  -- strategy: 'inform','respond','wait_invitation','wait_lunar'
  strategy TEXT,
  -- profile: z. B. '1/3', '6/2'
  profile TEXT,
  -- Aktive Gates (Array von 1..64)
  defined_gates INTEGER[] NOT NULL DEFAULT '{}',
  -- Definierte Zentren: 'head','ajna','throat','g','heart','sacral','solar_plexus','spleen','root'
  defined_centers TEXT[] NOT NULL DEFAULT '{}',
  -- Komplette Berechnung (Personality + Design Aktivierungen, Lines etc.)
  computation JSONB NOT NULL DEFAULT '{}'::jsonb,
  notes TEXT,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_hd_charts_user
  ON public.human_design_charts(user_id, computed_at DESC);

-- 2. hd_meanings ------------------------------------------------
-- category: 'type','authority','center','gate','profile','strategy'
-- key: gate '1'..'64'; center 'head'...'root'; type 'manifestor'...; etc.
CREATE TABLE IF NOT EXISTS public.hd_meanings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  key TEXT NOT NULL,
  title TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '✨',
  keywords TEXT[] NOT NULL DEFAULT '{}',
  short_text TEXT NOT NULL,
  deep_text TEXT,
  shadow_text TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  UNIQUE (category, key)
);
CREATE INDEX IF NOT EXISTS idx_hd_meanings_cat
  ON public.hd_meanings(category, sort_order);

-- 3. RLS --------------------------------------------------------
ALTER TABLE public.human_design_charts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hd_meanings         ENABLE ROW LEVEL SECURITY;

-- 4. Policies ---------------------------------------------------
DROP POLICY IF EXISTS "User sieht eigene HD-Charts" ON public.human_design_charts;
CREATE POLICY "User sieht eigene HD-Charts" ON public.human_design_charts
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "HD-Lexikon öffentlich" ON public.hd_meanings;
CREATE POLICY "HD-Lexikon öffentlich" ON public.hd_meanings
  FOR SELECT TO anon, authenticated USING (true);

-- 5. GRANTs -----------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON public.human_design_charts TO authenticated;
GRANT SELECT                         ON public.hd_meanings         TO anon, authenticated;
