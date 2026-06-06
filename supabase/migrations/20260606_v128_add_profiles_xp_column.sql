-- v128: profiles.xp Spalte ergaenzen.
--
-- Der gesamte Server-XP-Pfad (add_user_xp RPC, Worker /admin/users/:id/xp
-- Endpoint inkl. Fallback-PATCH, Worker user-detail select=xp) erwartet
-- profiles.xp -- die Spalte existierte aber nie. Dadurch schlug jede
-- Admin-XP-Vergabe fehl ("column profiles.xp does not exist"). Die
-- alternative player_progress-Tabelle ist tot (0 Zeilen, FK auf
-- auth.users den InvisibleAuth-User nicht haben). profiles.xp ist die
-- konsistente Server-Quelle -- additive Spalte, bricht nichts.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS xp INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.profiles.xp IS
  'Server-seitiger XP-Zaehler (v128). Wird von add_user_xp RPC + Admin-XP-Endpoint gepflegt.';
