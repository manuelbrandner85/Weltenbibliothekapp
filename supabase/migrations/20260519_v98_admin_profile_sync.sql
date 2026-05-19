-- v98: Admin-Dashboard Verbesserungen.
-- 1. Auto-Profile-Erstellung fuer auth.users (Trigger)
-- 2. RPC ensure_profile fuer Legacy-User
-- 3. Komfort-Index auf last_seen_at

-- ── 1. Auto-Profile bei neuem auth.user ────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_username TEXT;
BEGIN
  -- Generiere Username aus user_metadata oder email-Prefix.
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'display_name',
    split_part(COALESCE(NEW.email, ''), '@', 1),
    'user_' || substring(NEW.id::text, 1, 8)
  );

  -- Idempotent: nur einfuegen wenn noch kein Profil existiert.
  INSERT INTO public.profiles (id, username, display_name, role, is_banned, created_at)
  VALUES (
    NEW.id,
    base_username,
    COALESCE(NEW.raw_user_meta_data->>'display_name', base_username),
    'user',
    false,
    COALESCE(NEW.created_at, NOW())
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- ── 2. RPC zum Anlegen/Updaten von InvisibleAuth-Profilen ────────────────
-- Wird vom UserPresenceService aufgerufen. Erstellt Profil falls fehlt
-- und aktualisiert last_seen_at.
CREATE OR REPLACE FUNCTION public.ensure_legacy_profile(
  p_legacy_id    TEXT,
  p_username     TEXT,
  p_display_name TEXT DEFAULT NULL
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

  -- Suche bestehenden Eintrag.
  SELECT id INTO v_id
  FROM public.profiles
  WHERE legacy_user_id = p_legacy_id
  LIMIT 1;

  IF v_id IS NULL THEN
    -- Neu anlegen.
    INSERT INTO public.profiles (
      id, username, display_name, role, is_banned,
      legacy_user_id, created_at, last_seen_at
    )
    VALUES (
      gen_random_uuid(),
      p_username,
      COALESCE(p_display_name, p_username),
      'user',
      false,
      p_legacy_id,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_id;
  ELSE
    -- Update last_seen_at + username falls geaendert.
    UPDATE public.profiles
    SET last_seen_at = NOW(),
        username = COALESCE(NULLIF(p_username, ''), username),
        display_name = COALESCE(NULLIF(p_display_name, ''), display_name)
    WHERE id = v_id;
  END IF;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_legacy_profile(TEXT, TEXT, TEXT)
  TO anon, authenticated, service_role;

-- ── 3. Komfort-Index ──────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_profiles_last_seen
  ON public.profiles(last_seen_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_profiles_legacy
  ON public.profiles(legacy_user_id)
  WHERE legacy_user_id IS NOT NULL;

-- ── 4. Backfill: existierende auth.users die kein profile haben ──────────
INSERT INTO public.profiles (id, username, display_name, role, is_banned, created_at)
SELECT
  u.id,
  COALESCE(
    u.raw_user_meta_data->>'username',
    split_part(COALESCE(u.email, ''), '@', 1),
    'user_' || substring(u.id::text, 1, 8)
  ) AS username,
  COALESCE(u.raw_user_meta_data->>'display_name',
           split_part(COALESCE(u.email, ''), '@', 1),
           'user_' || substring(u.id::text, 1, 8)) AS display_name,
  'user',
  false,
  u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;
