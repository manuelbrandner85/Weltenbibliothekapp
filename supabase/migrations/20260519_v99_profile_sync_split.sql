-- v99: Profile-Sync getrennt von Presence-Heartbeat.
-- Auto-Create eines Profils geschieht NUR wenn der User aktiv ein Profil
-- ausfuellt (per ensure_legacy_profile mit Avatar). Der Heartbeat darf
-- nur noch last_seen_at updaten -- keine neuen Eintraege mehr.

-- ── 1. ensure_legacy_profile erweitert (mit avatar_emoji + role) ─────────
-- Wird vom Client aufgerufen wenn ein Materie/Energie/etc-Profil GESPEICHERT
-- wird. Erstellt Profil falls noch nicht da; sonst werden Felder
-- aktualisiert (Username/Display-Name/Avatar). last_seen_at wird mit
-- gesetzt damit der User direkt "online" erscheint.
DROP FUNCTION IF EXISTS public.ensure_legacy_profile(TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.ensure_legacy_profile(
  p_legacy_id    TEXT,
  p_username     TEXT,
  p_display_name TEXT DEFAULT NULL,
  p_avatar_emoji TEXT DEFAULT NULL,
  p_avatar_url   TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  IF p_legacy_id IS NULL OR p_legacy_id = '' THEN
    RAISE EXCEPTION 'legacy_id darf nicht leer sein';
  END IF;
  IF p_username IS NULL OR p_username = '' THEN
    RAISE EXCEPTION 'username darf nicht leer sein';
  END IF;

  SELECT id INTO v_id
  FROM public.profiles
  WHERE legacy_user_id = p_legacy_id
  LIMIT 1;

  IF v_id IS NULL THEN
    -- Neu anlegen mit allen verfuegbaren Echtdaten.
    INSERT INTO public.profiles (
      id, username, display_name, role, is_banned,
      legacy_user_id, avatar_url, avatar_emoji,
      created_at, last_seen_at
    )
    VALUES (
      gen_random_uuid(),
      p_username,
      COALESCE(p_display_name, p_username),
      'user',
      false,
      p_legacy_id,
      p_avatar_url,
      p_avatar_emoji,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_id;
  ELSE
    -- Bestehendes Profil mit Echtdaten abgleichen.
    UPDATE public.profiles
    SET username     = COALESCE(NULLIF(p_username, ''), username),
        display_name = COALESCE(NULLIF(p_display_name, ''), display_name),
        avatar_emoji = COALESCE(NULLIF(p_avatar_emoji, ''), avatar_emoji),
        avatar_url   = COALESCE(NULLIF(p_avatar_url, ''), avatar_url),
        last_seen_at = NOW()
    WHERE id = v_id;
  END IF;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION
  public.ensure_legacy_profile(TEXT, TEXT, TEXT, TEXT, TEXT)
  TO anon, authenticated, service_role;

-- ── 2. touch_legacy_presence: nur last_seen, kein Auto-Create ───────────
-- Wird vom Heartbeat-Ticker aufgerufen. Wenn kein Profil existiert,
-- passiert nichts (no-op). Verhindert Datenmuell durch reine App-Oeffner
-- ohne ausgefuelltes Profil.
CREATE OR REPLACE FUNCTION public.touch_legacy_presence(
  p_legacy_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated INTEGER;
BEGIN
  IF p_legacy_id IS NULL OR p_legacy_id = '' THEN
    RETURN false;
  END IF;

  UPDATE public.profiles
  SET last_seen_at = NOW()
  WHERE legacy_user_id = p_legacy_id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.touch_legacy_presence(TEXT)
  TO anon, authenticated, service_role;

-- ── 3. touch_auth_presence (Symmetrie fuer auth.uid()-User) ─────────────
-- Updated last_seen anhand der Session. Nur fuer eingeloggte User.
CREATE OR REPLACE FUNCTION public.touch_auth_presence()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated INTEGER;
  v_uid UUID;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN false;
  END IF;

  UPDATE public.profiles
  SET last_seen_at = NOW()
  WHERE id = v_uid;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.touch_auth_presence()
  TO authenticated, service_role;
