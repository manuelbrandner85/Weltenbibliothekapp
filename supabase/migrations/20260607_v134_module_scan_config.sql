-- W7: Konfiguration fuer den KI-Auto-Scan-Cron (Single-Row).
CREATE TABLE IF NOT EXISTS module_scan_config (
  id          integer     PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  enabled     boolean     NOT NULL DEFAULT true,
  worlds      text[]      NOT NULL DEFAULT ARRAY['materie','energie','vorhang','ursprung'],
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  text
);
ALTER TABLE module_scan_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service rw module_scan_config" ON module_scan_config FOR ALL USING (auth.role() = 'service_role');
INSERT INTO module_scan_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
