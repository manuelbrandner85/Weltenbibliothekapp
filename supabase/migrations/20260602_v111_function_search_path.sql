-- ======================================================================
-- MIGRATION v111 -- search_path-Haertung aller eigenen Funktionen
-- ======================================================================
--
-- Advisor-WARN function_search_path_mutable: 34 eigene Funktionen (20
-- SECURITY DEFINER + 14 Trigger-Util) hatten keinen festen search_path.
--
-- Risiko: Bei SECURITY DEFINER laeuft die Funktion mit Rechten des
-- Owners (postgres/supabase_admin). Ohne festen search_path kann ein
-- Angreifer den Session-search_path manipulieren und unqualifizierte
-- Objektreferenzen (z.B. profiles, user_achievements) auf eigene Objekte
-- in einem von ihm kontrollierten Schema umbiegen -> Code-Execution mit
-- Owner-Rechten (Privilege Escalation).
--
-- Fix: SET search_path = public, pg_temp. Pinnt den Pfad auf 'public'
-- (identische Aufloesung wie bisher, kein Verhaltensbruch) und macht ihn
-- per-Call immutable. pg_temp zuletzt = sichere Reihenfolge (Temp-Objekte
-- koennen public nicht shadowen). pg_catalog ist implizit immer zuerst.
--
-- Extension-Funktionen (pg_trgm: gtrgm_*, gin_*, similarity*, word_*)
-- bewusst ausgeschlossen -- die gehoeren der Extension, nicht uns.
--
-- Idempotent (ALTER ... SET ist wiederholbar).
-- ======================================================================

-- ── SECURITY DEFINER Funktionen (20) ─────────────────────────────────
alter function public.add_user_xp(uuid, text, integer)                          set search_path = public, pg_temp;
alter function public.delete_chat_message(uuid, uuid)                           set search_path = public, pg_temp;
alter function public.edit_chat_message(uuid, text, uuid)                       set search_path = public, pg_temp;
alter function public.fn_insert_notification_both(uuid, text, text, text, jsonb) set search_path = public, pg_temp;
alter function public.fn_notify_follow()                                        set search_path = public, pg_temp;
alter function public.fn_notify_mention()                                       set search_path = public, pg_temp;
alter function public.fn_notify_new_article()                                   set search_path = public, pg_temp;
alter function public.fn_notify_reply()                                         set search_path = public, pg_temp;
alter function public.fn_unlock_achievement(uuid, text, text, text)             set search_path = public, pg_temp;
alter function public.handle_new_user()                                         set search_path = public, pg_temp;
alter function public.log_profile_role_change()                                 set search_path = public, pg_temp;
alter function public.mark_message_as_read(text, text)                          set search_path = public, pg_temp;
alter function public.mark_room_messages_as_read(text, text)                    set search_path = public, pg_temp;
alter function public.notify_on_comment()                                       set search_path = public, pg_temp;
alter function public.notify_on_community_post_comment()                        set search_path = public, pg_temp;
alter function public.notify_on_community_post_like()                           set search_path = public, pg_temp;
alter function public.notify_on_like()                                          set search_path = public, pg_temp;
alter function public.on_unlike()                                               set search_path = public, pg_temp;
alter function public.recompute_annotation_votes()                              set search_path = public, pg_temp;
alter function public.trg_voice_session_joined()                                set search_path = public, pg_temp;

-- ── Trigger-Util Funktionen (14, SECURITY INVOKER) ───────────────────
alter function public.app_config_touch_updated_at()                             set search_path = public, pg_temp;
alter function public.enforce_username_immutability()                           set search_path = public, pg_temp;
alter function public.handle_updated_at()                                       set search_path = public, pg_temp;
alter function public.mentor_sessions_updated_at()                              set search_path = public, pg_temp;
alter function public.prevent_admin_web_access_insert()                         set search_path = public, pg_temp;
alter function public.set_chat_read_receipts_updated_at()                       set search_path = public, pg_temp;
alter function public.set_community_posts_updated_at()                          set search_path = public, pg_temp;
alter function public.set_kg_updated_at()                                       set search_path = public, pg_temp;
alter function public.set_updated_at()                                          set search_path = public, pg_temp;
alter function public.set_user_tool_data_updated_at()                           set search_path = public, pg_temp;
alter function public.touch_saved_threads()                                     set search_path = public, pg_temp;
alter function public.trg_user_avatar_updated()                                 set search_path = public, pg_temp;
alter function public.update_room_message_count()                               set search_path = public, pg_temp;
alter function public.update_web_user_profiles_updated_at()                     set search_path = public, pg_temp;
