-- ═══════════════════════════════════════════════════════════════
-- WELTENBIBLIOTHEK - D1 DATABASE SCHEMA
-- ═══════════════════════════════════════════════════════════════
-- Version: 2.0.0 (Clean Rebuild)
-- Database: weltenbibliothek-db
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- TABLE: users
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user', -- 'user', 'admin', 'super_admin'
  is_banned INTEGER DEFAULT 0,
  is_muted INTEGER DEFAULT 0,
  muted_until INTEGER,
  created_at INTEGER NOT NULL,
  last_login INTEGER,
  bio TEXT
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: chat_rooms
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS chat_rooms (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  type TEXT DEFAULT 'fixed', -- 'fixed', 'user_created'
  created_by TEXT,
  created_at TEXT NOT NULL,
  member_count INTEGER DEFAULT 0,
  last_message TEXT,
  last_message_time TEXT,
  emoji TEXT DEFAULT '💬',
  is_fixed INTEGER DEFAULT 0,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_chat_rooms_type ON chat_rooms(type);
CREATE INDEX idx_chat_rooms_created_at ON chat_rooms(created_at);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: messages
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  chat_room_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  sender_name TEXT NOT NULL,
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text', -- 'text', 'image', 'video', 'audio'
  media_url TEXT,
  created_at TEXT NOT NULL,
  is_edited INTEGER DEFAULT 0,
  updated_at TEXT,
  FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(id)
);

CREATE INDEX idx_messages_chat_room ON messages(chat_room_id, created_at);
CREATE INDEX idx_messages_sender ON messages(sender_id);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: live_rooms
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS live_rooms (
  room_id TEXT PRIMARY KEY,
  chat_room_id TEXT,
  title TEXT NOT NULL,
  description TEXT,
  host_username TEXT NOT NULL,
  host_user_id TEXT,
  status TEXT DEFAULT 'live', -- 'live', 'ended', 'scheduled'
  category TEXT DEFAULT 'general',
  created_at INTEGER NOT NULL,
  started_at INTEGER,
  ended_at INTEGER,
  participant_count INTEGER DEFAULT 0,
  max_participants INTEGER DEFAULT 50,
  is_private INTEGER DEFAULT 0,
  FOREIGN KEY (chat_room_id) REFERENCES chat_rooms(id),
  FOREIGN KEY (host_user_id) REFERENCES users(id)
);

CREATE INDEX idx_live_rooms_status ON live_rooms(status);
CREATE INDEX idx_live_rooms_chat_room ON live_rooms(chat_room_id);
CREATE INDEX idx_live_rooms_created_at ON live_rooms(created_at);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: events (Geografische Ereignisse)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  image_url TEXT,
  video_url TEXT,
  document_url TEXT,
  tags TEXT, -- JSON array as text
  source TEXT,
  is_verified INTEGER DEFAULT 0,
  resonance_frequency REAL,
  created_at TEXT NOT NULL,
  created_by TEXT,
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_events_category ON events(category);
CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_events_location ON events(latitude, longitude);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: direct_messages
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS direct_messages (
  id TEXT PRIMARY KEY,
  from_user_id TEXT NOT NULL,
  to_user_id TEXT NOT NULL,
  content TEXT NOT NULL,
  type TEXT DEFAULT 'text',
  media_url TEXT,
  created_at TEXT NOT NULL,
  is_read INTEGER DEFAULT 0,
  is_edited INTEGER DEFAULT 0,
  updated_at TEXT,
  FOREIGN KEY (from_user_id) REFERENCES users(id),
  FOREIGN KEY (to_user_id) REFERENCES users(id)
);

CREATE INDEX idx_dm_from_to ON direct_messages(from_user_id, to_user_id, created_at);
CREATE INDEX idx_dm_conversation ON direct_messages(from_user_id, to_user_id);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: reports (Moderation)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS reports (
  id TEXT PRIMARY KEY,
  reported_user_id TEXT NOT NULL,
  reported_by_user_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending', -- 'pending', 'resolved', 'dismissed'
  created_at TEXT NOT NULL,
  resolved_at TEXT,
  resolved_by TEXT,
  action_taken TEXT,
  FOREIGN KEY (reported_user_id) REFERENCES users(id),
  FOREIGN KEY (reported_by_user_id) REFERENCES users(id),
  FOREIGN KEY (resolved_by) REFERENCES users(id)
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_at ON reports(created_at);

-- ═══════════════════════════════════════════════════════════════
-- TABLE: admin_actions
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS admin_actions (
  id TEXT PRIMARY KEY,
  admin_id TEXT NOT NULL,
  target_user_id TEXT NOT NULL,
  action TEXT NOT NULL, -- 'ban', 'unban', 'mute', 'unmute', 'promote', 'demote'
  reason TEXT,
  duration INTEGER, -- Duration in seconds (for mutes)
  created_at TEXT NOT NULL,
  FOREIGN KEY (admin_id) REFERENCES users(id),
  FOREIGN KEY (target_user_id) REFERENCES users(id)
);

CREATE INDEX idx_admin_actions_admin ON admin_actions(admin_id);
CREATE INDEX idx_admin_actions_target ON admin_actions(target_user_id);
CREATE INDEX idx_admin_actions_created_at ON admin_actions(created_at);
