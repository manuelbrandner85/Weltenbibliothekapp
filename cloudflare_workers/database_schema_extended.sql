-- ═══════════════════════════════════════════════════════════════
-- WELTENBIBLIOTHEK - EXTENDED D1 DATABASE SCHEMA
-- ═══════════════════════════════════════════════════════════════
-- Phase 2: Impact Features Database Schema
-- Includes: Event Favorites, Push Subscriptions, Music Playlists,
--           User Activity Logs, Moderation History
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- 1. EVENT FAVORITES - User ↔ Event Mappings
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS event_favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  event_title TEXT,
  event_category TEXT,
  latitude REAL,
  longitude REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  -- Prevent duplicate favorites
  UNIQUE(user_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON event_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_event ON event_favorites(event_id);

-- ═══════════════════════════════════════════════════════════════
-- 2. PUSH NOTIFICATION SUBSCRIPTIONS
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS push_subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  endpoint TEXT NOT NULL UNIQUE,
  p256dh_key TEXT NOT NULL,
  auth_key TEXT NOT NULL,
  
  -- Notification preferences
  notify_new_streams BOOLEAN DEFAULT 1,
  notify_messages BOOLEAN DEFAULT 1,
  notify_event_updates BOOLEAN DEFAULT 1,
  
  -- Metadata
  user_agent TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  last_used DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(user_id, endpoint)
);

CREATE INDEX IF NOT EXISTS idx_push_user ON push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_push_active ON push_subscriptions(last_used);

