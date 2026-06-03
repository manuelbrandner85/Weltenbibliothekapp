-- v118: profiles.role Default 'system' -> 'user' + Rollen-Audit-Trigger fixen
--
-- A) profiles.role hatte DEFAULT 'system'. Echte App-Registrierungen
--    (via /api/profile/materie|energie) setzten role nicht explizit -> jeder
--    neue User bekam role='system' statt 'user'. Default jetzt 'user';
--    bestehende echte User (ausser den 00000000-System-Platzhaltern) auf
--    'user' korrigiert.
--
-- B) KRITISCH: Der Trigger profiles_role_change_audit (Funktion
--    log_profile_role_change) schrieb in admin_audit_log mit Spalten
--    (actor_id, target_type, target_id, payload), die es NICHT gibt. Das
--    aktuelle Schema hat (admin_username, target_identity, target_username,
--    details, ...). Dadurch schlug JEDE Rollenaenderung auf profiles mit
--    42703 fehl -- inkl. des Admin-Rollenwechsels. Funktion auf das echte
--    Schema umgeschrieben.

-- ── B) Trigger-Funktion auf korrektes admin_audit_log-Schema ────────────
CREATE OR REPLACE FUNCTION public.log_profile_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
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

-- ── A) Default + Bestands-Korrektur (jetzt moeglich, Trigger ist gefixt) ─
ALTER TABLE public.profiles ALTER COLUMN role SET DEFAULT 'user';

UPDATE public.profiles
SET role = 'user'
WHERE role = 'system'
  AND id::text NOT LIKE '00000000-%';
