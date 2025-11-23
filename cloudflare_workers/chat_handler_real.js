/**
 * ═══════════════════════════════════════════════════════════════
 * ECHTER CHAT HANDLER - Messages CRUD mit D1
 * ═══════════════════════════════════════════════════════════════
 */

import { verifyJWT, extractUserFromToken } from './auth_utils.js';

export async function handleChatReal(request, path, env) {
  const method = request.method;

  // GET /chat-rooms
  if (path === '/chat-rooms' && method === 'GET') {
    try {
      const { results } = await env.DB.prepare(
        'SELECT * FROM chat_rooms ORDER BY is_fixed DESC, created_at DESC'
      ).all();
      
      return new Response(JSON.stringify({
        success: true,
        chat_rooms: results
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Error fetching chat rooms:', error);
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Database error',
        chat_rooms: [] 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // GET /messages/:roomId
  if (path.startsWith('/messages/') && method === 'GET') {
    const roomId = path.split('/')[2];
    
    try {
      const { results } = await env.DB.prepare(
        'SELECT * FROM messages WHERE chat_room_id = ? ORDER BY created_at DESC LIMIT 100'
      ).bind(roomId).all();
      
      return new Response(JSON.stringify({
        success: true,
        messages: results.reverse() // Chronological order
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Error fetching messages:', error);
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Database error',
        messages: [] 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // POST /messages/:roomId - Send message
  if (path.startsWith('/messages/') && method === 'POST') {
    const roomId = path.split('/')[2];
    
    try {
      // Verify authentication
      const authHeader = request.headers.get('Authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Unauthorized' 
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const token = authHeader.substring(7);
      const payload = await verifyJWT(token);

      if (!payload) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Invalid or expired token' 
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Get message data
      const body = await request.json();
      const { content, type, media_url } = body;

      if (!content) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Content is required' 
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Create message
      const messageId = 'msg_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
      const now = new Date().toISOString();

      await env.DB.prepare(
        'INSERT INTO messages (id, chat_room_id, sender_id, sender_name, content, type, media_url, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
      ).bind(
        messageId,
        roomId,
        payload.userId,
        payload.username,
        content,
        type || 'text',
        media_url || null,
        now
      ).run();

      // Update last message in chat room
      await env.DB.prepare(
        'UPDATE chat_rooms SET last_message = ?, last_message_time = ? WHERE id = ?'
      ).bind(content.substring(0, 100), now, roomId).run();

      return new Response(JSON.stringify({
        success: true,
        message: {
          id: messageId,
          chat_room_id: roomId,
          sender_id: payload.userId,
          sender_name: payload.username,
          content: content,
          type: type || 'text',
          media_url: media_url || null,
          created_at: now,
          is_edited: 0
        }
      }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Error sending message:', error);
      return new Response(JSON.stringify({ 
        success: false,
        error: 'Failed to send message: ' + error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // PUT /messages/:roomId/:messageId - Edit message
  if (path.match(/^\/messages\/[^/]+\/[^/]+$/) && method === 'PUT') {
    const [, , roomId, messageId] = path.split('/');
    
    try {
      // Verify authentication
      const authHeader = request.headers.get('Authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Unauthorized' 
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const token = authHeader.substring(7);
      const payload = await verifyJWT(token);

      if (!payload) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Invalid or expired token' 
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Get message
      const message = await env.DB.prepare(
        'SELECT * FROM messages WHERE id = ? AND chat_room_id = ?'
      ).bind(messageId, roomId).first();

      if (!message) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Message not found' 
        }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Check if user owns the message
      if (message.sender_id !== payload.userId) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'You can only edit your own messages' 
        }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Get new content
      const body = await request.json();
      const { content } = body;

      if (!content) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Content is required' 
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Update message
      const now = new Date().toISOString();
      await env.DB.prepare(
        'UPDATE messages SET content = ?, is_edited = 1, updated_at = ? WHERE id = ?'
      ).bind(content, now, messageId).run();

      return new Response(JSON.stringify({
        success: true,
        message: {
          ...message,
          content: content,
          is_edited: 1,
          updated_at: now
        }
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Error editing message:', error);
      return new Response(JSON.stringify({ 
        success: false,
        error: 'Failed to edit message: ' + error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // DELETE /messages/:roomId/:messageId - Delete message
  if (path.match(/^\/messages\/[^/]+\/[^/]+$/) && method === 'DELETE') {
    const [, , roomId, messageId] = path.split('/');
    
    try {
      // Verify authentication
      const authHeader = request.headers.get('Authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Unauthorized' 
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const token = authHeader.substring(7);
      const payload = await verifyJWT(token);

      if (!payload) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Invalid or expired token' 
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Get message
      const message = await env.DB.prepare(
        'SELECT * FROM messages WHERE id = ? AND chat_room_id = ?'
      ).bind(messageId, roomId).first();

      if (!message) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'Message not found' 
        }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Check if user owns the message or is admin
      if (message.sender_id !== payload.userId && payload.role !== 'admin' && payload.role !== 'super_admin') {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'You can only delete your own messages' 
        }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Delete message
      await env.DB.prepare(
        'DELETE FROM messages WHERE id = ?'
      ).bind(messageId).run();

      return new Response(JSON.stringify({
        success: true,
        message: 'Message deleted'
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Error deleting message:', error);
      return new Response(JSON.stringify({ 
        success: false,
        error: 'Failed to delete message: ' + error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' }
  });
}