-- ═══════════════════════════════════════════════════════════════
-- 3. MUSIC PLAYLISTS - Shared Music Rooms
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS music_playlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_by TEXT NOT NULL,
  is_public BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS playlist_tracks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  playlist_id INTEGER NOT NULL,
  youtube_id TEXT NOT NULL,
  title TEXT NOT NULL,
  artist TEXT,
  duration_seconds INTEGER,
  added_by TEXT NOT NULL,
  position INTEGER NOT NULL,
  votes INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (playlist_id) REFERENCES music_playlists(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist ON playlist_tracks(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_position ON playlist_tracks(playlist_id, position);

-- ═══════════════════════════════════════════════════════════════
-- 4. USER ACTIVITY LOG - Engagement Tracking
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_activity_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  activity_type TEXT NOT NULL,
  -- Types: 'stream_watch', 'chat_message', 'event_view', 'login', 'profile_update'
  
  metadata TEXT, -- JSON field for additional data
  duration_seconds INTEGER, -- For activities with duration
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activity_user ON user_activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_type ON user_activity_log(activity_type);
CREATE INDEX IF NOT EXISTS idx_activity_timestamp ON user_activity_log(timestamp);

-- ═══════════════════════════════════════════════════════════════
-- 5. STREAM QUALITY METRICS - WebRTC Performance
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS stream_quality_metrics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  peer_id TEXT,
  
  -- Quality metrics
  avg_rtt REAL,
  avg_packet_loss REAL,
  avg_jitter REAL,
  connection_quality TEXT, -- 'excellent', 'good', 'fair', 'poor', 'critical'
  
  -- Session info
  session_duration_seconds INTEGER,
  disconnect_reason TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quality_room ON stream_quality_metrics(room_id);
CREATE INDEX IF NOT EXISTS idx_quality_user ON stream_quality_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_quality_timestamp ON stream_quality_metrics(timestamp);

-- ═══════════════════════════════════════════════════════════════
-- 6. MODERATION HISTORY - Admin Actions
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS moderation_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  moderator_id TEXT NOT NULL,
  target_user_id TEXT,
  action_type TEXT NOT NULL,
  -- Types: 'warn', 'mute', 'kick', 'ban', 'unban', 'delete_message'
  
  reason TEXT,
  duration_seconds INTEGER, -- For temporary actions
  metadata TEXT, -- JSON: affected content, chat room, etc.
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_moderation_moderator ON moderation_history(moderator_id);
CREATE INDEX IF NOT EXISTS idx_moderation_target ON moderation_history(target_user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_timestamp ON moderation_history(timestamp);

-- ═══════════════════════════════════════════════════════════════
-- 7. MESSAGE REACTIONS - Enhanced Chat Features
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS message_reactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  emoji TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(message_id, user_id, emoji)
);

CREATE INDEX IF NOT EXISTS idx_reactions_message ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON message_reactions(user_id);

-- ═══════════════════════════════════════════════════════════════
-- 8. MESSAGE THREADS - Reply-to Functionality
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS message_threads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id TEXT NOT NULL UNIQUE,
  parent_message_id TEXT, -- NULL for root messages
  thread_root_id TEXT, -- Always points to the root message
  reply_count INTEGER DEFAULT 0,
  last_reply_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (parent_message_id) REFERENCES message_threads(message_id)
);

CREATE INDEX IF NOT EXISTS idx_threads_parent ON message_threads(parent_message_id);
CREATE INDEX IF NOT EXISTS idx_threads_root ON message_threads(thread_root_id);

-- ═══════════════════════════════════════════════════════════════
-- 9. USER NOTIFICATIONS - In-App Notifications
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  type TEXT NOT NULL,
  -- Types: 'new_message', 'stream_started', 'reaction', 'mention', 'system'
  
  title TEXT NOT NULL,
  body TEXT,
  action_url TEXT, -- Deep link to relevant content
  metadata TEXT, -- JSON: sender info, room info, etc.
  
  is_read BOOLEAN DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  read_at DATETIME
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON user_notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON user_notifications(created_at);

-- ═══════════════════════════════════════════════════════════════
-- 10. SYSTEM STATISTICS - Aggregated Data
-- ═══════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS system_statistics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  stat_date DATE NOT NULL UNIQUE,
  
  -- User stats
  total_users INTEGER DEFAULT 0,
  active_users INTEGER DEFAULT 0,
  new_users INTEGER DEFAULT 0,
  
  -- Stream stats
  total_streams INTEGER DEFAULT 0,
  total_stream_minutes INTEGER DEFAULT 0,
  avg_viewers REAL DEFAULT 0,
  
  -- Chat stats
  total_messages INTEGER DEFAULT 0,
  total_reactions INTEGER DEFAULT 0,
  
  -- Event stats
  total_event_views INTEGER DEFAULT 0,
  total_favorites INTEGER DEFAULT 0,
  
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stats_date ON system_statistics(stat_date);

-- ═══════════════════════════════════════════════════════════════
-- DATA MIGRATION & SAMPLE DATA
-- ═══════════════════════════════════════════════════════════════

-- Insert sample push subscription (for testing)
INSERT OR IGNORE INTO push_subscriptions 
(user_id, endpoint, p256dh_key, auth_key, user_agent)
VALUES 
('demo_user_1', 
 'https://fcm.googleapis.com/fcm/send/demo-endpoint-123',
 'demo_p256dh_key',
 'demo_auth_key',
 'Mozilla/5.0 (Linux; Android) Chrome/120.0.0.0');

-- Insert sample event favorite
INSERT OR IGNORE INTO event_favorites
(user_id, event_id, event_title, event_category, latitude, longitude)
VALUES
('demo_user_1', 'stonehenge', 'Stonehenge', 'archaeology', 51.1789, -1.8262);

-- Insert initial system statistics
INSERT OR IGNORE INTO system_statistics
(stat_date, total_users, active_users)
VALUES
(DATE('now'), 1, 1);

-- ═══════════════════════════════════════════════════════════════
-- VIEWS FOR ANALYTICS
-- ═══════════════════════════════════════════════════════════════

-- Most favorited events
CREATE VIEW IF NOT EXISTS v_popular_events AS
SELECT 
  event_id,
  event_title,
  event_category,
  COUNT(*) as favorite_count,
  GROUP_CONCAT(user_id) as favorited_by
FROM event_favorites
GROUP BY event_id
ORDER BY favorite_count DESC;

-- User engagement scores
CREATE VIEW IF NOT EXISTS v_user_engagement AS
SELECT 
  user_id,
  COUNT(*) as total_activities,
  SUM(CASE WHEN activity_type = 'stream_watch' THEN 1 ELSE 0 END) as streams_watched,
  SUM(CASE WHEN activity_type = 'chat_message' THEN 1 ELSE 0 END) as messages_sent,
  SUM(duration_seconds) as total_active_seconds,
  MAX(timestamp) as last_activity
FROM user_activity_log
GROUP BY user_id;

-- ═══════════════════════════════════════════════════════════════
-- SUCCESS!
-- ═══════════════════════════════════════════════════════════════
