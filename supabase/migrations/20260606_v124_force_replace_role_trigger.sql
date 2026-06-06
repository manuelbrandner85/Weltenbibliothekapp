-- v124: Force-Replace fuer log_profile_role_change.
--
-- v123 wurde in der migrations-Tabelle eingetragen, hat den Funktions-
-- Body aber aus unklaren Gruenden nicht ueberschrieben (pg_proc.prosrc
-- enthielt nach v123 weiter die v91-Variante mit actor_id). Dadurch
-- schlug jeder Rollenwechsel mit 42703 fehl.
--
-- Diese Migration laeuft denselben DROP + CREATE und schliesst mit einem
-- Assert ab, der bricht falls der Body nach dem CREATE weiter actor_id
-- referenziert. Dadurch wird ein "Migration registriert, aber DDL nicht
-- ausgefuehrt"-Zustand sofort sichtbar.

DROP TRIGGER IF EXISTS profiles_role_change_audit ON public.profiles;
DROP FUNCTION IF EXISTS public.log_profile_role_change() CASCADE;

CREATE FUNCTION public.log_profile_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $body$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    INSERT INTO public.admin_audit_log (
      admin_username, action, target_identity, target_username, details, created_at
    ) VALUES (
      'system (trigger)',
      'role_change',
      NEW.id::text,
      NEW.username,
      jsonb_build_object(
        'old_role', OLD.role,
        'new_role', NEW.role,
        'username', NEW.username
      ),
      NOW()
    );
  END IF;
  RETURN NEW;
END;
$body$;

CREATE TRIGGER profiles_role_change_audit
  AFTER UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.log_profile_role_change();

DO $check$
DECLARE
  src TEXT;
BEGIN
  SELECT p.prosrc INTO src
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'log_profile_role_change'
  LIMIT 1;
  IF src ILIKE '%actor_id%' THEN
    RAISE EXCEPTION 'v124 assert failed: log_profile_role_change still references actor_id (something is reverting it)';
  END IF;
END $check$;
