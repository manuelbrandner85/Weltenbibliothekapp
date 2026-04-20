-- ============================================================
-- v22: Spirit-Tools Phase 4 – Seelenvertrag (Tool 5)
-- Step 5.1a: Schema only (no seed data)
--
-- Numerologie-basierter Seelenvertrag:
--   - Lebensweg (Life Path)          aus Geburtsdatum
--   - Ausdruck (Destiny/Expression)  aus vollem Geburtsnamen
--   - Seelenantrieb (Soul Urge)      aus Vokalen im Namen
--   - Persönlichkeit (Personality)   aus Konsonanten im Namen
--   - Geburtstag (Birth Day)         aus Tag-Ziffer
-- Plus Karmische Schulden (13/14/16/19) und Meisterzahlen (11/22/33).
-- ============================================================

-- 1. soul_number_meanings (statisch, öffentlich lesbar) ---------
-- Pro (number, category) eine Bedeutung.
CREATE TABLE IF NOT EXISTS public.soul_number_meanings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- 1–9 Grundzahlen, 11/22/33 Meisterzahlen,
  -- 13/14/16/19 Karmische Schulden
  number INTEGER NOT NULL,
  -- 'life_path' | 'destiny' | 'soul_urge' | 'personality'
  --  | 'birth_day' | 'karmic_debt' | 'master'
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  keywords TEXT[] NOT NULL DEFAULT '{}',
  -- Kurzbeschreibung (1–2 Sätze)
  short_text TEXT NOT NULL,
  -- Tiefere Deutung (mehrere Absätze möglich)
  deep_text TEXT NOT NULL,
  -- Optionaler Heilungs-/Praxishinweis
  practice_text TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT soul_number_meanings_unique UNIQUE (number, category)
);
CREATE INDEX IF NOT EXISTS idx_soul_number_meanings_cat
  ON public.soul_number_meanings(category, number);

-- 2. soul_contracts (pro User, chronologisch) -------------------
CREATE TABLE IF NOT EXISTS public.soul_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- User-Eingaben (werden mitgespeichert, damit der Scan reproduzierbar ist)
  full_name TEXT NOT NULL,
  birth_date DATE NOT NULL,
  -- Berechnete Zahlen
  life_path INTEGER NOT NULL,
  destiny INTEGER NOT NULL,
  soul_urge INTEGER NOT NULL,
  personality INTEGER NOT NULL,
  birth_day INTEGER NOT NULL,
  -- Karmische Schulden, die im Chart vorkommen (Array)
  karmic_debts INTEGER[] NOT NULL DEFAULT '{}',
  -- Ganzes Berechnungs-Detail (zwischen-Summen, masterzahl-flags, etc.)
  computation JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Freitext-Notiz des Users
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_soul_contracts_user
  ON public.soul_contracts(user_id, computed_at DESC);

-- 3. RLS aktivieren ---------------------------------------------
ALTER TABLE public.soul_number_meanings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.soul_contracts       ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent) --------------------------------------
DROP POLICY IF EXISTS "Seelenzahlen öffentlich" ON public.soul_number_meanings;
CREATE POLICY "Seelenzahlen öffentlich" ON public.soul_number_meanings
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "User sieht eigene Seelenverträge" ON public.soul_contracts;
CREATE POLICY "User sieht eigene Seelenverträge" ON public.soul_contracts
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. GRANTs (PostgREST braucht explizite Table-Privileges) ------
GRANT SELECT                         ON public.soul_number_meanings TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.soul_contracts       TO authenticated;

-- ============================================================
-- Verifikation:
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema='public'
--     AND table_name IN ('soul_number_meanings','soul_contracts');
-- ============================================================
