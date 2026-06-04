-- v122: Erweiterung 2 "Vier Linsen" -- welt-uebergreifende Querverbindungen.
-- Ein Thema, durch die Brille aller vier Welten betrachtet.
-- Gleiche RLS-Logik wie v120/v121: oeffentlich lesbar, Schreiben content_editor+.

CREATE TABLE IF NOT EXISTS public.cross_world_topics (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT UNIQUE NOT NULL,
  title         TEXT NOT NULL,
  subtitle      TEXT,
  emoji         TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  -- Die vier Linsen: je Welt eine Perspektive auf dasselbe Thema.
  materie_ref   TEXT,
  energie_ref   TEXT,
  vorhang_ref   TEXT,
  ursprung_ref  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cross_world_topics_order
  ON public.cross_world_topics (sort_order);

GRANT SELECT ON TABLE public.cross_world_topics TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.cross_world_topics TO authenticated;

ALTER TABLE public.cross_world_topics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cross_world_topics_public_select ON public.cross_world_topics;
CREATE POLICY cross_world_topics_public_select ON public.cross_world_topics
  FOR SELECT USING (true);

DROP POLICY IF EXISTS cross_world_topics_editor_insert ON public.cross_world_topics;
CREATE POLICY cross_world_topics_editor_insert ON public.cross_world_topics
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')));

DROP POLICY IF EXISTS cross_world_topics_editor_update ON public.cross_world_topics;
CREATE POLICY cross_world_topics_editor_update ON public.cross_world_topics
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')));

DROP POLICY IF EXISTS cross_world_topics_editor_delete ON public.cross_world_topics;
CREATE POLICY cross_world_topics_editor_delete ON public.cross_world_topics
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'content_editor')));

-- Seed: das Mond-Beispiel aus der Spezifikation + weitere universelle Themen.
INSERT INTO public.cross_world_topics
  (slug, title, subtitle, emoji, sort_order, materie_ref, energie_ref, vorhang_ref, ursprung_ref)
VALUES
  ('mond', 'Der Mond', 'Ein Himmelskoerper -- vier Perspektiven', '🌙', 10,
   'Apollo-Missionen und offene Fragen zur Mondlandung.',
   'Mondkalender, Mondphasen und ihr Einfluss auf Rhythmen.',
   'Verborgene Mond-Symbolik in Logos, Wappen und Kulten.',
   'Schoepfungsmythen: der Mond als Urgottheit und Zeitgeber.'),
  ('pyramide', 'Die Pyramide', 'Bauwerk, Symbol und Raetsel', '🔺', 20,
   'Ingenieurskunst, Vermessung und Bautechnik der Pyramiden.',
   'Pyramidenenergie, Geometrie und Resonanz-Vorstellungen.',
   'Pyramide mit Auge: Macht-Symbolik bis zur Dollarnote.',
   'Pyramiden weltweit als Spur fruehester Hochkulturen.'),
  ('schlange', 'Die Schlange', 'Vom Tier zum Urymbol', '🐍', 30,
   'Biologie, Gift und reale Gefahr -- und ihre Mythologisierung.',
   'Kundalini: die Schlangenkraft entlang der Wirbelsaeule.',
   'Schlange als Symbol von Wissen, Versuchung und Eliten.',
   'Weltenschlange und Ouroboros in Schoepfungsmythen.'),
  ('wasser', 'Das Wasser', 'Ursprung und Traeger des Lebens', '💧', 40,
   'Hydrologie, Trinkwasser und geopolitische Wasserkonflikte.',
   'Wasser als Informationstraeger und Reinigungselement.',
   'Kontrolle ueber Wasser als verborgenes Macht-Instrument.',
   'Urozean und Schoepfung aus dem Wasser in vielen Kulturen.'),
  ('sonne', 'Die Sonne', 'Licht, Macht und Verehrung', '☀️', 50,
   'Astrophysik der Sonne und ihr Einfluss aufs Klima.',
   'Sonnenenergie, Lichtmeditation und Solarplexus-Chakra.',
   'Sonnenkulte und Sonnensymbolik in Herrschaftsritualen.',
   'Sonnengottheiten (Ra, Helios) als fruehe Schoepferkraefte.'),
  ('tod-wiedergeburt', 'Tod & Wiedergeburt', 'Das groesste Mysterium', '♾️', 60,
   'Biologischer Tod, Nahtod-Forschung und ihre Deutung.',
   'Reinkarnation, Seelenreise und Bewusstsein nach dem Tod.',
   'Mysterienkulte und verborgenes Wissen ueber den Uebergang.',
   'Jenseits- und Wiedergeburtsmythen der Urkulturen.')
ON CONFLICT (slug) DO NOTHING;
