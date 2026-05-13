-- ══════════════════════════════════════════════════════════════════════════════
-- v63 — KNOWLEDGE GRAPH
-- Interaktiver Wissensgraph: Knoten + Kanten für alle 4 Welten
-- Welten: materie, energie, vorhang, ursprung
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. KNOWLEDGE_GRAPH_NODES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.knowledge_graph_nodes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world       TEXT NOT NULL CHECK (world IN ('materie', 'energie', 'vorhang', 'ursprung', 'universal')),
  label       TEXT NOT NULL,
  description TEXT,
  node_type   TEXT NOT NULL DEFAULT 'concept'
              CHECK (node_type IN ('concept', 'person', 'event', 'place', 'artifact', 'theory')),
  tags        TEXT[] NOT NULL DEFAULT '{}',
  source_url  TEXT,
  icon_emoji  TEXT NOT NULL DEFAULT '🔵',
  color_hex   TEXT NOT NULL DEFAULT '#4A90D9',
  weight      INT  NOT NULL DEFAULT 1 CHECK (weight BETWEEN 1 AND 10),
  created_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_kg_nodes_world  ON public.knowledge_graph_nodes (world);
CREATE INDEX IF NOT EXISTS idx_kg_nodes_type   ON public.knowledge_graph_nodes (node_type);
CREATE INDEX IF NOT EXISTS idx_kg_nodes_user   ON public.knowledge_graph_nodes (created_by);
CREATE INDEX IF NOT EXISTS idx_kg_nodes_label  ON public.knowledge_graph_nodes USING GIN (to_tsvector('simple', label));

-- ── 2. KNOWLEDGE_GRAPH_EDGES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.knowledge_graph_edges (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_id    UUID NOT NULL REFERENCES public.knowledge_graph_nodes(id) ON DELETE CASCADE,
  target_id    UUID NOT NULL REFERENCES public.knowledge_graph_nodes(id) ON DELETE CASCADE,
  relation     TEXT NOT NULL DEFAULT 'related'
               CHECK (relation IN ('related', 'causes', 'contradicts', 'supports', 'part_of', 'influenced_by', 'connected_to')),
  strength     INT  NOT NULL DEFAULT 5 CHECK (strength BETWEEN 1 AND 10),
  description  TEXT,
  created_by   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source_id, target_id, relation)
);

CREATE INDEX IF NOT EXISTS idx_kg_edges_source ON public.knowledge_graph_edges (source_id);
CREATE INDEX IF NOT EXISTS idx_kg_edges_target ON public.knowledge_graph_edges (target_id);

-- ── 3. USER_GRAPH_BOOKMARKS ─────────────────────────────────────────────────
-- User können Knoten bookmarken / zu eigenen Sammlungen hinzufügen
CREATE TABLE IF NOT EXISTS public.user_graph_bookmarks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  node_id    UUID NOT NULL REFERENCES public.knowledge_graph_nodes(id) ON DELETE CASCADE,
  note       TEXT,
  saved_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, node_id)
);

CREATE INDEX IF NOT EXISTS idx_graph_bookmarks_user ON public.user_graph_bookmarks (user_id);
CREATE INDEX IF NOT EXISTS idx_graph_bookmarks_node ON public.user_graph_bookmarks (node_id);

-- ── UPDATED_AT TRIGGER ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_kg_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_kg_nodes_updated_at ON public.knowledge_graph_nodes;
CREATE TRIGGER trg_kg_nodes_updated_at
  BEFORE UPDATE ON public.knowledge_graph_nodes
  FOR EACH ROW EXECUTE FUNCTION public.set_kg_updated_at();

-- ── RLS POLICIES ────────────────────────────────────────────────────────────

-- knowledge_graph_nodes: öffentlich lesbar, Auth-User dürfen eigene Knoten schreiben
ALTER TABLE public.knowledge_graph_nodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kg_nodes_select_all"    ON public.knowledge_graph_nodes;
DROP POLICY IF EXISTS "kg_nodes_insert_auth"   ON public.knowledge_graph_nodes;
DROP POLICY IF EXISTS "kg_nodes_update_own"    ON public.knowledge_graph_nodes;
DROP POLICY IF EXISTS "kg_nodes_delete_own"    ON public.knowledge_graph_nodes;

