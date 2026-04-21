-- v39: Chat-Message → notification_queue Trigger
--
-- Sobald eine neue Chat-Nachricht geschrieben wird, legen wir für jeden
-- anderen aktiven User im Raum eine notification_queue-Zeile an. Der
-- Worker-Dispatcher / Client-Poll (`/api/push/pending`) liefert sie dann
-- als lokale Benachrichtigung aus.
--
-- Ziel: In-App-Benachrichtigungen ohne FCM. Wenn die App offen ist (oder
-- beim Resume), drain'd der Client die Queue und zeigt die Nachrichten
-- als flutter_local_notifications an.
--
-- Sicherheit: Trigger läuft als SECURITY DEFINER — muss `auth.users` lesen
-- und in `notification_queue` schreiben dürfen. RLS auf
-- notification_queue greift für Leserechte (User sieht nur eigene Zeilen).

-- Sicherstellen dass die Tabelle existiert (idempotent).
CREATE TABLE IF NOT EXISTS public.notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'pending',
  attempts INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notification_queue_pending
  ON public.notification_queue(status, created_at)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_notification_queue_user_pending
  ON public.notification_queue(user_id, status, created_at)
  WHERE status = 'pending';

ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;

-- User sieht nur eigene Queue-Einträge
DO $d$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'notification_queue'
      AND policyname = 'Users read own notifications'
  ) THEN
    CREATE POLICY "Users read own notifications"
      ON public.notification_queue FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END $d$;

-- Trigger-Funktion: fan-out auf alle User die mal im Raum geschrieben haben
CREATE OR REPLACE FUNCTION public.fn_enqueue_chat_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_title TEXT;
  v_body TEXT;
  v_room_id TEXT;
  v_sender TEXT;
  v_content TEXT;
BEGIN
  -- Skip system/bot messages if we ever have them
  IF NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_room_id := NEW.room_id;
  v_sender  := COALESCE(NEW.username, 'Jemand');
  v_content := COALESCE(NEW.message, NEW.content, '');
  IF char_length(v_content) > 120 THEN
    v_content := left(v_content, 117) || '...';
  END IF;

  v_title := v_sender || ' · ' || v_room_id;
  v_body  := v_content;

  -- Für jeden distinct user_id der schon mal im Raum geschrieben hat
  -- (außer dem Sender selbst) eine Queue-Zeile erzeugen.
  INSERT INTO public.notification_queue (user_id, title, body, data)
  SELECT DISTINCT cm.user_id,
         v_title,
         v_body,
         jsonb_build_object(
           'room_id', v_room_id,
           'message_id', NEW.id,
           'sender', v_sender,
           'type', 'chat_message'
         )
  FROM public.chat_messages cm
  WHERE cm.room_id = v_room_id
    AND cm.user_id IS NOT NULL
    AND cm.user_id <> NEW.user_id
    AND cm.created_at > NOW() - INTERVAL '30 days';

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Wir wollen NICHT die INSERT auf chat_messages scheitern lassen nur weil
  -- die Queue-Insertion failt. Stattdessen still schlucken.
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_chat_notification ON public.chat_messages;
CREATE TRIGGER trg_enqueue_chat_notification
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_enqueue_chat_notification();
