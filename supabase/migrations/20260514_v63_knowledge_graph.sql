-- v63: Knowledge Graph — knowledge_nodes, knowledge_edges, user_node_progress
-- Idempotent (IF NOT EXISTS / ON CONFLICT DO NOTHING)

-- ── knowledge_nodes ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.knowledge_nodes (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          TEXT UNIQUE NOT NULL,
  title         TEXT NOT NULL,
  description   TEXT,
  world         TEXT NOT NULL CHECK (world IN ('ursprung','vorhang','energie','materie')),
  category      TEXT,
  icon          TEXT,
  level         INT DEFAULT 1 CHECK (level BETWEEN 1 AND 5),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── knowledge_edges ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.knowledge_edges (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id     UUID NOT NULL REFERENCES public.knowledge_nodes(id) ON DELETE CASCADE,
  target_id     UUID NOT NULL REFERENCES public.knowledge_nodes(id) ON DELETE CASCADE,
  relation      TEXT NOT NULL CHECK (relation IN ('basiert_auf','enthält','führt_zu','ähnlich','widerspricht')),
  strength      FLOAT DEFAULT 1.0 CHECK (strength BETWEEN 0.1 AND 3.0),
  UNIQUE (source_id, target_id)
);

-- ── user_node_progress ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_node_progress (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  node_id       UUID NOT NULL REFERENCES public.knowledge_nodes(id) ON DELETE CASCADE,
  discovered_at TIMESTAMPTZ DEFAULT NOW(),
  notes         TEXT,
  UNIQUE (user_id, node_id)
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_knowledge_nodes_world ON public.knowledge_nodes(world);
CREATE INDEX IF NOT EXISTS idx_knowledge_edges_source ON public.knowledge_edges(source_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_edges_target ON public.knowledge_edges(target_id);
CREATE INDEX IF NOT EXISTS idx_user_node_progress_user ON public.user_node_progress(user_id);

-- ── RLS ───────────────────────────────────────────────────────────────────────
ALTER TABLE public.knowledge_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_node_progress ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='knowledge_nodes' AND policyname='knowledge_nodes_read_all') THEN
    CREATE POLICY knowledge_nodes_read_all ON public.knowledge_nodes FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='knowledge_edges' AND policyname='knowledge_edges_read_all') THEN
    CREATE POLICY knowledge_edges_read_all ON public.knowledge_edges FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='user_node_progress' AND policyname='user_node_progress_own') THEN
    CREATE POLICY user_node_progress_own ON public.user_node_progress FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- ── Grants ────────────────────────────────────────────────────────────────────
GRANT SELECT ON public.knowledge_nodes TO anon, authenticated;
GRANT SELECT ON public.knowledge_edges TO anon, authenticated;
GRANT ALL ON public.user_node_progress TO authenticated;

