-- ============================================================
-- v23: Spirit-Tools Phase 5 – Ahnenarbeit (Tool 4)
-- Step 4.1a: Schema only (no seed data)
--
-- Drei Tabellen:
--   - ancestors           (user-scoped: eingetragene Ahnen)
--   - ancestor_patterns   (user-scoped: Familien-/Generationsmuster)
--   - ancestral_rituals   (statisch öffentlich: Rituale aus Traditionen)
-- ============================================================

-- 1. ancestors (pro User) ---------------------------------------
CREATE TABLE IF NOT EXISTS public.ancestors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  -- 'mother','father','grandmother_mat','grandfather_mat',
  -- 'grandmother_pat','grandfather_pat','great_grand_*',
  -- 'aunt','uncle','sibling','other'
  relation TEXT NOT NULL,
  birth_year INTEGER,
  death_year INTEGER,
  -- was über diese Person bekannt ist (Eigenschaften, Werte, Prägungen)
  known_traits TEXT[] NOT NULL DEFAULT '{}',
  -- Geschichte / Erinnerungen
  story TEXT,
  -- Gaben, die diese Person mitbrachte
  gifts TEXT,
  -- Wunden/Themen, die noch Heilung brauchen
  healing_needed TEXT,
  -- User-Intention zu dieser Person
  intention TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ancestors_user
  ON public.ancestors(user_id, created_at DESC);

-- 2. ancestor_patterns (pro User) -------------------------------
-- Familien-Muster, Generations-Themen, Glaubens-Sätze
CREATE TABLE IF NOT EXISTS public.ancestor_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  -- Beschreibung des Musters
  description TEXT NOT NULL,
  -- 'belief','trauma','strength','gift','silence','taboo','other'
  pattern_type TEXT NOT NULL DEFAULT 'other',
  -- betroffene Generationen, Freitext
  generations_affected TEXT,
  -- Heil-Intention
  healing_intention TEXT,
  -- Status: 'recognized','in_healing','integrated'
  status TEXT NOT NULL DEFAULT 'recognized',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ancestor_patterns_user
  ON public.ancestor_patterns(user_id, created_at DESC);

-- 3. ancestral_rituals (statisch, öffentlich lesbar) ------------
CREATE TABLE IF NOT EXISTS public.ancestral_rituals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  -- Tradition: 'allgemein','schamanisch','keltisch','familienaufstellung',
  -- 'germanisch','afrikanisch','ostasiatisch','buddhistisch'
  tradition TEXT NOT NULL,
  emoji TEXT NOT NULL DEFAULT '🕯️',
  description TEXT NOT NULL,
  -- geordnete Schritte
  steps TEXT[] NOT NULL DEFAULT '{}',
  -- benötigte Materialien
  materials TEXT[] NOT NULL DEFAULT '{}',
  duration_minutes INTEGER NOT NULL DEFAULT 20,
  -- empfohlener Zeitpunkt / Zyklus
  best_time TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_ancestral_rituals_tradition
  ON public.ancestral_rituals(tradition, sort_order);

-- 4. RLS ---------------------------------------------------------
ALTER TABLE public.ancestors           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ancestor_patterns   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ancestral_rituals   ENABLE ROW LEVEL SECURITY;

-- 5. Policies (idempotent) ---------------------------------------
DROP POLICY IF EXISTS "User sieht eigene Ahnen" ON public.ancestors;
CREATE POLICY "User sieht eigene Ahnen" ON public.ancestors
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "User sieht eigene Muster" ON public.ancestor_patterns;
CREATE POLICY "User sieht eigene Muster" ON public.ancestor_patterns
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Ahnen-Rituale öffentlich" ON public.ancestral_rituals;
CREATE POLICY "Ahnen-Rituale öffentlich" ON public.ancestral_rituals
  FOR SELECT TO anon, authenticated USING (true);

-- 6. GRANTs ------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ancestors         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ancestor_patterns TO authenticated;
GRANT SELECT                         ON public.ancestral_rituals TO anon, authenticated;

-- ============================================================
-- Verifikation:
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema='public'
--     AND table_name IN ('ancestors','ancestor_patterns','ancestral_rituals');
-- ============================================================
