-- ============================================================================
-- WELTENBIBLIOTHEK V99 - D1 DATABASE SCHEMA
-- ============================================================================
-- Neue Tabellen für Admin Dashboard:
-- - voice_sessions: Voice Call Tracking
-- - admin_actions: Moderation Log
-- ============================================================================

-- Voice Sessions Table (Call Tracking)
CREATE TABLE IF NOT EXISTS voice_sessions (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  room_name TEXT,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  world TEXT NOT NULL,  -- 'materie' oder 'energie'
  joined_at INTEGER NOT NULL,  -- Unix timestamp (ms)
  left_at INTEGER,  -- Unix timestamp (ms), NULL = still active
  is_muted INTEGER DEFAULT 0,  -- 0 = not muted, 1 = muted
  created_at INTEGER NOT NULL DEFAULT (unixepoch() * 1000)
);

CREATE INDEX IF NOT EXISTS idx_voice_sessions_room 
  ON voice_sessions(room_id, world);
CREATE INDEX IF NOT EXISTS idx_voice_sessions_user 
  ON voice_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_sessions_active 
  ON voice_sessions(world, left_at);

-- Admin Actions Table (Moderation Log)
CREATE TABLE IF NOT EXISTS admin_actions (
  id TEXT PRIMARY KEY,
  action_type TEXT NOT NULL,  -- 'kick', 'mute', 'ban', 'warn'
  target_user_id TEXT NOT NULL,
  target_username TEXT NOT NULL,
  admin_user_id TEXT NOT NULL,
  admin_username TEXT NOT NULL,
  world TEXT NOT NULL,  -- 'materie' oder 'energie'
  room_id TEXT,  -- Optional: Room where action occurred
  reason TEXT,
  duration_hours INTEGER,  -- For bans/timeouts
  created_at INTEGER NOT NULL DEFAULT (unixepoch() * 1000),
  expires_at INTEGER  -- For temporary bans
);

CREATE INDEX IF NOT EXISTS idx_admin_actions_target 
  ON admin_actions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin 
  ON admin_actions(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_world 
  ON admin_actions(world, created_at);

-- Users Table (if not exists)
CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  role TEXT DEFAULT 'user',  -- 'user', 'admin', 'root_admin'
  avatar_emoji TEXT,
  bio TEXT,
  world TEXT NOT NULL,  -- 'materie' oder 'energie'
  created_at INTEGER NOT NULL DEFAULT (unixepoch() * 1000),
  last_active INTEGER
);

CREATE INDEX IF NOT EXISTS idx_users_world 
  ON users(world, role);

-- Chat Messages Table (if not exists)
CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  realm TEXT NOT NULL,  -- 'materie' oder 'energie'
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  edited_at INTEGER,
  deleted INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_room 
  ON chat_messages(room_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user 
  ON chat_messages(user_id);
