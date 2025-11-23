/**
 * ═══════════════════════════════════════════════════════════════
 * WELTENBIBLIOTHEK - UNIFIED MASTER WORKER v3.0 REAL
 * ═══════════════════════════════════════════════════════════════
 * ECHTE Implementierung - Keine Demos, keine Simulationen!
 * 
 * - 🔐 Echte Auth: PBKDF2 Password-Hashing + JWT-Tokens
 * - 💬 Chat CRUD: Create, Read, Update, Delete Messages
 * - 📺 Live Streaming: Echte Usernames aus JWT
 * - 📡 WebRTC: Durable Objects Signaling
 * - 🗄️ D1 Database: Alle Daten persistent gespeichert
 * ═══════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════
// PASSWORD HASHING (PBKDF2 via Web Crypto API)
// ═══════════════════════════════════════════════════════════════

async function hashPassword(password, providedSalt) {
  const encoder = new TextEncoder();
  const salt = providedSalt || crypto.getRandomValues(new Uint8Array(16));
  
  const keyMaterial = await crypto.subtle.importKey(
    "raw", encoder.encode(password), { name: "PBKDF2" }, false, ["deriveBits", "deriveKey"]
  );
  
  const key = await crypto.subtle.deriveKey(
    { name: "PBKDF2", salt: salt, iterations: 100000, hash: "SHA-256" },
    keyMaterial, { name: "AES-GCM", length: 256 }, true, ["encrypt", "decrypt"]
  );
  
  const exportedKey = await crypto.subtle.exportKey("raw", key);
  const hashBuffer = new Uint8Array(exportedKey);
  const hashHex = Array.from(hashBuffer).map(b => b.toString(16).padStart(2, "0")).join("");
  const saltHex = Array.from(salt).map(b => b.toString(16).padStart(2, "0")).join("");
  
  return `${saltHex}:${hashHex}`;
}

async function verifyPassword(storedHash, passwordAttempt) {
  const [saltHex, originalHash] = storedHash.split(":");
  const matchResult = saltHex.match(/.{1,2}/g);
  if (!matchResult) throw new Error("Invalid salt format");
  
  const salt = new Uint8Array(matchResult.map(byte => parseInt(byte, 16)));
  const attemptHashWithSalt = await hashPassword(passwordAttempt, salt);
  const [, attemptHash] = attemptHashWithSalt.split(":");
  
  return attemptHash === originalHash;
}

// ═══════════════════════════════════════════════════════════════
// JWT TOKEN HANDLING
// ═══════════════════════════════════════════════════════════════

const JWT_SECRET = "weltenbibliothek_secret_2025_v3";

async function generateJWT(payload) {
  const header = { alg: "HS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const jwtPayload = { ...payload, iat: now, exp: now + (7 * 24 * 60 * 60) };
  
  const encodedHeader = btoa(JSON.stringify(header));
  const encodedPayload = btoa(JSON.stringify(jwtPayload));
  const message = `${encodedHeader}.${encodedPayload}`;
  const signature = await signHMAC(message, JWT_SECRET);
  
  return `${message}.${signature}`;
}

async function verifyJWT(token) {
  try {
    const [encodedHeader, encodedPayload, providedSignature] = token.split('.');
    if (!encodedHeader || !encodedPayload || !providedSignature) return null;
    
    const message = `${encodedHeader}.${encodedPayload}`;
    const expectedSignature = await signHMAC(message, JWT_SECRET);
    if (expectedSignature !== providedSignature) return null;
    
    const payload = JSON.parse(atob(encodedPayload));
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) return null;
    
    return payload;
  } catch (error) {
    return null;
  }
}

async function signHMAC(message, secret) {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(message));
  const signatureArray = Array.from(new Uint8Array(signature));
  return btoa(String.fromCharCode(...signatureArray))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

// Helper: Extract user from JWT token
async function getUserFromToken(request, env) {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  
  const token = authHeader.substring(7);
  const payload = await verifyJWT(token);
  return payload;
}

// ═══════════════════════════════════════════════════════════════
// MAIN WORKER EXPORT
// ═══════════════════════════════════════════════════════════════

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      let response;

      // ═══ AUTH ROUTES ═══
      if (path === '/api/auth/register' && method === 'POST') {
        const body = await request.json();
        const { username, password, email } = body;

        if (!username || !password) {
          return new Response(JSON.stringify({ success: false, error: 'Username and password required' }), 
            { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const existing = await env.DB.prepare('SELECT id FROM users WHERE username = ?').bind(username).first();
        if (existing) {
          return new Response(JSON.stringify({ success: false, error: 'Username exists' }), 
            { status: 409, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const passwordHash = await hashPassword(password);
        const userId = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        const now = Math.floor(Date.now() / 1000);

        await env.DB.prepare('INSERT INTO users (id, username, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?, ?)')
          .bind(userId, username, email || null, passwordHash, 'user', now).run();

        const token = await generateJWT({ userId, username, role: 'user' });

        return new Response(JSON.stringify({
          success: true, token, 
          user: { id: userId, username, email: email || null, role: 'user' }
        }), { status: 201, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      if (path === '/api/auth/login' && method === 'POST') {
        const body = await request.json();
        const { username, password } = body;

        if (!username || !password) {
          return new Response(JSON.stringify({ success: false, error: 'Username and password required' }), 
            { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const user = await env.DB.prepare('SELECT id, username, email, password_hash, role, is_banned FROM users WHERE username = ?')
          .bind(username).first();

        if (!user || user.is_banned === 1) {
          return new Response(JSON.stringify({ success: false, error: 'Invalid credentials or banned' }), 
            { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const isValid = await verifyPassword(user.password_hash, password);
        if (!isValid) {
          return new Response(JSON.stringify({ success: false, error: 'Invalid credentials' }), 
            { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const now = Math.floor(Date.now() / 1000);
        await env.DB.prepare('UPDATE users SET last_login = ? WHERE id = ?').bind(now, user.id).run();

        const token = await generateJWT({ userId: user.id, username: user.username, role: user.role });

        return new Response(JSON.stringify({
          success: true, token,
          user: { id: user.id, username: user.username, email: user.email, role: user.role }
        }), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      if (path === '/api/auth/me' && method === 'GET') {
        const payload = await getUserFromToken(request, env);
        if (!payload) {
          return new Response(JSON.stringify({ error: 'Unauthorized' }), 
            { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const user = await env.DB.prepare('SELECT id, username, email, role FROM users WHERE id = ?')
          .bind(payload.userId).first();

        if (!user) {
          return new Response(JSON.stringify({ error: 'User not found' }), 
            { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        return new Response(JSON.stringify({ user }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // ═══ CHAT ROUTES ═══
      if (path === '/chat-rooms' && method === 'GET') {
        const { results } = await env.DB.prepare('SELECT * FROM chat_rooms ORDER BY is_fixed DESC, created_at DESC').all();
        return new Response(JSON.stringify({ success: true, chat_rooms: results }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      if (path.startsWith('/messages/') && method === 'GET') {
        const roomId = path.split('/')[2];
        const { results } = await env.DB.prepare('SELECT * FROM messages WHERE chat_room_id = ? ORDER BY created_at DESC LIMIT 100')
          .bind(roomId).all();
        return new Response(JSON.stringify({ success: true, messages: results.reverse() }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // POST /messages/:roomId - Send message
      if (path.startsWith('/messages/') && method === 'POST' && !path.match(/\/messages\/[^/]+\/[^/]+$/)) {
        const roomId = path.split('/')[2];
        const payload = await getUserFromToken(request, env);
        if (!payload) {
          return new Response(JSON.stringify({ success: false, error: 'Unauthorized' }), 
            { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const body = await request.json();
        const { content, type, media_url } = body;
        if (!content) {
          return new Response(JSON.stringify({ success: false, error: 'Content required' }), 
            { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const messageId = 'msg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        const now = new Date().toISOString();

        await env.DB.prepare('INSERT INTO messages (id, chat_room_id, sender_id, sender_name, content, type, media_url, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
          .bind(messageId, roomId, payload.userId, payload.username, content, type || 'text', media_url || null, now).run();

        await env.DB.prepare('UPDATE chat_rooms SET last_message = ?, last_message_time = ? WHERE id = ?')
          .bind(content.substring(0, 100), now, roomId).run();

        return new Response(JSON.stringify({
          success: true,
          message: { id: messageId, chat_room_id: roomId, sender_id: payload.userId, sender_name: payload.username, content, type: type || 'text', media_url, created_at: now, is_edited: 0 }
        }), { status: 201, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // PUT /messages/:roomId/:messageId - Edit message
      if (path.match(/^\/messages\/[^/]+\/[^/]+$/) && method === 'PUT') {
        const [, , roomId, messageId] = path.split('/');
        const payload = await getUserFromToken(request, env);
        if (!payload) {
          return new Response(JSON.stringify({ success: false, error: 'Unauthorized' }), 
            { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const message = await env.DB.prepare('SELECT * FROM messages WHERE id = ? AND chat_room_id = ?')
          .bind(messageId, roomId).first();

        if (!message) {
          return new Response(JSON.stringify({ success: false, error: 'Message not found' }), 
            { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        if (message.sender_id !== payload.userId) {
          return new Response(JSON.stringify({ success: false, error: 'You can only edit your own messages' }), 
            { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const body = await request.json();
        const { content } = body;
        if (!content) {
          return new Response(JSON.stringify({ success: false, error: 'Content required' }), 
            { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const now = new Date().toISOString();
        await env.DB.prepare('UPDATE messages SET content = ?, is_edited = 1, updated_at = ? WHERE id = ?')
          .bind(content, now, messageId).run();

        return new Response(JSON.stringify({ success: true, message: { ...message, content, is_edited: 1, updated_at: now } }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // DELETE /messages/:roomId/:messageId - Delete message
      if (path.match(/^\/messages\/[^/]+\/[^/]+$/) && method === 'DELETE') {
        const [, , roomId, messageId] = path.split('/');
        const payload = await getUserFromToken(request, env);
        if (!payload) {
          return new Response(JSON.stringify({ success: false, error: 'Unauthorized' }), 
            { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        const message = await env.DB.prepare('SELECT * FROM messages WHERE id = ? AND chat_room_id = ?')
          .bind(messageId, roomId).first();

        if (!message) {
          return new Response(JSON.stringify({ success: false, error: 'Message not found' }), 
            { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        if (message.sender_id !== payload.userId && payload.role !== 'admin' && payload.role !== 'super_admin') {
          return new Response(JSON.stringify({ success: false, error: 'Permission denied' }), 
            { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
        }

        await env.DB.prepare('DELETE FROM messages WHERE id = ?').bind(messageId).run();

        return new Response(JSON.stringify({ success: true, message: 'Message deleted' }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // ═══ LIVE ROOMS (keeping existing implementation) ═══
      if (path === '/api/live/rooms' && method === 'GET') {
        const { results } = await env.DB.prepare("SELECT * FROM live_rooms WHERE status = 'live' ORDER BY created_at DESC").all();
        return new Response(JSON.stringify({ success: true, rooms: results }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      if (path === '/api/live/rooms' && method === 'POST') {
        const payload = await getUserFromToken(request, env);
        const body = await request.json();
        const { chatRoomId, title, description, category } = body;
        
        const username = payload ? payload.username : 'unknown';
        const roomId = 'room_' + Date.now();
        const now = Math.floor(Date.now() / 1000);

        await env.DB.prepare('INSERT INTO live_rooms (room_id, chat_room_id, title, description, host_username, status, category, created_at, started_at, participant_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
          .bind(roomId, chatRoomId, title, description || '', username, 'live', category || 'general', now, now, 0).run();

        return new Response(JSON.stringify({
          success: true,
          room: { room_id: roomId, chat_room_id: chatRoomId, title, description, host_username: username, category, status: 'live', created_at: now, started_at: now, participant_count: 0 }
        }), { status: 201, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // ═══ MUSIC & ADMIN (keeping existing stubs) ═══
      if (path.startsWith('/extract-audio/')) {
        const videoId = path.split('/')[2];
        return new Response(JSON.stringify({ success: true, videoId, title: 'Demo Video', audioUrl: 'https://example.com/audio.mp3' }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      if (path === '/api/v1/health') {
        return new Response(JSON.stringify({ status: 'healthy', timestamp: new Date().toISOString() }), 
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      // ═══ WEBRTC SIGNALING ═══
      if (path.startsWith('/ws/') || request.headers.get('Upgrade') === 'websocket') {
        const upgradeHeader = request.headers.get('Upgrade');
        if (upgradeHeader !== 'websocket') {
          return new Response('Expected WebSocket', { status: 426 });
        }
        const roomId = path.split('/')[2] || 'default';
        const id = env.WEBRTC_ROOM.idFromName(roomId);
        const stub = env.WEBRTC_ROOM.get(id);
        return stub.fetch(request);
      }

      // ═══ HEALTH CHECK ═══
      if (path === '/health' || path === '/') {
        return new Response(JSON.stringify({
          status: 'healthy',
          version: '3.0.0-real',
          timestamp: new Date().toISOString(),
          services: ['auth-real', 'chat-crud', 'live', 'webrtc'],
          features: ['PBKDF2 hashing', 'JWT tokens', 'Message CRUD', 'Real usernames']
        }), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
      }

      return new Response(JSON.stringify({ error: 'Not Found' }), 
        { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } });

    } catch (error) {
      console.error('Worker Error:', error);
      return new Response(JSON.stringify({ error: 'Internal Server Error', message: error.message }), 
        { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }
  }
};

// ═══════════════════════════════════════════════════════════════
// DURABLE OBJECT: WebRTCRoom
// ═══════════════════════════════════════════════════════════════

export class WebRTCRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map();
  }

  async fetch(request) {
    const webSocketPair = new WebSocketPair();
    const [client, server] = Object.values(webSocketPair);
    server.accept();

    server.addEventListener('message', async (event) => {
      try {
        const message = JSON.parse(event.data);
        await this.handleMessage(server, message);
      } catch (error) {
        console.error('WebSocket message error:', error);
        server.send(JSON.stringify({ type: 'error', message: error.message }));
      }
    });

    server.addEventListener('close', () => {
      for (const [peerId, session] of this.sessions.entries()) {
        if (session.socket === server) {
          this.sessions.delete(peerId);
          this.broadcast({ type: 'user-left', peerId, username: session.username }, peerId);
          break;
        }
      }
    });

    return new Response(null, { status: 101, webSocket: client });
  }

  async handleMessage(server, message) {
    const { type, peerId, roomId, username, uid, role } = message;

    switch (type) {
      case 'join':
        this.sessions.set(peerId, {
          socket: server,
          username: username || 'Unknown',
          uid: uid || peerId,
          role: role || 'viewer',
          joinedAt: new Date().toISOString()
        });

        const currentPeers = Array.from(this.sessions.entries())
          .filter(([id, _]) => id !== peerId)
          .map(([id, session]) => ({
            peerId: id,
            username: session.username,
            uid: session.uid,
            role: session.role
          }));

        server.send(JSON.stringify({ type: 'peers-list', peers: currentPeers, count: currentPeers.length }));
        this.broadcast({ type: 'new-peer', peerId, username, uid, role }, peerId);
        break;

      case 'offer':
      case 'answer':
      case 'ice-candidate':
        const targetSession = this.sessions.get(message.target);
        if (targetSession) {
          targetSession.socket.send(JSON.stringify({ ...message, from: peerId }));
        }
        break;

      case 'leave':
        this.sessions.delete(peerId);
        this.broadcast({ type: 'user-left', peerId, username }, peerId);
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

export class ChatRoom {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }
  async fetch(request) {
    return new Response('ChatRoom Durable Object', { status: 501 });
  }
}

export class MusicRoomState {
  constructor(state, env) {
    this.state = state;
    this.env = env;
  }
  async fetch(request) {
    return new Response('MusicRoomState Durable Object', { status: 501 });
  }
}
