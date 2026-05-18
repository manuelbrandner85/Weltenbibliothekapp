-- ══════════════════════════════════════════════════════════════════════════════
-- MIGRATION v90 - add_user_xp RPC
--
-- Atomares XP-Increment fuer profiles.xp. Wird genutzt von:
--   - Worker: Vorhang/Ursprung Module-Complete + Admin-XP-Vergabe
--   - Client: SpiritReadingService award beim Reading-Save
--
-- SECURITY DEFINER damit Funktion auch von Client mit RLS-User-Token
-- ausgefuehrt werden kann (umgeht RLS-Restriktionen auf profiles).
-- Funktion validiert dass p_user_id eine UUID ist die in profiles existiert.
-- ══════════════════════════════════════════════════════════════════════════════

-- Sicherheit: nur creator (postgres) darf grant geben.
-- Funktion akzeptiert sowohl uuid als auch text user_id (legacy InvisibleAuth).
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
BEGIN
  -- Bound check: max ±10000 pro Call (verhindert Missbrauch)
  IF p_amount > 10000 OR p_amount < -10000 THEN
    RAISE EXCEPTION 'add_user_xp: amount must be in [-10000, 10000]';
  END IF;

  -- Versuche p_user_id als UUID zu parsen. Wenn das fehlschlaegt,
  -- ist es eine legacy InvisibleAuth-ID (user_<ts>_<rand>) und wir machen
  -- no-op (die User existieren nicht in profiles).
  BEGIN
    uid := p_user_id::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN -1;
  END;

  -- Atomar updaten (NULL-safe via COALESCE)
  UPDATE public.profiles
     SET xp = GREATEST(0, COALESCE(xp, 0) + p_amount)
   WHERE id = uid
   RETURNING xp INTO new_xp;

  IF new_xp IS NULL THEN
    RETURN -1; -- profile not found
  END IF;

  -- Optional Audit (sichtbar in admin_audit_log wenn Tabelle existiert)
  BEGIN
    INSERT INTO public.admin_audit_log
      (admin_username, action, target_identity, details)
    VALUES
      ('system_xp', 'xp_grant', p_user_id,
       jsonb_build_object('amount', p_amount, 'reason', p_reason, 'new_xp', new_xp));
  EXCEPTION WHEN undefined_table THEN
    NULL; -- admin_audit_log nicht gesetzt (v76 vorher noetig)
  END;

  RETURN new_xp;
END;
$$;

-- Grants
REVOKE ALL ON FUNCTION public.add_user_xp(text, integer, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.add_user_xp(text, integer, text)
  TO anon, authenticated, service_role;

COMMENT ON FUNCTION public.add_user_xp(text, integer, text) IS
  'Atomares XP-Increment. SECURITY DEFINER. Tolerant gegenueber legacy
   text-user_ids (no-op wenn nicht-UUID). Bounded [-10000, +10000].
   Returns new xp total oder -1 bei Fehler (Profil nicht gefunden).';
