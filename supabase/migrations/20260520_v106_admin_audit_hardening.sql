-- ══════════════════════════════════════════════════════════════════════════
-- MIGRATION v106 -- Admin-Bereich-Audit Fixes (A3, A6, B2, B7, B14, C10)
-- ══════════════════════════════════════════════════════════════════════════
--
-- Stuetzt die Worker-Seite (api-worker.js v106) damit Admin-Aktionen
-- konsistent persistiert werden und nicht trivial zu missbrauchen sind.
--
-- Enthaelt:
--   A3  -- add_user_xp RPC mit Caller-Validierung + Self-Cap +100
--   A6  -- admin_bans Tabelle (existiert in v103, Worker speist sie jetzt ein)
--   B2  -- admin_mutes Tabelle fuer Chat-Mute (war Stub)
--   B7  -- user_push_preferences Tabelle (disabled_types[], dnd_until)
--   B14 -- admin_rate_limits Tabelle fuer Rate-Limiting auf Mutationen
--   C10 -- profiles.timezone Spalte fuer zeitzone-bewusste Cron-Pushes
--   ext -- RLS-Haertung auf admin_bans (Self-Read entfernt)
--
-- Idempotent durchfuehrbar.
-- ══════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────
-- A3: add_user_xp RPC haerten
--
-- Vorher: SECURITY DEFINER, GRANT EXECUTE TO anon + authenticated, max +-10000.
-- Jeder eingeloggte User konnte sich selbst 10000 XP geben.
--
-- Jetzt:
--   * Hoechstens +100 pro Call wenn Caller != service_role
--   * Caller muss == p_user_id sein (auth.uid()) ODER service_role
--   * Anon-Calls (ohne Auth) blocken
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.add_user_xp(
  p_user_id text,
  p_amount integer,
  p_reason text DEFAULT NULL
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_xp integer;
  uid uuid;
  caller_role text;
  caller_uid uuid;
  is_service_role boolean;
BEGIN
  -- Caller-Identitaet bestimmen
  caller_role := current_setting('request.jwt.claim.role', true);
  is_service_role := (caller_role = 'service_role');

  IF NOT is_service_role THEN
    -- Anon-Calls blockieren (keine Session)
    IF auth.uid() IS NULL THEN
      RAISE EXCEPTION 'add_user_xp: anonymous calls not allowed';
    END IF;
    caller_uid := auth.uid();

    -- Self-grant nur fuer eigene UUID
    BEGIN
      uid := p_user_id::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RETURN -1;
    END;
    IF uid <> caller_uid THEN
      RAISE EXCEPTION 'add_user_xp: caller can only modify own xp';
    END IF;

    -- Self-cap: max +100 pro Call. Negative Amounts komplett blockieren
    -- (kein Self-XP-Drain).
    IF p_amount > 100 OR p_amount < 0 THEN
      RAISE EXCEPTION 'add_user_xp: self-call amount must be in [0, 100]';
    END IF;
  ELSE
    -- service_role darf groesseren Range, aber bounded (kein Overflow-Bug)
    IF p_amount > 100000 OR p_amount < -100000 THEN
      RAISE EXCEPTION 'add_user_xp: service amount must be in [-100000, 100000]';
    END IF;
    BEGIN
      uid := p_user_id::uuid;
    EXCEPTION WHEN invalid_text_representation THEN
      RETURN -1;
    END;
  END IF;

  -- Atomar updaten (NULL-safe via COALESCE)
  UPDATE public.profiles
     SET xp = GREATEST(0, COALESCE(xp, 0) + p_amount)
   WHERE id = uid
   RETURNING xp INTO new_xp;

  IF new_xp IS NULL THEN
    RETURN -1; -- profile not found
  END IF;

  -- Audit (best-effort, table optional)
  BEGIN
    INSERT INTO public.admin_audit_log
      (admin_username, action, target_identity, details)
    VALUES
      (COALESCE(caller_role, 'unknown'), 'xp_grant', p_user_id,
       jsonb_build_object('amount', p_amount, 'reason', p_reason, 'new_xp', new_xp));
  EXCEPTION WHEN undefined_table THEN
    NULL;
  END;

  RETURN new_xp;
END;
$$;

-- Grants neu setzen -- anon entzogen, authenticated darf nur Self-Cap
REVOKE ALL ON FUNCTION public.add_user_xp(text, integer, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.add_user_xp(text, integer, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.add_user_xp(text, integer, text)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.add_user_xp(text, integer, text) IS
  'v106 audit-haerung: SECURITY DEFINER + caller=uid Check + Self-Cap +100.
   anon EXECUTE entzogen. service_role darf -100000..100000.';

-- ─────────────────────────────────────────────────────────────────────────
-- A6: admin_bans (RLS-Haertung -- Self-Read entfernen)
--
-- v103 erlaubte gebanntem User die eigene Ban-Row zu lesen. Informationsleck
-- ueber Reason / Banned-By / Expires-At. Entfernt.
-- ─────────────────────────────────────────────────────────────────────────

DO $$ BEGIN
  -- Pruefe ob Tabelle existiert (v103 sollte da sein)
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema = 'public' AND table_name = 'admin_bans') THEN
    -- Self-Read Policy entfernen wenn vorhanden
    DROP POLICY IF EXISTS admin_bans_self_select ON public.admin_bans;
    DROP POLICY IF EXISTS admin_bans_user_read ON public.admin_bans;
    -- Nur Admins (via app-Rolle) duerfen lesen. Service-Role umgeht RLS.
    DROP POLICY IF EXISTS admin_bans_admin_select ON public.admin_bans;
    CREATE POLICY admin_bans_admin_select ON public.admin_bans
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid()
            AND p.role IN ('root_admin','admin','moderator')
        )
      );
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────
-- B2: admin_mutes -- persistente Chat-Stummschaltung
--
-- Vorher: /api/admin/users/:id/mute war ein Stub ({success:true}).
-- Jetzt: persistiert mit Reason, Duration und Audit-Trail.
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_mutes (
  user_id text PRIMARY KEY,
  muted_by uuid NOT NULL,
  reason text NOT NULL,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_mutes_expires
  ON public.admin_mutes(expires_at)
  WHERE expires_at > NOW();

ALTER TABLE public.admin_mutes ENABLE ROW LEVEL SECURITY;

-- Admins koennen lesen, service_role darf alles
DROP POLICY IF EXISTS admin_mutes_admin_select ON public.admin_mutes;
CREATE POLICY admin_mutes_admin_select ON public.admin_mutes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('root_admin','admin','moderator')
    )
  );

