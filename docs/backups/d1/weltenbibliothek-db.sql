-- D1 Backup: weltenbibliothek-db
-- Erstellt: 2026-04-02T17:28:47Z

-- TABLE: users
CREATE TABLE users (
  user_id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  is_active INTEGER NOT NULL DEFAULT 1
, device_id TEXT, auth_token TEXT, last_login TEXT, last_seen TEXT);

-- TABLE: world_profiles
CREATE TABLE world_profiles (
  profile_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  world TEXT NOT NULL CHECK (world IN ('materie', 'energie')),
  username TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('user', 'admin', 'root_admin')) DEFAULT 'user',
  
  -- Profile Data
  display_name TEXT,
  avatar_url TEXT,
  avatar_emoji TEXT,
  bio TEXT,
  
  -- World-Specific Data (JSON String)
  world_data TEXT DEFAULT '{}',
  
  -- Timestamps
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  
  -- Foreign Key
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  
  -- Constraints
  UNIQUE(world, username),  -- Username unique per world
  UNIQUE(user_id, world)    -- One profile per user per world
);

-- TABLE: chat_messages
CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  room_id TEXT NOT NULL,
  realm TEXT NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  message TEXT NOT NULL,
  avatar_emoji TEXT DEFAULT '👤',
  avatar_url TEXT,
  media_type TEXT,
  media_url TEXT,
  timestamp TEXT NOT NULL,
  edited INTEGER DEFAULT 0,
  edited_at TEXT,
  deleted INTEGER DEFAULT 0,
  deleted_at TEXT,
  reply_to TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- TABLE: chat_rooms
CREATE TABLE chat_rooms (
  id TEXT PRIMARY KEY,
  realm TEXT NOT NULL,
  room_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  last_activity TEXT,
  message_count INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(realm, room_id)
);

-- TABLE: community_posts
CREATE TABLE community_posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT,
  timestamp INTEGER NOT NULL,
  likes INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- TABLE: post_comments
CREATE TABLE post_comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  post_id INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  comment TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (post_id) REFERENCES community_posts(id)
);

