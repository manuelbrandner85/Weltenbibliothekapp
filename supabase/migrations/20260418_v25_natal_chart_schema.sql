-- ============================================================
-- v25: Spirit-Tools Phase 5 – Geburtshoroskop (Tool 1)
-- Step 1.1a: Schema only (no seed data)
--
-- Zwei Tabellen:
--   - natal_charts              (user-scoped: gespeicherte Geburtshoroskope)
--   - astrology_meanings        (statisch öffentlich: Planeten/Zeichen/Häuser/Aspekte)
-- ============================================================

-- 1. natal_charts (pro User) ------------------------------------
CREATE TABLE IF NOT EXISTS public.natal_charts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Name / Titel des Charts (z. B. "Ich", "Partner", "Kind")
  label TEXT NOT NULL,
  -- Geburtsdaten
  birth_date DATE NOT NULL,
  birth_time TIME,                -- kann NULL sein (Zeit unbekannt)
  birth_time_unknown BOOLEAN NOT NULL DEFAULT FALSE,
  birth_place TEXT,
  birth_latitude DOUBLE PRECISION,
  birth_longitude DOUBLE PRECISION,
  -- Zeitzone als IANA-String (z. B. "Europe/Vienna") oder offset_hours
  timezone_offset_hours DOUBLE PRECISION NOT NULL DEFAULT 0,
  -- Zentrale Punkte: Zeichen (0–11) und Grad (0–30) in jeweiligem Zeichen
  -- 0=Widder,1=Stier,2=Zwillinge,...,11=Fische
  sun_sign INTEGER,
  sun_degree DOUBLE PRECISION,
  moon_sign INTEGER,
  moon_degree DOUBLE PRECISION,
  mercury_sign INTEGER,
  mercury_degree DOUBLE PRECISION,
  venus_sign INTEGER,
  venus_degree DOUBLE PRECISION,
  mars_sign INTEGER,
  mars_degree DOUBLE PRECISION,
  jupiter_sign INTEGER,
  jupiter_degree DOUBLE PRECISION,
  saturn_sign INTEGER,
  saturn_degree DOUBLE PRECISION,
  uranus_sign INTEGER,
  uranus_degree DOUBLE PRECISION,
  neptune_sign INTEGER,
  neptune_degree DOUBLE PRECISION,
  pluto_sign INTEGER,
  pluto_degree DOUBLE PRECISION,
  ascendant_sign INTEGER,         -- nur bekannt wenn birth_time + lat/lng vorhanden
  ascendant_degree DOUBLE PRECISION,
  mc_sign INTEGER,                -- Medium Coeli (nur mit Zeit+Ort)
  mc_degree DOUBLE PRECISION,
  -- Vollständige Berechnung zur Transparenz
  computation JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- User-Notizen
  notes TEXT,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_natal_charts_user
  ON public.natal_charts(user_id, computed_at DESC);

-- 2. astrology_meanings (statisch, öffentlich lesbar) -----------
-- category: 'sign','planet','house','aspect','element','modality'
-- key:      bei sign 0–11 als String, bei planet 'sun','moon',...
CREATE TABLE IF NOT EXISTS public.astrology_meanings (
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
CREATE INDEX IF NOT EXISTS idx_astrology_meanings_cat
  ON public.astrology_meanings(category, sort_order);

-- 3. RLS ---------------------------------------------------------
ALTER TABLE public.natal_charts       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astrology_meanings ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent) ---------------------------------------
DROP POLICY IF EXISTS "User sieht eigene Charts" ON public.natal_charts;
CREATE POLICY "User sieht eigene Charts" ON public.natal_charts
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Astrologie-Lexikon öffentlich" ON public.astrology_meanings;
CREATE POLICY "Astrologie-Lexikon öffentlich" ON public.astrology_meanings
  FOR SELECT TO anon, authenticated USING (true);

-- 5. GRANTs ------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON public.natal_charts       TO authenticated;
GRANT SELECT                         ON public.astrology_meanings TO anon, authenticated;
