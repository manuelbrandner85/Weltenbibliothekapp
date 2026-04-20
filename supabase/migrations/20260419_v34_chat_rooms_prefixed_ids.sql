-- ============================================================
-- v34: chat_rooms auf prefixed IDs (energie-*, materie-*) anpassen
-- ============================================================
-- Root cause bisher: Die App sendet room_id = "energie-meditation",
-- aber in chat_rooms existierten nur bare IDs wie "meditation".
-- FK chat_messages.room_id → chat_rooms.id schlug bei jedem INSERT
-- mit Code 23503 fehl → "Nachricht konnte nicht gesendet werden".
--
-- Fix: Alle prefixed IDs, die die Chat-Screens erzeugen
-- (_roomIdMap in energie_live_chat_screen.dart / materie_live_chat_screen.dart),
-- als Räume anlegen. Bestehende Zeilen werden nicht überschrieben.
-- ============================================================
INSERT INTO public.chat_rooms (id, name, world, is_active) VALUES
  ('energie-meditation',    'Meditation',      'energie', true),
  ('energie-traeume',       'Träume',          'energie', true),
  ('energie-chakra',        'Chakren',         'energie', true),
  ('energie-bewusstsein',   'Bewusstsein',     'energie', true),
  ('energie-heilung',       'Heilung',         'energie', true),
  ('energie-astrologie',    'Astrologie',      'energie', true),
  ('energie-kristalle',     'Kristalle',       'energie', true),
  ('energie-kraftorte',     'Kraftorte',       'energie', true),
  ('materie-politik',       'Politik',         'materie', true),
  ('materie-geschichte',    'Geschichte',      'materie', true),
  ('materie-ufo',           'UFOs',            'materie', true),
  ('materie-verschwoerung', 'Verschwörungen',  'materie', true),
  ('materie-wissenschaft',  'Wissenschaft',    'materie', true),
  ('materie-tech',          'Technologie',     'materie', true),
  ('materie-gesundheit',    'Gesundheit',      'materie', true),
  ('materie-medien',        'Medien',          'materie', true),
  ('materie-finanzen',      'Finanzen',        'materie', true)
ON CONFLICT (id) DO NOTHING;