-- TABLE: sessions
CREATE TABLE sessions (
  session_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  auth_token TEXT NOT NULL UNIQUE,
  
  -- World Context
  active_world TEXT NOT NULL CHECK (active_world IN ('materie', 'energie')),
  active_role TEXT NOT NULL CHECK (active_role IN ('user', 'admin', 'root_admin')),
  
  -- Expiration
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  last_activity TEXT NOT NULL DEFAULT (datetime('now')),
  
  -- Foreign Key
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- TABLE: voice_sessions
CREATE TABLE voice_sessions (
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
, session_id TEXT, duration_seconds INTEGER DEFAULT 0, speaking_seconds INTEGER DEFAULT 0);

-- TABLE: admin_actions
CREATE TABLE admin_actions (
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

-- TABLE: moderation_log
CREATE TABLE moderation_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- Welt-Kontext
  world TEXT NOT NULL CHECK(world IN ('materie', 'energie')),
  
  -- Action Details
  action_type TEXT NOT NULL CHECK(action_type IN (
    'delete_post',
    'delete_comment', 
    'edit_post',
    'edit_comment',
    'mute_user_24h',
    'mute_user_permanent',
    'unmute_user',
    'flag_content',
    'resolve_flag',
    'dismiss_flag'
  )),
  
  -- Moderator Info
  moderator_id TEXT NOT NULL,
  moderator_username TEXT NOT NULL,
  moderator_role TEXT NOT NULL CHECK(moderator_role IN ('admin', 'root_admin')),
  
  -- Target Info
  target_type TEXT NOT NULL CHECK(target_type IN ('post', 'comment', 'user', 'flag')),
  target_id TEXT NOT NULL,
  target_username TEXT, -- Bei User-Actions
  
  -- Details
  reason TEXT, -- Optional: Grund für die Aktion
  metadata TEXT, -- JSON für zusätzliche Daten
  
  -- Timestamps
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- TABLE: user_statistics
CREATE TABLE user_statistics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  world TEXT NOT NULL CHECK(world IN ('materie', 'energie')),
  user_id TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL,
  total_logins INTEGER DEFAULT 0,
  total_posts INTEGER DEFAULT 0,
  total_comments INTEGER DEFAULT 0,
  total_chat_messages INTEGER DEFAULT 0,
  total_flags_received INTEGER DEFAULT 0,
  total_flags_submitted INTEGER DEFAULT 0,
  total_likes_received INTEGER DEFAULT 0,
  total_likes_given INTEGER DEFAULT 0,
  total_reactions_received INTEGER DEFAULT 0,
  total_reactions_given INTEGER DEFAULT 0,
  first_login_at TEXT,
  last_login_at TEXT,
  last_activity_at TEXT,
  total_active_days INTEGER DEFAULT 0,
  reputation_score INTEGER DEFAULT 0,
  trust_level TEXT DEFAULT 'new' CHECK(trust_level IN ('new', 'basic', 'member', 'regular', 'leader')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- TABLE: user_suspensions
CREATE TABLE user_suspensions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  world TEXT NOT NULL CHECK(world IN ('materie', 'energie')),
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  suspension_type TEXT NOT NULL CHECK(suspension_type IN ('temporary', 'permanent')),
  reason TEXT NOT NULL,
  suspended_by_id TEXT NOT NULL,
  suspended_by_username TEXT NOT NULL,
  suspended_by_role TEXT NOT NULL CHECK(suspended_by_role IN ('admin', 'root_admin')),
  suspended_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT,
  is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
  unsuspended_at TEXT,
  unsuspended_by_id TEXT,
  unsuspended_by_username TEXT
);

-- TABLE: user_mutes
CREATE TABLE user_mutes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- Welt-Kontext
  world TEXT NOT NULL CHECK(world IN ('materie', 'energie')),
  
  -- User Info
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  
  -- Mute Details
  mute_type TEXT NOT NULL CHECK(mute_type IN ('24h', 'permanent')),
  muted_by_id TEXT NOT NULL,
  muted_by_username TEXT NOT NULL,
  muted_by_role TEXT NOT NULL CHECK(muted_by_role IN ('admin', 'root_admin')),
  reason TEXT,
  
  -- Status
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  
  -- Expiration
  expires_at TEXT, -- NULL für permanent
  
  -- Timestamps
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  unmuted_at TEXT,
  unmuted_by_id TEXT,
  unmuted_by_username TEXT
);

-- TABLE: user_notes
CREATE TABLE user_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  world TEXT NOT NULL CHECK(world IN ('materie', 'energie')),
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  note TEXT NOT NULL,
  note_type TEXT DEFAULT 'general' CHECK(note_type IN ('general', 'warning', 'praise', 'concern')),
  created_by_id TEXT NOT NULL,
  created_by_username TEXT NOT NULL,
  created_by_role TEXT NOT NULL CHECK(created_by_role IN ('admin', 'root_admin')),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- TABLE: user_presence
CREATE TABLE user_presence (
  id TEXT PRIMARY KEY,
  realm TEXT NOT NULL,
  room_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  avatar_emoji TEXT DEFAULT '👤',
  last_seen TEXT NOT NULL,
  is_online INTEGER DEFAULT 1,
  UNIQUE(realm, room_id, user_id)
);

-- TABLE: feature_flags
CREATE TABLE feature_flags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  is_enabled INTEGER DEFAULT 0,
  rollout_percentage REAL DEFAULT 0.0,
  enabled_for_users TEXT,  -- JSON array
  enabled_for_roles TEXT,  -- JSON array
  expires_at TEXT,
  config TEXT,  -- JSON
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_by TEXT NOT NULL
);

-- TABLE: reserved_usernames
CREATE TABLE reserved_usernames (username TEXT PRIMARY KEY, reason TEXT NOT NULL, reserved_for TEXT, created_at INTEGER DEFAULT (unixepoch()));


