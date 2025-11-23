# 📊 Weltenbibliothek - Monitoring & Observability Guide

## 🎯 Overview

Dieses Dokument beschreibt das Monitoring-Setup für die Weltenbibliothek Cloudflare Workers API, inklusive Metriken, Alerting, Logging und Performance-Überwachung.

---

## 📈 1. Cloudflare Workers Analytics

### Zugriff auf Built-in Analytics

Cloudflare bietet automatische Analytics für alle Workers:

**Dashboard-Zugriff:**
```
1. Gehe zu: https://dash.cloudflare.com
2. Wähle dein Konto → Workers & Pages
3. Wähle "weltenbibliothek-api" (oder dein Worker Name)
4. Klicke auf "Analytics" Tab
```

**Verfügbare Metriken:**
- **Requests per Second** - Aktuelle Last und Traffic-Muster
- **Status Codes** - 2xx (Success), 4xx (Client Errors), 5xx (Server Errors)
- **CPU Time** - Execution time per request
- **Errors** - Uncaught exceptions and errors
- **Duration** - Response time percentiles (p50, p95, p99)

---

## 🔍 2. Health Check Monitoring

### Health Endpoint

Die API bietet einen Health Check Endpoint für kontinuierliche Überwachung:

**Endpoint:**
```
GET https://your-worker.workers.dev/health
GET https://your-worker.workers.dev/api/health
```

**Beispiel Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-11-23T13:45:00.000Z",
  "version": "2.0.0",
  "checks": {
    "api": {
      "status": "ok"
    },
    "database": {
      "status": "ok",
      "message": "D1 Database connected"
    },
    "kv": {
      "status": "ok",
      "message": "KV Namespace accessible"
    }
  }
}
```

**Status Codes:**
- `200` - Healthy (all systems operational)
- `503` - Degraded or Unhealthy (one or more components failing)

### Automated Health Checks

**Mit curl (Linux/macOS):**
```bash
#!/bin/bash
# health_check_monitor.sh

API_URL="https://your-worker.workers.dev/health"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

while true; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
  
  if [ "$HTTP_CODE" != "200" ]; then
    # Send alert to Slack
    curl -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"⚠️ API Health Check Failed! Status: $HTTP_CODE\"}"
  fi
  
  sleep 300  # Check every 5 minutes
done
```

**Mit UptimeRobot (External Monitoring):**
1. Gehe zu: https://uptimerobot.com (kostenlos für 50 Monitors)
2. Erstelle neuen Monitor: "HTTP(s)"
3. URL: `https://your-worker.workers.dev/health`
4. Monitoring Interval: 5 Minuten
5. Alert Kontakte: Email/SMS/Slack

**Mit Better Uptime:**
1. Gehe zu: https://betteruptime.com
2. Erstelle neuen Monitor
3. Setze Expected Status Code: `200`
4. Setze Incident Escalation Policies

---

## 📊 3. Custom Metrics mit Cloudflare Analytics Engine

### Analytics Engine Setup

**Voraussetzungen:**
- Cloudflare Workers Paid Plan ($5/Monat)
- Analytics Engine Addon aktiviert

**Integration in Worker:**
```javascript
// In api_endpoints_extended.js hinzufügen

export default {
  async fetch(request, env, ctx) {
    const startTime = Date.now();
    const url = new URL(request.url);
    const path = url.pathname;
    
    try {
      // Handle request...
      const response = await handleRequest(request, env);
      
      // Log metrics to Analytics Engine
      const duration = Date.now() - startTime;
      ctx.waitUntil(
        env.ANALYTICS.writeDataPoint({
          indexes: [path, request.method],
          doubles: [duration, response.status],
          blobs: [request.headers.get('User-Agent') || 'unknown']
        })
      );
      
      return response;
      
    } catch (error) {
      // Log errors
      ctx.waitUntil(
        env.ANALYTICS.writeDataPoint({
          indexes: ['error', path],
          doubles: [Date.now() - startTime, 500],
          blobs: [error.message]
        })
      );
      
      throw error;
    }
  }
};
```

**Query Analytics Data:**
```bash
# Install Cloudflare API client
npm install -g @cloudflare/wrangler

# Query metrics for last 24 hours
curl -X POST "https://api.cloudflare.com/client/v4/accounts/{account_id}/analytics_engine/sql" \
  -H "Authorization: Bearer {api_token}" \
  -d "SELECT path, AVG(double1) as avg_duration, COUNT(*) as requests 
      FROM ANALYTICS_DATASET 
      WHERE timestamp > NOW() - INTERVAL '24' HOUR 
      GROUP BY path 
      ORDER BY requests DESC"
```

---

## 🚨 4. Error Tracking mit Sentry

### Sentry Integration

**Setup:**
```bash
npm install @sentry/cloudflare
```

