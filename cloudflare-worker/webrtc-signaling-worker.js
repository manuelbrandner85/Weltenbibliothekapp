/**
 * 🎤 WELTENBIBLIOTHEK - WEBRTC SIGNALING SERVER
 * 
 * Cloudflare Worker für WebRTC Voice Chat Signaling
 * Version: 1.0.0
 * 
 * Features:
 * - WebSocket-based signaling für WebRTC peer connections
 * - Room-basiertes Routing (MATERIE, ENERGIE, SPIRIT)
 * - Participant limit enforcement (max 10 per room)
 * - Admin controls (kick, mute)
 * - Connection health monitoring
 * - Automatic cleanup von disconnected peers
 */

// ═══════════════════════════════════════════════════════════════════════════
// 📋 CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const CONFIG = {
  MAX_PARTICIPANTS_PER_ROOM: 10,
  CONNECTION_TIMEOUT_MS: 30000,     // 30 seconds
  HEARTBEAT_INTERVAL_MS: 15000,      // 15 seconds  
  AUTH_TOKEN: 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB', // Admin/WebRTC token
  ALLOWED_ORIGINS: ['*'],            // CORS - adjust for production
};

// ═══════════════════════════════════════════════════════════════════════════
// 🗄️ GLOBAL STATE (in-memory for this worker)
// ═══════════════════════════════════════════════════════════════════════════

class RoomManager {
  constructor() {
    // rooms: { roomId: { participants: Map<userId, ParticipantData> } }
    this.rooms = new Map();
  }

  createRoom(roomId) {
    if (!this.rooms.has(roomId)) {
      this.rooms.set(roomId, {
        participants: new Map(),
        createdAt: Date.now(),
      });
      console.log(`✅ Room created: ${roomId}`);
    }
  }

  getRoomSize(roomId) {
    const room = this.rooms.get(roomId);
    return room ? room.participants.size : 0;
  }

  addParticipant(roomId, userId, participantData) {
    this.createRoom(roomId);
    const room = this.rooms.get(roomId);
    
    if (room.participants.size >= CONFIG.MAX_PARTICIPANTS_PER_ROOM) {
      throw new Error('Room full');
    }

    room.participants.set(userId, participantData);
    console.log(`✅ Participant added: ${userId} → ${roomId} (${room.participants.size}/${CONFIG.MAX_PARTICIPANTS_PER_ROOM})`);
  }

  removeParticipant(roomId, userId) {
    const room = this.rooms.get(roomId);
    if (room) {
      const deleted = room.participants.delete(userId);
      console.log(`✅ Participant removed: ${userId} from ${roomId} (deleted: ${deleted})`);
      
      // Cleanup empty rooms
      if (room.participants.size === 0) {
        this.rooms.delete(roomId);
        console.log(`✅ Room deleted (empty): ${roomId}`);
      }
      return deleted;
    }
    return false;
  }

  getParticipants(roomId) {
    const room = this.rooms.get(roomId);
    return room ? Array.from(room.participants.entries()) : [];
  }

  getAllRooms() {
    return Array.from(this.rooms.entries()).map(([roomId, room]) => ({
      roomId,
      participantCount: room.participants.size,
      participants: Array.from(room.participants.keys()),
    }));
  }

  isRoomFull(roomId) {
    return this.getRoomSize(roomId) >= CONFIG.MAX_PARTICIPANTS_PER_ROOM;
  }
}

const roomManager = new RoomManager();

