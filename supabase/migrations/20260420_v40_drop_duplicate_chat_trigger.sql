-- v40: Doppelten Chat-Notification-Trigger entfernen
--
-- v13 hatte `chat_message_push_trigger` angelegt, der ALLE aktiven
-- push_subscriptions-User benachrichtigt (spammy).
-- v39 ersetzt ihn durch `trg_enqueue_chat_notification`, der nur User
-- benachrichtigt, die in den letzten 30 Tagen im Raum geschrieben haben.
--
-- Ohne diesen Cleanup bekäme jeder User jede Nachricht doppelt.
-- Idempotent: DROP IF EXISTS ist no-op wenn der Trigger schon weg ist.

DROP TRIGGER IF EXISTS chat_message_push_trigger ON public.chat_messages;
DROP FUNCTION IF EXISTS public.trigger_chat_message_notification();
