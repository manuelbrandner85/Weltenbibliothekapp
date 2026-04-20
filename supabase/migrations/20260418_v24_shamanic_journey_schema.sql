-- ============================================================
-- v24: Spirit-Tools Phase 5 – Schamanische Reise (Tool 2)
-- Step 2.1a: Schema only (no seed data)
--
-- Drei Tabellen:
--   - shamanic_journeys       (user-scoped: durchgeführte Reisen + Erlebnisse)
--   - shamanic_power_animals  (user-scoped: persönliche Krafttiere)
--   - shamanic_journey_guides (statisch öffentlich: Reise-Leitfäden)
-- ============================================================

-- 1. shamanic_journeys (pro User) ------------------------------
CREATE TABLE IF NOT EXISTS public.shamanic_journeys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- 'lower_world','upper_world','middle_world'
  world TEXT NOT NULL,
  -- Intention / Frage für diese Reise
  intention TEXT NOT NULL,
  -- Methode: 'drum','rattle','breath','silence','guided'
  method TEXT NOT NULL DEFAULT 'drum',
  -- Dauer in Minuten (meist 15–30)
  duration_minutes INTEGER NOT NULL DEFAULT 20,
  -- Was wurde erlebt? Bilder, Symbole, Worte, Gefühle
  experience TEXT,
  -- Begegnete Wesen (Krafttiere, Ahnen, Geistführer)
  encountered_beings TEXT[] NOT NULL DEFAULT '{}',
  -- Empfangene Symbole / Gaben
  symbols_received TEXT[] NOT NULL DEFAULT '{}',
  -- Antwort / Botschaft
  message TEXT,
  -- Integration: wie setze ich das Erlebte im Alltag um?
  integration TEXT,
  journeyed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_shamanic_journeys_user
  ON public.shamanic_journeys(user_id, journeyed_at DESC);

-- 2. shamanic_power_animals (pro User) -------------------------
CREATE TABLE IF NOT EXISTS public.shamanic_power_animals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  animal TEXT NOT NULL,
  -- wann es sich zeigte
  first_encountered_at TIMESTAMPTZ,
  -- Qualitäten dieses Krafttiers
  qualities TEXT[] NOT NULL DEFAULT '{}',
  -- Botschaft / Aufgabe dieses Krafttiers
  message TEXT,
  -- Werkzeuge / Geschenke, die es gibt
  gifts TEXT,
  -- weiterhin aktiv als Begleiter?
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_shamanic_power_animals_user
  ON public.shamanic_power_animals(user_id, created_at DESC);

-- 3. shamanic_journey_guides (statisch, öffentlich lesbar) -----
CREATE TABLE IF NOT EXISTS public.shamanic_journey_guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  -- Welt-Empfehlung: 'lower','upper','middle','any'
  world TEXT NOT NULL DEFAULT 'any',
  emoji TEXT NOT NULL DEFAULT '🥁',
  -- kurze Beschreibung, worum es geht
  description TEXT NOT NULL,
  -- geordnete Schritte
  steps TEXT[] NOT NULL DEFAULT '{}',
  -- typische Intentionen / Fragen
  sample_intentions TEXT[] NOT NULL DEFAULT '{}',
  -- empfohlene Dauer in Minuten
  duration_minutes INTEGER NOT NULL DEFAULT 20,
  -- Vorbereitung, Materialien
  preparation TEXT,
  -- Warnhinweise / für wen geeignet
  safety_notes TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_shamanic_journey_guides_world
  ON public.shamanic_journey_guides(world, sort_order);

-- 4. RLS ---------------------------------------------------------
ALTER TABLE public.shamanic_journeys       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shamanic_power_animals  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shamanic_journey_guides ENABLE ROW LEVEL SECURITY;

-- 5. Policies (idempotent) ---------------------------------------
DROP POLICY IF EXISTS "User sieht eigene Reisen" ON public.shamanic_journeys;
CREATE POLICY "User sieht eigene Reisen" ON public.shamanic_journeys
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "User sieht eigene Krafttiere" ON public.shamanic_power_animals;
CREATE POLICY "User sieht eigene Krafttiere" ON public.shamanic_power_animals
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Reise-Leitfäden öffentlich" ON public.shamanic_journey_guides;
CREATE POLICY "Reise-Leitfäden öffentlich" ON public.shamanic_journey_guides
  FOR SELECT TO anon, authenticated USING (true);

-- 6. GRANTs ------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shamanic_journeys       TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shamanic_power_animals  TO authenticated;
GRANT SELECT                         ON public.shamanic_journey_guides TO anon, authenticated;
