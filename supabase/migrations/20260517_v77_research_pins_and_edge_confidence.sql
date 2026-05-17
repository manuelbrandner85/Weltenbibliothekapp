-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v77 – User-Research-Pins (B2) + Edge-Confidence (B4)
--
-- B2: user_research_pins — User-erstellte Map-Marker mit Up/Downvote
-- B4: user_edge_confidence — pro Verbindung im Conspiracy-Network
--     speichert User ein Confidence-Rating (1-5).
-- ═══════════════════════════════════════════════════════════════

-- ── B2 ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_research_pins (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,           -- InvisibleAuth id ODER Supabase uuid
  username     text,                    -- best-effort
  world        text NOT NULL,           -- materie/energie/vorhang/ursprung
  latitude     double precision NOT NULL,
  longitude    double precision NOT NULL,
  title        text NOT NULL,
  description  text,
  upvotes      int  NOT NULL DEFAULT 0,
  downvotes    int  NOT NULL DEFAULT 0,
  is_archived  boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pins_world_time
  ON public.user_research_pins (world, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pins_geo
  ON public.user_research_pins (latitude, longitude);

ALTER TABLE public.user_research_pins ENABLE ROW LEVEL SECURITY;

-- Lese: alle non-archived. Schreibt: alle (Auth-Refactor folgt noch).
DROP POLICY IF EXISTS pins_read ON public.user_research_pins;
CREATE POLICY pins_read ON public.user_research_pins
  FOR SELECT USING (is_archived = false);

DROP POLICY IF EXISTS pins_insert ON public.user_research_pins;
CREATE POLICY pins_insert ON public.user_research_pins
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS pins_update_own ON public.user_research_pins;
CREATE POLICY pins_update_own ON public.user_research_pins
  FOR UPDATE USING (true) WITH CHECK (true);

-- Upvote/Downvote-Tracking pro User pro Pin (kein Doppel-Voting).
CREATE TABLE IF NOT EXISTS public.user_research_pin_votes (
  pin_id    uuid REFERENCES public.user_research_pins(id) ON DELETE CASCADE,
  user_id   text NOT NULL,
  vote      smallint NOT NULL,  -- +1 oder -1
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (pin_id, user_id)
);

ALTER TABLE public.user_research_pin_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pin_votes_all ON public.user_research_pin_votes;
CREATE POLICY pin_votes_all ON public.user_research_pin_votes
  FOR ALL USING (true) WITH CHECK (true);


-- ── B4 ────────────────────────────────────────────────────────
-- Conspiracy-Network speichert keine Edges in DB (sind frontend-statisch);
-- wir taggen Edges by `node_a` + `node_b` (alphabetisch sortiert).
CREATE TABLE IF NOT EXISTS public.user_edge_confidence (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  world        text NOT NULL DEFAULT 'materie',
  node_a       text NOT NULL,
  node_b       text NOT NULL,
  rating       smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, world, node_a, node_b)
);

CREATE INDEX IF NOT EXISTS idx_edge_conf_edge
  ON public.user_edge_confidence (world, node_a, node_b);

ALTER TABLE public.user_edge_confidence ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS edge_conf_read ON public.user_edge_confidence;
CREATE POLICY edge_conf_read ON public.user_edge_confidence
  FOR SELECT USING (true);

DROP POLICY IF EXISTS edge_conf_write_own ON public.user_edge_confidence;
CREATE POLICY edge_conf_write_own ON public.user_edge_confidence
  FOR ALL USING (true) WITH CHECK (true);


-- ── Aggregat-Views (für Community-Consensus) ─────────────────
CREATE OR REPLACE VIEW public.edge_confidence_aggregate AS
SELECT
  world,
  node_a,
  node_b,
  count(*)::int as vote_count,
  round(avg(rating)::numeric, 2) as avg_rating
FROM public.user_edge_confidence
GROUP BY world, node_a, node_b;

COMMENT ON TABLE public.user_research_pins IS
  'User-erstellte Recherche-Pins auf der Welt-Karte (B2).';
COMMENT ON TABLE public.user_edge_confidence IS
  'Pro User Confidence-Rating (1-5) für Verbindungen im Conspiracy-Network (B4).';
