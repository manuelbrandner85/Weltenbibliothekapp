-- ═══════════════════════════════════════════════════════════════
-- WELTENBIBLIOTHEK - SEED DATA
-- ═══════════════════════════════════════════════════════════════
-- Sample data for testing and development
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- SEED: users
-- ═══════════════════════════════════════════════════════════════
INSERT INTO users (id, username, email, password_hash, display_name, role, created_at, bio) VALUES
('user_admin', 'Weltenbibliothek', 'admin@weltenbibliothek.de', 'demo_hash', 'Weltenbibliothek', 'super_admin', 1700000000, 'Hüter des Wissens'),
('user_manuel', 'ManuelBrandner', 'manuel@weltenbibliothek.de', 'demo_hash', 'Manuel Brandner', 'admin', 1700000000, 'Professionelle Wissensweitergabe'),
('user_demo1', 'WissensSucher', 'sucher@example.com', 'demo_hash', 'Der Wissenssuchende', 'user', 1700000100, 'Auf der Suche nach verborgenen Wahrheiten'),
('user_demo2', 'Mysterien_Jäger', 'jaeger@example.com', 'demo_hash', 'Mysterienjäger', 'user', 1700000200, 'Erforscher des Unbekannten'),
('user_demo3', 'Alchemist42', 'alchemist@example.com', 'demo_hash', 'Der Alchemist', 'user', 1700000300, 'Transformation durch Wissen');

-- ═══════════════════════════════════════════════════════════════
-- SEED: chat_rooms (Fixed Rooms)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO chat_rooms (id, name, description, type, created_by, created_at, emoji, is_fixed, member_count) VALUES
('general', 'Allgemeiner Chat', 'Zentraler Treffpunkt für alle Benutzer der Weltenbibliothek', 'fixed', 'user_admin', '2025-01-01T00:00:00Z', '🌍', 1, 5),
('music', 'Musik-Chat', 'Diskussionen über Musik, Künstler und musikalische Geheimnisse', 'fixed', 'user_admin', '2025-01-01T00:00:00Z', '🎵', 1, 3),
('room_mystery', 'Mysterien & Rätsel', 'Ungelöste Geheimnisse und verborgene Wahrheiten', 'fixed', 'user_admin', '2025-01-01T00:00:00Z', '🔮', 1, 8),
('room_wisdom', 'Weisheit & Philosophie', 'Philosophische Diskussionen und alte Weisheiten', 'fixed', 'user_admin', '2025-01-01T00:00:00Z', '📚', 1, 6),
('room_alchemy', 'Alchemie & Transformation', 'Die Kunst der inneren und äußeren Transformation', 'fixed', 'user_admin', '2025-01-01T00:00:00Z', '⚗️', 1, 4);

-- ═══════════════════════════════════════════════════════════════
-- SEED: messages (Chat History)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO messages (id, chat_room_id, sender_id, sender_name, content, type, created_at) VALUES
('msg_001', 'general', 'user_admin', 'Weltenbibliothek', 'Willkommen in der Weltenbibliothek! Hier sammeln wir das Wissen der Welt.', 'text', '2025-01-01T10:00:00Z'),
('msg_002', 'general', 'user_manuel', 'ManuelBrandner', 'Hallo zusammen! Freue mich auf spannende Diskussionen.', 'text', '2025-01-01T10:05:00Z'),
('msg_003', 'general', 'user_demo1', 'WissensSucher', 'Hat jemand Infos über antike Zivilisationen?', 'text', '2025-01-01T10:10:00Z'),
('msg_004', 'music', 'user_demo2', 'Mysterien_Jäger', 'Was haltet ihr von der 432 Hz Frequenz?', 'text', '2025-01-01T11:00:00Z'),
('msg_005', 'music', 'user_demo3', 'Alchemist42', 'Sehr interessant! Musik hat definitiv transformative Kraft.', 'text', '2025-01-01T11:05:00Z'),
('msg_006', 'room_mystery', 'user_demo1', 'WissensSucher', 'Die Pyramiden von Gizeh - wer hat sie wirklich gebaut?', 'text', '2025-01-01T12:00:00Z'),
('msg_007', 'room_mystery', 'user_demo2', 'Mysterien_Jäger', 'Eine der größten Fragen der Menschheit!', 'text', '2025-01-01T12:05:00Z');

