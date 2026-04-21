-- ============================================================================
-- v41 – Vollständiges Notification-System
-- Alle Trigger + neue Tabellen für Push-Delivery (auch bei geschlossener App)
-- Idempotent (IF NOT EXISTS / CREATE OR REPLACE) — sicher bei Mehrfachausführung
-- ============================================================================

-- ─── 1. user_achievements — welche Achievements hat ein User schon ───────────
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  unlocked_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "user_achievements_own"
  ON public.user_achievements FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user
  ON public.user_achievements(user_id);

-- ─── 2. followers ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.followers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "followers_select"
  ON public.followers FOR SELECT TO authenticated
  USING (auth.uid() = follower_id OR auth.uid() = following_id);
CREATE POLICY IF NOT EXISTS "followers_insert"
  ON public.followers FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = follower_id);
CREATE POLICY IF NOT EXISTS "followers_delete"
  ON public.followers FOR DELETE TO authenticated
  USING (auth.uid() = follower_id);
CREATE INDEX IF NOT EXISTS idx_followers_follower ON public.followers(follower_id);
CREATE INDEX IF NOT EXISTS idx_followers_following ON public.followers(following_id);

-- ─── 3. world_subscriptions — Artikel-Alerts pro Welt ─────────────────────
CREATE TABLE IF NOT EXISTS public.world_subscriptions (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  world      TEXT NOT NULL CHECK (world IN ('materie', 'energie')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, world)
);
ALTER TABLE public.world_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "world_subs_own"
  ON public.world_subscriptions FOR ALL TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX IF NOT EXISTS idx_world_subs_world ON public.world_subscriptions(world);

