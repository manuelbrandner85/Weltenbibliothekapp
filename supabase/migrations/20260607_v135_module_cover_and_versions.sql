-- W3: Cover-Bild je Modul.
ALTER TABLE vorhang_modules  ADD COLUMN IF NOT EXISTS cover_image_url text;
ALTER TABLE ursprung_modules ADD COLUMN IF NOT EXISTS cover_image_url text;
ALTER TABLE materie_modules  ADD COLUMN IF NOT EXISTS cover_image_url text;
ALTER TABLE energie_modules  ADD COLUMN IF NOT EXISTS cover_image_url text;

-- W5: Versions-Snapshots je Modul (fuer Undo).
CREATE TABLE IF NOT EXISTS module_versions (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  world       text        NOT NULL,
  module_code text        NOT NULL,
  snapshot    jsonb       NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  text
);
CREATE INDEX IF NOT EXISTS idx_module_versions_lookup
  ON module_versions (world, module_code, created_at DESC);
ALTER TABLE module_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service rw module_versions" ON module_versions FOR ALL USING (auth.role() = 'service_role');