-- DATA: users
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('root_admin_001', '2026-02-04 21:36:43', '2026-02-04 21:36:43', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_test_001', '2026-02-04 21:36:43', '2026-02-04 21:36:43', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_test_002', '2026-02-04 21:36:43', '2026-02-04 21:36:43', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_test_003', '2026-02-04 21:36:43', '2026-02-04 21:36:43', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_1770246998781_782', '2026-02-04 23:16:38', '2026-02-04 23:16:38', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('test_final', '2026-02-05T22:40:00Z', '2026-02-05 22:35:53', 1, 'device_final', 'token_final', NULL, '2026-02-05T22:35:53.841Z');
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('admin_test_001', '2026-02-05T23:00:00Z', '2026-02-05 22:39:31', 1, 'device_admin_001', 'wb_admin_test_token_001', NULL, '2026-02-05T22:39:31.393Z');
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_final_v12_1770333345', '2026-02-05 23:15:46', '2026-02-05 23:15:46', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_maxtesr', '2026-02-05 23:16:57', '2026-02-05 23:16:57', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_Weltenbibliothek', '2026-02-05 23:17:18', '2026-02-05 23:17:18', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_max', '2026-02-05 23:27:04', '2026-02-05 23:27:04', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_auto_1770334161', '2026-02-05 23:29:22', '2026-02-05 23:29:22', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_1770335598837_495895', '2026-02-06T00:53:18.837923', '2026-02-05 23:53:19', 1, 'device_1770335598837_287697', 'wb_44dff844db9bf1a5f336b2380b2a3dce16a913e5a59cfdfa8b155afcf0243684', NULL, '2026-02-05T23:53:19.058Z');
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_complete_19669', '2026-02-06 00:07:09', '2026-02-06 00:07:09', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('energie_Testusermax', '2026-02-06 00:49:27', '2026-02-06 00:49:27', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('energie_testusermax', '2026-02-06 00:50:22', '2026-02-06 00:50:22', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_Weltenbibliothektest', '2026-02-06 02:44:23', '2026-02-06 02:44:24', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_1770365851023_414139', '2026-02-06T09:17:31.023930', '2026-02-06 08:17:31', 1, 'device_1770365851023_216835', 'wb_947129811d7e305c11c9db29bc1bf4b16fd0ebd59504ee3872dc23f0fcbb9838', NULL, '2026-02-06T08:17:31.412Z');
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_1770366215577_923139', '2026-02-06T09:23:35.577051', '2026-02-06 08:23:36', 1, 'device_1770366215577_773395', 'wb_0f19e5a4d9e07e301541dc821dcec377d687645c82ba4a6581a14f6c250c8d53', NULL, '2026-02-08T14:09:39.466Z');
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('user_1770373157181_279603', '2026-02-06T11:19:17.182', '2026-02-06 10:19:17', 1, 'device_1770373157181_11156', 'wb_bd8aa1d80adaa9a36da11180f0f443ef9df33f1a17ba3a5f2ea4172467651715', NULL, '2026-02-06T10:19:17.774Z');
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('energie_hans', '2026-02-06 21:10:15', '2026-02-06 21:10:15', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_Weltenbibliothekedit', '2026-02-08 02:40:30', '2026-02-08 02:40:30', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_TestUser123', '2026-02-08 17:25:33', '2026-02-08 17:25:33', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_Weltenbibliotheke', '2026-02-08 17:28:18', '2026-02-08 17:28:18', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_testusermax', '2026-02-08 22:05:07', '2026-02-08 22:05:07', 1, NULL, NULL, NULL, NULL);
INSERT INTO users (user_id, created_at, updated_at, is_active, device_id, auth_token, last_login, last_seen) VALUES ('materie_Weltenbiblioth', '2026-02-12 20:43:50', '2026-02-12 20:43:50', 1, NULL, NULL, NULL, NULL);