**Worker Integration:**
```javascript
// In api_endpoints_extended.js

import * as Sentry from '@sentry/cloudflare';

export default {
  async fetch(request, env, ctx) {
    // Initialize Sentry
    Sentry.init({
      dsn: env.SENTRY_DSN,
      environment: env.ENVIRONMENT || 'production',
      tracesSampleRate: 0.1,
    });
    
    try {
      return await handleRequest(request, env);
    } catch (error) {
      // Log to Sentry
      Sentry.captureException(error, {
        tags: {
          path: new URL(request.url).pathname,
          method: request.method,
        },
        user: {
          id: request.headers.get('X-User-ID') || 'anonymous',
        },
      });
      
      return jsonResponse({ error: 'Internal Server Error' }, 500);
    }
  }
};
```

**Sentry Dashboard:**
- Issues tracking mit Stack Traces
- Performance Monitoring
- Release Tracking
- User Feedback Integration

---

## 📝 5. Structured Logging

### Logpush Setup (Enterprise Feature)

**Für Enterprise Kunden:**
```bash
# Configure Logpush to S3/GCS/R2
wrangler tail --format json | \
  jq -c '{timestamp, outcome, logs}' | \
  aws s3 cp - s3://your-logs-bucket/$(date +%Y%m%d).json
```

### Development Logging

**Console Logging Best Practices:**
```javascript
// Structured logging helper
function logEvent(level, message, metadata = {}) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level: level,
    message: message,
    ...metadata,
  };
  
  console.log(JSON.stringify(logEntry));
}

// Usage
logEvent('info', 'Push notification sent', {
  userId: 'user_123',
  topic: 'new_events',
  success: true,
});

logEvent('error', 'Database query failed', {
  query: 'SELECT * FROM push_subscriptions',
  error: error.message,
  duration: 1234,
});
```

**Tail Logs in Real-Time:**
```bash
# Stream logs from production worker
wrangler tail weltenbibliothek-api --env production

# Filter for errors only
wrangler tail weltenbibliothek-api --env production --status error

# Format as JSON
wrangler tail weltenbibliothek-api --format json
```

---

## 📊 6. Performance Monitoring

### Key Performance Indicators (KPIs)

**Response Time Targets:**
- **P50 (Median):** < 100ms
- **P95:** < 500ms
- **P99:** < 1000ms

**Error Rate Targets:**
- **4xx Errors:** < 5% of total requests
- **5xx Errors:** < 0.1% of total requests

**Availability Target:**
- **Uptime:** 99.95% (SLA)

### Performance Optimization Checklist

**Database Queries:**
```javascript
// ✅ Good: Use prepared statements with indexes
await env.DATABASE.prepare(
  'SELECT * FROM push_subscriptions WHERE user_id = ? AND is_active = 1'
).bind(userId).all();

// ❌ Bad: Full table scan without indexes
await env.DATABASE.prepare(
  'SELECT * FROM push_subscriptions WHERE LOWER(endpoint) LIKE ?'
).bind('%example%').all();
```

**KV Caching:**
```javascript
// ✅ Good: Cache frequently accessed data
async function getPlaylist(playlistId, env) {
  // Try cache first
  const cached = await env.PLAYLISTS_KV.get(playlistId, { type: 'json' });
  if (cached) return cached;
  
  // Fetch from database
  const playlist = await fetchPlaylistFromDB(playlistId, env);
  
  // Cache for 1 hour
  await env.PLAYLISTS_KV.put(playlistId, JSON.stringify(playlist), {
    expirationTtl: 3600
  });
  
  return playlist;
}
```

**Response Compression:**
```javascript
// Enable compression for large responses
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Content-Encoding': 'gzip',  // If data > 1KB
      'Cache-Control': 'public, max-age=300',
    },
  });
}
```

---

## 🔔 7. Alerting & Notifications

### Cloudflare Notifications Setup

**Dashboard Configuration:**
```
1. Gehe zu: Cloudflare Dashboard → Notifications
2. Erstelle neue Notification Policy
3. Wähle Event Types:
   - Worker exceeded CPU limit
   - Worker threw exception
   - Worker script failed to deploy
4. Wähle Delivery Method:
   - Email
   - PagerDuty
   - Webhooks (Slack/Discord)
```

**Beispiel Slack Webhook:**
```javascript
// In Worker: Send alerts to Slack
async function sendSlackAlert(message, env) {
  const webhook = env.SLACK_WEBHOOK_URL;
  
  await fetch(webhook, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      text: `🚨 Weltenbibliothek Alert`,
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: message,
          },
        },
      ],
    }),
  });
}

// Usage
if (errorRate > 0.05) {
  await sendSlackAlert('⚠️ Error rate exceeded 5% threshold!', env);
}
```

---

## 📦 8. Monitoring Tools Comparison

