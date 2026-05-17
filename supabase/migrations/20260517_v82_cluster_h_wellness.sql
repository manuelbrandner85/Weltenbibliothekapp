-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v82 – Cluster H: Wellness-Features
--
-- H1 meditation_presets: Guided-Session-Vorlagen
-- H2 frequency_presets: Solfeggio/Schumann/Brainwave-Presets + User-Custom
-- ═══════════════════════════════════════════════════════════════

-- H1 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.meditation_presets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title        text NOT NULL,
  description  text,
  duration_min smallint NOT NULL,            -- 5/10/20
  voice_prompts jsonb NOT NULL,              -- [{at_sec, text}]
  category     text DEFAULT 'general',       -- 'breath' | 'body' | 'mantra' | 'chakra'
  is_system    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.meditation_presets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS med_presets_read ON public.meditation_presets;
CREATE POLICY med_presets_read ON public.meditation_presets FOR SELECT USING (true);

-- Seed: 3 Klassiker — 5/10/20 Min mit Atem-Prompts
INSERT INTO public.meditation_presets (title, description, duration_min, voice_prompts, category, is_system)
SELECT * FROM (VALUES
  ('5-Minuten Atem-Reset', 'Schnelle Box-Breathing-Session', 5::smallint,
   '[
     {"at_sec": 0,  "text": "Atme tief ein, durch die Nase."},
     {"at_sec": 30, "text": "Halte den Atem. 4 Sekunden."},
     {"at_sec": 60, "text": "Atme langsam aus, durch den Mund."},
     {"at_sec": 120,"text": "Du bist hier. Du bist sicher."},
     {"at_sec": 180,"text": "Spür deinen Körper, von Kopf bis Fuß."},
     {"at_sec": 240,"text": "Noch eine Minute. Bleib bei deinem Atem."},
     {"at_sec": 300,"text": "Komm langsam zurück. Öffne die Augen."}
   ]'::jsonb,
   'breath', true),
  ('10-Minuten Körper-Scan', 'Body-Scan von oben nach unten', 10::smallint,
   '[
     {"at_sec": 0,   "text": "Setz dich bequem hin. Schließe die Augen."},
     {"at_sec": 60,  "text": "Spür deinen Kopf. Lass ihn schwer werden."},
     {"at_sec": 180, "text": "Schultern. Lass los, was du nicht brauchst."},
     {"at_sec": 300, "text": "Brust und Bauch. Atme in den Bauch hinein."},
     {"at_sec": 420, "text": "Becken und Beine. Erde dich."},
     {"at_sec": 540, "text": "Füße. Spür den Boden unter dir."},
     {"at_sec": 600, "text": "Komm sanft zurück."}
   ]'::jsonb,
   'body', true),
  ('20-Minuten Tiefen-Meditation', 'Mantra-basiert, lange Stille', 20::smallint,
   '[
     {"at_sec": 0,    "text": "Wähle ein inneres Wort. So ham. Oder einfach: ich bin."},
     {"at_sec": 120,  "text": "Wiederhole es im Geist. Sanft."},
     {"at_sec": 300,  "text": "Gedanken kommen. Lass sie ziehen."},
     {"at_sec": 600,  "text": "Du bist mehr als deine Gedanken."},
     {"at_sec": 900,  "text": "Halbzeit. Bleib bei deinem Wort."},
     {"at_sec": 1080, "text": "Spür die Stille zwischen den Worten."},
     {"at_sec": 1200, "text": "Komm sanft zurück. Bewege Finger und Zehen."}
   ]'::jsonb,
   'mantra', true)
) AS v(title, description, duration_min, voice_prompts, category, is_system)
WHERE NOT EXISTS (
  SELECT 1 FROM public.meditation_presets WHERE meditation_presets.title = v.title
);


-- H2 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.frequency_presets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL DEFAULT 'system',
  username     text,
  title        text NOT NULL,
  hz           numeric(8,3) NOT NULL,
  description  text,
  category     text DEFAULT 'solfeggio',     -- 'solfeggio'|'schumann'|'brainwave'|'custom'
  is_system    boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_freq_presets_category
  ON public.frequency_presets (category, is_system);
CREATE INDEX IF NOT EXISTS idx_freq_presets_user
  ON public.frequency_presets (user_id, created_at DESC);

ALTER TABLE public.frequency_presets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS freq_read ON public.frequency_presets;
CREATE POLICY freq_read ON public.frequency_presets FOR SELECT USING (true);
DROP POLICY IF EXISTS freq_write ON public.frequency_presets;
CREATE POLICY freq_write ON public.frequency_presets
  FOR ALL USING (true) WITH CHECK (true);

-- Seed: Klassische Frequenzen
INSERT INTO public.frequency_presets (user_id, title, hz, description, category, is_system)
SELECT * FROM (VALUES
  ('system', 'Solfeggio 396 Hz', 396.0, 'Befreiung von Furcht und Schuld', 'solfeggio', true),
  ('system', 'Solfeggio 417 Hz', 417.0, 'Wandel und Veränderung', 'solfeggio', true),
  ('system', 'Solfeggio 528 Hz', 528.0, 'Liebe und DNA-Heilung', 'solfeggio', true),
  ('system', 'Solfeggio 639 Hz', 639.0, 'Beziehungen und Verbindung', 'solfeggio', true),
  ('system', 'Solfeggio 741 Hz', 741.0, 'Intuition und Ausdruck', 'solfeggio', true),
  ('system', 'Solfeggio 852 Hz', 852.0, 'Spirituelle Ordnung', 'solfeggio', true),
  ('system', 'Solfeggio 963 Hz', 963.0, 'Göttliches Bewusstsein', 'solfeggio', true),
  ('system', 'Schumann 7.83 Hz', 7.83, 'Erd-Resonanz, Grundton', 'schumann', true),
  ('system', 'Alpha 10 Hz', 10.0, 'Entspannte Wachheit', 'brainwave', true),
  ('system', 'Theta 6 Hz', 6.0, 'Tiefe Meditation, Traumzustand', 'brainwave', true),
  ('system', 'Delta 2 Hz', 2.0, 'Tiefschlaf, Regeneration', 'brainwave', true),
  ('system', 'Gamma 40 Hz', 40.0, 'Hohe Konzentration, Flow', 'brainwave', true)
) AS v(user_id, title, hz, description, category, is_system)
WHERE NOT EXISTS (
  SELECT 1 FROM public.frequency_presets
  WHERE frequency_presets.user_id = 'system' AND frequency_presets.title = v.title
);

COMMENT ON TABLE public.meditation_presets IS 'Geführte Meditationen mit Voice-Prompts (H1).';
COMMENT ON TABLE public.frequency_presets IS 'Solfeggio/Schumann/Brainwave + User-Custom (H2).';
