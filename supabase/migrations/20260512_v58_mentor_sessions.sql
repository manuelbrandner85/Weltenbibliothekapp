-- v58: KI-Mentor Sessions Tabelle
-- Speichert Mentor-Chat-Sessions für Analytics und optionalen Cloud-Sync.
-- Lokaler Chat-Verlauf bleibt in SQLite (primär), diese Tabelle dient als
-- serverseitiges Backup und für Admin-Analytics.
-- Idempotent: CREATE TABLE IF NOT EXISTS

-- ══════════════════════════════════════════════════════════════
-- MENTOR_SESSIONS TABLE
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.mentor_sessions (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  world         text NOT NULL CHECK (world IN ('materie', 'energie', 'vorhang', 'ursprung')),
  personality   text NOT NULL CHECK (personality IN ('forscher', 'heiler', 'stratege', 'alchemist')),
  message_count integer DEFAULT 0,
  last_message  text,
  model_used    text,            -- 'groq-llama-3.3-70b' oder 'workers-ai-llama-3.1-8b'
  created_at    timestamptz DEFAULT now() NOT NULL,
  updated_at    timestamptz DEFAULT now() NOT NULL
);

-- ── Indexes ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_mentor_sessions_user_id
  ON public.mentor_sessions(user_id);

CREATE INDEX IF NOT EXISTS idx_mentor_sessions_world
  ON public.mentor_sessions(world);

CREATE INDEX IF NOT EXISTS idx_mentor_sessions_user_world
  ON public.mentor_sessions(user_id, world);

-- ── Updated-At Trigger ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.mentor_sessions_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mentor_sessions_updated_at ON public.mentor_sessions;
CREATE TRIGGER trg_mentor_sessions_updated_at
  BEFORE UPDATE ON public.mentor_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.mentor_sessions_updated_at();

-- ══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════════════════════

ALTER TABLE public.mentor_sessions ENABLE ROW LEVEL SECURITY;

-- User kann nur eigene Sessions sehen
DROP POLICY IF EXISTS "Users can view own mentor sessions" ON public.mentor_sessions;
CREATE POLICY "Users can view own mentor sessions"
  ON public.mentor_sessions FOR SELECT
  USING (auth.uid() = user_id);

-- User kann eigene Sessions erstellen
DROP POLICY IF EXISTS "Users can create own mentor sessions" ON public.mentor_sessions;
CREATE POLICY "Users can create own mentor sessions"
  ON public.mentor_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- User kann eigene Sessions aktualisieren
DROP POLICY IF EXISTS "Users can update own mentor sessions" ON public.mentor_sessions;
CREATE POLICY "Users can update own mentor sessions"
  ON public.mentor_sessions FOR UPDATE
  USING (auth.uid() = user_id);

-- User kann eigene Sessions löschen
DROP POLICY IF EXISTS "Users can delete own mentor sessions" ON public.mentor_sessions;
CREATE POLICY "Users can delete own mentor sessions"
  ON public.mentor_sessions FOR DELETE
  USING (auth.uid() = user_id);

-- ── Grants ───────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mentor_sessions TO authenticated;
GRANT SELECT ON public.mentor_sessions TO anon;

-- ── Realtime (optional, für Admin-Dashboard) ─────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'mentor_sessions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.mentor_sessions;
  END IF;
END $$;