CREATE POLICY "kg_nodes_select_all"  ON public.knowledge_graph_nodes FOR SELECT USING (true);
CREATE POLICY "kg_nodes_insert_auth" ON public.knowledge_graph_nodes FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "kg_nodes_update_own"  ON public.knowledge_graph_nodes FOR UPDATE
  USING (auth.uid() = created_by);
CREATE POLICY "kg_nodes_delete_own"  ON public.knowledge_graph_nodes FOR DELETE
  USING (auth.uid() = created_by);

-- knowledge_graph_edges: öffentlich lesbar, Auth-User dürfen eigene Kanten schreiben
ALTER TABLE public.knowledge_graph_edges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "kg_edges_select_all"    ON public.knowledge_graph_edges;
DROP POLICY IF EXISTS "kg_edges_insert_auth"   ON public.knowledge_graph_edges;
DROP POLICY IF EXISTS "kg_edges_delete_own"    ON public.knowledge_graph_edges;

CREATE POLICY "kg_edges_select_all"  ON public.knowledge_graph_edges FOR SELECT USING (true);
CREATE POLICY "kg_edges_insert_auth" ON public.knowledge_graph_edges FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "kg_edges_delete_own"  ON public.knowledge_graph_edges FOR DELETE
  USING (auth.uid() = created_by);

-- user_graph_bookmarks: nur eigene Zeilen sichtbar
ALTER TABLE public.user_graph_bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "graph_bookmarks_own"    ON public.user_graph_bookmarks;
DROP POLICY IF EXISTS "graph_bookmarks_insert" ON public.user_graph_bookmarks;
DROP POLICY IF EXISTS "graph_bookmarks_delete" ON public.user_graph_bookmarks;

CREATE POLICY "graph_bookmarks_own"    ON public.user_graph_bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "graph_bookmarks_insert" ON public.user_graph_bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "graph_bookmarks_delete" ON public.user_graph_bookmarks FOR DELETE USING (auth.uid() = user_id);

-- ── REALTIME PUBLICATION ────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'knowledge_graph_nodes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.knowledge_graph_nodes;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'knowledge_graph_edges'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.knowledge_graph_edges;
  END IF;
END $$;

-- ── GRANTS ──────────────────────────────────────────────────────────────────
GRANT SELECT ON public.knowledge_graph_nodes    TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.knowledge_graph_nodes TO authenticated;
GRANT SELECT ON public.knowledge_graph_edges    TO anon, authenticated;
GRANT INSERT, DELETE ON public.knowledge_graph_edges TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.user_graph_bookmarks TO authenticated;

-- ── SEED DATA — Starter-Knoten für alle 4 Welten ───────────────────────────
INSERT INTO public.knowledge_graph_nodes
  (world, label, description, node_type, tags, icon_emoji, color_hex, weight)