-- DATA: world_profiles
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('root_admin_001_materie', 'root_admin_001', 'materie', 'Weltenbibliothek', 'root_admin', 'Weltenbibliothek', NULL, NULL, NULL, '{"name":null}', '2026-02-04 21:36:43', '2026-02-08T03:01:32.284Z');
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('root_admin_001_energie', 'root_admin_001', 'energie', 'Weltenbibliothek', 'root_admin', 'Weltenbibliothek', NULL, '🔥', 'Root Administrator der Energie-Welt', '{"firstName": "Root", "lastName": "Administrator", "birthDate": "2026-01-01T00:00:00Z", "birthPlace": "Weltenbibliothek"}', '2026-02-04 21:36:43', '2026-02-07T21:00:44.515Z');
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('energie_Testusermax_energie', 'energie_Testusermax', 'energie', 'Testusermax', 'admin', 'Testusermax', NULL, NULL, NULL, '{}', '2026-02-06T00:49:27.098Z', '2026-02-06T00:51:54.218Z');
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('materie_max_materie', 'materie_max', 'materie', 'max', 'admin', 'max', NULL, NULL, NULL, '{}', '2026-02-06T03:49:38.822Z', '2026-02-14T15:14:57.375Z');
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('materie_Weltenbibliothekedit_materie', 'materie_Weltenbibliothekedit', 'materie', 'Weltenbibliothekedit', 'user', 'Weltenbibliothekedit', NULL, NULL, NULL, '{}', '2026-02-08T02:46:56.160Z', '2026-02-08T02:46:56.160Z');
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('materie_testusermax_materie', 'materie_testusermax', 'materie', 'testusermax', 'user', 'testusermax', NULL, NULL, NULL, '{}', '2026-02-08 22:05:08', '2026-02-14T22:37:23.202Z');
INSERT INTO world_profiles (profile_id, user_id, world, username, role, display_name, avatar_url, avatar_emoji, bio, world_data, created_at, updated_at) VALUES ('materie_Weltenbiblioth_materie', 'materie_Weltenbiblioth', 'materie', 'Weltenbiblioth', 'user', 'Weltenbiblioth', NULL, NULL, NULL, '{}', '2026-02-12 20:43:50', '2026-02-12 20:43:50');

