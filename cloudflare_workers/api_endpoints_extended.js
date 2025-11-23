/**
 * 🚀 Weltenbibliothek - Extended API Endpoints
 * 
 * Cloudflare Worker für Push Notifications, Musik-Playlists und Admin Analytics
 * 
 * Voraussetzungen:
 * - KV Namespace: PLAYLISTS_KV (für Musik-Playlists)
 * - D1 Database: DATABASE (für Push Subscriptions & Analytics)
 * - Web Push VAPID Keys (für Push Notifications)
 */

// ============================================================================
// 🔔 PUSH NOTIFICATIONS API
// ============================================================================

/**
 * Subscribe zu Push Notifications
 * POST /api/push/subscribe
 */
async function handlePushSubscribe(request, env) {
  try {
    const body = await request.json();
    const { user_id, topics, platform } = body;
    
    if (!user_id) {
      return jsonResponse({ error: 'user_id is required' }, 400);
    }
    
    const subscription_id = `sub_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // Speichere Subscription in D1
    await env.DATABASE.prepare(`
      INSERT INTO push_subscriptions (
        subscription_id, user_id, topics, platform, created_at, is_active
      ) VALUES (?, ?, ?, ?, datetime('now'), 1)
    `).bind(
      subscription_id,
      user_id,
      JSON.stringify(topics || []),
      platform || 'web'
    ).run();
    
    return jsonResponse({
      success: true,
      subscription_id,
      topics: topics || [],
    }, 201);
    
  } catch (error) {
    console.error('Error in handlePushSubscribe:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Unsubscribe von Push Notifications
 * DELETE /api/push/unsubscribe
 */
async function handlePushUnsubscribe(request, env) {
  try {
    const body = await request.json();
    const { subscription_id } = body;
    
    if (!subscription_id) {
      return jsonResponse({ error: 'subscription_id is required' }, 400);
    }
    
    // Deaktiviere Subscription
    await env.DATABASE.prepare(`
      UPDATE push_subscriptions 
      SET is_active = 0, updated_at = datetime('now')
      WHERE subscription_id = ?
    `).bind(subscription_id).run();
    
    return jsonResponse({ success: true });
    
  } catch (error) {
    console.error('Error in handlePushUnsubscribe:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Subscribe zu Topic
 * POST /api/push/topics/subscribe
 */
async function handleTopicSubscribe(request, env) {
  try {
    const body = await request.json();
    const { subscription_id, topic } = body;
    
    if (!subscription_id || !topic) {
      return jsonResponse({ error: 'subscription_id and topic are required' }, 400);
    }
    
    // Hole aktuelle Topics
    const result = await env.DATABASE.prepare(`
      SELECT topics FROM push_subscriptions WHERE subscription_id = ?
    `).bind(subscription_id).first();
    
    if (!result) {
      return jsonResponse({ error: 'Subscription not found' }, 404);
    }
    
    const topics = JSON.parse(result.topics || '[]');
    if (!topics.includes(topic)) {
      topics.push(topic);
    }
    
    // Update Topics
    await env.DATABASE.prepare(`
      UPDATE push_subscriptions 
      SET topics = ?, updated_at = datetime('now')
      WHERE subscription_id = ?
    `).bind(JSON.stringify(topics), subscription_id).run();
    
    return jsonResponse({ success: true, topics });
    
  } catch (error) {
    console.error('Error in handleTopicSubscribe:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Hole Subscription Settings
 * GET /api/push/subscription/:id
 */
async function handleGetSubscription(request, env, subscriptionId) {
  try {
    const result = await env.DATABASE.prepare(`
      SELECT subscription_id, user_id, topics, platform, created_at, is_active
      FROM push_subscriptions 
      WHERE subscription_id = ?
    `).bind(subscriptionId).first();
    
    if (!result) {
      return jsonResponse({ error: 'Subscription not found' }, 404);
    }
    
    return jsonResponse({
      subscription_id: result.subscription_id,
      user_id: result.user_id,
      topics: JSON.parse(result.topics || '[]'),
      platform: result.platform,
      created_at: result.created_at,
      is_active: result.is_active === 1,
    });
    
  } catch (error) {
    console.error('Error in handleGetSubscription:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Sende Test-Notification
 * POST /api/push/test
 */
async function handleSendTestNotification(request, env) {
  try {
    const body = await request.json();
    const { subscription_id, title, body: notifBody, icon } = body;
    
    // In einer echten Implementierung würde hier die Web Push API verwendet
    // Für Demo-Zwecke simulieren wir den Erfolg
    
    console.log('Test Notification:', {
      subscription_id,
      title,
      body: notifBody,
      icon,
    });
    
    return jsonResponse({
      success: true,
      message: 'Test notification sent (simulated)',
    });
    
  } catch (error) {
    console.error('Error in handleSendTestNotification:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

// ============================================================================
// 🎵 MUSIK-PLAYLISTS API (Cloudflare KV)
// ============================================================================

/**
 * Hole alle Playlists eines Users
 * GET /api/playlists
 */
async function handleGetPlaylists(request, env) {
  try {
    const userId = request.headers.get('X-User-ID');
    
    if (!userId) {
      return jsonResponse({ error: 'X-User-ID header is required' }, 400);
    }
    
    // Liste alle Playlists des Users aus KV
    const listResult = await env.PLAYLISTS_KV.list({ prefix: `playlist_${userId}_` });
    
    const playlists = [];
    for (const key of listResult.keys) {
      const playlistData = await env.PLAYLISTS_KV.get(key.name, 'json');
      if (playlistData) {
        playlists.push(playlistData);
      }
    }
    
    // Sortiere nach Update-Zeit
    playlists.sort((a, b) => new Date(b.updated_at) - new Date(a.updated_at));
    
    return jsonResponse(playlists);
    
  } catch (error) {
    console.error('Error in handleGetPlaylists:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Speichere/Update Playlist
 * POST /api/playlists/:id
 */
async function handleSavePlaylist(request, env, playlistId) {
  try {
    const userId = request.headers.get('X-User-ID');
    const body = await request.json();
    
    if (!userId) {
      return jsonResponse({ error: 'X-User-ID header is required' }, 400);
    }
    
    // Speichere in KV
    const key = `playlist_${userId}_${playlistId}`;
    await env.PLAYLISTS_KV.put(key, JSON.stringify(body));
    
    return jsonResponse({
      success: true,
      playlist_id: playlistId,
    });
    
  } catch (error) {
    console.error('Error in handleSavePlaylist:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Lösche Playlist
 * DELETE /api/playlists/:id
 */
async function handleDeletePlaylist(request, env, playlistId) {
  try {
    const userId = request.headers.get('X-User-ID');
    
    if (!userId) {
      return jsonResponse({ error: 'X-User-ID header is required' }, 400);
    }
    
    const key = `playlist_${userId}_${playlistId}`;
    await env.PLAYLISTS_KV.delete(key);
    
    return jsonResponse({ success: true });
    
  } catch (error) {
    console.error('Error in handleDeletePlaylist:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

// ============================================================================
// 📊 ADMIN ANALYTICS API (erweitert)
// ============================================================================

/**
 * Hole Analytics Summary
 * GET /api/analytics/summary?timeRange=7d
 */
async function handleAnalyticsSummary(request, env) {
  try {
    const url = new URL(request.url);
    const timeRange = url.searchParams.get('timeRange') || '7d';
    
    // Berechne Zeitfilter
    const timeFilter = getTimeFilter(timeRange);
    
    // Hole verschiedene Metriken
    const totalUsers = await env.DATABASE.prepare(`
      SELECT COUNT(DISTINCT user_id) as count 
      FROM user_activity_log 
      WHERE ${timeFilter}
    `).first();
    
    const totalEvents = await env.DATABASE.prepare(`
      SELECT COUNT(*) as count 
      FROM analytics_events 
      WHERE ${timeFilter}
    `).first();
    
    const totalStreams = await env.DATABASE.prepare(`
      SELECT COUNT(*) as count 
      FROM analytics_events 
      WHERE event_type = 'stream_started' AND ${timeFilter}
    `).first();
    
    const totalMessages = await env.DATABASE.prepare(`
      SELECT COUNT(*) as count 
      FROM analytics_events 
      WHERE event_type = 'message_sent' AND ${timeFilter}
    `).first();
    
    return jsonResponse({
      time_range: timeRange,
      total_users: totalUsers?.count || 0,
      total_events: totalEvents?.count || 0,
      total_streams: totalStreams?.count || 0,
      total_messages: totalMessages?.count || 0,
      generated_at: new Date().toISOString(),
    });
    
  } catch (error) {
    console.error('Error in handleAnalyticsSummary:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Hole WebRTC Metriken
 * GET /api/analytics/webrtc?timeRange=7d
 */
async function handleWebRTCMetrics(request, env) {
  try {
    const url = new URL(request.url);
    const timeRange = url.searchParams.get('timeRange') || '7d';
    const timeFilter = getTimeFilter(timeRange);
    
    // Hole WebRTC Statistiken
    const metrics = await env.DATABASE.prepare(`
      SELECT 
        COUNT(*) as total_connections,
        SUM(CASE WHEN connection_successful = 1 THEN 1 ELSE 0 END) as successful,
        AVG(connection_quality) as avg_quality
      FROM stream_quality_metrics 
      WHERE ${timeFilter}
    `).first();
    
    const successRate = metrics?.total_connections > 0
      ? metrics.successful / metrics.total_connections
      : 0;
    
    return jsonResponse({
      time_range: timeRange,
      total_connections: metrics?.total_connections || 0,
      success_rate: successRate,
      avg_quality: metrics?.avg_quality || 0,
      generated_at: new Date().toISOString(),
    });
    
  } catch (error) {
    console.error('Error in handleWebRTCMetrics:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

/**
 * Hole User Engagement Daten
 * GET /api/analytics/engagement?timeRange=7d
 */
async function handleUserEngagement(request, env) {
  try {
    const url = new URL(request.url);
    const timeRange = url.searchParams.get('timeRange') || '7d';
    const timeFilter = getTimeFilter(timeRange);
    
    // Aktive User
    const activeUsers = await env.DATABASE.prepare(`
      SELECT COUNT(DISTINCT user_id) as count 
      FROM user_activity_log 
      WHERE ${timeFilter}
    `).first();
    
    // Durchschnittliche Session-Dauer
    const avgSession = await env.DATABASE.prepare(`
      SELECT AVG(session_duration) as avg_duration 
      FROM user_activity_log 
      WHERE ${timeFilter}
    `).first();
    
    // Top Events
    const topEvents = await env.DATABASE.prepare(`
      SELECT event_type as type, COUNT(*) as count 
      FROM analytics_events 
      WHERE ${timeFilter}
      GROUP BY event_type 
      ORDER BY count DESC 
      LIMIT 10
    `).all();
    
    return jsonResponse({
      time_range: timeRange,
      active_users: activeUsers?.count || 0,
      avg_session_duration: avgSession?.avg_duration || 0,
      top_events: topEvents?.results || [],
      generated_at: new Date().toISOString(),
    });
    
  } catch (error) {
    console.error('Error in handleUserEngagement:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getTimeFilter(timeRange) {
  switch (timeRange) {
    case '24h':
      return "timestamp >= datetime('now', '-1 day')";
    case '7d':
      return "timestamp >= datetime('now', '-7 days')";
    case '30d':
      return "timestamp >= datetime('now', '-30 days')";
    case 'all':
      return '1=1';
    default:
      return "timestamp >= datetime('now', '-7 days')";
  }
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-User-ID',
    },
  });
}

// ============================================================================
// 🏥 HEALTH CHECK & MONITORING
// ============================================================================

/**
 * Health Check Endpoint
 * GET /health oder /api/health
 * 
 * Überprüft:
 * - API Verfügbarkeit
 * - Datenbankverbindung (D1)
 * - KV Namespace Zugriff
 * - Systemversion
 */
async function handleHealthCheck(request, env) {
  try {
    const healthStatus = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '2.0.0',
      checks: {
        api: { status: 'ok' },
        database: { status: 'unknown' },
        kv: { status: 'unknown' },
      },
    };
    
    // Check D1 Database connectivity
    try {
      const dbTest = await env.DATABASE.prepare(
        'SELECT 1 as test'
      ).first();
      
      healthStatus.checks.database = {
        status: dbTest ? 'ok' : 'error',
        message: dbTest ? 'D1 Database connected' : 'D1 Database unreachable',
      };
    } catch (dbError) {
      healthStatus.checks.database = {
        status: 'error',
        message: `D1 Database error: ${dbError.message}`,
      };
      healthStatus.status = 'degraded';
    }
    
    // Check KV Namespace connectivity
    try {
      await env.PLAYLISTS_KV.put('_health_check', 'ok', { expirationTtl: 60 });
      const kvTest = await env.PLAYLISTS_KV.get('_health_check');
      
      healthStatus.checks.kv = {
        status: kvTest === 'ok' ? 'ok' : 'error',
        message: kvTest === 'ok' ? 'KV Namespace accessible' : 'KV Namespace error',
      };
    } catch (kvError) {
      healthStatus.checks.kv = {
        status: 'error',
        message: `KV Namespace error: ${kvError.message}`,
      };
      healthStatus.status = 'degraded';
    }
    
    // Determine overall HTTP status code
    const statusCode = healthStatus.status === 'healthy' ? 200 : 503;
    
    return jsonResponse(healthStatus, statusCode);
    
  } catch (error) {
    console.error('Health check error:', error);
    return jsonResponse({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
    }, 503);
  }
}

// ============================================================================
// MAIN ROUTER
// ============================================================================

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return jsonResponse(null, 204);
    }
    
    try {
      // Push Notifications Routes
      if (path === '/api/push/subscribe' && request.method === 'POST') {
        return handlePushSubscribe(request, env);
      }
      if (path === '/api/push/unsubscribe' && request.method === 'DELETE') {
        return handlePushUnsubscribe(request, env);
      }
      if (path === '/api/push/topics/subscribe' && request.method === 'POST') {
        return handleTopicSubscribe(request, env);
      }
      if (path.startsWith('/api/push/subscription/') && request.method === 'GET') {
        const subscriptionId = path.split('/').pop();
        return handleGetSubscription(request, env, subscriptionId);
      }
      if (path === '/api/push/test' && request.method === 'POST') {
        return handleSendTestNotification(request, env);
      }
      
      // Playlist Routes
      if (path === '/api/playlists' && request.method === 'GET') {
        return handleGetPlaylists(request, env);
      }
      if (path.startsWith('/api/playlists/') && request.method === 'POST') {
        const playlistId = path.split('/').pop();
        return handleSavePlaylist(request, env, playlistId);
      }
      if (path.startsWith('/api/playlists/') && request.method === 'DELETE') {
        const playlistId = path.split('/').pop();
        return handleDeletePlaylist(request, env, playlistId);
      }
      
      // Analytics Routes
      if (path === '/api/analytics/summary') {
        return handleAnalyticsSummary(request, env);
      }
      if (path === '/api/analytics/webrtc') {
        return handleWebRTCMetrics(request, env);
      }
      if (path === '/api/analytics/engagement') {
        return handleUserEngagement(request, env);
      }
      
      // Health Check Endpoint
      if (path === '/health' || path === '/api/health') {
        return handleHealthCheck(request, env);
      }
      
      // Default 404
      return jsonResponse({ error: 'Not Found' }, 404);
      
    } catch (error) {
      console.error('Router error:', error);
      return jsonResponse({ error: 'Internal Server Error' }, 500);
    }
  },
};
