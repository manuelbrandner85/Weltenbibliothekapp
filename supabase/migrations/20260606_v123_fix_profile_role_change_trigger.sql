-- v123: Bulletproof-Fix fuer profiles_role_change_audit Trigger.
--
-- v118 versuchte CREATE OR REPLACE FUNCTION, ist aber offenbar nicht
-- wirksam geworden (Live-Fehler 42703 column "actor_id" of relation
-- "admin_audit_log" does not exist). Diese Migration droppt Trigger
-- UND Funktion explizit und legt beides frisch mit dem korrekten
-- admin_audit_log-Schema neu an.

DROP TRIGGER IF EXISTS profiles_role_change_audit ON public.profiles;
DROP FUNCTION IF EXISTS public.log_profile_role_change() CASCADE;

CREATE FUNCTION public.log_profile_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
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
$function$;

CREATE TRIGGER profiles_role_change_audit
  AFTER UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.log_profile_role_change();