-- DATA: chat_messages
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770575295404_lwewx5rz8', 'general', 'materie', 'manuel', 'Manuel', 'Hallo Weltenbibliothek! 🔬', '👤', NULL, NULL, NULL, '2026-02-08T18:28:15.404Z', 0, NULL, 0, NULL, NULL, '2026-02-08 18:28:15');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770575546352_o9akfrj00', 'general', 'energie', 'test', 'TestUser', 'Test', '👤', NULL, NULL, NULL, '2026-02-08T18:32:26.352Z', 0, NULL, 0, NULL, NULL, '2026-02-08 18:32:26');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770576260689_zqb2o3ice', 'politik', 'materie', 'weltenbibliothek', 'Weltenbibliothek', 'Willkommen im Materie Live-Chat! 🔬 Hier könnt ihr über Politik, UFOs, Geschichte und Verschwörungen diskutieren.', '👤', NULL, NULL, NULL, '2026-02-08T18:44:20.689Z', 0, NULL, 0, NULL, NULL, '2026-02-08 18:44:20');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770576260933_5kv01h7b2', 'meditation', 'energie', 'weltenbibliothek', 'Weltenbibliothek', 'Willkommen im Energie Live-Chat! ✨ Hier teilen wir Meditation, Chakra-Arbeit und spirituelle Erfahrungen.', '👤', NULL, NULL, NULL, '2026-02-08T18:44:20.933Z', 0, NULL, 0, NULL, NULL, '2026-02-08 18:44:20');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770576863669_a70derlat', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', '[Nachricht gelöscht]', '👤', NULL, NULL, NULL, '2026-02-08T18:54:23.669Z', 0, NULL, 1, '2026-02-08T19:52:21.044Z', NULL, '2026-02-08 18:54:23');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770576905875_g0wsxes9o', 'politik', 'materie', 'test_user', 'TestUser', 'Chat funktioniert jetzt! ✅ Das graue Problem ist gelöst! 🎉', '👤', NULL, NULL, NULL, '2026-02-08T18:55:05.875Z', 0, NULL, 0, NULL, NULL, '2026-02-08 18:55:05');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770576930909_i9dbqnhip', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', '[Nachricht gelöscht]', '👤', NULL, NULL, NULL, '2026-02-08T18:55:30.909Z', 0, NULL, 1, '2026-02-08T19:52:16.439Z', NULL, '2026-02-08 18:55:30');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770577953130_oyzvlnch3', 'meditation', 'energie', 'user_weltenbibliothekedit', 'Weltenbibliothekedit', '[Nachricht gelöscht]', '🔥', NULL, NULL, NULL, '2026-02-08T19:12:33.130Z', 0, NULL, 1, '2026-02-08T19:53:01.490Z', NULL, '2026-02-08 19:12:33');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770580350297_eya67ikiq', 'ufo', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', '[Nachricht gelöscht]', '👤', NULL, NULL, NULL, '2026-02-08T19:52:30.297Z', 0, NULL, 1, '2026-02-08T19:52:34.500Z', NULL, '2026-02-08 19:52:30');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770580360482_kug5xstco', 'ufo', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', '[Nachricht gelöscht]', '👤', NULL, NULL, NULL, '2026-02-08T19:52:40.482Z', 1, '2026-02-08T19:52:47.321Z', 1, '2026-02-08T19:52:50.823Z', NULL, '2026-02-08 19:52:40');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770580385242_en890mtjy', 'meditation', 'energie', 'user_weltenbibliothekedit', 'Weltenbibliothekedit', '[Nachricht gelöscht]', '🔥', NULL, NULL, NULL, '2026-02-08T19:53:05.242Z', 1, '2026-02-08T19:53:10.894Z', 1, '2026-02-08T19:53:14.075Z', NULL, '2026-02-08 19:53:05');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770588171218_w6pnv6a7b', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', '[Nachricht gelöscht]', '👤', NULL, NULL, NULL, '2026-02-08T22:02:51.218Z', 0, NULL, 1, '2026-02-08T22:02:55.287Z', NULL, '2026-02-08 22:02:51');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770588333008_57liyxj27', 'meditation', 'energie', 'user_weltenbibliothek', 'Weltenbibliothek', '[Nachricht gelöscht]', '🔥', NULL, NULL, NULL, '2026-02-08T22:05:33.008Z', 0, NULL, 1, '2026-02-08T22:05:38.667Z', NULL, '2026-02-08 22:05:33');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770929035962_g3gba4agv', 'politik', 'materie', 'user_weltenbiblioth', 'Weltenbiblioth', '[Nachricht gelöscht]', '👤', NULL, NULL, NULL, '2026-02-12T20:43:55.962Z', 0, NULL, 1, '2026-02-12T20:44:02.368Z', NULL, '2026-02-12 20:43:56');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_welcome_1', 'general', 'materie', 'user_system', 'System', 'Willkommen in der Weltenbibliothek! 🌍', '🌟', NULL, NULL, NULL, '2026-02-12T23:00:00.000Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:40:29');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_welcome_2', 'general', 'materie', 'user_manuel', 'Manuel', 'Hallo! Freue mich auf Diskussionen! 👋', '🧙‍♂️', NULL, NULL, NULL, '2026-02-12T23:01:00.000Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:40:29');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_welcome_3', 'general', 'materie', 'user_anna', 'Anna', 'Was sind eure Gedanken zum Weltgeschehen?', '🌸', NULL, NULL, NULL, '2026-02-12T23:02:00.000Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:40:29');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_welcome_4', 'general', 'materie', 'user_klaus', 'Klaus', 'Die Wahrheit ist da draußen! 🔍', '🕵️', NULL, NULL, NULL, '2026-02-12T23:03:00.000Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:40:29');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_welcome_5', 'general', 'materie', 'user_sarah', 'Sarah', 'Neuer Recherche-Artikel ist sehr interessant!', '📚', NULL, NULL, NULL, '2026-02-12T23:04:00.000Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:40:29');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770939738910_0dw8gomci', 'general', 'materie', 'user_testuser', 'TestUser', 'Test aus API v2.2! ✅ Chat funktioniert jetzt!', '🚀', NULL, NULL, NULL, '2026-02-12T23:42:18.910Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:42:18');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770939755497_8urpjpgez', 'general', 'materie', 'user_tester', 'Tester', 'Endpoint Test', '🔬', NULL, NULL, NULL, '2026-02-12T23:42:35.497Z', 0, NULL, 0, NULL, NULL, '2026-02-12 23:42:35');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770988788959_sx3ps90t2', 'general', 'materie', 'test_admin', 'Admin Test', 'System Test v5.7.0 ✅', '👨‍💼', NULL, NULL, NULL, '2026-02-13T13:19:48.959Z', 0, NULL, 0, NULL, NULL, '2026-02-13 13:19:48');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770989242234_r5wipgf11', 'general', 'materie', 'test', 'Test', 'OK', '👤', NULL, NULL, NULL, '2026-02-13T13:27:22.234Z', 0, NULL, 0, NULL, NULL, '2026-02-13 13:27:22');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770989981299_necbswba4', 'allgemein', 'energie', 'user_testadmin', 'TestAdmin', '✏️ BEARBEITET: Nachrichten können jetzt editiert werden!', '👨‍💻', NULL, NULL, NULL, '2026-02-13T13:39:41.299Z', 1, '2026-02-13T13:39:42.219Z', 1, '2026-02-13T13:39:58.472Z', NULL, '2026-02-13 13:39:41');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770990385334_gxf770got', 'allgemein', 'materie', 'user_testadmin', 'AdminTest', 'Admin Dashboard Test ✅', '👨‍💼', NULL, NULL, NULL, '2026-02-13T13:46:25.334Z', 0, NULL, 0, NULL, NULL, '2026-02-13 13:46:25');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770990809279_3fy5778el', 'allgemein', 'materie', 'user_QA_Tester_1770990808', 'QA_Tester_1770990808', '✏️ EDITED: Professional QA Test - Message Edited', '🧪', NULL, NULL, NULL, '2026-02-13T13:53:29.279Z', 1, '2026-02-13T13:53:30.219Z', 1, '2026-02-13T13:53:30.444Z', NULL, '2026-02-13 13:53:29');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770991188788_4gbexvxdh', 'meditation', 'energie', 'user_weltenbibliothek', 'Weltenbibliothek', 'huhu', '💎', NULL, NULL, NULL, '2026-02-13T13:59:48.788Z', 0, NULL, 1, '2026-02-13T13:59:53.874Z', NULL, '2026-02-13 13:59:48');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770991226922_w99wschdu', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', 'huhu', '👤', NULL, NULL, NULL, '2026-02-13T14:00:26.922Z', 0, NULL, 1, '2026-02-13T14:00:32.649Z', NULL, '2026-02-13 14:00:26');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770991890775_n1nas4mha', 'test', 'materie', 'test_user', 'TestUser', 'Test message v5.7.2', '🧪', NULL, NULL, NULL, '2026-02-13T14:11:30.775Z', 0, NULL, 0, NULL, NULL, '2026-02-13 14:11:30');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1770992796225_db31rbngj', 'politik', 'materie', 'user_test', 'test', 'test', '👤', NULL, NULL, NULL, '2026-02-13T14:26:36.225Z', 0, NULL, 1, '2026-02-13T14:26:40.671Z', NULL, '2026-02-13 14:26:36');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1771000680806_lgmy4yik4', 'politik', 'materie', 'test_phase_cd', 'Phase C Test', 'Backend Test aus Phase C - Admin Dashboard Integration ✅', '🧪', NULL, NULL, NULL, '2026-02-13T16:38:00.806Z', 0, NULL, 0, NULL, NULL, '2026-02-13 16:38:00');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1771025506497_c1syqwrou', 'politik', 'materie', 'user_anonymous', 'User9395', 'test', '👤', NULL, NULL, NULL, '2026-02-13T23:31:46.497Z', 0, NULL, 1, '2026-02-13T23:31:50.867Z', NULL, '2026-02-13 23:31:46');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1771108340216_pefyckwan', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', 'huhu', '👤', NULL, NULL, NULL, '2026-02-14T22:32:20.216Z', 0, NULL, 1, '2026-02-14T22:32:24.483Z', NULL, '2026-02-14 22:32:20');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1771108380922_z8aez6s1p', 'astralreisen', 'energie', 'user_weltenbibliothek', 'Weltenbibliothek', 'vjb', '💎', NULL, NULL, NULL, '2026-02-14T22:33:00.922Z', 0, NULL, 1, '2026-02-14T22:33:04.211Z', NULL, '2026-02-14 22:33:00');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1771108657564_reo9gntcr', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', 'huhu', '👤', NULL, NULL, NULL, '2026-02-14T22:37:37.564Z', 0, NULL, 1, '2026-02-14T22:37:41.792Z', NULL, '2026-02-14 22:37:37');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1772142192004_wpftntuh4', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', 'huhu', '👤', NULL, NULL, NULL, '2026-02-26T21:43:12.004Z', 0, NULL, 1, '2026-02-26T21:43:19.390Z', NULL, '2026-02-26 21:43:12');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1772319959610_ufse1phof', 'politik', 'materie', 'user_weltenbibliothek', 'Weltenbibliothek', 'test', '👤', NULL, NULL, NULL, '2026-02-28T23:05:59.610Z', 0, NULL, 1, '2026-02-28T23:06:05.307Z', NULL, '2026-02-28 23:05:59');
INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, media_type, media_url, timestamp, edited, edited_at, deleted, deleted_at, reply_to, created_at) VALUES ('msg_1774546965458_83vyvktoc', 'meditation', 'energie', 'user_manuel', 'Manuel', 'huhu', '🔮', NULL, NULL, NULL, '2026-03-26T17:42:45.458Z', 0, NULL, 1, '2026-03-26T17:42:50.845Z', NULL, '2026-03-26 17:42:45');