-- ─── Helper: beide Tabellen gleichzeitig befüllen ──────────────────────────
-- Wird von allen Triggern verwendet um Doppel-Code zu vermeiden.
CREATE OR REPLACE FUNCTION fn_insert_notification_both(
  p_user_id   UUID,
  p_type      TEXT,
  p_title     TEXT,
  p_body      TEXT,
  p_data      JSONB
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- 1. In-App NotificationCenter
  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (p_user_id, p_type, p_title, p_body, p_data)
  ON CONFLICT DO NOTHING;
  -- 2. FCM-Delivery-Queue (auch bei geschlossener App)
  INSERT INTO public.notification_queue (user_id, title, body, data)
  VALUES (p_user_id, p_title, p_body, p_data);
END;
$$;

-- ─── 4. Like → notification_queue (bisher nur notifications) ──────────────
CREATE OR REPLACE FUNCTION notify_on_like() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_author UUID; v_name TEXT;
BEGIN
  SELECT a.user_id, p.username
    INTO v_author, v_name
    FROM articles a
    LEFT JOIN profiles p ON p.id = NEW.user_id
   WHERE a.id = NEW.article_id;

  IF v_author IS NOT NULL AND v_author != COALESCE(NEW.user_id, '00000000-0000-0000-0000-000000000000') THEN
    PERFORM fn_insert_notification_both(
      v_author, 'like',
      '❤️ Neues Like',
      COALESCE(v_name, 'Jemand') || ' mag deinen Beitrag',
      jsonb_build_object('type','like','article_id',NEW.article_id,'from_user_id',NEW.user_id)
    );
    UPDATE articles SET like_count = like_count + 1 WHERE id = NEW.article_id;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_like_notify ON public.likes;
CREATE TRIGGER on_like_notify
  AFTER INSERT ON public.likes
  FOR EACH ROW EXECUTE FUNCTION notify_on_like();

-- ─── 5. Comment → notification_queue ──────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_on_comment() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_author UUID;
BEGIN
  SELECT user_id INTO v_author FROM articles WHERE id = NEW.article_id;
  IF v_author IS NOT NULL AND v_author != COALESCE(NEW.user_id, '00000000-0000-0000-0000-000000000000') THEN
    PERFORM fn_insert_notification_both(
      v_author, 'message',
      '💬 Neuer Kommentar',
      COALESCE(NEW.username, 'Jemand') || ' hat deinen Beitrag kommentiert',
      jsonb_build_object('type','comment','article_id',NEW.article_id,'comment_id',NEW.id)
    );
    UPDATE articles SET comment_count = comment_count + 1 WHERE id = NEW.article_id;
  END IF;
  RETURN NEW;
END;
$$;
-- Trigger bleibt unverändert, nur Funktion wurde erweitert

-- ─── 6. Chat @Mention → sofortiger Push ──────────────────────────────────
CREATE OR REPLACE FUNCTION fn_notify_mention() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_mention     TEXT;
  v_target_id   UUID;
  v_msg         TEXT;
BEGIN
  v_msg := COALESCE(NEW.content, NEW.message, '');
  -- Alle @username Patterns extrahieren
  FOR v_mention IN
    SELECT DISTINCT (regexp_matches(v_msg, '@([A-Za-z0-9_äöüÄÖÜß]+)', 'g'))[1]
  LOOP
    SELECT id INTO v_target_id
      FROM profiles WHERE username = v_mention LIMIT 1;

    IF v_target_id IS NOT NULL
       AND v_target_id::TEXT != COALESCE(NEW.user_id::TEXT, '')
    THEN
      PERFORM fn_insert_notification_both(
        v_target_id, 'message',
        '📣 ' || COALESCE(NEW.username, 'Jemand') || ' hat dich erwähnt',
        LEFT(v_msg, 120),
        jsonb_build_object('type','mention','room_id',NEW.room_id,'message_id',NEW.id,'sender',NEW.username)
      );
    END IF;
  END LOOP;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_chat_mention ON public.chat_messages;
CREATE TRIGGER on_chat_mention
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION fn_notify_mention();

-- ─── 7. Chat Reply → Push an Original-Autor ───────────────────────────────
CREATE OR REPLACE FUNCTION fn_notify_reply() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_author_id UUID;
BEGIN
  IF NEW.reply_to_id IS NULL THEN RETURN NEW; END IF;

  -- Suche Original-Autor via reply_to_sender_name (Snapshot) in profiles
  IF NEW.reply_to_sender_name IS NOT NULL THEN
    SELECT id INTO v_author_id
      FROM profiles WHERE username = NEW.reply_to_sender_name LIMIT 1;
  END IF;

  -- Fallback: direkt aus der Original-Nachricht + profiles
  IF v_author_id IS NULL THEN
    SELECT p.id INTO v_author_id
      FROM chat_messages cm
      JOIN profiles p ON p.username = cm.username
     WHERE cm.id = NEW.reply_to_id LIMIT 1;
  END IF;

  IF v_author_id IS NOT NULL
     AND v_author_id::TEXT != COALESCE(NEW.user_id::TEXT, '')
  THEN
    PERFORM fn_insert_notification_both(
      v_author_id, 'message',
      '↩️ ' || COALESCE(NEW.username, 'Jemand') || ' hat geantwortet',
      LEFT(COALESCE(NEW.content, NEW.message, ''), 120),
      jsonb_build_object('type','reply','room_id',NEW.room_id,'message_id',NEW.id,'reply_to_id',NEW.reply_to_id)
    );
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_chat_reply ON public.chat_messages;
CREATE TRIGGER on_chat_reply
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION fn_notify_reply();

-- ─── 8. Follow → Push an gefolgter Person ────────────────────────────────
CREATE OR REPLACE FUNCTION fn_notify_follow() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  SELECT username INTO v_name FROM profiles WHERE id = NEW.follower_id;
  PERFORM fn_insert_notification_both(
    NEW.following_id, 'follow',
    '👤 Neuer Follower',
    COALESCE(v_name, 'Jemand') || ' folgt dir jetzt',
    jsonb_build_object('type','follow','follower_id',NEW.follower_id,'follower_name',v_name)
  );
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_follow_notify ON public.followers;
CREATE TRIGGER on_follow_notify
  AFTER INSERT ON public.followers
  FOR EACH ROW EXECUTE FUNCTION fn_notify_follow();

-- ─── 9. Neuer Artikel → Push an Welt-Abonnenten ──────────────────────────
CREATE OR REPLACE FUNCTION fn_notify_new_article() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_uid UUID;
BEGIN
  -- Nur wenn is_published gerade auf true kippt
  IF NOT (NEW.is_published = TRUE
          AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND (OLD.is_published IS DISTINCT FROM TRUE))))
  THEN RETURN NEW; END IF;

  FOR v_uid IN
    SELECT ws.user_id FROM world_subscriptions ws
     WHERE ws.world = NEW.world
       AND ws.user_id IS DISTINCT FROM NEW.user_id
  LOOP
    PERFORM fn_insert_notification_both(
      v_uid, 'system',
      '📰 Neuer Artikel · ' || CASE WHEN NEW.world = 'energie' THEN 'Energie' ELSE 'Materie' END,
      COALESCE(NEW.title, 'Neuer Artikel verfügbar'),
      jsonb_build_object('type','new_article','article_id',NEW.id,'world',NEW.world)
    );
  END LOOP;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_article_published ON public.articles;
CREATE TRIGGER on_article_published
  AFTER INSERT OR UPDATE ON public.articles
  FOR EACH ROW EXECUTE FUNCTION fn_notify_new_article();

-- ─── 10. Achievement-Unlock Hilfsfunktion (aufgerufen via Worker/RPC) ────
CREATE OR REPLACE FUNCTION fn_unlock_achievement(
  p_user_id      UUID,
  p_achievement_id TEXT,
  p_title        TEXT,
  p_icon         TEXT
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Idempotent: zweiter Aufruf macht nichts
  INSERT INTO user_achievements (user_id, achievement_id)
  VALUES (p_user_id, p_achievement_id)
  ON CONFLICT (user_id, achievement_id) DO NOTHING;

  IF NOT FOUND THEN RETURN FALSE; END IF; -- bereits freigeschaltet

  PERFORM fn_insert_notification_both(
    p_user_id, 'achievement',
    '🏆 Achievement freigeschaltet!',
    p_icon || ' ' || p_title,
    jsonb_build_object('type','achievement','achievement_id',p_achievement_id)
  );
  RETURN TRUE;
END;
$$;
-- RPC darf vom authentifizierten User aus Dart aufgerufen werden
REVOKE ALL ON FUNCTION fn_unlock_achievement(UUID, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION fn_unlock_achievement(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- ─── Index für schnelle Notification-Abfragen ──────────────────────────────
CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON public.notifications(user_id, created_at DESC)
  WHERE read_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_notif_queue_pending
  ON public.notification_queue(created_at ASC)
  WHERE status = 'pending';
