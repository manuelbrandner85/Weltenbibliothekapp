-- ════════════════════════════════════════════════════════════════════════
-- v42 — community_posts Tabelle anlegen (fehlte komplett)
-- ════════════════════════════════════════════════════════════════════════
--
-- Die Tabelle wurde im Code an mehreren Stellen referenziert
-- (lib/screens/{materie,energie}/home_tab_v5.dart, lib/services/community_service.dart,
-- lib/screens/shared/stats_dashboard_screen.dart), war aber nie als Migration
-- angelegt. Folge: Stats-Banner zeigte 0 Beiträge, Realtime-Stream lieferte nichts,
-- Community-Feed lud nichts.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS / CREATE INDEX IF NOT EXISTS / DO $$ blocks.

CREATE TABLE IF NOT EXISTS public.community_posts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  world           text NOT NULL CHECK (world IN ('materie', 'energie')),
  content         text NOT NULL,
  author          text,
  username        text,
  author_avatar   text,
  likes_count     integer NOT NULL DEFAULT 0,
  comments_count  integer NOT NULL DEFAULT 0,
  shares_count    integer NOT NULL DEFAULT 0,
  tags            text[] NOT NULL DEFAULT '{}',
  media_url       text,
  media_type      text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Indexe — Feed-Queries sortieren nach world + created_at desc
CREATE INDEX IF NOT EXISTS idx_community_posts_world_created
  ON public.community_posts (world, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_posts_user
  ON public.community_posts (user_id);

CREATE INDEX IF NOT EXISTS idx_community_posts_created
  ON public.community_posts (created_at DESC);

-- updated_at Auto-Trigger
CREATE OR REPLACE FUNCTION public.set_community_posts_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_community_posts_updated_at ON public.community_posts;
CREATE TRIGGER trg_community_posts_updated_at
  BEFORE UPDATE ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION public.set_community_posts_updated_at();

-- RLS aktivieren — Posts sind public lesbar, schreiben nur eingeloggt
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- SELECT: alle dürfen alle Posts lesen
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'community_posts'
      AND policyname = 'community_posts_select_all'
  ) THEN
    CREATE POLICY community_posts_select_all
      ON public.community_posts
      FOR SELECT
      USING (true);
  END IF;

  -- INSERT: eingeloggte User können nur eigene Posts anlegen
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'community_posts'
      AND policyname = 'community_posts_insert_own'
  ) THEN
    CREATE POLICY community_posts_insert_own
      ON public.community_posts
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  -- UPDATE: nur Autor darf eigenen Post bearbeiten
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'community_posts'
      AND policyname = 'community_posts_update_own'
  ) THEN
    CREATE POLICY community_posts_update_own
      ON public.community_posts
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  -- DELETE: nur Autor darf eigenen Post löschen
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'community_posts'
      AND policyname = 'community_posts_delete_own'
  ) THEN
    CREATE POLICY community_posts_delete_own
      ON public.community_posts
      FOR DELETE
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END$$;

-- Realtime-Publication — Feed-Streams brauchen INSERT/UPDATE/DELETE-Events
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'community_posts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_posts;
  END IF;
END$$;

-- Anon-Read-Grant (für nicht-eingeloggte Feed-Vorschau)
GRANT SELECT ON public.community_posts TO anon;
GRANT ALL ON public.community_posts TO authenticated;