-- DATA: chat_rooms
INSERT INTO chat_rooms (id, realm, room_id, name, description, last_activity, message_count, created_at) VALUES ('room_materie_general', 'materie', 'general', 'general', NULL, '2026-02-08T18:28:15.404Z', 1, '2026-02-08 18:28:15');
INSERT INTO chat_rooms (id, realm, room_id, name, description, last_activity, message_count, created_at) VALUES ('room_energie_general', 'energie', 'general', 'general', NULL, '2026-02-08T18:32:26.352Z', 1, '2026-02-08 18:32:26');
INSERT INTO chat_rooms (id, realm, room_id, name, description, last_activity, message_count, created_at) VALUES ('room_materie_politik', 'materie', 'politik', 'politik', NULL, '2026-02-12T20:43:55.962Z', 6, '2026-02-08 18:44:20');
INSERT INTO chat_rooms (id, realm, room_id, name, description, last_activity, message_count, created_at) VALUES ('room_energie_meditation', 'energie', 'meditation', 'meditation', NULL, '2026-02-08T22:05:33.008Z', 4, '2026-02-08 18:44:20');
INSERT INTO chat_rooms (id, realm, room_id, name, description, last_activity, message_count, created_at) VALUES ('room_materie_ufo', 'materie', 'ufo', 'ufo', NULL, '2026-02-08T19:52:40.482Z', 2, '2026-02-08 19:52:30');

-- DATA: voice_sessions
INSERT INTO voice_sessions (id, room_id, room_name, user_id, username, world, joined_at, left_at, is_muted, created_at, session_id, duration_seconds, speaking_seconds) VALUES (NULL, 'test_room', NULL, 'test_user_001', 'Test User', 'materie', '2026-02-13 20:10:17', NULL, 0, 1771013417000, 'e8b175c9-0352-46db-95d1-68dd4aac0110', 0, 0);
INSERT INTO voice_sessions (id, room_id, room_name, user_id, username, world, joined_at, left_at, is_muted, created_at, session_id, duration_seconds, speaking_seconds) VALUES (NULL, 'politik', NULL, 'user_anonymous', 'User9395', 'materie', '2026-02-13 23:31:59', NULL, 0, 1771025519000, 'c655146b-8be4-4b36-a61c-9ca598312700', 0, 0);
