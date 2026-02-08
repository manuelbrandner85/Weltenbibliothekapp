-- Erweitere chat_messages Tabelle mit zusätzlichen Feldern
-- Die Tabelle existiert bereits, wir fügen nur fehlende Spalten hinzu

-- Prüfe ob realm Spalte existiert, wenn nicht, füge sie hinzu
ALTER TABLE chat_messages ADD COLUMN realm TEXT DEFAULT 'materie';

-- Prüfe ob avatar Spalte existiert, wenn nicht, füge sie hinzu
ALTER TABLE chat_messages ADD COLUMN avatar TEXT DEFAULT '👤';

-- Index für Realm-Filter
CREATE INDEX IF NOT EXISTS idx_room_realm ON chat_messages(room_id, realm, timestamp DESC);
