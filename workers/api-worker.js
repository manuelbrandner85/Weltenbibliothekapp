/**
 * Weltenbibliothek API Worker
 * URL: https://weltenbibliothek-api.brandy13062.workers.dev
 *
 * Endpoints:
 *   GET  /                    → Health check
 *   POST /recherche            → KI-Recherche (proxied to OpenClaw)
 *   GET  /api/articles         → Artikel (proxied to Supabase)
 *   GET  /api/chat/messages    → Chat-Nachrichten (proxied to Supabase)
 *   POST /api/chat/messages    → Nachricht senden
 *   GET  /voice/rooms          → Voice-Räume
 *   GET  /api/tools/*          → Tool-Endpoints
 *   POST /errors/report        → Error-Reporting
 *   POST /api/media/upload     → Media-Upload (R2)
 */

const SUPABASE_URL = 'https://adtviduaftdquvfjpojb.supabase.co';
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
  'Content-Type': 'application/json',
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: CORS_HEADERS,
  });
}

function errorResponse(message, status = 500) {
  return jsonResponse({ error: message, status }, status);
}

async function proxyToSupabase(request, env, path, method, body) {
  const anonKey = env.SUPABASE_ANON_KEY || '';
  const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;
  
  const url = `${SUPABASE_URL}${path}`;
  const res = await fetch(url, {
    method: method || request.method,
    headers: {
      'Content-Type': 'application/json',
      'apikey': anonKey,
      'Authorization': authHeader,
      'Prefer': request.headers.get('Prefer') || '',
    },
    body: body ? JSON.stringify(body) : (method === 'GET' ? undefined : request.body),
  });
  
  const data = await res.json().catch(() => ({}));
  return jsonResponse(data, res.status);
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // ── Health Check ──────────────────────────────────────────
    if (path === '/' || path === '/health') {
      return jsonResponse({
        status: 'ok',
        service: 'Weltenbibliothek API Worker',
        version: '2.0.0',
        timestamp: new Date().toISOString(),
        endpoints: ['/recherche', '/api/articles', '/api/chat/messages', '/voice/rooms', '/api/tools/*'],
      });
    }

    // ── Recherche (KI-Suche) ──────────────────────────────────
    if (path === '/recherche' && method === 'POST') {
      try {
        const body = await request.json();
        const gatewayUrl = env.OPENCLAW_GATEWAY_URL || 'http://72.62.154.95:50074';
        
        const res = await fetch(`${gatewayUrl}/recherche`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        }).catch(() => null);

        if (!res || !res.ok) {
          // Fallback: Leeres Ergebnis zurückgeben, kein Absturz
          return jsonResponse({ results: [], query: body.query, error: 'Gateway nicht erreichbar' });
        }
        const data = await res.json();
        return jsonResponse(data);
      } catch (e) {
        return errorResponse(`Recherche-Fehler: ${e.message}`);
      }
    }

    // ── Artikel ───────────────────────────────────────────────
    if (path === '/api/articles') {
      const params = url.searchParams;
      let supaPath = '/rest/v1/articles?select=*&is_published=eq.true&order=created_at.desc';
      if (params.get('world')) supaPath += `&world=eq.${params.get('world')}`;
      if (params.get('realm')) supaPath += `&world=eq.${params.get('realm')}`;
      if (params.get('category')) supaPath += `&category=eq.${params.get('category')}`;
      if (params.get('limit')) supaPath += `&limit=${params.get('limit')}`;
      if (params.get('offset')) supaPath += `&offset=${params.get('offset')}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── Chat Nachrichten ──────────────────────────────────────
    if (path === '/api/chat/messages') {
      const roomId = url.searchParams.get('room') || url.searchParams.get('room_id');
      if (method === 'GET' && roomId) {
        const supaPath = `/rest/v1/chat_messages?select=*&room_id=eq.${roomId}&is_deleted=eq.false&order=created_at.desc&limit=50`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
      if (method === 'POST') {
        const body = await request.json();
        return proxyToSupabase(request, env, '/rest/v1/chat_messages', 'POST', body);
      }
    }

    // ── Chat Räume ────────────────────────────────────────────
    if (path === '/voice/rooms' || path === '/api/chat/rooms') {
      const world = url.searchParams.get('realm') || url.searchParams.get('world');
      let supaPath = '/rest/v1/chat_rooms?select=*&is_active=eq.true&order=name.asc';
      if (world) supaPath += `&world=eq.${world}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── Profil ────────────────────────────────────────────────
    if (path.startsWith('/api/profile/')) {
      const parts = path.split('/'); // /api/profile/{world}/{username}
      const username = parts[4];
      if (username) {
        const supaPath = `/rest/v1/profiles?select=id,username,display_name,avatar_url,bio,world&username=eq.${encodeURIComponent(username)}&limit=1`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
    }

    // ── Tool-Endpoints ────────────────────────────────────────
    if (path.startsWith('/api/tools/')) {
      const tool = path.replace('/api/tools/', '');
      return jsonResponse({
        tool,
        status: 'available',
        message: `Tool '${tool}' ist bereit. Daten werden aus Supabase geladen.`,
      });
    }

    // ── Error Reporting ───────────────────────────────────────
    if (path === '/errors/report' && method === 'POST') {
      // Fehler loggen und bestätigen (kein Absturz)
      try {
        const body = await request.json();
        console.error('[ERROR_REPORT]', JSON.stringify(body));
      } catch (_) {}
      return jsonResponse({ received: true });
    }

    // ── Media Upload (R2) ─────────────────────────────────────
    if (path === '/api/media/upload' && method === 'POST') {
      try {
        const formData = await request.formData();
        const file = formData.get('file');
        if (!file || !env.R2_BUCKET) {
          return errorResponse('Keine Datei oder kein R2-Bucket konfiguriert', 400);
        }
        const key = `media/${Date.now()}_${file.name}`;
        await env.R2_BUCKET.put(key, file.stream(), {
          httpMetadata: { contentType: file.type },
        });
        const publicUrl = `https://pub-${env.CF_ACCOUNT_ID}.r2.dev/${key}`;
        return jsonResponse({ url: publicUrl, key });
      } catch (e) {
        return errorResponse(`Upload-Fehler: ${e.message}`);
      }
    }

    // ── Wrapper / Short-URLs ──────────────────────────────────
    if (path.startsWith('/go/') || path.startsWith('/out')) {
      const target = url.searchParams.get('url') || path.replace('/go/', 'https://t.me/');
      return Response.redirect(target, 302);
    }

    // ── 404 ───────────────────────────────────────────────────
    return errorResponse(`Endpoint '${path}' nicht gefunden`, 404);
  },
};
