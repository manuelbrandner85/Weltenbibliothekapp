/**
 * ═══════════════════════════════════════════════════════════════
 * WELTENBIBLIOTHEK - ANALYTICS MODULE
 * ═══════════════════════════════════════════════════════════════
 * Basic Analytics System for tracking user engagement and system health
 * 
 * Features:
 * - Event tracking (Livestreams, Chat, User Actions)
 * - WebRTC quality metrics
 * - User engagement statistics
 * - System health monitoring
 * - D1 Database storage for persistence
 * ═══════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════
// ANALYTICS EVENT TYPES
// ═══════════════════════════════════════════════════════════════

const ANALYTICS_EVENTS = {
  // User Events
  USER_LOGIN: 'user_login',
  USER_REGISTER: 'user_register',
  USER_LOGOUT: 'user_logout',
  
  // Livestream Events
  STREAM_STARTED: 'stream_started',
  STREAM_ENDED: 'stream_ended',
  STREAM_JOINED: 'stream_joined',
  STREAM_LEFT: 'stream_left',
  
  // Chat Events
  MESSAGE_SENT: 'message_sent',
  MESSAGE_REACTION: 'message_reaction',
  DM_SENT: 'dm_sent',
  
  // Event Map Events
  EVENT_VIEWED: 'event_viewed',
  EVENT_FAVORITED: 'event_favorited',
  
  // WebRTC Quality
  WEBRTC_CONNECTION_SUCCESS: 'webrtc_connection_success',
  WEBRTC_CONNECTION_FAILED: 'webrtc_connection_failed',
  WEBRTC_QUALITY_POOR: 'webrtc_quality_poor',
};

// ═══════════════════════════════════════════════════════════════
// ANALYTICS TRACKING FUNCTIONS
// ═══════════════════════════════════════════════════════════════

/**
 * Track an analytics event
 * @param {Object} env - Cloudflare environment with D1 binding
 * @param {string} eventType - Type of event (from ANALYTICS_EVENTS)
 * @param {string} userId - User ID (optional for anonymous events)
 * @param {Object} metadata - Additional event data
 */
async function trackEvent(env, eventType, userId = null, metadata = {}) {
  try {
    const timestamp = new Date().toISOString();
    
    // Store in D1 database
    await env.DB.prepare(`
      INSERT INTO analytics_events 
      (event_type, user_id, metadata, timestamp)
      VALUES (?, ?, ?, ?)
    `).bind(
      eventType,
      userId,
      JSON.stringify(metadata),
      timestamp
    ).run();
    
    console.log(`📊 Analytics: ${eventType} tracked for user ${userId || 'anonymous'}`);
    return true;
  } catch (error) {
    console.error('❌ Analytics tracking error:', error);
    return false;
  }
}

/**
 * Get analytics summary for a time period
 * @param {Object} env - Cloudflare environment
 * @param {string} startDate - ISO date string
 * @param {string} endDate - ISO date string
 */
async function getAnalyticsSummary(env, startDate, endDate) {
  try {
    // Total events
    const totalEvents = await env.DB.prepare(`
      SELECT COUNT(*) as count
      FROM analytics_events
      WHERE timestamp BETWEEN ? AND ?
    `).bind(startDate, endDate).first();
    
    // Events by type
    const eventsByType = await env.DB.prepare(`
      SELECT event_type, COUNT(*) as count
      FROM analytics_events
      WHERE timestamp BETWEEN ? AND ?
      GROUP BY event_type
      ORDER BY count DESC
    `).bind(startDate, endDate).all();
    
    // Active users
    const activeUsers = await env.DB.prepare(`
      SELECT COUNT(DISTINCT user_id) as count
      FROM analytics_events
      WHERE timestamp BETWEEN ? AND ?
      AND user_id IS NOT NULL
    `).bind(startDate, endDate).first();
    
    // Livestream statistics
    const streamStats = await env.DB.prepare(`
      SELECT 
        SUM(CASE WHEN event_type = 'stream_started' THEN 1 ELSE 0 END) as streams_started,
        SUM(CASE WHEN event_type = 'stream_joined' THEN 1 ELSE 0 END) as stream_joins,
        AVG(CASE WHEN event_type = 'stream_joined' THEN 
          CAST(JSON_EXTRACT(metadata, '$.duration') AS INTEGER) ELSE NULL END) as avg_watch_time
      FROM analytics_events
      WHERE timestamp BETWEEN ? AND ?
      AND event_type IN ('stream_started', 'stream_joined', 'stream_ended')
    `).bind(startDate, endDate).first();
    
    // Chat activity
    const chatStats = await env.DB.prepare(`
      SELECT 
        SUM(CASE WHEN event_type = 'message_sent' THEN 1 ELSE 0 END) as messages_sent,
        SUM(CASE WHEN event_type = 'message_reaction' THEN 1 ELSE 0 END) as reactions,
        SUM(CASE WHEN event_type = 'dm_sent' THEN 1 ELSE 0 END) as dms_sent
      FROM analytics_events
      WHERE timestamp BETWEEN ? AND ?
    `).bind(startDate, endDate).first();
    
    return {
      summary: {
        totalEvents: totalEvents.count,
        activeUsers: activeUsers.count,
        timeRange: { start: startDate, end: endDate }
      },
      eventsByType: eventsByType.results,
      livestreams: {
        streamsStarted: streamStats.streams_started || 0,
        totalJoins: streamStats.stream_joins || 0,
        avgWatchTime: streamStats.avg_watch_time || 0
      },
      chat: {
        messagesSent: chatStats.messages_sent || 0,
        reactions: chatStats.reactions || 0,
        dmsSent: chatStats.dms_sent || 0
      }
    };
  } catch (error) {
    console.error('❌ Analytics summary error:', error);
    throw error;
  }
}

