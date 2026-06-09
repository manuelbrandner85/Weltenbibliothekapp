-- v141: God-Mode Typen + selbstlernende Themen
-- Erweitert godmode_requests um wb_type (Fehler/Bug, Neuerung, Erweiterung, ...)
-- und legt godmode_topics an: von der KI selbststaendig erkannte App-Bereiche.
-- RLS an, keine Policy -> nur Worker (service_role) liest/schreibt.

-- 1) Typ-Spalte: was fuer eine Massnahme (Bug/Neuerung/Erweiterung/...).
ALTER TABLE godmode_requests
  ADD COLUMN IF NOT EXISTS wb_type text;

ALTER TABLE godmode_requests
  DROP CONSTRAINT IF EXISTS godmode_requests_wb_type_check;
ALTER TABLE godmode_requests
  ADD CONSTRAINT godmode_requests_wb_type_check
  CHECK (wb_type IS NULL OR wb_type IN (
    'bug','neuerung','erweiterung','verbesserung','performance','ux'
  ));

-- 2) Selbstlernende Themen/Bereiche: die KI traegt mit der Zeit neue
--    Bereiche ein, zu denen sie dann gezielt Vorschlaege liefert.
CREATE TABLE IF NOT EXISTS godmode_topics (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  slug          text NOT NULL UNIQUE,
  label         text NOT NULL,
  origin        text NOT NULL DEFAULT 'ai',      -- 'ai' (gelernt) | 'manual'
  status        text NOT NULL DEFAULT 'active',  -- 'active' | 'archived'
  hit_count     integer NOT NULL DEFAULT 1,      -- wie oft die KI das Thema vorschlug
  last_seen_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS godmode_topics_status_idx
  ON godmode_topics (status, last_seen_at DESC);

ALTER TABLE godmode_topics
  DROP CONSTRAINT IF EXISTS godmode_topics_origin_check;
ALTER TABLE godmode_topics
  ADD CONSTRAINT godmode_topics_origin_check
  CHECK (origin IN ('ai','manual'));

ALTER TABLE godmode_topics
  DROP CONSTRAINT IF EXISTS godmode_topics_status_check;
ALTER TABLE godmode_topics
  ADD CONSTRAINT godmode_topics_status_check
  CHECK (status IN ('active','archived'));

ALTER TABLE godmode_topics ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION godmode_topics_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS godmode_topics_touch ON godmode_topics;
CREATE TRIGGER godmode_topics_touch
  BEFORE UPDATE ON godmode_topics
  FOR EACH ROW EXECUTE FUNCTION godmode_topics_touch_updated_at();
