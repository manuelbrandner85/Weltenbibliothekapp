-- v46: Notification-Fixes
--
-- 1. trg_voice_session_joined: nutzte recipient_id statt user_id → INSERT fail
-- 2. community_posts: Likes/Kommentare → notification_queue (fehlten komplett)

-- ══════════════════════════════════════════════════════════════
-- FIX 1: Voice-Session-Trigger — recipient_id → user_id
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.trg_voice_session_joined()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_title TEXT;
  v_body  TEXT;
  v_rec   RECORD;
BEGIN
  v_title := COALESCE(NEW.display_name, 'Jemand') || ' ist jetzt live';
  v_body  := 'Raum: ' || NEW.room_name || ' — Jetzt beitreten!';

  -- Alle Profile der gleichen Welt benachrichtigen (außer dem Beitretenden selbst)
  FOR v_rec IN
    SELECT id FROM public.profiles
    WHERE (world = NEW.world OR world_preference = NEW.world)
      AND id IS DISTINCT FROM NEW.user_id
      AND (is_banned IS NULL OR is_banned = FALSE)
    LIMIT 200
  LOOP
    INSERT INTO public.notification_queue
      (user_id, title, body, data)
    VALUES (
      v_rec.id,
      v_title,
      v_body,
      jsonb_build_object(
        'type',     'voice_join',
        'roomName', NEW.room_name,
        'world',    NEW.world,
        'from_user_id', NEW.user_id
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_voice_session_joined ON public.voice_sessions;
CREATE TRIGGER trg_voice_session_joined
  AFTER INSERT ON public.voice_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_voice_session_joined();

-- ══════════════════════════════════════════════════════════════
-- FIX 2: community_posts — Likes + Kommentare → notification_queue
-- ══════════════════════════════════════════════════════════════

-- community_posts_likes Tabelle sicherstellen
CREATE TABLE IF NOT EXISTS public.community_post_likes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (post_id, user_id)
);
ALTER TABLE public.community_post_likes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "community_post_likes_all" ON public.community_post_likes;
CREATE POLICY "community_post_likes_all" ON public.community_post_likes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "community_post_likes_read" ON public.community_post_likes;
CREATE POLICY "community_post_likes_read" ON public.community_post_likes
  FOR SELECT USING (true);

-- Trigger: community_post Like → Notification
CREATE OR REPLACE FUNCTION public.notify_on_community_post_like()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_author UUID;
  v_liker  TEXT;
BEGIN
  SELECT user_id INTO v_author FROM public.community_posts WHERE id = NEW.post_id;
  SELECT username INTO v_liker FROM public.profiles WHERE id = NEW.user_id;

  IF v_author IS NOT NULL AND v_author IS DISTINCT FROM NEW.user_id THEN
    INSERT INTO public.notification_queue (user_id, title, body, data)
    VALUES (
      v_author,
      '❤️ Neues Like',
      COALESCE(v_liker, 'Jemand') || ' mag deinen Community-Beitrag',
      jsonb_build_object('type', 'like', 'post_id', NEW.post_id, 'from_user_id', NEW.user_id)
    );
    UPDATE public.community_posts SET likes_count = GREATEST(0, likes_count + 1) WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_community_post_like ON public.community_post_likes;
CREATE TRIGGER trg_community_post_like
  AFTER INSERT ON public.community_post_likes
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_community_post_like();

-- Trigger: community_post Kommentar → Notification (via chat_messages mit room = post_id)
CREATE OR REPLACE FUNCTION public.notify_on_community_post_comment()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_post_author UUID;
  v_commenter   TEXT;
BEGIN
  -- Kommentare werden in community_posts.comments_count getrackt; Post-Author benachrichtigen
  IF NEW.parent_id IS NOT NULL THEN
    SELECT cp.user_id INTO v_post_author
      FROM public.community_posts cp
      WHERE cp.id = NEW.parent_id::UUID;

    SELECT username INTO v_commenter FROM public.profiles WHERE id = NEW.user_id;

    IF v_post_author IS NOT NULL AND v_post_author IS DISTINCT FROM NEW.user_id THEN
      INSERT INTO public.notification_queue (user_id, title, body, data)
      VALUES (
        v_post_author,
        '💬 Neuer Kommentar',
        COALESCE(v_commenter, 'Jemand') || ' hat deinen Beitrag kommentiert',
        jsonb_build_object('type', 'comment', 'post_id', NEW.parent_id, 'from_user_id', NEW.user_id)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_community_post_comment ON public.community_posts;
CREATE TRIGGER trg_community_post_comment
  AFTER INSERT ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_community_post_comment();
