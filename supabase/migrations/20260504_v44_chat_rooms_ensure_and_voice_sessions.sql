-- v44: Chat-Räume sicherstellen + Voice-Sessions-Tabelle
--
-- Teil 1: Alle Räume, die die App nutzt, idempotent anlegen.
--   Hintergrund: FK chat_messages.room_id → chat_rooms(id) blockiert INSERT
--   wenn ein Raum nicht existiert. Diese Migration stellt alle App-Räume
--   sicher, unabhängig davon ob v34 bereits lief.
--
-- Teil 2: voice_sessions — Tracking aktiver LiveKit-Anrufe.
--   Wird genutzt für: Live-Banner in Chat-Screens + Push-Notification
--   wenn jemand einen Anruf startet.

-- ══════════════════════════════════════════════════════════════
-- TEIL 1 — Chat-Räume sicherstellen
-- ══════════════════════════════════════════════════════════════

-- chat_rooms braucht mindestens: id TEXT PRIMARY KEY, name TEXT, world TEXT, is_active BOOL
-- Spalten hinzufügen falls Tabelle vorhanden aber unvollständig:
ALTER TABLE IF EXISTS public.chat_rooms
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Alle App-Räume anlegen (ON CONFLICT → kein Überschreiben bestehender Daten)
INSERT INTO public.chat_rooms (id, name, world, is_active) VALUES
  -- Materie-Welt
  ('materie-politik',       'Politik',           'materie', true),
  ('materie-geschichte',    'Geschichte',        'materie', true),
  ('materie-ufo',           'UFOs & Aliens',     'materie', true),
  ('materie-verschwoerung', 'Verschwörungen',    'materie', true),
  ('materie-wissenschaft',  'Wissenschaft',      'materie', true),
  ('materie-tech',          'Technologie',       'materie', true),
  ('materie-gesundheit',    'Gesundheit',        'materie', true),
  ('materie-medien',        'Medien',            'materie', true),
  ('materie-finanzen',      'Finanzen',          'materie', true),
  -- Energie-Welt
  ('energie-meditation',    'Meditation',        'energie', true),
  ('energie-traeume',       'Träume',            'energie', true),
  ('energie-chakra',        'Chakren',           'energie', true),
  ('energie-bewusstsein',   'Bewusstsein',       'energie', true),
  ('energie-heilung',       'Heilung',           'energie', true),
  ('energie-astrologie',    'Astrologie',        'energie', true),
  ('energie-kristalle',     'Kristalle',         'energie', true),
  ('energie-kraftorte',     'Kraftorte',         'energie', true)
ON CONFLICT (id) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- TEIL 2 — voice_sessions Tabelle
-- ══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.voice_sessions (
  id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  room_name     TEXT          NOT NULL,
  world         TEXT          NOT NULL,
  user_id       UUID          REFERENCES public.profiles(id) ON DELETE SET NULL,
  username      TEXT          NOT NULL DEFAULT 'Unbekannt',
  display_name  TEXT,
  joined_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  left_at       TIMESTAMPTZ,
  is_active     BOOLEAN       NOT NULL DEFAULT TRUE
);

-- Indexes
CREATE INDEX IF NOT EXISTS voice_sessions_room_idx   ON public.voice_sessions (room_name) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS voice_sessions_world_idx  ON public.voice_sessions (world)     WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS voice_sessions_user_idx   ON public.voice_sessions (user_id)   WHERE is_active = TRUE;

-- RLS aktivieren
ALTER TABLE public.voice_sessions ENABLE ROW LEVEL SECURITY;

-- Jeder darf aktive Sessions sehen (für Live-Banner im Chat)
DROP POLICY IF EXISTS "voice_sessions_select" ON public.voice_sessions;
CREATE POLICY "voice_sessions_select"
  ON public.voice_sessions
  FOR SELECT
  USING (true);

-- Eigene Session anlegen (anon und authenticated)
DROP POLICY IF EXISTS "voice_sessions_insert" ON public.voice_sessions;
CREATE POLICY "voice_sessions_insert"
  ON public.voice_sessions
  FOR INSERT
  WITH CHECK (
    (auth.uid() IS NULL AND user_id IS NULL)
    OR (auth.uid() IS NOT NULL AND (auth.uid() = user_id OR user_id IS NULL))
  );

-- Eigene Session beenden (UPDATE is_active=false, left_at=NOW())
DROP POLICY IF EXISTS "voice_sessions_update" ON public.voice_sessions;
CREATE POLICY "voice_sessions_update"
  ON public.voice_sessions
  FOR UPDATE
  USING (
    auth.uid() = user_id
    OR auth.uid() IN (
      SELECT id FROM public.profiles
      WHERE role IN ('admin', 'root_admin', 'root-admin', 'moderator')
    )
  );

-- Supabase Realtime aktivieren
ALTER PUBLICATION supabase_realtime ADD TABLE public.voice_sessions;

-- Grants
GRANT SELECT, INSERT, UPDATE ON public.voice_sessions TO anon, authenticated;

-- ══════════════════════════════════════════════════════════════
-- TEIL 3 — Push-Notification wenn jemand einen Anruf startet
-- ══════════════════════════════════════════════════════════════

-- Trigger feuert wenn eine NEUE Session angelegt wird (jemand betritt einen Raum)
-- und schreibt eine Notification in notification_queue für alle anderen User
-- der gleichen Welt die gerade NICHT im gleichen Raum sind.
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
  v_title := NEW.display_name || ' ist jetzt live';
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
      (recipient_id, sender_id, type, title, body, data, created_at)
    VALUES (
      v_rec.id,
      NEW.user_id,
      'voice_join',
      v_title,
      v_body,
      jsonb_build_object(
        'roomName', NEW.room_name,
        'world',    NEW.world,
        'action',   'join_voice'
      ),
      NOW()
    )
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$;

-- Trigger nur auf INSERT (neuer Anruf)
DROP TRIGGER IF EXISTS trg_voice_session_joined ON public.voice_sessions;
CREATE TRIGGER trg_voice_session_joined
  AFTER INSERT ON public.voice_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_voice_session_joined();
