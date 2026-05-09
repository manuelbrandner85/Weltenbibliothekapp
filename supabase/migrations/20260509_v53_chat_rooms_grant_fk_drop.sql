-- v53: chat_rooms SELECT-Grant + FK-Drop by name (KEIN PL/pgSQL)
-- Root cause: chat_messages hat noch FK room_id→chat_rooms(id).
-- PostgreSQL prüft FK via SELECT auf chat_rooms — anon/authenticated fehlt GRANT SELECT.
-- Behebt: "permission denied for table chat_rooms" beim INSERT auf chat_messages.

-- ── 1. SELECT-Grant auf chat_rooms (sofortiger Fix für FK-Check) ─────────────
GRANT SELECT ON public.chat_rooms TO anon;
GRANT SELECT ON public.chat_rooms TO authenticated;

-- ── 2. RLS auf chat_rooms — SELECT-Policy für alle ──────────────────────────
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "chat_rooms_select_all" ON public.chat_rooms;
CREATE POLICY "chat_rooms_select_all" ON public.chat_rooms
  FOR SELECT USING (true);

-- ── 3. FK-Constraints auf chat_messages by name droppen (kein DO-Block) ─────
-- Standard-Name den PostgreSQL beim REFERENCES vergibt:
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_room_id_fkey;
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_user_id_fkey;
-- Mögliche Varianten aus älteren Migrationen:
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_room_id_chat_rooms_fkey;
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS fk_chat_messages_room;
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS fk_chat_room;
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS fk_room_id;
