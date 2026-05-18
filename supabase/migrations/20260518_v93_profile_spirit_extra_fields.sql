-- ══════════════════════════════════════════════════════════════════════════════
-- v93 — PROFILE: EXTRA-FELDER FUER SPIRIT-TOOLS (lat/lng/tz/time_unknown)
-- ══════════════════════════════════════════════════════════════════════════════
-- Anforderung: Spirit-Tools (Horoskop, Human Design, Birthchart 360) sollen
-- alle Daten aus dem Profil ziehen, nicht jedes Mal vom User abfragen.
--
-- Fehlende Felder identifiziert via Audit:
--   - birth_latitude, birth_longitude → Aszendent-Berechnung im Horoskop
--   - timezone_offset_hours → Human-Design + Horoskop UTC-Konvertierung
--   - birth_time_unknown → persistenter Flag (vorher nur UI-State)

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS birth_latitude       NUMERIC(9, 6),
  ADD COLUMN IF NOT EXISTS birth_longitude      NUMERIC(9, 6),
  ADD COLUMN IF NOT EXISTS timezone_offset_hours NUMERIC(4, 2),
  ADD COLUMN IF NOT EXISTS birth_time_unknown   BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS gender               TEXT
    CHECK (gender IN ('male', 'female', 'diverse', 'prefer_not_say') OR gender IS NULL);

-- Index fuer Astrologie-Aggregate (Wer hat Geburtsort in welcher Region)
CREATE INDEX IF NOT EXISTS idx_profiles_birth_coords
  ON public.profiles (birth_latitude, birth_longitude)
  WHERE birth_latitude IS NOT NULL AND birth_longitude IS NOT NULL;

COMMENT ON COLUMN public.profiles.birth_latitude IS
  'Geo-Koordinate des Geburtsorts (Dezimalgrad, -90..90). Wird fuer exakte '
  'Aszendent-Berechnung im Astrologie-Modul benoetigt.';
COMMENT ON COLUMN public.profiles.birth_longitude IS
  'Geo-Koordinate des Geburtsorts (Dezimalgrad, -180..180).';
COMMENT ON COLUMN public.profiles.timezone_offset_hours IS
  'UTC-Offset des Geburtsorts zur Geburtszeit (z.B. 1.0 fuer MEZ, '
  '5.5 fuer Indien). Halbstunden-Offsets sind valid (Indien, NF).';
COMMENT ON COLUMN public.profiles.birth_time_unknown IS
  'Wenn TRUE: User kennt seine Geburtszeit nicht - Tools sollen 12:00 lokal '
  'als Annahme nehmen und keine Aszendent-Berechnung versuchen.';
COMMENT ON COLUMN public.profiles.gender IS
  'Optional fuer gender-tuned Content (Affirmationen, Mantras). '
  'NULL = nicht angegeben, prefer_not_say = explizit privat.';
