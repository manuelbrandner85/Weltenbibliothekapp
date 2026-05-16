-- ══════════════════════════════════════════════════════════════════════════════
-- v67 — DIE GEHEIME BIBLIOTHEK (AUFGABE 9B)
-- Originalquellen-Datenbank, freigeschaltet ab Level 10
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.bibliothek_books (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  author          TEXT NOT NULL,
  year            TEXT,
  category        TEXT NOT NULL CHECK (category IN
    ('cia','hermetik','alchemie','quantenphysik','philosophie','mystik')),
  summary         TEXT NOT NULL,
  key_insights    TEXT[] NOT NULL DEFAULT '{}',
  related_modules TEXT[] DEFAULT '{}',
  external_url    TEXT,
  difficulty      TEXT DEFAULT 'intermediate'
                    CHECK (difficulty IN ('beginner','intermediate','advanced','master')),
  cover_color     TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bibliothek_category ON public.bibliothek_books (category);
CREATE INDEX IF NOT EXISTS idx_bibliothek_year     ON public.bibliothek_books (year);

ALTER TABLE public.bibliothek_books ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "bibliothek_select_all" ON public.bibliothek_books;
CREATE POLICY "bibliothek_select_all" ON public.bibliothek_books
  FOR SELECT USING (true);

GRANT SELECT ON public.bibliothek_books TO anon, authenticated;
