-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v71 – Auto-Role-Trigger für 'Weltenbibliothek'
-- Setzt role='root_admin' automatisch bei jedem INSERT/UPDATE
-- auf profiles wenn username='weltenbibliothek' (case-insensitive).
-- SECURITY DEFINER: übergeht RLS, da Trigger server-seitig läuft.
-- ═══════════════════════════════════════════════════════════════

-- Trigger-Funktion (SECURITY DEFINER für RLS-Bypass)
CREATE OR REPLACE FUNCTION public.auto_set_admin_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF lower(NEW.username) = 'weltenbibliothek' THEN
    NEW.role := 'root_admin';
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger auf profiles (BEFORE → modifiziert NEW direkt)
DROP TRIGGER IF EXISTS trg_auto_admin_role ON public.profiles;
CREATE TRIGGER trg_auto_admin_role
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_set_admin_role();

-- Sofort das aktuelle Profil aktualisieren (falls schon vorhanden)
UPDATE public.profiles
   SET role = 'root_admin', updated_at = now()
 WHERE lower(username) = 'weltenbibliothek';
