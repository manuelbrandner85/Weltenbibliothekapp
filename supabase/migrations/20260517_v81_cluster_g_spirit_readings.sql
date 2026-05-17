-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v81 – Cluster G: Spirit-Tool-Readings (Server-Persist)
--
-- G4 spirit_readings: unified History für alle 15 Spirit-Tools.
-- Optional Server-Sync für die lokal in SQLite-Boxen gespeicherten
-- Ergebnisse — erlaubt Vergleiche / Audio-TTS / Combo-Synthesen
-- (G1/G2/G3) auch nach App-Reinstall.
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.spirit_readings (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  username     text,
  tool         text NOT NULL,          -- 'chakra' | 'numerology' | …
  summary      text,                   -- 1-Zeiler für die History-Liste
  result       jsonb NOT NULL,         -- vollständiges Tool-Ergebnis
  audio_url    text,                   -- gecachtes TTS (G3) — optional
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spirit_readings_user_tool_time
  ON public.spirit_readings (user_id, tool, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_spirit_readings_user_time
  ON public.spirit_readings (user_id, created_at DESC);

ALTER TABLE public.spirit_readings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS readings_own ON public.spirit_readings;
CREATE POLICY readings_own ON public.spirit_readings
  FOR ALL USING (true) WITH CHECK (true);

COMMENT ON TABLE public.spirit_readings IS
  'Server-Persist für Spirit-Tool-Ergebnisse (G1-G4).';
