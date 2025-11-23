/**
 * ═══════════════════════════════════════════════════════════════
 * WELTENBIBLIOTHEK - UNIFIED MASTER WORKER
 * ═══════════════════════════════════════════════════════════════
 * Version: 2.0.0 (Clean Rebuild)
 * 
 * Ein einziger Worker für alle Backend-Funktionen:
 * - 🔐 Authentication (JWT)
 * - 💬 Chat & Messages
 * - 📺 Live Streaming Rooms
 * - 🎵 Music Sync & YouTube Integration
 * - 🔧 Admin & Moderation
 * - 📡 WebRTC Signaling (WebSocket)
 * 
 * Durable Objects:
 * - ChatRoom: Persistent chat room state
 * - WebRTCRoom: WebRTC signaling server
 * - MusicRoomState: Synchronized music playback
 * ═══════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════
// MAIN WORKER - HTTP REQUEST HANDLER
// ═══════════════════════════════════════════════════════════════

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS Headers für alle Requests
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle CORS Preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      let response;

      // ═══════════════════════════════════════════════════════════
      // ROUTING
      // ═══════════════════════════════════════════════════════════

      // 🔐 Authentication Routes
      if (path.startsWith('/api/auth/')) {
        response = await handleAuth(request, path, env);
      }
      // 💬 Chat Routes
      else if (path.startsWith('/chat-rooms') || path.startsWith('/messages')) {
        response = await handleChat(request, path, env);
      }
      // 📺 Live Streaming Routes
      else if (path.startsWith('/api/live/')) {
        response = await handleLiveRooms(request, path, env);
      }
      // 🎵 Music Routes
      else if (path.startsWith('/extract-audio/') || path.startsWith('/music/')) {
        response = await handleMusic(request, path, env);
      }
      // 🔧 Admin Routes
      else if (path.startsWith('/api/v1/')) {
        response = await handleAdmin(request, path, env);
      }
      // 📡 WebRTC Signaling (WebSocket)
      else if (path.startsWith('/ws/') || request.headers.get('Upgrade') === 'websocket') {
        response = await handleWebRTC(request, path, env);
      }
      // ❤️ Health Check
      else if (path === '/health' || path === '/') {
        response = new Response(JSON.stringify({
          status: 'healthy',
          version: '2.0.0',
          timestamp: new Date().toISOString(),
          services: ['auth', 'chat', 'live', 'music', 'admin', 'webrtc']
        }), {
          headers: { 'Content-Type': 'application/json', ...corsHeaders }
        });
      }
      // 404 Not Found
      else {
        response = new Response(JSON.stringify({ error: 'Not Found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json', ...corsHeaders }
        });
      }

      // Add CORS headers to response
      const newHeaders = new Headers(response.headers);
      Object.entries(corsHeaders).forEach(([key, value]) => {
        newHeaders.set(key, value);
      });

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: newHeaders
      });

    } catch (error) {
      console.error('Worker Error:', error);
      return new Response(JSON.stringify({ 
        error: 'Internal Server Error',
        message: error.message 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json', ...corsHeaders }
      });
    }
  }
};

// ═══════════════════════════════════════════════════════════════
// 🔐 AUTHENTICATION HANDLER
// ═══════════════════════════════════════════════════════════════

async function handleAuth(request, path, env) {
  const method = request.method;

  // POST /api/auth/register
  if (path === '/api/auth/register' && method === 'POST') {
    const body = await request.json();
    const { username, password, email } = body;

    // Simple token generation (Demo - use proper JWT in production)
    const token = 'demo_token_' + username + '_' + Date.now();
    
    return new Response(JSON.stringify({
      success: true,
      token: token,
      user: {
        username: username,
        email: email || null,
        created_at: new Date().toISOString()
      }
    }), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // POST /api/auth/login
  if (path === '/api/auth/login' && method === 'POST') {
    const body = await request.json();
    const { username, password } = body;

    // Simple authentication (Demo - verify against DB in production)
    const token = 'demo_token_' + username + '_' + Date.now();
    
    return new Response(JSON.stringify({
      success: true,
      token: token,
      user: {
        username: username,
        email: username + '@weltenbibliothek.de',
        last_login: new Date().toISOString()
      }
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // GET /api/auth/me
  if (path === '/api/auth/me' && method === 'GET') {
    const authHeader = request.headers.get('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const username = token.split('_')[2]; // Extract username from demo token

    return new Response(JSON.stringify({
      user: {
        username: username,
        email: username + '@weltenbibliothek.de'
      }
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// 💬 CHAT HANDLER
// ═══════════════════════════════════════════════════════════════

async function handleChat(request, path, env) {
  // GET /chat-rooms
  if (path === '/chat-rooms' && request.method === 'GET') {
    // Return demo chat rooms (integrate with D1 later)
    return new Response(JSON.stringify({
      success: true,
      chat_rooms: [
        {
          id: 'general',
          name: 'Allgemein',
          description: 'Allgemeiner Chat',
          is_fixed: 1,
          created_at: Date.now()
        }
      ]
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // GET /messages/:roomId
  if (path.startsWith('/messages/') && request.method === 'GET') {
    const roomId = path.split('/')[2];
    
    return new Response(JSON.stringify({
      success: true,
      messages: []
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// 📺 LIVE ROOMS HANDLER
// ═══════════════════════════════════════════════════════════════

async function handleLiveRooms(request, path, env) {
  const method = request.method;

  // GET /api/live/rooms - Get all active live rooms
  if (path === '/api/live/rooms' && method === 'GET') {
    return new Response(JSON.stringify({
      success: true,
      rooms: []
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // POST /api/live/rooms - Create new live room
  if (path === '/api/live/rooms' && method === 'POST') {
    const body = await request.json();
    const { chatRoomId, title, description, category } = body;

    const roomId = 'room_' + Date.now();

    return new Response(JSON.stringify({
      success: true,
      room: {
        room_id: roomId,
        chat_room_id: chatRoomId,
        title: title,
        description: description,
        category: category,
        status: 'live',
        created_at: Math.floor(Date.now() / 1000),
        participant_count: 0
      }
    }), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// 🎵 MUSIC HANDLER (YouTube Integration)
// ═══════════════════════════════════════════════════════════════

async function handleMusic(request, path, env) {
  // GET /extract-audio/:videoId
  if (path.startsWith('/extract-audio/')) {
    const videoId = path.split('/')[2];

    // Return demo response (integrate with actual yt-dlp service later)
    return new Response(JSON.stringify({
      success: true,
      videoId: videoId,
      title: 'Demo Video',
      audioUrl: 'https://example.com/audio.mp3',
      duration: 180
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// 🔧 ADMIN HANDLER
// ═══════════════════════════════════════════════════════════════

async function handleAdmin(request, path, env) {
  // GET /api/v1/health
  if (path === '/api/v1/health' && request.method === 'GET') {
    return new Response(JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString()
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' }
  });
}

// ═══════════════════════════════════════════════════════════════
// 📡 WEBRTC SIGNALING HANDLER (WebSocket)
// ═══════════════════════════════════════════════════════════════

async function handleWebRTC(request, path, env) {
  // WebSocket Upgrade Check
  const upgradeHeader = request.headers.get('Upgrade');
  if (upgradeHeader !== 'websocket') {
    return new Response('Expected WebSocket', { status: 426 });
  }

  // Extract room ID from path (e.g., /ws/room123)
  const roomId = path.split('/')[2] || 'default';

  // Get or create Durable Object for this room
  const id = env.WEBRTC_ROOM.idFromName(roomId);
  const stub = env.WEBRTC_ROOM.get(id);

  // Forward WebSocket connection to Durable Object
  return stub.fetch(request);
}

// ═══════════════════════════════════════════════════════════════
// DURABLE OBJECT: WebRTC Room
// ═══════════════════════════════════════════════════════════════

export class WebRTCRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map(); // peerId -> {socket, username, uid, role, joinedAt}
  }

  async fetch(request) {
    // Upgrade to WebSocket
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);

    // Accept WebSocket connection
    server.accept();

    // Handle WebSocket messages
    server.addEventListener('message', async (event) => {
      try {
        const message = JSON.parse(event.data);
        await this.handleMessage(server, message);
      } catch (error) {
        console.error('WebSocket message error:', error);
        server.send(JSON.stringify({ type: 'error', message: error.message }));
      }
    });

    // Handle WebSocket close
    server.addEventListener('close', () => {
      // Find and remove this session
      for (const [peerId, session] of this.sessions.entries()) {
        if (session.socket === server) {
          this.sessions.delete(peerId);
          
          // Notify others that user left
          this.broadcast({
            type: 'user-left',
            peerId: peerId,
            username: session.username
          }, peerId);
          
          break;
        }
      }
    });

    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  }

  async handleMessage(server, message) {
    const { type, peerId, roomId, username, uid, role } = message;

    switch (type) {
      case 'join':
        // Store session with metadata
        this.sessions.set(peerId, {
          socket: server,
          username: username || 'Unknown',
          uid: uid || peerId,
          role: role || 'viewer',
          joinedAt: new Date().toISOString()
        });

        // Send current peers list to new joiner
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

        // Notify others about new peer
        this.broadcast({
          type: 'new-peer',
          peerId: peerId,
          username: username,
          uid: uid,
          role: role
        }, peerId);
        break;

      case 'offer':
      case 'answer':
      case 'ice-candidate':
        // Forward WebRTC signaling to target peer
        const targetSession = this.sessions.get(message.target);
        if (targetSession) {
          targetSession.socket.send(JSON.stringify({
            ...message,
            from: peerId
          }));
        }
        break;

      case 'leave':
        this.sessions.delete(peerId);
        this.broadcast({
          type: 'user-left',
          peerId: peerId,
          username: username
        }, peerId);
        break;
    }
  }

  broadcast(message, excludePeerId) {
    const messageStr = JSON.stringify(message);
    for (const [peerId, session] of this.sessions.entries()) {
      if (peerId !== excludePeerId) {
        try {
          session.socket.send(messageStr);
        } catch (error) {
          console.error('Broadcast error:', error);
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// DURABLE OBJECT: Chat Room (Placeholder for future use)
// ═══════════════════════════════════════════════════════════════

export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }

  async fetch(request) {
    return new Response('ChatRoom Durable Object - Not implemented yet', { status: 501 });
  }
}

// ═══════════════════════════════════════════════════════════════
// DURABLE OBJECT: Music Room State (Placeholder for future use)
// ═══════════════════════════════════════════════════════════════

export class MusicRoomState {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }

  async fetch(request) {
    return new Response('MusicRoomState Durable Object - Not implemented yet', { status: 501 });
  }
}
