-- v123: God-Mode Dev-Requests
-- Backing-Table fuer Root-Admin-Entwicklerkonsole.
-- RLS an, keine Policy -> nur Worker (service_role) liest/schreibt.

CREATE TABLE IF NOT EXISTS godmode_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  requested_by  text NOT NULL,
  category      text NOT NULL DEFAULT 'other',
  title         text NOT NULL,
  description   text NOT NULL DEFAULT '',
  source        text NOT NULL DEFAULT 'manual',
  status        text NOT NULL DEFAULT 'queued',
  issue_number  integer,
  issue_url     text,
  pr_number     integer,
  pr_url        text,
  error         text
);

CREATE INDEX IF NOT EXISTS godmode_requests_created_idx
  ON godmode_requests (created_at DESC);
CREATE INDEX IF NOT EXISTS godmode_requests_status_idx
  ON godmode_requests (status);

ALTER TABLE godmode_requests
  DROP CONSTRAINT IF EXISTS godmode_requests_status_check;
ALTER TABLE godmode_requests
  ADD CONSTRAINT godmode_requests_status_check
  CHECK (status IN (
    'queued','issue_created','building','pr_open','merged','failed','rejected'
  ));

ALTER TABLE godmode_requests
  DROP CONSTRAINT IF EXISTS godmode_requests_category_check;
ALTER TABLE godmode_requests
  ADD CONSTRAINT godmode_requests_category_check
  CHECK (category IN (
    'ui_ux','feature','module','bugfix','performance','other'
  ));

ALTER TABLE godmode_requests ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION godmode_requests_touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS godmode_requests_touch ON godmode_requests;
CREATE TRIGGER godmode_requests_touch
  BEFORE UPDATE ON godmode_requests
  FOR EACH ROW EXECUTE FUNCTION godmode_requests_touch_updated_at();