VALUES
  -- Materie
  ('materie', 'Bilderberg-Gruppe',   'Jährliches Treffen westlicher Eliten seit 1954',           'event',   ARRAY['geopolitik','eliten'],     '🏛️', '#E53935', 8),
  ('materie', 'Petrodollar',         'US-Dollar als globale Öl-Währung seit 1971',                'concept', ARRAY['finanzen','geopolitik'],   '💵', '#E53935', 7),
  ('materie', 'Operation Gladio',    'NATO Stay-Behind-Netzwerk im Kalten Krieg',                 'event',   ARRAY['cia','nato'],               '🕵️', '#C62828', 9),
  ('materie', 'MK Ultra',            'CIA-Gedankenkontroll-Programm 1953–1973',                   'event',   ARRAY['cia','experimente'],        '🧠', '#B71C1C', 9),
  ('materie', 'Federal Reserve',     'Private US-Zentralbank gegründet 1913',                     'concept', ARRAY['finanzen','kontrolle'],     '🏦', '#E53935', 8),
  -- Energie
  ('energie', 'Akasha',              'Universelles Informationsfeld im vedischen Weltbild',       'concept', ARRAY['spiritualität','bewusstsein'],'✨','#7C4DFF', 9),
  ('energie', 'Torsionsfeld',        'Hypothetisches Wirbelfeld als Bewusstseinsträger',           'theory',  ARRAY['physik','bewusstsein'],     '🌀', '#651FFF', 7),
  ('energie', 'Hundertste Affe',     'Morphisches Resonanz-Phänomen nach Sheldrake',              'theory',  ARRAY['morphisches_feld'],         '🐒', '#7C4DFF', 6),
  ('energie', 'Chakren-System',      '7 Energiezentren im yogischen Körperbild',                  'concept', ARRAY['chakren','yoga'],           '🌈', '#7C4DFF', 8),
  ('energie', 'Skalarwellen',        'Longitudinalwellen jenseits Maxwell-Gleichungen',            'theory',  ARRAY['tesla','energie'],          '⚡', '#9C27B0', 7),
  -- Vorhang
  ('vorhang', 'Hermetik',            '7 hermetische Prinzipien — "Wie oben, so unten"',           'concept', ARRAY['esoterik','philosophie'],   '📜', '#C9A84C', 9),
  ('vorhang', 'Geheimbünde',         'Freimaurer, Rosenkreuzer & Co. — Struktur und Ziele',       'concept', ARRAY['freimaurer','macht'],       '🔑', '#B8860B', 8),
  ('vorhang', 'Synarchie',           'Herrschaft durch geheime Elitengruppen',                    'theory',  ARRAY['macht','kontrolle'],        '👁️', '#C9A84C', 7),
  -- Ursprung
  ('ursprung', 'Veda-Kosmologie',    'Zyklisches Weltbild der Yugas (4 Zeitalter)',               'concept', ARRAY['hinduismus','kosmologie'],  '🌍', '#00D4AA', 9),
  ('ursprung', 'Dreamtime',          'Australische Ureinwohner-Schöpfungskosmologie',             'concept', ARRAY['naturvölker','ursprung'],   '🌙', '#00BCD4', 8),
  ('ursprung', 'Dogon-Astronomie',   'Sirius-B-Wissen der Dogon 3000 Jahre vor Entdeckung',      'event',   ARRAY['astronomie','naturvölker'], '⭐', '#00D4AA', 9)
ON CONFLICT DO NOTHING;

-- Kanten zwischen Starter-Knoten (materie)
WITH n AS (
  SELECT id, label FROM public.knowledge_graph_nodes WHERE world = 'materie'
)
INSERT INTO public.knowledge_graph_edges (source_id, target_id, relation, strength)
SELECT a.id, b.id, 'related', 7
FROM n a, n b
WHERE a.label = 'Bilderberg-Gruppe' AND b.label = 'Federal Reserve'
ON CONFLICT DO NOTHING;

WITH n AS (
  SELECT id, label FROM public.knowledge_graph_nodes WHERE world = 'materie'
)
INSERT INTO public.knowledge_graph_edges (source_id, target_id, relation, strength)
SELECT a.id, b.id, 'related', 8
FROM n a, n b
WHERE a.label = 'Operation Gladio' AND b.label = 'MK Ultra'
ON CONFLICT DO NOTHING;

-- Kanten (energie)
WITH n AS (
  SELECT id, label FROM public.knowledge_graph_nodes WHERE world = 'energie'
)
INSERT INTO public.knowledge_graph_edges (source_id, target_id, relation, strength)
SELECT a.id, b.id, 'related', 9
FROM n a, n b
WHERE a.label = 'Akasha' AND b.label = 'Torsionsfeld'
ON CONFLICT DO NOTHING;

WITH n AS (
  SELECT id, label FROM public.knowledge_graph_nodes WHERE world = 'energie'
)
INSERT INTO public.knowledge_graph_edges (source_id, target_id, relation, strength)
SELECT a.id, b.id, 'influenced_by', 6
FROM n a, n b
WHERE a.label = 'Torsionsfeld' AND b.label = 'Skalarwellen'
ON CONFLICT DO NOTHING;
