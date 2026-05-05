-- v47: Kaninchenbau Saved Threads + Community Annotations
--
-- 1. saved_threads      — User speichert seine Recherche-Pfade
-- 2. thread_annotations — Community-Hinweise/Beweise zu Themen (anonym möglich)

-- ══════════════════════════════════════════════════════════════
-- TABLE: saved_threads
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.saved_threads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  topic           TEXT NOT NULL,
  path            TEXT[] NOT NULL DEFAULT '{}',  -- Breadcrumb-Trail
  notes           TEXT,
  is_public       BOOLEAN NOT NULL DEFAULT FALSE,
  share_token     TEXT UNIQUE,                   -- für Read-only-Share-Links
  card_snapshot   JSONB,                          -- optional: kompletter Card-Cache
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_saved_threads_user
  ON public.saved_threads(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_threads_share
  ON public.saved_threads(share_token) WHERE share_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_saved_threads_topic
  ON public.saved_threads(LOWER(topic));

ALTER TABLE public.saved_threads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saved_threads_owner_all" ON public.saved_threads;
CREATE POLICY "saved_threads_owner_all" ON public.saved_threads
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_threads_public_read" ON public.saved_threads;
CREATE POLICY "saved_threads_public_read" ON public.saved_threads
  FOR SELECT USING (is_public = TRUE OR share_token IS NOT NULL);

-- updated_at-Trigger
CREATE OR REPLACE FUNCTION public.touch_saved_threads()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_touch_saved_threads ON public.saved_threads;
CREATE TRIGGER trg_touch_saved_threads
  BEFORE UPDATE ON public.saved_threads
  FOR EACH ROW EXECUTE FUNCTION public.touch_saved_threads();

-- ══════════════════════════════════════════════════════════════
-- TABLE: thread_annotations  (Community Intelligence Layer)
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.thread_annotations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic           TEXT NOT NULL,                     -- Topic (lowercased)
  user_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_anonymous    BOOLEAN NOT NULL DEFAULT FALSE,    -- Whistleblower-Modus
  body            TEXT NOT NULL,
  source_url      TEXT,                              -- optional Beleg
  upvotes         INT NOT NULL DEFAULT 0,
  downvotes       INT NOT NULL DEFAULT 0,
  flagged         BOOLEAN NOT NULL DEFAULT FALSE,    -- Moderations-Flag
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_thread_annotations_topic
  ON public.thread_annotations(LOWER(topic), created_at DESC);

ALTER TABLE public.thread_annotations ENABLE ROW LEVEL SECURITY;

-- Lesen: alle eingeloggten User dürfen alle (außer geflaggte) sehen
DROP POLICY IF EXISTS "thread_annotations_read" ON public.thread_annotations;
CREATE POLICY "thread_annotations_read" ON public.thread_annotations
  FOR SELECT USING (NOT flagged);

-- Schreiben: jeder eingeloggte User darf erstellen
DROP POLICY IF EXISTS "thread_annotations_insert" ON public.thread_annotations;
CREATE POLICY "thread_annotations_insert" ON public.thread_annotations
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Update/Delete: nur Owner (wenn nicht anonym), anonyme Posts werden über Worker-Admin gemoderiert
DROP POLICY IF EXISTS "thread_annotations_owner_modify" ON public.thread_annotations;
CREATE POLICY "thread_annotations_owner_modify" ON public.thread_annotations
  FOR UPDATE USING (auth.uid() = user_id AND NOT is_anonymous);

DROP POLICY IF EXISTS "thread_annotations_owner_delete" ON public.thread_annotations;
CREATE POLICY "thread_annotations_owner_delete" ON public.thread_annotations
  FOR DELETE USING (auth.uid() = user_id AND NOT is_anonymous);

-- ══════════════════════════════════════════════════════════════
-- TABLE: thread_annotation_votes  (1 Vote pro User pro Annotation)
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.thread_annotation_votes (
  annotation_id  UUID NOT NULL REFERENCES public.thread_annotations(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vote           INT NOT NULL CHECK (vote IN (-1, 1)),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (annotation_id, user_id)
);

ALTER TABLE public.thread_annotation_votes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "annotation_votes_all" ON public.thread_annotation_votes;
CREATE POLICY "annotation_votes_all" ON public.thread_annotation_votes
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Trigger: Up/Downvote-Counts auf annotations-Row aktualisieren
CREATE OR REPLACE FUNCTION public.recompute_annotation_votes()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  aid UUID;
  up_count INT;
  down_count INT;
BEGIN
  aid := COALESCE(NEW.annotation_id, OLD.annotation_id);
  SELECT
    COUNT(*) FILTER (WHERE vote = 1),
    COUNT(*) FILTER (WHERE vote = -1)
  INTO up_count, down_count
  FROM public.thread_annotation_votes WHERE annotation_id = aid;
  UPDATE public.thread_annotations
    SET upvotes = up_count, downvotes = down_count
    WHERE id = aid;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trg_recompute_votes ON public.thread_annotation_votes;
CREATE TRIGGER trg_recompute_votes
  AFTER INSERT OR UPDATE OR DELETE ON public.thread_annotation_votes
  FOR EACH ROW EXECUTE FUNCTION public.recompute_annotation_votes();
