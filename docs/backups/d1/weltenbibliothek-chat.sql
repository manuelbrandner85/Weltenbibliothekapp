-- D1 Backup: weltenbibliothek-chat
-- Erstellt: Thu Apr  2 17:29:14 UTC 2026
CREATE TABLE chat_messages (
      id TEXT PRIMARY KEY,
      room_id TEXT NOT NULL,
      realm TEXT NOT NULL,
      user_id TEXT NOT NULL,
      username TEXT NOT NULL,
      message TEXT NOT NULL,
      avatar TEXT DEFAULT '👤',
      avatar_url TEXT,
      media_type TEXT,
      media_url TEXT,
      timestamp INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      edited BOOLEAN DEFAULT 0,
      edited_at TEXT,
      deleted BOOLEAN DEFAULT 0,
      UNIQUE(id)
    );
CREATE TABLE chat_polls (
      id TEXT PRIMARY KEY,
      room_id TEXT NOT NULL,
      realm TEXT NOT NULL,
      creator_id TEXT NOT NULL,
      creator_username TEXT NOT NULL,
      question TEXT NOT NULL,
      options TEXT NOT NULL,
      votes TEXT DEFAULT '{}',
      created_at TEXT NOT NULL,
      expires_at TEXT,
      UNIQUE(id)
    );
CREATE TABLE chat_reactions (
      id TEXT PRIMARY KEY,
      message_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      username TEXT NOT NULL,
      emoji TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      FOREIGN KEY(message_id) REFERENCES chat_messages(id),
      UNIQUE(message_id, user_id, emoji)
    );
