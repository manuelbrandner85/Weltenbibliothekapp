-- v116: Admin-gesteuerte Modul-Freischaltung / -Sperre
-- Erlaubt Admins, einzelne Module fuer einzelne User zu erzwingen (grant)
-- oder zu blockieren (revoke) -- unabhaengig vom normalen Prerequisite-System.
-- Zeile in dieser Tabelle = Override; kein Eintrag = normale Prerequisite-Logik.

CREATE TABLE IF NOT EXISTS public.admin_module_access (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      TEXT NOT NULL,        -- profiles.id (text wie in anderen admin_*-Tabellen)
  module_code  TEXT NOT NULL,        -- z.B. 'V-01', 'U-03'
  module_type  TEXT NOT NULL CHECK (module_type IN ('vorhang', 'ursprung')),
  is_granted   BOOLEAN NOT NULL,     -- true = Force-Unlock, false = Force-Block
  granted_by   TEXT,                 -- Admin-Username der Aktion ausgefuehrt hat
  reason       TEXT,                 -- optionale Begruendung
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, module_code)      -- ein Override pro User+Modul
);

-- Index fuer schnellen Lookup nach User (Haupt-Query-Pattern im Worker)
CREATE INDEX IF NOT EXISTS idx_admin_module_access_user
  ON public.admin_module_access (user_id);

-- Index fuer Admin-Uebersicht: alle Overrides eines Moduls
CREATE INDEX IF NOT EXISTS idx_admin_module_access_module
  ON public.admin_module_access (module_type, module_code);

-- RLS: Admins koennen alles lesen + schreiben. User haben keinen Zugriff
-- (Overrides werden serverseitig angewandt, nicht client-seitig zurueckgegeben).
ALTER TABLE public.admin_module_access ENABLE ROW LEVEL SECURITY;

-- Admins/Mods duerfen alles sehen
CREATE POLICY "admin_module_access_admin_select" ON public.admin_module_access
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin', 'moderator', 'content_editor')
    )
  );

-- Nur Admins duerfen schreiben (nicht Mods -- Modul-Override ist erheblicher Eingriff)
CREATE POLICY "admin_module_access_admin_insert" ON public.admin_module_access
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin')
    )
  );

CREATE POLICY "admin_module_access_admin_update" ON public.admin_module_access
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin')
    )
  );

CREATE POLICY "admin_module_access_admin_delete" ON public.admin_module_access
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id::text = auth.uid()::text
        AND role IN ('admin', 'root_admin')
    )
  );

-- Service-Role (Worker) umgeht RLS automatisch via service_role key.
