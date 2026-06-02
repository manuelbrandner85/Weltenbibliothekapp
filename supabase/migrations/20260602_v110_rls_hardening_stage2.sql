-- ======================================================================
-- MIGRATION v110 -- RLS-Haertung Stufe 2 (text-typed user_id Tabellen)
-- ======================================================================
--
-- 18 Tabellen haben user_id TEXT statt UUID. Alle USING(true)/WITH CHECK(true)
-- Policies werden auf auth.uid()::text = user_id gehaertet.
--
-- Voraussetzung: PR #210 (Auth-Refactor) ist gemergt -- InvisibleAuthService
-- liefert jetzt auth.uid() (Supabase-UUID) als userId. Alle neuen Schreibzugriffe
-- setzen user_id = auth.uid()::text, der Cast in der Policy passt.
--
-- Datenlage (geprueft via SQL):
--   spirit_readings: 4 Zeilen mit Legacy-ID (user_<ts>_<rand>) -- werden
--     zu orphaned rows (schon jetzt unzugreifbar nach Auth-Migration).
--     Alle anderen Text-Tabellen: 0 Zeilen oder bereits UUID-Format.
--
-- Bewusst NICHT geaendert:
--   user_reports.user_reports_insert_anon (true): Absichtlich offen --
--     jeder kann eine Meldung einreichen (anonym-tauglich).
--   user_research_pins.pins_update_own (true): Deferred -- der Vote-
--     Aggregat-Writer ist der Voter, nicht der Pin-Owner. Hardening
--     benoetigt eigene SECURITY DEFINER Funktion (naechste Stufe).
--   *_read SELECT (true): Oeffentliche Leaderboard/Frequenz/Edge-Daten
--     bleiben weltoeffentlich lesbar (Leaderboard-Feature).
--
-- Idempotent durchfuehrbar.
-- ======================================================================

-- ─────────────────────────────────────────────────────────────────────
-- 1) biometric_data_cache
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists bio_own on public.biometric_data_cache;
create policy bio_own on public.biometric_data_cache
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 2) bookmark_collections
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists coll_own on public.bookmark_collections;
create policy coll_own on public.bookmark_collections
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 3) destiny_weekly_draws
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists dwd_own on public.destiny_weekly_draws;
create policy dwd_own on public.destiny_weekly_draws
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 4) frequency_presets  (lb_read SELECT bleibt true)
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists freq_write on public.frequency_presets;
create policy freq_write on public.frequency_presets
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 5) leaderboard_weekly  (lb_read SELECT bleibt true)
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists lb_write on public.leaderboard_weekly;
create policy lb_write on public.leaderboard_weekly
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 6) manifestation_goals
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists manifest_own on public.manifestation_goals;
create policy manifest_own on public.manifestation_goals
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 7) propaganda_bias_history
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists bias_hist_all on public.propaganda_bias_history;
create policy bias_hist_all on public.propaganda_bias_history
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 8) rv_target_guesses
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists rv_guesses_all on public.rv_target_guesses;
create policy rv_guesses_all on public.rv_target_guesses
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 9) spirit_readings
--    Hinweis: 4 Zeilen mit Legacy-IDs (user_<ts>_<rand>) werden orphaned.
--    Diese Rows sind nach Auth-Refactor (PR #210) bereits unzugreifbar.
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists readings_own on public.spirit_readings;
create policy readings_own on public.spirit_readings
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 10) user_annotations
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists ann_own on public.user_annotations;
create policy ann_own on public.user_annotations
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 11) user_edge_confidence  (edge_conf_read SELECT bleibt true)
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists edge_conf_write_own on public.user_edge_confidence;
create policy edge_conf_write_own on public.user_edge_confidence
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 12) user_notification_prefs
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists notif_prefs_own on public.user_notification_prefs;
create policy notif_prefs_own on public.user_notification_prefs
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 13) user_power_spots  (power_spots_read SELECT bleibt is_public=true)
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists power_spots_write on public.user_power_spots;
create policy power_spots_write on public.user_power_spots
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 14) user_research_pin_votes
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists pin_votes_all on public.user_research_pin_votes;
create policy pin_votes_all on public.user_research_pin_votes
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 15) vorhang_branch_boss_attempts
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists boss_att_own on public.vorhang_branch_boss_attempts;
create policy boss_att_own on public.vorhang_branch_boss_attempts
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);

-- ─────────────────────────────────────────────────────────────────────
-- 16) vorhang_lesson_notes
-- ─────────────────────────────────────────────────────────────────────
drop policy if exists notes_own on public.vorhang_lesson_notes;
create policy notes_own on public.vorhang_lesson_notes
  for all to public
  using  (auth.uid()::text = user_id)
  with check (auth.uid()::text = user_id);
