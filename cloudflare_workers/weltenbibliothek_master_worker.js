/**
 * WebRTC Signaling Server - Cloudflare Worker
 * COMPATIBILITY MODE: Exports both ChatRoom AND SignalingServer classes
 * 
 * Features:
 * - WebSocket-basiertes Signaling für WebRTC
 * - Room-basiertes Peer Management
 * - SDP Offer/Answer Exchange
 * - ICE Candidate Relay
 * - Automatisches Cleanup bei Disconnect
 * 
 * Architektur:
 * - Durable Objects für Room State Management
 * - WebSocket für Low-Latency Signaling
 * - Mesh Topology Support (jeder Peer verbindet sich mit jedem)
 */

// ═══════════════════════════════════════════════════════════════
// CLOUDFLARE WORKER - HTTP Handler
// ═══════════════════════════════════════════════════════════════

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // WebSocket Upgrade Request
    if (request.headers.get('Upgrade') === 'websocket') {
      return handleWebSocket(request, env);
    }
    
    // HTTP Endpoints
    if (url.pathname === '/') {
      return new Response('WebRTC Signaling Server v1.3 - Status: Online (Full API Support)', {
        status: 200,
        headers: { 'Content-Type': 'text/plain' }
      });
    }
    
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.3.0'
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Auth Endpoints
    if (url.pathname === '/api/auth/login' && request.method === 'POST') {
      return handleLogin(request, env);
    }
    
    if (url.pathname === '/api/auth/register' && request.method === 'POST') {
      return handleRegister(request, env);
    }
    
    if (url.pathname === '/api/auth/me' && request.method === 'GET') {
      return handleGetUser(request, env);
    }
    
    // Live Room Endpoints
    if (url.pathname === '/api/live/rooms' && request.method === 'GET') {
      return handleGetLiveRooms(request, env);
    }
    
    if (url.pathname === '/api/live/rooms' && request.method === 'POST') {
      return handleCreateLiveRoom(request, env);
    }
    
    if (url.pathname.match(/^\/api\/live\/rooms\/[^\/]+\/join$/) && request.method === 'POST') {
      return handleJoinLiveRoom(request, env);
    }
    
    if (url.pathname.match(/^\/api\/live\/rooms\/[^\/]+\/leave$/) && request.method === 'POST') {
      return handleLeaveLiveRoom(request, env);
    }
    
    if (url.pathname.match(/^\/api\/live\/rooms\/[^\/]+\/end$/) && request.method === 'POST') {
      return handleEndLiveRoom(request, env);
    }
    
    // Messages/Chat Endpoints
    if (url.pathname.match(/^\/api\/messages\/direct/) && request.method === 'GET') {
      return handleGetDirectMessages(request, env);
    }
    
    if (url.pathname === '/api/messages/direct' && request.method === 'POST') {
      return handleSendDirectMessage(request, env);
    }
    
    // Events Endpoints
    if (url.pathname === '/api/events' && request.method === 'GET') {
      return handleGetEvents(request, env);
    }
    
    if (url.pathname === '/api/events' && request.method === 'POST') {
      return handleCreateEvent(request, env);
    }
    
    // Admin Endpoints (stub implementations)
    if (url.pathname.startsWith('/api/admin/')) {
      return new Response(JSON.stringify({ success: true, message: 'Admin endpoint (demo)' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Reports Endpoints (stub)
    if (url.pathname === '/api/reports') {
      return new Response(JSON.stringify({ success: true, message: 'Reports endpoint (demo)' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    return new Response('Not Found', { status: 404 });
  }
};

// ═══════════════════════════════════════════════════════════════
// AUTH HANDLERS (Simple In-Memory Authentication for Demo)
// ═══════════════════════════════════════════════════════════════

async function handleLogin(request, env) {
  try {
    const body = await request.json();
    const { username, password } = body;
    
    // Simple validation (accept any non-empty credentials for demo)
    if (!username || !password) {
      return new Response(JSON.stringify({
        error: 'Username and password are required'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Generate simple JWT-like token (demo only - use proper JWT in production)
    const token = btoa(`${username}:${Date.now()}`);
    
    const user = {
      id: btoa(username),
      username: username,
      displayName: username,
      email: `${username}@weltenbibliothek.app`,
      createdAt: new Date().toISOString()
    };
    
    return new Response(JSON.stringify({
      token: token,
      user: user
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (e) {
    return new Response(JSON.stringify({
      error: 'Invalid request'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function handleRegister(request, env) {
  try {
    const body = await request.json();
    const { username, password, email } = body;
    
    if (!username || !password) {
      return new Response(JSON.stringify({
        error: 'Username and password are required'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Generate token
    const token = btoa(`${username}:${Date.now()}`);
    
    const user = {
      id: btoa(username),
      username: username,
      displayName: username,
      email: email || `${username}@weltenbibliothek.app`,
      createdAt: new Date().toISOString()
    };
    
    return new Response(JSON.stringify({
      token: token,
      user: user
    }), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (e) {
    return new Response(JSON.stringify({
      error: 'Invalid request'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function handleGetUser(request, env) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(JSON.stringify({
      error: 'Unauthorized'
    }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }
  
  try {
    const token = authHeader.substring(7);
    const decoded = atob(token);
    const username = decoded.split(':')[0];
    
    const user = {
      id: btoa(username),
      username: username,
      displayName: username,
      email: `${username}@weltenbibliothek.app`
    };
    
    return new Response(JSON.stringify({ user }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (e) {
    return new Response(JSON.stringify({
      error: 'Invalid token'
    }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// LIVE ROOM HANDLERS (In-Memory Demo Storage)
// ═══════════════════════════════════════════════════════════════

const liveRooms = new Map(); // In-memory storage for demo

async function handleGetLiveRooms(request, env) {
  const rooms = Array.from(liveRooms.values()).filter(room => room.status === 'live');
  return new Response(JSON.stringify({ rooms }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}

async function handleCreateLiveRoom(request, env) {
  try {
    const body = await request.json();
    const roomId = `room_${Date.now()}`;
    
    const room = {
      room_id: roomId,
      chat_room_id: body.chatRoomId || null,
      title: body.title || 'Untitled Stream',
      description: body.description || '',
      host_username: body.hostUsername || 'Unknown',
      status: 'live',
      created_at: Math.floor(Date.now() / 1000),
      started_at: Math.floor(Date.now() / 1000),
      ended_at: null,
      participant_count: 0,
      max_participants: body.maxParticipants || 50,
      is_private: body.isPrivate ? 1 : 0,
      category: body.category || null
    };
    
    liveRooms.set(roomId, room);
    
    return new Response(JSON.stringify({ success: true, room }), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: 'Invalid request' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

async function handleJoinLiveRoom(request, env) {
  return new Response(JSON.stringify({ success: true, message: 'Joined room' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}

async function handleLeaveLiveRoom(request, env) {
  return new Response(JSON.stringify({ success: true, message: 'Left room' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}

async function handleEndLiveRoom(request, env) {
  return new Response(JSON.stringify({ success: true, message: 'Room ended' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// MESSAGES HANDLERS (Stub Implementation)
// ═══════════════════════════════════════════════════════════════

async function handleGetDirectMessages(request, env) {
  return new Response(JSON.stringify({ messages: [] }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}

async function handleSendDirectMessage(request, env) {
  return new Response(JSON.stringify({ success: true, message: 'Message sent' }), {
    status: 201,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// EVENTS HANDLERS (Stub Implementation)
// ═══════════════════════════════════════════════════════════════

async function handleGetEvents(request, env) {
  return new Response(JSON.stringify({ events: [] }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}

async function handleCreateEvent(request, env) {
  return new Response(JSON.stringify({ success: true, message: 'Event created' }), {
    status: 201,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// WEBSOCKET HANDLER
// ═══════════════════════════════════════════════════════════════

async function handleWebSocket(request, env) {
  const url = new URL(request.url);
  const roomId = url.pathname.split('/').pop() || 'default';
  
  console.log(`🔌 WebSocket request for room: ${roomId}`);
  
  // Get Durable Object for this room
  const id = env.WEBRTC_ROOMS.idFromName(roomId);
  const room = env.WEBRTC_ROOMS.get(id);
  
  // Forward WebSocket to Durable Object
  return room.fetch(request);
}

// ═══════════════════════════════════════════════════════════════
// SHARED IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════

class RoomBase {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map();
  }
  
  async fetch(request) {
    const upgradeHeader = request.headers.get('Upgrade');
    if (!upgradeHeader || upgradeHeader !== 'websocket') {
      return new Response('Expected WebSocket', { status: 426 });
    }
    
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    
    server.accept();
    
    let peerId = null;
    let roomId = null;
    
    server.addEventListener('message', async (event) => {
      try {
        const data = JSON.parse(event.data);
        const type = data.type;
        
        console.log(`📥 [${peerId || 'unknown'}] ${type}`);
        
        switch (type) {
          case 'join':
            peerId = data.peerId;
            roomId = data.roomId;
            const username = data.username || peerId;
            const uid = data.uid || peerId;
            const role = data.role || 'viewer';
            
            this.sessions.set(peerId, {
              socket: server,
              username: username,
              uid: uid,
              role: role,
              joinedAt: new Date().toISOString()
            });
            
            console.log(`👤 Peer joined: ${username} (peerId: ${peerId}, role: ${role}, Room: ${roomId})`);
            console.log(`📊 Total peers in room: ${this.sessions.size}`);
            
            this.broadcast({
              type: 'peer-joined',
              peerId: peerId,
              username: username,
              uid: uid,
              role: role,
              roomId: roomId,
            }, peerId);
            
            const currentPeers = Array.from(this.sessions.entries())
              .filter(([id, _]) => id !== peerId)
              .map(([id, session]) => ({
                peerId: id,
                username: session.username,
                uid: session.uid,
                role: session.role
              }));
            
            server.send(JSON.stringify({
              type: 'peers-list',
              peers: currentPeers,
              count: currentPeers.length
            }));
            
            console.log(`📤 Sent peers list to ${peerId}: ${currentPeers.length} peer(s)`);
            break;
            
          case 'leave':
            console.log(`👋 Peer leaving: ${peerId}`);
            this.handlePeerLeave(peerId);
            break;
            
          case 'offer':
            this.forwardToPeer(data.toPeerId, {
              type: 'offer',
              fromPeerId: data.fromPeerId,
              sdp: data.sdp,
            });
            break;
            
          case 'answer':
            this.forwardToPeer(data.toPeerId, {
              type: 'answer',
              fromPeerId: data.fromPeerId,
              sdp: data.sdp,
            });
            break;
            
          case 'ice-candidate':
            this.forwardToPeer(data.toPeerId, {
              type: 'ice-candidate',
              fromPeerId: data.fromPeerId,
              candidate: data.candidate,
            });
            break;
            
          default:
            console.warn(`⚠️ Unknown message type: ${type}`);
        }
        
      } catch (error) {
        console.error('❌ Message handling error:', error);
        server.send(JSON.stringify({
          type: 'error',
          message: error.message,
        }));
      }
    });
    
    server.addEventListener('close', () => {
      console.log(`🔌 WebSocket closed: ${peerId}`);
      if (peerId) {
        this.handlePeerLeave(peerId);
      }
    });
    
    server.addEventListener('error', (error) => {
      console.error(`❌ WebSocket error: ${peerId}`, error);
      if (peerId) {
        this.handlePeerLeave(peerId);
      }
    });
    
    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }
  
  forwardToPeer(peerId, message) {
    const session = this.sessions.get(peerId);
    if (session && session.socket && session.socket.readyState === 1) {
      session.socket.send(JSON.stringify(message));
      console.log(`📤 Forwarded ${message.type} to ${peerId} (${session.username})`);
    } else {
      console.warn(`⚠️ Peer not found or not connected: ${peerId}`);
    }
  }
  
  broadcast(message, excludePeerId = null) {
    const messageStr = JSON.stringify(message);
    let broadcastCount = 0;
    
    for (const [peerId, session] of this.sessions.entries()) {
      if (peerId !== excludePeerId && session.socket && session.socket.readyState === 1) {
        session.socket.send(messageStr);
        broadcastCount++;
      }
    }
    
    console.log(`📢 Broadcast ${message.type} to ${broadcastCount} peer(s)`);
  }
  
  handlePeerLeave(peerId) {
    const session = this.sessions.get(peerId);
    const username = session?.username || peerId;
    
    this.sessions.delete(peerId);
    
    console.log(`🗑️ Peer left: ${username} (peerId: ${peerId})`);
    console.log(`📊 Remaining peers: ${this.sessions.size}`);
    
    this.broadcast({
      type: 'peer-left',
      peerId: peerId,
      username: username,
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// EXPORT BOTH CLASS NAMES (Compatibility with all possible configurations)
// ═══════════════════════════════════════════════════════════════

export class ChatRoom extends RoomBase {}
export class SignalingServer extends RoomBase {}
export class WebRTCRoom extends RoomBase {}
