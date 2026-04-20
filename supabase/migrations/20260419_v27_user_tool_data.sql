-- ============================================================
-- v27: Generische Cloud-Synchronisation für Spirit-Tool-Daten
-- ============================================================
-- Statt 21 spezialisierter Tabellen eine einzige generische
-- `user_tool_data` Tabelle als Key-Value-Store mit JSONB-Payload.
--
-- Warum generic statt 21 Tabellen:
--   • Eine RLS-Policy statt 21
--   • Hive-Boxen sind bereits KV-JSON — 1:1-Mapping ohne Schema-Drift
--   • Neue Tools (mantra_v2, …) brauchen keine neue Migration
--   • Indexed auf (user_id, tool_key) → O(log n) Lookups
--
-- Tool-Keys (= Hive-Box-Name):
--   'chakra_daily_scores'           tägliche Chakra-Balance
--   'chakra_journal'                Chakra-Tagebuch
--   'chakra_meditation_sessions'    Meditation pro Chakra
--   'chakra_affirmations'           gesammelte Affirmationen
--   'numerology_year_journey'       Personal-Year pro Jahr
--   'numerology_journal'            Numerologie-Journal
--   'numerology_milestones'         Meilensteine
--   'crystal_collection'            persönliche Kristalle
--   'mantra_challenges'             laufende Mantra-Challenges
--   'tool_streaks'                  Streaks pro Tool
--   'tarot_daily_cards'             Karte des Tages (Datum-Key)
--   'tarot_spreads'                 Tarot-Legungen
--   'synchronicity_entries'         Synchronizitäts-Erlebnisse
--   'journal_entries'               generisches Journal
--   'spirit_entries'                Spirit-Einträge
--   'spirit_progress'               Progress-Tracker
--   'partner_profiles'              Partner-Stammdaten
--   'compatibility_analyses'        Kompatibilitäts-Analysen
--   'weekly_horoscope'              Wochen-Horoskop-Cache
--   'meditation_sessions_enhanced'  neue Meditation-Tracks
--   'meditation_presets'            User-Presets
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_tool_data (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tool_key   TEXT NOT NULL,
  item_id    TEXT NOT NULL,
  data       JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, tool_key, item_id)
);

CREATE INDEX IF NOT EXISTS idx_user_tool_data_lookup
  ON public.user_tool_data(user_id, tool_key);
CREATE INDEX IF NOT EXISTS idx_user_tool_data_updated
  ON public.user_tool_data(user_id, tool_key, updated_at DESC);

-- updated_at auto-bump Trigger
CREATE OR REPLACE FUNCTION public.set_user_tool_data_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_tool_data_updated_at ON public.user_tool_data;
CREATE TRIGGER trg_user_tool_data_updated_at
  BEFORE UPDATE ON public.user_tool_data
  FOR EACH ROW EXECUTE FUNCTION public.set_user_tool_data_updated_at();

-- RLS: jeder User sieht/schreibt nur eigene Einträge
ALTER TABLE public.user_tool_data ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User eigene Tool-Daten" ON public.user_tool_data;
CREATE POLICY "User eigene Tool-Daten" ON public.user_tool_data
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_tool_data TO authenticated;

-- ============================================================
-- Verifikation (im SQL-Editor)
-- ============================================================
-- SELECT count(*) FROM public.user_tool_data;  -- sollte 0 sein
-- \d public.user_tool_data                     -- Schema prüfen
