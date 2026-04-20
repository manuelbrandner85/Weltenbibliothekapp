-- ✨ Batch 2.3 — Chat Read-Receipts
--
-- Ein User hat PRO Raum genau eine Zeile: last_read_at = Timestamp der
-- letzten Nachricht, die er beim Scrollen bis ans Ende gesehen hat.
-- Damit können wir für eine eigene Nachricht m zählen, wie viele andere
-- User `last_read_at >= m.created_at` haben → „Gelesen von N".
--
-- Idempotent: create-if-not-exists + policy-replace, sicher für mehrfaches
-- Anwenden.

CREATE TABLE IF NOT EXISTS public.chat_read_receipts (
    user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    room_id       text        NOT NULL,
    last_read_at  timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, room_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_read_receipts_room
    ON public.chat_read_receipts (room_id, last_read_at DESC);

-- Updated-At Trigger
CREATE OR REPLACE FUNCTION public.set_chat_read_receipts_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_chat_read_receipts_updated_at
    ON public.chat_read_receipts;
CREATE TRIGGER trg_chat_read_receipts_updated_at
    BEFORE UPDATE ON public.chat_read_receipts
    FOR EACH ROW EXECUTE FUNCTION public.set_chat_read_receipts_updated_at();

-- RLS
ALTER TABLE public.chat_read_receipts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "read all receipts"      ON public.chat_read_receipts;
DROP POLICY IF EXISTS "upsert own receipt"     ON public.chat_read_receipts;
DROP POLICY IF EXISTS "update own receipt"     ON public.chat_read_receipts;
DROP POLICY IF EXISTS "delete own receipt"     ON public.chat_read_receipts;

-- Jede:r darf receipts lesen (zum Rendern des „Gelesen von N")
CREATE POLICY "read all receipts"
    ON public.chat_read_receipts
    FOR SELECT
    USING (true);

-- Nur der eigene User darf eigene Receipts schreiben
CREATE POLICY "upsert own receipt"
    ON public.chat_read_receipts
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "update own receipt"
    ON public.chat_read_receipts
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "delete own receipt"
    ON public.chat_read_receipts
    FOR DELETE
    USING (auth.uid() = user_id);

-- Realtime aktivieren, damit Clients Receipts live sehen
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_read_receipts;
