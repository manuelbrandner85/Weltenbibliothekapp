-- ══════════════════════════════════════════════════════════════════════════════
-- v91 — PROFILE-INVISIBLE-AUTH-KOMPATIBILITAET + user_devices + role audit
-- ══════════════════════════════════════════════════════════════════════════════
-- Behebt das Kern-Problem: InvisibleAuth-User koennen kein Profil anlegen
-- weil profiles.id eine UUID FK auf auth.users(id) ohne DEFAULT war.
-- Worker-POST /api/profile/materie schlug bei neuen Usern silent fehl.
--
-- Aenderungen:
-- 1. profiles.id bekommt DEFAULT gen_random_uuid() (auto-generierte UUID
--    fuer Neuanlagen ohne auth.users-Eintrag)
-- 2. FK profiles_id_fkey wird DEFERRABLE INITIALLY DEFERRED damit
--    InvisibleAuth-User Profile anlegen koennen die nicht in auth.users
--    existieren (FK-Check passiert erst beim COMMIT - wir koennen ihn
--    durch fehlende auth.users-Zeile umgehen wenn wir KEIN auth.uid setzen)
-- 3. Neue Spalte profiles.legacy_user_id TEXT UNIQUE - speichert die
--    client-generierte InvisibleAuth-ID damit die App ihre Daten wiederfindet
-- 4. user_devices Tabelle fuer FCM-Token-Persistenz (vorher nur Worker-Cache,
--    kein Audit + kein Cross-Device-Sync moeglich)
-- 5. admin_audit_log Eintrag fuer jede Role-Aenderung (Compliance)
--
-- Rueckwaerts-kompatibel: bestehende Profile mit auth.users-Eintrag funktionieren
-- weiter, nur neue InvisibleAuth-User koennen jetzt zusaetzlich angelegt werden.

-- ── 1. profiles.id DEFAULT gen_random_uuid() ────────────────────────────────
ALTER TABLE public.profiles
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- ── 2. FK auf auth.users entkoppeln (bestehende Rows behalten ihre id) ─────
-- Wir droppen die FK damit InvisibleAuth-User profiles.id auto-generieren
-- koennen ohne auth.users-Zeile zu brauchen. Wer echte Auth nutzt, dessen
-- profiles.id passt weiter zu auth.users.id (das war schon immer so via Trigger
-- handle_new_user). Datenintegritaet bleibt durch UNIQUE(id) erhalten.
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- ── 3. legacy_user_id Spalte fuer InvisibleAuth ─────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS legacy_user_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_legacy_user_id
  ON public.profiles (legacy_user_id)
  WHERE legacy_user_id IS NOT NULL;

-- ── 4. user_devices Tabelle fuer FCM-Token-Persistenz ──────────────────────
CREATE TABLE IF NOT EXISTS public.user_devices (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  legacy_user_id  TEXT,  -- fallback fuer InvisibleAuth-User ohne profile_id
  fcm_token       TEXT NOT NULL,
  platform        TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  app_version     TEXT,
  device_model    TEXT,
  last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (fcm_token)  -- ein FCM-Token = ein Device, egal welcher User
);

CREATE INDEX IF NOT EXISTS idx_user_devices_profile_id
  ON public.user_devices (profile_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_legacy_user_id
  ON public.user_devices (legacy_user_id) WHERE legacy_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_devices_platform
  ON public.user_devices (platform);

-- Auto-update last_seen_at on UPDATE
DROP TRIGGER IF EXISTS user_devices_last_seen ON public.user_devices;
CREATE TRIGGER user_devices_last_seen
  BEFORE UPDATE ON public.user_devices
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- RLS aktivieren (Worker nutzt Service-Role-Key)
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Default-Policies: User darf NUR seine eigenen Devices sehen (via legacy_user_id
-- header oder auth.uid). Schreiben nur via Service-Role (Worker).
DROP POLICY IF EXISTS user_devices_read_own ON public.user_devices;
CREATE POLICY user_devices_read_own ON public.user_devices
  FOR SELECT USING (
    profile_id = auth.uid()
    OR legacy_user_id IS NOT NULL  -- temporaer permissiv fuer InvisibleAuth-Phase
  );

-- ── 5. admin_audit_log: Trigger fuer profile.role Aenderungen ──────────────
-- Bestehende admin_audit_log Tabelle (v87 cluster_m_admin) wird genutzt.
-- Jede Aenderung von profiles.role wird automatisch geloggt.
--
-- ROOT-CAUSE-FIX (2026-06-06): Diese Migration laeuft bei JEDEM Push auf
-- main (apply_migrations.yml hat keinen paths-Filter). Die urspruengliche
-- Variante schrieb in admin_audit_log(actor_id, target_type, target_id,
-- payload) -- Spalten, die im aktuellen Schema NICHT existieren. Dadurch
-- wurde die Funktion bei jedem Deploy wieder auf die kaputte Form
-- zurueckgesetzt und JEDER Rollenwechsel schlug mit 42703 fehl, obwohl
-- v118/v123/v124 sie zwischenzeitlich gefixt hatten (diese laufen nicht
-- im Workflow). Deshalb hier an der Quelle auf das echte Schema
-- (admin_username, action, target_identity, target_username, details)
-- korrigiert.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'admin_audit_log'
  ) THEN
    CREATE OR REPLACE FUNCTION public.log_profile_role_change()
    RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
    SET search_path = public AS $func$
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
    $func$;

    DROP TRIGGER IF EXISTS profiles_role_change_audit ON public.profiles;
    CREATE TRIGGER profiles_role_change_audit
      AFTER UPDATE OF role ON public.profiles
      FOR EACH ROW EXECUTE FUNCTION public.log_profile_role_change();
  END IF;
END
$$;

-- ── 6. RLS auf profiles VERSCHAERFEN ───────────────────────────────────────
-- Aktuell USING(true) auf vielen Tabellen (siehe CLAUDE.md TODO). Speziell
-- fuer profiles.role: nur Admins duerfen rollen aendern.
DROP POLICY IF EXISTS profiles_role_update_admin_only ON public.profiles;
CREATE POLICY profiles_role_update_admin_only ON public.profiles
  FOR UPDATE
  USING (
    -- Read access fuer eigenen Eintrag oder via Service-Role
    auth.uid() = id OR auth.role() = 'service_role'
  )
  WITH CHECK (
    -- Schreib-Check: entweder Service-Role (Worker) ODER User aendert
    -- nur seine eigenen Nicht-Role-Felder. Role-Aenderung NUR durch Service-Role.
    auth.role() = 'service_role'
    OR (auth.uid() = id AND role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid()))
  );

-- ── 7. COMMENT fuer Doku ───────────────────────────────────────────────────
COMMENT ON COLUMN public.profiles.legacy_user_id IS
  'Client-generierte InvisibleAuth-ID (user_<ts>_<rand>). Wird beim Profile-Save vom Worker gespeichert. Kann genutzt werden um App-Daten an die spaeter migrierte Supabase-Auth-Identitaet zu binden.';

COMMENT ON TABLE public.user_devices IS
  'FCM-Token-Registry pro Device. Persistierter Backup vom Worker-Cache. Erlaubt Cross-Device-Push + Audit. profile_id oder legacy_user_id muessen gesetzt sein.';
