-- v127 (2026-06-07): Migriert bestehende admin_module_access-Zeilen mit
-- Legacy-IDs ('user_<ts>_<rand>') auf die kanonische profiles.id (UUID).
--
-- Hintergrund:
--   Frueher schrieb /api/admin/users/:userId/module-access die user_id
--   1:1 aus dem URL-Pfad. Wenn die Admin-User-Liste einen User mit seiner
--   Legacy-ID auspackte, landete die Override-Zeile unter dieser Legacy-ID.
--   Der Lesepfad in vorhang_service.dart sucht zwar via .inFilter ueber
--   UUID + legacy_user_id (siehe BUGFIX-Kommentar dort), aber die
--   Inkonsistenz blieb im Schreibpfad bestehen.
--
-- Diese Migration:
--   1) Findet alle admin_module_access-Zeilen mit Legacy-IDs ('user_%')
--   2) Sucht die zugehoerige profiles.id ueber profiles.legacy_user_id
--   3) Wenn UUID gefunden: schreibt user_id auf die UUID um
--      (per UPDATE, ON CONFLICT loescht die alte Legacy-Zeile)
--   4) Idempotent: kann mehrfach ausgefuehrt werden ohne Schaden
--   5) Loggt Anzahl der migrierten / verwaisten Zeilen in NOTICE
--
-- Sicherheit:
--   - Bestehende UUID-Zeilen bleiben unangetastet
--   - Wenn fuer eine Legacy-ID keine UUID auffindbar ist: Zeile bleibt
--     unveraendert (kein DELETE) damit kein User seine Freischaltung
--     verliert
--   - Doppelzeilen (UUID + Legacy fuer denselben Modul-Code) werden
--     deduplizert: UUID-Version gewinnt, Legacy-Version geloescht

BEGIN;

DO $$
DECLARE
  rec RECORD;
  uuid_id TEXT;
  migrated_count INT := 0;
  orphan_count INT := 0;
  conflict_count INT := 0;
BEGIN
  -- Iteriere ueber alle Legacy-Zeilen
  FOR rec IN
    SELECT user_id, module_code, module_type, is_granted, granted_by, reason, created_at
    FROM admin_module_access
    WHERE user_id LIKE 'user\_%' ESCAPE '\'
  LOOP
    -- UUID via profiles.legacy_user_id suchen
    SELECT id::text INTO uuid_id
    FROM profiles
    WHERE legacy_user_id = rec.user_id
    LIMIT 1;

    IF uuid_id IS NULL THEN
      orphan_count := orphan_count + 1;
      CONTINUE;
    END IF;

    -- Pruefen ob bereits eine UUID-Zeile fuer dasselben Modul existiert
    IF EXISTS (
      SELECT 1 FROM admin_module_access
      WHERE user_id = uuid_id AND module_code = rec.module_code
    ) THEN
      -- Konflikt: UUID-Zeile gewinnt, Legacy-Zeile loeschen
      DELETE FROM admin_module_access
      WHERE user_id = rec.user_id AND module_code = rec.module_code;
      conflict_count := conflict_count + 1;
    ELSE
      -- Umschreiben auf UUID
      UPDATE admin_module_access
      SET user_id = uuid_id
      WHERE user_id = rec.user_id AND module_code = rec.module_code;
      migrated_count := migrated_count + 1;
    END IF;
  END LOOP;

  RAISE NOTICE 'admin_module_access Legacy->UUID Migration abgeschlossen:';
  RAISE NOTICE '  Migriert (umgeschrieben):      %', migrated_count;
  RAISE NOTICE '  Konflikte (Legacy geloescht):  %', conflict_count;
  RAISE NOTICE '  Verwaist (kein profiles-Match): %', orphan_count;
END $$;

COMMIT;
