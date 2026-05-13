-- v62 · Biometric Feedback System
-- ================================
-- Stores per-session HRV/HR snapshots and the computed effectiveness score
-- (Wirkungs-Score). Powered by the `health` Flutter plugin which reads from
-- Apple HealthKit (iOS) and Android Health Connect (Android).

CREATE TABLE IF NOT EXISTS public.biometric_readings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_type TEXT NOT NULL,               -- e.g. 'gateway', 'breathmaster', 'meditation'
  session_world TEXT,                       -- e.g. 'ursprung', 'vorhang'
  hrv_before REAL,
  hrv_after REAL,
  hr_before REAL,
  hr_after REAL,
  effectiveness_score REAL,
  duration_minutes INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_biometric_readings_user_created
  ON public.biometric_readings (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_biometric_readings_user_world
  ON public.biometric_readings (user_id, session_world);

-- ── Row-Level Security ──────────────────────────────────────────────
ALTER TABLE public.biometric_readings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "biometric_readings_select_own" ON public.biometric_readings;
CREATE POLICY "biometric_readings_select_own"
  ON public.biometric_readings
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "biometric_readings_insert_own" ON public.biometric_readings;
CREATE POLICY "biometric_readings_insert_own"
  ON public.biometric_readings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "biometric_readings_update_own" ON public.biometric_readings;
CREATE POLICY "biometric_readings_update_own"
  ON public.biometric_readings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "biometric_readings_delete_own" ON public.biometric_readings;
CREATE POLICY "biometric_readings_delete_own"
  ON public.biometric_readings
  FOR DELETE
  USING (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.biometric_readings TO authenticated;
