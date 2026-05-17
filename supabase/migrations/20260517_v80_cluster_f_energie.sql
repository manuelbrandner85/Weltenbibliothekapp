-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v80 – Cluster F: Energie-Home-Erweiterungen
--
-- F1 daily_mantras: Pool für Tages-Zitate/Mantras
-- F3 user_power_spots: User-eigene Heilige-Orte / Power-Spots
-- ═══════════════════════════════════════════════════════════════

-- F1 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_mantras (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  text_de     text NOT NULL,
  author      text,
  tradition   text,                          -- z.B. 'buddhistisch', 'hermetisch'
  weight      smallint NOT NULL DEFAULT 1,   -- Häufigkeits-Gewicht
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.daily_mantras ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mantras_read ON public.daily_mantras;
CREATE POLICY mantras_read ON public.daily_mantras FOR SELECT USING (true);

-- Seed-Daten: 12 Klassiker. Idempotent via NOT EXISTS.
INSERT INTO public.daily_mantras (text_de, author, tradition)
SELECT * FROM (VALUES
  ('Wie oben, so unten. Wie innen, so außen.', 'Hermes Trismegistos', 'hermetisch'),
  ('Erkenne dich selbst.', 'Orakel von Delphi', 'antike'),
  ('Der Weg ist das Ziel.', 'Konfuzius', 'konfuzianisch'),
  ('Sei die Veränderung, die du in der Welt sehen willst.', 'Mahatma Gandhi', null),
  ('Das einzig Wahre ist die Liebe.', 'Buddha', 'buddhistisch'),
  ('Alles, was wir sind, ist das Ergebnis dessen, was wir gedacht haben.', 'Buddha', 'buddhistisch'),
  ('Was du nicht willst, das man dir tu, das füg auch keinem andern zu.', null, 'universal'),
  ('Stille ist die Sprache Gottes, alles andere ist schlechte Übersetzung.', 'Rumi', 'sufi'),
  ('Das Universum ist mental. Alles ist Geist.', 'Kybalion', 'hermetisch'),
  ('Wer im Außen sucht, träumt. Wer nach innen schaut, erwacht.', 'C.G. Jung', null),
  ('Atme tief. Du bist genau dort, wo du sein sollst.', null, 'modern'),
  ('Vertraue dem Prozess.', null, 'modern')
) AS v(text_de, author, tradition)
WHERE NOT EXISTS (SELECT 1 FROM public.daily_mantras WHERE daily_mantras.text_de = v.text_de);


-- F3 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_power_spots (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  username     text,
  name         text NOT NULL,
  latitude     double precision NOT NULL,
  longitude    double precision NOT NULL,
  description  text,
  energy_type  text,                         -- 'natur', 'heilig', 'kraftort', 'lei-linie', etc.
  is_public    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_power_spots_geo
  ON public.user_power_spots (latitude, longitude);

ALTER TABLE public.user_power_spots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS power_spots_read ON public.user_power_spots;
CREATE POLICY power_spots_read ON public.user_power_spots
  FOR SELECT USING (is_public = true);
DROP POLICY IF EXISTS power_spots_write ON public.user_power_spots;
CREATE POLICY power_spots_write ON public.user_power_spots
  FOR ALL USING (true) WITH CHECK (true);

-- Seed: 8 bekannte Power-Spots
INSERT INTO public.user_power_spots (user_id, username, name, latitude, longitude, description, energy_type, is_public)
SELECT * FROM (VALUES
  ('system', 'system', 'Stonehenge', 51.1789::double precision, -1.8262::double precision, 'Megalithischer Steinkreis, Wiltshire', 'heilig', true),
  ('system', 'system', 'Sedona Vortex', 34.8697::double precision, -111.7610::double precision, 'Energetische Wirbel-Zone', 'kraftort', true),
  ('system', 'system', 'Mount Shasta', 41.4099::double precision, -122.1949::double precision, 'Heiliger Berg, Kalifornien', 'kraftort', true),
  ('system', 'system', 'Machu Picchu', -13.1631::double precision, -72.5450::double precision, 'Inka-Stätte, Peru', 'heilig', true),
  ('system', 'system', 'Externsteine', 51.8689::double precision, 8.9152::double precision, 'Sandstein-Formation, Teutoburger Wald', 'kraftort', true),
  ('system', 'system', 'Glastonbury Tor', 51.1448::double precision, -2.6986::double precision, 'Avalon-Hügel, Somerset', 'heilig', true),
  ('system', 'system', 'Uluru', -25.3444::double precision, 131.0369::double precision, 'Heiliger Berg der Anangu', 'heilig', true),
  ('system', 'system', 'Externsteine-Linie', 50.0::double precision, 9.0::double precision, 'Lei-Linie durch Deutschland', 'lei-linie', true)
) AS v(user_id, username, name, latitude, longitude, description, energy_type, is_public)
WHERE NOT EXISTS (
  SELECT 1 FROM public.user_power_spots
  WHERE user_power_spots.user_id = 'system' AND user_power_spots.name = v.name
);

COMMENT ON TABLE public.daily_mantras IS 'Pool für Tages-Mantras/Zitate (F1).';
COMMENT ON TABLE public.user_power_spots IS 'User-eigene + system Power-Spots (F3).';
