-- v126: Defensive Schema-Erweiterung fuer admin_audit_log.
--
-- Trotz v123/v124/v125, die public.log_profile_role_change auf das
-- neue Schema umgebogen haben, wird der Funktions-Body offenbar wieder
-- in die v91-Form zurueckgesetzt (Mechanismus unbekannt -- evtl. ein
-- Supabase-Replay alter Migrationen oder ein anderer Replacer den wir
-- noch nicht gefunden haben). Solange wir das nicht eindeutig fangen
-- koennen, schliessen wir den Bug von der anderen Seite: wir geben
-- admin_audit_log die alten Spalten als nullable -- dann gehen
-- INSERTs beider Form sauber durch. Kein Daten-Verlust, keine RLS-
-- Aenderung, kein Verhalten der App betroffen.

ALTER TABLE public.admin_audit_log
  ADD COLUMN IF NOT EXISTS actor_id     UUID,
  ADD COLUMN IF NOT EXISTS target_type  TEXT,
  ADD COLUMN IF NOT EXISTS target_id    TEXT,
  ADD COLUMN IF NOT EXISTS payload      JSONB;

COMMENT ON COLUMN public.admin_audit_log.actor_id IS
  'Legacy v91 column -- v126 schema-defense fuer alte log_profile_role_change-Variante. Echte Audit-Eintraege nutzen admin_username.';
COMMENT ON COLUMN public.admin_audit_log.target_type IS
  'Legacy v91 column -- v126 schema-defense.';
COMMENT ON COLUMN public.admin_audit_log.target_id IS
  'Legacy v91 column -- v126 schema-defense. Echte Eintraege nutzen target_identity.';
COMMENT ON COLUMN public.admin_audit_log.payload IS
  'Legacy v91 column -- v126 schema-defense. Echte Eintraege nutzen details (jsonb).';
