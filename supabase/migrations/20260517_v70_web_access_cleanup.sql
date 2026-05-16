-- ═══════════════════════════════════════════════════════════════════════
-- MIGRATION v70 – Web-Access Cleanup
-- Löscht verwaiste Admin-Einträge aus web_access_requests.
-- Der Admin "Weltenbibliothek" wird hardcoded geprüft (kein DB-Eintrag nötig).
-- ═══════════════════════════════════════════════════════════════════════

-- Alten Test-Eintrag löschen (falls vorhanden, idempotent)
DELETE FROM public.web_access_requests
 WHERE lower(display_name) = 'weltenbibliothek';

-- Sicherheitsnetz: Trigger verhindert künftige Inserts mit Admin-Name
CREATE OR REPLACE FUNCTION public.prevent_admin_web_access_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF lower(NEW.display_name) = 'weltenbibliothek' THEN
    RAISE EXCEPTION 'Admin-Name kann nicht als Web-Zugang registriert werden.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_admin_web_access ON public.web_access_requests;
CREATE TRIGGER trg_prevent_admin_web_access
  BEFORE INSERT OR UPDATE ON public.web_access_requests
  FOR EACH ROW EXECUTE FUNCTION public.prevent_admin_web_access_insert();
