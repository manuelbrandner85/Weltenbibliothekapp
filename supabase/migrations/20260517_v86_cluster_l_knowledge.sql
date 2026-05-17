-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v86 – Cluster L: Mentor / Knowledge
--
-- L3 user_annotations:        Highlights + Notizen in Knowledge-Reader
-- L5 bookmark_collections:    Ordner-Struktur für Bookmarks
-- L6 biometric_data_sync:     Cached Health/Fit-Daten pro User
-- ═══════════════════════════════════════════════════════════════

-- L3 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_annotations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       text NOT NULL,
  resource_type text NOT NULL,            -- 'article' | 'module' | 'book'
  resource_id   text NOT NULL,
  highlight     text NOT NULL,            -- markierter Original-Text
  note          text,                     -- User-Kommentar
  color         text NOT NULL DEFAULT 'yellow',
  position      jsonb,                    -- { offset_start, offset_end }
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_annot_user_resource
  ON public.user_annotations (user_id, resource_type, resource_id);

ALTER TABLE public.user_annotations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ann_own ON public.user_annotations;
CREATE POLICY ann_own ON public.user_annotations
  FOR ALL USING (true) WITH CHECK (true);

-- L5 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bookmark_collections (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  name         text NOT NULL,
  icon         text,
  color        text,
  order_idx    smallint NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, name)
);

CREATE INDEX IF NOT EXISTS idx_bookmark_coll_user
  ON public.bookmark_collections (user_id, order_idx);

ALTER TABLE public.bookmark_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS coll_own ON public.bookmark_collections;
CREATE POLICY coll_own ON public.bookmark_collections
  FOR ALL USING (true) WITH CHECK (true);

CREATE TABLE IF NOT EXISTS public.bookmark_collection_items (
  collection_id uuid REFERENCES public.bookmark_collections(id) ON DELETE CASCADE,
  bookmark_id   text NOT NULL,
  added_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (collection_id, bookmark_id)
);

ALTER TABLE public.bookmark_collection_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS coll_items_all ON public.bookmark_collection_items;
CREATE POLICY coll_items_all ON public.bookmark_collection_items
  FOR ALL USING (true) WITH CHECK (true);

-- L6 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.biometric_data_cache (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      text NOT NULL,
  metric       text NOT NULL,            -- 'heart_rate' | 'hrv' | 'sleep_score' | 'steps'
  value        numeric(8,2) NOT NULL,
  unit         text NOT NULL,            -- 'bpm' | 'ms' | 'score' | 'count'
  source       text,                      -- 'healthkit' | 'google_fit' | 'manual'
  measured_at  timestamptz NOT NULL,
  synced_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bio_user_metric_time
  ON public.biometric_data_cache (user_id, metric, measured_at DESC);

ALTER TABLE public.biometric_data_cache ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bio_own ON public.biometric_data_cache;
CREATE POLICY bio_own ON public.biometric_data_cache
  FOR ALL USING (true) WITH CHECK (true);

COMMENT ON TABLE public.user_annotations IS 'Highlights + Notizen im Reader (L3).';
COMMENT ON TABLE public.bookmark_collections IS 'Ordner-Struktur für Bookmarks (L5).';
COMMENT ON TABLE public.biometric_data_cache IS 'Cached Health/Fit-Werte (L6).';
