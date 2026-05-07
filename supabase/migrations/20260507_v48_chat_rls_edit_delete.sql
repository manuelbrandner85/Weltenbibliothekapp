-- v48: Chat-Nachrichten RLS für direkte Supabase UPDATE/DELETE
-- Edit und Delete laufen nicht mehr über den Cloudflare Worker,
-- sondern direkt via Supabase Client mit auth.uid() Ownership-Check.

-- ── UPDATE-Policy: User darf eigene Nachrichten bearbeiten ──────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'chat_messages'
      AND policyname = 'users_can_edit_own_messages'
  ) THEN
    CREATE POLICY users_can_edit_own_messages ON public.chat_messages
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ── DELETE-Policy: User darf eigene Nachrichten löschen ─────────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'chat_messages'
      AND policyname = 'users_can_delete_own_messages'
  ) THEN
    CREATE POLICY users_can_delete_own_messages ON public.chat_messages
      FOR DELETE
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- ── Admin-Policy: Admins dürfen alle Nachrichten löschen ────────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'chat_messages'
      AND policyname = 'admins_can_delete_any_message'
  ) THEN
    CREATE POLICY admins_can_delete_any_message ON public.chat_messages
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'superadmin', 'root')
        )
      );
  END IF;
END $$;

-- ── Admin-Policy: Admins dürfen alle Nachrichten bearbeiten ─────────────────
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'chat_messages'
      AND policyname = 'admins_can_edit_any_message'
  ) THEN
    CREATE POLICY admins_can_edit_any_message ON public.chat_messages
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'superadmin', 'root')
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'superadmin', 'root')
        )
      );
  END IF;
END $$;

-- Sicherstellen dass RLS aktiviert ist
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
