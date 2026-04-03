-- ============================================================
-- Weltenbibliothek – Migration 002: Realtime
-- ============================================================

-- Enable realtime for chat_messages (live chat)
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- Message count trigger for chat_rooms
CREATE OR REPLACE FUNCTION public.update_room_message_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.chat_rooms
    SET message_count = message_count + 1
    WHERE id = NEW.room_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER chat_messages_count_trigger
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.update_room_message_count();