-- ═══════════════════════════════════════════════════════════════
-- SEED: events (Geografische Ereignisse)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO events (id, title, description, latitude, longitude, category, date, source, is_verified, resonance_frequency, created_at, created_by) VALUES
('event_001', 'Pyramiden von Gizeh', 'Die mysteriösen Pyramiden von Gizeh - eines der sieben Weltwunder', 29.9792, 31.1342, 'ancient', '2560-01-01T00:00:00Z', 'Historische Aufzeichnungen', 1, 432.0, '2025-01-01T00:00:00Z', 'user_admin'),
('event_002', 'Stonehenge', 'Prähistorisches Monument mit astronomischer Ausrichtung', 51.1789, -1.8262, 'ancient', '3000-01-01T00:00:00Z', 'Archäologische Forschung', 1, 528.0, '2025-01-01T00:00:00Z', 'user_admin'),
('event_003', 'Nazca-Linien', 'Gigantische Geoglyphen in der Wüste von Peru', -14.7390, -75.1302, 'mystery', '500-01-01T00:00:00Z', 'UNESCO Weltkulturerbe', 1, 396.0, '2025-01-01T00:00:00Z', 'user_demo1'),
('event_004', 'Machu Picchu', 'Verlorene Stadt der Inkas in den Anden', -13.1631, -72.5450, 'ancient', '1450-01-01T00:00:00Z', 'Archäologie Peru', 1, 444.0, '2025-01-01T00:00:00Z', 'user_demo2'),
('event_005', 'Atlantis (Hypothetisch)', 'Die sagenumwobene versunkene Stadt', 31.6340, -24.0260, 'mystery', '9600-01-01T00:00:00Z', 'Platons Dialoge', 0, 639.0, '2025-01-01T00:00:00Z', 'user_demo3'),
('event_006', 'Göbekli Tepe', 'Ältester bekannter Tempelkomplex der Menschheit', 37.2232, 38.9225, 'ancient', '9600-01-01T00:00:00Z', 'Archäologische Ausgrabungen Türkei', 1, 417.0, '2025-01-01T00:00:00Z', 'user_admin'),
('event_007', 'Bermuda-Dreieck', 'Mysteriöses Gebiet mit unerklärlichen Vorfällen', 25.0000, -71.0000, 'phenomenon', '1945-01-01T00:00:00Z', 'Diverse Berichte', 0, 369.0, '2025-01-01T00:00:00Z', 'user_demo2'),
('event_008', 'Osterinsel Moai', 'Riesenstatuen der Rapa Nui Kultur', -27.1127, -109.3497, 'ancient', '1400-01-01T00:00:00Z', 'Archäologie Chile', 1, 528.0, '2025-01-01T00:00:00Z', 'user_demo1'),
('event_009', 'Teotihuacán', 'Mysteriöse Pyramidenstadt in Mexiko', 19.6925, -98.8438, 'ancient', '100-01-01T00:00:00Z', 'Mexikanische Archäologie', 1, 396.0, '2025-01-01T00:00:00Z', 'user_admin'),
('event_010', 'Angkor Wat', 'Größter religiöser Tempelkomplex der Welt', 13.4125, 103.8670, 'ancient', '1150-01-01T00:00:00Z', 'UNESCO Kambodscha', 1, 444.0, '2025-01-01T00:00:00Z', 'user_demo3');

-- ═══════════════════════════════════════════════════════════════
-- SEED: live_rooms (Demo Live Streams)
-- ═══════════════════════════════════════════════════════════════
-- Keine aktiven Live Rooms beim Start (werden dynamisch erstellt)

-- ═══════════════════════════════════════════════════════════════
-- SEED: direct_messages (Demo DMs)
-- ═══════════════════════════════════════════════════════════════
INSERT INTO direct_messages (id, from_user_id, to_user_id, content, type, created_at, is_read) VALUES
('dm_001', 'user_demo1', 'user_admin', 'Hallo! Ich habe eine Frage zu den Pyramiden.', 'text', '2025-01-01T14:00:00Z', 1),
('dm_002', 'user_admin', 'user_demo1', 'Gerne! Was möchtest du wissen?', 'text', '2025-01-01T14:05:00Z', 1),
('dm_003', 'user_demo2', 'user_demo3', 'Hast du das neue Video über Atlantis gesehen?', 'text', '2025-01-01T15:00:00Z', 0);
