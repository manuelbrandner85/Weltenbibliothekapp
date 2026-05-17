-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v79 – Cluster E: Chat-Features
--
-- E1 chat_messages.voice_url + duration_sec — Voice-Memo-Support
-- E2 pinned_messages — Sticky Pin pro Room (Mod-only)
-- E4 hand_raise_queue (LiveKit) — Reihenfolge im Stream
-- ═══════════════════════════════════════════════════════════════

-- E1 ──────────────────────────────────────────────────────────
ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS voice_url        text,
  ADD COLUMN IF NOT EXISTS voice_duration   smallint,    -- in Sekunden
  ADD COLUMN IF NOT EXISTS voice_waveform   jsonb;        -- optional Sampled Amplitude

-- E2 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pinned_messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id         text NOT NULL,
  message_id      text NOT NULL,            -- referenziert chat_messages.id (string)
  pinned_by       text NOT NULL,            -- admin/mod username
  pinned_by_role  text,
  preview         text,                     -- Snippet für die Anzeige (max 280)
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (room_id, message_id)
);

CREATE INDEX IF NOT EXISTS idx_pinned_room
  ON public.pinned_messages (room_id, created_at DESC);

ALTER TABLE public.pinned_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pinned_read ON public.pinned_messages;
CREATE POLICY pinned_read ON public.pinned_messages FOR SELECT USING (true);

DROP POLICY IF EXISTS pinned_write ON public.pinned_messages;
CREATE POLICY pinned_write ON public.pinned_messages
  FOR ALL USING (true) WITH CHECK (true);


-- E4 ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.hand_raise_queue (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_name    text NOT NULL,
  identity     text NOT NULL,
  username     text,
  raised_at    timestamptz NOT NULL DEFAULT now(),
  cleared_at   timestamptz,                  -- NULL = noch in Queue
  UNIQUE (room_name, identity, raised_at)
);

CREATE INDEX IF NOT EXISTS idx_hand_queue_room_time
  ON public.hand_raise_queue (room_name, raised_at);

ALTER TABLE public.hand_raise_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS hand_queue_read ON public.hand_raise_queue;
CREATE POLICY hand_queue_read ON public.hand_raise_queue
  FOR SELECT USING (true);

DROP POLICY IF EXISTS hand_queue_write ON public.hand_raise_queue;
CREATE POLICY hand_queue_write ON public.hand_raise_queue
  FOR ALL USING (true) WITH CHECK (true);

COMMENT ON COLUMN public.chat_messages.voice_url IS
  'Voice-Memo URL in R2 (E1). NULL für Text-Nachrichten.';
COMMENT ON TABLE public.pinned_messages IS
  'Sticky-Pin pro Chat-Room durch Mods (E2).';
COMMENT ON TABLE public.hand_raise_queue IS
  'Hand-Raising-Reihenfolge pro LiveKit-Room (E4).';
