-- ============================================================
-- v21: Spirit-Tools Phase 3 – Chakra-Körperscan (Tool 7)
-- Step 7.1a: Schema only (no seed data)
-- ============================================================

-- 1. chakra_symptoms (statisch, öffentlich lesbar) --------------
-- Jede Zeile: ein Symptom das einem Chakra zugeordnet ist.
-- Ein Symptom kann mehreren Chakren zugeordnet sein (mehrere Rows).
CREATE TABLE IF NOT EXISTS public.chakra_symptoms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- 1=Wurzel, 2=Sakral, 3=Solarplexus, 4=Herz,
  -- 5=Kehle, 6=Stirn/Drittes Auge, 7=Krone
  chakra_number INTEGER NOT NULL CHECK (chakra_number BETWEEN 1 AND 7),
  chakra_name TEXT NOT NULL,
  chakra_color TEXT NOT NULL,
  chakra_emoji TEXT NOT NULL,
  -- Kategorien: 'körperlich', 'emotional', 'mental', 'spirituell'
  symptom_category TEXT NOT NULL,
  symptom_text TEXT NOT NULL,
  -- Gewichtung: 1=schwach, 2=mittel, 3=stark (für Score)
  weight INTEGER NOT NULL DEFAULT 2 CHECK (weight BETWEEN 1 AND 3),
  sort_order INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_chakra_symptoms_chakra
  ON public.chakra_symptoms(chakra_number, symptom_category);

-- 2. body_scan_results (pro User, chronologisch) ---------------
CREATE TABLE IF NOT EXISTS public.body_scan_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scanned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Gewählte Symptom-IDs (Array)
  selected_symptom_ids UUID[] NOT NULL DEFAULT '{}',
  -- Ergebnis als JSONB: { "1": 6, "2": 3, … } (chakra_number → score)
  chakra_scores JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Chakra-Nummer mit höchstem Score (Haupt-Blockade)
  primary_blocked_chakra INTEGER,
  -- Freitext-Notiz des Users
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_body_scan_results_user
  ON public.body_scan_results(user_id, scanned_at DESC);

-- 3. RLS aktivieren ---------------------------------------------
ALTER TABLE public.chakra_symptoms    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_scan_results  ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent) --------------------------------------
DROP POLICY IF EXISTS "Chakra-Symptome öffentlich" ON public.chakra_symptoms;
CREATE POLICY "Chakra-Symptome öffentlich" ON public.chakra_symptoms
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "User sieht eigene Scan-Ergebnisse" ON public.body_scan_results;
CREATE POLICY "User sieht eigene Scan-Ergebnisse" ON public.body_scan_results
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. GRANTs (PostgREST braucht explizite Table-Privileges) ------
GRANT SELECT                         ON public.chakra_symptoms   TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.body_scan_results TO authenticated;

-- ============================================================
-- Verifikation:
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema='public'
--     AND table_name IN ('chakra_symptoms','body_scan_results');
-- ============================================================
