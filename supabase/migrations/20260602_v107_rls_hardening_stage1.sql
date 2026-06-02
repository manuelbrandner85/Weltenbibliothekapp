-- ══════════════════════════════════════════════════════════════════════════
-- MIGRATION v107 -- RLS-Haertung Stufe 1 (Impersonation-Loecher schliessen)
-- ══════════════════════════════════════════════════════════════════════════
--
-- Voraussetzung: PR #210 (Auth-Identitaets-Vereinheitlichung) -- die App
-- schreibt jetzt auth.uid() als kanonische user_id. Damit sind
-- auth.uid()=user_id-Policies durchsetzbar.
--
-- Diese Stufe behandelt NUR uuid-keyed Tabellen, bei denen der Client
-- nachweislich user_id = auth.uid() setzt (verifiziert in supabase_service.dart,
-- community_service.dart, vorhang/ursprung_community_tab.dart). Daher sind die
-- strengeren Policies fuer legitime Flows transparent.
--
-- Enthaelt:
--   1) community_posts -- INSERT/UPDATE/DELETE waren USING/CHECK (true):
--      jeder konnte fremde Posts bearbeiten/loeschen. Jetzt Ownership.
--   2) likes / message_reactions -- redundante anon_insert/anon_delete (true)
--      hebelten die strengen Owner-Policies aus (RLS ist permissiv/OR).
--      Entfernt; die strengen *_auth_insert / *_owner_delete bleiben aktiv.
--
-- Bewusst NICHT enthalten (spaetere Stufen): text-keyed user_id-Tabellen,
-- Gamification-System-Inserts (user_stats/user_achievements), chat_messages,
-- SECURITY DEFINER View, Storage-Bucket-Listing.
--
-- Idempotent durchfuehrbar.
-- ══════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────
-- 1) community_posts: Ownership erzwingen (war: true)
-- ─────────────────────────────────────────────────────────────────────────
drop policy if exists community_posts_insert_own on public.community_posts;
create policy community_posts_insert_own on public.community_posts
  for insert to public
  with check (auth.uid() = user_id);

drop policy if exists community_posts_update_own on public.community_posts;
create policy community_posts_update_own on public.community_posts
  for update to public
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists community_posts_delete_own on public.community_posts;
create policy community_posts_delete_own on public.community_posts
  for delete to public
  using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────
-- 2) likes / message_reactions: redundante "true"-Duplikate entfernen
--    (die strengen Owner-/Auth-Policies bleiben bestehen)
-- ─────────────────────────────────────────────────────────────────────────
drop policy if exists anon_insert on public.likes;
drop policy if exists anon_delete on public.likes;

drop policy if exists anon_insert on public.message_reactions;
drop policy if exists anon_delete on public.message_reactions;
