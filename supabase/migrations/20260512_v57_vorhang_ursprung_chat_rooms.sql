-- v57: Chat-Räume für VORHANG & URSPRUNG Welten
-- 3 Vorhang-Räume + 4 Ursprung-Räume = 7 neue Räume
-- Idempotent: INSERT ... ON CONFLICT DO NOTHING

-- ══════════════════════════════════════════════════════════════
-- VORHANG CHAT ROOMS (3 Räume)
-- ══════════════════════════════════════════════════════════════

INSERT INTO public.chat_rooms (id, name, world, description, is_active)
VALUES
  ('vorhang-allgemein', 'Vorhang Allgemein', 'vorhang',
   'Allgemeine Diskussionen über Dunkle Psychologie & Elite-Strategien', true),
  ('vorhang-psychologie', 'Dunkle Psychologie', 'vorhang',
   'Manipulation erkennen, Massenpsychologie, Einfluss-Techniken', true),
  ('vorhang-elite', 'Elite-Strategien', 'vorhang',
   'Machtstrukturen, Geheimgesellschaften, Schutzstrategien', true)
ON CONFLICT (id) DO NOTHING;

-- ══════════════════════════════════════════════════════════════
-- URSPRUNG CHAT ROOMS (4 Räume)
-- ══════════════════════════════════════════════════════════════

INSERT INTO public.chat_rooms (id, name, world, description, is_active)
VALUES
  ('ursprung-allgemein', 'Ursprung Allgemein', 'ursprung',
   'Allgemeine Diskussionen über Realitätserschaffung & Bewusstseins-Codes', true),
  ('ursprung-gateway', 'CIA Gateway Process', 'ursprung',
   'Hemisync, Monroe-Institut, Gateway Experience Tapes', true),
  ('ursprung-remote-viewing', 'Remote Viewing', 'ursprung',
   'CRV-Protokolle, Fernwahrnehmung, SRI-Forschung', true),
  ('ursprung-manifestation', 'Realitätserschaffung', 'ursprung',
   'Quantenbewusstsein, Manifestation, Frequenz-Programmierung', true)
ON CONFLICT (id) DO NOTHING;
