-- Weltenbibliothek V95: Chat-Nachrichten Tabelle
CREATE TABLE IF NOT EXISTS chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  avatar TEXT DEFAULT '👤'
);

CREATE INDEX IF NOT EXISTS idx_room_timestamp 
ON chat_messages(room_id, timestamp DESC);

-- Beispiel-Nachrichten für alle 10 Räume
INSERT INTO chat_messages (room_id, user_name, message, timestamp, avatar) VALUES
  ('politik', 'System', 'Willkommen im Politik Raum! 🏛️', datetime('now'), '🤖'),
  ('geschichte', 'System', 'Willkommen im Geschichte Raum! 📜', datetime('now'), '🤖'),
  ('ufo', 'System', 'Willkommen im UFO Raum! 🛸', datetime('now'), '🤖'),
  ('verschwoerungen', 'System', 'Willkommen im Verschwörungen Raum! 🔍', datetime('now'), '🤖'),
  ('wissenschaft', 'System', 'Willkommen im Wissenschaft Raum! 🔬', datetime('now'), '🤖'),
  ('meditation', 'System', 'Willkommen im Meditation Raum! 🧘', datetime('now'), '🤖'),
  ('astralreisen', 'System', 'Willkommen im Astralreisen Raum! ✨', datetime('now'), '🤖'),
  ('chakren', 'System', 'Willkommen im Chakren Raum! 🌈', datetime('now'), '🤖'),
  ('spiritualitaet', 'System', 'Willkommen im Spiritualität Raum! 🕉️', datetime('now'), '🤖'),
  ('heilung', 'System', 'Willkommen im Heilung Raum! 💚', datetime('now'), '🤖');
