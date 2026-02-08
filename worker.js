// ============================================================================
// WELTENBIBLIOTHEK V98 - CLOUDFLARE WORKER MIT WEBSOCKETS
// ============================================================================
// Vollständige Implementierung: 10 Tool-Endpoints + 10 Chat-Endpoints + WebSockets
// D1-Datenbank: weltenbibliothek-db
// Durable Objects: ChatRoom (WebSocket-Support)
// Deployment: wrangler deploy
// ============================================================================

// Import ChatRoom Durable Object
export { ChatRoom } from './chat_room.js';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS Headers für alle Antworten (ERWEITERT für Authorization)
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
      // Keine Tabellen-Initialisierung mehr nötig - Tabelle existiert bereits

      // ====================================================================
      // HEALTH CHECK
      // ====================================================================
      if (path === '/api/health') {
        return new Response(JSON.stringify({
          status: 'ok',
          version: 'V98',
          tools: 10,
          chat_rooms: 10,
          websockets: 'enabled',
          database: env.DB ? 'connected' : 'not_connected'
        }), { headers: corsHeaders });
      }

      // ====================================================================
      // WEBSOCKET ENDPOINT
      // ====================================================================
      if (path === '/api/ws') {
        const upgradeHeader = request.headers.get('Upgrade');
        if (upgradeHeader !== 'websocket') {
          return new Response('Expected WebSocket', { status: 426 });
        }

        // Hole roomId aus Query-Parameter
        const roomId = url.searchParams.get('room');
        if (!roomId) {
          return new Response('Missing room parameter', { status: 400 });
        }

        // Erstelle oder hole Durable Object für den Raum
        const id = env.CHAT_ROOM.idFromName(roomId);
        const stub = env.CHAT_ROOM.get(id);
        
        // Leite WebSocket-Anfrage an Durable Object weiter
        return stub.fetch(request);
      }

      // ====================================================================
      // CHAT-ENDPOINTS (10 Räume)
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
          } else {
            // Fallback: Mock-Daten
            return new Response(JSON.stringify({
              success: true,
              room_id: roomId,
              messages: [
                {
                  id: 'msg_system',
                  room_id: roomId,
                  username: 'System',
                  message: `Willkommen im ${roomId} Raum! 🌟`,
                  timestamp: Date.now()
                }
              ],
              count: 1
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

          // Bestimme Realm basierend auf Room-ID
          const materieRooms = ['politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft'];
          const realm = materieRooms.includes(roomId) ? 'materie' : 'energie';
          const timestamp = Date.now(); // Unix timestamp in ms
          const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
          const userId = `user_${username.toLowerCase()}`;

          if (env.DB) {
            const result = await env.DB.prepare(
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
          } else {
            // Fallback: Mock-Response
            return new Response(JSON.stringify({
              success: true,
              id: messageId,
              room_id: roomId,
              timestamp: timestamp
            }), { headers: corsHeaders });
          }
        }

        // PUT - Nachricht bearbeiten
        if (method === 'PUT') {
          const body = await request.json();
          const { messageId, userId, message } = body;

          if (!messageId || !userId || !message) {
            return new Response(JSON.stringify({ 
              error: 'messageId, userId, and message are required' 
            }), { 
              status: 400, 
              headers: corsHeaders 
            });
          }

          if (env.DB) {
            // Prüfe ob Nachricht dem User gehört
            const check = await env.DB.prepare(
              `SELECT user_id FROM chat_messages WHERE id = ? AND room_id = ?`
            ).bind(messageId, roomId).first();

            if (!check) {
              return new Response(JSON.stringify({ 
                error: 'Message not found' 
              }), { 
                status: 404, 
                headers: corsHeaders 
              });
            }

            if (check.user_id !== userId) {
              return new Response(JSON.stringify({ 
                error: 'Not authorized to edit this message' 
              }), { 
                status: 403, 
                headers: corsHeaders 
              });
            }

            // Update message
            await env.DB.prepare(
              `UPDATE chat_messages SET message = ?, edited = 1 WHERE id = ?`
            ).bind(message, messageId).run();

            return new Response(JSON.stringify({
              success: true,
              id: messageId,
              message: 'Message updated'
            }), { headers: corsHeaders });
          } else {
            return new Response(JSON.stringify({
              success: true,
              message: 'Message updated (mock)'
            }), { headers: corsHeaders });
          }
        }

        // DELETE - Nachricht löschen
        if (method === 'DELETE') {
          const body = await request.json();
          const { messageId, userId } = body;

          if (!messageId || !userId) {
            return new Response(JSON.stringify({ 
              error: 'messageId and userId are required' 
            }), { 
              status: 400, 
              headers: corsHeaders 
            });
          }

          if (env.DB) {
            // Prüfe ob Nachricht dem User gehört
            const check = await env.DB.prepare(
              `SELECT user_id FROM chat_messages WHERE id = ? AND room_id = ?`
            ).bind(messageId, roomId).first();

            if (!check) {
              return new Response(JSON.stringify({ 
                error: 'Message not found' 
              }), { 
                status: 404, 
                headers: corsHeaders 
              });
            }

            if (check.user_id !== userId) {
              return new Response(JSON.stringify({ 
                error: 'Not authorized to delete this message' 
              }), { 
                status: 403, 
                headers: corsHeaders 
              });
            }

            // Delete message
            await env.DB.prepare(
              `DELETE FROM chat_messages WHERE id = ?`
            ).bind(messageId).run();

            return new Response(JSON.stringify({
              success: true,
              id: messageId,
              message: 'Message deleted'
            }), { headers: corsHeaders });
          } else {
            return new Response(JSON.stringify({
              success: true,
              message: 'Message deleted (mock)'
            }), { headers: corsHeaders });
          }
        }
      }

      // ====================================================================
      // TOOL-ENDPOINTS (10 Tools - bestehende Implementierung)
      // ====================================================================
      const toolMatch = path.match(/^\/api\/tools\/([a-z]+)$/);
      if (toolMatch) {
        const tool = toolMatch[1];
        
        // Tool-Namen Mapping
        const toolNames = {
          'debatte': 'debatte',
          'zeitleiste': 'zeitleiste',
          'sichtungen': 'sichtungen',
          'recherche': 'recherche',
          'experiment': 'experiment',
          'session': 'session',
          'traumanalyse': 'traumanalyse',
          'energie': 'energie',
          'weisheit': 'weisheit',
          'heilung': 'heilung'
        };

        if (!toolNames[tool]) {
          return new Response(JSON.stringify({ error: 'Unknown tool' }), { 
            status: 404, 
            headers: corsHeaders 
          });
        }

        const tableName = toolNames[tool];

        // GET - Tool-Daten abrufen
        if (method === 'GET') {
          if (env.DB) {
            try {
              const result = await env.DB.prepare(
                `SELECT * FROM ${tableName} ORDER BY created_at DESC LIMIT 50`
              ).all();

              const countResult = await env.DB.prepare(
                `SELECT COUNT(DISTINCT user_name) as user_count FROM ${tableName}`
              ).first();

              return new Response(JSON.stringify({
                success: true,
                items: result.results || [],
                user_count: countResult?.user_count || 0
              }), { headers: corsHeaders });
            } catch (e) {
              // Fallback wenn Tabelle nicht existiert
              return new Response(JSON.stringify({
                success: true,
                items: [],
                user_count: 0
              }), { headers: corsHeaders });
            }
          } else {
            // Mock-Daten
            return new Response(JSON.stringify({
              success: true,
              items: [],
              user_count: 0
            }), { headers: corsHeaders });
          }
        }

        // POST - Neue Tool-Daten speichern
        if (method === 'POST') {
          const body = await request.json();
          
          if (env.DB) {
            try {
              // Auto-assign realm based on room_id if not provided
              if (!body.realm && body.room_id) {
                const materieRooms = ['politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft'];
                body.realm = materieRooms.includes(body.room_id) ? 'materie' : 'energie';
              }
              
              // Auto-assign user_id if not provided
              if (!body.user_id && body.username) {
                body.user_id = 'user_' + body.username.toLowerCase().replace(/\s+/g, '');
              }
              
              // Auto-assign timestamp if not provided
              if (!body.timestamp) {
                body.timestamp = Date.now();
              }
              
              // Dynamisches Insert basierend auf Tool
              const columns = Object.keys(body).join(', ');
              const placeholders = Object.keys(body).map(() => '?').join(', ');
              const values = Object.values(body);

              const result = await env.DB.prepare(
                `INSERT INTO ${tableName} (${columns}) VALUES (${placeholders})`
              ).bind(...values).run();

              return new Response(JSON.stringify({
                success: true,
                id: result.meta.last_row_id
              }), { headers: corsHeaders });
            } catch (e) {
              return new Response(JSON.stringify({
                error: 'Database insert failed',
                details: e.message
              }), { 
                status: 500, 
                headers: corsHeaders 
              });
            }
          } else {
            // Mock-Response
            return new Response(JSON.stringify({
              success: true,
              id: Date.now()
            }), { headers: corsHeaders });
          }
        }
      }

      // ====================================================================
      // PUSH NOTIFICATIONS
      // ====================================================================
      if (path === '/api/push/subscribe' && method === 'POST') {
        const body = await request.json();
        
        if (!body.subscription || !body.userId) {
          return new Response(JSON.stringify({ 
            error: 'Missing subscription or userId' 
          }), { 
            status: 400, 
            headers: corsHeaders 
          });
        }

        if (env.DB) {
          try {
            // Speichere Push-Subscription in D1
            await env.DB.prepare(
              `INSERT OR REPLACE INTO push_subscriptions (user_id, endpoint, p256dh, auth, realm, created_at)
               VALUES (?, ?, ?, ?, ?, ?)`
            ).bind(
              body.userId,
              body.subscription.endpoint,
              body.subscription.keys.p256dh,
              body.subscription.keys.auth,
              body.realm || 'materie',
              Date.now()
            ).run();

            return new Response(JSON.stringify({
              success: true,
              message: 'Push subscription saved'
            }), { headers: corsHeaders });
          } catch (e) {
            return new Response(JSON.stringify({
              error: 'Failed to save subscription',
              details: e.message
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }
        }

        return new Response(JSON.stringify({
          success: true,
          message: 'Push subscription received (DB not configured)'
        }), { headers: corsHeaders });
      }

      if (path === '/api/push/send' && method === 'POST') {
        const body = await request.json();
        
        if (!body.roomId || !body.message) {
          return new Response(JSON.stringify({ 
            error: 'Missing roomId or message' 
          }), { 
            status: 400, 
            headers: corsHeaders 
          });
        }

        // ✅ SIMPLIFIED PUSH: Fetch subscriptions and broadcast via WebSocket
        if (env.DB && env.CHAT_ROOM) {
          try {
            // 1. Get all subscriptions for this room's realm
            const materieRooms = ['politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft'];
            const realm = materieRooms.includes(body.roomId) ? 'materie' : 'energie';
            
            const subs = await env.DB.prepare(
              `SELECT * FROM push_subscriptions WHERE realm = ?`
            ).bind(realm).all();
            
            // 2. Broadcast via WebSocket (instant delivery for connected users)
            const roomId = env.CHAT_ROOM.idFromName(body.roomId);
            const roomStub = env.CHAT_ROOM.get(roomId);
            
            // Broadcast message via Durable Object
            await roomStub.fetch(new Request('https://internal/broadcast', {
              method: 'POST',
              body: JSON.stringify({
                type: 'notification',
                message: body.message,
                title: body.title || 'Neue Nachricht',
                roomId: body.roomId
              })
            }));
            
            return new Response(JSON.stringify({
              success: true,
              message: 'Push notification broadcasted',
              subscribers: subs.results.length,
              delivery: 'websocket'
            }), { headers: corsHeaders });
            
          } catch (e) {
            return new Response(JSON.stringify({
              error: 'Push broadcast failed',
              details: e.message
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }
        }
        
        return new Response(JSON.stringify({
          success: true,
          message: 'Push notification queued (DB not configured)'
        }), { headers: corsHeaders });
      }

      // ====================================================================
      // 404 - Endpoint nicht gefunden
      // ====================================================================
      return new Response(JSON.stringify({ 
        error: 'Endpoint not found',
        available_endpoints: [
          'GET /api/health',
          'GET /api/chat/{room}',
          'POST /api/chat/{room}',
          'GET /api/tools/{tool}',
          'POST /api/tools/{tool}',
          'POST /api/push/subscribe',
          'POST /api/push/send'
        ]
      }), { 
        status: 404, 
        headers: corsHeaders 
      });

    } catch (error) {
      return new Response(JSON.stringify({ 
        error: 'Internal Server Error',
        message: error.message 
      }), { 
        status: 500, 
        headers: corsHeaders 
      });
    }
  }
};
