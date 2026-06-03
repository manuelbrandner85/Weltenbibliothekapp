-- v119: admin_module_access fuer den eigenen Client lesbar machen
--
-- BUG: Admin schaltet ein Modul frei (Worker schreibt via service_role,
--   umgeht RLS -> Insert klappt). Aber die App liest admin_module_access
--   mit dem ANON-Client (vorhang_service.dart / ursprung_service.dart,
--   .from('admin_module_access').select(...).eq('user_id', ...)). Die
--   vorhandene SELECT-Policy verlangt jedoch eine Admin-Rolle via
--   auth.uid(). Unter InvisibleAuth gibt es keine echte Supabase-Session,
--   daher ist auth.uid() NULL -> ein normaler User liest 0 Zeilen -> der
--   Admin-Override wird nie angewendet. "Freischaltung funktioniert nicht".
--
-- FIX: Zusaetzliche permissive SELECT-Policy (qual = true). Die Daten sind
--   unkritisch (nur welche Module fuer welche user_id freigeschaltet/
--   gesperrt sind). Schreibzugriff (INSERT/UPDATE/DELETE) bleibt durch die
--   bestehenden Admin-Policies geschuetzt; der Worker schreibt ohnehin per
--   service_role (RLS-Bypass). Sobald der Auth-Refactor (Anonymous Auth)
--   steht, kann dies auf auth.uid()=user_id verschaerft werden.

DROP POLICY IF EXISTS admin_module_access_public_select ON public.admin_module_access;
CREATE POLICY admin_module_access_public_select
  ON public.admin_module_access
  FOR SELECT
  USING (true);
