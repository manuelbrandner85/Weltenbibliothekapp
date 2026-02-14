-- ============================================================================
-- WELTENBIBLIOTHEK V99 - D1 DATABASE MIGRATION (SAFE)
-- ============================================================================
-- Migration strategy: ALTER TABLE instead of CREATE TABLE
-- Safe for existing production database
-- ============================================================================

-- Voice Sessions Table (New)
CREATE TABLE IF NOT EXISTS voice_sessions (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  room_name TEXT,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  world TEXT NOT NULL,
  joined_at INTEGER NOT NULL,
  left_at INTEGER,
  is_muted INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (unixepoch() * 1000)
);

CREATE INDEX IF NOT EXISTS idx_voice_sessions_room 
  ON voice_sessions(room_id, world);
CREATE INDEX IF NOT EXISTS idx_voice_sessions_user 
  ON voice_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_sessions_active 
  ON voice_sessions(world, left_at);

-- Admin Actions Table (New)
CREATE TABLE IF NOT EXISTS admin_actions (
  id TEXT PRIMARY KEY,
  action_type TEXT NOT NULL,
  target_user_id TEXT NOT NULL,
  target_username TEXT NOT NULL,
  admin_user_id TEXT NOT NULL,
  admin_username TEXT NOT NULL,
  world TEXT NOT NULL,
  room_id TEXT,
  reason TEXT,
  duration_hours INTEGER,
  created_at INTEGER NOT NULL DEFAULT (unixepoch() * 1000),
  expires_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_admin_actions_target 
  ON admin_actions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_admin 
  ON admin_actions(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_actions_world 
  ON admin_actions(world, created_at);

-- Chat Messages Table (if not exists)
CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  realm TEXT NOT NULL,
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
