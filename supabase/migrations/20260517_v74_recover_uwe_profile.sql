-- ══════════════════════════════════════════════════════════════════════════════
-- v74 — RECOVER USER PROFILE FROM ABANDONED zctuf PROJECT
-- ──────────────────────────────────────────────────────────────────────────────
-- Während der versehentlichen Migration zu zctufcfjsixfgmmwvnmv (Commit 1bf45a5)
-- hat sich genau ein realer User registriert: "the Sound of 80er" (Uwe Vetter).
-- Bei der Rück-Migration (Commit 173c8b1) ging dieses Profile verloren.
-- Diese Migration legt das Profile in adtv wieder an, idempotent.
--
-- Quelle: zctufcfjsixfgmmwvnmv.supabase.co/rest/v1/profiles?id=eq.34fc7544-...
-- Felder DROPpen: name, password, world_preference, is_verified, avatar_url
--   - name/password/world_preference/is_verified existieren nicht in adtv-Schema
--   - avatar_url war ein lokaler Android-Pfad (ungültig), User lädt bei nächstem
--     App-Start neuen Avatar hoch
-- ══════════════════════════════════════════════════════════════════════════════

INSERT INTO public.profiles (id, username, world, role, is_banned, created_at, updated_at)
VALUES (
  '34fc7544-4486-4da2-aeb8-f06fbb57bfa0',
  'the Sound of 80er',
  'materie',
  'user',
  false,
  '2026-05-16T10:38:27.007681+00:00',
  now()
)
ON CONFLICT (id) DO NOTHING;