-- ── Seed: knowledge_nodes (48 nodes) ─────────────────────────────────────────
INSERT INTO public.knowledge_nodes (slug, title, description, world, category, icon, level) VALUES
-- URSPRUNG
('ursprung_bewusstsein','Bewusstsein','Das primäre Feld aller Existenz jenseits von Raum und Zeit','ursprung','grundlage','🌌',1),
('ursprung_einheit','Einheit','Alle Dinge sind verbunden und entstammen einer Quelle','ursprung','grundlage','☯️',1),
('ursprung_schöpfung','Schöpfungsakt','Der Urimpuls der Existenz — Gedanke wird Wirklichkeit','ursprung','kosmologie','✨',2),
('ursprung_akasha','Akasha-Feld','Das universelle Gedächtnis — alle Ereignisse sind gespeichert','ursprung','kosmologie','📜',2),
('ursprung_logos','Logos','Das universelle Wort und Prinzip der göttlichen Ordnung','ursprung','philosophie','Ω',2),
('ursprung_pleroma','Pleroma','Die Fülle des Lichts im gnostischen Kosmos','ursprung','gnosis','💎',3),
('ursprung_metatron','Metatrons Würfel','Die heilige Geometrie als Blaupause der Schöpfung','ursprung','geometrie','🔮',3),
('ursprung_null','Nullpunkt','Der kosmische Nullpunktraum als Ursprung aller Energie','ursprung','physik','⚛️',4),
('ursprung_simulation','Simulationstheorie','Existenz als Informationsfeld — Realität als Code','ursprung','theorie','💻',4),
('ursprung_stille','Heilige Stille','Die schöpferische Stille vor dem Urknall','ursprung','meditation','🤍',3),
('ursprung_fraktal','Fraktale Realität','Das Große spiegelt das Kleine — As Above So Below','ursprung','geometrie','🌀',3),
('ursprung_zeit','Zeitlosigkeit','Vergangenheit, Gegenwart und Zukunft als simultanes Jetzt','ursprung','physik','⏳',4),
-- VORHANG
('vorhang_schleier','Der Schleier','Die Grenze zwischen sichtbarer und unsichtbarer Welt','vorhang','grenze','🌫️',1),
('vorhang_matrix','Matrix-Kontrolle','Systeme die menschliche Wahrnehmung und Freiheit einschränken','vorhang','system','🕸️',2),
('vorhang_propaganda','Medienpropaganda','Massenmedien als Werkzeug zur Bewusstseinsformung','vorhang','kontrolle','📺',2),
('vorhang_tiefer_staat','Tiefer Staat','Verborgene Machtstrukturen hinter politischen Systemen','vorhang','macht','🏛️',3),
('vorhang_mkultra','MK-Ultra','CIA-Bewusstseinskontrollprogramme — dokumentiert','vorhang','kontrolle','🔬',3),
('vorhang_nwo','Neue Weltordnung','Pläne für eine globale Einheitsregierung','vorhang','macht','🌐',3),
('vorhang_finanzsystem','Finanzsystem','Zentralbanken und Schuldgeld als Kontrollmechanismus','vorhang','system','💰',2),
('vorhang_überwachung','Überwachungsstaat','Totale digitale Überwachung und Social Scoring','vorhang','kontrolle','👁️',3),
('vorhang_freimaurerei','Freimaurerei','Geheimbünde und ihre Rolle in Weltgeschichte und -politik','vorhang','bund','🔺',3),
('vorhang_jesuiten','Jesuiten','Die Black Pope-Struktur und globaler Einfluss','vorhang','bund','✝️',3),
('vorhang_transhumanismus','Transhumanismus','Verschmelzung von Mensch und Maschine als Agenda','vorhang','agenda','🤖',4),
('vorhang_geoengineering','Geoengineering','Wettermanipulation und Chemtrails — Beweise und Theorie','vorhang','agenda','☁️',3),
-- ENERGIE
('energie_chakren','Chakren','Die 7 Energiezentren des menschlichen Feinkörpers','energie','körper','🌈',1),
('energie_aura','Aura','Das elektromagnetische Feld um jeden lebenden Organismus','energie','körper','✨',1),
('energie_meditation','Meditation','Die Praxis der inneren Stille und Bewusstseinserweiterung','energie','praxis','🧘',1),
('energie_kundalini','Kundalini','Die Schlangenkraft an der Wirbelsäulenbasis','energie','körper','🐍',2),
('energie_heilung','Energieheilung','Quantenheilung, Reiki und bioenergetische Medizin','energie','heilung','🌿',2),
('energie_kristalle','Kristallenergie','Edelsteine als energetische Verstärker und Heiler','energie','materie','💎',2),
('energie_astrologie','Astrologie','Planetare Einflüsse auf menschliches Schicksal','energie','kosmos','⭐',2),
('energie_mondrhythmen','Mondrhythmen','Lunare Zyklen und ihr Einfluss auf Natur und Psyche','energie','natur','🌙',2),
('energie_traumarbeit','Traumarbeit','Traumdeutung und Unterbewusstsein als Erkenntnisquelle','energie','psyche','💫',2),
('energie_numerologie','Numerologie','Die heilige Sprache der Zahlen und Schicksal','energie','symbol','🔢',2),
('energie_heilpflanzen','Heilpflanzen','Pflanzliche Alchemie und schamanische Medizin','energie','heilung','🌱',3),
('energie_schamanismus','Schamanismus','Reisen zwischen den Welten — Jäger des Lichts','energie','tradition','🦅',3),
-- MATERIE
('materie_geopolitik','Geopolitik','Machtspiele der Nationen auf dem weltpolitischen Schachbrett','materie','politik','🌍',1),
('materie_geschichte','Verborgene Geschichte','Umgeschriebene Geschichte und verlorenes Wissen','materie','wissen','📚',1),
('materie_ufos','UFOs & UAPs','Außerirdische Intelligenz und Regierungsvertuschungen','materie','kontakt','🛸',2),
('materie_tesla','Tesla & Freie Energie','Unterdrückte Technologien und Nullpunktenergie','materie','technologie','⚡',2),
('materie_archeologie','Verbotene Archäologie','Prähistorische Hochkulturen und ihre verschwundenen Technologien','materie','wissen','🏛️',3),
('materie_mond','Mondlüge','Anomalien der Mondlandung und Mondstruktur','materie','raumfahrt','🌕',3),
('materie_mrna','mRNA-Technologie','Gentechnische Eingriffe und das Immunsystem','materie','medizin','💉',3),
('materie_5g','5G & EMF','Elektromagnetische Strahlung und biologische Auswirkungen','materie','technologie','📡',3),
('materie_wasser','Wasserbewusstsein','Wassergedächtnis nach Emoto und lebendiges Wasser','materie','natur','💧',2),
('materie_food','Food System','Monsanto, GMO und die Vergiftung der Nahrungskette','materie','system','🌾',2),
('materie_tartaria','Tartaria','Die verschwundene Weltzivilisation und Mudflood-Reset','materie','geschichte','🗺️',4),
('materie_drachen','Draconische Linie','Reptiliane Einflüsse und die Blutlinie der Elite','materie','kontakt','🐉',5)
ON CONFLICT (slug) DO NOTHING;

