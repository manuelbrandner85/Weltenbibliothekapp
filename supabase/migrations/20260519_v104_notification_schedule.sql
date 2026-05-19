-- v104: notification_queue.scheduled_at fuer zeitgesteuerte Pushes.
-- Erweitert das bestehende Cron-getriebene Dispatch-System um Pushes
-- die zu einem zukuenftigen Zeitpunkt feuern sollen. Der bestehende
-- dispatchPushQueue() filtert aktiv auf scheduled_at IS NULL OR
-- scheduled_at <= NOW().

ALTER TABLE public.notification_queue
  ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled
  ON public.notification_queue(scheduled_at)
  WHERE scheduled_at IS NOT NULL AND status = 'pending';