GRANT SELECT ON public.admin_mutes TO authenticated;
GRANT ALL ON public.admin_mutes TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- B7: user_push_preferences -- pro User Opt-out fuer Push-Typen
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_push_preferences (
  user_id uuid,
  legacy_user_id text,
  disabled_types text[] NOT NULL DEFAULT '{}',
  dnd_until timestamptz,
  updated_at timestamptz NOT NULL DEFAULT NOW()
);

-- Genau eine Identitaet (uuid xor legacy) -- aber kein hartes Constraint weil
-- der bestehende Code beides setzen will. Stattdessen Composite Unique.
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_push_pref_user
  ON public.user_push_preferences(user_id) WHERE user_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_push_pref_legacy
  ON public.user_push_preferences(legacy_user_id) WHERE legacy_user_id IS NOT NULL;

ALTER TABLE public.user_push_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_push_pref_self ON public.user_push_preferences;
CREATE POLICY user_push_pref_self ON public.user_push_preferences
  FOR ALL USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()
            AND p.role IN ('root_admin','admin'))
  ) WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid()
            AND p.role IN ('root_admin','admin'))
  );

GRANT SELECT, INSERT, UPDATE ON public.user_push_preferences TO authenticated;
GRANT ALL ON public.user_push_preferences TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- B14: Rate-Limiting fuer Admin-Mutationen
--
-- Counter-Tabelle mit (admin_id, action, window_start_minute). Worker
-- INSERTs eine Row pro Mutation; bei zu vielen in einem 60s-Fenster wird
-- der Request mit 429 abgewiesen. Cleanup via Cron.
-- ─────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_rate_limits (
  admin_id uuid NOT NULL,
  action text NOT NULL,
  bucket_minute timestamptz NOT NULL,
  count integer NOT NULL DEFAULT 0,
  PRIMARY KEY (admin_id, action, bucket_minute)
);

CREATE INDEX IF NOT EXISTS idx_admin_rate_limits_cleanup
  ON public.admin_rate_limits(bucket_minute);

GRANT ALL ON public.admin_rate_limits TO service_role;

-- ─────────────────────────────────────────────────────────────────────────
-- C10: profiles.timezone fuer Timezone-bewusste Cron-Pushes
-- ─────────────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS timezone text DEFAULT 'Europe/Berlin';

-- ─────────────────────────────────────────────────────────────────────────
-- B3: 3-Strike-Auto-Ban Trigger
--
-- Wenn ein 3. Warning fuer einen User eingeht, automatisch in admin_bans
-- einfuegen (Hard-Ban + Audit). Loest die Race vom Client-Side Code.
-- ─────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_three_strike_auto_ban()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  warning_count integer;
BEGIN
  -- Zaehle aktive Warnings fuer den User (inkl. dieser)
  SELECT COUNT(*) INTO warning_count
  FROM public.admin_warnings
  WHERE user_id = NEW.user_id
    AND (expires_at IS NULL OR expires_at > NOW());

  IF warning_count >= 3 THEN
    -- Auto-Ban einfuegen (idempotent via ON CONFLICT)
    INSERT INTO public.admin_bans (user_id, banned_by, reason, expires_at, created_at)
    VALUES (
      NEW.user_id,
      NEW.warned_by,
      '3-Strike Auto-Ban: ' || COALESCE(NEW.reason, 'wiederholte Regelverstoesse'),
      NULL,  -- permanent
      NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- profiles.is_banned setzen
    UPDATE public.profiles SET is_banned = true WHERE id::text = NEW.user_id;

    -- Audit
    BEGIN
      INSERT INTO public.admin_audit_log
        (actor_id, admin_username, action, target_type, target_id, payload)
      VALUES (
        NEW.warned_by, 'system_auto', '3_strike_auto_ban',
        'profile', NEW.user_id,
        jsonb_build_object('warning_count', warning_count, 'triggered_by_warning', NEW.id)
      );
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
  END IF;

  RETURN NEW;
END;
$$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='admin_warnings') THEN
    DROP TRIGGER IF EXISTS tr_three_strike_auto_ban ON public.admin_warnings;
    CREATE TRIGGER tr_three_strike_auto_ban
      AFTER INSERT ON public.admin_warnings
      FOR EACH ROW
      EXECUTE FUNCTION public.fn_three_strike_auto_ban();
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────
-- DONE. v106 Admin-Audit fertig.
-- ─────────────────────────────────────────────────────────────────────────
