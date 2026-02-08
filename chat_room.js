// ============================================================================
// WELTENBIBLIOTHEK V98 - CHAT ROOM DURABLE OBJECT
// ============================================================================
// WebSocket-basiertes Chat-System mit Cloudflare Durable Objects
// Echtzeit-Nachrichten + Tool-Aktivitäten
// ============================================================================

export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Set();
    
    // Broadcast-Queue für Nachrichten
    this.messageQueue = [];
    this.broadcastInterval = null;
  }

  async fetch(request) {
    const url = new URL(request.url);
    
    // ✅ Internal broadcast endpoint (for push notifications)
    if (url.pathname === '/broadcast' && request.method === 'POST') {
      try {
        const body = await request.json();
        this.broadcast({
          type: body.type || 'notification',
          message: body.message,
          title: body.title,
          roomId: body.roomId,
          timestamp: Date.now()
        });
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json' }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), {
          status: 500,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }
    
    // WebSocket-Upgrade
    if (request.headers.get('Upgrade') === 'websocket') {
      return this.handleWebSocket(request);
    }
    
    // HTTP Fallback für Polling
    return new Response('WebSocket required', { status: 426 });
  }

  async handleWebSocket(request) {
    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);

    // Accept WebSocket connection
    this.state.acceptWebSocket(server);
    
    const session = {
      webSocket: server,
      userId: `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      username: null,
      roomId: null,
      connectedAt: Date.now(),
    };

    this.sessions.add(session);

    // Handle incoming messages
    server.addEventListener('message', async (event) => {
      try {
        const data = JSON.parse(event.data);
        await this.handleMessage(session, data);
      } catch (error) {
        console.error('WebSocket message error:', error);
        server.send(JSON.stringify({
          type: 'error',
          message: 'Invalid message format'
        }));
      }
    });

    // Handle connection close
    server.addEventListener('close', () => {
      this.sessions.delete(session);
      this.broadcastToRoom(session.roomId, {
        type: 'user_left',
        userId: session.userId,
        username: session.username,
        timestamp: Date.now(),
      });
    });

    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }

  async handleMessage(session, data) {
    const { type, payload } = data;

    switch (type) {
      case 'join':
        // User tritt Raum bei
        session.username = payload.username || `User${session.userId.substr(-4)}`;
        session.roomId = payload.roomId;
        
        // Willkommens-Nachricht
        session.webSocket.send(JSON.stringify({
          type: 'joined',
          userId: session.userId,
          username: session.username,
          roomId: session.roomId,
          timestamp: Date.now(),
        }));

        // Broadcast an andere User
        this.broadcastToRoom(session.roomId, {
          type: 'user_joined',
          userId: session.userId,
          username: session.username,
          timestamp: Date.now(),
        }, session.userId);

        // Sende letzte 50 Nachrichten aus D1
        await this.sendRecentMessages(session);
        break;

      case 'message':
        // Chat-Nachricht senden
        const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const messageData = {
          id: messageId,
          room_id: session.roomId,
          user_id: session.userId,
          username: session.username,
          message: payload.message,
          realm: payload.realm || 'materie',
          avatar: payload.avatar || '👤',
          timestamp: Date.now(),
        };

        // Speichere in D1
        if (this.env.DB) {
          try {
            await this.env.DB.prepare(
              `INSERT INTO chat_messages (id, room_id, user_id, username, message, realm, avatar, timestamp)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
            ).bind(
              messageData.id,
              messageData.room_id,
              messageData.user_id,
              messageData.username,
              messageData.message,
              messageData.realm,
              messageData.avatar,
              messageData.timestamp
            ).run();
          } catch (error) {
            console.error('D1 insert error:', error);
          }
        }

        // Broadcast an alle User im Raum
        this.broadcastToRoom(session.roomId, {
          type: 'new_message',
          message: messageData,
        });
        break;

      case 'tool_activity':
        // Tool-Aktivität posten
        const activityId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const activityMessage = `${payload.icon || '🔧'} ${session.username} nutzt ${payload.toolName}: ${payload.activity}`;
        
        const activityData = {
          id: activityId,
          room_id: session.roomId,
          user_id: session.userId,
          username: session.username,
          message: activityMessage,
          realm: payload.realm || 'materie',
          avatar: payload.icon || '🔧',
          timestamp: Date.now(),
        };

        // Speichere in D1
        if (this.env.DB) {
          try {
            await this.env.DB.prepare(
              `INSERT INTO chat_messages (id, room_id, user_id, username, message, realm, avatar, timestamp)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
            ).bind(
              activityData.id,
              activityData.room_id,
              activityData.user_id,
              activityData.username,
              activityData.message,
              activityData.realm,
              activityData.avatar,
              activityData.timestamp
            ).run();
          } catch (error) {
            console.error('D1 insert error:', error);
          }
        }

        // Broadcast Tool-Aktivität
        this.broadcastToRoom(session.roomId, {
          type: 'new_message',
          message: activityData,
        });
        break;

      case 'typing':
        // Typing-Indicator
        this.broadcastToRoom(session.roomId, {
          type: 'user_typing',
          userId: session.userId,
          username: session.username,
          isTyping: payload.isTyping,
        }, session.userId);
        break;

      case 'ping':
        // Heartbeat
        session.webSocket.send(JSON.stringify({
          type: 'pong',
          timestamp: Date.now(),
        }));
        break;

      default:
        console.warn('Unknown message type:', type);
    }
  }

  async sendRecentMessages(session) {
    if (!this.env.DB || !session.roomId) return;

    try {
      const result = await this.env.DB.prepare(
        `SELECT * FROM chat_messages 
         WHERE room_id = ? 
         ORDER BY timestamp DESC 
         LIMIT 50`
      ).bind(session.roomId).all();

      if (result.results && result.results.length > 0) {
        // Sende in richtiger Reihenfolge (älteste zuerst)
        const messages = result.results.reverse();
        session.webSocket.send(JSON.stringify({
          type: 'history',
          messages: messages,
        }));
      }
    } catch (error) {
      console.error('Failed to load recent messages:', error);
    }
  }

  broadcastToRoom(roomId, message, excludeUserId = null) {
    if (!roomId) return;

    const payload = JSON.stringify(message);
    
    for (const session of this.sessions) {
      if (session.roomId === roomId && session.userId !== excludeUserId) {
        try {
          session.webSocket.send(payload);
        } catch (error) {
          console.error('Broadcast error:', error);
          this.sessions.delete(session);
        }
      }
    }
  }

  getRoomStats(roomId) {
    const activeUsers = Array.from(this.sessions)
      .filter(s => s.roomId === roomId)
      .map(s => ({
        userId: s.userId,
        username: s.username,
        connectedAt: s.connectedAt,
      }));

    return {
      roomId,
      activeUsers: activeUsers.length,
      users: activeUsers,
    };
  }
}
