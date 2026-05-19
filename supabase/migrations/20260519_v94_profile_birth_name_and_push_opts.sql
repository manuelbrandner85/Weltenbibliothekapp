-- v94: Geburtsname-Felder (Verbesserung 2) + numerology_push_enabled (Verbesserung 5)
-- Alle Spalten idempotent + nullable, daher backward-compatible.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS birth_first_name TEXT,
  ADD COLUMN IF NOT EXISTS birth_middle_names TEXT,
  ADD COLUMN IF NOT EXISTS birth_last_name TEXT,
  ADD COLUMN IF NOT EXISTS numerology_push_enabled BOOLEAN DEFAULT TRUE;

-- Kommentare zur Doku:
COMMENT ON COLUMN profiles.birth_first_name IS
  'Vorname bei Geburt -- relevant fuer Numerologie-Vergleich nach Namensaenderung (Heirat/Adoption).';
COMMENT ON COLUMN profiles.birth_middle_names IS
  'Alle Zweitnamen bei Geburt (Space-separated).';
COMMENT ON COLUMN profiles.birth_last_name IS
  'Nachname bei Geburt (z.B. Maedchenname).';
COMMENT ON COLUMN profiles.numerology_push_enabled IS
  'Opt-In fuer taegliche Numerologie-Tagesenergie-Push (default TRUE).';
