// ============================================================================
// WELTENBIBLIOTHEK V101 - BACKEND-FIRST WEBRTC FLOW
// ============================================================================
// V101 Features:
// - POST /api/voice/join - Backend-First Voice Join (Session-ID generieren)
// - POST /api/voice/leave - Voice Leave (Session beenden)
// - GET /api/voice/rooms/:world - Aktive Räume
// - All V100 Features (Admin Dashboard, Session Tracking)
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

// Helper: JSON Response mit CORS
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Expose-Headers': 'Content-Type',
      'Content-Type': 'application/json',
    }
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Expose-Headers': 'Content-Type',
      'Content-Type': 'application/json',
    };

    // OPTIONS pre-flight
    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ====================================================================
      // HEALTH CHECK
      // ====================================================================
      if (path === '/api/health' || path === '/health') {
        return jsonResponse({
          status: 'ok',
          version: 'V101',
          features: [
            '10 Tool-Endpoints',
            '10 Chat-Endpoints', 
            'WebSockets',
            'Admin Dashboard',
            'Voice Call Tracking',
            'Session Tracking',
            'Admin Action Logging',
            'Backend-First Voice Join (NEW)',
            'Voice Session Management (NEW)'
          ],
          database: env.DB ? 'connected' : 'not_connected',
          timestamp: new Date().toISOString()
        });
      }

      // ====================================================================
      // 🆕 BACKEND-FIRST VOICE JOIN
      // ====================================================================
      
      // POST /api/voice/join - Backend-Session erstellen, Session-ID zurückgeben
      if (path === '/api/voice/join' && method === 'POST') {
        if (!validateToken(request)) {
          return jsonResponse({
            success: false,
            error: 'Unauthorized',
            message: 'Invalid or missing API token'
          }, 401);
        }

        if (!env.DB) {
          return jsonResponse({
            success: false,
            error: 'Database not configured'
          }, 500);
        }

        try {
          const body = await request.json();
          const { room_id, user_id, username, world } = body;

          // Validierung
          if (!room_id || !user_id || !username || !world) {
            return jsonResponse({
              success: false,
              error: 'Missing required fields',
              required: ['room_id', 'user_id', 'username', 'world']
            }, 400);
          }

          // Raum-Kapazität prüfen
          const currentCountResult = await env.DB.prepare(
            'SELECT COUNT(*) as count FROM voice_sessions WHERE room_id = ? AND left_at IS NULL'
          ).bind(room_id).first();

          const currentCount = currentCountResult?.count || 0;
          const maxParticipants = 10;

          if (currentCount >= maxParticipants) {
            return jsonResponse({
              success: false,
              error: 'Room full',
              message: `Raum ist voll (${currentCount}/${maxParticipants} Teilnehmer)`,
              current_participant_count: currentCount,
              max_participants: maxParticipants
            }, 403);
          }

          // Prüfen ob User bereits im Raum
          const existingSession = await env.DB.prepare(
            'SELECT session_id FROM voice_sessions WHERE room_id = ? AND user_id = ? AND left_at IS NULL'
          ).bind(room_id, user_id).first();

          if (existingSession) {
            return jsonResponse({
              success: false,
              error: 'Already in room',
              message: 'Sie sind bereits in diesem Raum',
              session_id: existingSession.session_id
            }, 409);
          }

          // Session-ID generieren
          const sessionId = crypto.randomUUID();

          // Session in DB erstellen
          await env.DB.prepare(`
            INSERT INTO voice_sessions (
              session_id,
              room_id,
              user_id,
              username,
              world,
              joined_at
            ) VALUES (?, ?, ?, ?, ?, datetime('now'))
          `).bind(sessionId, room_id, user_id, username, world).run();

          // Aktuelle Teilnehmer laden
          const participantsResult = await env.DB.prepare(
            'SELECT user_id, username FROM voice_sessions WHERE room_id = ? AND left_at IS NULL'
          ).bind(room_id).all();

          const participants = participantsResult.results.map(p => ({
            userId: p.user_id,
            username: p.username,
            isMuted: false,
            isSpeaking: false
          }));

          // Erfolg zurückgeben
          return jsonResponse({
            success: true,
            session_id: sessionId,
            room_id: room_id,
            max_participants: maxParticipants,
            current_participant_count: currentCount + 1,
            participants: participants,
            joined_at: new Date().toISOString(),
            message: 'Backend-Session erfolgreich erstellt'
          });

        } catch (error) {
          return jsonResponse({
            success: false,
            error: 'Internal server error',
            message: error.message
          }, 500);
        }
      }

      // ====================================================================
      // 🆕 VOICE LEAVE
      // ====================================================================
      
      // POST /api/voice/leave - Session beenden
      if (path === '/api/voice/leave' && method === 'POST') {
        if (!validateToken(request)) {
          return jsonResponse({
            success: false,
            error: 'Unauthorized'
          }, 401);
        }

        if (!env.DB) {
          return jsonResponse({
            success: false,
            error: 'Database not configured'
          }, 500);
        }

        try {
          const body = await request.json();
          const { session_id } = body;

          if (!session_id) {
            return jsonResponse({
              success: false,
              error: 'Missing session_id'
            }, 400);
          }

          // Session-Info laden
          const session = await env.DB.prepare(
            'SELECT * FROM voice_sessions WHERE session_id = ?'
          ).bind(session_id).first();

          if (!session) {
            return jsonResponse({
              success: false,
              error: 'Session not found'
            }, 404);
          }

          if (session.left_at) {
            return jsonResponse({
              success: false,
              error: 'Session already ended',
              left_at: session.left_at
            }, 409);
          }

          // Session beenden
          await env.DB.prepare(`
            UPDATE voice_sessions
            SET left_at = datetime('now'),
                duration_seconds = cast((julianday(datetime('now')) - julianday(joined_at)) * 86400 as integer)
            WHERE session_id = ?
          `).bind(session_id).run();

          // Aktualisierte Session laden
          const updatedSession = await env.DB.prepare(
            'SELECT * FROM voice_sessions WHERE session_id = ?'
          ).bind(session_id).first();

          return jsonResponse({
            success: true,
            session_id: session_id,
            room_id: session.room_id,
            user_id: session.user_id,
            duration_seconds: updatedSession.duration_seconds || 0,
            left_at: updatedSession.left_at,
            message: 'Session erfolgreich beendet'
          });

        } catch (error) {
          return jsonResponse({
            success: false,
            error: 'Internal server error',
            message: error.message
          }, 500);
        }
      }

      // ====================================================================
      // 🆕 ACTIVE ROOMS
      // ====================================================================
      
      // GET /api/voice/rooms/:world - Aktive Räume
      const roomsMatch = path.match(/^\/api\/voice\/rooms\/(materie|energie)$/);
      if (roomsMatch && method === 'GET') {
        if (!validateToken(request)) {
          return jsonResponse({
            success: false,
            error: 'Unauthorized'
          }, 401);
        }

        if (!env.DB) {
          return jsonResponse({
            success: false,
            error: 'Database not configured'
          }, 500);
        }

        try {
          const world = roomsMatch[1];

          // Aktive Räume mit Teilnehmer-Anzahl
          const roomsResult = await env.DB.prepare(`
            SELECT 
              room_id,
              COUNT(*) as participant_count,
              MIN(joined_at) as first_joined_at
            FROM voice_sessions
            WHERE world = ? AND left_at IS NULL
            GROUP BY room_id
          `).bind(world).all();

          const rooms = roomsResult.results.map(r => ({
            room_id: r.room_id,
            participant_count: r.participant_count,
            max_participants: 10,
            is_full: r.participant_count >= 10,
            first_joined_at: r.first_joined_at
          }));

          return jsonResponse({
            success: true,
            world: world,
            rooms: rooms,
            total_active_rooms: rooms.length
          });

        } catch (error) {
          return jsonResponse({
            success: false,
            error: 'Internal server error',
            message: error.message
          }, 500);
        }
      }

      // ====================================================================
      // V100 ENDPOINTS (Admin Dashboard, Session Tracking)
      // ====================================================================
      
      // GET /api/admin/voice-calls/:world
      const voiceCallsMatch = path.match(/^\/api\/admin\/voice-calls\/(materie|energie)$/);
      if (voiceCallsMatch && method === 'GET') {
        if (!validateToken(request)) {
          return jsonResponse({ error: 'Unauthorized' }, 401);
        }

        if (!env.DB) {
          return jsonResponse({ error: 'Database not configured' }, 500);
        }

        try {
          const world = voiceCallsMatch[1];
          
          const result = await env.DB.prepare(`
            SELECT 
              room_id,
              COUNT(*) as participant_count,
              GROUP_CONCAT(username, ', ') as participants,
              MIN(joined_at) as started_at,
              cast((julianday(datetime('now')) - julianday(MIN(joined_at))) * 86400 as integer) as duration_seconds
            FROM voice_sessions
            WHERE world = ? AND left_at IS NULL
            GROUP BY room_id
          `).bind(world).all();

          const calls = result.results.map(row => ({
            room_id: row.room_id,
            room_name: row.room_id.charAt(0).toUpperCase() + row.room_id.slice(1),
            participant_count: row.participant_count,
            participants: row.participants ? row.participants.split(', ') : [],
            started_at: row.started_at,
            duration_seconds: row.duration_seconds || 0
          }));

          return jsonResponse({
            success: true,
            world: world,
            calls: calls,
            total_active_calls: calls.length
          });

        } catch (error) {
          return jsonResponse({
            success: false,
            error: error.message
          }, 500);
        }
      }

      // POST /api/admin/voice-session/start
      if (path === '/api/admin/voice-session/start' && method === 'POST') {
        if (!validateToken(request)) {
          return jsonResponse({ success: false, error: 'Unauthorized' }, 401);
        }

        return jsonResponse({
          success: true,
          message: 'Session tracking started',
          note: 'Use /api/voice/join for backend-first flow'
        });
      }

      // POST /api/admin/voice-session/end
      if (path === '/api/admin/voice-session/end' && method === 'POST') {
        if (!validateToken(request)) {
          return jsonResponse({ success: false, error: 'Unauthorized' }, 401);
        }

        const body = await request.json();
        const { session_id } = body;

        if (session_id) {
          // Weiterleitung zu /api/voice/leave
          return jsonResponse({
            success: true,
            message: 'Use /api/voice/leave for ending sessions',
            redirect: '/api/voice/leave'
          });
        }

        return jsonResponse({
          success: true,
          message: 'Session tracking ended'
        });
      }

      // POST /api/admin/action/log
      if (path === '/api/admin/action/log' && method === 'POST') {
        if (!validateToken(request)) {
          return jsonResponse({ success: false, error: 'Unauthorized' }, 401);
        }

        if (!env.DB) {
          return jsonResponse({ success: false, error: 'Database not configured' }, 500);
        }

        try {
          const body = await request.json();
          const { action_type, target_user_id, admin_user_id, world, room_id, reason } = body;

          await env.DB.prepare(`
            INSERT INTO admin_actions (
              action_type,
              target_user_id,
              admin_user_id,
              world,
              room_id,
              reason,
              created_at
            ) VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
          `).bind(
            action_type || 'unknown',
            target_user_id || '',
            admin_user_id || '',
            world || '',
            room_id || '',
            reason || ''
          ).run();

          return jsonResponse({
            success: true,
            message: 'Admin action logged'
          });

        } catch (error) {
          return jsonResponse({
            success: false,
            error: error.message
          }, 500);
        }
      }

      // ====================================================================
      // WEBSOCKET UPGRADE
      // ====================================================================
      
      if (request.headers.get('Upgrade') === 'websocket') {
        return new Response('WebSocket upgrade expected', { status: 426 });
      }

      // ====================================================================
      // 404 NOT FOUND
      // ====================================================================
      
      return jsonResponse({
        error: 'Not found',
        path: path,
        available_endpoints: [
          'POST /api/voice/join',
          'POST /api/voice/leave',
          'GET /api/voice/rooms/:world',
          'GET /api/admin/voice-calls/:world',
          'POST /api/admin/voice-session/start',
          'POST /api/admin/voice-session/end',
          'POST /api/admin/action/log',
          'GET /api/health'
        ]
      }, 404);

    } catch (error) {
      return jsonResponse({
        error: 'Internal server error',
        message: error.message
      }, 500);
    }
  }
};
