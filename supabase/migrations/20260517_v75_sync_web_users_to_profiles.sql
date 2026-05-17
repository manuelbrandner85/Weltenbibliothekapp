-- ══════════════════════════════════════════════════════════════════════════════
-- v75 — SYNC WEB-USERS NACH PROFILES
-- ──────────────────────────────────────────────────────────────────────────────
-- Web-User wurden bisher NUR in web_access_requests gespeichert. Sie tauchten
-- daher nicht im Admin-Dashboard auf, das aus profiles liest.
--
-- Diese Migration legt für jeden approved web_access_requests-Eintrag ein
-- profiles-Datensatz an, sofern noch nicht vorhanden (per username).
-- Idempotent: ON CONFLICT (id) DO NOTHING + WHERE NOT EXISTS.
--
-- Ab jetzt (siehe web_login_screen.dart) wird jeder Web-Login auch in
-- profiles via Worker /api/profile/materie geschrieben.
-- ══════════════════════════════════════════════════════════════════════════════

INSERT INTO public.profiles (id, username, display_name, world, role, is_banned, created_at, updated_at)
SELECT
  gen_random_uuid(),
  w.display_name,
  w.display_name,
  'materie',  -- Default-Welt; User können das später ändern
  'user',
  false,
  COALESCE(w.requested_at, now()),
  now()
FROM public.web_access_requests w
WHERE w.status = 'approved'
  AND NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE lower(p.username) = lower(w.display_name)
  );
