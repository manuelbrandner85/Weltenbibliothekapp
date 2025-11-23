/**
 * ═══════════════════════════════════════════════════════════════
 * ECHTE AUTHENTIFIZIERUNG - Registration & Login mit D1
 * ═══════════════════════════════════════════════════════════════
 */

import { hashPassword, verifyPassword, generateJWT, verifyJWT, extractUserFromToken } from './auth_utils.js';

export async function handleAuthReal(request, path, env) {
  const method = request.method;

  // POST /api/auth/register - ECHTE Registration
  if (path === '/api/auth/register' && method === 'POST') {
    try {
      const body = await request.json();
      const { username, password, email } = body;

      // Validation
      if (!username || !password) {
        return new Response(JSON.stringify({
          success: false,
          error: 'Username and password are required'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Check if user exists
      const existingUser = await env.DB.prepare(
        'SELECT id FROM users WHERE username = ?'
      ).bind(username).first();

      if (existingUser) {
        return new Response(JSON.stringify({
          success: false,
          error: 'Username already exists'
        }), {
          status: 409,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Hash password
      const passwordHash = await hashPassword(password);
      
      // Create user
      const userId = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
      const now = Math.floor(Date.now() / 1000);

      await env.DB.prepare(
        'INSERT INTO users (id, username, email, password_hash, role, created_at) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(userId, username, email || null, passwordHash, 'user', now).run();

      // Generate JWT
      const token = await generateJWT({
        userId: userId,
        username: username,
        role: 'user'
      });

      return new Response(JSON.stringify({
        success: true,
        token: token,
        user: {
          id: userId,
          username: username,
          email: email || null,
          role: 'user',
          created_at: new Date(now * 1000).toISOString()
        }
      }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Registration error:', error);
      return new Response(JSON.stringify({
        success: false,
        error: 'Registration failed: ' + error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // POST /api/auth/login - ECHTES Login
  if (path === '/api/auth/login' && method === 'POST') {
    try {
      const body = await request.json();
      const { username, password } = body;

      // Validation
      if (!username || !password) {
        return new Response(JSON.stringify({
          success: false,
          error: 'Username and password are required'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Get user from database
      const user = await env.DB.prepare(
        'SELECT id, username, email, password_hash, role, is_banned FROM users WHERE username = ?'
      ).bind(username).first();

      if (!user) {
        return new Response(JSON.stringify({
          success: false,
          error: 'Invalid username or password'
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Check if banned
      if (user.is_banned === 1) {
        return new Response(JSON.stringify({
          success: false,
          error: 'Account is banned'
        }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Verify password
      const isValidPassword = await verifyPassword(user.password_hash, password);
      
      if (!isValidPassword) {
        return new Response(JSON.stringify({
          success: false,
          error: 'Invalid username or password'
        }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Update last login
      const now = Math.floor(Date.now() / 1000);
      await env.DB.prepare(
        'UPDATE users SET last_login = ? WHERE id = ?'
      ).bind(now, user.id).run();

      // Generate JWT
      const token = await generateJWT({
        userId: user.id,
        username: user.username,
        role: user.role
      });

      return new Response(JSON.stringify({
        success: true,
        token: token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role,
          last_login: new Date(now * 1000).toISOString()
        }
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Login error:', error);
      return new Response(JSON.stringify({
        success: false,
        error: 'Login failed: ' + error.message
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }

  // GET /api/auth/me - Get current user
  if (path === '/api/auth/me' && method === 'GET') {
    try {
      const authHeader = request.headers.get('Authorization');
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      const token = authHeader.substring(7);
      const payload = await verifyJWT(token);

      if (!payload) {
        return new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      // Get user from database
      const user = await env.DB.prepare(
        'SELECT id, username, email, role, created_at FROM users WHERE id = ?'
      ).bind(payload.userId).first();

      if (!user) {
        return new Response(JSON.stringify({ error: 'User not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        });
      }

      return new Response(JSON.stringify({
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          role: user.role
        }
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    } catch (error) {
      console.error('Get user error:', error);
      return new Response(JSON.stringify({ 
        error: 'Failed to get user' 
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
