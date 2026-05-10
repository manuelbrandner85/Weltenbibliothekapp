-- v56: chat_messages FK drop + chat_rooms GRANT fix
-- Root cause: chat_messages hat noch FK room_id→chat_rooms(id).
-- PostgreSQL prüft FK via SELECT auf chat_rooms — ohne GRANT SELECT schlägt
-- der INSERT fehl mit "permission denied for table chat_rooms".
-- Diese Migration (idempotent) behebt das dauerhaft.

-- 1. GRANT SELECT auf chat_rooms (sofortiger Fix für FK-Check)
GRANT SELECT ON public.chat_rooms TO anon;
GRANT SELECT ON public.chat_rooms TO authenticated;

-- 2. RLS auf chat_rooms aktivieren + SELECT-Policy für alle
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "chat_rooms_select_all" ON public.chat_rooms;
CREATE POLICY "chat_rooms_select_all" ON public.chat_rooms
  FOR SELECT USING (true);

-- 3. FK chat_messages.room_id → chat_rooms.id droppen (alle bekannten Namen)
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_room_id_fkey;
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_room_id_chat_rooms_fkey;
ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS fk_chat_messages_room_id;

-- Fallback: dynamisch per Name suchen und droppen (falls abweichend benannt)
DO $$
DECLARE
  fk_name TEXT;
BEGIN
  SELECT constraint_name INTO fk_name
  FROM information_schema.table_constraints
  WHERE table_schema = 'public'
    AND table_name   = 'chat_messages'
    AND constraint_type = 'FOREIGN KEY'
    AND constraint_name LIKE '%room%';
  IF fk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.chat_messages DROP CONSTRAINT IF EXISTS %I', fk_name);
  END IF;
END $$;
