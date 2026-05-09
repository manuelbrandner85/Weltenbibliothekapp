-- ============================================================
-- Weltenbibliothek – Migration 003: Storage
-- ============================================================

-- Avatars bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  TRUE,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Media bucket (images in articles/chat)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'media',
  'media',
  TRUE,
  10485760, -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml']
) ON CONFLICT (id) DO NOTHING;

-- Storage policies: avatars
DROP POLICY IF EXISTS "avatars_public_read" ON public.storage;
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_own_upload" ON public.storage;
CREATE POLICY "avatars_own_upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "avatars_own_update" ON public.storage;
CREATE POLICY "avatars_own_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "avatars_own_delete" ON public.storage;
CREATE POLICY "avatars_own_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Storage policies: media
DROP POLICY IF EXISTS "media_public_read" ON public.storage;
CREATE POLICY "media_public_read"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'media');

DROP POLICY IF EXISTS "media_authenticated_upload" ON public.storage;
CREATE POLICY "media_authenticated_upload"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'media');
