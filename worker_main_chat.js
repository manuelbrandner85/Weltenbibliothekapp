// ============================================================================
// WELTENBIBLIOTHEK V99 - MAIN API WORKER WITH CHAT
// ============================================================================
// Kombiniert Main API + Chat + WebSocket Support
// D1-Datenbank: weltenbibliothek-db
// Durable Objects: ChatRoom (WebSocket-Support)
// ============================================================================

// Import ChatRoom Durable Object
export { ChatRoom } from './chat_room.js';

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS + Security Headers für alle Antworten
    const corsHeaders = {
      // CORS Headers
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Expose-Headers': 'Content-Type',
      'Content-Type': 'application/json',
      // Security Headers
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
      'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.workers.dev https://*.pages.dev wss://*.workers.dev",
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=(), payment=(), usb=(), magnetometer=(), gyroscope=()',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'X-XSS-Protection': '1; mode=block',
    };

    // OPTIONS pre-flight handling
    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ====================================================================
      // ROOT ENDPOINT - API OVERVIEW
      // ====================================================================
      if (path === '/') {
        const apiInfo = {
          service: 'Weltenbibliothek API',
          version: '99.0 (Chat Edition)',
          status: 'online',
          endpoints: {
            health: '/health or /api/health',
            knowledge: '/api/knowledge/*',
            community: '/api/community/*',
            articles: '/api/articles/*',
            chat: '/api/chat/:room (GET/POST/PUT/DELETE)',
            websocket: '/api/ws?room=:roomId',
            chat_rooms: 'politik, geschichte, ufo, verschwoerungen, wissenschaft, meditation, astralreisen, chakren, spiritualitaet, heilung',
            documentation: 'https://weltenbibliothek-ey9.pages.dev'
          },
          database: env.DB ? 'connected' : 'not_connected',
          chat: {
            enabled: true,
            websocket: true,
            durable_objects: true,
            rooms: 10
          },
          message: 'API with Chat is running. Use documented endpoints.'
        };
        
        return new Response(JSON.stringify(apiInfo, null, 2), { 
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // HEALTH CHECK
      // ====================================================================
      if (path === '/health' || path === '/api/health') {
        let dbStatus = 'not_connected';
        let dbError = null;

        if (env.DB) {
          try {
            // Test DB connection with simple query
            const testResult = await env.DB.prepare(
              'SELECT 1 as test'
            ).first();
            
            if (testResult && testResult.test === 1) {
              dbStatus = 'connected';
            }
          } catch (error) {
            dbStatus = 'error';
            dbError = error.message;
          }
        }

        return new Response(JSON.stringify({
          status: 'healthy',
          version: '99.0',
          timestamp: new Date().toISOString(),
          services: {
            api: 'online',
            database: dbStatus,
            cors: 'enabled',
            chat: 'enabled',
            websocket: 'enabled',
            durable_objects: 'enabled'
          },
          database_error: dbError,
          uptime: 'continuous',
          chat_rooms: 10
        }), { headers: corsHeaders });
      }

      // ====================================================================
      // WEBSOCKET ENDPOINT
      // ====================================================================
      if (path === '/api/ws') {
        const upgradeHeader = request.headers.get('Upgrade');
        if (upgradeHeader !== 'websocket') {
          return new Response(JSON.stringify({
            error: 'Expected WebSocket',
            upgrade_header: upgradeHeader,
            help: 'Use WebSocket connection with Upgrade header'
          }), { 
            status: 426,
            headers: corsHeaders 
          });
        }

        // Hole roomId aus Query-Parameter
        const roomId = url.searchParams.get('room');
        if (!roomId) {
          return new Response(JSON.stringify({
            error: 'Missing room parameter',
            help: 'Add ?room=roomname to URL'
          }), { 
            status: 400,
            headers: corsHeaders 
          });
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
        const validRooms = [
          'politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft', 
          'meditation', 'astralreisen', 'chakren', 'spiritualitaet', 'heilung'
        ];
        
        if (!validRooms.includes(roomId)) {
          return new Response(JSON.stringify({ 
            error: 'Invalid room ID',
            provided: roomId,
            valid_rooms: validRooms 
          }), { 
            status: 400, 
            headers: corsHeaders 
          });
        }

        // GET - Nachrichten abrufen
        if (method === 'GET') {
          const limit = parseInt(url.searchParams.get('limit') || '50');
          const offset = parseInt(url.searchParams.get('offset') || '0');
          
          if (env.DB) {
            try {
              const result = await env.DB.prepare(
                `SELECT * FROM chat_messages 
                 WHERE room_id = ? 
                 ORDER BY timestamp DESC 
                 LIMIT ? OFFSET ?`
              ).bind(roomId, limit, offset).all();

              return new Response(JSON.stringify({
                success: true,
                room_id: roomId,
                messages: result.results || [],
                count: result.results?.length || 0,
                limit: limit,
                offset: offset
              }), { headers: corsHeaders });
            } catch (error) {
              return new Response(JSON.stringify({
                error: 'Database query failed',
                details: error.message,
                room_id: roomId
              }), { 
                status: 500, 
                headers: corsHeaders 
              });
            }
          } else {
            // Fallback: Welcome message wenn DB nicht verfügbar
            return new Response(JSON.stringify({
              success: true,
              room_id: roomId,
              messages: [
                {
                  id: 'msg_welcome',
                  room_id: roomId,
                  username: 'System',
                  message: `Willkommen im ${roomId} Raum! 🌟 Datenbank wird initialisiert...`,
                  timestamp: Date.now(),
                  avatar: '🌟'
                }
              ],
              count: 1,
              database_status: 'connecting'
            }), { headers: corsHeaders });
          }
        }

        // POST - Neue Nachricht senden
        if (method === 'POST') {
          try {
            const body = await request.json();
            const { username, message, realm, avatar } = body;

            if (!username || !message) {
              return new Response(JSON.stringify({ 
                error: 'username and message are required',
                received: { username, message }
              }), { 
                status: 400, 
                headers: corsHeaders 
              });
            }

            // Bestimme Realm basierend auf Room-ID (wenn nicht angegeben)
            const materieRooms = ['politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft'];
            const finalRealm = realm || (materieRooms.includes(roomId) ? 'materie' : 'energie');
            const timestamp = Date.now();
            const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            const userId = `user_${username.toLowerCase().replace(/\s+/g, '_')}`;
            const finalAvatar = avatar || '👤';

            if (env.DB) {
              try {
                // id ist AUTOINCREMENT, wir übergeben es nicht
                const result = await env.DB.prepare(
                  `INSERT INTO chat_messages (room_id, realm, user_id, username, message, avatar, timestamp)
                   VALUES (?, ?, ?, ?, ?, ?, ?)`
                ).bind(
                  roomId, 
                  finalRealm,
                  userId,
                  username, 
                  message,
                  finalAvatar,
                  timestamp
                ).run();

                // Hole die generierte ID
                const insertedId = result.meta.last_row_id;

                return new Response(JSON.stringify({
                  success: true,
                  id: insertedId,
                  room_id: roomId,
                  timestamp: timestamp,
                  realm: finalRealm
                }), { headers: corsHeaders });
              } catch (error) {
                return new Response(JSON.stringify({
                  error: 'Failed to save message',
                  details: error.message
                }), { 
                  status: 500, 
                  headers: corsHeaders 
                });
              }
            } else {
              // Fallback: Mock-Response
              return new Response(JSON.stringify({
                success: true,
                id: messageId,
                room_id: roomId,
                timestamp: timestamp,
                database_status: 'not_connected',
                message: 'Message received but not persisted'
              }), { headers: corsHeaders });
            }
          } catch (error) {
            return new Response(JSON.stringify({
              error: 'Invalid request body',
              details: error.message
            }), { 
              status: 400, 
              headers: corsHeaders 
            });
          }
        }

        // PUT - Nachricht bearbeiten
        if (method === 'PUT') {
          try {
            const body = await request.json();
            const { messageId, userId, message } = body;

            if (!messageId || !userId || !message) {
              return new Response(JSON.stringify({ 
                error: 'messageId, userId, and message are required',
                received: { messageId, userId, message }
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
                  error: 'Message not found',
                  messageId: messageId,
                  roomId: roomId
                }), { 
                  status: 404, 
                  headers: corsHeaders 
                });
              }

              if (check.user_id !== userId) {
                return new Response(JSON.stringify({ 
                  error: 'Unauthorized: You can only edit your own messages',
                  message_owner: check.user_id,
                  your_id: userId
                }), { 
                  status: 403, 
                  headers: corsHeaders 
                });
              }

              // Update Nachricht
              await env.DB.prepare(
                `UPDATE chat_messages 
                 SET message = ?, timestamp = ? 
                 WHERE id = ? AND room_id = ?`
              ).bind(message, Date.now(), messageId, roomId).run();

              return new Response(JSON.stringify({
                success: true,
                id: messageId,
                room_id: roomId,
                updated: true
              }), { headers: corsHeaders });
            } else {
              return new Response(JSON.stringify({
                error: 'Database not available',
                database_status: 'not_connected'
              }), { 
                status: 503, 
                headers: corsHeaders 
              });
            }
          } catch (error) {
            return new Response(JSON.stringify({
              error: 'Failed to update message',
              details: error.message
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }
        }

        // DELETE - Nachricht löschen
        if (method === 'DELETE') {
          try {
            const body = await request.json();
            const { messageId, userId } = body;

            if (!messageId || !userId) {
              return new Response(JSON.stringify({ 
                error: 'messageId and userId are required',
                received: { messageId, userId }
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
                  error: 'Message not found',
                  messageId: messageId,
                  roomId: roomId
                }), { 
                  status: 404, 
                  headers: corsHeaders 
                });
              }

              if (check.user_id !== userId) {
                return new Response(JSON.stringify({ 
                  error: 'Unauthorized: You can only delete your own messages',
                  message_owner: check.user_id,
                  your_id: userId
                }), { 
                  status: 403, 
                  headers: corsHeaders 
                });
              }

              // Lösche Nachricht
              await env.DB.prepare(
                `DELETE FROM chat_messages WHERE id = ? AND room_id = ?`
              ).bind(messageId, roomId).run();

              return new Response(JSON.stringify({
                success: true,
                id: messageId,
                room_id: roomId,
                deleted: true
              }), { headers: corsHeaders });
            } else {
              return new Response(JSON.stringify({
                error: 'Database not available',
                database_status: 'not_connected'
              }), { 
                status: 503, 
                headers: corsHeaders 
              });
            }
          } catch (error) {
            return new Response(JSON.stringify({
              error: 'Failed to delete message',
              details: error.message
            }), { 
              status: 500, 
              headers: corsHeaders 
            });
          }
        }
      }

      // ====================================================================
      // KNOWLEDGE ENDPOINTS (Placeholder)
      // ====================================================================
      if (path.startsWith('/api/knowledge')) {
        return new Response(JSON.stringify({
          message: 'Knowledge API endpoints',
          available: [
            'GET /api/knowledge - List all entries',
            'GET /api/knowledge/:id - Get specific entry'
          ],
          status: 'coming_soon'
        }), { headers: corsHeaders });
      }

      // ====================================================================
      // COMMUNITY ENDPOINTS (Placeholder)
      // ====================================================================
      if (path.startsWith('/api/community')) {
        return new Response(JSON.stringify({
          message: 'Community API endpoints',
          available: [
            'GET /api/community/posts - List posts',
            'POST /api/community/posts - Create post',
            'GET /api/community/posts/:id - Get post'
          ],
          status: 'coming_soon',
          note: 'Use weltenbibliothek-community-api.brandy13062.workers.dev for community features'
        }), { headers: corsHeaders });
      }

      // ====================================================================
      // 404 - ROUTE NOT FOUND
      // ====================================================================
      return new Response(JSON.stringify({
        error: 'Route not found',
        path: path,
        method: method,
        available_endpoints: {
          root: '/',
          health: '/health or /api/health',
          chat: '/api/chat/:room (GET/POST/PUT/DELETE)',
          websocket: '/api/ws?room=:roomId',
          knowledge: '/api/knowledge',
          community: '/api/community'
        },
        chat_rooms: [
          'politik', 'geschichte', 'ufo', 'verschwoerungen', 'wissenschaft',
          'meditation', 'astralreisen', 'chakren', 'spiritualitaet', 'heilung'
        ],
        documentation: 'https://weltenbibliothek-ey9.pages.dev',
        suggestion: 'Check the available endpoints above'
      }), { 
        status: 404, 
        headers: corsHeaders 
      });

    } catch (error) {
      // Global error handler
      return new Response(JSON.stringify({
        error: 'Internal server error',
        message: error.message,
        path: path,
        method: method
      }), { 
        status: 500, 
        headers: corsHeaders 
      });
    }
  }
};
