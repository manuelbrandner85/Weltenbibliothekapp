-- ═══════════════════════════════════════════════════════════════
-- MIGRATION v88 – User-Presence-Tracking
--
-- Fügt `last_seen_at` zur profiles-Tabelle hinzu damit das Admin-
-- Dashboard pro User anzeigen kann: Online (< 2 min), Inaktiv (< 15 min),
-- Offline. Wird vom Client per Heartbeat aktualisiert.
-- ═══════════════════════════════════════════════════════════════

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;

-- Index für Online-Listen + Sortierung im Admin-Dashboard.
CREATE INDEX IF NOT EXISTS idx_profiles_last_seen
  ON public.profiles (last_seen_at DESC NULLS LAST);

-- Initial alle vorhandenen Profile auf NULL (Offline) lassen — der
-- Heartbeat füllt das beim nächsten App-Start ein.

COMMENT ON COLUMN public.profiles.last_seen_at IS
  'Letzter Heartbeat des Users. NULL = noch nie online. <2min = aktiv.';
