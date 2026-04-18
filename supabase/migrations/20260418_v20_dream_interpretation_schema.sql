-- ============================================================
-- v20: Spirit-Tools Phase 2 – Traumdeutung (Tool 6)
-- Step 6.1a: Schema only (no seed data)
-- ============================================================
-- Legt Tabellen für Symbol-Lexikon + User-Traumtagebuch an.
-- Folgt dem v18/v19-Pattern: RLS + GRANT anon/authenticated.
-- Seeds werden in v20b/c/d/e nachgereicht.
-- ============================================================

-- 1. dream_symbols (statisches Lexikon, öffentlich lesbar) -----
CREATE TABLE IF NOT EXISTS public.dream_symbols (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Normalisierter Schlüssel (lowercase, ohne Umlaute/Leerzeichen).
  -- Beispiel: "wasser", "schlange", "verfolgtwerden".
  symbol_key TEXT NOT NULL UNIQUE,
  -- Anzeigename in Deutsch, z.B. "Wasser", "Verfolgt werden".
  symbol_name TEXT NOT NULL,
  -- Kategorie zum Gruppieren: 'element', 'tier', 'mensch',
  -- 'aktion', 'ort', 'objekt', 'natur', 'körper'.
  category TEXT NOT NULL,
  emoji TEXT,
  -- Synonyme/Stichwörter für Auto-Matching im Traumtext.
  -- Z.B. für "Wasser": ["see","meer","fluss","ozean","regen"].
  keywords TEXT[] NOT NULL DEFAULT '{}',
  -- Bedeutungen pro Tradition als JSONB:
  -- {
  --   "jungian": "...",   (Jung: Archetypen/kollektives Unbewusstes)
  --   "freudian": "...",  (Freud: verdrängte Wünsche)
  --   "spiritual": "...", (Esoterisch/New-Age)
  --   "shamanic": "...",  (Schamanisch/Naturvölker)
  --   "germanic": "..."   (Germanisch/Paungger-Tradition)
  -- }
  meanings JSONB NOT NULL DEFAULT '{}'::jsonb,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dream_symbols_category
  ON public.dream_symbols(category, sort_order);
CREATE INDEX IF NOT EXISTS idx_dream_symbols_keywords
  ON public.dream_symbols USING GIN(keywords);

-- 2. dream_journal_v2 (pro User, chronologisch) ----------------
-- Neue Tabelle statt alter dream-Tabelle damit altes Tool
-- parallel weiter funktioniert, bis Phase 6.4 die Integration
-- umschaltet.
CREATE TABLE IF NOT EXISTS public.dream_journal_v2 (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  dream_date DATE NOT NULL DEFAULT CURRENT_DATE,
  title TEXT,
  description TEXT NOT NULL,
  -- Auto-getaggte Symbole (Array aus symbol_key-Werten).
  -- Z.B. ['wasser','schlange','verfolgtwerden'].
  symbol_tags TEXT[] NOT NULL DEFAULT '{}',
  -- Stimmung: 'angst','freude','traurig','wut','neutral','ekstatisch'.
  mood TEXT,
  lucid BOOLEAN NOT NULL DEFAULT false,
  -- Wiederkehrender Traum?
  recurring BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dream_journal_v2_user
  ON public.dream_journal_v2(user_id, dream_date DESC);
CREATE INDEX IF NOT EXISTS idx_dream_journal_v2_tags
  ON public.dream_journal_v2 USING GIN(symbol_tags);

-- 3. RLS aktivieren ---------------------------------------------
ALTER TABLE public.dream_symbols     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dream_journal_v2  ENABLE ROW LEVEL SECURITY;

-- 4. Policies (idempotent) --------------------------------------
DROP POLICY IF EXISTS "Traumsymbole öffentlich"        ON public.dream_symbols;
CREATE POLICY "Traumsymbole öffentlich" ON public.dream_symbols
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "User sieht eigenes Traumbuch"   ON public.dream_journal_v2;
CREATE POLICY "User sieht eigenes Traumbuch" ON public.dream_journal_v2
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. Table-Privileges (PostgREST braucht explizite GRANTs) -----
GRANT SELECT                         ON public.dream_symbols    TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.dream_journal_v2 TO authenticated;

-- ============================================================
-- Verifikation (nach Apply):
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema='public'
--     AND table_name IN ('dream_symbols','dream_journal_v2');
-- ============================================================