-- ── Seed: knowledge_edges (52 edges) ─────────────────────────────────────────
INSERT INTO public.knowledge_edges (source_id, target_id, relation, strength)
SELECT s.id, t.id, rel, str
FROM (VALUES
  ('ursprung_bewusstsein','ursprung_einheit','basiert_auf',2.5),
  ('ursprung_einheit','ursprung_schöpfung','führt_zu',2.0),
  ('ursprung_schöpfung','ursprung_akasha','enthält',1.8),
  ('ursprung_logos','ursprung_schöpfung','basiert_auf',2.0),
  ('ursprung_metatron','ursprung_fraktal','enthält',2.2),
  ('ursprung_null','ursprung_bewusstsein','führt_zu',1.5),
  ('ursprung_fraktal','ursprung_akasha','ähnlich',1.3),
  ('ursprung_zeit','ursprung_bewusstsein','basiert_auf',1.5),
  ('ursprung_pleroma','ursprung_logos','basiert_auf',2.0),
  ('ursprung_simulation','ursprung_akasha','ähnlich',1.8),
  ('ursprung_bewusstsein','energie_meditation','führt_zu',2.0),
  ('ursprung_einheit','energie_chakren','basiert_auf',1.5),
  ('ursprung_akasha','materie_geschichte','enthält',1.3),
  ('ursprung_metatron','energie_kristalle','basiert_auf',1.5),
  ('ursprung_null','materie_tesla','ähnlich',2.0),
  ('ursprung_simulation','vorhang_matrix','ähnlich',2.5),
  ('vorhang_schleier','vorhang_matrix','führt_zu',2.5),
  ('vorhang_matrix','vorhang_propaganda','enthält',2.0),
  ('vorhang_matrix','vorhang_finanzsystem','enthält',2.0),
  ('vorhang_tiefer_staat','vorhang_mkultra','enthält',2.5),
  ('vorhang_tiefer_staat','vorhang_nwo','basiert_auf',2.0),
  ('vorhang_nwo','vorhang_transhumanismus','führt_zu',2.2),
  ('vorhang_überwachung','vorhang_matrix','basiert_auf',2.0),
  ('vorhang_freimaurerei','vorhang_tiefer_staat','basiert_auf',1.8),
  ('vorhang_jesuiten','vorhang_freimaurerei','ähnlich',1.5),
  ('vorhang_geoengineering','vorhang_tiefer_staat','basiert_auf',1.5),
  ('vorhang_propaganda','vorhang_überwachung','enthält',1.5),
  ('vorhang_matrix','materie_geopolitik','basiert_auf',1.8),
  ('vorhang_finanzsystem','materie_food','führt_zu',1.5),
  ('vorhang_transhumanismus','materie_mrna','enthält',2.0),
  ('vorhang_transhumanismus','materie_5g','enthält',1.8),
  ('vorhang_schleier','energie_aura','ähnlich',1.5),
  ('energie_chakren','energie_aura','enthält',2.0),
  ('energie_kundalini','energie_chakren','basiert_auf',2.5),
  ('energie_meditation','energie_chakren','führt_zu',2.0),
  ('energie_heilung','energie_chakren','basiert_auf',1.8),
  ('energie_kristalle','energie_heilung','basiert_auf',1.5),
  ('energie_astrologie','energie_mondrhythmen','enthält',1.8),
  ('energie_mondrhythmen','energie_traumarbeit','ähnlich',1.3),
  ('energie_schamanismus','energie_heilpflanzen','enthält',2.0),
  ('energie_schamanismus','energie_traumarbeit','basiert_auf',1.8),
  ('energie_numerologie','energie_astrologie','ähnlich',1.5),
  ('materie_geopolitik','materie_geschichte','basiert_auf',2.0),
  ('materie_ufos','materie_mond','basiert_auf',1.8),
  ('materie_tesla','materie_geopolitik','widerspricht',2.0),
  ('materie_archeologie','materie_tartaria','basiert_auf',2.2),
  ('materie_mrna','materie_food','ähnlich',1.5),
  ('materie_5g','materie_überwachung','ähnlich',1.5),
  ('materie_wasser','materie_food','ähnlich',1.3),
  ('materie_drachen','materie_geschichte','basiert_auf',1.5),
  ('energie_heilpflanzen','materie_food','widerspricht',1.8),
  ('energie_astrologie','materie_ufos','ähnlich',1.3)
) AS v(src, tgt, rel, str)
JOIN public.knowledge_nodes s ON s.slug = v.src
JOIN public.knowledge_nodes t ON t.slug = v.tgt
ON CONFLICT (source_id, target_id) DO NOTHING;
