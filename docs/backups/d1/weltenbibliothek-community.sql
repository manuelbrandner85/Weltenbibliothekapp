-- D1 Backup: weltenbibliothek-community
-- Erstellt: Thu Apr  2 17:29:15 UTC 2026
CREATE TABLE articles (id TEXT PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, realm TEXT NOT NULL, category TEXT, user_id TEXT, username TEXT DEFAULT 'Anonymous', created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE saved_articles (user_id TEXT NOT NULL, article_id TEXT NOT NULL, saved_at TEXT NOT NULL, PRIMARY KEY (user_id, article_id));
CREATE TABLE user_content (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, username TEXT DEFAULT 'Anonymous', realm TEXT NOT NULL, type TEXT NOT NULL, title TEXT, content TEXT NOT NULL, media_url TEXT, created_at TEXT NOT NULL);
CREATE TABLE users (id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE, email TEXT UNIQUE, avatar_url TEXT, realm TEXT DEFAULT 'both', created_at TEXT NOT NULL, device_id TEXT, auth_token TEXT, user_id TEXT, last_login TEXT, last_seen TEXT);
