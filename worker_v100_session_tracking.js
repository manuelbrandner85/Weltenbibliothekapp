// ============================================================================
// WELTENBIBLIOTHEK V100 - ADMIN DASHBOARD + SESSION TRACKING
// ============================================================================
// V100 Features:
// - GET /api/admin/voice-calls/:world - Active Voice Calls
// - GET /api/admin/call-history/:world - Call History
// - GET /api/admin/user-profile/:userId - User Activity
// - POST /api/admin/voice-session/start - Start Session Tracking
// - POST /api/admin/voice-session/end - End Session Tracking
// - POST /api/admin/action/log - Log Admin Actions
// ============================================================================

// Import ChatRoom Durable Object
export { ChatRoom } from './chat_room.js';

// API Token Validation
const VALID_TOKENS = [
  'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y',
  'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB'
];

function validateToken(request) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader) return false;
  
  const token = authHeader.replace('Bearer ', '');
  return VALID_TOKENS.includes(token);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS Headers für alle Antworten
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Expose-Headers': 'Content-Type',
      'Content-Type': 'application/json',
    };

    // OPTIONS pre-flight handling
    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ====================================================================
      // HEALTH CHECK
      // ====================================================================
      if (path === '/api/health' || path === '/health') {
        return new Response(JSON.stringify({
          status: 'ok',
          version: 'V100',
          features: [
            '10 Tool-Endpoints',
            '10 Chat-Endpoints', 
            'WebSockets',
            'Admin Dashboard',
            'Voice Call Tracking',
            'Session Tracking (NEW)',
            'Admin Action Logging (NEW)'
          ],
          database: env.DB ? 'connected' : 'not_connected',
          timestamp: new Date().toISOString()
        }), { headers: corsHeaders });
      }

      // ====================================================================
      // 🆕 ADMIN ENDPOINTS
      // ====================================================================
      
      // GET /api/admin/voice-calls/:world - Aktive Voice Calls
      const voiceCallsMatch = path.match(/^\/api\/admin\/voice-calls\/(materie|energie)$/);
      if (voiceCallsMatch && method === 'GET') {
        if (!validateToken(request)) {
          return new Response(JSON.stringify({ 
            error: 'Unauthorized',
            message: 'Invalid or missing API token'
          }), { 
            status: 401, 
            headers: corsHeaders 
          });
        }

        const world = voiceCallsMatch[1];
        
        if (!env.DB) {
          return new Response(JSON.stringify({ 
            error: 'Database not configured' 
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }

        try {
          // Query active voice calls from voice_sessions table
          const result = await env.DB.prepare(
            `SELECT 
              room_id,
              room_name,
              COUNT(DISTINCT user_id) as participant_count,
              MIN(joined_at) as started_at,
              json_group_array(
                json_object(
                  'user_id', user_id,
                  'username', username,
                  'is_muted', is_muted,
                  'joined_at', joined_at
                )
              ) as participants
            FROM voice_sessions
            WHERE world = ? AND left_at IS NULL
            GROUP BY room_id, room_name
            ORDER BY started_at DESC`
          ).bind(world).all();

          const calls = (result.results || []).map(row => {
            const now = Date.now();
            const startedAt = row.started_at || now;
            
            return {
              room_id: row.room_id,
              room_name: row.room_name || row.room_id,
              participant_count: row.participant_count || 0,
              participants: JSON.parse(row.participants || '[]'),
              started_at: new Date(startedAt).toISOString(),
              duration_seconds: Math.floor((now - startedAt) / 1000)
            };
          });

          return new Response(JSON.stringify({
            success: true,
            world: world,
            calls: calls,
            total: calls.length,
            timestamp: new Date().toISOString()
          }), { headers: corsHeaders });

        } catch (e) {
          return new Response(JSON.stringify({
            error: 'Failed to fetch active calls',
            details: e.message
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }
      }

      // GET /api/admin/call-history/:world - Call Historie
      const callHistoryMatch = path.match(/^\/api\/admin\/call-history\/(materie|energie)$/);
      if (callHistoryMatch && method === 'GET') {
        if (!validateToken(request)) {
          return new Response(JSON.stringify({ 
            error: 'Unauthorized' 
          }), { 
            status: 401, 
            headers: corsHeaders 
          });
        }

        const world = callHistoryMatch[1];
        const limit = parseInt(url.searchParams.get('limit') || '50');
        
        if (!env.DB) {
          return new Response(JSON.stringify({ 
            error: 'Database not configured' 
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }

        try {
          // Query completed voice calls
          const result = await env.DB.prepare(
            `SELECT 
              room_id,
              room_name,
              MIN(joined_at) as started_at,
              MAX(left_at) as ended_at,
              COUNT(DISTINCT user_id) as max_participants,
              COUNT(*) as total_sessions
            FROM voice_sessions
            WHERE world = ? AND left_at IS NOT NULL
            GROUP BY room_id, room_name
            ORDER BY ended_at DESC
            LIMIT ?`
          ).bind(world, limit).all();

          const calls = (result.results || []).map(row => {
            const startedAt = row.started_at || 0;
            const endedAt = row.ended_at || 0;
            
            return {
              room_id: row.room_id,
              room_name: row.room_name || row.room_id,
              started_at: new Date(startedAt).toISOString(),
              ended_at: new Date(endedAt).toISOString(),
              duration_seconds: Math.floor((endedAt - startedAt) / 1000),
              max_participants: row.max_participants || 0,
              total_sessions: row.total_sessions || 0
            };
          });

          return new Response(JSON.stringify({
            success: true,
            world: world,
            calls: calls,
            total: calls.length,
            timestamp: new Date().toISOString()
          }), { headers: corsHeaders });

        } catch (e) {
          return new Response(JSON.stringify({
            error: 'Failed to fetch call history',
            details: e.message
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }
      }

      // GET /api/admin/user-profile/:userId - User Activity
      const userProfileMatch = path.match(/^\/api\/admin\/user-profile\/([^/]+)$/);
      if (userProfileMatch && method === 'GET') {
        if (!validateToken(request)) {
          return new Response(JSON.stringify({ 
            error: 'Unauthorized' 
          }), { 
            status: 401, 
            headers: corsHeaders 
          });
        }

        const userId = userProfileMatch[1];
        
        if (!env.DB) {
          return new Response(JSON.stringify({ 
            error: 'Database not configured' 
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }

        try {
          // Get user info from users table
          const userInfo = await env.DB.prepare(
            `SELECT * FROM users WHERE user_id = ?`
          ).bind(userId).first();

          if (!userInfo) {
            return new Response(JSON.stringify({
              error: 'User not found',
              user_id: userId
            }), { 
              status: 404, 
              headers: corsHeaders 
            });
          }

          // Get voice call stats
          const voiceStats = await env.DB.prepare(
            `SELECT 
              COUNT(DISTINCT room_id) as total_calls,
              SUM(CASE 
                WHEN left_at IS NOT NULL 
                THEN (left_at - joined_at) 
                ELSE 0 
              END) / 1000 / 60 as total_minutes
            FROM voice_sessions
            WHERE user_id = ?`
          ).bind(userId).first();

          // Get admin actions (warnings, kicks, bans)
          const adminActions = await env.DB.prepare(
            `SELECT 
              COUNT(CASE WHEN action_type = 'warn' THEN 1 END) as warnings,
              COUNT(CASE WHEN action_type = 'kick' THEN 1 END) as kicks,
              COUNT(CASE WHEN action_type = 'ban' THEN 1 END) as bans
            FROM admin_actions
            WHERE target_user_id = ?`
          ).bind(userId).first();

          return new Response(JSON.stringify({
            success: true,
            user: {
              user_id: userInfo.user_id,
              username: userInfo.username,
              role: userInfo.role || 'user',
              avatar_emoji: userInfo.avatar_emoji,
              bio: userInfo.bio,
              created_at: new Date(userInfo.created_at).toISOString(),
              last_active: userInfo.last_active ? new Date(userInfo.last_active).toISOString() : null,
              total_calls: voiceStats?.total_calls || 0,
              total_minutes: Math.floor(voiceStats?.total_minutes || 0),
              warnings: adminActions?.warnings || 0,
              kicks: adminActions?.kicks || 0,
              bans: adminActions?.bans || 0
            },
            timestamp: new Date().toISOString()
          }), { headers: corsHeaders });

        } catch (e) {
          return new Response(JSON.stringify({
            error: 'Failed to fetch user profile',
            details: e.message
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }
      }

      // ====================================================================
      // 🆕 VOICE SESSION TRACKING ENDPOINTS
      // ====================================================================
      
      // POST /api/admin/voice-session/start - Start tracking voice session
      if (path === '/api/admin/voice-session/start' && method === 'POST') {
        if (!validateToken(request)) {
          return new Response(JSON.stringify({ 
            error: 'Unauthorized',
            message: 'Invalid or missing API token'
          }), { 
            status: 401, 
            headers: corsHeaders 
          });
        }

        try {
          const body = await request.json();
          const { session_id, room_id, user_id, username, world, joined_at } = body;

          if (!env.DB) {
            return new Response(JSON.stringify({ 
              error: 'Database not configured',
              message: 'D1 database binding missing'
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }

          // Insert session start into voice_sessions table
          await env.DB.prepare(`
            INSERT INTO voice_sessions 
            (session_id, room_id, user_id, username, world, joined_at)
            VALUES (?, ?, ?, ?, ?, ?)
          `).bind(
            session_id,
            room_id,
            user_id,
            username,
            world,
            joined_at
          ).run();

          return new Response(JSON.stringify({
            success: true,
            session_id,
            message: 'Voice session started',
            timestamp: new Date().toISOString()
          }), { headers: corsHeaders });

        } catch (e) {
          return new Response(JSON.stringify({
            error: 'Failed to start voice session',
            details: e.message
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }
      }

      // POST /api/admin/voice-session/end - End voice session
      if (path === '/api/admin/voice-session/end' && method === 'POST') {
        if (!validateToken(request)) {
          return new Response(JSON.stringify({ 
            error: 'Unauthorized',
            message: 'Invalid or missing API token'
          }), { 
            status: 401, 
            headers: corsHeaders 
          });
        }

        try {
          const body = await request.json();
          const { session_id, room_id, user_id, left_at, duration_seconds, speaking_seconds } = body;

          if (!env.DB) {
            return new Response(JSON.stringify({ 
              error: 'Database not configured',
              message: 'D1 database binding missing'
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }

          // Update session with end time and stats
          await env.DB.prepare(`
            UPDATE voice_sessions
            SET left_at = ?,
                duration_seconds = ?,
                speaking_seconds = ?
            WHERE session_id = ?
          `).bind(
            left_at,
            duration_seconds,
            speaking_seconds || 0,
            session_id
          ).run();

          return new Response(JSON.stringify({
            success: true,
            session_id,
            message: 'Voice session ended',
            stats: {
              duration_seconds,
              speaking_seconds: speaking_seconds || 0
            },
            timestamp: new Date().toISOString()
          }), { headers: corsHeaders });

        } catch (e) {
          return new Response(JSON.stringify({
            error: 'Failed to end voice session',
            details: e.message
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }
      }

      // POST /api/admin/action/log - Log admin action (kick, mute, ban, warn)
      if (path === '/api/admin/action/log' && method === 'POST') {
        if (!validateToken(request)) {
          return new Response(JSON.stringify({ 
            error: 'Unauthorized',
            message: 'Invalid or missing API token'
          }), { 
            status: 401, 
            headers: corsHeaders 
          });
        }

        try {
          const body = await request.json();
          const { 
            action_type, 
            target_user_id, 
            target_username,
            admin_user_id, 
            admin_username,
            world,
            room_id,
            reason,
            timestamp 
          } = body;

          if (!env.DB) {
            return new Response(JSON.stringify({ 
              error: 'Database not configured',
              message: 'D1 database binding missing'
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }

          // Insert admin action into admin_actions table
          await env.DB.prepare(`
            INSERT INTO admin_actions 
            (action_type, target_user_id, target_username, admin_user_id, admin_username, world, room_id, reason, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          `).bind(
            action_type,
            target_user_id,
            target_username,
            admin_user_id,
            admin_username,
            world,
            room_id || null,
            reason || null,
            timestamp
          ).run();

          return new Response(JSON.stringify({
            success: true,
            message: 'Admin action logged',
            action: {
              type: action_type,
              target: target_username,
              admin: admin_username
            },
            timestamp: new Date().toISOString()
          }), { headers: corsHeaders });

        } catch (e) {
          return new Response(JSON.stringify({
            error: 'Failed to log admin action',
            details: e.message
          }), { 
            status: 500, 
            headers: corsHeaders 
          });
        }
      }

      // ====================================================================
      // WEBSOCKET ENDPOINT
      // ====================================================================
      if (path === '/api/ws') {
        const upgradeHeader = request.headers.get('Upgrade');
        if (upgradeHeader !== 'websocket') {
          return new Response('Expected WebSocket', { status: 426 });
        }

        const roomId = url.searchParams.get('room');
        if (!roomId) {
          return new Response('Missing room parameter', { status: 400 });
        }

        const id = env.CHAT_ROOM.idFromName(roomId);
        const stub = env.CHAT_ROOM.get(id);
        
        return stub.fetch(request);
      }

      // ====================================================================
      // CHAT-ENDPOINTS (Existing implementation continues...)
      // ====================================================================
      const chatRoomMatch = path.match(/^\/api\/chat\/([a-z]+)$/);
      if (chatRoomMatch) {
        const roomId = chatRoomMatch[1];
        const validRooms = ['politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft', 
                           'meditation', 'astralreisen', 'chakren', 'spiritualitaet', 'heilung'];
        
        if (!validRooms.includes(roomId)) {
          return new Response(JSON.stringify({ 
            error: 'Invalid room ID',
            valid_rooms: validRooms 
          }), { 
            status: 400, 
            headers: corsHeaders 
          });
        }

        // GET - Nachrichten abrufen
        if (method === 'GET') {
          if (env.DB) {
            const result = await env.DB.prepare(
              `SELECT * FROM chat_messages 
               WHERE room_id = ? 
               ORDER BY timestamp DESC 
               LIMIT 50`
            ).bind(roomId).all();

            return new Response(JSON.stringify({
              success: true,
              room_id: roomId,
              messages: result.results || [],
              count: result.results?.length || 0
            }), { headers: corsHeaders });
          }
        }

        // POST - Neue Nachricht senden
        if (method === 'POST') {
          const body = await request.json();
          const { username, message } = body;

          if (!username || !message) {
            return new Response(JSON.stringify({ 
              error: 'username and message are required' 
            }), { 
              status: 400, 
              headers: corsHeaders 
            });
          }

          const materieRooms = ['politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft'];
          const realm = materieRooms.includes(roomId) ? 'materie' : 'energie';
          const timestamp = Date.now();
          const messageId = `msg_${timestamp}_${Math.random().toString(36).substr(2, 9)}`;
          const userId = `user_${username.toLowerCase()}`;

          if (env.DB) {
            await env.DB.prepare(
              `INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, timestamp)
               VALUES (?, ?, ?, ?, ?, ?, ?)`
            ).bind(
              messageId,
              roomId, 
              realm,
              userId,
              username, 
              message, 
              timestamp
            ).run();

            return new Response(JSON.stringify({
              success: true,
              id: messageId,
              room_id: roomId,
              timestamp: timestamp
            }), { headers: corsHeaders });
          }
        }
      }

      // ====================================================================
      // 404 - Endpoint nicht gefunden
      // ====================================================================
      return new Response(JSON.stringify({
        error: 'Endpoint not found',
        path: path,
        available_endpoints: [
          'GET /api/health',
          'GET /api/admin/voice-calls/:world',
          'GET /api/admin/call-history/:world',
          'GET /api/admin/user-profile/:userId',
          'GET /api/ws',
          'GET /api/chat/:room',
          'POST /api/chat/:room'
        ]
      }), { 
        status: 404, 
        headers: corsHeaders 
      });

    } catch (error) {
      return new Response(JSON.stringify({
        error: 'Internal Server Error',
        message: error.message,
        stack: error.stack
      }), { 
        status: 500, 
        headers: corsHeaders 
      });
    }
  }
};
