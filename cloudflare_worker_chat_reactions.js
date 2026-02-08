/**
 * 💬 CHAT REACTIONS API
 * Cloudflare Worker Extension für weltenbibliothek-community-api
 * 
 * Features:
 * - Reaktionen hinzufügen (Emoji)
 * - Reaktionen entfernen
 * - Reaktionen zählen
 * - User-Reaktionen tracken
 */

import { Router } from 'itty-router';

// ===========================
// KONFIGURATION
// ===========================

const ALLOWED_EMOJIS = [
  '👍', '❤️', '😂', '😮', '😢', '🙏',  // Standard
  '✨', '🔥', '💡', '🎯', '🌟', '⚡',  // Energie
  '📚', '🔍', '🧠', '💭', '🗣️', '👁️'   // Materie
];

// ===========================
// API ROUTES
// ===========================

/**
 * POST /chat/messages/:messageId/reactions
 * Füge Reaktion zu Chat-Nachricht hinzu
 * 
 * Body:
 * {
 *   "emoji": "👍",
 *   "username": "currentUser"
 * }
 */
export async function addReaction(request, env) {
  try {
    const { messageId } = request.params;
    const { emoji, username } = await request.json();
    
    // Validierung
    if (!emoji || !username) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Emoji und Username erforderlich'
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    if (!ALLOWED_EMOJIS.includes(emoji)) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Nicht erlaubtes Emoji'
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Prüfe ob Nachricht existiert
    const messageExists = await env.DB.prepare(`
      SELECT id FROM chat_messages WHERE id = ?
    `).bind(messageId).first();
    
    if (!messageExists) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Nachricht nicht gefunden'
      }), { status: 404, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Prüfe ob User bereits reagiert hat (verhindere Duplikate)
    const existingReaction = await env.DB.prepare(`
      SELECT id FROM chat_reactions 
      WHERE message_id = ? AND username = ? AND emoji = ?
    `).bind(messageId, username, emoji).first();
    
    if (existingReaction) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Du hast bereits mit diesem Emoji reagiert'
      }), { status: 409, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Füge Reaktion hinzu
    const result = await env.DB.prepare(`
      INSERT INTO chat_reactions (message_id, emoji, username, created_at)
      VALUES (?, ?, ?, datetime('now'))
    `).bind(messageId, emoji, username).run();
    
    // Hole aktualisierte Reaktions-Counts
    const counts = await getReactionCounts(env, messageId);
    
    return new Response(JSON.stringify({
      success: true,
      reaction: {
        id: result.meta.last_row_id,
        messageId: messageId,
        emoji: emoji,
        username: username,
        createdAt: new Date().toISOString()
      },
      counts: counts
    }), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Add Reaction Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message || 'Interner Server-Fehler'
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * DELETE /chat/messages/:messageId/reactions/:emoji
 * Entferne Reaktion von Chat-Nachricht
 * 
 * Query: ?username=currentUser
 */
export async function removeReaction(request, env) {
  try {
    const { messageId, emoji } = request.params;
    const url = new URL(request.url);
    const username = url.searchParams.get('username');
    
    // Validierung
    if (!username) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Username erforderlich'
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Dekodiere Emoji (URL-encoded)
    const decodedEmoji = decodeURIComponent(emoji);
    
    // Lösche Reaktion
    const result = await env.DB.prepare(`
      DELETE FROM chat_reactions 
      WHERE message_id = ? AND username = ? AND emoji = ?
    `).bind(messageId, username, decodedEmoji).run();
    
    if (result.meta.changes === 0) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Reaktion nicht gefunden'
      }), { status: 404, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Hole aktualisierte Reaktions-Counts
    const counts = await getReactionCounts(env, messageId);
    
    return new Response(JSON.stringify({
      success: true,
      message: 'Reaktion entfernt',
      counts: counts
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Remove Reaction Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * GET /chat/messages/:messageId/reactions
 * Hole alle Reaktionen für eine Nachricht
 */
export async function getReactions(request, env) {
  try {
    const { messageId } = request.params;
    
    // Hole alle Reaktionen mit Count
    const reactions = await env.DB.prepare(`
      SELECT 
        emoji,
        COUNT(*) as count,
        GROUP_CONCAT(username) as usernames
      FROM chat_reactions
      WHERE message_id = ?
      GROUP BY emoji
      ORDER BY count DESC
    `).bind(messageId).all();
    
    // Formatiere Ergebnis
    const formattedReactions = reactions.results.map(r => ({
      emoji: r.emoji,
      count: r.count,
      usernames: r.usernames ? r.usernames.split(',') : []
    }));
    
    return new Response(JSON.stringify({
      success: true,
      messageId: messageId,
      reactions: formattedReactions,
      totalReactions: formattedReactions.reduce((sum, r) => sum + r.count, 0)
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get Reactions Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * GET /chat/messages/:messageId/reactions/user/:username
 * Hole Reaktionen eines bestimmten Users
 */
export async function getUserReactions(request, env) {
  try {
    const { messageId, username } = request.params;
    
    const reactions = await env.DB.prepare(`
      SELECT emoji, created_at
      FROM chat_reactions
      WHERE message_id = ? AND username = ?
      ORDER BY created_at DESC
    `).bind(messageId, username).all();
    
    return new Response(JSON.stringify({
      success: true,
      messageId: messageId,
      username: username,
      reactions: reactions.results
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Get User Reactions Error:', error);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// ===========================
// HELPER FUNCTIONS
// ===========================

/**
 * Hole Reaktions-Counts für eine Nachricht
 */
async function getReactionCounts(env, messageId) {
  const counts = await env.DB.prepare(`
    SELECT emoji, COUNT(*) as count
    FROM chat_reactions
    WHERE message_id = ?
    GROUP BY emoji
  `).bind(messageId).all();
  
  return counts.results.reduce((acc, row) => {
    acc[row.emoji] = row.count;
    return acc;
  }, {});
}

// ===========================
// DATABASE SCHEMA
// ===========================

/**
 * D1 SQL Schema für Chat Reactions
 * 
 * Führe aus in Cloudflare Dashboard:
 */

/*
CREATE TABLE IF NOT EXISTS chat_reactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id TEXT NOT NULL,
  emoji TEXT NOT NULL,
  username TEXT NOT NULL,
  created_at TEXT NOT NULL,
  
  -- Verhindere Duplikate (User kann nur einmal mit gleichem Emoji reagieren)
  UNIQUE(message_id, username, emoji),
  
  -- Foreign Key zu chat_messages
  FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
  
  -- Indizes für Performance
  INDEX idx_message_id (message_id),
  INDEX idx_username (username),
  INDEX idx_emoji (emoji),
  INDEX idx_created_at (created_at)
);

-- Trigger: Lösche Reaktionen wenn Nachricht gelöscht wird
CREATE TRIGGER IF NOT EXISTS delete_reactions_on_message_delete
AFTER DELETE ON chat_messages
FOR EACH ROW
BEGIN
  DELETE FROM chat_reactions WHERE message_id = OLD.id;
END;
*/

// ===========================
// ROUTER INTEGRATION
// ===========================

/**
 * Füge zu routes.js hinzu:
 * 
 * import { 
 *   addReaction, 
 *   removeReaction, 
 *   getReactions, 
 *   getUserReactions 
 * } from './chat-reactions.js';
 * 
 * router.post('/chat/messages/:messageId/reactions', addReaction);
 * router.delete('/chat/messages/:messageId/reactions/:emoji', removeReaction);
 * router.get('/chat/messages/:messageId/reactions', getReactions);
 * router.get('/chat/messages/:messageId/reactions/user/:username', getUserReactions);
 */

// ===========================
// FLUTTER INTEGRATION
// ===========================

/**
 * CloudflareApiService erweitern in Flutter:
 */

/*
// Reaktion hinzufügen
Future<void> addReaction(String messageId, String emoji, String username) async {
  final response = await http.post(
    Uri.parse('$baseUrl/chat/messages/$messageId/reactions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiToken',
    },
    body: json.encode({
      'emoji': emoji,
      'username': username,
    }),
  );
  
  if (response.statusCode != 201) {
    throw Exception('Failed to add reaction: ${response.statusCode}');
  }
}

// Reaktion entfernen
Future<void> removeReaction(String messageId, String emoji, String username) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/chat/messages/$messageId/reactions/${Uri.encodeComponent(emoji)}?username=$username'),
    headers: {
      'Authorization': 'Bearer $apiToken',
    },
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to remove reaction: ${response.statusCode}');
  }
}

// Reaktionen laden
Future<Map<String, dynamic>> getReactions(String messageId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/chat/messages/$messageId/reactions'),
    headers: {
      'Authorization': 'Bearer $apiToken',
    },
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load reactions: ${response.statusCode}');
  }
}
*/

export default {
  addReaction,
  removeReaction,
  getReactions,
  getUserReactions
};
