-- ======================================================================
-- MIGRATION v109 -- RLS-Haertung Stufe 3 (Gamification-INSERT-Luecken)
-- ======================================================================
--
-- Problem: drei Tabellen haben INSERT WITH CHECK (true), obwohl alle
-- legitimen Schreibpfade RLS umgehen und die Policy nicht benoetigen:
--
--   user_stats:        add_user_xp()         -- SECURITY DEFINER
--   user_achievements: fn_unlock_achievement() -- SECURITY DEFINER
--   notifications:     Worker via SERVICE_ROLE -- bypasses RLS vollstaendig
--
-- Konsequenz der offenen Policies: jeder anon-User kann beliebige XP-
-- Werte, Achievements und Notifications fuer fremde User-IDs einspielen
-- (XP-Farming, Achievement-Manipulation, Notification-Spam).
--
-- Zusaetzlich entfernt: redundante Duplikat-Policies und fehlendes
-- WITH CHECK in stats_owner_update.
--
-- Idempotent durchfuehrbar.
-- ======================================================================

-- ─────────────────────────────────────────────────────────────────────
-- 1) user_stats: system_insert (true) entfernen
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists stats_system_insert on public.user_stats;

-- stats_owner_update hatte kein WITH CHECK -- fehlende Spalten-Integritaet
drop policy if exists stats_owner_update on public.user_stats;
create policy stats_owner_update on public.user_stats
  for update to public
  using  (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Duplikat: stats_public_select == public_read (beide USING true)
drop policy if exists stats_public_select on public.user_stats;

-- ─────────────────────────────────────────────────────────────────────
-- 2) user_achievements: system_insert (true) entfernen
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists achievements_system_insert on public.user_achievements;

-- Duplikat: achievements_owner_select ist Teilmenge von user_achievements_own (ALL)
drop policy if exists achievements_owner_select on public.user_achievements;

-- ─────────────────────────────────────────────────────────────────────
-- 3) notifications: system_insert (true) entfernen
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists notifications_system_insert on public.notifications;

-- Duplikate: *_own_read == *_owner_select, *_own_update == *_owner_update
drop policy if exists notifications_owner_select on public.notifications;
drop policy if exists notifications_owner_update on public.notifications;
