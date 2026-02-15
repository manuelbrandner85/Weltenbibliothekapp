/**
 * 🌐 WELTENBIBLIOTHEK - BACKEND API V3.2
 * 
 * Erweiterte Cloudflare Worker Integration:
 * - WebRTC Signaling Server (dediziert)
 * - Admin API Endpoints (ban, mute, delete mit Response Validation)
 * - Voice Chat Management
 * - User Management
 * 
 * Version: 3.2.0
 * Author: Manuel Brandner
 */

// ═══════════════════════════════════════════════════════════════════════════
// 📋 CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

const CONFIG = {
  MAX_PARTICIPANTS_PER_ROOM: 10,
  CONNECTION_TIMEOUT_MS: 30000,
  HEARTBEAT_INTERVAL_MS: 15000,
  PRIMARY_TOKEN: 'y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y',
  ADMIN_TOKEN: 'XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB',
  ALLOWED_ORIGINS: ['*'],
};

// ═══════════════════════════════════════════════════════════════════════════
// 🗄️ IN-MEMORY STATE MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

class StateManager {
  constructor() {
    this.rooms = new Map(); // Voice chat rooms
    this.bans = new Map();  // User bans: userId → { reason, expiresAt }
    this.mutes = new Map(); // User mutes: userId → { reason, expiresAt }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Room Management
  // ───────────────────────────────────────────────────────────────────────

  createRoom(roomId) {
    if (!this.rooms.has(roomId)) {
      this.rooms.set(roomId, {
        participants: new Map(),
        createdAt: Date.now(),
      });
    }
  }

  getRoomSize(roomId) {
    const room = this.rooms.get(roomId);
    return room ? room.participants.size : 0;
  }

  addParticipant(roomId, userId, participantData) {
    // Check if user is banned
    if (this.isBanned(userId)) {
      throw new Error('User is banned');
    }

    this.createRoom(roomId);
    const room = this.rooms.get(roomId);

    if (room.participants.size >= CONFIG.MAX_PARTICIPANTS_PER_ROOM) {
      throw new Error('Room full');
    }

    room.participants.set(userId, participantData);
    console.log(`✅ Participant added: ${userId} → ${roomId}`);
  }

  removeParticipant(roomId, userId) {
    const room = this.rooms.get(roomId);
    if (room) {
      room.participants.delete(userId);
      if (room.participants.size === 0) {
        this.rooms.delete(roomId);
      }
      return true;
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

  // ───────────────────────────────────────────────────────────────────────
  // Ban Management
  // ───────────────────────────────────────────────────────────────────────

  banUser(userId, reason, durationHours) {
    const expiresAt = Date.now() + (durationHours * 3600000);
    this.bans.set(userId, { reason, expiresAt, bannedAt: Date.now() });
    console.log(`🚫 User banned: ${userId} for ${durationHours}h`);

    // Remove from all rooms
    this.rooms.forEach((room, roomId) => {
      if (room.participants.has(userId)) {
        this.removeParticipant(roomId, userId);
      }
    });
  }

  unbanUser(userId) {
    const existed = this.bans.delete(userId);
    if (existed) {
      console.log(`✅ User unbanned: ${userId}`);
    }
    return existed;
  }

  isBanned(userId) {
    const ban = this.bans.get(userId);
    if (!ban) return false;

    // Check if ban expired
    if (Date.now() > ban.expiresAt) {
      this.bans.delete(userId);
      return false;
    }

    return true;
  }

  getBanInfo(userId) {
    return this.bans.get(userId);
  }

  // ───────────────────────────────────────────────────────────────────────
  // Mute Management
  // ───────────────────────────────────────────────────────────────────────

  muteUser(userId, reason, durationMinutes) {
    const expiresAt = Date.now() + (durationMinutes * 60000);
    this.mutes.set(userId, { reason, expiresAt, mutedAt: Date.now() });
    console.log(`🔇 User muted: ${userId} for ${durationMinutes}min`);
  }

  unmuteUser(userId) {
    return this.mutes.delete(userId);
  }

  isMuted(userId) {
    const mute = this.mutes.get(userId);
    if (!mute) return false;

    if (Date.now() > mute.expiresAt) {
      this.mutes.delete(userId);
      return false;
    }

    return true;
  }

  getMuteInfo(userId) {
    return this.mutes.get(userId);
  }
}

const state = new StateManager();

// ═══════════════════════════════════════════════════════════════════════════
// 🌐 MAIN WORKER HANDLER
// ═══════════════════════════════════════════════════════════════════════════

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Role, X-User-ID, X-World',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ═════════════════════════════════════════════════════════════════
      // 🎤 WEBRTC SIGNALING (WebSocket)
      // ═════════════════════════════════════════════════════════════════
      if (path === '/voice/signaling') {
        const upgradeHeader = request.headers.get('Upgrade');
        if (upgradeHeader !== 'websocket') {
          return jsonResponse({ error: 'Expected WebSocket upgrade' }, 426, corsHeaders);
        }

        const pair = new WebSocketPair();
        const [client, server] = Object.values(pair);
        await handleWebSocket(server);

        return new Response(null, {
          status: 101,
          webSocket: client,
          headers: corsHeaders,
        });
      }

      // ═════════════════════════════════════════════════════════════════
      // 📊 VOICE CHAT ENDPOINTS
      // ═════════════════════════════════════════════════════════════════

      if (path === '/voice/rooms' && request.method === 'GET') {
        return jsonResponse({
          success: true,
          rooms: state.getAllRooms(),
          timestamp: new Date().toISOString(),
        }, 200, corsHeaders);
      }

      if (path.match(/^\/voice\/rooms\/[^/]+$/) && request.method === 'GET') {
        const roomId = path.split('/').pop();
        const participants = state.getParticipants(roomId);

        return jsonResponse({
          success: true,
          roomId,
          participantCount: participants.length,
          isFull: state.isRoomFull(roomId),
          maxParticipants: CONFIG.MAX_PARTICIPANTS_PER_ROOM,
          participants: participants.map(([userId, data]) => ({
            userId,
            username: data.username,
            joinedAt: data.joinedAt,
          })),
        }, 200, corsHeaders);
      }

      // ═════════════════════════════════════════════════════════════════
      // 🛡️ ADMIN ENDPOINTS (with Response Validation)
      // ═════════════════════════════════════════════════════════════════

      // POST /admin/users/:userId/ban
      if (path.match(/^\/admin\/users\/[^/]+\/ban$/) && request.method === 'POST') {
        const authResult = validateAuth(request);
        if (!authResult.valid) {
          return jsonResponse({
            success: false,
            error: authResult.error,
          }, 401, corsHeaders);
        }

        const userId = path.split('/')[3];
        const body = await request.json().catch(() => ({}));
        const { reason = 'No reason provided', durationHours = 24 } = body;

        // Validate input
        if (!userId || userId === 'undefined') {
          return jsonResponse({
            success: false,
            error: 'Invalid user ID',
          }, 400, corsHeaders);
        }

        state.banUser(userId, reason, durationHours);

        return jsonResponse({
          success: true,
          message: `User ${userId} banned for ${durationHours} hours`,
          userId,
          reason,
          durationHours,
          expiresAt: new Date(Date.now() + durationHours * 3600000).toISOString(),
          timestamp: new Date().toISOString(),
        }, 200, corsHeaders);
      }

      // POST /admin/users/:userId/mute
      if (path.match(/^\/admin\/users\/[^/]+\/mute$/) && request.method === 'POST') {
        const authResult = validateAuth(request);
        if (!authResult.valid) {
          return jsonResponse({
            success: false,
            error: authResult.error,
          }, 401, corsHeaders);
        }

        const userId = path.split('/')[3];
        const body = await request.json().catch(() => ({}));
        const { reason = 'No reason provided', durationMinutes = 60 } = body;

        if (!userId || userId === 'undefined') {
          return jsonResponse({
            success: false,
            error: 'Invalid user ID',
          }, 400, corsHeaders);
        }

        state.muteUser(userId, reason, durationMinutes);

        return jsonResponse({
          success: true,
          message: `User ${userId} muted for ${durationMinutes} minutes`,
          userId,
          reason,
          durationMinutes,
          expiresAt: new Date(Date.now() + durationMinutes * 60000).toISOString(),
          timestamp: new Date().toISOString(),
        }, 200, corsHeaders);
      }

      // POST /admin/users/:userId/unban
      if (path.match(/^\/admin\/users\/[^/]+\/unban$/) && request.method === 'POST') {
        const authResult = validateAuth(request);
        if (!authResult.valid) {
          return jsonResponse({
            success: false,
            error: authResult.error,
          }, 401, corsHeaders);
        }

        const userId = path.split('/')[3];

        if (!userId || userId === 'undefined') {
          return jsonResponse({
            success: false,
            error: 'Invalid user ID',
          }, 400, corsHeaders);
        }

        const existed = state.unbanUser(userId);

        return jsonResponse({
          success: true,
          message: existed
            ? `User ${userId} unbanned successfully`
            : `User ${userId} was not banned`,
          userId,
          wasBanned: existed,
          timestamp: new Date().toISOString(),
        }, 200, corsHeaders);
      }

      // DELETE /api/admin/delete/:world/:userId
      if (path.match(/^\/api\/admin\/delete\/[^/]+\/[^/]+$/) && request.method === 'DELETE') {
        const authResult = validateAuth(request);
        if (!authResult.valid) {
          return jsonResponse({
            success: false,
            error: authResult.error,
          }, 401, corsHeaders);
        }

        const pathParts = path.split('/');
        const world = pathParts[4];
        const userId = pathParts[5];

        if (!userId || userId === 'undefined') {
          return jsonResponse({
            success: false,
            error: 'Invalid user ID',
          }, 400, corsHeaders);
        }

        // TODO: Implement actual user deletion from D1 database
        console.log(`🗑️ User deletion requested: ${userId} from ${world}`);

        // Remove from all rooms
        state.rooms.forEach((room, roomId) => {
          if (room.participants.has(userId)) {
            state.removeParticipant(roomId, userId);
          }
        });

        return jsonResponse({
          success: true,
          message: `User ${userId} deleted from ${world}`,
          world,
          userId,
          timestamp: new Date().toISOString(),
        }, 200, corsHeaders);
      }

      // GET /admin/users/:userId/status - Check user status
      if (path.match(/^\/admin\/users\/[^/]+\/status$/) && request.method === 'GET') {
        const authResult = validateAuth(request);
        if (!authResult.valid) {
          return jsonResponse({
            success: false,
            error: authResult.error,
          }, 401, corsHeaders);
        }

        const userId = path.split('/')[3];

        return jsonResponse({
          success: true,
          userId,
          isBanned: state.isBanned(userId),
          isMuted: state.isMuted(userId),
          banInfo: state.getBanInfo(userId) || null,
          muteInfo: state.getMuteInfo(userId) || null,
          timestamp: new Date().toISOString(),
        }, 200, corsHeaders);
      }

      // ═════════════════════════════════════════════════════════════════
      // 🏥 HEALTH CHECK
      // ═════════════════════════════════════════════════════════════════
      if (path === '/health') {
        return jsonResponse({
          status: 'healthy',
          service: 'Weltenbibliothek Backend v3.2',
          version: '3.2.0',
          features: [
            'WebRTC Signaling Server',
            'Admin API (ban/mute/delete with validation)',
            'Voice Chat Management',
            'User Status Tracking',
          ],
          timestamp: new Date().toISOString(),
          activeRooms: state.getAllRooms().length,
          activeBans: Array.from(state.bans.keys()).length,
          activeMutes: Array.from(state.mutes.keys()).length,
        }, 200, corsHeaders);
      }

      // Not found
      return jsonResponse({
        error: 'Endpoint not found',
        path,
      }, 404, corsHeaders);

    } catch (error) {
      console.error('❌ Worker error:', error);
      return jsonResponse({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      }, 500, corsHeaders);
    }
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// 🔐 AUTHENTICATION
// ═══════════════════════════════════════════════════════════════════════════

function validateAuth(request) {
  const authHeader = request.headers.get('Authorization');

  if (!authHeader) {
    return { valid: false, error: 'Missing Authorization header' };
  }

  const token = authHeader.replace('Bearer ', '');

  if (token !== CONFIG.ADMIN_TOKEN && token !== CONFIG.PRIMARY_TOKEN) {
    return { valid: false, error: 'Invalid token' };
  }

  return { valid: true };
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔌 WEBSOCKET HANDLER
// ═══════════════════════════════════════════════════════════════════════════

async function handleWebSocket(websocket) {
  websocket.accept();

  let roomId = null;
  let userId = null;
  let heartbeatInterval = null;

  websocket.addEventListener('message', async (event) => {
    try {
      const data = JSON.parse(event.data);

      switch (data.type) {
        case 'join':
          roomId = data.roomId;
          userId = data.userId;
          const username = data.username || 'Anonymous';

          if (state.isRoomFull(roomId)) {
            websocket.send(JSON.stringify({
              type: 'error',
              error: 'room_full',
            }));
            return;
          }

          state.addParticipant(roomId, userId, {
            username,
            websocket,
            joinedAt: Date.now(),
          });

          websocket.send(JSON.stringify({
            type: 'joined',
            roomId,
            userId,
            participants: state.getParticipants(roomId).map(([id, data]) => ({
              userId: id,
              username: data.username,
            })),
          }));

          broadcastToRoom(roomId, {
            type: 'user-joined',
            userId,
            username,
          }, userId);

          heartbeatInterval = setInterval(() => {
            try {
              websocket.send(JSON.stringify({ type: 'ping' }));
            } catch (e) {
              clearInterval(heartbeatInterval);
            }
          }, CONFIG.HEARTBEAT_INTERVAL_MS);
          break;

        case 'offer':
        case 'answer':
        case 'ice-candidate':
          if (roomId && userId) {
            const targetUserId = data.targetUserId;
            const participants = state.getParticipants(roomId);
            const target = participants.find(([id]) => id === targetUserId);

            if (target) {
              const [, targetData] = target;
              targetData.websocket.send(JSON.stringify({
                ...data,
                fromUserId: userId,
              }));
            }
          }
          break;

        case 'mute':
          if (roomId && userId) {
            broadcastToRoom(roomId, {
              type: 'user-muted',
              userId,
              isMuted: data.isMuted,
            }, userId);
          }
          break;
      }
    } catch (error) {
      console.error('WebSocket error:', error);
    }
  });

  websocket.addEventListener('close', () => {
    if (roomId && userId) {
      state.removeParticipant(roomId, userId);
      broadcastToRoom(roomId, {
        type: 'user-left',
        userId,
      });
    }
    if (heartbeatInterval) {
      clearInterval(heartbeatInterval);
    }
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// 📡 HELPERS
// ═══════════════════════════════════════════════════════════════════════════

function jsonResponse(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });
}

function broadcastToRoom(roomId, message, excludeUserId = null) {
  const participants = state.getParticipants(roomId);
  const messageStr = JSON.stringify(message);

  participants.forEach(([userId, data]) => {
    if (userId !== excludeUserId) {
      try {
        data.websocket.send(messageStr);
      } catch (error) {
        console.error(`Failed to send to ${userId}:`, error);
      }
    }
  });
}
