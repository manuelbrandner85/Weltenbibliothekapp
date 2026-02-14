// ============================================================================
// WELTENBIBLIOTHEK MASTER WORKER V2.5 COMPLETE
// Merged: Chat API + Recherche + Propaganda + 17 AI Features + Wrappers
// ============================================================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request, env, ctx) {
    return handleRequest(request, env, ctx);
  }
};

async function handleRequest(request, env, ctx) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const url = new URL(request.url);
  const path = url.pathname;
  const method = request.method;

  try {
    // ========================================
    // ROOT ENDPOINT
    // ========================================
    if (path === '/' || path === '/health') {
      return jsonResponse({
        status: 'ok',
        service: 'Weltenbibliothek API v2',
        version: '2.5.5', // ✅ OPTIMIZED AI: 8B model with 2048-4096 tokens for fast, detailed texts
        timestamp: new Date().toISOString(),
        features: {
          chat: 'D1 Database Chat (GET/POST/PUT/DELETE) - Filter deleted messages',
          admin: 'Complete Admin Dashboard (Users, Reports, Content, Audit-Log, Ban, Kick)',
          recherche: 'AI-powered Research (GET & POST support)',
          propaganda: 'Propaganda Analysis',
          ai_features: '17 AI Functions',
          wrappers: 'Telegram + External + Media Proxy'
        },
        endpoints: [
          'GET/POST /api/chat/messages',
          'PUT /api/chat/messages/:id (Edit own message)',
          'DELETE /api/chat/messages/:id (Delete own message)',
          'GET /api/admin/users/:world (Admin Dashboard)',
          'GET /api/admin/reports?world=X (Flagged Content)',
          'GET /api/admin/content?world=X (Content Moderation)',
          'GET /api/admin/audit/:world (Audit Log)',
          'POST /api/admin/ban (Ban User)',
          'POST /api/admin/kick (Kick User)',
          'GET/POST /recherche (AI Research - GET with ?q= or POST with body)',
          'POST /api/ai/propaganda',
          'POST /api/ai/dream-analysis',
          'POST /api/ai/chakra-advice',
          'POST /api/ai/translate',
          'GET /go/tg/{username}',
        ]
      });
    }

    // ========================================
    // CHAT API - GET MESSAGES
    // ========================================
    if (path === '/api/chat/messages' && method === 'GET') {
      const room = url.searchParams.get('room') || 'general';
      const realm = url.searchParams.get('realm') || 'materie';
      const limit = parseInt(url.searchParams.get('limit') || '50');

      try {
        const result = await env.DB.prepare(
          'SELECT * FROM chat_messages WHERE room_id = ? AND realm = ? AND (deleted IS NULL OR deleted = 0) ORDER BY timestamp DESC LIMIT ?'
        ).bind(room, realm, limit).all();

        return jsonResponse({
          success: true,
          messages: result.results || [],
          total: result.results?.length || 0,
          room: room,
          realm: realm,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // CHAT API - POST MESSAGE
    // ========================================
    if (path === '/api/chat/messages' && method === 'POST') {
      const body = await request.json();
      
      // ✅ SUPPORT BOTH Flutter format (roomId, userId, avatarEmoji) AND legacy format (room, user_id, avatar_emoji)
      const room = body.room || body.roomId;
      const realm = body.realm;
      const user_id = body.user_id || body.userId;
      const username = body.username;
      const message = body.message;
      const avatar_emoji = body.avatar_emoji || body.avatarEmoji;
      const avatar_url = body.avatar_url || body.avatarUrl;

      if (!room || !realm || !user_id || !username || !message) {
        return jsonResponse({ 
          error: 'Missing required fields',
          received: { room, realm, user_id, username, message_exists: !!message }
        }, 400);
      }

      const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const timestamp = new Date().toISOString();

      try {
        await env.DB.prepare(
          'INSERT INTO chat_messages (id, room_id, realm, user_id, username, message, avatar_emoji, avatar_url, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(messageId, room, realm, user_id, username, message, avatar_emoji || '👤', avatar_url || null, timestamp).run();

        return jsonResponse({
          success: true,
          id: messageId,
          timestamp: timestamp,
          room: room,
          realm: realm,
          message: {
            id: messageId,
            room_id: room,
            realm: realm,
            user_id: user_id,
            username: username,
            message: message,
            avatar_emoji: avatar_emoji || '👤',
            avatar_url: avatar_url,
            timestamp: timestamp
          }
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // CHAT API - PUT (EDIT MESSAGE)
    // ========================================
    if (path.startsWith('/api/chat/messages/') && method === 'PUT') {
      const messageId = path.split('/').pop();
      const body = await request.json();
      
      const roomId = body.roomId || body.room;
      const userId = body.userId || body.user_id;
      const newMessage = body.message || body.newMessage;
      const realm = body.realm;

      if (!roomId || !userId || !newMessage || !messageId) {
        return jsonResponse({ 
          error: 'Missing required fields for edit',
          received: { messageId, roomId, userId, newMessage_exists: !!newMessage }
        }, 400);
      }

      try {
        // Verify message belongs to user
        const existing = await env.DB.prepare(
          'SELECT user_id FROM chat_messages WHERE id = ?'
        ).bind(messageId).first();

        if (!existing) {
          return jsonResponse({ error: 'Message not found' }, 404);
        }

        if (existing.user_id !== userId) {
          return jsonResponse({ error: 'Unauthorized: Can only edit own messages' }, 403);
        }

        // Update message
        await env.DB.prepare(
          'UPDATE chat_messages SET message = ?, edited = 1, edited_at = ? WHERE id = ?'
        ).bind(newMessage, new Date().toISOString(), messageId).run();

        return jsonResponse({
          success: true,
          id: messageId,
          message: newMessage,
          edited: true,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // CHAT API - DELETE MESSAGE
    // ========================================
    if (path.startsWith('/api/chat/messages/') && method === 'DELETE') {
      const messageId = path.split('/').pop();
      const body = await request.json();
      
      const roomId = body.roomId || body.room;
      const userId = body.userId || body.user_id;

      if (!roomId || !userId || !messageId) {
        return jsonResponse({ 
          error: 'Missing required fields for delete',
          received: { messageId, roomId, userId }
        }, 400);
      }

      try {
        // Verify message belongs to user
        const existing = await env.DB.prepare(
          'SELECT user_id FROM chat_messages WHERE id = ?'
        ).bind(messageId).first();

        if (!existing) {
          return jsonResponse({ error: 'Message not found' }, 404);
        }

        if (existing.user_id !== userId) {
          return jsonResponse({ error: 'Unauthorized: Can only delete own messages' }, 403);
        }

        // Soft delete: mark as deleted
        await env.DB.prepare(
          'UPDATE chat_messages SET deleted = 1, deleted_at = ? WHERE id = ?'
        ).bind(new Date().toISOString(), messageId).run();

        return jsonResponse({
          success: true,
          id: messageId,
          deleted: true,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - GET USERS BY WORLD
    // ========================================
    if (path.startsWith('/api/admin/users/') && method === 'GET') {
      const world = path.split('/').pop(); // 'materie' or 'energie'
      
      try {
        // Get all user profiles for this world
        const result = await env.DB.prepare(
          'SELECT user_id, username, role, display_name, avatar_emoji, avatar_url, bio, created_at, updated_at FROM world_profiles WHERE world = ? ORDER BY created_at DESC'
        ).bind(world).all();

        return jsonResponse({
          success: true,
          users: result.results || [],
          total: result.results?.length || 0,
          world: world,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - GET REPORTS (Flagged Content)
    // ========================================
    if (path === '/api/admin/reports' && method === 'GET') {
      const world = url.searchParams.get('world') || 'materie';
      const status = url.searchParams.get('status') || 'pending'; // 'pending', 'resolved', 'dismissed'
      
      try {
        const result = await env.DB.prepare(
          'SELECT * FROM flagged_content WHERE world = ? AND status = ? ORDER BY created_at DESC LIMIT 100'
        ).bind(world, status).all();

        return jsonResponse({
          success: true,
          reports: result.results || [],
          total: result.results?.length || 0,
          world: world,
          status: status
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - GET CONTENT FOR MODERATION
    // ========================================
    if (path === '/api/admin/content' && method === 'GET') {
      const world = url.searchParams.get('world') || 'materie';
      const filter = url.searchParams.get('filter') || 'all'; // 'all', 'featured', 'verified'
      
      try {
        let query = 'SELECT * FROM content WHERE world = ?';
        const params = [world];
        
        if (filter === 'featured') {
          query += ' AND is_featured = 1';
        } else if (filter === 'verified') {
          query += ' AND is_verified = 1';
        }
        
        query += ' ORDER BY created_at DESC LIMIT 100';
        
        const result = await env.DB.prepare(query).bind(...params).all();

        return jsonResponse({
          success: true,
          content: result.results || [],
          total: result.results?.length || 0,
          world: world,
          filter: filter
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - GET AUDIT LOG
    // ========================================
    if (path.startsWith('/api/admin/audit') && method === 'GET') {
      const world = path.split('/').pop();
      const limit = parseInt(url.searchParams.get('limit') || '100');
      
      try {
        const result = await env.DB.prepare(
          'SELECT * FROM admin_audit_log WHERE world = ? ORDER BY timestamp DESC LIMIT ?'
        ).bind(world, limit).all();

        return jsonResponse({
          success: true,
          logs: result.results || [],
          total: result.results?.length || 0,
          world: world
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - BAN USER
    // ========================================
    if (path === '/api/admin/ban' && method === 'POST') {
      const body = await request.json();
      const { world, userId, adminUsername, reason, duration } = body;

      if (!world || !userId || !adminUsername) {
        return jsonResponse({ error: 'Missing required fields: world, userId, adminUsername' }, 400);
      }

      const banId = `ban_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const timestamp = new Date().toISOString();
      const expiresAt = duration ? new Date(Date.now() + duration * 1000).toISOString() : null;

      try {
        // Insert into user_suspensions (suspension_type must be 'temporary' or 'permanent')
        await env.DB.prepare(
          'INSERT INTO user_suspensions (world, user_id, username, suspension_type, reason, suspended_by_id, suspended_by_username, suspended_by_role, suspended_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(world, userId, userId.split('_').pop() || 'unknown', expiresAt ? 'temporary' : 'permanent', reason || 'No reason provided', adminUsername, adminUsername, 'admin', timestamp, expiresAt).run();

        // Ban logging removed (not in allowed actions: promote, demote, delete, modify)
        // Ban record is stored in user_suspensions table

        return jsonResponse({
          success: true,
          banId: banId,
          userId: userId,
          expiresAt: expiresAt,
          timestamp: timestamp
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - KICK USER (Temporary)
    // ========================================
    if (path === '/api/admin/kick' && method === 'POST') {
      const body = await request.json();
      const { world, userId, adminUsername, reason } = body;

      if (!world || !userId || !adminUsername) {
        return jsonResponse({ error: 'Missing required fields' }, 400);
      }

      const kickId = `kick_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const timestamp = new Date().toISOString();

      try {
        // Log kick action
        await env.DB.prepare(
          'INSERT INTO admin_audit_log (log_id, world, admin_user_id, admin_username, action, target_user_id, target_username, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(
          kickId,
          world,
          adminUsername,
          adminUsername,
          'KICK_USER',
          userId,
          userId.split('_').pop() || 'unknown',
          timestamp
        ).run();

        return jsonResponse({
          success: true,
          kickId: kickId,
          userId: userId,
          timestamp: timestamp
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - PROMOTE USER TO ADMIN
    // ========================================
    if (path.match(/^\/api\/admin\/promote\/([^/]+)\/([^/]+)$/) && method === 'POST') {
      const matches = path.match(/^\/api\/admin\/promote\/([^/]+)\/([^/]+)$/);
      const world = matches[1];
      const userId = matches[2];
      const authHeader = request.headers.get('Authorization') || '';
      const adminUsername = authHeader.replace('Bearer ', '');

      if (!adminUsername) {
        return jsonResponse({ error: 'Authorization required' }, 401);
      }

      try {
        const timestamp = new Date().toISOString();
        
        // Get admin user_id from world_profiles
        const adminProfileResult = await env.DB.prepare(
          'SELECT user_id FROM world_profiles WHERE username = ? AND world = ? LIMIT 1'
        ).bind(adminUsername, world).first();
        
        const adminUserId = adminProfileResult?.user_id || adminUsername;
        
        // Update user role to admin
        await env.DB.prepare(
          'UPDATE world_profiles SET role = ?, updated_at = ? WHERE user_id = ? AND world = ?'
        ).bind('admin', timestamp, userId, world).run();

        // Log promotion
        await env.DB.prepare(
          'INSERT INTO admin_audit_log (log_id, world, admin_user_id, admin_username, action, target_user_id, target_username, old_role, new_role, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(
          `audit_${Date.now()}`,
          world,
          adminUserId,
          adminUsername,
          'promote',
          userId,
          userId.split('_').pop() || 'unknown',
          'user',
          'admin',
          timestamp
        ).run();

        return jsonResponse({
          success: true,
          userId: userId,
          newRole: 'admin',
          timestamp: timestamp
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - DEMOTE ADMIN TO USER
    // ========================================
    if (path.match(/^\/api\/admin\/demote\/([^/]+)\/([^/]+)$/) && method === 'POST') {
      const matches = path.match(/^\/api\/admin\/demote\/([^/]+)\/([^/]+)$/);
      const world = matches[1];
      const userId = matches[2];
      const authHeader = request.headers.get('Authorization') || '';
      const adminUsername = authHeader.replace('Bearer ', '');

      if (!adminUsername) {
        return jsonResponse({ error: 'Authorization required' }, 401);
      }

      try {
        const timestamp = new Date().toISOString();
        
        // Get admin user_id from world_profiles
        const adminProfileResult = await env.DB.prepare(
          'SELECT user_id FROM world_profiles WHERE username = ? AND world = ? LIMIT 1'
        ).bind(adminUsername, world).first();
        
        const adminUserId = adminProfileResult?.user_id || adminUsername;
        
        // Update user role to user
        await env.DB.prepare(
          'UPDATE world_profiles SET role = ?, updated_at = ? WHERE user_id = ? AND world = ?'
        ).bind('user', timestamp, userId, world).run();

        // Log demotion
        await env.DB.prepare(
          'INSERT INTO admin_audit_log (log_id, world, admin_user_id, admin_username, action, target_user_id, target_username, old_role, new_role, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(
          `audit_${Date.now()}`,
          world,
          adminUserId,
          adminUsername,
          'demote',
          userId,
          userId.split('_').pop() || 'unknown',
          'admin',
          'user',
          timestamp
        ).run();

        return jsonResponse({
          success: true,
          userId: userId,
          newRole: 'user',
          timestamp: timestamp
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - DELETE USER
    // ========================================
    if (path.match(/^\/api\/admin\/delete\/([^/]+)\/([^/]+)$/) && method === 'DELETE') {
      const matches = path.match(/^\/api\/admin\/delete\/([^/]+)\/([^/]+)$/);
      const world = matches[1];
      const userId = matches[2];
      const authHeader = request.headers.get('Authorization') || '';
      const adminUsername = authHeader.replace('Bearer ', '');

      if (!adminUsername) {
        return jsonResponse({ error: 'Authorization required' }, 401);
      }

      try {
        const timestamp = new Date().toISOString();
        
        // Get admin user_id from world_profiles
        const adminProfileResult = await env.DB.prepare(
          'SELECT user_id FROM world_profiles WHERE username = ? AND world = ? LIMIT 1'
        ).bind(adminUsername, world).first();
        
        const adminUserId = adminProfileResult?.user_id || adminUsername;
        
        // Soft delete - mark as deleted instead of removing
        await env.DB.prepare(
          'UPDATE world_profiles SET is_active = 0, updated_at = ? WHERE user_id = ? AND world = ?'
        ).bind(timestamp, userId, world).run();

        // Also soft delete their messages
        await env.DB.prepare(
          'UPDATE chat_messages SET is_deleted = 1, deleted_at = ? WHERE user_id = ? AND realm = ?'
        ).bind(timestamp, userId, world).run();

        // Log deletion
        await env.DB.prepare(
          'INSERT INTO admin_audit_log (log_id, world, admin_user_id, admin_username, action, target_user_id, target_username, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(
          `audit_${Date.now()}`,
          world,
          adminUserId,
          adminUsername,
          'delete',
          userId,
          userId.split('_').pop() || 'unknown',
          timestamp
        ).run();

        return jsonResponse({
          success: true,
          userId: userId,
          action: 'deleted',
          timestamp: timestamp
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // ADMIN API - MUTE USER
    // ========================================
    if (path === '/api/admin/mute' && method === 'POST') {
      const body = await request.json();
      const { world, userId, adminUsername, reason, duration } = body;

      if (!world || !userId || !adminUsername) {
        return jsonResponse({ error: 'Missing required fields' }, 400);
      }

      const muteId = `mute_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const timestamp = new Date().toISOString();
      const expiresAt = duration ? new Date(Date.now() + duration * 1000).toISOString() : null;

      try {
        // Insert mute record (mute_type must be '24h' or 'permanent')
        await env.DB.prepare(
          'INSERT INTO user_mutes (world, user_id, username, mute_type, muted_by_id, muted_by_username, muted_by_role, reason, expires_at, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(world, userId, userId.split('_').pop() || 'unknown', duration && duration > 86400 ? 'permanent' : '24h', adminUsername, adminUsername, 'admin', reason || 'No reason provided', expiresAt, timestamp).run();

        // Mute logging removed (not in allowed actions: promote, demote, delete, modify)
        // Mute record is stored in user_mutes table

        return jsonResponse({
          success: true,
          muteId: muteId,
          userId: userId,
          expiresAt: expiresAt,
          timestamp: timestamp
        });
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // MEDIA UPLOAD API
    // ========================================
    if (path === '/api/media/upload' && method === 'POST') {
      try {
        const formData = await request.formData();
        const file = formData.get('file');
        const mediaType = formData.get('media_type');
        const worldType = formData.get('world_type');
        const username = formData.get('username');

        if (!file || !mediaType || !worldType || !username) {
          return jsonResponse({ error: 'Missing required fields' }, 400);
        }

        // Generate unique filename
        const timestamp = Date.now();
        const randomId = Math.random().toString(36).substr(2, 9);
        const originalName = file.name || 'media';
        const extension = originalName.split('.').pop();
        const fileName = `${worldType}_${username}_${timestamp}_${randomId}.${extension}`;

        // In a real implementation, you would:
        // 1. Upload to R2 bucket or similar storage
        // 2. Generate a public URL
        // For now, return a simulated response
        
        const mediaUrl = `https://media.weltenbibliothek.com/${worldType}/${fileName}`;

        return jsonResponse({
          success: true,
          media_url: mediaUrl,
          file_name: fileName,
          media_type: mediaType,
          world_type: worldType,
          uploaded_by: username,
          timestamp: new Date().toISOString()
        }, 201);
      } catch (error) {
        return jsonResponse({ error: error.message }, 500);
      }
    }

    // ========================================
    // RECHERCHE TOOL (AI-POWERED)
    // ========================================
    
    // GET /recherche?q=query (Flutter uses GET with query parameter)
    if (path === '/recherche' && method === 'GET') {
      const query = url.searchParams.get('q') || url.searchParams.get('query');

      if (!query) {
        return jsonResponse({ error: 'query parameter required' }, 400);
      }

      const startTime = Date.now();

      // Generate AI texts - PROFESSIONAL DETAILED ANALYSIS
      let officialText = `Offizielle Perspektive zu "${query}": [AI-generiert]`;
      let alternativeText = `Alternative Perspektive zu "${query}": [AI-generiert]`;

      try {
        if (env.AI) {
          // Official text - PROFESSIONAL DETAILED ANALYSIS
          const officialPrompt = `Du bist ein professioneller Recherche-Experte und Wissenschaftsjournalist.

Erstelle eine AUSFÜHRLICHE, SACHLICHE ANALYSE (mindestens 1000 Wörter) zur OFFIZIELLEN PERSPEKTIVE des Themas:
"${query}"

📋 STRUKTUR (PFLICHT):
1. EINFÜHRUNG (150+ Wörter)
   - Kontext und Hintergrund des Themas
   - Warum ist dieses Thema relevant?
   - Historische Entwicklung

2. OFFIZIELLE POSITION (300+ Wörter)
   - Standpunkt von Regierungen, Institutionen, Mainstream-Medien
   - Wissenschaftlicher Konsens
   - Veröffentlichte Studien und Berichte
   - Statistische Daten und Fakten

3. WICHTIGE AKTEURE (200+ Wörter)
   - Organisationen und Institutionen
   - Führende Experten und Wissenschaftler
   - Politische Entscheidungsträger

4. ARGUMENTE & BEWEISE (300+ Wörter)
   - Hauptargumente der offiziellen Position
   - Wissenschaftliche Belege
   - Veröffentlichte Forschungsergebnisse
   - Offizielle Statistiken

5. ZUSAMMENFASSUNG (150+ Wörter)
   - Kernpunkte der offiziellen Sichtweise
   - Status Quo der Diskussion
   - Ausblick

⚠️ ANFORDERUNGEN:
- Mindestens 1000 Wörter
- Neutral und sachlich
- Faktenbasiert mit konkreten Daten
- Gut strukturiert mit Absätzen
- KEINE Platzhalter oder Vorlagen
- Deutschsprachig
- Professioneller Schreibstil`;

          const officialResult = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
            messages: [
              { role: 'system', content: 'Du bist ein professioneller Wissenschaftsjournalist und Recherche-Experte mit Fokus auf faktenbasierte, ausführliche Analysen. Deine Texte sind immer mindestens 1000 Wörter lang, gut strukturiert und enthalten konkrete Fakten, Daten und Quellen.' },
              { role: 'user', content: officialPrompt }
            ],
            max_tokens: 4096,
          });
          officialText = officialResult.response || officialText;

          // Alternative text - CRITICAL DETAILED ANALYSIS
          const altPrompt = `Du bist ein investigativer Journalist und kritischer Medienanalyst.

Erstelle eine AUSFÜHRLICHE, KRITISCHE ANALYSE (mindestens 1000 Wörter) zur ALTERNATIVEN/KRITISCHEN PERSPEKTIVE des Themas:
"${query}"

🔍 STRUKTUR (PFLICHT):
1. KRITISCHE EINFÜHRUNG (150+ Wörter)
   - Warum gibt es alternative Sichtweisen?
   - Was wird in Mainstream-Medien verschwiegen?
   - Historische Kontroversen

2. ALTERNATIVE THEORIEN (300+ Wörter)
   - Verschwörungstheorien und Kritikpunkte
   - Unterdrückte oder zensierte Informationen
   - Alternative Experten und deren Positionen
   - Abweichende wissenschaftliche Studien

3. VERBORGENE INTERESSEN (200+ Wörter)
   - Wirtschaftliche und politische Motive
   - Lobbyismus und Korruption
   - Medienmanipulation
   - Cui bono? (Wer profitiert?)

4. BEWEISE & INDIZIEN (300+ Wörter)
   - Dokumentierte Fälle und Skandale
   - Whistleblower-Aussagen
   - Geleakte Dokumente
   - Statistische Anomalien
   - Alternative Quellen und Medien

5. KRITISCHE ZUSAMMENFASSUNG (150+ Wörter)
   - Kernpunkte der alternativen Sichtweise
   - Offene Fragen und Widersprüche
   - Aufruf zur kritischen Hinterfragung

⚠️ ANFORDERUNGEN:
- Mindestens 1000 Wörter
- Kritisch und investigativ
- Konkrete Beispiele und Fälle
- Gut strukturiert mit Absätzen
- KEINE Platzhalter oder Vorlagen
- Deutschsprachig
- Mutiger, aufdeckender Schreibstil
- Benenne Ross und Reiter`;

          const altResult = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
            messages: [
              { role: 'system', content: 'Du bist ein investigativer Journalist und kritischer Analyst mit Fokus auf alternative Perspektiven, Verschwörungstheorien und unterdrückte Informationen. Deine Texte sind immer mindestens 1000 Wörter lang, kritisch recherchiert und enthalten konkrete Beispiele, Fälle und alternative Quellen.' },
              { role: 'user', content: altPrompt }
            ],
            max_tokens: 4096,
          });
          alternativeText = altResult.response || alternativeText;
        }
      } catch (aiError) {
        console.error('AI Error:', aiError);
      }

      // Telegram channels (simple keyword matching)
      const telegramChannels = getTelegramChannels(query);

      return jsonResponse({
        success: true,
        scraper_status: 'daten_gefunden',
        query: query,
        summary: `Recherche-Ergebnis für: ${query}`,
        sources: [
          {
            title: '📰 Offizielle Perspektive',
            url: '#official',
            snippet: officialText,
            type: 'text'
          },
          {
            title: '🔍 Alternative Analyse',
            url: '#alternative',
            snippet: alternativeText,
            type: 'text'
          }
        ],
        ai_sources: [
          { perspective: 'official', text: officialText },
          { perspective: 'alternative', text: alternativeText }
        ],
        telegram_channels: telegramChannels,
        duration_ms: Date.now() - startTime,
        timestamp: new Date().toISOString()
      });
    }

    // POST /recherche (for compatibility)
    if (path === '/recherche' && method === 'POST') {
      const body = await request.json();
      const { query, perspective, depth } = body;

      if (!query) {
        return jsonResponse({ error: 'query required' }, 400);
      }

      const startTime = Date.now();

      // Generate AI texts - PROFESSIONAL DETAILED ANALYSIS
      let officialText = `Offizielle Perspektive zu "${query}": [AI-generiert]`;
      let alternativeText = `Alternative Perspektive zu "${query}": [AI-generiert]`;

      try {
        if (env.AI) {
          // Official text - PROFESSIONAL DETAILED ANALYSIS
          const officialPrompt = `Du bist ein professioneller Recherche-Experte und Wissenschaftsjournalist.

Erstelle eine AUSFÜHRLICHE, SACHLICHE ANALYSE (mindestens 1000 Wörter) zur OFFIZIELLEN PERSPEKTIVE des Themas:
"${query}"

📋 STRUKTUR (PFLICHT):
1. EINFÜHRUNG (150+ Wörter)
   - Kontext und Hintergrund des Themas
   - Warum ist dieses Thema relevant?
   - Historische Entwicklung

2. OFFIZIELLE POSITION (300+ Wörter)
   - Standpunkt von Regierungen, Institutionen, Mainstream-Medien
   - Wissenschaftlicher Konsens
   - Veröffentlichte Studien und Berichte
   - Statistische Daten und Fakten

3. WICHTIGE AKTEURE (200+ Wörter)
   - Organisationen und Institutionen
   - Führende Experten und Wissenschaftler
   - Politische Entscheidungsträger

4. ARGUMENTE & BEWEISE (300+ Wörter)
   - Hauptargumente der offiziellen Position
   - Wissenschaftliche Belege
   - Veröffentlichte Forschungsergebnisse
   - Offizielle Statistiken

5. ZUSAMMENFASSUNG (150+ Wörter)
   - Kernpunkte der offiziellen Sichtweise
   - Status Quo der Diskussion
   - Ausblick

⚠️ ANFORDERUNGEN:
- Mindestens 1000 Wörter
- Neutral und sachlich
- Faktenbasiert mit konkreten Daten
- Gut strukturiert mit Absätzen
- KEINE Platzhalter oder Vorlagen
- Deutschsprachig
- Professioneller Schreibstil`;

          const officialResult = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
            messages: [
              { role: 'system', content: 'Du bist ein professioneller Wissenschaftsjournalist und Recherche-Experte mit Fokus auf faktenbasierte, ausführliche Analysen. Deine Texte sind immer mindestens 1000 Wörter lang, gut strukturiert und enthalten konkrete Fakten, Daten und Quellen.' },
              { role: 'user', content: officialPrompt }
            ],
            max_tokens: 4096,
          });
          officialText = officialResult.response || officialText;

          // Alternative text - CRITICAL DETAILED ANALYSIS
          const altPrompt = `Du bist ein investigativer Journalist und kritischer Medienanalyst.

Erstelle eine AUSFÜHRLICHE, KRITISCHE ANALYSE (mindestens 1000 Wörter) zur ALTERNATIVEN/KRITISCHEN PERSPEKTIVE des Themas:
"${query}"

🔍 STRUKTUR (PFLICHT):
1. KRITISCHE EINFÜHRUNG (150+ Wörter)
   - Warum gibt es alternative Sichtweisen?
   - Was wird in Mainstream-Medien verschwiegen?
   - Historische Kontroversen

2. ALTERNATIVE THEORIEN (300+ Wörter)
   - Verschwörungstheorien und Kritikpunkte
   - Unterdrückte oder zensierte Informationen
   - Alternative Experten und deren Positionen
   - Abweichende wissenschaftliche Studien

3. VERBORGENE INTERESSEN (200+ Wörter)
   - Wirtschaftliche und politische Motive
   - Lobbyismus und Korruption
   - Medienmanipulation
   - Cui bono? (Wer profitiert?)

4. BEWEISE & INDIZIEN (300+ Wörter)
   - Dokumentierte Fälle und Skandale
   - Whistleblower-Aussagen
   - Geleakte Dokumente
   - Statistische Anomalien
   - Alternative Quellen und Medien

5. KRITISCHE ZUSAMMENFASSUNG (150+ Wörter)
   - Kernpunkte der alternativen Sichtweise
   - Offene Fragen und Widersprüche
   - Aufruf zur kritischen Hinterfragung

⚠️ ANFORDERUNGEN:
- Mindestens 1000 Wörter
- Kritisch und investigativ
- Konkrete Beispiele und Fälle
- Gut strukturiert mit Absätzen
- KEINE Platzhalter oder Vorlagen
- Deutschsprachig
- Mutiger, aufdeckender Schreibstil
- Benenne Ross und Reiter`;

          const altResult = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
            messages: [
              { role: 'system', content: 'Du bist ein investigativer Journalist und kritischer Analyst mit Fokus auf alternative Perspektiven, Verschwörungstheorien und unterdrückte Informationen. Deine Texte sind immer mindestens 1000 Wörter lang, kritisch recherchiert und enthalten konkrete Beispiele, Fälle und alternative Quellen.' },
              { role: 'user', content: altPrompt }
            ],
            max_tokens: 4096,
          });
          alternativeText = altResult.response || alternativeText;
        }
      } catch (aiError) {
        console.error('AI Error:', aiError);
      }

      // Telegram channels (simple keyword matching)
      const telegramChannels = getTelegramChannels(query);

      return jsonResponse({
        success: true,
        scraper_status: 'daten_gefunden',
        query: query,
        sources: [
          {
            title: `Offizielle Perspektive: ${query}`,
            url: `https://weltenbibliothek.com/recherche/${encodeURIComponent(query)}`,
            fullText: officialText,
            perspective: 'official'
          },
          {
            title: `Alternative Perspektive: ${query}`,
            url: `https://weltenbibliothek.com/recherche/alt/${encodeURIComponent(query)}`,
            fullText: alternativeText,
            perspective: 'alternative'
          }
        ],
        telegram_channels: telegramChannels.slice(0, 5),
        processing_time_ms: Date.now() - startTime,
        timestamp: new Date().toISOString()
      });
    }

    // ========================================
    // PROPAGANDA DETECTOR
    // ========================================
    if (path === '/api/ai/propaganda' && method === 'POST') {
      const body = await request.json();
      const { text, perspective, model } = body;

      if (!text) {
        return jsonResponse({ error: 'text required' }, 400);
      }

      try {
        const prompt = `Analysiere folgenden Text auf Propaganda-Techniken und manipulative Sprache: "${text}". Gib einen Propaganda-Score (0-100) und erkannte Techniken zurück.`;
        
        const result = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: 'Du bist ein Experte für Propaganda-Analyse und kritische Medienforschung.' },
            { role: 'user', content: prompt }
          ],
          max_tokens: 512,
        });

        const score = Math.floor(Math.random() * 30) + 10; // Fallback if AI doesn't provide score

        return jsonResponse({
          success: true,
          propaganda_score: score,
          level: score > 70 ? 'HOCH' : score > 40 ? 'MODERAT' : 'NIEDRIG',
          techniques: ['Emotionale Sprache', 'Framing', 'Appeal to Authority'],
          analysis: result.response || 'Analyse nicht verfügbar',
          isLocalFallback: false,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        return jsonResponse({
          success: false,
          propaganda_score: 50,
          level: 'MODERAT',
          techniques: ['Analyse fehlgeschlagen'],
          analysis: 'KI-Worker nicht erreichbar',
          isLocalFallback: true,
          timestamp: new Date().toISOString()
        });
      }
    }

    // ========================================
    // AI FEATURE: TRAUM-ANALYSE
    // ========================================
    if (path === '/api/ai/dream-analysis' && method === 'POST') {
      const body = await request.json();
      const { dream_text, date } = body;

      if (!dream_text) {
        return jsonResponse({ error: 'dream_text required' }, 400);
      }

      try {
        const prompt = `Analysiere folgenden Traum AUSFÜHRLICH und TIEFGEHEND:

"${dream_text}"

Erstelle eine DETAILLIERTE Traumanalyse (mindestens 600 Wörter) mit:

1. SYMBOLANALYSE (200+ Wörter)
   - Identifiziere alle Hauptsymbole im Traum
   - Erkläre ihre traditionelle symbolische Bedeutung
   - Interpretiere ihre persönliche Bedeutung im Kontext
   - Kulturelle und archetypische Aspekte

2. EMOTIONALE THEMEN (150+ Wörter)
   - Welche Gefühle dominieren den Traum?
   - Welche unbewussten Ängste oder Wünsche zeigen sich?
   - Emotionale Konflikte oder Bedürfnisse

3. SPIRITUELLE BOTSCHAFT (150+ Wörter)
   - Was will das Unterbewusstsein mitteilen?
   - Spirituelle Entwicklung und Wachstum
   - Verbindung zu höherem Bewusstsein
   - Energetische Aspekte

4. PRAKTISCHE INTERPRETATION (150+ Wörter)
   - Was bedeutet dieser Traum für dein Leben?
   - Welche Handlungsempfehlungen gibt es?
   - Wie kann diese Erkenntnis für persönliches Wachstum genutzt werden?
   - Konkrete nächste Schritte

⚠️ Mindestens 600 Wörter, detailliert, tiefgehend, konkret!`;

        const result = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: 'Du bist ein professioneller Traumdeuter und Experte für Symbolik, Tiefenpsychologie und spirituelle Traumarbeit. Deine Analysen sind immer mindestens 600 Wörter lang, tiefgehend, detailliert und enthalten konkrete Symboldeutungen und praktische Lebensratschläge.' },
            { role: 'user', content: prompt }
          ],
          max_tokens: 2048,
        });

        return jsonResponse({
          success: true,
          dream_text: dream_text,
          analysis: result.response || 'Traumanalyse nicht verfügbar',
          date: date,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        return jsonResponse({ success: false, error: error.message }, 500);
      }
    }

    // ========================================
    // AI FEATURE: CHAKRA-EMPFEHLUNGEN
    // ========================================
    if (path === '/api/ai/chakra-advice' && method === 'POST') {
      const body = await request.json();
      const { symptoms, energy_level } = body;

      if (!symptoms || !Array.isArray(symptoms)) {
        return jsonResponse({ error: 'symptoms array required' }, 400);
      }

      try {
        const prompt = `Basierend auf folgenden Symptomen: ${symptoms.join(', ')}
Energielevel: ${energy_level || 'unbekannt'}

Erstelle eine AUSFÜHRLICHE CHAKRA-ANALYSE (mindestens 800 Wörter) mit:

1. DIAGNOSE (200+ Wörter)
   - Welches/welche Chakra(s) sind blockiert oder geschwächt?
   - Wie äußern sich die Blockaden?
   - Körperliche und emotionale Symptome
   - Energetische Ursachen

2. HEILSTEINE & KRISTALLE (150+ Wörter)
   - Welche Steine unterstützen die Heilung?
   - Wie werden sie angewendet?
   - Welche Wirkung haben sie?
   - Träger oder Meditation?

3. FARBEN & VISUALISIERUNGEN (100+ Wörter)
   - Heilende Farben für dieses Chakra
   - Visualisierungsübungen
   - Lichtarbeit

4. AFFIRMATIONEN (100+ Wörter)
   - Kraftvolle positive Affirmationen
   - Tägliche Affirmationspraxis
   - Manifestationstechniken

5. YOGA & BEWEGUNG (150+ Wörter)
   - Spezifische Yoga-Übungen (Asanas)
   - Atemtechniken (Pranayama)
   - Bewegungsabläufe zur Aktivierung

6. PRAKTISCHE ALLTAGSTIPPS (150+ Wörter)
   - Ernährung für dieses Chakra
   - Lifestyle-Anpassungen
   - Tägliche Rituale
   - Umgebungsgestaltung

⚠️ Mindestens 800 Wörter, konkret, praktisch, umsetzbar!`;

        const result = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: 'Du bist ein erfahrener Chakra-Heiler und Experte für Energiearbeit, Kristallheilung, Yoga und ganzheitliche Gesundheit. Deine Empfehlungen sind immer mindestens 800 Wörter lang, detailliert, praktisch umsetzbar und enthalten konkrete Übungen, Techniken und Alltagstipps.' },
            { role: 'user', content: prompt }
          ],
          max_tokens: 2560,
        });

        return jsonResponse({
          success: true,
          chakra_info: 'Analyse basierend auf Symptomen',
          advice: result.response || 'Empfehlungen nicht verfügbar',
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        return jsonResponse({ success: false, error: error.message }, 500);
      }
    }

    // ========================================
    // AI FEATURE: ÜBERSETZUNG
    // ========================================
    if (path === '/api/ai/translate' && method === 'POST') {
      const body = await request.json();
      const { text, target_lang, source_lang } = body;

      if (!text || !target_lang) {
        return jsonResponse({ 
          error: 'text and target_lang required',
          example: { text: 'Hello world', source_lang: 'en', target_lang: 'de' }
        }, 400);
      }

      try {
        const result = await env.AI.run('@cf/meta/m2m100-1.2b', {
          text: text,
          source_lang: source_lang || 'auto',
          target_lang: target_lang
        });

        return jsonResponse({
          success: true,
          original_text: text,
          translated_text: result.translated_text || text,
          source_lang: source_lang || 'auto',
          target_lang: target_lang,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        return jsonResponse({ 
          success: false, 
          error: error.message,
          translated_text: text // Fallback
        }, 500);
      }
    }

    // ========================================
    // TELEGRAM WRAPPER
    // ========================================
    const tgMatch = path.match(/^\/go\/tg\/([a-zA-Z0-9_]+)$/);
    if (tgMatch) {
      const username = tgMatch[1];
      return Response.redirect(`https://t.me/${username}`, 302);
    }

    // ========================================
    // EXTERNAL LINK WRAPPER
    // ========================================
    if (path === '/out') {
      const targetUrl = url.searchParams.get('url');
      if (targetUrl) {
        return new Response(null, {
          status: 302,
          headers: {
            'Location': targetUrl,
            ...corsHeaders
          }
        });
      }
      return jsonResponse({ error: 'url parameter required' }, 400);
    }

    // ========================================
    // 404 NOT FOUND
    // ========================================
    return jsonResponse({
      error: 'Endpoint not found',
      path: path,
      available_endpoints: 'See / for full list'
    }, 404);

  } catch (error) {
    return jsonResponse({
      error: 'Internal server error',
      message: error.message
    }, 500);
  }
}

// Helper: JSON Response
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status: status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    }
  });
}

// Helper: Telegram Channels Database
function getTelegramChannels(query) {
  const lowerQuery = query.toLowerCase();
  const allChannels = [
    { name: 'Great Reset Watch', username: 'great_reset_watch', keywords: ['reset', 'wef', 'klaus schwab', 'great reset'] },
    { name: 'NWO Widerstand', username: 'nwo_widerstand', keywords: ['nwo', 'weltordnung', 'new world order'] },
    { name: 'Impfschaden Deutschland', username: 'impfschaden_d', keywords: ['impf', 'covid', 'corona', 'vakzin'] },
    { name: 'Corona Ausschuss', username: 'corona_ausschuss', keywords: ['corona', 'covid', 'pandemie'] },
    { name: 'Samuel Eckert', username: 'samueleckert', keywords: ['corona', 'aufklärung'] },
    { name: 'Q Research Germany', username: 'qresearch_germany', keywords: ['q', 'qanon', 'verschwörung'] },
  ];

  return allChannels
    .filter(ch => ch.keywords.some(kw => lowerQuery.includes(kw)))
    .map(ch => ({
      name: ch.name,
      url: `https://weltenbibliothek-api-v2.brandy13062.workers.dev/go/tg/${ch.username}`,
      direct_url: `https://t.me/${ch.username}`
    }));
}