| Tool | Type | Pricing | Best For |
|------|------|---------|----------|
| **Cloudflare Analytics** | Built-in | Free | Basic metrics, status codes |
| **UptimeRobot** | External | Free (50 monitors) | Uptime monitoring |
| **Better Uptime** | External | $20/mo | Status pages, incident management |
| **Sentry** | APM | $26/mo | Error tracking, stack traces |
| **Datadog** | APM | $15/host/mo | Advanced monitoring, dashboards |
| **Grafana Cloud** | Observability | Free tier | Custom dashboards, metrics |
| **LogDNA** | Logging | $30/mo | Log aggregation, search |

---

## 🛠️ 9. Monitoring Setup Checklist

### Initial Setup (Required)

- [ ] Health Check Endpoint implementiert
- [ ] Cloudflare Analytics Dashboard gecheckt
- [ ] UptimeRobot Monitor erstellt
- [ ] Error Logging in Worker implementiert
- [ ] Structured Logging Format verwendet

### Advanced Setup (Recommended)

- [ ] Sentry Integration für Error Tracking
- [ ] Custom Metrics mit Analytics Engine
- [ ] Slack/Discord Webhooks für Alerts
- [ ] Performance Budgets definiert
- [ ] Incident Response Playbook erstellt

### Production Readiness (Critical)

- [ ] On-call Rotation Plan
- [ ] Backup & Recovery Prozeduren
- [ ] Rollback Strategy dokumentiert
- [ ] Load Testing durchgeführt
- [ ] Security Audit abgeschlossen

---

## 📞 10. Incident Response

### Severity Levels

**P0 - Critical:**
- API komplett down (> 50% error rate)
- Datenverlust oder Security Breach
- Response: Sofortiges Eingreifen, alle Stakeholder benachrichtigen

**P1 - High:**
- Teilausfall einer Funktion (Push Notifications down)
- Performance-Degradation (Response Zeit > 5s)
- Response: Innerhalb 1 Stunde, Team Lead benachrichtigen

**P2 - Medium:**
- Einzelne Features betroffen
- Error Rate 1-5%
- Response: Innerhalb 4 Stunden, normal priorisieren

**P3 - Low:**
- Kosmetische Issues
- Performance unter Target aber akzeptabel
- Response: Nächster Sprint

### Incident Response Workflow

```
1. DETECT:
   - Alert empfangen (UptimeRobot, Sentry, Health Check)
   - Severity bestimmen

2. ASSESS:
   - wrangler tail logs checken
   - Cloudflare Analytics Dashboard
   - Health Check Details

3. MITIGATE:
   - Rollback zu letzter funktionierender Version:
     wrangler rollback weltenbibliothek-api --env production
   - Traffic Routing anpassen (falls multi-region)

4. FIX:
   - Root Cause Analysis
   - Fix implementieren und testen
   - Deploy mit Extra-Monitoring

5. DOCUMENT:
   - Post-Mortem erstellen
   - Lessons Learned teilen
   - Monitoring verbessern
```

---

## 🚀 Quick Start Commands

```bash
# Check Worker Status
wrangler deployments list --name weltenbibliothek-api

# Stream Logs
wrangler tail weltenbibliothek-api --env production

# Test Health Endpoint
curl https://your-worker.workers.dev/health | jq

# Check Database Status
wrangler d1 execute weltenbibliothek_db_production \
  --command="SELECT COUNT(*) FROM push_subscriptions"

# Performance Test
ab -n 1000 -c 10 https://your-worker.workers.dev/api/analytics/summary

# Deploy New Version
wrangler deploy --env production
```

---

## 📚 Resources

**Official Docs:**
- [Cloudflare Workers Metrics](https://developers.cloudflare.com/workers/observability/metrics-and-analytics/)
- [Cloudflare Analytics Engine](https://developers.cloudflare.com/analytics/analytics-engine/)
- [Wrangler Tail](https://developers.cloudflare.com/workers/wrangler/commands/#tail)

**Third-Party Tools:**
- [UptimeRobot](https://uptimerobot.com)
- [Sentry for Cloudflare Workers](https://docs.sentry.io/platforms/javascript/guides/cloudflare-workers/)
- [Better Uptime](https://betteruptime.com)

**Dashboards:**
- [Cloudflare Dashboard](https://dash.cloudflare.com)
- [Grafana Cloud](https://grafana.com/products/cloud/)

---

## ✅ Next Steps

1. Implementiere Health Check Monitoring (UptimeRobot)
2. Richte Slack/Discord Alerts ein
3. Definiere Performance Budgets
4. Erstelle Incident Response Playbook
5. Führe Load Testing durch

**Monitoring ist ein kontinuierlicher Prozess. Passe deine Alerts und Metriken basierend auf realen Daten an!** 📊

---

**Last Updated:** November 23, 2024  
**Version:** 2.0.0  
**Maintained by:** Weltenbibliothek Dev Team
