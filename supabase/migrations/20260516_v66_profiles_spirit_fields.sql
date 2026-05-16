-- ══════════════════════════════════════════════════════════════════════════════
-- v66 — PROFILES SPIRIT-FELDER + WELTÜBERGREIFENDES PROFIL
-- ══════════════════════════════════════════════════════════════════════════════
-- Erweitert die profiles-Tabelle um Spirit-Daten (Geburtstag, Ort, Name)
-- die von allen Berechnungstools (Numerologie, Astrologie, Human Design) genutzt werden.
-- Das `world`-Feld wird auf alle 4 Welten + NULL erweitert (kein Pflichtfeld mehr).

-- ── 1. WORLD-CHECK ERWEITERN (alle 4 Welten + NULL) ─────────────────────────
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_world_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_world_check
    CHECK (world IN ('materie','energie','vorhang','ursprung','both') OR world IS NULL);

ALTER TABLE public.profiles
  ALTER COLUMN world DROP NOT NULL;

ALTER TABLE public.profiles
  ALTER COLUMN world DROP DEFAULT;

-- ── 2. SPIRIT-FELDER HINZUFÜGEN ─────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS full_name   TEXT,
  ADD COLUMN IF NOT EXISTS birth_date  DATE,
  ADD COLUMN IF NOT EXISTS birth_time  TIME,
  ADD COLUMN IF NOT EXISTS birth_place TEXT;

-- ── 3. INDEX FÜR SUPABASE-ABFRAGEN ─────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_profiles_birth_date ON public.profiles (birth_date)
  WHERE birth_date IS NOT NULL;

-- ── 4. RLS SICHERSTELLEN (spirit fields lesbar für alle, schreibbar nur eigen) ─
-- Die bestehenden RLS-Policies auf profiles decken bereits alle Spalten ab.
-- Kein zusätzliches Setup nötig — die neuen Spalten folgen den bestehenden Policies.

-- ── 5. REALTIME (idempotent) ──────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  END IF;
END$$;
