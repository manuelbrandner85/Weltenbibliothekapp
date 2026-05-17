-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v78 – Cluster C: Research-Tools-Erweiterungen
--
-- C2 shared_investigations: Kollaborative Kaninchenbau-Investigations
-- C3 propaganda_bias_history: Trend-Chart pro geprüfter Quelle
-- C4 research_smart_tags: Cache für AI-vorgeschlagene Tags
-- ═══════════════════════════════════════════════════════════════

-- C2 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.shared_investigations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  share_token   text UNIQUE NOT NULL,        -- kurzer URL-safe Token
  owner_user_id text NOT NULL,
  owner_username text,
  title         text NOT NULL,
  topic         text NOT NULL,
  payload       jsonb NOT NULL,              -- Komplette Investigation-State
  is_public     boolean NOT NULL DEFAULT false,
  view_count    int NOT NULL DEFAULT 0,
  contributors  text[] NOT NULL DEFAULT '{}',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_shared_inv_token
  ON public.shared_investigations (share_token);
CREATE INDEX IF NOT EXISTS idx_shared_inv_owner
  ON public.shared_investigations (owner_user_id, created_at DESC);

ALTER TABLE public.shared_investigations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS shared_inv_read ON public.shared_investigations;
CREATE POLICY shared_inv_read ON public.shared_investigations
  FOR SELECT USING (is_public = true);

DROP POLICY IF EXISTS shared_inv_write ON public.shared_investigations;
CREATE POLICY shared_inv_write ON public.shared_investigations
  FOR ALL USING (true) WITH CHECK (true);


-- C3 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.propaganda_bias_history (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_domain text NOT NULL,
  bias_score    numeric(3,2) NOT NULL,     -- -1.0 (links) bis +1.0 (rechts) o.ä.
  reliability   numeric(3,2),               -- 0.0 - 1.0
  user_id       text,
  details       jsonb DEFAULT '{}'::jsonb,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bias_history_domain_time
  ON public.propaganda_bias_history (source_domain, created_at DESC);

ALTER TABLE public.propaganda_bias_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS bias_hist_all ON public.propaganda_bias_history;
CREATE POLICY bias_hist_all ON public.propaganda_bias_history
  FOR ALL USING (true) WITH CHECK (true);


-- C4 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.research_smart_tags (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  archive_id    text NOT NULL,              -- Referenz auf research_archive Eintrag
  tag           text NOT NULL,
  source        text NOT NULL DEFAULT 'ai', -- 'ai' | 'user'
  confidence    numeric(3,2),               -- nur bei AI
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (archive_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_smart_tags_archive
  ON public.research_smart_tags (archive_id);

ALTER TABLE public.research_smart_tags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS smart_tags_all ON public.research_smart_tags;
CREATE POLICY smart_tags_all ON public.research_smart_tags
  FOR ALL USING (true) WITH CHECK (true);


COMMENT ON TABLE public.shared_investigations IS
  'Kaninchenbau-Investigations zum Teilen via share_token (C2).';
COMMENT ON TABLE public.propaganda_bias_history IS
  'Trend-Daten für wiederholt geprüfte Quellen im Propaganda-Detector (C3).';
COMMENT ON TABLE public.research_smart_tags IS
  'Auto-vorgeschlagene Tags (NER via Worker-AI) für Research-Archive (C4).';