// ═══════════════════════════════════════════════════════════════════════════
// 🌐 HTTP REQUEST HANDLER
// ═══════════════════════════════════════════════════════════════════════════

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle OPTIONS (CORS preflight)
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // ───────────────────────────────────────────────────────────────────────
    // 🎤 WebSocket Upgrade für Signaling
    // ───────────────────────────────────────────────────────────────────────
    if (path === '/voice/signaling') {
      // Check for WebSocket upgrade
      const upgradeHeader = request.headers.get('Upgrade');
      if (upgradeHeader !== 'websocket') {
        return new Response('Expected WebSocket upgrade', { 
          status: 426,
          headers: corsHeaders,
        });
      }

      // Create WebSocket pair
      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      // Accept WebSocket connection
      await handleWebSocket(server, request);

      return new Response(null, {
        status: 101,
        webSocket: client,
        headers: corsHeaders,
      });
    }

    // ───────────────────────────────────────────────────────────────────────
    // 📊 HTTP API Endpoints
    // ───────────────────────────────────────────────────────────────────────

    // GET /voice/rooms - List all active rooms
    if (path === '/voice/rooms' && request.method === 'GET') {
      return new Response(JSON.stringify({
        success: true,
        rooms: roomManager.getAllRooms(),
        timestamp: Date.now(),
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // GET /voice/rooms/:roomId - Get room info
    if (path.startsWith('/voice/rooms/') && request.method === 'GET') {
      const roomId = path.split('/').pop();
      const participants = roomManager.getParticipants(roomId);
      
      return new Response(JSON.stringify({
        success: true,
        roomId,
        participantCount: participants.length,
        isFull: roomManager.isRoomFull(roomId),
        maxParticipants: CONFIG.MAX_PARTICIPANTS_PER_ROOM,
        participants: participants.map(([userId, data]) => ({
          userId,
          username: data.username,
          joinedAt: data.joinedAt,
        })),
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ───────────────────────────────────────────────────────────────────────
    // 🛡️ ADMIN ENDPOINTS (Authentication required)
    // ───────────────────────────────────────────────────────────────────────

    // POST /admin/users/:userId/ban - Ban user
    if (path.startsWith('/admin/users/') && path.endsWith('/ban') && request.method === 'POST') {
      const authResult = validateAuth(request);
      if (!authResult.valid) {
        return new Response(JSON.stringify({ 
          success: false, 
          error: authResult.error 
        }), { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      const userId = path.split('/')[3];
      const body = await request.json();
      const { reason, durationHours = 24 } = body;

      // TODO: Persist ban to D1 database
      console.log(`🚫 User banned: ${userId} for ${durationHours}h - Reason: ${reason}`);

      return new Response(JSON.stringify({
        success: true,
        message: `User ${userId} banned for ${durationHours} hours`,
        userId,
        reason,
        expiresAt: Date.now() + (durationHours * 3600000),
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // POST /admin/users/:userId/mute - Mute user
    if (path.startsWith('/admin/users/') && path.endsWith('/mute') && request.method === 'POST') {
      const authResult = validateAuth(request);
      if (!authResult.valid) {
        return new Response(JSON.stringify({ 
          success: false, 
          error: authResult.error 
        }), { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      const userId = path.split('/')[3];
      const body = await request.json();
      const { reason, durationMinutes = 60 } = body;

      // TODO: Persist mute to D1 database
      console.log(`🔇 User muted: ${userId} for ${durationMinutes}min - Reason: ${reason}`);

      return new Response(JSON.stringify({
        success: true,
        message: `User ${userId} muted for ${durationMinutes} minutes`,
        userId,
        reason,
        expiresAt: Date.now() + (durationMinutes * 60000),
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // POST /admin/users/:userId/unban - Unban user
    if (path.startsWith('/admin/users/') && path.endsWith('/unban') && request.method === 'POST') {
      const authResult = validateAuth(request);
      if (!authResult.valid) {
        return new Response(JSON.stringify({ 
          success: false, 
          error: authResult.error 
        }), { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      const userId = path.split('/')[3];

      // TODO: Remove ban from D1 database
      console.log(`✅ User unbanned: ${userId}`);

      return new Response(JSON.stringify({
        success: true,
        message: `User ${userId} unbanned`,
        userId,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // DELETE /admin/delete/:world/:userId - Delete user
    if (path.startsWith('/api/admin/delete/') && request.method === 'DELETE') {
      const authResult = validateAuth(request);
      if (!authResult.valid) {
        return new Response(JSON.stringify({ 
          success: false, 
          error: authResult.error 
        }), { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      const pathParts = path.split('/');
      const world = pathParts[4];
      const userId = pathParts[5];

      // TODO: Delete user from D1 database
      console.log(`🗑️ User deleted: ${userId} from world ${world}`);

      return new Response(JSON.stringify({
        success: true,
        message: `User ${userId} deleted from ${world}`,
        world,
        userId,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ───────────────────────────────────────────────────────────────────────
    // 🏥 Health Check
    // ───────────────────────────────────────────────────────────────────────
    if (path === '/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        service: 'weltenbibliothek-webrtc-signaling',
        version: '1.0.0',
        timestamp: Date.now(),
        activeRooms: roomManager.getAllRooms().length,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Default 404
    return new Response('Not Found', { status: 404, headers: corsHeaders });
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// 🔐 AUTHENTICATION HELPER
// ═══════════════════════════════════════════════════════════════════════════

function validateAuth(request) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader) {
    return { valid: false, error: 'Missing Authorization header' };
  }

  const token = authHeader.replace('Bearer ', '');
  
  if (token !== CONFIG.AUTH_TOKEN) {
    return { valid: false, error: 'Invalid token' };
  }

  return { valid: true };
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔌 WEBSOCKET HANDLER
// ═══════════════════════════════════════════════════════════════════════════

async function handleWebSocket(websocket, request) {
  websocket.accept();

  let roomId = null;
  let userId = null;
  let heartbeatInterval = null;

  websocket.addEventListener('message', async (event) => {
    try {
      const data = JSON.parse(event.data);
      console.log(`📥 Received: ${data.type} from ${userId || 'unknown'}`);

      switch (data.type) {
        // ─────────────────────────────────────────────────────────────────
        // JOIN ROOM
        // ─────────────────────────────────────────────────────────────────
        case 'join':
          roomId = data.roomId;
          userId = data.userId;
          const username = data.username || 'Anonymous';

          // Check if room is full
          if (roomManager.isRoomFull(roomId)) {
            websocket.send(JSON.stringify({
              type: 'error',
              error: 'room_full',
              message: `Room ${roomId} is full (max ${CONFIG.MAX_PARTICIPANTS_PER_ROOM} participants)`,
            }));
            websocket.close(1000, 'Room full');
            return;
          }

          // Add participant
          roomManager.addParticipant(roomId, userId, {
            username,
            websocket,
            joinedAt: Date.now(),
          });

          // Send confirmation
          websocket.send(JSON.stringify({
            type: 'joined',
            roomId,
            userId,
            participants: roomManager.getParticipants(roomId).map(([id, data]) => ({
              userId: id,
              username: data.username,
            })),
          }));

          // Notify other participants
          broadcastToRoom(roomId, {
            type: 'user-joined',
            userId,
            username,
          }, userId);

          // Start heartbeat
          heartbeatInterval = setInterval(() => {
            try {
              websocket.send(JSON.stringify({ type: 'ping' }));
            } catch (e) {
              console.error('❌ Heartbeat failed:', e);
              clearInterval(heartbeatInterval);
            }
          }, CONFIG.HEARTBEAT_INTERVAL_MS);

          break;

        // ─────────────────────────────────────────────────────────────────
        // LEAVE ROOM
        // ─────────────────────────────────────────────────────────────────
        case 'leave':
          if (roomId && userId) {
            roomManager.removeParticipant(roomId, userId);
            
            // Notify other participants
            broadcastToRoom(roomId, {
              type: 'user-left',
              userId,
            }, userId);

            // Clear heartbeat
            if (heartbeatInterval) {
              clearInterval(heartbeatInterval);
            }
          }
          break;

        // ─────────────────────────────────────────────────────────────────
        // WEBRTC SIGNALING: OFFER
        // ─────────────────────────────────────────────────────────────────
        case 'offer':
          if (roomId && userId) {
            const targetUserId = data.targetUserId;
            const sdp = data.sdp;

            // Forward offer to target peer
            const participants = roomManager.getParticipants(roomId);
            const target = participants.find(([id]) => id === targetUserId);
            
            if (target) {
              const [, targetData] = target;
              targetData.websocket.send(JSON.stringify({
                type: 'offer',
                fromUserId: userId,
                sdp,
              }));
            }
          }
          break;

        // ─────────────────────────────────────────────────────────────────
        // WEBRTC SIGNALING: ANSWER
        // ─────────────────────────────────────────────────────────────────
        case 'answer':
          if (roomId && userId) {
            const targetUserId = data.targetUserId;
            const sdp = data.sdp;

            // Forward answer to target peer
            const participants = roomManager.getParticipants(roomId);
            const target = participants.find(([id]) => id === targetUserId);
            
            if (target) {
              const [, targetData] = target;
              targetData.websocket.send(JSON.stringify({
                type: 'answer',
                fromUserId: userId,
                sdp,
              }));
            }
          }
          break;

        // ─────────────────────────────────────────────────────────────────
        // WEBRTC SIGNALING: ICE CANDIDATE
        // ─────────────────────────────────────────────────────────────────
        case 'ice-candidate':
          if (roomId && userId) {
            const targetUserId = data.targetUserId;
            const candidate = data.candidate;

            // Forward ICE candidate to target peer
            const participants = roomManager.getParticipants(roomId);
            const target = participants.find(([id]) => id === targetUserId);
            
            if (target) {
              const [, targetData] = target;
              targetData.websocket.send(JSON.stringify({
                type: 'ice-candidate',
                fromUserId: userId,
                candidate,
              }));
            }
          }
          break;

        // ─────────────────────────────────────────────────────────────────
        // MUTE STATUS UPDATE
        // ─────────────────────────────────────────────────────────────────
        case 'mute':
          if (roomId && userId) {
            const isMuted = data.isMuted;

            // Broadcast mute status to room
            broadcastToRoom(roomId, {
              type: 'user-muted',
              userId,
              isMuted,
            }, userId);
          }
          break;

        // ─────────────────────────────────────────────────────────────────
        // HEARTBEAT PONG
        // ─────────────────────────────────────────────────────────────────
        case 'pong':
          // Acknowledge heartbeat
          break;

        default:
          console.warn(`⚠️ Unknown message type: ${data.type}`);
      }
    } catch (error) {
      console.error('❌ WebSocket message error:', error);
      websocket.send(JSON.stringify({
        type: 'error',
        error: 'invalid_message',
        message: error.message,
      }));
    }
  });

  websocket.addEventListener('close', () => {
    console.log(`🔌 WebSocket closed: ${userId}`);
    
    // Cleanup
    if (roomId && userId) {
      roomManager.removeParticipant(roomId, userId);
      
      // Notify other participants
      broadcastToRoom(roomId, {
        type: 'user-left',
        userId,
      });
    }

    // Clear heartbeat
    if (heartbeatInterval) {
      clearInterval(heartbeatInterval);
    }
  });

  websocket.addEventListener('error', (error) => {
    console.error('❌ WebSocket error:', error);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 📡 BROADCAST HELPER
// ═══════════════════════════════════════════════════════════════════════════

function broadcastToRoom(roomId, message, excludeUserId = null) {
  const participants = roomManager.getParticipants(roomId);
  const messageStr = JSON.stringify(message);

  participants.forEach(([userId, data]) => {
    if (userId !== excludeUserId) {
      try {
        data.websocket.send(messageStr);
      } catch (error) {
        console.error(`❌ Failed to send to ${userId}:`, error);
      }
    }
  });
}