/**
 * Get WebRTC quality metrics
 * @param {Object} env - Cloudflare environment
 * @param {string} timeRange - Time range ('24h', '7d', '30d')
 */
async function getWebRTCMetrics(env, timeRange = '24h') {
  const hours = timeRange === '24h' ? 24 : timeRange === '7d' ? 168 : 720;
  const startDate = new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();
  const endDate = new Date().toISOString();
  
  try {
    const metrics = await env.DB.prepare(`
      SELECT 
        SUM(CASE WHEN event_type = 'webrtc_connection_success' THEN 1 ELSE 0 END) as successful,
        SUM(CASE WHEN event_type = 'webrtc_connection_failed' THEN 1 ELSE 0 END) as failed,
        SUM(CASE WHEN event_type = 'webrtc_quality_poor' THEN 1 ELSE 0 END) as quality_issues,
        AVG(CASE WHEN event_type = 'webrtc_connection_success' THEN 
          CAST(JSON_EXTRACT(metadata, '$.rtt') AS REAL) ELSE NULL END) as avg_rtt,
        AVG(CASE WHEN event_type = 'webrtc_connection_success' THEN 
          CAST(JSON_EXTRACT(metadata, '$.packetLoss') AS REAL) ELSE NULL END) as avg_packet_loss
      FROM analytics_events
      WHERE timestamp BETWEEN ? AND ?
      AND event_type LIKE 'webrtc%'
    `).bind(startDate, endDate).first();
    
    const successRate = metrics.successful / (metrics.successful + metrics.failed) * 100;
    
    return {
      connections: {
        successful: metrics.successful || 0,
        failed: metrics.failed || 0,
        successRate: successRate.toFixed(2) + '%'
      },
      quality: {
        issues: metrics.quality_issues || 0,
        avgRTT: metrics.avg_rtt?.toFixed(2) || 0,
        avgPacketLoss: metrics.avg_packet_loss?.toFixed(2) || 0
      },
      timeRange: { start: startDate, end: endDate }
    };
  } catch (error) {
    console.error('❌ WebRTC metrics error:', error);
    throw error;
  }
}

/**
 * Get user engagement metrics
 * @param {Object} env - Cloudflare environment
 * @param {string} userId - User ID
 */
async function getUserEngagement(env, userId) {
  try {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const now = new Date().toISOString();
    
    const engagement = await env.DB.prepare(`
      SELECT 
        COUNT(*) as total_events,
        SUM(CASE WHEN event_type = 'stream_joined' THEN 1 ELSE 0 END) as streams_watched,
        SUM(CASE WHEN event_type = 'message_sent' THEN 1 ELSE 0 END) as messages_sent,
        SUM(CASE WHEN event_type = 'event_viewed' THEN 1 ELSE 0 END) as events_viewed,
        MIN(timestamp) as first_activity,
        MAX(timestamp) as last_activity
      FROM analytics_events
      WHERE user_id = ?
      AND timestamp BETWEEN ? AND ?
    `).bind(userId, thirtyDaysAgo, now).first();
    
    return {
      userId,
      last30Days: {
        totalEvents: engagement.total_events || 0,
        streamsWatched: engagement.streams_watched || 0,
        messagesSent: engagement.messages_sent || 0,
        eventsViewed: engagement.events_viewed || 0,
        firstActivity: engagement.first_activity,
        lastActivity: engagement.last_activity
      }
    };
  } catch (error) {
    console.error('❌ User engagement error:', error);
    throw error;
  }
}

// ═══════════════════════════════════════════════════════════════
// DATABASE SCHEMA - Run this to create analytics table
// ═══════════════════════════════════════════════════════════════

const ANALYTICS_SCHEMA = `
CREATE TABLE IF NOT EXISTS analytics_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type TEXT NOT NULL,
  user_id TEXT,
  metadata TEXT,
  timestamp TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON analytics_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON analytics_events(user_id);
`;

// ═══════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════

export {
  ANALYTICS_EVENTS,
  trackEvent,
  getAnalyticsSummary,
  getWebRTCMetrics,
  getUserEngagement,
  ANALYTICS_SCHEMA
};
