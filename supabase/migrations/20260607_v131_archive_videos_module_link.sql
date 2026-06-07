-- C3: Video <-> Modul-Verknuepfung
ALTER TABLE archive_videos ADD COLUMN IF NOT EXISTS module_code text;
ALTER TABLE archive_videos ADD COLUMN IF NOT EXISTS module_world text;
CREATE INDEX IF NOT EXISTS idx_archive_videos_module
  ON archive_videos (module_world, module_code) WHERE module_code IS NOT NULL;
