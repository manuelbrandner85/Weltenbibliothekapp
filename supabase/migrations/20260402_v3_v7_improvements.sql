-- ================================================================
-- Migration: V3-V7 Security & Feature Improvements
-- Date: 2026-04-02
-- ================================================================

-- ================================================================
-- V3: profiles RLS – Update-Policy für eigenen Datensatz
-- ================================================================
DROP POLICY IF EXISTS "public read" ON profiles;
DROP POLICY IF EXISTS "profiles_public_read" ON profiles;
DROP POLICY IF EXISTS "profiles_public_select" ON profiles;
DROP POLICY IF EXISTS "update own" ON profiles;
DROP POLICY IF EXISTS "profiles_owner_update" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;

CREATE POLICY "profiles_public_select" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "profiles_owner_update" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ================================================================
-- V4: chat_messages – Realtime-freundliche SELECT-Policy
-- ================================================================
DROP POLICY IF EXISTS "public read" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_select" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_soft_delete" ON chat_messages;

CREATE POLICY "chat_messages_select" ON chat_messages
  FOR SELECT USING (is_deleted = false);

CREATE POLICY "chat_messages_insert" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "chat_messages_soft_delete" ON chat_messages
  FOR UPDATE USING (auth.uid() = user_id);

-- ================================================================
-- V5: notifications – type CHECK Constraint erweitern
-- ================================================================
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
  CHECK (type IN ('like','comment','follow','mention','system','message','achievement'));

-- ================================================================
-- V6: articles – RLS für Auth-only INSERT
-- ================================================================
DROP POLICY IF EXISTS "public read" ON articles;
DROP POLICY IF EXISTS "articles_public_read" ON articles;
DROP POLICY IF EXISTS "insert" ON articles;
DROP POLICY IF EXISTS "articles_insert" ON articles;
DROP POLICY IF EXISTS "articles_auth_insert" ON articles;
DROP POLICY IF EXISTS "update own" ON articles;
DROP POLICY IF EXISTS "articles_owner_update" ON articles;
DROP POLICY IF EXISTS "articles_owner_delete" ON articles;

CREATE POLICY "articles_public_read" ON articles
  FOR SELECT USING (is_published = true);

CREATE POLICY "articles_auth_insert" ON articles
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "articles_owner_update" ON articles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "articles_owner_delete" ON articles
  FOR DELETE USING (auth.uid() = user_id);

-- ================================================================
-- V7: Storage – Upload-Policies für auth. User
-- ================================================================
-- avatars bucket
DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
DROP POLICY IF EXISTS "avatars_auth_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_delete" ON storage.objects;
-- media bucket
DROP POLICY IF EXISTS "media_public_read" ON storage.objects;
DROP POLICY IF EXISTS "media_auth_insert" ON storage.objects;
DROP POLICY IF EXISTS "media_owner_delete" ON storage.objects;

CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_auth_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() IS NOT NULL);

CREATE POLICY "avatars_owner_update" ON storage.objects
  FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_owner_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "media_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'media');

CREATE POLICY "media_auth_insert" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'media' AND auth.uid() IS NOT NULL);

CREATE POLICY "media_owner_delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'media' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ================================================================
-- V9: Supabase Edge Function trigger – Notifications bei Events
-- Wird als separate Edge Function deployt
-- ================================================================
-- Trigger: Bei neuem like → Notification erstellen
CREATE OR REPLACE FUNCTION notify_on_like()
RETURNS TRIGGER AS $$
DECLARE
  article_author_id UUID;
BEGIN
  SELECT user_id INTO article_author_id FROM articles WHERE id = NEW.article_id;
  IF article_author_id IS NOT NULL AND article_author_id != NEW.user_id THEN
    INSERT INTO notifications (user_id, type, title, message, data)
    VALUES (
      article_author_id,
      'like',
      'Neues Like',
      'Jemand hat deinen Artikel geliked',
      jsonb_build_object('article_id', NEW.article_id, 'from_user_id', NEW.user_id)
    ) ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_like_notify ON likes;
CREATE TRIGGER on_like_notify
  AFTER INSERT ON likes
  FOR EACH ROW EXECUTE FUNCTION notify_on_like();

-- Trigger: Bei neuem Kommentar → Notification
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  article_author_id UUID;
BEGIN
  SELECT user_id INTO article_author_id FROM articles WHERE id = NEW.article_id;
  IF article_author_id IS NOT NULL AND article_author_id != NEW.user_id THEN
    INSERT INTO notifications (user_id, type, title, message, data)
    VALUES (
      article_author_id,
      'comment',
      'Neuer Kommentar',
      NEW.username || ' hat deinen Artikel kommentiert',
      jsonb_build_object('article_id', NEW.article_id, 'comment_id', NEW.id)
    ) ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_comment_notify ON comments;
CREATE TRIGGER on_comment_notify
  AFTER INSERT ON comments
  FOR EACH ROW EXECUTE FUNCTION notify_on_comment();
