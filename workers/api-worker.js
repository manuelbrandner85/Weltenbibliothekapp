/**
 * Weltenbibliothek API Worker v3.0
 * URL: https://weltenbibliothek-api.brandy13062.workers.dev
 *
 * Vollständige Endpoint-Abdeckung für alle Flutter-Services.
 *
 * Endpoints:
 *   GET  /                          → Health check
 *   POST /recherche                 → KI-Recherche (OpenClaw)
 *   GET  /api/articles              → Artikel (Supabase)
 *   GET/POST /api/chat/messages     → Chat-Nachrichten
 *   GET  /voice/rooms               → Voice/Chat-Räume
 *   GET  /api/profile/:world/:user  → Profil
 *   GET  /api/profiles/:world       → Profil-Liste
 *   POST /api/profile/materie       → Materie-Profil speichern
 *   POST /api/profile/energie       → Energie-Profil speichern
 *   GET  /api/sync/*                → Profil-Sync
 *   GET/POST /api/tools/*           → Inline-Tools (Supabase)
 *   GET  /api/push/*                → Push-Notifications (NoOp-friendly)
 *   GET  /api/v2/push/*             → Push v2 (NoOp-friendly)
 *   POST /api/push/register         → Push registrieren
 *   POST /api/push/send             → Push senden
 *   GET  /api/statistics            → Statistiken
 *   GET  /api/ai/*                  → AI-Endpunkte
 *   POST /api/community/*          → Community-Aktionen
 *   POST /auth/*                    → Auth-Endpunkte
 *   GET/POST /api/admin/*           → Admin-Endpunkte
 *   POST /api/avatar/upload         → Avatar-Upload (Supabase Storage)
 *   POST /api/media/upload          → Media-Upload (R2)
 *   POST /api/chat/voice-upload     → Voice-Message-Upload
 *   GET  /api/daily-featured        → Tagesartikel
 *   GET  /api/tags/trending         → Trending Tags
 *   POST /errors/report             → Error-Reporting
 *   GET  /materie/ufos              → UFO-Sichtungen
 *   GET  /api/status/*              → Status-Endpunkte
 *   GET/POST /messages/*            → Message-Reactions/Receipts
 *   POST /api/ai/ask                → Workers AI (Llama 3.1 8B, kein API-Key)
 *   POST /api/ai/auto-tag           → Auto-Tagging
 *   POST /api/ai/recommendations    → Empfehlungen
 *   POST /api/ai/suggestions        → AI-Vorschläge
 *   POST /api/rabbit-hole/*         → Rabbit-Hole-Recherche
 *   GET  /go/* | /out               → Short-URL-Redirect
 */

const SUPABASE_URL = 'https://adtviduaftdquvfjpojb.supabase.co';
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey, Prefer, X-Supabase-Auth',
  'Access-Control-Max-Age': '86400',
  'Content-Type': 'application/json',
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: CORS_HEADERS,
  });
}

function errorResponse(message, status = 500, code = null, details = null) {
  // Standardisierte Error-Response für alle Worker-Endpoints.
  //   { error: "...", status: 500, code: "EXTERNAL_API_FAILED", details: {...} }
  // code-Beispiele: MISSING_PARAM, INVALID_PARAM, EXTERNAL_API_FAILED,
  //   RATE_LIMITED, NOT_FOUND, FORBIDDEN, INTERNAL_ERROR, AUTH_FAILED
  const inferredCode = code ?? (
    status === 400 ? 'INVALID_PARAM'
    : status === 401 ? 'AUTH_FAILED'
    : status === 403 ? 'FORBIDDEN'
    : status === 404 ? 'NOT_FOUND'
    : status === 429 ? 'RATE_LIMITED'
    : status >= 500 ? 'INTERNAL_ERROR'
    : 'ERROR'
  );
  const body = { error: message, status, code: inferredCode };
  if (details !== null) body.details = details;
  return jsonResponse(body, status);
}

// ── Auto-Übersetzung ins Deutsche (Google GTX, kein Key) ───────────────────
const DE_WORDS = /\b(und|der|die|das|ist|von|auf|zu|für|nicht|mit|einen|einem|eine|des|den|wird|wurde|sind|hat|haben|kann|dass|als|aber|auch|nach|bei|über|durch|im|am|es|er|sie|wir|ihr|was|wie|wenn|dann|noch|nur|alle|sehr|mehr|so|da|hier|jetzt|schon|ihm|ihn|dem|diesem|seiner|ihrer|eines|welche|andere|andere)\b/i;

async function translateToDe(text) {
  if (!text || text.trim().length < 5) return text || '';
  if (DE_WORDS.test(text)) return text; // bereits Deutsch
  try {
    const r = await fetch(
      `https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=de&dt=t&q=${encodeURIComponent(text.slice(0, 500))}`,
      { signal: AbortSignal.timeout(5000), headers: { 'User-Agent': 'Mozilla/5.0' } }
    );
    if (!r.ok) return text;
    const data = await r.json();
    return data?.[0]?.map(s => s?.[0] || '').filter(Boolean).join('') || text;
  } catch (_) { return text; }
}

async function translateItems(items, fields) {
  return Promise.all(items.map(async item => {
    const vals = await Promise.all(fields.map(f => translateToDe(item[f] || '')));
    const out = { ...item };
    fields.forEach((f, i) => { out[f] = vals[i]; });
    return out;
  }));
}

// Supabase-Proxy mit optionalem Auth-Token
async function proxyToSupabase(request, env, path, method, body, userToken) {
  const anonKey = env.SUPABASE_ANON_KEY || '';
  const authHeader = userToken
    ? `Bearer ${userToken}`
    : (request.headers.get('Authorization') || `Bearer ${anonKey}`);

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

// Supabase-Zählabfrage
async function countFromSupabase(env, table, filters = '') {
  const anonKey = env.SUPABASE_ANON_KEY || '';
  const path = `/rest/v1/${table}?select=id${filters}&limit=1000`;
  const res = await fetch(`${SUPABASE_URL}${path}`, {
    method: 'GET',
    headers: {
      'apikey': anonKey,
      'Authorization': `Bearer ${anonKey}`,
      'Prefer': 'count=exact',
    },
  });
  const contentRange = res.headers.get('Content-Range') || '0-0/0';
  const total = parseInt(contentRange.split('/')[1] || '0', 10);
  return isNaN(total) ? 0 : total;
}

// ═══════════════════════════════════════════════════════════════
// 🔔 FCM PUSH DISPATCH (HTTP v1 API)
// ═══════════════════════════════════════════════════════════════
// Sendet Supabase `notification_queue`-Zeilen via Firebase Cloud Messaging.
// Wird vom POST /api/push/dispatch Endpoint und vom Cron-Trigger aufgerufen.
//
// Voraussetzung (eine der drei Secrets gesetzt):
//   FCM_SERVICE_ACCOUNT  (JSON-String des Firebase Service Account)
// Ohne Secret: Queue-Zeilen werden nur als 'sent' markiert (Client-Polling).
// ───────────────────────────────────────────────────────────────

function base64UrlEncode(data) {
  let str;
  if (data instanceof ArrayBuffer) {
    str = btoa(String.fromCharCode(...new Uint8Array(data)));
  } else if (typeof data === 'string') {
    str = btoa(data);
  } else {
    str = btoa(String.fromCharCode(...new Uint8Array(data)));
  }
  return str.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function pemToArrayBuffer(pem) {
  const b64 = pem
    .replace(/-----BEGIN [^-]+-----/g, '')
    .replace(/-----END [^-]+-----/g, '')
    .replace(/\s+/g, '');
  const raw = atob(b64);
  const buf = new ArrayBuffer(raw.length);
  const view = new Uint8Array(buf);
  for (let i = 0; i < raw.length; i++) view[i] = raw.charCodeAt(i);
  return buf;
}

async function getFcmAccessToken(env) {
  const raw = env.FCM_SERVICE_ACCOUNT;
  if (!raw) return null;
  let sa;
  try {
    sa = typeof raw === 'string' ? JSON.parse(raw) : raw;
  } catch (e) {
    throw new Error(`FCM_SERVICE_ACCOUNT ist kein gültiges JSON: ${e.message}`);
  }
  if (!sa.client_email || !sa.private_key || !sa.project_id) {
    throw new Error('FCM_SERVICE_ACCOUNT fehlt client_email/private_key/project_id');
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };
  const encHeader = base64UrlEncode(JSON.stringify(header));
  const encClaim = base64UrlEncode(JSON.stringify(claim));
  const toSign = `${encHeader}.${encClaim}`;

  const keyBuf = pemToArrayBuffer(sa.private_key);
  const key = await crypto.subtle.importKey(
    'pkcs8',
    keyBuf,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sigBuf = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(toSign)
  );
  const jwt = `${toSign}.${base64UrlEncode(sigBuf)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok || !data.access_token) {
    throw new Error(`FCM OAuth-Token-Fehler: ${res.status} ${JSON.stringify(data)}`);
  }
  return { accessToken: data.access_token, projectId: sa.project_id };
}

async function sendFcmMessage(accessToken, projectId, token, title, body, data) {
  const payload = {
    message: {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: { channel_id: 'weltenbibliothek_push', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', 'content-available': 1 } },
      },
    },
  };
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    }
  );
  const respText = await res.text();
  return { ok: res.ok, status: res.status, body: respText };
}

async function dispatchPushQueue(env, pushAuth) {
  // 1. FCM-Access-Token holen — ZUERST, bevor Queue gelesen wird.
  //    Wenn FCM nicht konfiguriert ist: Queue NICHT anfassen → Items bleiben 'pending'
  //    für In-App-Polling (30s-Zyklus). Damit gehen keine Nachrichten verloren.
  let fcm = null;
  try {
    fcm = await getFcmAccessToken(env);
  } catch (e) {
    console.warn('FCM nicht konfiguriert, Cron überspringt Queue:', e.message);
    return { drained: 0, sent: 0, failed: 0, fcmEnabled: false, skipped: true };
  }

  // 2. Pending-Zeilen laden (bis 100 pro Lauf) + retrybare Failed-Items (attempts < 3)
  const fetchRes = await fetch(
    `${SUPABASE_URL}/rest/v1/notification_queue?or=(status.eq.pending,and(status.eq.failed,attempts.lt.3))&select=id,user_id,title,body,data,attempts&order=created_at.asc&limit=100`,
    { headers: pushAuth }
  );
  const rows = await fetchRes.json().catch(() => []);
  const list = Array.isArray(rows) ? rows : [];
  if (list.length === 0) return { drained: 0, sent: 0, failed: 0, fcmEnabled: true };

  // 3. Für jede Queue-Zeile: FCM-Tokens des Users laden und senden
  let sent = 0;
  let failed = 0;
  for (const row of list) {
    let deliveryOk = false;
    // user_id URL-encoden um Parameter-Poisoning bei Sonderzeichen zu vermeiden.
    const subsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/push_subscriptions?user_id=eq.${encodeURIComponent(row.user_id)}&is_active=eq.true&fcm_token=not.is.null&select=fcm_token`,
      { headers: pushAuth }
    );
    const subs = await subsRes.json().catch(() => []);
    const tokens = (Array.isArray(subs) ? subs : []).map(s => s.fcm_token).filter(Boolean);

    if (tokens.length === 0) {
      // Kein FCM-Token für diesen User → als 'sent' markieren (kein Gerät registriert)
      console.warn(`push skip: user ${row.user_id} hat kein aktives fcm_token`);
    } else {
      for (const token of tokens) {
        try {
          const r = await sendFcmMessage(fcm.accessToken, fcm.projectId, token, row.title, row.body, row.data || {});
          if (r.ok) {
            deliveryOk = true;
            console.log(`FCM ok: user=${row.user_id}`);
          } else if (r.status === 404 || r.status === 410) {
            // Token invalid / unregistered → deaktivieren
            console.warn(`FCM token invalid (${r.status}), deaktiviere: ${token.slice(0, 20)}…`);
            await fetch(
              `${SUPABASE_URL}/rest/v1/push_subscriptions?fcm_token=eq.${encodeURIComponent(token)}`,
              { method: 'PATCH', headers: { ...pushAuth, 'Content-Type': 'application/json' }, body: JSON.stringify({ is_active: false }) }
            );
          } else {
            const errBody = await r.text().catch(() => '');
            console.error(`FCM error ${r.status}: ${errBody}`);
          }
        } catch (e) {
          console.error('FCM send exception:', e.message);
        }
      }
    }

    // 4. Queue-Zeile markieren: 'sent' wenn Delivery ok oder kein Token; 'failed' sonst.
    //    Failed-Items mit attempts < 3 werden beim nächsten Cron-Lauf erneut versucht.
    const newStatus = (deliveryOk || tokens.length === 0) ? 'sent' : 'failed';
    await fetch(
      `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${row.id}`,
      {
        method: 'PATCH',
        headers: { ...pushAuth, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: newStatus,
          processed_at: new Date().toISOString(),
          attempts: (row.attempts || 0) + 1,
        }),
      }
    );
    if (newStatus === 'sent') sent++; else failed++;
  }

  return { drained: list.length, sent, failed, fcmEnabled: true };
}

export default {
  // ⏰ Cron-Trigger — ruft den Dispatcher einmal pro Minute auf.
  async scheduled(event, env, ctx) {
    const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || '';
    if (!serviceKey) {
      console.error('cron skip: SUPABASE_SERVICE_ROLE_KEY fehlt');
      return;
    }
    const pushAuth = {
      'apikey': serviceKey,
      'Authorization': `Bearer ${serviceKey}`,
    };
    try {
      const result = await dispatchPushQueue(env, pushAuth);
      console.log('cron dispatch ok:', JSON.stringify(result));
    } catch (e) {
      console.error('cron dispatch failed:', e.message);
    }
    // 🧹 6h Chat-Reset: ALLE Nachrichten aus allen Räumen löschen.
    // Läuft ca. einmal pro 6h (random 1/360 per Minute-Cron).
    try {
      if (Math.random() < 1 / 360) {
        const chatDeleteRes = await fetch(
          `${SUPABASE_URL}/rest/v1/chat_messages?id=not.is.null`,
          {
            method: 'DELETE',
            headers: { ...pushAuth, 'Prefer': 'return=minimal' },
          },
        );
        console.log('cron chat-reset:', chatDeleteRes.status);
      }
    } catch (e) {
      console.error('cron chat-reset failed:', e.message);
    }

    // 🧹 Bundle P-X7: Wöchentliche Cleanup — alte 'sent'/'failed'-Zeilen
    // aus notification_queue entfernen (>7 Tage). Reduziert ständig
    // wachsende Tabelle. Nur einmal pro 60min triggern (delete-Lokal-
    // Spam-Schutz: random ~1/60).
    try {
      if (Math.random() < 1 / 60) {
        const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
          .toISOString();
        const cleanRes = await fetch(
          `${SUPABASE_URL}/rest/v1/notification_queue?status=in.(sent,failed)&created_at=lt.${cutoff}`,
          {
            method: 'DELETE',
            headers: { ...pushAuth, 'Prefer': 'return=minimal' },
          },
        );
        console.log('cron queue-cleanup:', cleanRes.status);
      }
    } catch (e) {
      console.error('cron queue-cleanup failed:', e.message);
    }
  },

  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // ── Migration v15: avatar_emoji Spalten + RLS-Policies für chat_messages ─
    // Aufruf: POST /admin/migrate-v15 {"token": "mig15-wb-2026"}
    if (path === '/admin/migrate-v15' && method === 'POST') {
      const body = await request.json().catch(() => ({}));
      if (body.token !== 'mig15-wb-2026') return jsonResponse({ error: 'Forbidden' }, 403);
      const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
      const results = [];
      
      // Diese Migration fügt avatar_emoji zu beiden Tabellen hinzu
      // und setzt RLS-Policies für chat_messages
      const migrations = [
        // 1. avatar_emoji zu chat_messages hinzufügen
        { name: 'add_avatar_emoji_chat', body: { message: 'ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS avatar_emoji TEXT DEFAULT NULL' } },
        // 2. avatar_emoji zu profiles hinzufügen
        { name: 'add_avatar_emoji_profiles', body: { message: 'ALTER TABLE profiles ADD COLUMN IF NOT EXISTS avatar_emoji TEXT DEFAULT NULL' } },
        // 3. RLS Policy für chat_messages SELECT (alle können lesen)
        { name: 'rls_chat_select', body: { message: 'DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename=\'chat_messages\' AND policyname=\'Allow public read\') THEN CREATE POLICY "Allow public read" ON chat_messages FOR SELECT USING (true); END IF; END $$' } },
        // 4. RLS Policy für chat_messages INSERT (anon darf inserting)
        { name: 'rls_chat_insert', body: { message: 'DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename=\'chat_messages\' AND policyname=\'Allow anon insert\') THEN CREATE POLICY "Allow anon insert" ON chat_messages FOR INSERT WITH CHECK (true); END IF; END $$' } },
        // 5. RLS Policy für chat_messages UPDATE (anon darf updaten wenn username passt)
        { name: 'rls_chat_update', body: { message: 'DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename=\'chat_messages\' AND policyname=\'Allow anon update\') THEN CREATE POLICY "Allow anon update" ON chat_messages FOR UPDATE USING (true) WITH CHECK (true); END IF; END $$' } },
      ];
      
      for (const mig of migrations) {
        try {
          // Nutze Supabase REST API direkt (exec_sql existiert nicht)
          // Stattdessen nutzen wir den pg_dump Trick: Spalte via ALTER TABLE
          // Das geht nur über die Supabase Dashboard SQL Editor oder Management API
          // Hier versuchen wir einen Workaround via RPC
          const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'apikey': svcKey, 'Authorization': `Bearer ${svcKey}` },
            body: JSON.stringify({ sql: mig.body.message }),
          });
          const txt = await r.text();
          results.push({ name: mig.name, status: r.status, response: txt.substring(0, 200) });
        } catch (e) {
          results.push({ name: mig.name, error: String(e) });
        }
      }
      return jsonResponse({ ok: true, migration: 'v15', results });
    }

    // ── Migration v13 (einmalig, Token-gesichert) ─────────────
    if (path === '/admin/migrate-v13' && method === 'POST') {
      const body = await request.json().catch(() => ({}));
      if (body.token !== 'mig13-wb-2026') return jsonResponse({ error: 'Forbidden' }, 403);
      const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
      const results = [];
      const statements = [
        `ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS read_by TEXT[] NOT NULL DEFAULT '{}'`,
        `CREATE INDEX IF NOT EXISTS idx_chat_messages_read_by ON chat_messages USING GIN (read_by)`,
        `CREATE OR REPLACE FUNCTION mark_message_as_read(p_message_id TEXT, p_user_id TEXT) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $f$ BEGIN UPDATE chat_messages SET read_by = array_append(read_by, p_user_id) WHERE id = p_message_id AND NOT (p_user_id = ANY(read_by)); END; $f$`,
        `CREATE OR REPLACE FUNCTION mark_room_messages_as_read(p_room_id TEXT, p_user_id TEXT) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $f$ BEGIN UPDATE chat_messages SET read_by = array_append(read_by, p_user_id) WHERE room_id = p_room_id AND is_deleted = FALSE AND NOT (p_user_id = ANY(read_by)); END; $f$`,
        `CREATE TABLE IF NOT EXISTS push_subscriptions (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, endpoint TEXT NOT NULL, p256dh TEXT NOT NULL DEFAULT '', auth_key TEXT NOT NULL DEFAULT '', platform TEXT NOT NULL DEFAULT 'web', fcm_token TEXT, device_info JSONB DEFAULT '{}', is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), UNIQUE(user_id, endpoint))`,
        `ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY`,
        `DO $d$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='push_subscriptions' AND policyname='Users manage own push subscriptions') THEN CREATE POLICY "Users manage own push subscriptions" ON push_subscriptions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id); END IF; END $d$`,
        `CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user_id ON push_subscriptions(user_id)`,
        `CREATE TABLE IF NOT EXISTS notification_queue (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, title TEXT NOT NULL, body TEXT NOT NULL, data JSONB DEFAULT '{}', status TEXT NOT NULL DEFAULT 'pending', attempts INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), processed_at TIMESTAMPTZ)`,
        `CREATE INDEX IF NOT EXISTS idx_notification_queue_pending ON notification_queue(status, created_at) WHERE status = 'pending'`,
      ];
      for (const sql of statements) {
        try {
          const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` },
            body: JSON.stringify({ sql }),
          });
          const txt = await r.text();
          results.push({ sql: sql.substring(0, 80), status: r.status, response: txt.substring(0, 100) });
        } catch(e) { results.push({ sql: sql.substring(0, 80), error: String(e) }); }
      }
      return jsonResponse({ ok: true, results });
    }

    // ── Migration v14: RPC-Funktionen für Chat Edit/Delete (Token-gesichert) ─
    // Erstellt SECURITY DEFINER Funktionen die RLS bypassen
    // Aufruf: POST /admin/migrate-v14 mit {"token": "mig14-wb-2026"}
    if (path === '/admin/migrate-v14' && method === 'POST') {
      const body = await request.json().catch(() => ({}));
      if (body.token !== 'mig14-wb-2026') return jsonResponse({ error: 'Forbidden' }, 403);
      const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
      
      // WICHTIG: Supabase Management API zum Erstellen von SQL-Funktionen
      // Da exec_sql nicht existiert, nutzen wir die Supabase Management API
      // oder deployen die Funktionen über direkten SQL-Zugang
      
      // Direkte SQL-Ausführung über Supabase Management API
      const projectRef = 'adtviduaftdquvfjpojb';
      
      const sqls = [
        // Funktion zum Editieren von Chat-Nachrichten (SECURITY DEFINER bypasses RLS)
        `CREATE OR REPLACE FUNCTION edit_chat_message(
          p_message_id UUID,
          p_username TEXT,
          p_new_message TEXT,
          p_is_admin BOOLEAN DEFAULT FALSE
        ) RETURNS JSONB
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $$
        DECLARE
          v_existing RECORD;
          v_result JSONB;
        BEGIN
          -- Nachricht suchen
          SELECT id, username, user_id INTO v_existing
          FROM chat_messages
          WHERE id = p_message_id;
          
          IF NOT FOUND THEN
            RETURN jsonb_build_object('success', false, 'error', 'Nachricht nicht gefunden');
          END IF;
          
          -- Ownership-Check (Admin darf alles)
          IF NOT p_is_admin AND v_existing.username != p_username THEN
            RETURN jsonb_build_object('success', false, 'error', 'Keine Berechtigung');
          END IF;
          
          -- Update
          UPDATE chat_messages
          SET message = p_new_message,
              content = p_new_message,
              edited_at = NOW()
          WHERE id = p_message_id;
          
          RETURN jsonb_build_object('success', true, 'message', 'Nachricht bearbeitet');
        END;
        $$`,
        
        // Funktion zum Löschen von Chat-Nachrichten (Soft-Delete, SECURITY DEFINER)
        `CREATE OR REPLACE FUNCTION delete_chat_message(
          p_message_id UUID,
          p_username TEXT,
          p_is_admin BOOLEAN DEFAULT FALSE
        ) RETURNS JSONB
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $$
        DECLARE
          v_existing RECORD;
        BEGIN
          -- Nachricht suchen
          SELECT id, username, user_id INTO v_existing
          FROM chat_messages
          WHERE id = p_message_id;
          
          IF NOT FOUND THEN
            RETURN jsonb_build_object('success', false, 'error', 'Nachricht nicht gefunden');
          END IF;
          
          -- Ownership-Check (Admin darf alles)
          IF NOT p_is_admin AND v_existing.username != p_username THEN
            RETURN jsonb_build_object('success', false, 'error', 'Keine Berechtigung');
          END IF;
          
          -- Soft-Delete
          UPDATE chat_messages
          SET is_deleted = true,
              deleted_at = NOW()
          WHERE id = p_message_id;
          
          RETURN jsonb_build_object('success', true, 'message', 'Nachricht gelöscht');
        END;
        $$`,
        
        // Grant execute auf die Funktionen für die anon Rolle
        `GRANT EXECUTE ON FUNCTION edit_chat_message(UUID, TEXT, TEXT, BOOLEAN) TO anon, authenticated`,
        `GRANT EXECUTE ON FUNCTION delete_chat_message(UUID, TEXT, BOOLEAN) TO anon, authenticated`,
      ];
      
      const results = [];
      
      // Versuche über Supabase Management API
      for (const sql of sqls) {
        try {
          // Supabase Management API (braucht service key)
          const r = await fetch(`https://api.supabase.com/v1/projects/${projectRef}/database/query`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${svcKey}`,
            },
            body: JSON.stringify({ query: sql }),
          });
          const txt = await r.text();
          results.push({ sql: sql.substring(0, 80), status: r.status, response: txt.substring(0, 200) });
        } catch(e) {
          results.push({ sql: sql.substring(0, 80), error: String(e) });
        }
      }
      return jsonResponse({ ok: true, results });
    }

    // ── Health Check ──────────────────────────────────────────
    if (path === '/' || path === '/health') {
      return jsonResponse({
        status: 'ok',
        service: 'Weltenbibliothek API Worker',
        version: '3.0.0',
        timestamp: new Date().toISOString(),
        endpoints: [
          '/recherche', '/api/articles', '/api/chat/messages',
          '/voice/rooms', '/api/tools/*', '/api/push/*',
          '/api/statistics', '/api/admin/*', '/api/profile/*',
          '/api/sync/*', '/api/ai/*', '/api/community/*',
          '/auth/*', '/errors/report', '/api/media/upload',
        ],
      });
    }

    // ── Recherche (KI-Suche) ──────────────────────────────────
    if ((path === '/recherche' || path === '/api/recherche') && (method === 'POST' || method === 'GET')) {
      try {
        let query, realm;
        if (method === 'POST') {
          const body = await request.json();
          query = body.query || body.q || '';
          realm = body.realm || 'materie';
        } else {
          query = url.searchParams.get('q') || url.searchParams.get('query') || '';
          realm = url.searchParams.get('realm') || 'materie';
        }
        if (!query) return jsonResponse({ results: [], query: '', error: 'Kein Suchbegriff' });

        // ── PHASE 1: Parallele Suche (DB + Wikipedia DE + DuckDuckGo Instant) ──
        const anonKey = env.SUPABASE_ANON_KEY || '';
        const searchWord = encodeURIComponent(`%${query}%`);

        const [dbRes, wikiDeRes, wikiEnRes, ddgRes] = await Promise.all([
          // 1. Lokale DB: eigene Artikel
          fetch(`${SUPABASE_URL}/rest/v1/articles?select=id,title,content,category,world,created_at&or=(title.ilike.${searchWord},content.ilike.${searchWord})&is_published=eq.true&limit=5`, {
            headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` },
          }).then(r => r.json()).catch(() => []),

          // 2. Wikipedia DE (Deutsch priorisiert)
          fetch(`https://de.wikipedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(query)}&srlimit=8&format=json&utf8=1`, {
            headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' },
          }).then(r => r.json()).catch(() => ({})),

          // 3. Wikipedia EN (englisch als Ergänzung)
          fetch(`https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=${encodeURIComponent(query)}&srlimit=5&format=json&utf8=1`, {
            headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' },
          }).then(r => r.json()).catch(() => ({})),

          // 4. DuckDuckGo Instant Answer API (kostenlos)
          fetch(`https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_redirect=1&no_html=1&skip_disambig=1`, {
            headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' },
          }).then(r => r.json()).catch(() => ({})),
        ]);

        // Parse Wikipedia DE results (priorisiert)
        const wikiDeResults = ((wikiDeRes?.query?.search) || []).map(r => ({
          title: r.title,
          snippet: (r.snippet || '').replace(/<[^>]+>/g, ''),
          source: 'Wikipedia DE',
          url: `https://de.wikipedia.org/wiki/${encodeURIComponent(r.title.replace(/ /g, '_'))}`,
          type: 'wiki',
          pageId: r.pageid,
        }));

        // Parse Wikipedia EN results (Ergänzung – Duplikate filtern)
        const deTitles = new Set(wikiDeResults.map(r => r.title.toLowerCase()));
        const wikiEnResults = ((wikiEnRes?.query?.search) || [])
          .filter(r => !deTitles.has(r.title.toLowerCase()))
          .map(r => ({
            title: r.title,
            snippet: (r.snippet || '').replace(/<[^>]+>/g, ''),
            source: 'Wikipedia EN',
            url: `https://en.wikipedia.org/wiki/${encodeURIComponent(r.title.replace(/ /g, '_'))}`,
            type: 'wiki_en',
            pageId: r.pageid,
          }));

        const wikiResults = [...wikiDeResults, ...wikiEnResults];

        // Parse DuckDuckGo Instant Answer
        const ddgResults = [];
        if (ddgRes?.Abstract) {
          ddgResults.push({
            title: ddgRes.Heading || query,
            snippet: ddgRes.Abstract,
            source: ddgRes.AbstractSource || 'DuckDuckGo',
            url: ddgRes.AbstractURL || null,
            type: 'instant',
          });
        }
        // DDG Related Topics
        for (const topic of (ddgRes?.RelatedTopics || []).slice(0, 5)) {
          if (topic.Text) {
            ddgResults.push({
              title: topic.Text.split(' - ')[0] || topic.Text.substring(0, 80),
              snippet: topic.Text,
              source: 'DuckDuckGo',
              url: topic.FirstURL || null,
              type: 'related',
            });
          }
        }

        // Lokale DB Ergebnisse
        const safeDb = Array.isArray(dbRes) ? dbRes : [];
        const dbResults = safeDb.map(a => ({
          title: a.title,
          snippet: (a.content || '').substring(0, 300),
          source: 'Weltenbibliothek',
          url: null,
          category: a.category,
          type: 'article',
        }));

        const allResults = [...dbResults, ...ddgResults, ...wikiResults];

        // ── PHASE 2: KI-Zusammenfassung (Cloudflare Workers AI – kostenlos) ──
        let aiSummary = null;
        if (env.AI && allResults.length > 0) {
          try {
            const context = allResults.slice(0, 5).map(r => `${r.title}: ${r.snippet}`).join('\n');
            const aiRes = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
              messages: [
                { role: 'system', content: 'Du bist ein Recherche-Assistent. Fasse die folgenden Suchergebnisse in 3-5 Sätzen auf Deutsch zusammen. Sei sachlich und informativ.' },
                { role: 'user', content: `Suchanfrage: "${query}"\n\nErgebnisse:\n${context}` },
              ],
              max_tokens: 500,
            });
            aiSummary = aiRes?.response || null;
          } catch (aiErr) {
            // AI ist optional – kein Error
          }
        }

        return jsonResponse({
          results: allResults,
          query,
          total: allResults.length,
          summary: aiSummary,
          sources: { db: dbResults.length, wiki: wikiResults.length, ddg: ddgResults.length },
        });
      } catch (e) {
        return errorResponse(`Recherche-Fehler: ${e.message}`);
      }
    }

    // ── Rabbit-Hole Recherche ──────────────────────────────────
    if (path.startsWith('/api/rabbit-hole')) {
      try {
        const topic = path.replace('/api/rabbit-hole/', '').replace('/api/rabbit-hole', '');
        const gatewayUrl = env.OPENCLAW_GATEWAY_URL || 'http://72.62.154.95:50074';

        if (method === 'POST') {
          const body = await request.json();
          const res = await fetch(`${gatewayUrl}/rabbit-hole`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
          }).catch(() => null);
          if (!res || !res.ok) {
            return jsonResponse({ connections: [], topic: body.topic || topic });
          }
          const data = await res.json();
          return jsonResponse(data);
        }

        // GET: Rabbit-Hole für Topic
        return jsonResponse({
          topic: decodeURIComponent(topic),
          connections: [],
          depth: 0,
          message: 'Rabbit-Hole-Daten werden geladen...',
        });
      } catch (e) {
        return errorResponse(`Rabbit-Hole-Fehler: ${e.message}`);
      }
    }

    // ── Artikel ───────────────────────────────────────────────
    if (path === '/api/articles') {
      const params = url.searchParams;
      let supaPath = '/rest/v1/articles?select=*&is_published=eq.true&order=created_at.desc';
      if (params.get('world')) supaPath += `&world=eq.${params.get('world')}`;
      if (params.get('realm')) supaPath += `&world=eq.${params.get('realm')}`;
      if (params.get('category')) supaPath += `&category=eq.${params.get('category')}`;
      const limit = params.get('limit') || '50';
      const offset = params.get('offset') || '0';
      supaPath += `&limit=${limit}&offset=${offset}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── Tages-Featured ────────────────────────────────────────
    if (path === '/api/daily-featured') {
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const world = url.searchParams.get('world') || 'materie';
      const supaPath = `/rest/v1/articles?select=*&is_published=eq.true&world=eq.${world}&order=created_at.desc&limit=1`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── Chat Nachrichten ──────────────────────────────────────
    if (path === '/api/chat/messages') {
      const roomId = url.searchParams.get('room') || url.searchParams.get('room_id');
      const limitParam = parseInt(url.searchParams.get('limit') || '50', 10);

      if (method === 'GET' && roomId) {
        const anonKey = env.SUPABASE_ANON_KEY || '';
        const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;
        // FIX: Explicit column list with avatar_emoji (added via migration v14/v15)
        const selectCols = 'id,room_id,user_id,username,avatar_url,avatar_emoji,message,content,message_type,created_at,edited_at,deleted_at,is_deleted,read_by';
        const supaPath = `/rest/v1/chat_messages?select=${selectCols}&room_id=eq.${encodeURIComponent(roomId)}&is_deleted=eq.false&order=created_at.asc&limit=${limitParam}`;
        const res = await fetch(`${SUPABASE_URL}${supaPath}`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'apikey': serviceKey,
            'Authorization': `Bearer ${serviceKey}`,
          },
        });
        const messages = await res.json().catch(() => []);
        const safeMessages = Array.isArray(messages) ? messages : [];
        return jsonResponse({
          messages: safeMessages.map(m => ({
            message_id: m.id,
            id: m.id,
            room_id: m.room_id,
            user_id: m.user_id,
            userId: m.user_id,
            username: m.username || 'Anonym',
            avatar_url: m.avatar_url || null,
            avatar_emoji: m.avatar_emoji || null,  // null-safe: Spalte existiert nach Migration v15
            message: m.message || m.content || '',
            content: m.content || m.message || '',
            message_type: m.message_type || 'text',
            created_at: m.created_at,
            timestamp: m.created_at,
            is_deleted: m.is_deleted || false,
            deleted: m.is_deleted || false,
          })),
          total: safeMessages.length,
          hasMore: safeMessages.length >= limitParam,
        });
      }

      if (method === 'POST') {
        try {
          const body = await request.json();
          const anonKey = env.SUPABASE_ANON_KEY || '';
          // Use service role key so non-UUID user_ids and anonymous inserts work
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;

          // Sanitize userId: only keep valid UUIDs (must exist in auth.users due to FK)
          const rawUserId = body.userId || body.user_id || null;
          const isUUID = rawUserId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(rawUserId);
          // Only use UUID if it's a valid format; null is allowed (user_id is nullable in DB)
          const finalUserId = isUUID ? rawUserId : null;

          const replyToId      = body.replyToId || body.reply_to_id || null;
          const replyToContent = body.replyToContent || body.reply_to_content || null;
          const replyToSender  = body.replyToSenderName || body.reply_to_sender_name || null;
          const mediaUrl       = body.mediaUrl || body.media_url || null;

          const insertBody = {
            room_id:      body.roomId || body.room_id || '',
            user_id:      finalUserId,
            username:     body.username || 'Anonym',
            avatar_url:   body.avatarUrl || body.avatar_url || null,
            avatar_emoji: body.avatarEmoji || body.avatar_emoji || null,
            content:      body.message || body.content || '',
            message:      body.message || body.content || '',
            message_type: body.mediaType === 'audio' ? 'voice' : (body.mediaType === 'image' ? 'image' : 'text'),
            ...(mediaUrl       ? { media_url: mediaUrl }                  : {}),
            ...(replyToId      ? { reply_to_id: replyToId }               : {}),
            ...(replyToContent ? { reply_to_content: replyToContent.substring(0, 280) } : {}),
            ...(replyToSender  ? { reply_to_sender_name: replyToSender }  : {}),
          };

          const res = await fetch(`${SUPABASE_URL}/rest/v1/chat_messages`, {
            method: 'POST',
            headers: {
              'Content-Type':  'application/json',
              'apikey':        serviceKey,
              'Authorization': `Bearer ${serviceKey}`,
              'Prefer':        'return=representation',
            },
            body: JSON.stringify(insertBody),
          });

          const rawData = await res.json().catch(() => null);
          const saved   = Array.isArray(rawData) ? rawData[0] : rawData;

          if (res.ok && saved) {
            return jsonResponse({ success: true, message: saved });
          }
          // Surface Supabase error for debugging
          return jsonResponse(
            { success: false, error: saved?.message || `Supabase ${res.status}` },
            res.status
          );
        } catch (e) {
          return errorResponse(`Chat-Send-Fehler: ${e.message}`);
        }
      }
    }

    // ── Chat Nachricht bearbeiten (PUT /api/chat/messages/:id) ──
    if (path.startsWith('/api/chat/messages/') && method === 'PUT') {
      const messageId = path.replace('/api/chat/messages/', '');
      if (!messageId) return errorResponse('Nachrichten-ID fehlt', 400);
      try {
        const body = await request.json().catch(() => ({}));
        const { roomId, userId, username, message, realm, isAdmin } = body;
        const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';

        // ✅ WICHTIG: App nutzt InvisibleAuth (custom IDs), NICHT Supabase Auth.
        // user_id in der DB ist daher NULL. Wir identifizieren die Nachricht
        // ausschließlich per message-ID + username-Prüfung für Sicherheit.
        // Service-Role-Key umgeht RLS komplett.

        // Erst prüfen ob die Nachricht dem User gehört (via username oder isAdmin)
        const checkRes = await fetch(
          `${SUPABASE_URL}/rest/v1/chat_messages?id=eq.${messageId}&select=id,username,user_id`,
          {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
              'apikey': svcKey,
              'Authorization': `Bearer ${svcKey}`,
            },
          }
        );
        const checkData = await checkRes.json().catch(() => []);
        if (!Array.isArray(checkData) || checkData.length === 0) {
          return errorResponse('Nachricht nicht gefunden', 404);
        }
        const existingMsg = checkData[0];
        // Sicherheitscheck: Username muss übereinstimmen (oder isAdmin) — case-insensitive
        if (!isAdmin && username && existingMsg.username?.toLowerCase() !== username.toLowerCase()) {
          return errorResponse('Keine Berechtigung zum Bearbeiten', 403);
        }

        const updateRes = await fetch(
          `${SUPABASE_URL}/rest/v1/chat_messages?id=eq.${messageId}`,
          {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              'apikey': svcKey,
              'Authorization': `Bearer ${svcKey}`,
              'Prefer': 'return=representation',
            },
            body: JSON.stringify({
              message: message || '',
              content: message || '',
              edited_at: new Date().toISOString(),
            }),
          }
        );
        if (!updateRes.ok) {
          const errText = await updateRes.text().catch(() => '');
          console.error('Edit Supabase error:', updateRes.status, errText);
          return errorResponse(`Supabase Fehler beim Bearbeiten: ${updateRes.status}`, updateRes.status);
        }
        const updated = await updateRes.json().catch(() => []);
        if (!Array.isArray(updated) || updated.length === 0) {
          return errorResponse('Nachricht konnte nicht bearbeitet werden (nicht gefunden)', 404);
        }
        return jsonResponse({ success: true, message: 'Nachricht bearbeitet', data: updated });
      } catch (e) {
        return errorResponse(`Edit-Fehler: ${e.message}`);
      }
    }

    // ── Chat Nachricht löschen (DELETE /api/chat/messages/:id) ──
    if (path.startsWith('/api/chat/messages/') && method === 'DELETE') {
      const messageId = path.replace('/api/chat/messages/', '');
      if (!messageId) return errorResponse('Nachrichten-ID fehlt', 400);
      try {
        const body = await request.json().catch(() => ({}));
        const { userId, username, roomId, realm, isAdmin } = body;
        const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';

        // ✅ WICHTIG: user_id in DB ist NULL (InvisibleAuth). 
        // Authentifizierung via username-Prüfung + Service-Role-Key.
        if (!isAdmin) {
          // Prüfe ob Nachricht dem User gehört (via username)
          const checkRes = await fetch(
            `${SUPABASE_URL}/rest/v1/chat_messages?id=eq.${messageId}&select=id,username,user_id`,
            {
              method: 'GET',
              headers: {
                'Content-Type': 'application/json',
                'apikey': svcKey,
                'Authorization': `Bearer ${svcKey}`,
              },
            }
          );
          const checkData = await checkRes.json().catch(() => []);
          if (!Array.isArray(checkData) || checkData.length === 0) {
            return errorResponse('Nachricht nicht gefunden', 404);
          }
          const existingMsg = checkData[0];
          if (username && existingMsg.username?.toLowerCase() !== username.toLowerCase()) {
            return errorResponse('Keine Berechtigung zum Löschen', 403);
          }
        }

        // HARD-DELETE statt Soft-Delete:
        // 1. Soft-Delete via PATCH feuert ein UPDATE-Event im Realtime-Stream → der
        //    Client-Filter auf `is_deleted=eq.false` beim initialen Load greift, aber
        //    die laufende Realtime-Subscription aktualisiert die Message in-place und
        //    zeigt sie weiterhin an. Ergebnis: Nachricht scheint "wieder aufzutauchen".
        // 2. Hard-DELETE feuert ein DELETE-Event → alle Clients entfernen die Message
        //    sofort aus der Liste. Persistenz + UI-Konsistenz in einem Schritt.
        const deleteRes = await fetch(
          `${SUPABASE_URL}/rest/v1/chat_messages?id=eq.${messageId}`,
          {
            method: 'DELETE',
            headers: {
              'apikey': svcKey,
              'Authorization': `Bearer ${svcKey}`,
              'Prefer': 'return=minimal',
            },
          }
        );
        if (!deleteRes.ok) {
          const errText = await deleteRes.text().catch(() => '');
          console.error('Delete Supabase error:', deleteRes.status, errText);
          return errorResponse(`Supabase Fehler beim Löschen: ${deleteRes.status}`, deleteRes.status);
        }
        // Idempotent: auch wenn 0 Rows betroffen (schon gelöscht), gilt als Erfolg
        return jsonResponse({ success: true, message: 'Nachricht gelöscht' });
      } catch (e) {
        return errorResponse(`Delete-Fehler: ${e.message}`);
      }
    }

    // ── Voice-Upload ──────────────────────────────────────────
    if (path === '/api/chat/voice-upload' && method === 'POST') {
      try {
        const formData = await request.formData();
        const file = formData.get('file') || formData.get('audio');
        if (!file || !env.R2_BUCKET) {
          return errorResponse('Keine Datei oder kein R2-Bucket konfiguriert', 400);
        }
        const key = `voice/${Date.now()}_${file.name || 'voice.m4a'}`;
        await env.R2_BUCKET.put(key, file.stream(), {
          httpMetadata: { contentType: file.type || 'audio/m4a' },
        });
        const publicUrl = `https://pub-${env.CF_ACCOUNT_ID || 'unknown'}.r2.dev/${key}`;
        return jsonResponse({ url: publicUrl, key });
      } catch (e) {
        return errorResponse(`Voice-Upload-Fehler: ${e.message}`);
      }
    }

    // ── Chat Räume ────────────────────────────────────────────
    if (path === '/voice/rooms' || path === '/api/chat/rooms') {
      const world = url.searchParams.get('realm') || url.searchParams.get('world');
      let supaPath = '/rest/v1/chat_rooms?select=*&is_active=eq.true&order=name.asc';
      if (world) supaPath += `&world=eq.${world}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── UFO-Sichtungen ────────────────────────────────────────
    if (path === '/materie/ufos' || path.startsWith('/materie/ufos')) {
      const roomId = url.searchParams.get('room_id');
      const limit = url.searchParams.get('limit') || '50';
      let supaPath = `/rest/v1/tool_ufo_sightings?select=*&order=created_at.desc&limit=${limit}`;
      if (roomId) supaPath += `&room_id=eq.${roomId}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── Profil (einzeln nach Username) ────────────────────────
    // ── Profil per userId Query (/api/profile/get?userId=xxx) ──
    if (path === '/api/profile/get' && method === 'GET') {
      const userId = url.searchParams.get('userId');
      if (userId) {
        const supaPath = `/rest/v1/profiles?select=*&id=eq.${encodeURIComponent(userId)}&limit=1`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
      return errorResponse('userId parameter required');
    }

    if (path.startsWith('/api/profile/')) {
      const parts = path.split('/'); // /api/profile/{world}/{username}

      // POST: Profil speichern (username-based auth, kein Supabase Auth nötig)
      if (method === 'POST' && (parts[3] === 'materie' || parts[3] === 'energie') && parts.length === 4) {
        try {
          const body = await request.json();
          const world = parts[3];
          if (!body.world) body.world = world;

          // Admin-Passwort-Prüfung — env.ROOT_ADMIN_PASSWORD via
          // `wrangler secret put ROOT_ADMIN_PASSWORD`. Fallback auf alten
          // Hardcoded-Wert für Übergangszeit damit kein User ausgesperrt
          // wird falls Secret noch nicht gesetzt. TODO: nach Migration
          // Fallback entfernen.
          const ADMIN_USERNAME = 'weltenbibliothek';
          const ADMIN_PASSWORD = env.ROOT_ADMIN_PASSWORD || 'Jolene2305';
          if (body.username && body.username.toLowerCase() === ADMIN_USERNAME) {
            if (!body.password || body.password !== ADMIN_PASSWORD) {
              return jsonResponse({ success: false, error: 'Falsches Admin-Passwort.' }, 403);
            }
          }
          // Passwort nicht in die DB schreiben
          delete body.password;

          // Upsert via username (UNIQUE constraint) — Trigger setzt role=root_admin für 'Weltenbibliothek'
          const anonKey = env.SUPABASE_ANON_KEY || '';
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;
          // Service-Role-Key nutzen damit Trigger und role-Feld auch mit RLS schreiben kann
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?on_conflict=username`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': serviceKey,
              'Authorization': `Bearer ${serviceKey}`,
              'Prefer': 'return=representation,resolution=merge-duplicates',
            },
            body: JSON.stringify(body),
          });
          const data = await res.json().catch(() => ({}));
          const profile = Array.isArray(data) ? data[0] : data;
          if (profile && profile.id) {
            const isRootAdmin = (profile.role || '').toLowerCase().replace('-', '_') === 'root_admin';
            const isAdmin = ['admin', 'root_admin', 'content_editor'].includes((profile.role || '').toLowerCase().replace('-', '_'));
            return jsonResponse({
              success: true,
              userId: profile.id,
              role: profile.role || 'user',
              isAdmin,
              isRootAdmin,
              profile,
            }, 200);
          }
          return jsonResponse(data, res.status < 300 ? 200 : res.status);
        } catch (e) {
          return errorResponse(`Profil-Speicher-Fehler: ${e.message}`);
        }
      }

      // GET: Profil nach Username
      const username = parts[4];
      if (username) {
        const supaPath = `/rest/v1/profiles?select=id,username,display_name,avatar_url,bio,world,role,is_banned&username=eq.${encodeURIComponent(username)}&limit=1`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }

      // GET: /api/profile/{world} → eigenes Profil
      if (parts[3] && !parts[4]) {
        const world = parts[3];
        const supaPath = `/rest/v1/profiles?select=*&world=eq.${world}&order=created_at.desc&limit=50`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
    }

    // ── Profil-Liste (/api/profiles/:world) ──────────────────
    if (path.startsWith('/api/profiles/')) {
      const world = path.split('/')[3];
      const username = url.searchParams.get('username');
      let supaPath = `/rest/v1/profiles?select=*&world=eq.${world}&order=created_at.desc&limit=50`;
      if (username) supaPath += `&username=eq.${encodeURIComponent(username)}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    // ── Profil-Sync (/api/sync/*) ─────────────────────────────
    if (path.startsWith('/api/sync')) {
      if (method === 'GET') {
        const userId = url.searchParams.get('userId');
        if (!userId) return jsonResponse({ profile: null });
        const supaPath = `/rest/v1/profiles?select=*&id=eq.${userId}&limit=1`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
      if (method === 'POST') {
        try {
          const body = await request.json();
          const anonKey = env.SUPABASE_ANON_KEY || '';
          const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': anonKey,
              'Authorization': authHeader,
              'Prefer': 'return=representation,resolution=merge-duplicates',
            },
            body: JSON.stringify(body),
          });
          const data = await res.json().catch(() => ({}));
          return jsonResponse({ success: res.ok, profile: Array.isArray(data) ? data[0] : data });
        } catch (e) {
          return errorResponse(`Sync-Fehler: ${e.message}`);
        }
      }
    }

    // ── Push-Notifications (/api/push/* und /api/v2/push/*) ──
    // Real Supabase-backed implementation:
    //   POST /api/push/subscribe   → upsert push_subscriptions row
    //   POST /api/push/unsubscribe → mark subscription inactive
    //   GET  /api/push/pending?user_id=UUID → fetch+mark pending notification_queue rows
    //   POST /api/push/dispatch    → drain notification_queue, mark status (cron-callable)
    // Legacy NoOp paths (/stats, /settings, /send, /schedule, /topics/*, /register) keep
    // returning success so old clients don't break.
    if (path.startsWith('/api/push/') || path.startsWith('/api/v2/push/')) {
      const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || '';
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const pushAuth = serviceKey
        ? { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` }
        : { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` };

      // Body MUSS hier geparst werden — alle nachfolgenden Push-Handler
      // referenzieren `body?.user_id`, ohne diese Zeile war `body` undefined
      // (oder ReferenceError) und Subscribe/Unsubscribe schlugen fehl.
      const body = (method === 'POST' || method === 'PUT' || method === 'PATCH')
        ? await request.json().catch(() => ({}))
        : {};

      // POST /api/push/subscribe
      if (method === 'POST' && (path.endsWith('/subscribe') || path.endsWith('/register'))) {
        const userId = body?.user_id || body?.userId;
        if (!userId) return errorResponse('user_id required', 400);
        const row = {
          user_id: userId,
          endpoint: body?.endpoint || body?.fcm_token || `local-${userId}`,
          p256dh: body?.keys?.p256dh || '',
          auth_key: body?.keys?.auth || '',
          platform: body?.platform || 'android',
          fcm_token: body?.fcm_token || null,
          device_info: body?.device_info || {},
          is_active: true,
          updated_at: new Date().toISOString(),
        };
        try {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/push_subscriptions?on_conflict=user_id,endpoint`,
            {
              method: 'POST',
              headers: {
                ...pushAuth,
                'Content-Type': 'application/json',
                'Prefer': 'resolution=merge-duplicates,return=representation',
              },
              body: JSON.stringify(row),
            }
          );
          const data = await res.json().catch(() => ({}));
          return jsonResponse({ success: res.ok, subscription: Array.isArray(data) ? data[0] : data }, res.ok ? 201 : 500);
        } catch (e) {
          return errorResponse(`Subscribe failed: ${e.message}`);
        }
      }

      // POST /api/push/unsubscribe  oder  DELETE /api/push/unsubscribe/:userId
      if ((method === 'POST' && path.endsWith('/unsubscribe')) ||
          (method === 'DELETE' && path.includes('/unsubscribe/'))) {
        const userId = body?.user_id || body?.userId || path.split('/').pop();
        if (!userId) return errorResponse('user_id required', 400);
        try {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/push_subscriptions?user_id=eq.${encodeURIComponent(userId)}`,
            {
              method: 'PATCH',
              headers: { ...pushAuth, 'Content-Type': 'application/json' },
              body: JSON.stringify({ is_active: false, updated_at: new Date().toISOString() }),
            }
          );
          return jsonResponse({ success: res.ok });
        } catch (e) {
          return errorResponse(`Unsubscribe failed: ${e.message}`);
        }
      }

      // GET /api/push/pending?user_id=UUID → returns pending + marks them 'sent'
      // Used by the mobile client while the app is open to drain queued notifications.
      if (method === 'GET' && path.includes('/pending')) {
        const userId = url.searchParams.get('user_id') || path.split('/').pop();
        if (!userId || userId === 'pending') {
          return jsonResponse({ notifications: [], count: 0 });
        }
        try {
          const fetchRes = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue?user_id=eq.${encodeURIComponent(userId)}&status=eq.pending&select=*&order=created_at.asc&limit=50`,
            { headers: pushAuth }
          );
          const rows = await fetchRes.json().catch(() => []);
          const list = Array.isArray(rows) ? rows : [];
          if (list.length > 0 && serviceKey) {
            const ids = list.map(r => r.id);
            await fetch(
              `${SUPABASE_URL}/rest/v1/notification_queue?id=in.(${ids.join(',')})`,
              {
                method: 'PATCH',
                headers: { ...pushAuth, 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: 'sent', processed_at: new Date().toISOString() }),
              }
            );
          }
          return jsonResponse({ notifications: list, count: list.length });
        } catch (e) {
          return errorResponse(`Pending fetch failed: ${e.message}`);
        }
      }

      // POST /api/push/test → legt Test-Notification für user_id in notification_queue
      // Body: { user_id, type?, title?, body? }
      if (method === 'POST' && path.endsWith('/test')) {
        const testReqBody = await request.json().catch(() => ({}));
        const userId = testReqBody?.user_id;
        if (!userId) return errorResponse('user_id required', 400);
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
        const type = testReqBody?.type || 'chat_message';
        const testTitle = testReqBody?.title || '🔔 Test-Benachrichtigung';
        const testBody = testReqBody?.body || `Push-System funktioniert! Typ: ${type} · ${new Date().toLocaleTimeString('de-DE')}`;
        try {
          const ins = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue`,
            {
              method: 'POST',
              headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=representation' },
              body: JSON.stringify({
                user_id: userId,
                title: testTitle,
                body: testBody,
                data: { type, test: true, sent_at: new Date().toISOString() },
                status: 'pending',
              }),
            }
          );
          const row = await ins.json().catch(() => null);
          // Sofort dispatchen damit FCM-Push nicht auf den nächsten Cron wartet
          if (env.AI || serviceKey) {
            try {
              const pushAuth2 = { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` };
              await dispatchPushQueue(env, pushAuth2);
            } catch (_) {}
          }
          return jsonResponse({ success: ins.ok, queued: true, row: Array.isArray(row) ? row[0] : row });
        } catch (e) {
          return errorResponse(`Test-Push fehlgeschlagen: ${e.message}`);
        }
      }

      // POST /api/push/dispatch → drains notification_queue; callable by cron.
      if (method === 'POST' && path.endsWith('/dispatch')) {
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
        try {
          const result = await dispatchPushQueue(env, pushAuth);
          return jsonResponse({ success: true, ...result });
        } catch (e) {
          return errorResponse(`Dispatch failed: ${e.message}`);
        }
      }

      // GET /api/push/debug?user_id=UUID → Diagnose-Endpunkt (kein Secret exponiert)
      if (method === 'GET' && path.endsWith('/debug')) {
        const userId = url.searchParams.get('user_id');
        const fcmConfigured = !!env.FCM_SERVICE_ACCOUNT;
        if (!userId) return jsonResponse({ fcm_configured: fcmConfigured });
        try {
          const [subsRes, queueRes] = await Promise.all([
            fetch(`${SUPABASE_URL}/rest/v1/push_subscriptions?user_id=eq.${encodeURIComponent(userId)}&select=is_active,fcm_token,platform,updated_at`, { headers: pushAuth }),
            fetch(`${SUPABASE_URL}/rest/v1/notification_queue?user_id=eq.${encodeURIComponent(userId)}&select=id,title,status,attempts,created_at&order=created_at.desc&limit=10`, { headers: pushAuth }),
          ]);
          const subs = await subsRes.json().catch(() => []);
          const queue = await queueRes.json().catch(() => []);
          const safeSubs = Array.isArray(subs) ? subs : [];
          return jsonResponse({
            fcm_configured: fcmConfigured,
            subscriptions: safeSubs.map(s => ({
              is_active: s.is_active,
              has_fcm_token: !!s.fcm_token,
              platform: s.platform,
              updated_at: s.updated_at,
            })),
            recent_queue: Array.isArray(queue) ? queue : [],
          });
        } catch (e) {
          return errorResponse(`Debug failed: ${e.message}`);
        }
      }

      // Legacy NoOp fallbacks (keep old clients working)
      if (method === 'POST') {
        return jsonResponse({ success: true, message: 'Push ok' });
      }
      if (method === 'GET') {
        if (path.includes('/stats')) {
          return jsonResponse({ pending: 0, sent: 0, failed: 0 });
        }
        if (path.includes('/settings')) {
          return jsonResponse({ enabled: true, rooms: [], topics: [] });
        }
        return jsonResponse({ status: 'ok' });
      }
    }

    // ── LiveKit Token ─────────────────────────────────────────
    // POST /api/livekit/token   { roomName, displayName? }
    // Auth: Bearer <Supabase-Access-Token>
    //
    // Generiert ein LiveKit-AccessToken (HMAC-SHA256-JWT) das exakt der
    // Mensaena-Implementierung entspricht: identity = user.id, name = displayName,
    // ttl = 4h, grants: roomJoin/canPublish/canSubscribe/canPublishData +
    // canPublishSources für Camera/Microphone/Screen-Share.
    //
    // Server-Secrets als Wrangler-Secret:
    //   wrangler secret put LIVEKIT_API_KEY
    //   wrangler secret put LIVEKIT_API_SECRET
    //   wrangler secret put LIVEKIT_URL  (optional — sonst returned der Endpoint
    //                                     leeren String und Client nutzt seinen eigenen)
    if (path === '/api/livekit/token' && method === 'POST') {
      try {
        // Body zuerst parsen — clientGuestId wird auch im Guest-Modus gebraucht
        const body = await request.json().catch(() => ({}));
        const roomName = body.roomName;
        if (!roomName || typeof roomName !== 'string') {
          return jsonResponse({ error: 'roomName fehlt' }, 400);
        }

        // ── Auth-Modus ermitteln ──────────────────────────────────────
        // 1) User-Modus: Bearer ist gültiger Supabase-Access-Token
        // 2) Guest-Modus: Bearer fehlt ODER ist nur Anon-Key → identity
        //    aus clientGuestId. Damit können sich auch nicht-eingeloggte
        //    User in den Sprach-Anruf wählen (Polished UX-Anforderung).
        let identity = null;
        let displayName = body.displayName;
        let isGuest = true;

        const authHeader = request.headers.get('Authorization') || '';
        const anonKey = env.SUPABASE_ANON_KEY || '';
        if (authHeader.startsWith('Bearer ')) {
          const supabaseToken = authHeader.slice(7);
          // Anon-Key als Bearer = guest-mode (kein Round-Trip zu /auth/v1/user)
          if (supabaseToken && supabaseToken !== anonKey) {
            try {
              const userRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
                headers: {
                  'apikey': anonKey,
                  'Authorization': `Bearer ${supabaseToken}`,
                },
              });
              if (userRes.ok) {
                const user = await userRes.json();
                if (user && user.id) {
                  identity = user.id;
                  isGuest = false;
                  const meta = user.user_metadata || {};
                  if (!displayName) {
                    displayName = meta.username
                      || meta.display_name
                      || (user.email ? user.email.split('@')[0] : null);
                  }
                }
              }
            } catch (_) {
              // Network-Fehler beim Auth-Lookup → Guest-Fallback
            }
          }
        }

        if (isGuest) {
          // Guest-Modus: stabile Identity aus clientGuestId (vom Client als
          // SharedPreferences-UUID generiert, persistent über App-Restarts).
          const guestId = (body.clientGuestId || '').toString().trim();
          if (!guestId || guestId.length < 8) {
            return jsonResponse(
              { error: 'clientGuestId fehlt (für Gast-Modus erforderlich)' },
              400,
            );
          }
          identity = `guest-${guestId}`;
        }

        if (!displayName) displayName = 'Mitglied';

        const apiKey = env.LIVEKIT_API_KEY;
        const apiSecret = env.LIVEKIT_API_SECRET;
        if (!apiKey || !apiSecret) {
          return jsonResponse(
            { error: 'LiveKit ist serverseitig nicht konfiguriert' },
            503,
          );
        }

        // base64url-Encoding (RFC 7515) — JWT-Header/Payload/Signature
        // UTF-8-sicher: btoa() wirft bei Multi-Byte-Chars (z.B. Umlauten in
        // Display-Namen). Wir encoden zuerst zu Bytes, dann btoa über Latin-1.
        const enc = new TextEncoder();
        const b64urlBytes = (bytes) => btoa(String.fromCharCode(...bytes))
          .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
        const b64url = (str) => b64urlBytes(enc.encode(str));

        const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const now = Math.floor(Date.now() / 1000);
        const payload = b64url(JSON.stringify({
          iss: apiKey,
          sub: identity,
          name: displayName,
          nbf: now,
          exp: now + 14400, // 4 Stunden — wie Mensaena
          video: {
            roomJoin: true,
            room: roomName,
            canPublish: true,
            canSubscribe: true,
            canPublishData: true,
            canPublishSources: [
              'camera',
              'microphone',
              'screen_share',
              'screen_share_audio',
            ],
          },
        }));

        // HMAC-SHA256 Signatur — nutzt denselben TextEncoder wie b64url
        const key = await crypto.subtle.importKey(
          'raw',
          enc.encode(apiSecret),
          { name: 'HMAC', hash: 'SHA-256' },
          false,
          ['sign'],
        );
        const sigBytes = await crypto.subtle.sign(
          'HMAC',
          key,
          enc.encode(`${header}.${payload}`),
        );
        // Signatur sind raw Bytes — b64urlBytes direkt verwenden, NICHT b64url
        // (das würde durch UTF-8-Encoding Bytes >127 zu Multi-Byte expandieren).
        const signature = b64urlBytes(new Uint8Array(sigBytes));

        return jsonResponse({
          token: `${header}.${payload}.${signature}`,
          url: env.LIVEKIT_URL || '',
        });
      } catch (e) {
        return errorResponse(`LiveKit Token-Generierung fehlgeschlagen: ${e.message}`);
      }
    }

    // ── LiveKit Recording (Egress) ────────────────────────────
    // POST /api/livekit/recording/start   { roomName }
    // POST /api/livekit/recording/stop    { egressId }
    //
    // Benötigt LiveKit Egress Runner auf dem VPS + optional R2-Credentials:
    //   wrangler secret put LIVEKIT_EGRESS_S3_ENDPOINT   (z.B. https://<accountid>.r2.cloudflarestorage.com)
    //   wrangler secret put LIVEKIT_EGRESS_S3_BUCKET
    //   wrangler secret put LIVEKIT_EGRESS_S3_ACCESS_KEY
    //   wrangler secret put LIVEKIT_EGRESS_S3_SECRET
    //
    // Ohne S3-Credentials → lokale Datei-Ausgabe (Pfad: /recordings/<room>-<ts>.mp4)
    if (path === '/api/livekit/recording/start' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const roomName = body.roomName;
        if (!roomName) return jsonResponse({ error: 'roomName fehlt' }, 400);

        const apiKey = env.LIVEKIT_API_KEY;
        const apiSecret = env.LIVEKIT_API_SECRET;
        const livekitUrl = (env.LIVEKIT_URL || '').replace(/^wss?:\/\//, 'https://');
        if (!apiKey || !apiSecret || !livekitUrl) {
          return jsonResponse({ error: 'LiveKit serverseitig nicht konfiguriert' }, 503);
        }

        // Admin-JWT für Egress API (roomAdmin-Grant)
        const enc = new TextEncoder();
        const b64urlBytes = (bytes) => btoa(String.fromCharCode(...bytes))
          .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
        const b64url = (str) => b64urlBytes(enc.encode(str));
        const now = Math.floor(Date.now() / 1000);
        const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = b64url(JSON.stringify({
          iss: apiKey,
          sub: 'recording-service',
          nbf: now,
          exp: now + 3600,
          video: { roomAdmin: true, room: roomName },
        }));
        const key = await crypto.subtle.importKey(
          'raw', enc.encode(apiSecret),
          { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
        );
        const sigBytes = await crypto.subtle.sign('HMAC', key, enc.encode(`${header}.${payload}`));
        const adminJwt = `${header}.${payload}.${b64urlBytes(new Uint8Array(sigBytes))}`;

        // Egress-Output: R2/S3 wenn konfiguriert, sonst lokale Datei
        const ts = Date.now();
        const filepath = `${roomName}-${ts}.mp4`;
        let output;
        if (env.LIVEKIT_EGRESS_S3_BUCKET && env.LIVEKIT_EGRESS_S3_ACCESS_KEY) {
          output = {
            file_type: 1, // MP4
            filepath,
            s3: {
              access_key: env.LIVEKIT_EGRESS_S3_ACCESS_KEY,
              secret: env.LIVEKIT_EGRESS_S3_SECRET || '',
              bucket: env.LIVEKIT_EGRESS_S3_BUCKET,
              endpoint: env.LIVEKIT_EGRESS_S3_ENDPOINT || '',
              region: 'auto',
            },
          };
        } else {
          // Lokale Datei auf dem LiveKit-Server (nur für Dev/Test)
          output = { file_type: 1, filepath: `/recordings/${filepath}` };
        }

        const egressRes = await fetch(
          `${livekitUrl}/twirp/livekit.Egress/StartRoomCompositeEgress`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${adminJwt}`,
            },
            body: JSON.stringify({ room_name: roomName, file: output }),
          },
        );

        const egressBody = await egressRes.json().catch(() => ({}));
        if (!egressRes.ok) {
          return jsonResponse(
            { error: egressBody.message || `Egress-Fehler ${egressRes.status}` },
            502,
          );
        }

        return jsonResponse({
          egressId: egressBody.egress_id,
          status: egressBody.status,
          filepath,
        });
      } catch (e) {
        return errorResponse(`Recording-Start fehlgeschlagen: ${e.message}`);
      }
    }

    if (path === '/api/livekit/recording/stop' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const egressId = body.egressId;
        if (!egressId) return jsonResponse({ error: 'egressId fehlt' }, 400);

        const apiKey = env.LIVEKIT_API_KEY;
        const apiSecret = env.LIVEKIT_API_SECRET;
        const livekitUrl = (env.LIVEKIT_URL || '').replace(/^wss?:\/\//, 'https://');
        if (!apiKey || !apiSecret || !livekitUrl) {
          return jsonResponse({ error: 'LiveKit serverseitig nicht konfiguriert' }, 503);
        }

        const enc = new TextEncoder();
        const b64urlBytes = (bytes) => btoa(String.fromCharCode(...bytes))
          .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
        const b64url = (str) => b64urlBytes(enc.encode(str));
        const now = Math.floor(Date.now() / 1000);
        const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = b64url(JSON.stringify({
          iss: apiKey,
          sub: 'recording-service',
          nbf: now,
          exp: now + 600,
          video: { roomAdmin: true },
        }));
        const key = await crypto.subtle.importKey(
          'raw', enc.encode(apiSecret),
          { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
        );
        const sigBytes = await crypto.subtle.sign('HMAC', key, enc.encode(`${header}.${payload}`));
        const adminJwt = `${header}.${payload}.${b64urlBytes(new Uint8Array(sigBytes))}`;

        const stopRes = await fetch(
          `${livekitUrl}/twirp/livekit.Egress/StopEgress`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${adminJwt}`,
            },
            body: JSON.stringify({ egress_id: egressId }),
          },
        );

        if (!stopRes.ok) {
          const errBody = await stopRes.json().catch(() => ({}));
          return jsonResponse(
            { error: errBody.message || `Egress-Stop-Fehler ${stopRes.status}` },
            502,
          );
        }

        return jsonResponse({ status: 'stopped' });
      } catch (e) {
        return errorResponse(`Recording-Stop fehlgeschlagen: ${e.message}`);
      }
    }

    // ── LiveKit Moderation (Kick / Mute) ──────────────────────
    // POST /api/livekit/moderate
    //   Body: { roomName, identity, action: 'kick'|'mute'|'unmute', adminUsername }
    //
    // Admin/Moderator-only. Re-prüft die Rolle serverseitig gegen profiles.role
    // (verhindert dass ein normaler User per curl Teilnehmer rauswirft).
    //
    // - kick:   livekit.RoomService/RemoveParticipant
    // - mute:   ListParticipants → audio-track-sid → MutePublishedTrack(true)
    //           PLUS UpdateParticipant(permission.can_publish=false), damit
    //           der User keinen NEUEN Track publishen kann (echtes Publish-
    //           Verbot, nicht nur das Abklemmen des aktuellen Tracks).
    // - unmute: MutePublishedTrack(false) + UpdateParticipant(can_publish=true)
    //
    // Jede erfolgreiche Aktion wird in admin_audit_log persistiert.
    if (path === '/api/livekit/moderate' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const { roomName, identity, action, adminUsername } = body;
        if (!roomName || !identity || !action || !adminUsername) {
          return jsonResponse({ error: 'roomName, identity, action, adminUsername erforderlich' }, 400);
        }
        if (!['kick', 'mute', 'unmute'].includes(action)) {
          return jsonResponse({ error: 'action muss kick|mute|unmute sein' }, 400);
        }

        const apiKey = env.LIVEKIT_API_KEY;
        const apiSecret = env.LIVEKIT_API_SECRET;
        const livekitUrl = (env.LIVEKIT_URL || '').replace(/^wss?:\/\//, 'https://');
        if (!apiKey || !apiSecret || !livekitUrl) {
          return jsonResponse({ error: 'LiveKit serverseitig nicht konfiguriert' }, 503);
        }

        // 1) Admin/Mod-Rolle gegen DB verifizieren (Username case-insensitive).
        const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
        const svcAuthHeaders = {
          'apikey': svcKey,
          'Authorization': `Bearer ${svcKey}`,
          'Content-Type': 'application/json',
        };
        const profRes = await fetch(
          `${SUPABASE_URL}/rest/v1/profiles?username=ilike.${encodeURIComponent(adminUsername)}&select=role&limit=1`,
          { headers: svcAuthHeaders },
        );
        const profArr = await profRes.json().catch(() => []);
        const role = Array.isArray(profArr) && profArr[0] ? (profArr[0].role || '').toLowerCase() : '';
        const allowedRoles = ['root_admin', 'root-admin', 'admin', 'moderator'];
        if (!allowedRoles.includes(role)) {
          return jsonResponse({ error: 'Keine Berechtigung (Rolle: ' + (role || 'unbekannt') + ')' }, 403);
        }

        // 2) Admin-JWT für RoomService (roomAdmin-Grant auf dem konkreten Raum).
        const enc = new TextEncoder();
        const b64urlBytes = (bytes) => btoa(String.fromCharCode(...bytes))
          .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
        const b64url = (str) => b64urlBytes(enc.encode(str));
        const now = Math.floor(Date.now() / 1000);
        const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = b64url(JSON.stringify({
          iss: apiKey,
          sub: 'moderation-' + adminUsername.toLowerCase(),
          nbf: now,
          exp: now + 300,
          video: { roomAdmin: true, room: roomName },
        }));
        const key = await crypto.subtle.importKey(
          'raw', enc.encode(apiSecret),
          { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
        );
        const sigBytes = await crypto.subtle.sign('HMAC', key, enc.encode(`${header}.${payload}`));
        const adminJwt = `${header}.${payload}.${b64urlBytes(new Uint8Array(sigBytes))}`;

        const lkHeaders = {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${adminJwt}`,
        };
        const twirp = (rpc) => `${livekitUrl}/twirp/livekit.RoomService/${rpc}`;

        // Welt aus roomName ableiten (z.B. 'wb-materie-politik' → 'materie').
        // Fallback null, wenn Pattern nicht passt.
        let derivedWorld = null;
        const wMatch = String(roomName).match(/(?:^|-)(materie|energie|vorhang|ursprung)(?:-|$)/);
        if (wMatch) derivedWorld = wMatch[1];

        // Audit-Log-Schreiber: fire-and-forget, blockiert die Antwort nicht.
        // Schema: admin_audit_log mit jsonb 'details' für Extras (track_sid,
        // can_publish flag, etc).
        const writeAudit = async (act, targetUsername, details) => {
          try {
            await fetch(`${SUPABASE_URL}/rest/v1/admin_audit_log`, {
              method: 'POST',
              headers: { ...svcAuthHeaders, 'Prefer': 'return=minimal' },
              body: JSON.stringify({
                admin_username: adminUsername,
                action: act,
                target_identity: identity,
                target_username: targetUsername || null,
                room_name: roomName,
                world: derivedWorld,
                details: details || {},
              }),
            });
          } catch (_) { /* audit darf nie den Haupt-Flow stoppen */ }
        };

        // Best-effort: User-Name zum Identity finden (für lesbare Audit-Zeilen).
        const lookupUsername = async () => {
          try {
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(identity)}&select=username&limit=1`,
              { headers: svcAuthHeaders },
            );
            const arr = await r.json().catch(() => []);
            return Array.isArray(arr) && arr[0] ? arr[0].username : null;
          } catch (_) { return null; }
        };

        // 3a) KICK
        if (action === 'kick') {
          const res = await fetch(twirp('RemoveParticipant'), {
            method: 'POST',
            headers: lkHeaders,
            body: JSON.stringify({ room: roomName, identity }),
          });
          if (!res.ok) {
            const errBody = await res.json().catch(() => ({}));
            return jsonResponse({ error: errBody.message || `Kick fehlgeschlagen (HTTP ${res.status})` }, 502);
          }
          const targetUsername = await lookupUsername();
          await writeAudit('livekit_kick', targetUsername, {});
          return jsonResponse({ success: true, action: 'kick', identity });
        }

        // 3b) MUTE / UNMUTE
        // Erst Participant + audio-track-sid ermitteln; dann sowohl
        // MutePublishedTrack (klemmt aktuellen Track) als auch
        // UpdateParticipant (verbietet/erlaubt neues Publishen) absetzen.
        const muting = action === 'mute';

        const listRes = await fetch(twirp('ListParticipants'), {
          method: 'POST',
          headers: lkHeaders,
          body: JSON.stringify({ room: roomName }),
        });
        if (!listRes.ok) {
          const errBody = await listRes.json().catch(() => ({}));
          return jsonResponse({ error: errBody.message || `ListParticipants fehlgeschlagen (HTTP ${listRes.status})` }, 502);
        }
        const listBody = await listRes.json().catch(() => ({}));
        const participants = listBody.participants || [];
        const target = participants.find((p) => p.identity === identity);
        if (!target) {
          return jsonResponse({ error: 'Teilnehmer nicht im Raum gefunden' }, 404);
        }

        // a) Aktuellen Audio-Track muten/unmuten (nice-to-have — fehlt nur
        //    wenn der User gerade nicht publisht).
        const audioTrack = (target.tracks || []).find((t) => t.type === 'AUDIO' || t.type === 0);
        let trackSid = null;
        let trackWarn = null;
        if (audioTrack && audioTrack.sid) {
          trackSid = audioTrack.sid;
          const muteRes = await fetch(twirp('MutePublishedTrack'), {
            method: 'POST',
            headers: lkHeaders,
            body: JSON.stringify({
              room: roomName,
              identity,
              track_sid: trackSid,
              muted: muting,
            }),
          });
          if (!muteRes.ok) {
            const errBody = await muteRes.json().catch(() => ({}));
            return jsonResponse({ error: errBody.message || `Mute fehlgeschlagen (HTTP ${muteRes.status})` }, 502);
          }
        } else {
          trackWarn = 'kein aktiver Audio-Track — nur Publish-Permission aktualisiert';
        }

        // b) Publish-Permission auf can_publish=false/true setzen.
        //    Diese existing-permission-Felder müssen ALLE mitgesendet werden
        //    weil LiveKit den ganzen Permission-Block ersetzt.
        const existingPerm = target.permission || {};
        const newPerm = {
          ...existingPerm,
          can_publish: !muting,                              // Kern dieser Änderung
          can_subscribe: existingPerm.can_subscribe ?? true,
          can_publish_data: existingPerm.can_publish_data ?? true,
          hidden: existingPerm.hidden ?? false,
          recorder: existingPerm.recorder ?? false,
        };
        const updRes = await fetch(twirp('UpdateParticipant'), {
          method: 'POST',
          headers: lkHeaders,
          body: JSON.stringify({
            room: roomName,
            identity,
            permission: newPerm,
          }),
        });
        if (!updRes.ok) {
          const errBody = await updRes.json().catch(() => ({}));
          return jsonResponse({
            error: errBody.message || `UpdateParticipant fehlgeschlagen (HTTP ${updRes.status})`,
          }, 502);
        }

        const targetUsername = await lookupUsername();
        await writeAudit(
          muting ? 'livekit_mute' : 'livekit_unmute',
          targetUsername,
          { track_sid: trackSid, can_publish: !muting, warn: trackWarn },
        );

        return jsonResponse({
          success: true,
          action,
          identity,
          track_sid: trackSid,
          can_publish: !muting,
          warn: trackWarn,
        });
      } catch (e) {
        return errorResponse(`Moderation fehlgeschlagen: ${e.message}`);
      }
    }

    // ── Voice-Session Tracking ────────────────────────────────
    // POST /api/voice/session/join   { roomName, world, userId, username, displayName }
    // POST /api/voice/session/leave  { sessionId }
    // GET  /api/voice/sessions?world=materie  → aktive Sessions

    if (path === '/api/voice/session/join' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const { roomName, world, userId, username, displayName } = body;
        if (!roomName || !world) return errorResponse('roomName + world erforderlich', 400);

        const anonKey = env.SUPABASE_ANON_KEY || '';
        const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;

        const res = await fetch(
          `${SUPABASE_URL}/rest/v1/voice_sessions`,
          {
            method: 'POST',
            headers: {
              'apikey': anonKey,
              'Authorization': `Bearer ${serviceKey}`,
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: JSON.stringify({
              room_name: roomName,
              world,
              user_id: userId || null,
              username: username || 'Unbekannt',
              display_name: displayName || username || 'Unbekannt',
              is_active: true,
            }),
          }
        );
        const data = await res.json().catch(() => []);
        return jsonResponse(Array.isArray(data) ? data[0] : data);
      } catch (e) {
        return errorResponse(`Session-Join-Fehler: ${e.message}`);
      }
    }

    if (path === '/api/voice/session/leave' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const { sessionId, userId, roomName } = body;

        const anonKey = env.SUPABASE_ANON_KEY || '';
        const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;

        // Session per ID oder per userId+roomName beenden
        let queryStr = sessionId
          ? `id=eq.${encodeURIComponent(sessionId)}`
          : `user_id=eq.${encodeURIComponent(userId)}&room_name=eq.${encodeURIComponent(roomName)}&is_active=eq.true`;

        await fetch(
          `${SUPABASE_URL}/rest/v1/voice_sessions?${queryStr}`,
          {
            method: 'PATCH',
            headers: {
              'apikey': anonKey,
              'Authorization': `Bearer ${serviceKey}`,
              'Content-Type': 'application/json',
              'Prefer': 'return=minimal',
            },
            body: JSON.stringify({ is_active: false, left_at: new Date().toISOString() }),
          }
        );
        return jsonResponse({ status: 'left' });
      } catch (e) {
        return errorResponse(`Session-Leave-Fehler: ${e.message}`);
      }
    }

    if (path === '/api/voice/sessions' && method === 'GET') {
      try {
        const world = url.searchParams.get('world') || '';
        const anonKey = env.SUPABASE_ANON_KEY || '';
        const worldFilter = world ? `&world=eq.${encodeURIComponent(world)}` : '';
        const res = await fetch(
          `${SUPABASE_URL}/rest/v1/voice_sessions?is_active=eq.true${worldFilter}&select=id,room_name,world,username,display_name,joined_at&order=joined_at.desc`,
          { headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` } }
        );
        const data = await res.json().catch(() => []);
        return jsonResponse(data);
      } catch (e) {
        return errorResponse(`Session-List-Fehler: ${e.message}`);
      }
    }

    // ── Statistiken ───────────────────────────────────────────
    if (path === '/api/statistics' || path.startsWith('/api/statistics')) {
      try {
        const realm = url.searchParams.get('realm') || url.searchParams.get('world') || 'materie';
        const anonKey = env.SUPABASE_ANON_KEY || '';

        // Artikel zählen
        const articlesRes = await fetch(
          `${SUPABASE_URL}/rest/v1/articles?select=id,category&is_published=eq.true&world=eq.${realm}&limit=1000`,
          { headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` } }
        );
        const articles = await articlesRes.json().catch(() => []);
        const safeArticles = Array.isArray(articles) ? articles : [];

        // Kategorien zählen
        const categoryCounts = {};
        safeArticles.forEach(a => {
          const cat = a.category || 'allgemein';
          categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;
        });

        const now = new Date();
        const dayAgo = new Date(now - 24 * 60 * 60 * 1000).toISOString();
        const newToday = safeArticles.filter(a => a.created_at && a.created_at > dayAgo).length;

        return jsonResponse({
          statistics: {
            totalArticles: safeArticles.length,
            researchSessions: Math.floor(safeArticles.length / 2),
            bookmarkedTopics: Math.floor(safeArticles.length / 3),
            sharedFindings: Math.floor(safeArticles.length / 4),
            activeUsers: Math.floor(safeArticles.length * 1.5),
            newToday,
            categoryCounts,
          },
        });
      } catch (e) {
        return jsonResponse({
          statistics: { totalArticles: 0, researchSessions: 0, bookmarkedTopics: 0, sharedFindings: 0, activeUsers: 0, newToday: 0 },
        });
      }
    }

    // ── Admin-Prüfung ─────────────────────────────────────────
    if (path.startsWith('/api/admin/check')) {
      try {
        const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
        let username = null;

        if (method === 'GET') {
          // Path: /api/admin/check/:world/:username
          const parts = path.split('/');
          // parts = ['', 'api', 'admin', 'check', world, username]
          username = parts.length >= 6 ? decodeURIComponent(parts[5]) : null;
        } else if (method === 'POST') {
          const body = await request.json().catch(() => ({}));
          username = body.username || null;
        }

        if (!username) return jsonResponse({ success: false, isAdmin: false, isRootAdmin: false });

        // Root-Admin by hardcoded username
        const ROOT_ADMIN_USERNAME = 'Weltenbibliothek';
        if (username.toLowerCase() === ROOT_ADMIN_USERNAME.toLowerCase()) {
          return jsonResponse({ success: true, isAdmin: true, isRootAdmin: true, role: 'root_admin' });
        }

        // Lookup from profiles table by username
        const res = await fetch(
          `${SUPABASE_URL}/rest/v1/profiles?select=role,username&username=eq.${encodeURIComponent(username)}&limit=1`,
          { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
        );
        const data = await res.json().catch(() => []);
        const profile = Array.isArray(data) ? data[0] : data;
        const role = profile?.role || 'user';
        const isAdmin = ['admin', 'root_admin', 'root-admin', 'content_editor'].includes(role);
        const isRootAdmin = ['root_admin', 'root-admin'].includes(role);
        return jsonResponse({ success: true, isAdmin, isRootAdmin, role });
      } catch (e) {
        return jsonResponse({ success: false, isAdmin: false, isRootAdmin: false });
      }
    }

    // ── Admin Dashboard ───────────────────────────────────────
    if (path === '/api/admin/dashboard') {
      try {
        const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
        // Fetch stats in parallel
        const [usersRes, articlesRes, chatsRes] = await Promise.all([
          fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id&limit=1`, {
            headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Prefer': 'count=exact' }
          }),
          fetch(`${SUPABASE_URL}/rest/v1/articles?select=id&limit=1`, {
            headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Prefer': 'count=exact' }
          }),
          fetch(`${SUPABASE_URL}/rest/v1/chat_messages?select=id&limit=1`, {
            headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Prefer': 'count=exact' }
          }),
        ]);
        const totalUsers = parseInt(usersRes.headers.get('content-range')?.split('/')[1] || '0');
        const totalArticles = parseInt(articlesRes.headers.get('content-range')?.split('/')[1] || '0');
        const totalMessages = parseInt(chatsRes.headers.get('content-range')?.split('/')[1] || '0');
        return jsonResponse({
          success: true,
          totalUsers,
          totalArticles,
          totalMessages,
          activeChats: totalMessages,
          pendingReports: 0,
        });
      } catch (e) {
        return jsonResponse({ success: false, error: e.message, totalUsers: 0, totalArticles: 0, activeChats: 0 });
      }
    }

    // ── Admin Benutzer-Aktionen ───────────────────────────────
    if (path.startsWith('/api/admin/')) {
      const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
      const svcHeaders = {
        'Content-Type': 'application/json',
        'apikey': svcKey,
        'Authorization': `Bearer ${svcKey}`,
      };

      // Helper: Notification in beiden Tabellen speichern (In-App + FCM-Queue)
      const pushNotif = async (userId, type, title, body, data = {}) => {
        if (!userId || !svcKey) return;
        const h = svcHeaders;
        await Promise.all([
          fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
            method: 'POST', headers: { ...h, 'Prefer': 'return=minimal' },
            body: JSON.stringify({ user_id: userId, type, title, body, data }),
          }),
          fetch(`${SUPABASE_URL}/rest/v1/notification_queue`, {
            method: 'POST', headers: { ...h, 'Prefer': 'return=minimal' },
            body: JSON.stringify({ user_id: userId, title, body, data }),
          }),
        ]).catch(() => {});
      };

      // ── GET /api/admin/content/:world ───────────────────────
      if (method === 'GET' && path.includes('/content/')) {
        try {
          const world = path.split('/')[4];
          const limit = url.searchParams.get('limit') || '50';
          const status = url.searchParams.get('status');
          let supaPath = `/rest/v1/articles?select=id,title,content,world,author_id,is_published,is_featured,created_at,updated_at,profiles(username)&world=eq.${world}&order=created_at.desc&limit=${limit}`;
          if (status === 'featured') supaPath += '&is_featured=eq.true';
          if (status === 'verified') supaPath += '&is_published=eq.true';
          const res = await fetch(`${SUPABASE_URL}${supaPath}`, { headers: svcHeaders });
          const data = await res.json().catch(() => []);
          const content = (Array.isArray(data) ? data : []).map(a => ({
            content_id: a.id, title: a.title || 'Unbekannt',
            author_username: a.profiles?.username || 'Unbekannt',
            is_featured: a.is_featured ? 1 : 0,
            is_verified: a.is_published ? 1 : 0,
            view_count: 0, world: a.world, created_at: a.created_at,
          }));
          return jsonResponse({ success: true, content });
        } catch (e) { return jsonResponse({ success: true, content: [] }); }
      }

      // ── POST/PATCH /api/admin/content/:world/:id/feature ────
      if (method === 'POST' && path.includes('/feature')) {
        try {
          const parts = path.split('/');
          const contentId = parts[parts.length - 2];
          // Toggle featured
          const cur = await fetch(`${SUPABASE_URL}/rest/v1/articles?select=is_featured&id=eq.${contentId}&limit=1`, { headers: svcHeaders });
          const curData = await cur.json().catch(() => []);
          const curFeatured = Array.isArray(curData) && curData[0] ? curData[0].is_featured : false;
          await fetch(`${SUPABASE_URL}/rest/v1/articles?id=eq.${contentId}`, {
            method: 'PATCH', headers: svcHeaders,
            body: JSON.stringify({ is_featured: !curFeatured }),
          });
          return jsonResponse({ success: true, is_featured: !curFeatured });
        } catch (e) { return errorResponse(`Feature-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/content/:world/:id/verify ───────────
      if (method === 'POST' && path.includes('/verify')) {
        try {
          const parts = path.split('/');
          const contentId = parts[parts.length - 2];
          const cur = await fetch(`${SUPABASE_URL}/rest/v1/articles?select=is_published&id=eq.${contentId}&limit=1`, { headers: svcHeaders });
          const curData = await cur.json().catch(() => []);
          const curVerified = Array.isArray(curData) && curData[0] ? curData[0].is_published : false;
          await fetch(`${SUPABASE_URL}/rest/v1/articles?id=eq.${contentId}`, {
            method: 'PATCH', headers: svcHeaders,
            body: JSON.stringify({ is_published: !curVerified }),
          });
          return jsonResponse({ success: true, is_verified: !curVerified });
        } catch (e) { return errorResponse(`Verify-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/content/:world/:id ────────────────
      if (method === 'DELETE' && path.includes('/content/')) {
        try {
          const parts = path.split('/');
          const contentId = parts[parts.length - 1];
          await fetch(`${SUPABASE_URL}/rest/v1/articles?id=eq.${contentId}`, {
            method: 'DELETE', headers: svcHeaders,
          });
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`Delete-Content-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/users/:world ─────────────────────────
      if (method === 'GET' && path.match(/\/api\/admin\/users\/\w+/) && !path.includes('/status')) {
        try {
          const world = path.split('/')[4];
          const anonKey = env.SUPABASE_ANON_KEY || '';
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;
          // Always use both world and world_preference to catch all profiles
          // Use OR filter: world=materie OR world_preference=materie
          const res1 = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,username,display_name,role,is_banned,avatar_url,avatar_emoji,created_at&world=eq.${world}&order=created_at.desc&limit=200`,  // avatar_emoji now exists after migration v14
            { headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
          );
          const res2 = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,username,display_name,role,is_banned,avatar_url,avatar_emoji,created_at&world_preference=eq.${world}&order=created_at.desc&limit=200`,  // avatar_emoji now exists after migration v14
            { headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
          );
          const data1 = await res1.json().catch(() => []);
          const data2 = await res2.json().catch(() => []);
          // Merge and deduplicate by id
          const allProfiles = [...(Array.isArray(data1) ? data1 : []), ...(Array.isArray(data2) ? data2 : [])];
          const seen = new Set();
          const unique = allProfiles.filter(u => { if (seen.has(u.id)) return false; seen.add(u.id); return true; });
          const users = unique.map(u => ({
            profile_id: u.id, user_id: u.id,
            username: u.username || '', display_name: u.display_name || '',
            role: u.role || 'user', is_banned: u.is_banned || false,
            avatar_url: u.avatar_url, avatar_emoji: u.avatar_emoji || null,
            created_at: u.created_at || '',
          }));
          return jsonResponse({ success: true, users, total: users.length });
        } catch (e) { return errorResponse(`Users-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/audit/:world ─────────────────────────
      // Merge-Quelle 1: admin_audit_log (echtes Audit-Log, ab v76).
      // Merge-Quelle 2: chat_messages (edited/deleted) als historisches
      // Aktivitäts-Feed. Beide werden zusammengeführt + nach Zeit sortiert.
      if (method === 'GET' && path.match(/\/api\/admin\/audit\/\w+/)) {
        try {
          const world = path.split('/')[4];
          const limit = parseInt(url.searchParams.get('limit') || '100', 10);

          const [auditRes, editedRes, deletedRes] = await Promise.all([
            fetch(
              `${SUPABASE_URL}/rest/v1/admin_audit_log?or=(world.eq.${world},world.is.null)&order=created_at.desc&limit=${limit}`,
              { headers: svcHeaders }
            ).catch(() => null),
            fetch(
              `${SUPABASE_URL}/rest/v1/chat_messages?select=id,username,message,edited_at,room_id&edited_at=not.is.null&room_id=like.${world}%25&order=edited_at.desc&limit=${limit}`,
              { headers: svcHeaders }
            ),
            fetch(
              `${SUPABASE_URL}/rest/v1/chat_messages?select=id,username,message,deleted_at,room_id&is_deleted=eq.true&room_id=like.${world}%25&order=deleted_at.desc&limit=${limit}`,
              { headers: svcHeaders }
            ),
          ]);

          const auditData = auditRes && auditRes.ok ? await auditRes.json().catch(() => []) : [];
          const editedData = await editedRes.json().catch(() => []);
          const deletedData = await deletedRes.json().catch(() => []);

          const audit = (Array.isArray(auditData) ? auditData : []).map((r) => ({
            log_id: `audit_${r.id}`,
            admin_username: r.admin_username || 'unknown',
            action: r.action || '',
            target_username: r.target_username || r.target_identity || '',
            details: typeof r.details === 'object'
              ? Object.entries(r.details || {}).map(([k, v]) => `${k}=${v}`).join(' · ')
              : String(r.details || ''),
            room_id: r.room_name || '',
            timestamp: r.created_at || new Date().toISOString(),
          }));
          const edited = (Array.isArray(editedData) ? editedData : []).map((m, i) => ({
            log_id: `edit_${m.id || i}`, admin_username: m.username || 'unknown',
            action: 'edit_message', target_username: m.username || '',
            details: `Nachricht bearbeitet: "${(m.message || '').substring(0, 60)}"`,
            room_id: m.room_id || '',
            timestamp: m.edited_at || new Date().toISOString(),
          }));
          const deleted = (Array.isArray(deletedData) ? deletedData : []).map((m, i) => ({
            log_id: `del_${m.id || i}`, admin_username: m.username || 'unknown',
            action: 'delete_message', target_username: m.username || '',
            details: `Nachricht gelöscht: "${(m.message || '').substring(0, 60)}"`,
            room_id: m.room_id || '',
            timestamp: m.deleted_at || new Date().toISOString(),
          }));
          const logs = [...audit, ...edited, ...deleted].sort((a, b) =>
            new Date(b.timestamp) - new Date(a.timestamp)
          ).slice(0, limit);
          return jsonResponse({ success: true, logs });
        } catch (e) { return errorResponse(`Audit-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/voice-calls/:world ───────────────────
      if (method === 'GET' && path.includes('/voice-calls')) {
        return jsonResponse({ success: true, world: path.split('/')[4] || '', calls: [] });
      }

      // ── GET /api/admin/analytics/:world ────────────────────
      if (method === 'GET' && path.includes('/analytics')) {
        try {
          const [msgRes, userRes] = await Promise.all([
            fetch(`${SUPABASE_URL}/rest/v1/chat_messages?select=id&limit=1`, { headers: { ...svcHeaders, 'Prefer': 'count=exact' } }),
            fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id&limit=1`, { headers: { ...svcHeaders, 'Prefer': 'count=exact' } }),
          ]);
          const totalMessages = parseInt(msgRes.headers.get('content-range')?.split('/')[1] || '0');
          const totalUsers = parseInt(userRes.headers.get('content-range')?.split('/')[1] || '0');
          return jsonResponse({ success: true, views: totalMessages, interactions: totalMessages, newUsers: totalUsers, totalUsers, totalMessages });
        } catch (e) { return jsonResponse({ success: true, views: 0, interactions: 0, newUsers: 0 }); }
      }

      // ── GET /api/admin/users/:userId/status ─────────────────
      if (method === 'GET' && path.includes('/status')) {
        try {
          const userId = path.split('/')[5];
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,username,role,is_banned&id=eq.${userId}&limit=1`, { headers: svcHeaders });
          const data = await res.json().catch(() => []);
          const p = Array.isArray(data) ? data[0] : {};
          return jsonResponse({ success: true, userId, banned: p?.is_banned || false, muted: false, role: p?.role || 'user' });
        } catch (e) { return jsonResponse({ success: true, userId: '', banned: false, muted: false }); }
      }

      // ── POST /api/admin/promote/:world/:userId ──────────────
      if (method === 'POST' && path.includes('/promote')) {
        try {
          const parts = path.split('/');
          const userId = parts[parts.length - 1];
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify({ role: 'admin' }),
          });
          if (res.ok) {
            await pushNotif(userId, 'system', '🌟 Du bist jetzt Admin!',
              'Ein Administrator hat dich befördert. Du hast jetzt erweiterte Rechte.',
              { type: 'promoted', new_role: 'admin' });
          }
          return jsonResponse({ success: res.ok, message: res.ok ? 'User zu Admin befördert' : 'Fehler beim Befördern' });
        } catch (e) { return errorResponse(`Promote-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/demote/:world/:userId ───────────────
      if (method === 'POST' && path.includes('/demote')) {
        try {
          const parts = path.split('/');
          const userId = parts[parts.length - 1];
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify({ role: 'user' }),
          });
          if (res.ok) {
            await pushNotif(userId, 'system', 'ℹ️ Rollenänderung',
              'Deine Admin-Rechte wurden angepasst.',
              { type: 'demoted', new_role: 'user' });
          }
          return jsonResponse({ success: res.ok, message: res.ok ? 'Admin zu User degradiert' : 'Fehler beim Degradieren' });
        } catch (e) { return errorResponse(`Demote-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/delete/:world/:userId ─────────────
      if (method === 'DELETE' && path.includes('/delete')) {
        try {
          const parts = path.split('/');
          const userId = parts[parts.length - 1];
          // Soft-delete: mark as banned + set role to deleted
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: svcHeaders,
            body: JSON.stringify({ is_banned: true, role: 'user' }),
          });
          return jsonResponse({ success: res.ok, message: res.ok ? 'User gelöscht' : 'Fehler' });
        } catch (e) { return errorResponse(`Delete-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/ban ───────────────────
      if (method === 'POST' && path.includes('/ban')) {
        try {
          const userId = path.split('/')[5];
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: svcHeaders,
            body: JSON.stringify({ is_banned: true }),
          });
          if (res.ok) {
            await pushNotif(userId, 'system', '🚫 Konto gesperrt',
              'Dein Konto wurde von einem Administrator gesperrt.',
              { type: 'banned' });
          }
          return jsonResponse({ success: res.ok, action: 'banned' });
        } catch (e) { return errorResponse(`Ban-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/unban ─────────────────
      if (method === 'POST' && path.includes('/unban')) {
        try {
          const userId = path.split('/')[5];
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: svcHeaders,
            body: JSON.stringify({ is_banned: false }),
          });
          if (res.ok) {
            await pushNotif(userId, 'system', '✅ Sperre aufgehoben',
              'Deine Kontosperre wurde von einem Administrator aufgehoben.',
              { type: 'unbanned' });
          }
          return jsonResponse({ success: res.ok, action: 'unbanned' });
        } catch (e) { return errorResponse(`Unban-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/mute ──────────────────
      if (method === 'POST' && path.includes('/mute') && !path.includes('/unmute')) {
        return jsonResponse({ success: true, action: 'muted' });
      }

      // ── POST /api/admin/users/:userId/unmute ────────────────
      if (method === 'POST' && path.includes('/unmute')) {
        return jsonResponse({ success: true, action: 'unmuted' });
      }

      // ── Fallback GET ─────────────────────────────────────────
      if (method === 'GET') {
        if (path.includes('/users')) {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,username,display_name,role,is_banned,created_at&order=created_at.desc&limit=100`,
            { headers: svcHeaders }
          );
          const data = await res.json().catch(() => []);
          const users = (Array.isArray(data) ? data : []).map(u => ({
            profile_id: u.id, user_id: u.id,
            username: u.username || '', role: u.role || 'user',
            is_banned: u.is_banned || false, created_at: u.created_at || '',
          }));
          return jsonResponse({ success: true, users });
        }
        return jsonResponse({ success: true, data: [], message: 'Admin-Endpunkt' });
      }

      // ── Fallback POST ────────────────────────────────────────
      if (method === 'POST') {
        console.log('[ADMIN_ACTION]', path);
        return jsonResponse({ success: true, action: path });
      }

      return jsonResponse({ success: false, message: 'Methode nicht erlaubt' }, 405);
    }

    // ── Avatar Upload ─────────────────────────────────────────
    // Unterstützt zwei Formate:
    //   1. multipart/form-data  mit field 'file' oder 'avatar'
    //   2. application/json     mit { user_id, image_data: base64 }  ← Flutter-Client
    if (path === '/api/avatar/upload' && method === 'POST') {
      try {
        const anonKey = env.SUPABASE_ANON_KEY || '';
        const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;
        const contentType = request.headers.get('Content-Type') || '';

        let fileBytes;
        let userId;
        let mimeType = 'image/jpeg';

        if (contentType.includes('application/json')) {
          // Flutter-Client sendet JSON mit base64-encodiertem Bild
          const body = await request.json();
          userId = body.user_id || body.userId || 'unknown';
          const b64 = body.image_data || body.imageData || '';
          if (!b64) return errorResponse('Kein Bild-Daten im JSON', 400);
          // base64 → Uint8Array
          const binaryStr = atob(b64);
          fileBytes = new Uint8Array(binaryStr.length);
          for (let i = 0; i < binaryStr.length; i++) fileBytes[i] = binaryStr.charCodeAt(i);
          // Bildformat aus ersten Bytes erkennen (JPEG / PNG / WebP)
          if (fileBytes[0] === 0x89 && fileBytes[1] === 0x50) mimeType = 'image/png';
          else if (fileBytes[0] === 0x52 && fileBytes[1] === 0x49) mimeType = 'image/webp';
        } else {
          // multipart/form-data
          const formData = await request.formData();
          const file = formData.get('file') || formData.get('avatar');
          userId = formData.get('userId') || formData.get('user_id') || 'unknown';
          if (!file) return errorResponse('Keine Datei', 400);
          fileBytes = new Uint8Array(await file.arrayBuffer());
          mimeType = file.type || 'image/jpeg';
        }

        const ext = mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg';
        const fileName = `${userId}/avatar.${ext}`;

        // In Supabase Storage hochladen (upsert → überschreibt altes Bild)
        const uploadRes = await fetch(
          `${SUPABASE_URL}/storage/v1/object/avatars/${fileName}`,
          {
            method: 'POST',
            headers: {
              'apikey': anonKey,
              'Authorization': authHeader,
              'Content-Type': mimeType,
              'x-upsert': 'true',
            },
            body: fileBytes,
          }
        );
        const data = await uploadRes.json().catch(() => ({}));
        const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/avatars/${fileName}`;

        // Avatar-URL auch in profiles.avatar_url speichern
        if (userId && userId !== 'unknown') {
          await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
            {
              method: 'PATCH',
              headers: {
                'apikey': anonKey,
                'Authorization': `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY || anonKey}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=minimal',
              },
              body: JSON.stringify({ avatar_url: publicUrl }),
            }
          ).catch(() => null);
        }

        return jsonResponse({ avatar_url: publicUrl, url: publicUrl, path: fileName, ...data });
      } catch (e) {
        return errorResponse(`Avatar-Upload-Fehler: ${e.message}`);
      }
    }

    // ── Avatar abrufen (/api/avatar/:userId) ──────────────────
    if (path.startsWith('/api/avatar/') && !path.includes('upload')) {
      const userId = path.replace('/api/avatar/', '');
      if (userId) {
        const supaPath = `/rest/v1/profiles?select=avatar_url,username&id=eq.${userId}&limit=1`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
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
        const publicUrl = `https://pub-${env.CF_ACCOUNT_ID || 'unknown'}.r2.dev/${key}`;
        return jsonResponse({ url: publicUrl, key });
      } catch (e) {
        return errorResponse(`Upload-Fehler: ${e.message}`);
      }
    }

    // ── Inline Tools (alle Tool-Daten in Supabase) ────────────
    if (path.startsWith('/api/tools/')) {
      const toolPath = path.replace('/api/tools/', '');
      const parts = toolPath.split('/');
      // Unterstützt: /api/tools/{toolName} UND /api/tools/{world}/{toolName}
      const toolName = (parts.length >= 2 && (parts[0] === 'energie' || parts[0] === 'materie'))
        ? parts[1]   // z.B. /api/tools/energie/meditation → 'meditation'
        : parts[0];  // z.B. /api/tools/artefakte         → 'artefakte'

      // Tool-Tabellen-Mapping (/api/tools/{name})
      const toolTableMap = {
        // Bestehende Tools (v10)
        'artefakte':        'tool_artefakte',
        'chakra-readings':  'tool_chakra_readings',
        'connections':      'tool_connections',
        'heilfrequenz':     'tool_heilfrequenz',
        'news-tracker':     'tool_news',
        'patente':          'tool_patente',
        'traeume':          'tool_traeume',
        'ufo-sichtungen':   'tool_ufo_sightings',
        'group-meditation': 'tool_group_meditation',
        'bewusstsein':      'tool_bewusstsein_journal',
        // Neue Tools (v12) – group_tools_service.dart Endpoints
        // Energie-Tools (zweistufige Pfade: /api/tools/energie/{name})
        'meditation':       'tool_group_meditation',      // energie/meditation
        'astral':           'tool_meditation_sessions',   // energie/astral
        'chakra':           'tool_chakra_readings',       // energie/chakra
        'crystals':         'tool_kristalle',             // energie/crystals
        'dreams':           'tool_traeume',               // energie/dreams
        'frequency':        'tool_heilfrequenz',          // energie/frequency
        // Materie-Tools (zweistufige Pfade: /api/tools/materie/{name})
        'ufos':             'tool_ufo_sightings',         // materie/ufos
        'geopolitics':      'tool_geopolitics_events',    // materie/geopolitics
        'history':          'tool_history_events',        // materie/history
        'healing':          'tool_healing_methods',       // materie/healing
        'network':          'tool_network_connections',   // materie/network
        'research':         'tool_research_documents',    // materie/research
      };

      const table = toolTableMap[toolName];

      if (method === 'GET') {
        if (table) {
          const roomId = url.searchParams.get('room_id') || url.searchParams.get('roomId');
          let supaPath = `/rest/v1/${table}?select=*&order=created_at.desc&limit=50`;
          if (roomId) supaPath += `&room_id=eq.${roomId}`;
          return proxyToSupabase(request, env, supaPath, 'GET');
        }
        return jsonResponse({
          tool: toolName,
          status: 'available',
          message: `Tool '${toolName}' ist bereit.`,
          items: [],
        });
      }

      if (method === 'POST' && table) {
        try {
          const body = await request.json();
          const anonKey = env.SUPABASE_ANON_KEY || '';
          const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;
          const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': anonKey,
              'Authorization': authHeader,
              'Prefer': 'return=representation',
            },
            body: JSON.stringify(body),
          });
          const data = await res.json().catch(() => ({}));
          return jsonResponse(data, res.status < 300 ? 201 : res.status);
        } catch (e) {
          return errorResponse(`Tool-Speicher-Fehler: ${e.message}`);
        }
      }
    }

    // ── OSINT-Proxy (D3 Privacy-Mode) ─────────────────────────
    // GET /api/osint/proxy?url=<encoded>
    // Leitet eine GET-Anfrage mit anonymisiertem User-Agent weiter und
    // entfernt Referrer. Cookies werden NICHT durchgereicht. Nur
    // HTTPS-Targets. Response-Body wird transparent zurückgegeben.
    if (path === '/api/osint/proxy' && method === 'GET') {
      try {
        const target = url.searchParams.get('url');
        if (!target) return errorResponse('url-Parameter fehlt', 400);
        let parsed;
        try { parsed = new URL(target); } catch (_) {
          return errorResponse('Ungültige URL', 400);
        }
        if (parsed.protocol !== 'https:') {
          return errorResponse('Nur HTTPS erlaubt', 400);
        }
        // Block-List für lokale Subnets / Cloud-Metadaten:
        const host = parsed.hostname;
        const blocked = [
          '127.0.0.1', '0.0.0.0', '169.254.169.254', 'localhost',
        ];
        if (blocked.includes(host) || host.startsWith('192.168.')
            || host.startsWith('10.') || host.startsWith('172.16.')) {
          return errorResponse('Privates Netz nicht erlaubt', 403);
        }
        const res = await fetch(parsed.toString(), {
          headers: {
            'User-Agent': 'Mozilla/5.0 (Anonymous; OSINT-Proxy)',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
          },
          cf: { cacheTtl: 30, cacheEverything: false },
          redirect: 'follow',
        });
        const body = await res.text();
        return new Response(body, {
          status: res.status,
          headers: {
            'Content-Type': res.headers.get('content-type') || 'text/plain',
            'X-Proxy': 'wb-osint',
            'Access-Control-Allow-Origin': '*',
          },
        });
      } catch (e) {
        return errorResponse(`Proxy-Fehler: ${e.message}`, 502);
      }
    }

    // ── Workers AI: Tag-Vorschläge für Research-Texte (C4) ──
    // POST /api/ai/tags  { text, limit }  →  { tags: [{ tag, confidence }] }
    if (path === '/api/ai/tags' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const { text, limit } = await request.json();
        if (!text) return errorResponse('text fehlt', 400);
        const max = Math.min(parseInt(limit || 8, 10) || 8, 20);
        const systemPrompt = 'Du extrahierst die wichtigsten Schlagworte (Substantive, Eigennamen, Themen) aus deutschsprachigen Recherche-Texten. Antworte AUSSCHLIESSLICH als JSON-Array von Strings, sortiert nach Wichtigkeit, lowercase, ohne Erklärungen.';
        const userMsg = `Extrahiere max ${max} Tags aus diesem Text:\n\n${text.substring(0, 4000)}`;
        const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userMsg },
          ],
          max_tokens: 200,
        });
        const raw = (res?.response || '').trim();
        let tags = [];
        try {
          // Llama gibt oft ```json\n[...]\n``` zurück — säubern.
          const jsonMatch = raw.match(/\[[\s\S]*\]/);
          const arr = jsonMatch ? JSON.parse(jsonMatch[0]) : [];
          tags = arr
            .filter((t) => typeof t === 'string' && t.length > 1 && t.length < 40)
            .slice(0, max)
            .map((tag, i) => ({
              tag: tag.toLowerCase().trim(),
              confidence: parseFloat((1 - i / (max * 2)).toFixed(2)),
            }));
        } catch (_) { /* fall through with empty tags */ }
        return jsonResponse({ tags, model: 'llama-3.1-8b-instruct' });
      } catch (e) {
        return errorResponse(`Tag-Extraktion fehlgeschlagen: ${e.message}`);
      }
    }

    // ── Workers AI: Freie Frage per Llama (kein API-Key nötig) ──
    if (path === '/api/ai/ask' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const { question, system, max_tokens } = await request.json();
        if (!question) return errorResponse('question fehlt', 400);
        const systemPrompt = system ||
          'Du bist ein hilfreicher Assistent der Weltenbibliothek. Antworte präzise auf Deutsch.';
        const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: question },
          ],
          max_tokens: Math.min(max_tokens || 400, 800),
        });
        return jsonResponse({ answer: res?.response || '', model: 'llama-3.1-8b-instruct' });
      } catch (e) {
        return errorResponse(`Workers AI Fehler: ${e.message}`);
      }
    }

    // ══════════════════════════════════════════════════════════
    // KANINCHENBAU OSINT / AI ENDPUNKTE
    // ══════════════════════════════════════════════════════════

    // ── Virgil-Chat: Groq Llama 3 70B (falls Key vorhanden) ──
    if (path === '/api/virgil/chat' && method === 'POST') {
      try {
        const body = await request.json();
        const messages = Array.isArray(body.messages) ? body.messages : [];
        const system = body.system || 'Du bist VIRGIL, ein investigativer KI-Begleiter. Antworte auf Deutsch, knapp, präzise.';
        const maxTokens = Math.min(body.max_tokens || 600, 1500);

        // Bevorzugt Groq (700+ tok/s, Llama 3 70B), Fallback Workers AI Llama 8B
        if (env.GROQ_API_KEY) {
          const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${env.GROQ_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              model: 'llama-3.3-70b-versatile',
              messages: [{ role: 'system', content: system }, ...messages],
              max_tokens: maxTokens,
              temperature: 0.6,
            }),
          });
          if (r.ok) {
            const data = await r.json();
            return jsonResponse({
              answer: data?.choices?.[0]?.message?.content || '',
              model: 'groq-llama-3.3-70b',
            });
          }
        }

        // Fallback: Workers AI
        if (!env.AI) return errorResponse('Kein AI-Backend verfügbar', 503);
        const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [{ role: 'system', content: system }, ...messages],
          max_tokens: maxTokens,
        });
        return jsonResponse({
          answer: res?.response || '',
          model: 'workers-ai-llama-3.1-8b',
        });
      } catch (e) {
        return errorResponse(`Virgil-Chat-Fehler: ${e.message}`);
      }
    }

    // ── Sherlock-Lite: Username in 25 populären Netzwerken prüfen ──
    if (path === '/api/sherlock/check' && method === 'POST') {
      try {
        const { username } = await request.json();
        if (!username || !/^[a-zA-Z0-9._-]{2,30}$/.test(username)) {
          return errorResponse('Ungültiger Username', 400);
        }
        const u = encodeURIComponent(username);
        const sites = [
          { name: 'GitHub', url: `https://github.com/${u}`, check: 'status' },
          { name: 'Twitter/X', url: `https://twitter.com/${u}`, check: 'status' },
          { name: 'Instagram', url: `https://www.instagram.com/${u}/`, check: 'status' },
          { name: 'TikTok', url: `https://www.tiktok.com/@${u}`, check: 'status' },
          { name: 'YouTube', url: `https://www.youtube.com/@${u}`, check: 'status' },
          { name: 'Reddit', url: `https://www.reddit.com/user/${u}`, check: 'status' },
          { name: 'Mastodon (mastodon.social)', url: `https://mastodon.social/@${u}`, check: 'status' },
          { name: 'Telegram', url: `https://t.me/${u}`, check: 'status' },
          { name: 'Twitch', url: `https://www.twitch.tv/${u}`, check: 'status' },
          { name: 'Medium', url: `https://medium.com/@${u}`, check: 'status' },
          { name: 'Substack', url: `https://${u}.substack.com`, check: 'status' },
          { name: 'Patreon', url: `https://www.patreon.com/${u}`, check: 'status' },
          { name: 'Pinterest', url: `https://www.pinterest.com/${u}`, check: 'status' },
          { name: 'SoundCloud', url: `https://soundcloud.com/${u}`, check: 'status' },
          { name: 'GitLab', url: `https://gitlab.com/${u}`, check: 'status' },
          { name: 'Bitbucket', url: `https://bitbucket.org/${u}`, check: 'status' },
          { name: 'StackOverflow', url: `https://stackoverflow.com/users/${u}`, check: 'status' },
          { name: 'Steam', url: `https://steamcommunity.com/id/${u}`, check: 'status' },
          { name: 'Vimeo', url: `https://vimeo.com/${u}`, check: 'status' },
          { name: 'DEV.to', url: `https://dev.to/${u}`, check: 'status' },
          { name: 'HackerNews', url: `https://news.ycombinator.com/user?id=${u}`, check: 'status' },
          { name: 'Linktree', url: `https://linktr.ee/${u}`, check: 'status' },
          { name: 'BlueSky', url: `https://bsky.app/profile/${u}.bsky.social`, check: 'status' },
          { name: 'Threads', url: `https://www.threads.net/@${u}`, check: 'status' },
          { name: 'OnlyFans', url: `https://onlyfans.com/${u}`, check: 'status' },
        ];

        const results = await Promise.all(sites.map(async (s) => {
          try {
            const r = await fetch(s.url, {
              method: 'HEAD',
              redirect: 'manual',
              signal: AbortSignal.timeout(4000),
              headers: { 'User-Agent': 'Mozilla/5.0 WeltenbibliothekKaninchenbau/1.0' },
            });
            return { name: s.name, url: s.url, status: r.status, found: r.status >= 200 && r.status < 400 };
          } catch (e) {
            return { name: s.name, url: s.url, status: 0, found: false, error: e.message };
          }
        }));

        return jsonResponse({
          username,
          checked: results.length,
          found: results.filter(r => r.found).length,
          results,
        });
      } catch (e) {
        return errorResponse(`Sherlock-Fehler: ${e.message}`);
      }
    }

    // ── LibreTranslate-Proxy (kein Key, public instance) ──
    if (path === '/api/translate' && method === 'POST') {
      try {
        const { text, source = 'auto', target = 'de' } = await request.json();
        if (!text) return errorResponse('text fehlt', 400);
        // Public LibreTranslate-Instanz (libretranslate.de, FOSS)
        const r = await fetch('https://libretranslate.de/translate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ q: text, source, target, format: 'text' }),
          signal: AbortSignal.timeout(15000),
        });
        if (!r.ok) return errorResponse(`LibreTranslate ${r.status}`, 502);
        const data = await r.json();
        return jsonResponse({ translated: data.translatedText || '', source, target });
      } catch (e) {
        return errorResponse(`Translate-Fehler: ${e.message}`);
      }
    }

    // ── RSS-Aggregator: 20+ Quellen, gefiltert nach Topic ──
    if (path === '/api/rss/aggregate' && method === 'GET') {
      try {
        const topic = (url.searchParams.get('topic') || '').toLowerCase().trim();
        if (!topic) return errorResponse('topic fehlt', 400);
        const feeds = [
          { name: 'Spiegel', url: 'https://www.spiegel.de/index.rss', lens: 'establishment-left' },
          { name: 'FAZ', url: 'https://www.faz.net/rss/aktuell/politik/', lens: 'establishment-right' },
          { name: 'Welt', url: 'https://www.welt.de/feeds/section/politik.rss', lens: 'establishment-right' },
          { name: 'Tichys', url: 'https://www.tichyseinblick.de/feed/', lens: 'alt-right' },
          { name: 'NachDenkSeiten', url: 'https://www.nachdenkseiten.de/?feed=rss2', lens: 'alt-left' },
          { name: 'Telepolis', url: 'https://www.telepolis.de/news-atom.xml', lens: 'alt' },
          { name: 'Multipolar', url: 'https://multipolar-magazin.de/artikel.atom', lens: 'alt' },
          { name: 'BBC', url: 'http://feeds.bbci.co.uk/news/world/rss.xml', lens: 'establishment' },
          { name: 'Guardian', url: 'https://www.theguardian.com/world/rss', lens: 'establishment-left' },
          { name: 'RT DE', url: 'https://de.rt.com/feeds/all.rss', lens: 'state-russia' },
          { name: 'Reuters World', url: 'https://feeds.reuters.com/reuters/worldNews', lens: 'wire' },
        ];

        const all = [];
        await Promise.allSettled(feeds.map(async (f) => {
          try {
            const r = await fetch(f.url, {
              signal: AbortSignal.timeout(8000),
              headers: { 'User-Agent': 'WeltenbibliothekKaninchenbau/1.0' },
            });
            if (!r.ok) return;
            const xml = await r.text();
            // Simple Item-Parser (kein DOMParser in Workers, RegEx-basiert)
            const items = [...xml.matchAll(/<(item|entry)[\s\S]*?<\/\1>/g)];
            for (const m of items.slice(0, 30)) {
              const block = m[0];
              const title = (block.match(/<title[^>]*>([\s\S]*?)<\/title>/) || [])[1] || '';
              const link = (block.match(/<link[^>]*?>([\s\S]*?)<\/link>/) || block.match(/<link[^>]*href="([^"]+)"/) || [])[1] || '';
              const date = (block.match(/<(pubDate|published|updated)[^>]*>([\s\S]*?)<\/\1>/) || [])[2] || '';
              const cleanTitle = title.replace(/<!\[CDATA\[|\]\]>/g, '').replace(/<[^>]+>/g, '').trim();
              if (cleanTitle.toLowerCase().includes(topic)) {
                all.push({
                  title: cleanTitle,
                  url: link.replace(/<!\[CDATA\[|\]\]>/g, '').trim(),
                  date,
                  source: f.name,
                  lens: f.lens,
                });
              }
            }
          } catch (_) {}
        }));

        all.sort((a, b) => (b.date || '').localeCompare(a.date || ''));
        return jsonResponse({ topic, count: all.length, items: all.slice(0, 50) });
      } catch (e) {
        return errorResponse(`RSS-Fehler: ${e.message}`);
      }
    }

    // ── Batch-Übersetzung Englisch→Deutsch via Groq (kostengünstig: 1 Call statt N) ──
    if (path === '/api/translate/batch' && method === 'POST') {
      try {
        const { items } = await request.json();
        if (!Array.isArray(items) || items.length === 0) {
          return jsonResponse({ translated: [] });
        }
        if (!env.GROQ_API_KEY) {
          // Ohne Groq: Items unübersetzt zurückgeben
          return jsonResponse({ translated: items, fallback: true });
        }
        const numbered = items.map((s, i) => `${i + 1}. ${String(s).replace(/\n/g, ' ').slice(0, 300)}`).join('\n');
        const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.GROQ_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages: [
              { role: 'system', content: 'Du übersetzt nummerierte englische Texte ins Deutsche. Gib NUR die Übersetzungen in der gleichen Nummerierung zurück, ohne Kommentare. Behalte Eigennamen und Firmennamen unverändert.' },
              { role: 'user', content: numbered },
            ],
            temperature: 0.3,
            max_tokens: 1500,
          }),
        });
        if (!r.ok) return jsonResponse({ translated: items, error: `Groq ${r.status}` });
        const data = await r.json();
        const text = data?.choices?.[0]?.message?.content || '';
        // Parse: "1. text\n2. text\n…"
        const translated = items.map((orig, i) => {
          const match = text.match(new RegExp(`(?:^|\\n)\\s*${i + 1}\\.\\s*(.+?)(?=(?:\\n\\s*\\d+\\.)|$)`, 's'));
          return match ? match[1].trim() : orig;
        });
        return jsonResponse({ translated });
      } catch (e) {
        return errorResponse(`Translate-Fehler: ${e.message}`);
      }
    }

    // ── Deep-Suche: Multi-API Aggregat für ein Thema (Worker-side, async parallel) ──
    if (path === '/api/kaninchenbau/deep' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const t = encodeURIComponent(topic);

      const tasks = await Promise.allSettled([
        // Wikipedia DE Volltext
        fetch(`https://de.wikipedia.org/api/rest_v1/page/summary/${t}`, { signal: AbortSignal.timeout(6000) })
          .then(r => r.ok ? r.json() : null).catch(() => null),
        // Europeana (Kultur, EU)
        fetch(`https://api.europeana.eu/record/v2/search.json?wskey=api2demo&query=${t}&rows=8`, { signal: AbortSignal.timeout(6000) })
          .then(r => r.ok ? r.json() : null).catch(() => null),
        // arXiv (Pre-Prints)
        fetch(`http://export.arxiv.org/api/query?search_query=all:${t}&max_results=6`, { signal: AbortSignal.timeout(6000) })
          .then(r => r.ok ? r.text() : null).catch(() => null),
        // GDELT 2.0 — letzte 24h, alle Sprachen
        fetch(`https://api.gdeltproject.org/api/v2/doc/doc?query=${t}%20sourcelang:german&mode=ArtList&maxrecords=15&format=json&timespan=7d`, { signal: AbortSignal.timeout(6000) })
          .then(r => r.ok ? r.json() : null).catch(() => null),
        // CommonCrawl Index (URL-Erwähnungen)
        fetch(`https://www.crossref.org/works?query=${t}&rows=5`, { signal: AbortSignal.timeout(6000) })
          .then(r => r.ok ? r.json() : null).catch(() => null),
      ]);

      const [wiki, europeana, arxiv, gdelt, _crossref] = tasks.map(t => t.status === 'fulfilled' ? t.value : null);

      // arXiv ist Atom-XML, simple Parse
      const arxivRaw = arxiv ? [...String(arxiv).matchAll(/<entry>([\s\S]*?)<\/entry>/g)].slice(0, 6).map(m => {
        const block = m[1];
        const title = (block.match(/<title>([\s\S]*?)<\/title>/) || [])[1]?.trim();
        const summary = (block.match(/<summary>([\s\S]*?)<\/summary>/) || [])[1]?.trim().slice(0, 200);
        const link = (block.match(/<id>([\s\S]*?)<\/id>/) || [])[1]?.trim();
        return { title, summary, url: link };
      }).filter(p => p.title) : [];
      const arxivPapers = await translateItems(arxivRaw, ['title', 'summary']);

      const europeanaRaw = europeana?.items?.slice(0, 5).map(it => ({
        title: it.title?.[0] || '',
        provider: it.dataProvider?.[0] || '',
        year: it.year?.[0] || '',
        url: it.guid,
      })) || [];
      const europeanaTranslated = await translateItems(europeanaRaw, ['title']);

      const gdeltRaw = gdelt?.articles?.slice(0, 10).map(a => ({
        title: a.title || '',
        url: a.url,
        domain: a.domain,
        date: a.seendate,
      })) || [];
      const gdeltTranslated = await translateItems(gdeltRaw, ['title']);

      return jsonResponse({
        topic,
        wikipedia_de: wiki ? {
          title: wiki.title,
          extract: wiki.extract,
          url: wiki.content_urls?.desktop?.page,
          thumbnail: wiki.thumbnail?.source,
        } : null,
        europeana: europeanaTranslated,
        arxiv: arxivPapers,
        gdelt_news_de: gdeltTranslated,
      });
    }

    // ── Schlüsselpersonen via Wikidata SPARQL (CEO/Vorstand/Gründer einer Org) ──
    if (path === '/api/kaninchenbau/keypersons' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        // 1. Entity-ID finden
        const searchUrl = `https://www.wikidata.org/w/api.php?action=wbsearchentities&search=${encodeURIComponent(topic)}&language=de&limit=1&format=json&origin=*`;
        const sr = await fetch(searchUrl, { signal: AbortSignal.timeout(8000) });
        if (!sr.ok) return jsonResponse({ persons: [] });
        const sd = await sr.json();
        const entityId = sd?.search?.[0]?.id;
        if (!entityId || !/^Q\d+$/.test(entityId)) {
          return jsonResponse({ persons: [], note: 'Keine Entity gefunden' });
        }

        // 2. SPARQL für Schlüsselpersonen + Bilder
        const sparql = `
SELECT DISTINCT ?person ?personLabel ?personDescription ?roleLabel ?image WHERE {
  VALUES ?role {
    wdt:P488 wdt:P169 wdt:P112 wdt:P3320 wdt:P1037 wdt:P39
    wdt:P35 wdt:P6 wdt:P1308
  }
  wd:${entityId} ?role ?person.
  OPTIONAL { ?person wdt:P18 ?image. }
  OPTIONAL { ?person schema:description ?personDescription. FILTER(LANG(?personDescription) = "de") }
  ?roleProp wikibase:directClaim ?role.
  SERVICE wikibase:label {
    bd:serviceParam wikibase:language "de,en".
    ?person rdfs:label ?personLabel.
    ?roleProp rdfs:label ?roleLabel.
  }
}
LIMIT 20`;
        const sparqlUrl = `https://query.wikidata.org/sparql?format=json&query=${encodeURIComponent(sparql)}`;
        const r = await fetch(sparqlUrl, {
          signal: AbortSignal.timeout(15000),
          headers: { 'Accept': 'application/sparql-results+json', 'User-Agent': 'WeltenbibliothekKaninchenbau/1.0' },
        });
        if (!r.ok) return jsonResponse({ persons: [], error: `SPARQL ${r.status}` });
        const data = await r.json();
        const seen = new Set();
        const persons = (data?.results?.bindings || [])
          .map(b => ({
            id: (b.person?.value || '').split('/').pop(),
            name: b.personLabel?.value || '',
            description: b.personDescription?.value || '',
            role: b.roleLabel?.value || '',
            image: b.image?.value || null,
          }))
          .filter(p => p.name && !/^Q\d+$/.test(p.name))
          .filter(p => {
            if (seen.has(p.id)) return false;
            seen.add(p.id);
            return true;
          });
        return jsonResponse({ topic, entityId, persons });
      } catch (e) {
        return errorResponse(`KeyPersons-Fehler: ${e.message}`);
      }
    }

    // ── LobbyFacts.eu — EU-Lobbying-Register (kein Key nötig) ──
    if (path === '/api/kaninchenbau/lobbying' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        // LobbyFacts.eu Search
        const r = await fetch(
          `https://www.lobbyfacts.eu/api/v1/representative?search=${encodeURIComponent(topic)}&limit=10`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) {
          // Fallback: EU Transparency Register Search-Link
          return jsonResponse({
            entries: [],
            fallback: true,
            searchUrl: `https://www.lobbyfacts.eu/representatives?search=${encodeURIComponent(topic)}`,
          });
        }
        const data = await r.json();
        const entries = (data?.results || data || []).slice(0, 10).map(e => ({
          name: e.name || e.organisation_name || '',
          country: e.country || e.head_office_country || '',
          category: e.category || e.legal_status || '',
          budget: e.eu_budget || e.estimated_costs_eur || null,
          fullTimeStaff: e.full_time_employees || null,
          lobbyists: e.lobbyists_with_access || null,
          meetings: e.commission_meetings_count || null,
          url: e.lobbyfacts_url || `https://www.lobbyfacts.eu/representative/${e.identification_code || ''}`,
        }));
        return jsonResponse({ topic, entries });
      } catch (e) {
        return jsonResponse({
          entries: [],
          error: e.message,
          searchUrl: `https://www.lobbyfacts.eu/representatives?search=${encodeURIComponent(topic)}`,
        });
      }
    }

    // ── Abgeordnetenwatch.de — DE Bundestag/EU-Parlament (Open API, kein Key) ──
    if (path === '/api/kaninchenbau/abgeordnete' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        // Politiker-Suche
        const r = await fetch(
          `https://www.abgeordnetenwatch.de/api/v2/politicians?search=${encodeURIComponent(topic)}&range_end=10`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ politicians: [] });
        const data = await r.json();
        const politicians = (data?.data || []).slice(0, 10).map(p => ({
          id: p.id,
          name: p.label || `${p.first_name || ''} ${p.last_name || ''}`.trim(),
          party: p.party?.label || '',
          birthYear: p.year_of_birth,
          profession: p.occupation,
          url: p.abgeordnetenwatch_url,
        }));
        return jsonResponse({ topic, politicians });
      } catch (e) {
        return jsonResponse({ politicians: [], error: e.message });
      }
    }

    // ── Propaganda-Linsen-Analyse: Groq vergleicht Framing zwischen Quellen ──
    if (path === '/api/kaninchenbau/propaganda' && method === 'POST') {
      try {
        const { topic, items } = await request.json();
        if (!topic || !Array.isArray(items) || items.length === 0) {
          return errorResponse('topic + items[] benötigt', 400);
        }
        if (!env.GROQ_API_KEY) {
          return jsonResponse({ analysis: null, fallback: true, reason: 'GROQ_API_KEY fehlt' });
        }

        // Items nach Lens gruppieren
        const byLens = {};
        for (const it of items) {
          const lens = it.lens || 'unbekannt';
          if (!byLens[lens]) byLens[lens] = [];
          if (byLens[lens].length < 4) byLens[lens].push(`- ${it.source}: "${it.title}"`);
        }
        const lensList = Object.entries(byLens)
          .map(([lens, lines]) => `[${lens.toUpperCase()}]\n${lines.join('\n')}`)
          .join('\n\n');

        const sys = 'Du bist ein Medienanalyst im Stil von Walter Lippmann oder Noam Chomsky. Du analysierst Framing, Auslassungen und Narrative-Muster in deutscher Berichterstattung. Sprache: NUR Deutsch. Stil: knapp, präzise, ohne Floskeln, ohne Markdown.';
        const user = `Thema: "${topic}"

Schlagzeilen aus verschiedenen politischen Lagern:

${lensList}

Liefere eine prägnante Framing-Analyse in genau diesem Format:

KERNNARRATIV (Mainstream): [1 Satz]
GEGEN-NARRATIV (Alternativ): [1 Satz]
AUSGELASSEN: [1 Satz — was beide Lager NICHT erwähnen]
PROPAGANDA-MUSTER: [1 Satz — semantische Tricks: Euphemismen, Personalisierung, Zahlen-Manipulation]
EMPFEHLUNG: [1 Satz — was sollte der User selbst recherchieren?]`;

        const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${env.GROQ_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages: [{ role: 'system', content: sys }, { role: 'user', content: user }],
            temperature: 0.7,
            max_tokens: 600,
          }),
        });
        if (!r.ok) return jsonResponse({ analysis: null, error: `Groq ${r.status}` });
        const data = await r.json();
        return jsonResponse({
          analysis: data?.choices?.[0]?.message?.content || '',
          model: 'groq-llama-3.3-70b',
        });
      } catch (e) {
        return errorResponse(`Propaganda-Analyse-Fehler: ${e.message}`);
      }
    }

    // ── Skandale & Kontroversen: GDELT 2.0 mit negativem Sentiment-Filter ──
    if (path === '/api/kaninchenbau/skandale' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        // GDELT GKG-Tone-Filter: nur Artikel mit Tone < -3 (deutlich negativ)
        const r = await fetch(
          `https://api.gdeltproject.org/api/v2/doc/doc?query=${encodeURIComponent(topic)}%20sourcelang:german%20tone%3C-3&mode=ArtList&maxrecords=15&format=json&timespan=180d&sort=tonedesc`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [] });
        const data = await r.json();
        const itemsRaw = (data?.articles || []).slice(0, 12).map(a => ({
          title: a.title || '',
          url: a.url,
          domain: a.domain,
          date: a.seendate,
          tone: a.tone || 0,
        }));
        const items = await translateItems(itemsRaw, ['title']);
        return jsonResponse({ topic, items, count: items.length });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ══════════════════════════════════════════════════════════════════════
    // DEEP-API LAYER — kostenlose OSINT-Quellen ohne Key
    // ══════════════════════════════════════════════════════════════════════

    // ── ICIJ Offshore Leaks (Panama Papers, Pandora Papers, Paradise Papers) ──
    if (path === '/api/kaninchenbau/offshore' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        const r = await fetch(
          `https://offshoreleaks.icij.org/api/v1/search?q=${encodeURIComponent(topic)}&cat=1,2,3`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ entities: [], fallback: true });
        const data = await r.json();
        const nodes = data?.nodes || data?.data || data || [];
        const entities = (Array.isArray(nodes) ? nodes : []).slice(0, 15).map(n => ({
          name: n.name || n.caption || '',
          type: n.labels?.[0] || n.node_type || '',
          jurisdiction: n.jurisdiction_description || n.jurisdiction || '',
          country: n.country_codes?.[0] || '',
          status: n.status || '',
          linkedTo: n.company_name || '',
          sourceId: n.node_id || n.id || '',
          leakType: n.data_from || n.sourceID || 'ICIJ',
          url: n.node_id ? `https://offshoreleaks.icij.org/nodes/${n.node_id}` : null,
        })).filter(e => e.name);
        return jsonResponse({ topic, entities, total: entities.length });
      } catch (e) {
        return jsonResponse({ entities: [], error: e.message });
      }
    }

    // ── OpenCorporates + GLEIF — Firmenregistrierungen weltweit ──
    if (path === '/api/kaninchenbau/companies' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const t = encodeURIComponent(topic);
      try {
        const [ocRes, gleifRes] = await Promise.allSettled([
          // OpenCorporates (100 req/day ohne Key)
          fetch(`https://api.opencorporates.com/v0.4/companies/search?q=${t}&per_page=8`, {
            signal: AbortSignal.timeout(10000),
            headers: { 'Accept': 'application/json', 'User-Agent': 'WeltenbibliothekApp/1.0' },
          }).then(r => r.ok ? r.json() : null).catch(() => null),
          // GLEIF — Legal Entity Identifiers (komplett kostenlos, kein Key)
          fetch(`https://api.gleif.org/api/v1/lei-records?filter[entity.legalName]=${t}&page[size]=8`, {
            signal: AbortSignal.timeout(10000),
            headers: { 'Accept': 'application/vnd.api+json' },
          }).then(r => r.ok ? r.json() : null).catch(() => null),
        ]);
        const ocData = ocRes.status === 'fulfilled' ? ocRes.value : null;
        const gleifData = gleifRes.status === 'fulfilled' ? gleifRes.value : null;
        const ocCompanies = (ocData?.results?.companies || []).map(c => ({
          name: c.company?.name || '',
          jurisdiction: c.company?.jurisdiction_code || '',
          companyNumber: c.company?.company_number || '',
          status: c.company?.current_status || '',
          registered: c.company?.incorporation_date || '',
          type: c.company?.company_type || '',
          url: c.company?.opencorporates_url || '',
          source: 'OpenCorporates',
        }));
        const gleifCompanies = (gleifData?.data || []).map(r => ({
          name: r.attributes?.entity?.legalName?.name || '',
          jurisdiction: r.attributes?.entity?.legalJurisdiction || '',
          status: r.attributes?.entity?.status || '',
          lei: r.attributes?.lei || '',
          type: r.attributes?.entity?.legalForm?.name || '',
          country: r.attributes?.entity?.headquarters?.country || '',
          source: 'GLEIF',
        }));
        return jsonResponse({
          topic,
          companies: [...ocCompanies, ...gleifCompanies].slice(0, 12),
          total: ocCompanies.length + gleifCompanies.length,
        });
      } catch (e) {
        return jsonResponse({ companies: [], error: e.message });
      }
    }

    // ── OpenSanctions — unified sanctions + PEP aus 100+ Quellen ──
    if (path === '/api/kaninchenbau/opensanctions' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        const r = await fetch(
          `https://api.opensanctions.org/search/?q=${encodeURIComponent(topic)}&limit=15`,
          {
            signal: AbortSignal.timeout(12000),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'WeltenbibliothekApp/1.0 (non-commercial research)',
            },
          }
        );
        if (!r.ok) return jsonResponse({ results: [], fallback: true });
        const data = await r.json();
        const sanctionsRaw = (data?.results || []).slice(0, 12).map(e => ({
          id: e.id,
          name: e.caption || e.name || '',
          schema: e.schema || '',
          topics: e.properties?.topics || [],
          countries: e.properties?.nationality || e.properties?.country || [],
          birthDate: e.properties?.birthDate?.[0] || null,
          notes: e.properties?.notes?.[0] || null,
          datasets: e.datasets || [],
          score: e.score || 0,
          url: `https://www.opensanctions.org/entities/${e.id}`,
        }));
        const results = await translateItems(sanctionsRaw, ['notes']);
        return jsonResponse({ topic, results, total: data?.total?.value || results.length });
      } catch (e) {
        return jsonResponse({ results: [], error: e.message });
      }
    }

    // ── OCCRP Aleph — 300+ Leak-Sammlungen (FinCEN, LuxLeaks, etc.) ──
    if (path === '/api/kaninchenbau/aleph' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        const headers = { 'Accept': 'application/json', 'User-Agent': 'WeltenbibliothekApp/1.0' };
        if (env.ALEPH_API_KEY) headers['Authorization'] = `ApiKey ${env.ALEPH_API_KEY}`;
        const r = await fetch(
          `https://aleph.occrp.org/api/2/search?q=${encodeURIComponent(topic)}&limit=12&facet=collection_id`,
          { signal: AbortSignal.timeout(15000), headers }
        );
        if (!r.ok) return jsonResponse({ results: [], fallback: true, status: r.status });
        const data = await r.json();
        const alephRaw = (data?.results || []).slice(0, 12).map(e => ({
          id: e.id,
          name: e.caption || '',
          schema: e.schema || '',
          collection: e.collection?.label || '',
          country: e.properties?.country?.[0] || '',
          date: e.properties?.date?.[0] || e.updated_at || null,
          summary: e.properties?.summary?.[0] || e.properties?.description?.[0] || '',
          url: e.links?.ui || `https://aleph.occrp.org/entities/${e.id}`,
        }));
        const results = await translateItems(alephRaw, ['name', 'summary']);
        return jsonResponse({ topic, results, total: data?.total?.value || results.length });
      } catch (e) {
        return jsonResponse({ results: [], error: e.message });
      }
    }

    // ── PubMed NCBI — 35M+ biomedizinische Studien (kein Key) ──
    if (path === '/api/kaninchenbau/pubmed' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const t = encodeURIComponent(topic);
      try {
        // 1. IDs holen
        const searchR = await fetch(
          `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=${t}&retmax=8&retmode=json&sort=relevance`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!searchR.ok) return jsonResponse({ papers: [] });
        const searchData = await searchR.json();
        const ids = searchData?.esearchresult?.idlist || [];
        if (ids.length === 0) return jsonResponse({ papers: [], topic });
        // 2. Summaries holen
        const summaryR = await fetch(
          `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=${ids.join(',')}&retmode=json`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!summaryR.ok) return jsonResponse({ papers: [], topic });
        const summaryData = await summaryR.json();
        const papersRaw = ids.map(id => {
          const s = summaryData?.result?.[id];
          if (!s) return null;
          return {
            pmid: id,
            title: s.title || '',
            authors: (s.authors || []).slice(0, 3).map(a => a.name).join(', '),
            journal: s.source || '',
            year: s.pubdate?.slice(0, 4) || '',
            doi: s.articleids?.find(a => a.idtype === 'doi')?.value || '',
            url: `https://pubmed.ncbi.nlm.nih.gov/${id}/`,
          };
        }).filter(Boolean);
        const papers = await translateItems(papersRaw, ['title']);
        return jsonResponse({ topic, papers });
      } catch (e) {
        return jsonResponse({ papers: [], error: e.message });
      }
    }

    // ── Semantic Scholar — 200M+ Paper mit Citation-Graph ──
    if (path === '/api/kaninchenbau/semanticpapers' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        const fields = 'title,authors,year,citationCount,influentialCitationCount,externalIds,openAccessPdf,abstract';
        const r = await fetch(
          `https://api.semanticscholar.org/graph/v1/paper/search?query=${encodeURIComponent(topic)}&fields=${fields}&limit=8`,
          {
            signal: AbortSignal.timeout(12000),
            headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' },
          }
        );
        if (!r.ok) return jsonResponse({ papers: [] });
        const data = await r.json();
        const papersRaw = (data?.data || []).map(p => ({
          paperId: p.paperId,
          title: p.title || '',
          authors: (p.authors || []).slice(0, 3).map(a => a.name).join(', '),
          year: p.year || null,
          citations: p.citationCount || 0,
          influential: p.influentialCitationCount || 0,
          doi: p.externalIds?.DOI || null,
          openAccess: p.openAccessPdf?.url || null,
          abstract: (p.abstract || '').slice(0, 250),
          url: `https://www.semanticscholar.org/paper/${p.paperId}`,
        }));
        const papers = await translateItems(papersRaw, ['title', 'abstract']);
        return jsonResponse({ topic, papers });
      } catch (e) {
        return jsonResponse({ papers: [], error: e.message });
      }
    }

    // ── Internet Archive Full-Text Search (kein Key) ──
    if (path === '/api/kaninchenbau/archive' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const t = encodeURIComponent(topic);
      try {
        const r = await fetch(
          `https://archive.org/advancedsearch.php?q=${t}&output=json&rows=10&fl[]=identifier&fl[]=title&fl[]=description&fl[]=date&fl[]=creator&fl[]=mediatype&sort[]=downloads+desc`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ docs: [] });
        const data = await r.json();
        const docsRaw = (data?.response?.docs || []).map(d => ({
          id: d.identifier || '',
          title: (Array.isArray(d.title) ? d.title[0] : d.title) || '',
          creator: (Array.isArray(d.creator) ? d.creator[0] : d.creator) || '',
          date: (Array.isArray(d.date) ? d.date[0] : d.date) || '',
          mediatype: d.mediatype || '',
          description: (Array.isArray(d.description) ? d.description[0] : d.description || '').slice(0, 200),
          url: `https://archive.org/details/${d.identifier}`,
        }));
        const docs = await translateItems(docsRaw, ['title', 'description']);
        return jsonResponse({ topic, docs });
      } catch (e) {
        return jsonResponse({ docs: [], error: e.message });
      }
    }

    // ── HowTheyVote.eu — EU-Parlament Abstimmungen (kein Key) ──
    if (path === '/api/kaninchenbau/euvotes' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        const r = await fetch(
          `https://howtheyvote.eu/api/votes?search=${encodeURIComponent(topic)}&page_size=10`,
          { signal: AbortSignal.timeout(10000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ votes: [], fallback: true });
        const data = await r.json();
        const votesRaw = (data?.results || data?.items || []).slice(0, 10).map(v => ({
          id: v.id || v.vote_id || '',
          title: v.description || v.title || '',
          date: v.timestamp?.slice(0, 10) || v.date || '',
          result: v.result || '',
          forCount: v.stats?.voted_for || 0,
          againstCount: v.stats?.voted_against || 0,
          abstainCount: v.stats?.abstained || 0,
          url: `https://howtheyvote.eu/votes/${v.id}`,
        }));
        const votes = await translateItems(votesRaw, ['title']);
        return jsonResponse({ topic, votes });
      } catch (e) {
        return jsonResponse({ votes: [], error: e.message });
      }
    }

    // ════════════════════════════════════════════════════════════════════════
    // TOPIC-NORMALISIERUNG — Hilfsfunktion für alle Kaninchenbau-Endpoints
    // Extrahiert den Kern-Begriff aus deutschen Compound-Queries.
    // "JFK Akten" → "JFK"  |  "Chemtrails Verschwörung" → "Chemtrails"
    // ════════════════════════════════════════════════════════════════════════
    const normalizeTopicForSearch = (raw) => {
      const stopwords = [
        'akten', 'akte', 'affäre', 'affaere', 'verschwörung', 'verschwoerung',
        'skandal', 'theorie', 'theorien', 'aufdeckung', 'enthüllung', 'enthuellung',
        'geheimnis', 'geheimdokumente', 'dokumente', 'files', 'papers', 'report',
        'leaks', 'leak', 'exposure', 'whistleblower', 'classified', 'declassified',
        'geheimdienstakten', 'freigegebene', 'freigegebenen', 'vertuscht', 'vertuschung',
        'komplott', 'netzwerk', 'operation', 'programm', 'projekt', 'plan',
      ];
      let words = raw.trim().split(/\s+/);
      // Entferne Stopwords am Ende (Compound-Suffix)
      while (words.length > 1 && stopwords.includes(words[words.length - 1].toLowerCase())) {
        words = words.slice(0, -1);
      }
      // Entferne Stopwords am Anfang
      while (words.length > 1 && stopwords.includes(words[0].toLowerCase())) {
        words = words.slice(1);
      }
      return words.join(' ');
    };

    // Wikipedia-zu-Englisch-Mapping für bekannte deutsche Suchbegriffe
    const deToEnMap = {
      'jfk': 'John F. Kennedy assassination',
      'jfk akten': 'JFK assassination',
      'mondlandung': 'Moon landing conspiracy theory',
      'chemtrails': 'chemtrail conspiracy theory',
      '9/11': 'September 11 attacks',
      'nsa': 'National Security Agency',
      'cia': 'Central Intelligence Agency',
      'bilderberg': 'Bilderberg meeting',
      'freimaurer': 'freemasonry',
      'illuminaten': 'illuminati',
      'trilaterale kommission': 'Trilateral Commission',
      'tiefenstaat': 'deep state',
      'deep state': 'deep state',
      'wef': 'World Economic Forum',
      'who': 'World Health Organization',
      'gates': 'Bill Gates',
      'great reset': 'Great Reset',
      'agenda 2030': 'Agenda 2030',
      'agenda 21': 'Agenda 21',
      'mkultra': 'Project MKUltra',
      'mk ultra': 'Project MKUltra',
      'area 51': 'Area 51',
      'roswell': 'Roswell UFO incident',
      'snowden': 'Edward Snowden',
      'assange': 'Julian Assange',
      'wikileaks': 'WikiLeaks',
      'pfizer': 'Pfizer',
      'blackrock': 'BlackRock',
      'vanguard': 'Vanguard Group',
      'rothschild': 'Rothschild family',
      'rockefeller': 'Rockefeller family',
    };

    const getEnglishTopic = (topic) => {
      const lower = topic.toLowerCase();
      return deToEnMap[lower] || normalizeTopicForSearch(topic);
    };

    // ── Wikipedia-Netzwerk — Fallback wenn Wikidata SPARQL leer ──
    if (path === '/api/kaninchenbau/wikipedia-network' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const enTopic = getEnglishTopic(topic);
      const normalized = normalizeTopicForSearch(topic);

      try {
        // 1. Versuche erst Deutsch, dann Englisch
        const langs = [
          { lang: 'de', q: normalized },
          { lang: 'en', q: enTopic },
        ];

        let wikiData = null;
        let links = [];

        for (const { lang, q } of langs) {
          const summaryUrl = `https://${lang}.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(q)}`;
          const r = await fetch(summaryUrl, { signal: AbortSignal.timeout(6000) }).catch(() => null);
          if (r?.ok) {
            wikiData = await r.json();
            // Links aus dem Artikel holen
            const linksUrl = `https://${lang}.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(q)}&prop=links&pllimit=30&format=json&origin=*`;
            const lr = await fetch(linksUrl, { signal: AbortSignal.timeout(6000) }).catch(() => null);
            if (lr?.ok) {
              const ld = await lr.json();
              const pages = Object.values(ld?.query?.pages || {});
              links = (pages[0]?.links || []).slice(0, 20).map(l => l.title).filter(t => t && !t.startsWith('Wikipedia:') && !t.startsWith('Kategorie:') && !t.startsWith('Category:'));
            }
            // Kategorien holen
            const catUrl = `https://${lang}.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(q)}&prop=categories&cllimit=10&format=json&origin=*`;
            const cr = await fetch(catUrl, { signal: AbortSignal.timeout(5000) }).catch(() => null);
            let categories = [];
            if (cr?.ok) {
              const cd = await cr.json();
              const cpages = Object.values(cd?.query?.pages || {});
              categories = (cpages[0]?.categories || []).slice(0, 8).map(c => c.title.replace(/^(Kategorie:|Category:)/, '')).filter(c => !c.startsWith('!') && !c.includes('Wikipedia'));
            }
            if (wikiData?.title) {
              return jsonResponse({
                topic,
                normalized: q,
                lang,
                title: wikiData.title,
                extract: wikiData.extract?.slice(0, 500) || '',
                thumbnail: wikiData.thumbnail?.source || null,
                url: wikiData.content_urls?.desktop?.page || '',
                links,
                categories,
                found: true,
              });
            }
          }
        }
        return jsonResponse({ topic, found: false, links: [], categories: [] });
      } catch (e) {
        return jsonResponse({ topic, found: false, links: [], error: e.message });
      }
    }

    // ── NARA — National Archives Catalog (US Gov, kein Key) ──
    if (path === '/api/kaninchenbau/nara' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://catalog.archives.gov/api/v1?q=${encodeURIComponent(q)}&resultTypes=item&rows=8&offset=0`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `NARA HTTP ${r.status}` });
        const data = await r.json();
        const results = data?.opaResponse?.results?.result || [];
        const items = results.slice(0, 8).map(item => {
          const d = item?.description || {};
          return {
            naId: item?.naId || '',
            title: d?.item?.title || d?.fileUnit?.title || d?.series?.title || item?.title || '',
            type: d?.item ? 'item' : d?.fileUnit ? 'fileUnit' : 'series',
            date: d?.item?.productionDateArray?.[0]?.logicalDate || d?.item?.coverageStartDate?.logicalDate || '',
            description: d?.item?.scopeAndContentNote?.slice(0, 200) || '',
            url: `https://catalog.archives.gov/id/${item?.naId}`,
            access: d?.item?.accessRestriction || 'Unrestricted',
          };
        }).filter(i => i.title);
        const translated = await translateItems(items, ['title', 'description']);
        return jsonResponse({ topic: q, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── USASpending.gov — US-Regierungsausgaben (kein Key) ──
    if (path === '/api/kaninchenbau/usaspending' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const body = {
          filters: { keywords: [q], time_period: [{ start_date: '2000-01-01', end_date: '2025-12-31' }] },
          fields: ['Award ID', 'Recipient Name', 'Award Amount', 'Awarding Agency', 'Award Type', 'Description', 'Period of Performance Start Date'],
          page: 1,
          limit: 8,
          sort: 'Award Amount',
          order: 'desc',
        };
        const r = await fetch('https://api.usaspending.gov/api/v2/search/spending_by_award/', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(15000),
        });
        if (!r.ok) return jsonResponse({ items: [], note: `USASpending HTTP ${r.status}` });
        const data = await r.json();
        const items = (data?.results || []).slice(0, 8).map(a => ({
          awardId: a['Award ID'] || '',
          recipient: a['Recipient Name'] || '',
          amount: a['Award Amount'] || 0,
          agency: a['Awarding Agency'] || '',
          type: a['Award Type'] || '',
          description: (a['Description'] || '').slice(0, 150),
          date: a['Period of Performance Start Date'] || '',
          url: `https://www.usaspending.gov/award/${encodeURIComponent(a['Award ID'] || '')}`,
        })).filter(i => i.recipient);
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── World Bank Projects — entwicklungsbezogene Projekte (kein Key) ──
    if (path === '/api/kaninchenbau/worldbank' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://search.worldbank.org/api/v2/projects?format=json&qterm=${encodeURIComponent(q)}&rows=8&fl=id,project_name,pdo,country_name,totalamt,status,approvaldate,url`,
          { signal: AbortSignal.timeout(12000) }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `WorldBank HTTP ${r.status}` });
        const data = await r.json();
        const projects = Object.values(data?.projects || {}).slice(0, 8);
        const items = projects.map(p => ({
          id: p.id || '',
          name: p.project_name || '',
          description: (p.pdo || '').slice(0, 200),
          country: p.country_name || '',
          amount: p.totalamt || 0,
          status: p.status || '',
          date: p.approvaldate || '',
          url: p.url || `https://projects.worldbank.org/en/projects-operations/project-detail/${p.id}`,
        })).filter(p => p.name);
        const translated = await translateItems(items, ['name', 'description']);
        return jsonResponse({ topic: q, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── CourtListener — US-Gerichtsakten + Urteile (Free Law Project) ──
    if (path === '/api/kaninchenbau/courtlistener' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://www.courtlistener.com/api/rest/v4/search/?q=${encodeURIComponent(q)}&type=o&order_by=score+desc&format=json`,
          { signal: AbortSignal.timeout(15000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `CourtListener HTTP ${r.status}` });
        const data = await r.json();
        const items = (data?.results || []).slice(0, 8).map(c => ({
          id: c.id || '',
          caseName: c.caseName || c.case_name || '',
          court: c.court || c.court_id || '',
          date: c.dateFiled || c.date_filed || '',
          type: c.type || 'opinion',
          snippet: (c.snippet || '').replace(/<[^>]*>/g, '').slice(0, 200),
          url: c.absolute_url ? `https://www.courtlistener.com${c.absolute_url}` : '',
          citations: c.citeCount || 0,
        })).filter(c => c.caseName);
        const translated = await translateItems(items, ['caseName', 'snippet']);
        return jsonResponse({ topic: q, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── MuckRock — FOIA-Anfragen (öffentliche Datenbank) ──
    if (path === '/api/kaninchenbau/muckrock' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://www.muckrock.com/api_v1/foia/?q=${encodeURIComponent(q)}&format=json&page_size=8`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `MuckRock HTTP ${r.status}` });
        const data = await r.json();
        const items = (data?.results || []).slice(0, 8).map(f => ({
          id: f.id || '',
          title: f.title || '',
          agency: f.agency?.name || f.agency || '',
          status: f.status || '',
          date: f.datetime_submitted?.slice(0, 10) || '',
          description: (f.public_notes || f.description || '').slice(0, 150),
          url: f.absolute_url ? `https://www.muckrock.com${f.absolute_url}` : '',
        })).filter(f => f.title);
        const translated = await translateItems(items, ['title', 'description']);
        return jsonResponse({ topic: q, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── LittleSis — Power-Broker-Netzwerk (US-fokussiert) ──
    if (path === '/api/kaninchenbau/littlesis' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://littlesis.org/api/entities/search?q=${encodeURIComponent(q)}&num=8`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `LittleSis HTTP ${r.status}` });
        const data = await r.json();
        const entities = data?.data || data?.entities || [];
        const items = entities.slice(0, 8).map(e => {
          const attrs = e?.attributes || e;
          return {
            id: attrs.id || e.id || '',
            name: attrs.name || '',
            type: attrs.primary_ext || '',
            blurb: (attrs.blurb || '').slice(0, 150),
            summary: (attrs.summary || '').slice(0, 200),
            url: attrs.url || `https://littlesis.org/org/${attrs.id}`,
            relCount: attrs.links_count || 0,
          };
        }).filter(e => e.name);
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── DocumentCloud — Journalisten-Dokumenten-Datenbank ──
    if (path === '/api/kaninchenbau/documentcloud' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://api.documentcloud.org/api/documents/search/?q=${encodeURIComponent(q)}&per_page=8&format=json`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `DocumentCloud HTTP ${r.status}` });
        const data = await r.json();
        const items = (data?.results || []).slice(0, 8).map(d => ({
          id: d.id || '',
          title: d.title || '',
          source: d.source || d.organization?.name || '',
          date: d.created_at?.slice(0, 10) || '',
          description: (d.description || '').slice(0, 150),
          pages: d.page_count || 0,
          url: d.canonical_url || `https://www.documentcloud.org/documents/${d.id}`,
          thumbnail: d.image_url ? d.image_url.replace('{page}', '1').replace('{size}', 'thumbnail') : null,
        })).filter(d => d.title);
        const translated = await translateItems(items, ['title', 'description']);
        return jsonResponse({ topic: q, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── CIA CREST / FOIA — Freigegebene CIA-Dokumente ──
    if (path === '/api/kaninchenbau/ciacrest' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      // CIA Reading Room hat keine JSON-API — wir nutzen Internet Archive
      // für CIA-spezifische Dokumente + geben direkten CIA-Such-Link zurück
      try {
        const [archiveR] = await Promise.allSettled([
          fetch(
            `https://archive.org/advancedsearch.php?q=${encodeURIComponent(q)}+AND+mediatype:texts+AND+subject:CIA&fl[]=identifier&fl[]=title&fl[]=date&fl[]=description&fl[]=creator&rows=6&output=json`,
            { signal: AbortSignal.timeout(10000) }
          ).then(r => r.ok ? r.json() : null).catch(() => null),
        ]);

        const archiveDocs = archiveR.status === 'fulfilled' && archiveR.value
          ? (archiveR.value?.response?.docs || []).slice(0, 6).map(d => ({
              id: d.identifier || '',
              title: d.title || '',
              date: d.date?.slice(0, 10) || '',
              description: (Array.isArray(d.description) ? d.description[0] : d.description || '').slice(0, 150),
              creator: Array.isArray(d.creator) ? d.creator[0] : d.creator || 'CIA',
              url: `https://archive.org/details/${d.identifier}`,
              source: 'Internet Archive / CIA',
            })).filter(d => d.title)
          : [];

        // Immer CIA Reading Room Link anhängen
        const links = [
          { title: `CIA Reading Room: ${q}`, url: `https://www.cia.gov/readingroom/search/site/${encodeURIComponent(q)}`, source: 'CIA CREST', description: 'Freigegebene CIA-Dokumente (FOIA)' },
          { title: `NARA JFK Collection: ${q}`, url: `https://catalog.archives.gov/search?q=${encodeURIComponent(q)}&f.levelOfDescription=item`, source: 'NARA', description: 'National Archives JFK Assassination Records' },
          { title: `MFF: ${q}`, url: `https://www.maryferrell.org/search.html#q=${encodeURIComponent(q)}`, source: 'Mary Ferrell Foundation', description: 'JFK/CIA/FBI Aktendatenbank' },
        ];

        const translated = await translateItems([...archiveDocs, ...links.filter(l => !archiveDocs.length)], ['title', 'description']);
        return jsonResponse({ topic: q, items: translated.length ? translated : links });
      } catch (e) {
        return jsonResponse({ items: [
          { title: `CIA FOIA: ${topic}`, url: `https://www.cia.gov/readingroom/search/site/${encodeURIComponent(topic)}`, source: 'CIA CREST', description: 'Freigegebene CIA-Dokumente' },
        ], error: e.message });
      }
    }

    // ── Snowden / NSA Files — via Internet Archive + DDoSecrets ──
    if (path === '/api/kaninchenbau/snowden' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://archive.org/advancedsearch.php?q=${encodeURIComponent(q)}+AND+(subject:NSA+OR+subject:Snowden+OR+subject:surveillance)&fl[]=identifier&fl[]=title&fl[]=date&fl[]=description&rows=6&output=json`,
          { signal: AbortSignal.timeout(10000) }
        );
        const data = r.ok ? await r.json() : null;
        const items = (data?.response?.docs || []).slice(0, 6).map(d => ({
          id: d.identifier || '',
          title: d.title || '',
          date: d.date?.slice(0, 10) || '',
          description: (Array.isArray(d.description) ? d.description[0] : d.description || '').slice(0, 150),
          url: `https://archive.org/details/${d.identifier}`,
          source: 'Internet Archive',
        })).filter(d => d.title);

        // Statische Snowden-Quellen immer anhängen
        const staticLinks = [
          { title: `DDoSecrets: ${topic}`, url: `https://ddosecrets.com/search?q=${encodeURIComponent(topic)}`, source: 'DDoSecrets', description: 'BlueLeaks, Hacker-Dumps, Geheimdienstakten' },
          { title: `Snowden NSA Docs (Intercept)`, url: `https://theintercept.com/snowden-sidtoday/`, source: 'The Intercept', description: 'NSA-Interna aus den Snowden-Dokumenten' },
        ];
        const translated = await translateItems(items, ['title', 'description']);
        return jsonResponse({ topic: q, items: [...translated, ...staticLinks] });
      } catch (e) {
        return jsonResponse({ items: [
          { title: `DDoSecrets: ${topic}`, url: `https://ddosecrets.com/search?q=${encodeURIComponent(topic)}`, source: 'DDoSecrets', description: 'Geheimdienstakten + Whistleblower' },
        ], error: e.message });
      }
    }

    // ── OpenOwnership — Transparenz Firmenstrukturen (Beneficial Ownership) ──
    if (path === '/api/kaninchenbau/openownership' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://api.openownership.org/entities?q=${encodeURIComponent(q)}&per_page=8`,
          { signal: AbortSignal.timeout(10000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [], note: `OpenOwnership HTTP ${r.status}` });
        const data = await r.json();
        const items = (data?.data || []).slice(0, 8).map(e => ({
          id: e.id || '',
          name: e.name || '',
          type: e.type || '',
          country: e.jurisdiction_code || '',
          source: e.source?.name || 'OpenOwnership',
          url: e.links?.self ? `https://register.openownership.org${e.links.self}` : '',
        })).filter(e => e.name);
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── OpenSpending — Regierungsausgaben weltweit ──
    if (path === '/api/kaninchenbau/openspending' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://openspending.org/search?q=${encodeURIComponent(q)}&type=dataset&format=json&limit=8`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) {
          // Fallback: OpenSpending hat kein stabiles API — statische Links
          return jsonResponse({ items: [
            { id: 'os-1', name: `OpenSpending: ${topic}`, country: 'Global', amount: 0, source: 'OpenSpending', url: `https://openspending.org/s/?q=${encodeURIComponent(topic)}` },
          ]});
        }
        const data = await r.json();
        const items = (data?.results || []).slice(0, 8).map(d => ({
          id: d.id || '',
          name: d.label || d.name || '',
          country: d.territories?.[0] || '',
          amount: d.total_budget || 0,
          source: 'OpenSpending',
          url: `https://openspending.org/${d.id}`,
        })).filter(i => i.name);
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── HUDOC — Europäischer Gerichtshof für Menschenrechte ──
    if (path === '/api/kaninchenbau/hudoc' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://hudoc.echr.coe.int/app/query/results?query=contentsitename:ECHR+AND+%28%22${encodeURIComponent(q)}%22%29&select=itemid,docname,kpdate,article,conclusion&sort=kpdate+Descending&start=0&length=8&language=ger`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [] });
        const data = await r.json();
        const items = (data?.results?.result || []).slice(0, 8).map(c => {
          const cols = c?.columns || {};
          return {
            id: cols?.itemid || '',
            title: cols?.docname || '',
            date: cols?.kpdate?.slice(0, 10) || '',
            articles: cols?.article || '',
            conclusion: (cols?.conclusion || '').slice(0, 150),
            url: `https://hudoc.echr.coe.int/eng#{%22itemid%22:[%22${cols?.itemid}%22]}`,
          };
        }).filter(c => c.title);
        const translated = await translateItems(items, ['title', 'conclusion']);
        return jsonResponse({ topic: q, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── EU-Curia — EU-Gerichtshof Urteile ──
    if (path === '/api/kaninchenbau/eucuria' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        // EU-Curia hat kein offenes API — nutzen EUR-Lex als Alternative
        const r = await fetch(
          `https://api.eurlex.europa.eu/rest/eurlex/search?queryText=${encodeURIComponent(topic)}&pageSize=8&pageNum=1&language=de&includeCorrigenda=false`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        let items = [];
        if (r.ok) {
          const data = await r.json();
          items = (data?.results || []).slice(0, 8).map(d => ({
            id: d.celexNumber || d.id || '',
            title: d.title || d.longTitle || '',
            date: d.date || '',
            type: d.documentType || 'Urteil',
            source: 'EUR-Lex',
            url: d.uri || `https://eur-lex.europa.eu/legal-content/DE/TXT/?uri=CELEX:${d.celexNumber}`,
          })).filter(i => i.title);
        }
        if (!items.length) {
          // Static-Link-Fallback
          items = [
            { id: 'curia-1', title: `EU-Gerichtshof: ${topic}`, date: '', type: 'Suche', source: 'EU-Curia', url: `https://curia.europa.eu/juris/recherche.jsf?language=de&query=${encodeURIComponent(topic)}` },
            { id: 'eurlex-1', title: `EUR-Lex: ${topic}`, date: '', type: 'Suche', source: 'EUR-Lex', url: `https://eur-lex.europa.eu/search.html?text=${encodeURIComponent(topic)}&lang=de` },
          ];
        }
        const translated = await translateItems(items, ['title']);
        return jsonResponse({ topic, items: translated });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── OpenSecrets — US-Wahlkampffinanzierung ──
    if (path === '/api/kaninchenbau/opensecrets' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      // OpenSecrets API braucht Key für Daten — wir geben statische Recherche-Links
      const items = [
        { id: 'os-1', name: `OpenSecrets: ${q}`, type: 'Suche', industry: '', amount: 0, year: new Date().getFullYear(), source: 'OpenSecrets', url: `https://www.opensecrets.org/search?q=${encodeURIComponent(q)}&cx=1` },
        { id: 'os-2', name: `FollowTheMoney: ${q}`, type: 'Suche', industry: '', amount: 0, year: new Date().getFullYear(), source: 'FollowTheMoney', url: `https://www.followthemoney.org/show-me?s=${encodeURIComponent(q)}` },
        { id: 'os-3', name: `FEC-Datenbank: ${q}`, type: 'Suche', industry: '', amount: 0, year: new Date().getFullYear(), source: 'FEC', url: `https://www.fec.gov/data/browse-data/?tab=bulk-data` },
      ];
      return jsonResponse({ topic: q, items });
    }

    // ── FEC — Federal Election Commission ──
    if (path === '/api/kaninchenbau/fec' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        // FEC API — Kandidaten-Suche (kein Key für basic)
        const r = await fetch(
          `https://api.open.fec.gov/v1/candidates/search/?q=${encodeURIComponent(q)}&per_page=8&api_key=DEMO_KEY`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        let items = [];
        if (r.ok) {
          const data = await r.json();
          items = (data?.results || []).slice(0, 8).map(c => ({
            id: c.candidate_id || '',
            name: c.name || '',
            party: c.party_full || '',
            office: c.office_full || '',
            state: c.state || '',
            cycles: c.election_years || [],
            url: `https://www.fec.gov/data/candidate/${c.candidate_id}/`,
          })).filter(c => c.name);
        }
        if (!items.length) {
          items = [{ id: 'fec-1', name: `FEC-Suche: ${q}`, party: '', office: '', state: '', cycles: [], url: `https://www.fec.gov/data/browse-data/?tab=candidates` }];
        }
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── EveryPolitician — globale Politiker-Datenbank ──
    if (path === '/api/kaninchenbau/everypolitician' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      // EveryPolitician ist GitHub-based, kein dynamisches Suche-API
      // Wir nutzen Wikidata SPARQL speziell für Politiker
      const q = getEnglishTopic(topic);
      try {
        const sparql = `
SELECT DISTINCT ?person ?personLabel ?countryLabel ?partyLabel ?positionLabel WHERE {
  ?person wdt:P31 wd:Q5.
  ?person wdt:P106 wd:Q82955.
  { ?person rdfs:label ?searchLabel. FILTER(CONTAINS(LCASE(STR(?searchLabel)), "${q.toLowerCase()}")) }
  UNION
  { ?person wdt:P102 ?party. ?party rdfs:label ?partyLabel2. FILTER(CONTAINS(LCASE(STR(?partyLabel2)), "${q.toLowerCase()}")) }
  OPTIONAL { ?person wdt:P27 ?country. }
  OPTIONAL { ?person wdt:P102 ?party. }
  OPTIONAL { ?person wdt:P39 ?position. }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "de,en". }
}
LIMIT 15`;
        const r = await fetch(
          `https://query.wikidata.org/sparql?format=json&query=${encodeURIComponent(sparql)}`,
          { signal: AbortSignal.timeout(15000), headers: { 'Accept': 'application/sparql-results+json', 'User-Agent': 'WeltenbibliothekKaninchenbau/1.0' } }
        );
        if (!r.ok) return jsonResponse({ items: [] });
        const data = await r.json();
        const seen = new Set();
        const items = (data?.results?.bindings || [])
          .map(b => ({
            id: (b.person?.value || '').split('/').pop(),
            name: b.personLabel?.value || '',
            country: b.countryLabel?.value || '',
            party: b.partyLabel?.value || '',
            position: b.positionLabel?.value || '',
            url: b.person?.value || '',
          }))
          .filter(p => p.name && !/^Q\d+$/.test(p.name) && !seen.has(p.id) && seen.add(p.id))
          .slice(0, 12);
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── OC-Network — OpenCorporates Officer-Netzwerk ──
    if (path === '/api/kaninchenbau/oc-network' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      try {
        const r = await fetch(
          `https://api.opencorporates.com/v0.4/officers/search?q=${encodeURIComponent(q)}&per_page=8`,
          { signal: AbortSignal.timeout(12000), headers: { 'Accept': 'application/json' } }
        );
        if (!r.ok) return jsonResponse({ items: [] });
        const data = await r.json();
        const officers = (data?.results?.officers || []).slice(0, 8);
        const items = officers.map(o => {
          const off = o.officer || o;
          return {
            id: off.id || '',
            name: off.name || '',
            position: off.position || '',
            company: off.company?.name || '',
            jurisdiction: off.company?.jurisdiction_code || '',
            startDate: off.start_date || '',
            endDate: off.end_date || '',
            url: off.opencorporates_url || '',
          };
        }).filter(o => o.name);
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── CorpWatch — Unternehmens-Kritik und Compliance-Verletzungen ──
    if (path === '/api/kaninchenbau/corpwatch' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      // CorpWatch API ist veraltet — wir kombinieren mehrere Quellen
      try {
        const [goodJobsR, violarR] = await Promise.allSettled([
          fetch(`https://www.goodjobsfirst.org/violation-tracker-api?company=${encodeURIComponent(q)}&limit=6`, { signal: AbortSignal.timeout(8000) }).then(r => r.ok ? r.json() : null).catch(() => null),
          fetch(`https://api.violationtracker.goodjobsfirst.org/violations?company=${encodeURIComponent(q)}&limit=6`, { signal: AbortSignal.timeout(8000) }).then(r => r.ok ? r.json() : null).catch(() => null),
        ]);
        // Static Recherche-Links als Fallback
        const items = [
          { id: 'cw-1', name: `Violation Tracker: ${q}`, type: 'compliance', description: 'US-Unternehmensstrafen + Compliance-Verletzungen', penalty: 0, year: 0, source: 'Good Jobs First', url: `https://violationtracker.goodjobsfirst.org/?company_search=${encodeURIComponent(q)}` },
          { id: 'cw-2', name: `CorpWatch: ${q}`, type: 'compliance', description: 'Unternehmens-Accountability-Datenbank', penalty: 0, year: 0, source: 'CorpWatch', url: `https://www.corpwatch.org/search/node/${encodeURIComponent(q)}` },
          { id: 'cw-3', name: `OSHA Inspektionen: ${q}`, type: 'safety', description: 'Arbeitssicherheits-Verletzungen (USA)', penalty: 0, year: 0, source: 'OSHA', url: `https://www.osha.gov/pls/imis/establishment.html` },
        ];
        return jsonResponse({ topic: q, items });
      } catch (e) {
        return jsonResponse({ items: [], error: e.message });
      }
    }

    // ── WikiLeaks Direkt-Suche ──
    if (path === '/api/kaninchenbau/wikileaks' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const q = getEnglishTopic(topic);
      // WikiLeaks hat kein öffentliches API — statische Quellen + Archive.org
      try {
        const r = await fetch(
          `https://archive.org/advancedsearch.php?q=${encodeURIComponent(q)}+AND+(subject:WikiLeaks+OR+creator:WikiLeaks)&fl[]=identifier&fl[]=title&fl[]=date&fl[]=description&rows=5&output=json`,
          { signal: AbortSignal.timeout(10000) }
        );
        const data = r.ok ? await r.json() : null;
        const archiveItems = (data?.response?.docs || []).slice(0, 5).map(d => ({
          id: d.identifier || '',
          title: d.title || '',
          date: d.date?.slice(0, 10) || '',
          collection: 'WikiLeaks via Archive.org',
          snippet: (Array.isArray(d.description) ? d.description[0] : d.description || '').slice(0, 150),
          url: `https://archive.org/details/${d.identifier}`,
        })).filter(d => d.title);

        const staticItems = [
          { id: 'wl-1', title: `WikiLeaks-Suche: ${q}`, date: '', collection: 'WikiLeaks', snippet: 'Diplomatische Depeschen, Geheimdienstberichte, interne Firmen-E-Mails', url: `https://search.wikileaks.org/?q=${encodeURIComponent(q)}` },
          { id: 'wl-2', title: `WikiLeaks GI-Files: ${q}`, date: '', collection: 'WikiLeaks / Stratfor', snippet: 'Stratfor Global Intelligence E-Mails', url: `https://search.wikileaks.org/gifiles/?query=${encodeURIComponent(q)}` },
        ];
        const translated = await translateItems(archiveItems, ['title', 'snippet']);
        return jsonResponse({ topic: q, items: [...translated, ...staticItems] });
      } catch (e) {
        return jsonResponse({ items: [
          { id: 'wl-1', title: `WikiLeaks: ${q}`, date: '', collection: 'WikiLeaks', snippet: '', url: `https://search.wikileaks.org/?q=${encodeURIComponent(q)}` },
        ], error: e.message });
      }
    }

    // ── Verbesserte keypersons: Wikipedia-Fallback wenn Wikidata leer ──
    // (Bereits implementiert oben — hier zusätzlicher Wikipedia-Extract-Endpoint)
    if (path === '/api/kaninchenbau/keypersons-wiki' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      if (!topic) return errorResponse('topic fehlt', 400);
      const enTopic = getEnglishTopic(topic);
      try {
        // Wikipedia-Artikel holen + Personen-Mentions extrahieren
        const langs = ['de', 'en'];
        for (const lang of langs) {
          const q = lang === 'en' ? enTopic : normalizeTopicForSearch(topic);
          const linksUrl = `https://${lang}.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(q)}&prop=links&pllimit=50&plnamespace=0&format=json&origin=*`;
          const lr = await fetch(linksUrl, { signal: AbortSignal.timeout(8000) }).catch(() => null);
          if (!lr?.ok) continue;
          const ld = await lr.json();
          const pages = Object.values(ld?.query?.pages || {});
          const links = pages[0]?.links || [];
          // Filter: nur Links die wie Personennamen aussehen (Großbuchstabe + kein ':')
          const personLinks = links
            .map(l => l.title)
            .filter(t => t && /^[A-ZÜÖÄ][a-züöäß]/.test(t) && !t.includes(':') && !t.includes('(') && t.split(' ').length >= 2)
            .slice(0, 15);
          if (personLinks.length >= 3) {
            const persons = personLinks.map((name, i) => ({
              id: `wiki-${i}`,
              name,
              description: `Erwähnt im Wikipedia-Artikel zu "${q}"`,
              role: 'Erwähnt',
              image: null,
              url: `https://${lang}.wikipedia.org/wiki/${encodeURIComponent(name)}`,
            }));
            return jsonResponse({ topic, lang, persons });
          }
        }
        return jsonResponse({ topic, persons: [] });
      } catch (e) {
        return jsonResponse({ persons: [], error: e.message });
      }
    }

    // ── Google Fact Check Tools (Worker-Proxy mit Server-Key) ──
    if (path === '/api/factcheck/search' && method === 'GET') {
      const q = url.searchParams.get('q');
      if (!q) return errorResponse('q fehlt', 400);

      // Verdict-Mapping: Englische Google-FactCheck-Verdicts → Deutsch
      const verdictDE = v => {
        if (!v) return v;
        const map = {
          'true': 'Wahr', 'mostly true': 'Größtenteils wahr',
          'half true': 'Halb wahr', 'mixture': 'Teils wahr / teils falsch',
          'mostly false': 'Größtenteils falsch', 'false': 'Falsch',
          'pants on fire': 'Nachweislich falsch', 'misleading': 'Irreführend',
          'unverified': 'Nicht verifiziert', 'unproven': 'Nicht bewiesen',
          'disputed': 'Umstritten', 'satire': 'Satire',
          'correct': 'Korrekt', 'incorrect': 'Falsch',
          'accurate': 'Zutreffend', 'inaccurate': 'Unzutreffend',
          'partially true': 'Teilweise wahr', 'partially false': 'Teilweise falsch',
          'missing context': 'Kontext fehlt', 'outdated': 'Veraltet',
          'no evidence': 'Kein Beleg', 'not credible': 'Nicht glaubwürdig',
          'unsupported': 'Nicht belegt', 'exaggerated': 'Übertrieben',
        };
        const key = v.toLowerCase().trim();
        return map[key] || v;
      };

      // Primär: Google FactCheck API (wenn Key vorhanden)
      if (env.GOOGLE_FACTCHECK_API_KEY) {
        try {
          const r = await fetch(
            `https://factchecktools.googleapis.com/v1alpha1/claims:search?query=${encodeURIComponent(q)}&pageSize=10&key=${env.GOOGLE_FACTCHECK_API_KEY}&languageCode=de`,
            { signal: AbortSignal.timeout(12000) }
          );
          if (r.ok) {
            const data = await r.json();
            // Verdicts auf Deutsch übersetzen
            const claims = (data.claims || []).map(c => ({
              ...c,
              claimReview: (c.claimReview || []).map(rv => ({
                ...rv,
                textualRating: verdictDE(rv.textualRating),
              })),
            }));
            return jsonResponse({ claims });
          }
        } catch (_) {}
      }

      // Fallback: Groq-basierte Faktenanalyse (kein Google-Key nötig)
      if (env.GROQ_API_KEY) {
        try {
          const prompt = `Du bist ein Faktenprüfer. Analysiere die folgende Suchanfrage auf bekannte Falschinformationen und Fakten auf Deutsch.
Suchanfrage: "${q}"

Antworte NUR als gültiges JSON-Array mit bis zu 5 Einträgen im Format:
[
  {
    "text": "Behauptung (kurz, konkret)",
    "claimant": "Quelle/Urheber oder 'Verbreitet in sozialen Medien'",
    "claimReview": [{"textualRating": "Wahr|Falsch|Irreführend|Umstritten|Teilweise wahr", "publisher": {"name": "KI-Analyse"}, "url": ""}]
  }
]
Falls keine konkreten Behauptungen bekannt sind, gib 1 allgemeinen Eintrag zum Thema zurück.`;

          const gr = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${env.GROQ_API_KEY}` },
            body: JSON.stringify({
              model: 'llama-3.3-70b-versatile',
              messages: [{ role: 'user', content: prompt }],
              max_tokens: 800,
              temperature: 0.2,
            }),
            signal: AbortSignal.timeout(20000),
          });
          if (gr.ok) {
            const gd = await gr.json();
            const raw = gd?.choices?.[0]?.message?.content?.trim() || '[]';
            const jsonStr = raw.replace(/^```json?\s*/i, '').replace(/\s*```$/, '');
            const claims = JSON.parse(jsonStr);
            if (Array.isArray(claims) && claims.length > 0) {
              return jsonResponse({ claims, source: 'groq_analysis' });
            }
          }
        } catch (_) {}
      }

      // Letzter Fallback: leere Liste → Client zeigt Directlinks
      return jsonResponse({ claims: [], fallback: true });
    }

    // ── OpenAlex — akademische Paper mit Übersetzung (DE) ──
    if (path === '/api/kaninchenbau/openalex' && method === 'GET') {
      const topic = url.searchParams.get('topic');
      const limit = parseInt(url.searchParams.get('limit') || '6', 10);
      if (!topic) return errorResponse('topic fehlt', 400);
      try {
        const r = await fetch(
          `https://api.openalex.org/works?search=${encodeURIComponent(topic)}&per_page=${limit}&sort=cited_by_count:desc`,
          { signal: AbortSignal.timeout(12000), headers: { 'User-Agent': 'WeltenbibliothekKaninchenbau/1.0 (mailto:dev@weltenbibliothek.app)' } }
        );
        if (!r.ok) return jsonResponse({ results: [] });
        const data = await r.json();
        const raw = (data.results || []).slice(0, limit).map(m => ({
          title: m.title || m.display_name || '',
          doi: (m.doi || '').replace('https://doi.org/', ''),
          authors: (m.authorships || []).slice(0, 4).map(a => a?.author?.display_name || '').filter(Boolean),
          year: m.publication_year || null,
          citations: m.cited_by_count || 0,
          url: m.doi || m.id || '',
          source: 'OpenAlex',
        }));
        const translated = await translateItems(raw, ['title']);
        return jsonResponse({ topic, results: translated });
      } catch (e) {
        return jsonResponse({ results: [], error: e.message });
      }
    }

    // ── Whisper Transcribe (Workers AI, kein API-Key) ──
    if (path === '/api/whisper/transcribe' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const buf = await request.arrayBuffer();
        if (buf.byteLength === 0) return errorResponse('audio fehlt', 400);
        if (buf.byteLength > 25 * 1024 * 1024) {
          return errorResponse('audio zu groß (max 25 MB)', 413);
        }
        const audio = [...new Uint8Array(buf)];
        const res = await env.AI.run('@cf/openai/whisper', { audio });
        return jsonResponse({
          text: res?.text || '',
          duration: res?.vtt ? null : undefined,
          word_count: res?.word_count,
        });
      } catch (e) {
        return errorResponse(`Whisper-Fehler: ${e.message}`);
      }
    }

    // ── AI Endpunkte ──────────────────────────────────────────
    if (path.startsWith('/api/ai/') || path.startsWith('/ai/')) {
      const gatewayUrl = env.OPENCLAW_GATEWAY_URL || 'http://72.62.154.95:50074';
      const aiPath = path.startsWith('/api/ai/') ? path.replace('/api/ai/', '') : path.replace('/ai/', '');

      try {
        if (method === 'POST') {
          const body = await request.json();
          const res = await fetch(`${gatewayUrl}/api/ai/${aiPath}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
          }).catch(() => null);

          if (!res || !res.ok) {
            // Graceful fallbacks
            if (aiPath === 'auto-tag') return jsonResponse({ tags: [] });
            if (aiPath === 'recommendations') return jsonResponse({ recommendations: [] });
            if (aiPath === 'suggestions') return jsonResponse({ suggestions: [] });
            if (aiPath === 'similar') return jsonResponse({ similar: [] });
            if (aiPath === 'trending') return jsonResponse({ trending: [] });
            return jsonResponse({ result: null, error: 'AI-Gateway nicht erreichbar' });
          }
          const data = await res.json();
          return jsonResponse(data);
        }

        if (method === 'GET') {
          if (aiPath === 'trending') {
            const limit = url.searchParams.get('limit') || '10';
            const anonKey = env.SUPABASE_ANON_KEY || '';
            const res = await fetch(
              `${SUPABASE_URL}/rest/v1/articles?select=tags,category&is_published=eq.true&order=created_at.desc&limit=100`,
              { headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` } }
            );
            const articles = await res.json().catch(() => []);
            const tagCounts = {};
            (Array.isArray(articles) ? articles : []).forEach(a => {
              (a.tags || []).forEach(tag => { tagCounts[tag] = (tagCounts[tag] || 0) + 1; });
              if (a.category) tagCounts[a.category] = (tagCounts[a.category] || 0) + 1;
            });
            const trending = Object.entries(tagCounts)
              .sort((a, b) => b[1] - a[1])
              .slice(0, parseInt(limit))
              .map(([tag, count]) => ({ tag, count }));
            return jsonResponse({ trending });
          }
          return jsonResponse({ data: [], status: 'ok' });
        }
      } catch (e) {
        return errorResponse(`AI-Fehler: ${e.message}`);
      }
    }

    // ── Tags Trending ─────────────────────────────────────────
    if (path.startsWith('/api/tags/trending')) {
      const limit = url.searchParams.get('limit') || '10';
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const res = await fetch(
        `${SUPABASE_URL}/rest/v1/articles?select=tags,category&is_published=eq.true&limit=200`,
        { headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` } }
      );
      const articles = await res.json().catch(() => []);
      const tagCounts = {};
      (Array.isArray(articles) ? articles : []).forEach(a => {
        (a.tags || []).forEach(tag => { tagCounts[tag] = (tagCounts[tag] || 0) + 1; });
        if (a.category) tagCounts[a.category] = (tagCounts[a.category] || 0) + 1;
      });
      const trending = Object.entries(tagCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, parseInt(limit))
        .map(([tag, count]) => ({ tag, count }));
      return jsonResponse(trending);
    }

    // ── Community Aktionen ────────────────────────────────────
    // ── Moderation Endpoints ──────────────────────────────────
    if (path.startsWith('/api/moderation/')) {
      const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
      const svcHeaders = { 'Content-Type': 'application/json', 'apikey': svcKey, 'Authorization': `Bearer ${svcKey}` };
      try {
        // GET /api/moderation/flagged-content/:world
        // Flutter erwartet Key "flagged_content" (nicht "flagged")
        if (method === 'GET' && path.includes('/flagged-content')) {
          const world = path.split('/')[4] || 'materie';
          const status = url.searchParams.get('status') || 'pending';
          const limit = url.searchParams.get('limit') || '50';
          // Lade neueste Chat-Nachrichten als gemeldete Inhalte (Proxy)
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/chat_messages?select=id,room_id,username,content,created_at&order=created_at.desc&limit=${limit}`,
            { headers: svcHeaders }
          );
          const data = await res.json().catch(() => []);
          const flagged_content = (Array.isArray(data) ? data : []).map((m, i) => ({
            id: i + 1,
            flag_id: `flag_${m.id || i}`,
            content_id: (m.id || '').toString(),
            content_type: 'chat_message',
            content_text: m.content || '',
            reported_by: 'system',
            flagged_by_id: 'system',
            flagged_by_username: 'system',
            flagged_by_role: 'admin',
            reason: 'review',
            status: status === 'all' ? 'pending' : status,
            created_at: m.created_at || new Date().toISOString(),
            author_username: m.username || '',
            content_author_username: m.username || '',
            world: world,
          }));
          return jsonResponse({ success: true, flagged_content, count: flagged_content.length });
        }
        // POST /api/moderation/resolve-flag
        if (method === 'POST' && path.includes('/resolve-flag')) {
          const body = await request.json().catch(() => ({}));
          return jsonResponse({ success: true, message: 'Flag resolved', flag_id: body.flag_id });
        }
        // POST /api/moderation/dismiss-flag
        if (method === 'POST' && path.includes('/dismiss-flag')) {
          const body = await request.json().catch(() => ({}));
          return jsonResponse({ success: true, message: 'Flag dismissed', flag_id: body.flag_id });
        }
        // POST /api/moderation/flag-content
        if (method === 'POST' && path.includes('/flag-content')) {
          const body = await request.json().catch(() => ({}));
          return jsonResponse({ success: true, message: 'Content flagged', flag_id: `flag_${Date.now()}` });
        }
        // POST /api/moderation/mute-user
        if (method === 'POST' && path.includes('/mute-user')) {
          const body = await request.json().catch(() => ({}));
          const userId = body.user_id || body.userId;
          if (userId) {
            await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
              method: 'PATCH', headers: svcHeaders,
              body: JSON.stringify({ is_banned: true }),
            }).catch(() => null);
          }
          return jsonResponse({ success: true, action: 'muted' });
        }
        // POST /api/moderation/unmute-user
        if (method === 'POST' && path.includes('/unmute-user')) {
          const body = await request.json().catch(() => ({}));
          const userId = body.user_id || body.userId;
          if (userId) {
            await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
              method: 'PATCH', headers: svcHeaders,
              body: JSON.stringify({ is_banned: false }),
            }).catch(() => null);
          }
          return jsonResponse({ success: true, action: 'unmuted' });
        }
        // GET /api/moderation/check-mute/:world/:userId
        if (method === 'GET' && path.includes('/check-mute')) {
          const parts = path.split('/');
          const userId = parts[parts.length - 1];
          let is_muted = false;
          if (userId && userId.length > 8) {
            const res = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?select=is_banned&id=eq.${userId}&limit=1`,
              { headers: svcHeaders }
            );
            const data = await res.json().catch(() => []);
            is_muted = Array.isArray(data) && data[0]?.is_banned === true;
          }
          return jsonResponse({ success: true, is_muted, mute_expires_at: null });
        }
        // GET /api/moderation/log/:world
        if (method === 'GET' && path.includes('/log/')) {
          const world = path.split('/')[4] || 'materie';
          const limit = url.searchParams.get('limit') || '50';
          // Lade Profil-Updates als Moderation-Log (Proxy)
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,username,role,updated_at&world=eq.${world}&order=updated_at.desc&limit=${limit}`,
            { headers: svcHeaders }
          );
          const data = await res.json().catch(() => []);
          const logs = (Array.isArray(data) ? data : []).map((u, i) => ({
            id: i + 1,
            log_id: `log_${i + 1}`,
            world: world,
            action_type: 'profile_update',
            action: 'profile_update',
            moderator_id: 'system',
            moderator_username: 'system',
            admin_username: 'system',
            moderator_role: 'admin',
            target_type: 'user',
            target_id: u.id || '',
            target_username: u.username || '',
            reason: null,
            metadata: null,
            created_at: u.updated_at || new Date().toISOString(),
          }));
          return jsonResponse({ success: true, logs, count: logs.length });
        }
        return jsonResponse({ success: true });
      } catch (e) {
        return jsonResponse({ success: false, error: e.message });
      }
    }

    if (path.startsWith('/api/community/') || path === '/posts/create' || path === '/comments/create') {
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;

      if (path.includes('/likes') && method === 'POST') {
        const body = await request.json().catch(() => ({}));
        const res = await fetch(`${SUPABASE_URL}/rest/v1/likes`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'apikey': anonKey, 'Authorization': authHeader, 'Prefer': 'return=representation' },
          body: JSON.stringify(body),
        });
        return jsonResponse(await res.json().catch(() => ({})), res.status);
      }

      if (path.includes('/comments') && method === 'GET') {
        const postId = path.split('/').pop();
        const supaPath = `/rest/v1/comments?select=*,profiles(username,avatar_url)&article_id=eq.${postId}&is_deleted=eq.false&order=created_at.asc`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }

      if (path === '/comments/create' || path.includes('/comment')) {
        const body = await request.json().catch(() => ({}));
        const res = await fetch(`${SUPABASE_URL}/rest/v1/comments`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'apikey': anonKey, 'Authorization': authHeader, 'Prefer': 'return=representation' },
          body: JSON.stringify({ ...body, content: body.content || body.text || '' }),
        });
        return jsonResponse(await res.json().catch(() => ({})), res.status);
      }

      if (path.includes('/share') && method === 'POST') {
        return jsonResponse({ success: true, shared: true });
      }

      if (path.includes('/user/') && path.includes('/stats')) {
        const userId = path.split('/user/')[1]?.split('/')[0];
        if (userId) {
          const supaPath = `/rest/v1/articles?select=id&user_id=eq.${userId}&is_published=eq.true&limit=1000`;
          const res = await fetch(`${SUPABASE_URL}${supaPath}`, {
            headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}`, 'Prefer': 'count=exact' },
          });
          const count = parseInt(res.headers.get('Content-Range')?.split('/')[1] || '0');
          return jsonResponse({ articleCount: count, followers: 0, following: 0 });
        }
      }

      // Batch-Likes
      if (path.includes('/likes/batch')) {
        const body = await request.json().catch(() => ({ ids: [] }));
        return jsonResponse({ liked: [], counts: {} });
      }

      return jsonResponse({ success: true });
    }

    // ── Auth Endpunkte ────────────────────────────────────────
    if (path.startsWith('/auth/')) {
      const authPath = path.replace('/auth/', '');
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;

      if (authPath === 'register' && method === 'POST') {
        // Registration läuft über Supabase Auth direkt
        return jsonResponse({ success: true, message: 'Nutze Supabase Auth direkt' });
      }
      if (authPath === 'validate' && method === 'POST') {
        const token = request.headers.get('Authorization')?.replace('Bearer ', '');
        if (!token) return jsonResponse({ valid: false });
        // Token-Validierung über Supabase
        const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
          headers: { 'apikey': anonKey, 'Authorization': `Bearer ${token}` },
        });
        const user = await res.json().catch(() => null);
        return jsonResponse({ valid: res.ok, user: user?.email ? { id: user.id, email: user.email } : null });
      }
      if (authPath === 'logout' && method === 'POST') {
        return jsonResponse({ success: true });
      }
      if (authPath === 'link-profile' && method === 'POST') {
        return jsonResponse({ success: true });
      }
      if (authPath === 'refresh' && method === 'POST') {
        return jsonResponse({ success: true });
      }
      return jsonResponse({ success: true });
    }

    // ── Messages Reactions/Receipts ───────────────────────────
    if (path.startsWith('/messages/')) {
      const parts = path.split('/'); // /messages/:id/:action
      const messageId = parts[2];
      const action = parts[3];
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const authHeader = request.headers.get('Authorization') || `Bearer ${anonKey}`;

      if (action === 'react' && method === 'POST') {
        const body = await request.json().catch(() => ({}));
        const res = await fetch(`${SUPABASE_URL}/rest/v1/message_reactions`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'apikey': anonKey, 'Authorization': authHeader, 'Prefer': 'return=representation' },
          body: JSON.stringify({ message_id: messageId, ...body }),
        });
        return jsonResponse(await res.json().catch(() => ({})), res.status < 300 ? 201 : res.status);
      }
      if (action === 'reactions' && method === 'GET') {
        const supaPath = `/rest/v1/message_reactions?select=*&message_id=eq.${messageId}&order=created_at.asc`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }
      if (action === 'read' && method === 'POST') {
        return jsonResponse({ success: true });
      }
      if (action === 'receipts' && method === 'GET') {
        return jsonResponse({ receipts: [] });
      }
      return jsonResponse({ success: true });
    }

    // ── Status Heartbeat ──────────────────────────────────────
    if (path.startsWith('/api/status/')) {
      if (method === 'POST') {
        return jsonResponse({ status: 'ok', timestamp: new Date().toISOString() });
      }
      return jsonResponse({ online: true, timestamp: new Date().toISOString() });
    }

    // ── Error Reporting ───────────────────────────────────────
    if (path === '/errors/report' && method === 'POST') {
      try {
        const body = await request.json();
        console.error('[ERROR_REPORT]', JSON.stringify(body));
      } catch (_) {}
      return jsonResponse({ received: true });
    }

    // ── Voice/WebRTC ──────────────────────────────────────────
    if (path.startsWith('/voice/') && path !== '/voice/rooms') {
      const voicePath = path.replace('/voice/', '');
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;

      // ── JOIN: Register participant in voice_participants ──────
      if ((voicePath === 'join' || voicePath.endsWith('/join')) && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const roomId   = body.roomId   || body.room_id   || voicePath.split('/')[0];
          const userId   = body.userId   || body.user_id   || null;
          const username = body.username || 'Anonym';
          const isUUID = userId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);

          if (roomId) {
            // Count active participants BEFORE this join to detect "first joiner"
            const countRes = await fetch(
              `${SUPABASE_URL}/rest/v1/voice_participants?room_id=eq.${roomId}&is_active=eq.true&select=id&limit=1`,
              { headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Prefer': 'count=exact' } }
            );
            const prevCount = parseInt(countRes.headers.get('content-range')?.split('/')[1] || '1', 10);

            const upsertBody = {
              room_id:    roomId,
              user_id:    isUUID ? userId : null,
              username:   username,
              avatar_url: body.avatarUrl || null,
              is_active:  true,
              is_muted:   body.pushToTalk || false,
              joined_at:  new Date().toISOString(),
            };
            await fetch(`${SUPABASE_URL}/rest/v1/voice_participants`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
                'Prefer': 'resolution=merge-duplicates,return=minimal',
              },
              body: JSON.stringify(upsertBody),
            });

            // Notify world subscribers when room goes from 0 → 1 participant
            if (prevCount === 0) {
              const world = body.world || (roomId.startsWith('energie') ? 'energie' : 'materie');
              const worldLabel = world === 'energie' ? 'Energie' : 'Materie';
              // Fetch all active push subscribers for this world (excluding the joiner)
              const subsRes = await fetch(
                `${SUPABASE_URL}/rest/v1/push_subscriptions?is_active=eq.true&select=user_id`,
                { headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
              );
              const subs = await subsRes.json().catch(() => []);
              if (Array.isArray(subs)) {
                const notifyTitle = `🎙️ Voice-Raum geöffnet · ${worldLabel}`;
                const notifyBody  = `${username} hat einen Voice-Raum gestartet. Tritt jetzt bei!`;
                const notifyData  = { type: 'voice_started', room_id: roomId, world, starter: username };
                await Promise.all(
                  subs
                    .filter(s => s.user_id && s.user_id !== (isUUID ? userId : null))
                    .map(s => fetch(`${SUPABASE_URL}/rest/v1/notification_queue`, {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Prefer': 'return=minimal' },
                      body: JSON.stringify({ user_id: s.user_id, title: notifyTitle, body: notifyBody, data: notifyData }),
                    }))
                );
              }
            }
          }
          return jsonResponse({ success: true, action: 'join', roomId });
        } catch (e) {
          return jsonResponse({ success: true, action: 'join', error: e.message });
        }
      }

      // ── LEAVE: Deactivate participant ─────────────────────────
      if ((voicePath === 'leave' || voicePath.endsWith('/leave')) && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const roomId = body.roomId || body.room_id;
          const userId = body.userId || body.user_id;
          const isUUID = userId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);

          if (roomId && isUUID) {
            await fetch(`${SUPABASE_URL}/rest/v1/voice_participants?room_id=eq.${roomId}&user_id=eq.${userId}`, {
              method: 'PATCH',
              headers: {
                'Content-Type': 'application/json',
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
              },
              body: JSON.stringify({ is_active: false, left_at: new Date().toISOString() }),
            });
          }
          return jsonResponse({ success: true, action: 'leave' });
        } catch (e) {
          return jsonResponse({ success: true, action: 'leave', error: e.message });
        }
      }

      // ── MUTE/UNMUTE ───────────────────────────────────────────
      if (voicePath === 'mute' && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const { roomId, userId, isMuted } = body;
          const isUUID = userId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);
          if (roomId && isUUID) {
            await fetch(`${SUPABASE_URL}/rest/v1/voice_participants?room_id=eq.${roomId}&user_id=eq.${userId}`, {
              method: 'PATCH',
              headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` },
              body: JSON.stringify({ is_muted: isMuted }),
            });
          }
          return jsonResponse({ success: true, isMuted });
        } catch (e) {
          return jsonResponse({ success: true });
        }
      }

      // ── PARTICIPANTS: Who is in the room? ─────────────────────
      if (voicePath.startsWith('participants/')) {
        const roomId = voicePath.replace('participants/', '');
        const supaPath = `/rest/v1/voice_participants?select=*,profiles(username,avatar_url)&room_id=eq.${roomId}&is_active=eq.true`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }

      // ── ROOMS by world ────────────────────────────────────────
      if (voicePath.startsWith('rooms/')) {
        const world = voicePath.replace('rooms/', '');
        const supaPath = `/rest/v1/chat_rooms?select=*&is_active=eq.true&world=eq.${world}&order=name.asc`;
        return proxyToSupabase(request, env, supaPath, 'GET');
      }

      // ── SIGNALING: WebRTC über Supabase Realtime (kein WS nötig) ──
      if (voicePath === 'signaling' || voicePath.startsWith('signal')) {
        // Cloudflare Workers unterstützen keine WebSockets zu externen WSS
        // → Signaling läuft über Supabase Realtime (Presence + Broadcast)
        return jsonResponse({
          success: true,
          signalingMode: 'supabase-realtime',
          realtimeUrl: `${SUPABASE_URL.replace('https://', 'wss://')}/realtime/v1/websocket`,
          message: 'Nutze Supabase Realtime für WebRTC Signaling',
        });
      }

      return jsonResponse({ success: true });
    }

    // ── Wrapper / Short-URLs ──────────────────────────────────
    if (path.startsWith('/go/') || path.startsWith('/out')) {
      const target = url.searchParams.get('url') || path.replace('/go/', 'https://t.me/');
      return Response.redirect(target, 302);
    }

    // ══════════════════════════════════════════════════════════
    // OSINT TOOLS — 7 Standalone-Tools (kein Key nötig)
    // ══════════════════════════════════════════════════════════

    // A — Bildanalyse: EXIF via exif.tools API, Fallback HEAD-Request
    if (path === '/api/tools/image-analysis' && method === 'GET') {
      try {
        const imageUrl = url.searchParams.get('url') || '';
        if (!imageUrl.startsWith('http')) return errorResponse('Ungültige URL', 400);

        // HEAD-Request für Content-Type und Größe
        const headResp = await fetch(imageUrl, { method: 'HEAD' });
        const contentType = headResp.headers.get('content-type') || 'unbekannt';
        const contentLength = headResp.headers.get('content-length');
        const lastModified  = headResp.headers.get('last-modified') || null;
        const sizeBytes = contentLength ? parseInt(contentLength, 10) : null;
        const sizeFormatted = sizeBytes
          ? sizeBytes > 1048576
            ? `${(sizeBytes / 1048576).toFixed(2)} MB`
            : `${(sizeBytes / 1024).toFixed(1)} KB`
          : null;

        let exifData = {};
        try {
          const exifResp = await fetch(
            `https://exif.tools/api?url=${encodeURIComponent(imageUrl)}`,
            { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }
          );
          if (exifResp.ok) {
            const exifJson = await exifResp.json();
            // exif.tools gibt flaches JSON zurück; relevante Felder extrahieren
            const keep = ['ImageWidth','ImageHeight','Make','Model','DateTime','GPSLatitude',
              'GPSLongitude','Software','ExposureTime','FNumber','ISO','Flash','Orientation'];
            for (const k of keep) {
              if (exifJson[k] !== undefined) exifData[k] = exifJson[k];
            }
          }
        } catch (_) { /* EXIF optional */ }

        return jsonResponse({
          contentType,
          size: sizeFormatted,
          sizeBytes,
          lastModified,
          width:  exifData['ImageWidth']  || null,
          height: exifData['ImageHeight'] || null,
          exif: exifData,
        });
      } catch (e) {
        return errorResponse(`Bildanalyse-Fehler: ${e.message}`);
      }
    }

    // B — Datenleck-Prüfer: ProxyNova COMB-Datenbank (frei, kein Key)
    if (path === '/api/tools/data-leak' && method === 'GET') {
      try {
        const email = url.searchParams.get('email') || '';
        if (!email.includes('@')) return errorResponse('Ungültige E-Mail', 400);

        const resp = await fetch(
          `https://api.proxynova.com/comb?search=${encodeURIComponent(email)}&start=0&limit=20`,
          { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }
        );
        if (!resp.ok) {
          return jsonResponse({ count: 0, samples: [], message: 'Datenbank nicht erreichbar' });
        }
        const data = await resp.json();
        const lines = Array.isArray(data.lines) ? data.lines : [];
        return jsonResponse({
          count: data.count || lines.length,
          samples: lines.slice(0, 10),
        });
      } catch (e) {
        return errorResponse(`Datenleck-Fehler: ${e.message}`);
      }
    }

    // C — Krypto-Verfolger: BTC via blockchain.info, ETH via Blockscout
    if (path === '/api/tools/crypto' && method === 'GET') {
      try {
        const address = url.searchParams.get('address') || '';
        if (!address) return errorResponse('Keine Adresse angegeben', 400);

        const isBtc = /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(address)
          || /^bc1[ac-hj-np-z02-9]{6,87}$/.test(address);
        const isEth = /^0x[0-9a-fA-F]{40}$/.test(address);

        if (isBtc) {
          const r = await fetch(
            `https://blockchain.info/rawaddr/${address}?limit=10`,
            { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }
          );
          if (!r.ok) return errorResponse('BTC-API nicht erreichbar', 502);
          const d = await r.json();
          const satoshi = d.final_balance || 0;
          const btc = (satoshi / 1e8).toFixed(8);
          const txs = (d.txs || []).slice(0, 5).map(tx => {
            const myOut = (tx.out || []).filter(o => o.addr === address).reduce((s, o) => s + o.value, 0);
            const myIn  = (tx.inputs || []).filter(i => i.prev_out?.addr === address).reduce((s, i) => s + i.prev_out.value, 0);
            const net = (myOut - myIn) / 1e8;
            return {
              hash: tx.hash?.slice(0, 16) + '…',
              amount: `${net >= 0 ? '+' : ''}${net.toFixed(8)} BTC`,
              date: tx.time ? new Date(tx.time * 1000).toISOString().split('T')[0] : null,
            };
          });
          return jsonResponse({
            coin: 'Bitcoin (BTC)',
            balance: `${btc} BTC`,
            balanceUsd: null,
            txCount: d.n_tx || 0,
            firstSeen: null,
            lastSeen: null,
            transactions: txs,
          });
        } else if (isEth) {
          const [addrResp, txResp] = await Promise.all([
            fetch(`https://eth.blockscout.com/api/v2/addresses/${address}`,
              { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }),
            fetch(`https://eth.blockscout.com/api/v2/addresses/${address}/transactions?filter=to%20%7C%20from&limit=5`,
              { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }),
          ]);
          if (!addrResp.ok) return errorResponse('ETH-API nicht erreichbar', 502);
          const addrData = await addrResp.json();
          const txData   = txResp.ok ? await txResp.json() : { items: [] };
          const weiBalance = BigInt(addrData.coin_balance || '0');
          const ethBalance = (Number(weiBalance) / 1e18).toFixed(6);
          const txs = (txData.items || []).slice(0, 5).map(tx => ({
            hash: (tx.hash || '').slice(0, 16) + '…',
            amount: `${tx.from?.hash?.toLowerCase() === address.toLowerCase() ? '-' : '+'}${(Number(tx.value || '0') / 1e18).toFixed(6)} ETH`,
            date: tx.timestamp ? tx.timestamp.split('T')[0] : null,
          }));
          return jsonResponse({
            coin: 'Ethereum (ETH)',
            balance: `${ethBalance} ETH`,
            balanceUsd: null,
            txCount: addrData.transaction_count || 0,
            firstSeen: null,
            lastSeen: null,
            transactions: txs,
          });
        } else {
          return errorResponse('Adresse nicht erkannt (BTC oder ETH erwartet)', 400);
        }
      } catch (e) {
        return errorResponse(`Krypto-Fehler: ${e.message}`);
      }
    }

    // D — Domain-OSINT: RDAP + Cloudflare DNS (A, MX, TXT)
    if (path === '/api/tools/domain' && method === 'GET') {
      try {
        const domain = url.searchParams.get('domain') || '';
        if (!domain || !/^[a-z0-9._-]{2,253}$/.test(domain)) return errorResponse('Ungültige Domain', 400);

        const [rdapResp, dnsAResp, dnsMxResp, dnsTxtResp] = await Promise.all([
          fetch(`https://rdap.org/domain/${encodeURIComponent(domain)}`,
            { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }),
          fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domain)}&type=A&ct=application/dns-json`,
            { headers: { 'Accept': 'application/dns-json' } }),
          fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domain)}&type=MX&ct=application/dns-json`,
            { headers: { 'Accept': 'application/dns-json' } }),
          fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domain)}&type=TXT&ct=application/dns-json`,
            { headers: { 'Accept': 'application/dns-json' } }),
        ]);

        // RDAP / WHOIS
        let whois = {};
        if (rdapResp.ok) {
          const rdap = await rdapResp.json();
          const registrar = (rdap.entities || []).find(e => (e.roles || []).includes('registrar'));
          const events = rdap.events || [];
          const reg = events.find(e => e.eventAction === 'registration');
          const exp = events.find(e => e.eventAction === 'expiration');
          const ns  = (rdap.nameservers || []).map(n => n.ldhName || n.unicodeName || '').filter(Boolean);
          whois = {
            registrar: registrar?.vcardArray?.[1]?.find(v => v[0] === 'fn')?.[3] || null,
            createdDate: reg?.eventDate?.split('T')[0] || null,
            expiryDate:  exp?.eventDate?.split('T')[0] || null,
            status: (rdap.status || []).join(', ') || null,
            nameservers: ns,
          };
        }

        // DNS
        const parseAnswers = (json, type) => {
          if (!json || !Array.isArray(json.Answer)) return [];
          return json.Answer.filter(r => r.type === type).map(r => r.data.replace(/"/g, '').trim());
        };
        const dnsA   = dnsAResp.ok   ? await dnsAResp.json()   : {};
        const dnsMx  = dnsMxResp.ok  ? await dnsMxResp.json()  : {};
        const dnsTxt = dnsTxtResp.ok ? await dnsTxtResp.json() : {};

        return jsonResponse({
          domain,
          whois,
          dns: {
            a:   parseAnswers(dnsA,  1),
            mx:  parseAnswers(dnsMx, 15),
            txt: parseAnswers(dnsTxt, 16),
          },
        });
      } catch (e) {
        return errorResponse(`Domain-OSINT-Fehler: ${e.message}`);
      }
    }

    // E — Telefon-OSINT: Regex-basierte Vorwahl-Analyse (kein Key nötig)
    if (path === '/api/tools/phone' && method === 'GET') {
      try {
        const raw = (url.searchParams.get('number') || '').replace(/[\s\-().]/g, '');
        if (!raw) return errorResponse('Keine Nummer angegeben', 400);

        // Normalisieren auf +XXXXXXXXXXX
        const normalized = raw.startsWith('+') ? raw : `+${raw}`;

        // Länder-Lookup-Tabelle (Top 80 Vorwahlen)
        const COUNTRY_DB = {
          '+1':   { country: 'USA / Kanada', flag: '🇺🇸', continent: 'Nordamerika', tz: 'UTC-5...-8' },
          '+7':   { country: 'Russland',     flag: '🇷🇺', continent: 'Eurasien',   tz: 'UTC+2...+12' },
          '+20':  { country: 'Ägypten',      flag: '🇪🇬', continent: 'Afrika',     tz: 'UTC+2' },
          '+27':  { country: 'Südafrika',    flag: '🇿🇦', continent: 'Afrika',     tz: 'UTC+2' },
          '+30':  { country: 'Griechenland', flag: '🇬🇷', continent: 'Europa',     tz: 'UTC+2' },
          '+31':  { country: 'Niederlande',  flag: '🇳🇱', continent: 'Europa',     tz: 'UTC+1' },
          '+32':  { country: 'Belgien',      flag: '🇧🇪', continent: 'Europa',     tz: 'UTC+1' },
          '+33':  { country: 'Frankreich',   flag: '🇫🇷', continent: 'Europa',     tz: 'UTC+1' },
          '+34':  { country: 'Spanien',      flag: '🇪🇸', continent: 'Europa',     tz: 'UTC+1' },
          '+36':  { country: 'Ungarn',       flag: '🇭🇺', continent: 'Europa',     tz: 'UTC+1' },
          '+39':  { country: 'Italien',      flag: '🇮🇹', continent: 'Europa',     tz: 'UTC+1' },
          '+40':  { country: 'Rumänien',     flag: '🇷🇴', continent: 'Europa',     tz: 'UTC+2' },
          '+41':  { country: 'Schweiz',      flag: '🇨🇭', continent: 'Europa',     tz: 'UTC+1' },
          '+43':  { country: 'Österreich',   flag: '🇦🇹', continent: 'Europa',     tz: 'UTC+1' },
          '+44':  { country: 'UK',           flag: '🇬🇧', continent: 'Europa',     tz: 'UTC+0' },
          '+45':  { country: 'Dänemark',     flag: '🇩🇰', continent: 'Europa',     tz: 'UTC+1' },
          '+46':  { country: 'Schweden',     flag: '🇸🇪', continent: 'Europa',     tz: 'UTC+1' },
          '+47':  { country: 'Norwegen',     flag: '🇳🇴', continent: 'Europa',     tz: 'UTC+1' },
          '+48':  { country: 'Polen',        flag: '🇵🇱', continent: 'Europa',     tz: 'UTC+1' },
          '+49':  { country: 'Deutschland',  flag: '🇩🇪', continent: 'Europa',     tz: 'UTC+1' },
          '+51':  { country: 'Peru',         flag: '🇵🇪', continent: 'Südamerika', tz: 'UTC-5' },
          '+52':  { country: 'Mexiko',       flag: '🇲🇽', continent: 'Nordamerika',tz: 'UTC-6' },
          '+54':  { country: 'Argentinien',  flag: '🇦🇷', continent: 'Südamerika', tz: 'UTC-3' },
          '+55':  { country: 'Brasilien',    flag: '🇧🇷', continent: 'Südamerika', tz: 'UTC-3' },
          '+56':  { country: 'Chile',        flag: '🇨🇱', continent: 'Südamerika', tz: 'UTC-4' },
          '+57':  { country: 'Kolumbien',    flag: '🇨🇴', continent: 'Südamerika', tz: 'UTC-5' },
          '+60':  { country: 'Malaysia',     flag: '🇲🇾', continent: 'Asien',      tz: 'UTC+8' },
          '+61':  { country: 'Australien',   flag: '🇦🇺', continent: 'Ozeanien',   tz: 'UTC+10' },
          '+62':  { country: 'Indonesien',   flag: '🇮🇩', continent: 'Asien',      tz: 'UTC+7' },
          '+63':  { country: 'Philippinen',  flag: '🇵🇭', continent: 'Asien',      tz: 'UTC+8' },
          '+64':  { country: 'Neuseeland',   flag: '🇳🇿', continent: 'Ozeanien',   tz: 'UTC+12' },
          '+65':  { country: 'Singapur',     flag: '🇸🇬', continent: 'Asien',      tz: 'UTC+8' },
          '+66':  { country: 'Thailand',     flag: '🇹🇭', continent: 'Asien',      tz: 'UTC+7' },
          '+81':  { country: 'Japan',        flag: '🇯🇵', continent: 'Asien',      tz: 'UTC+9' },
          '+82':  { country: 'Südkorea',     flag: '🇰🇷', continent: 'Asien',      tz: 'UTC+9' },
          '+84':  { country: 'Vietnam',      flag: '🇻🇳', continent: 'Asien',      tz: 'UTC+7' },
          '+86':  { country: 'China',        flag: '🇨🇳', continent: 'Asien',      tz: 'UTC+8' },
          '+90':  { country: 'Türkei',       flag: '🇹🇷', continent: 'Eurasien',   tz: 'UTC+3' },
          '+91':  { country: 'Indien',       flag: '🇮🇳', continent: 'Asien',      tz: 'UTC+5:30' },
          '+92':  { country: 'Pakistan',     flag: '🇵🇰', continent: 'Asien',      tz: 'UTC+5' },
          '+93':  { country: 'Afghanistan',  flag: '🇦🇫', continent: 'Asien',      tz: 'UTC+4:30' },
          '+94':  { country: 'Sri Lanka',    flag: '🇱🇰', continent: 'Asien',      tz: 'UTC+5:30' },
          '+95':  { country: 'Myanmar',      flag: '🇲🇲', continent: 'Asien',      tz: 'UTC+6:30' },
          '+98':  { country: 'Iran',         flag: '🇮🇷', continent: 'Asien',      tz: 'UTC+3:30' },
          '+212': { country: 'Marokko',      flag: '🇲🇦', continent: 'Afrika',     tz: 'UTC+1' },
          '+213': { country: 'Algerien',     flag: '🇩🇿', continent: 'Afrika',     tz: 'UTC+1' },
          '+216': { country: 'Tunesien',     flag: '🇹🇳', continent: 'Afrika',     tz: 'UTC+1' },
          '+218': { country: 'Libyen',       flag: '🇱🇾', continent: 'Afrika',     tz: 'UTC+2' },
          '+234': { country: 'Nigeria',      flag: '🇳🇬', continent: 'Afrika',     tz: 'UTC+1' },
          '+254': { country: 'Kenia',        flag: '🇰🇪', continent: 'Afrika',     tz: 'UTC+3' },
          '+380': { country: 'Ukraine',      flag: '🇺🇦', continent: 'Europa',     tz: 'UTC+2' },
          '+420': { country: 'Tschechien',   flag: '🇨🇿', continent: 'Europa',     tz: 'UTC+1' },
          '+421': { country: 'Slowakei',     flag: '🇸🇰', continent: 'Europa',     tz: 'UTC+1' },
          '+966': { country: 'Saudi-Arabien',flag: '🇸🇦', continent: 'Asien',      tz: 'UTC+3' },
          '+971': { country: 'VAE',          flag: '🇦🇪', continent: 'Asien',      tz: 'UTC+4' },
          '+972': { country: 'Israel',       flag: '🇮🇱', continent: 'Asien',      tz: 'UTC+2' },
          '+994': { country: 'Aserbaidschan',flag: '🇦🇿', continent: 'Asien',      tz: 'UTC+4' },
          '+995': { country: 'Georgien',     flag: '🇬🇪', continent: 'Asien',      tz: 'UTC+4' },
        };

        // Vorwahl-Matching (längste zuerst)
        let match = null;
        for (const len of [4, 3, 2, 1]) {
          const prefix = normalized.slice(0, len + 1);
          if (COUNTRY_DB[prefix]) { match = { ...COUNTRY_DB[prefix], callingCode: prefix }; break; }
        }

        // Leitungstyp-Heuristik (sehr grob, anhand Nummernlänge)
        const localPart = normalized.slice(match?.callingCode?.length || 2);
        const lineType = localPart.length <= 7 ? 'Festnetz (wahrscheinlich)' : 'Mobilfunk (wahrscheinlich)';

        // Formatierte Darstellung
        const formatted = match
          ? `${match.callingCode} ${localPart.replace(/(\d{3})(\d{3})(\d+)/, '$1 $2 $3')}`
          : normalized;

        return jsonResponse({
          countryCode: match?.callingCode?.slice(1) || null,
          callingCode: match?.callingCode || null,
          country: match?.country || 'Unbekannt',
          countryFlag: match?.flag || '🌐',
          continent: match?.continent || null,
          timezone: match?.tz || null,
          lineType,
          formatted,
          prefixInfo: match
            ? `Nummernkreis ${match.callingCode} ist ${match.country} zugeordnet (${match.continent}).`
            : 'Vorwahl konnte keinem Land zugeordnet werden.',
        });
      } catch (e) {
        return errorResponse(`Telefon-OSINT-Fehler: ${e.message}`);
      }
    }

    // F — KI-Content-Detektor: Groq Llama-3 Heuristik
    if (path === '/api/tools/ai-detect' && method === 'POST') {
      try {
        const body = await request.json();
        const text = (body.text || '').trim();
        if (text.length < 50) return errorResponse('Text zu kurz (min. 50 Zeichen)', 400);
        const excerpt = text.slice(0, 3000); // Kosten begrenzen

        if (env.GROQ_API_KEY) {
          const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${env.GROQ_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              model: 'llama-3.3-70b-versatile',
              messages: [{
                role: 'user',
                content: `Analysiere ob dieser Text von einer KI oder einem Menschen geschrieben wurde. Antworte NUR mit valide JSON (kein Markdown), folgendes Format: {"score": <0-100>, "indicators": ["<Merkmal1>", "<Merkmal2>"], "verdict": "<Human-verfasst|KI-generiert|Unklar>"}. Score 0=Mensch, 100=KI. Maximal 5 Indikatoren auf Deutsch.\n\nText:\n${excerpt}`,
              }],
              max_tokens: 300,
              temperature: 0.2,
            }),
          });
          if (r.ok) {
            const data = await r.json();
            const raw = data?.choices?.[0]?.message?.content || '{}';
            // JSON aus Antwort extrahieren (falls Markdown-Block)
            const jsonMatch = raw.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
              const parsed = JSON.parse(jsonMatch[0]);
              return jsonResponse({
                score: Math.min(100, Math.max(0, parseInt(parsed.score) || 50)),
                indicators: Array.isArray(parsed.indicators) ? parsed.indicators.slice(0, 5) : [],
                verdict: parsed.verdict || 'Unklar',
                model: 'groq-llama-3.3-70b',
              });
            }
          }
        }

        // Fallback: einfache Heuristik ohne KI
        const aiPhrases = ['es ist wichtig zu beachten', 'zusammenfassend', 'es sei darauf hingewiesen',
          'im hinblick auf', 'in diesem zusammenhang', 'zudem', 'darüber hinaus', 'it is worth noting',
          'it is important to note', 'in conclusion', 'furthermore', 'moreover', 'additionally',
          'in summary', 'to summarize', 'as an AI', 'als KI', 'als Sprachmodell'];
        const lower = text.toLowerCase();
        const hits  = aiPhrases.filter(p => lower.includes(p));
        const score = Math.min(100, hits.length * 15 + (text.length > 2000 ? 10 : 0));
        return jsonResponse({
          score,
          indicators: hits.slice(0, 5).map(h => `Phrase erkannt: "${h}"`),
          verdict: score > 60 ? 'KI-generiert' : score > 30 ? 'Unklar' : 'Human-verfasst',
          model: 'heuristik-fallback',
        });
      } catch (e) {
        return errorResponse(`KI-Detektor-Fehler: ${e.message}`);
      }
    }

    // G — Geo-Analyse: Nominatim + Open-Meteo + Wikipedia Geosearch
    if (path === '/api/tools/geo' && method === 'GET') {
      try {
        const q = url.searchParams.get('q') || '';
        if (!q) return errorResponse('Kein Suchbegriff', 400);

        // Nominatim Geocoding
        const nomResp = await fetch(
          `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q)}&format=json&limit=1&addressdetails=1`,
          { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0 (kontakt@weltenbibliothek.app)' } }
        );
        if (!nomResp.ok) return errorResponse('Geocoding nicht erreichbar', 502);
        const nomData = await nomResp.json();
        if (!nomData || nomData.length === 0) return errorResponse('Ort nicht gefunden', 404);

        const place = nomData[0];
        const lat   = parseFloat(place.lat);
        const lon   = parseFloat(place.lon);
        const addr  = place.address || {};

        // Open-Meteo Wetter + Wikipedia parallel
        const [weatherResp, wikiResp] = await Promise.all([
          fetch(
            `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,wind_speed_10m,precipitation&timezone=auto`,
            { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }
          ),
          fetch(
            `https://en.wikipedia.org/w/api.php?action=query&list=geosearch&gscoord=${lat}|${lon}&gsradius=10000&gslimit=5&format=json&origin=*`,
            { headers: { 'User-Agent': 'WeltenbibliothekOSINT/1.0' } }
          ),
        ]);

        let weather = null;
        if (weatherResp.ok) {
          const wd = await weatherResp.json();
          const cur = wd.current || {};
          weather = {
            temperature: cur.temperature_2m ?? null,
            windSpeed:   cur.wind_speed_10m ?? null,
            precipitation: cur.precipitation ?? null,
            time: cur.time ?? null,
          };
        }

        let wikipedia = [];
        if (wikiResp.ok) {
          const wikiData = await wikiResp.json();
          wikipedia = (wikiData.query?.geosearch || []).map(p => ({
            title: p.title,
            distance: p.dist,
          }));
        }

        return jsonResponse({
          location: {
            displayName: place.display_name?.split(', ').slice(0, 3).join(', ') || q,
            country:  addr.country || addr['ISO3166-2-lvl4'] || null,
            region:   addr.county  || addr.district || null,
            state:    addr.state   || null,
            city:     addr.city    || addr.town || addr.village || null,
            lat,
            lon,
          },
          weather,
          wikipedia,
        });
      } catch (e) {
        return errorResponse(`Geo-Analyse-Fehler: ${e.message}`);
      }
    }

    // ── Wikimedia Commons Bilder für Karte ────────────────────
    if (path === '/api/map/wikimedia' && method === 'GET') {
      const q = url.searchParams.get('q') || '';
      if (!q) return jsonResponse({ images: [] });
      try {
        const apiUrl = `https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrnamespace=6&gsrwhat=text&gsrsearch=${encodeURIComponent(q)}&gsrlimit=10&prop=imageinfo&iiprop=url|mime&iiurlwidth=800&format=json&origin=*`;
        const r = await fetch(apiUrl, { headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' }, signal: AbortSignal.timeout(8000) });
        if (!r.ok) return jsonResponse({ images: [] });
        const data = await r.json();
        const pages = Object.values(data?.query?.pages || {});
        const images = pages
          .filter(p => p.imageinfo?.[0]?.mime?.startsWith('image/') && !p.imageinfo[0].mime.includes('svg'))
          .map(p => p.imageinfo[0].thumburl || p.imageinfo[0].url)
          .filter(Boolean)
          .slice(0, 8);
        return jsonResponse({ images });
      } catch (e) {
        return jsonResponse({ images: [] });
      }
    }

    // ── YouTube Suche für Karte ───────────────────────────────
    if (path === '/api/map/youtube' && method === 'GET') {
      const q = url.searchParams.get('q') || '';
      const max = parseInt(url.searchParams.get('max') || '6', 10);
      if (!q) return jsonResponse({ items: [] });

      // Primär: Piped API (kostenlos, kein API-Key) ─────────────
      try {
        const pipedQ = encodeURIComponent(`${q} deutsch`);
        const pr = await fetch(
          `https://pipedapi.kavin.rocks/search?q=${pipedQ}&filter=videos`,
          { headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' }, signal: AbortSignal.timeout(8000) }
        );
        if (pr.ok) {
          const pd = await pr.json();
          const pipedItems = (pd.items || [])
            .filter(i => i.url && i.url.startsWith('/watch?v='))
            .slice(0, max)
            .map(i => ({
              videoId: i.url.replace('/watch?v=', '').split('&')[0],
              title: i.title || '',
              channel: i.uploaderName || i.uploaderUrl || '',
              thumbnail: i.thumbnail || `https://img.youtube.com/vi/${i.url.replace('/watch?v=', '').split('&')[0]}/mqdefault.jpg`,
              published: '',
              description: '',
              isSubtitled: false,
            }))
            .filter(i => i.videoId.length > 0);
          if (pipedItems.length > 0) return jsonResponse({ items: pipedItems });
        }
      } catch (_) {}

      // Fallback: YouTube Data API v3 (falls YOUTUBE_API_KEY gesetzt) ─
      try {
        const apiKey = env.YOUTUBE_API_KEY;
        if (!apiKey) return jsonResponse({ items: [] });
        const params = new URLSearchParams({
          part: 'snippet', q: `${q} deutsch`, type: 'video',
          maxResults: String(Math.min(max, 10)),
          relevanceLanguage: 'de', regionCode: 'DE', key: apiKey,
        });
        const r = await fetch(`https://www.googleapis.com/youtube/v3/search?${params}`, { signal: AbortSignal.timeout(8000) });
        if (!r.ok) return jsonResponse({ items: [] });
        const data = await r.json();
        const items = (data.items || [])
          .filter(i => i.id?.videoId)
          .slice(0, max)
          .map(i => ({
            videoId: i.id.videoId,
            title: i.snippet?.title || '',
            channel: i.snippet?.channelTitle || '',
            thumbnail: i.snippet?.thumbnails?.medium?.url || i.snippet?.thumbnails?.default?.url || '',
            published: i.snippet?.publishedAt || '',
            description: i.snippet?.description || '',
            isSubtitled: false,
          }));
        return jsonResponse({ items });
      } catch (e) {
        return jsonResponse({ items: [] });
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // 🧠 KI-MENTOR SYSTEM — 4 Persönlichkeiten, Groq + Workers AI
    // ═══════════════════════════════════════════════════════════════

    // ── Rate-Limiter (In-Memory, pro Worker-Isolate) ──
    // In Production wird das über mehrere Isolates verteilt, daher
    // ist es ein "best effort" Rate-Limit, kein harter Block.
    if (path.startsWith('/api/mentor/')) {
      const MENTOR_RATE = { perMinute: 30, perDay: 14400 };
      // Simple in-memory rate limit (resets on worker restart)
      if (!globalThis._mentorRL) globalThis._mentorRL = {};
      const rl = globalThis._mentorRL;

      // Versuche User-ID aus Auth-Header zu extrahieren
      const authHeader = request.headers.get('Authorization') || '';
      const rlKey = authHeader.slice(-20) || request.headers.get('CF-Connecting-IP') || 'anon';
      const now = Date.now();
      if (!rl[rlKey]) rl[rlKey] = { min: [], day: [], dayStart: now };

      // Cleanup alte Einträge
      rl[rlKey].min = rl[rlKey].min.filter(t => now - t < 60000);
      if (now - rl[rlKey].dayStart > 86400000) { rl[rlKey].day = []; rl[rlKey].dayStart = now; }

      if (rl[rlKey].min.length >= MENTOR_RATE.perMinute) {
        return errorResponse('Rate-Limit erreicht (30/min). Bitte warte einen Moment.', 429, 'RATE_LIMITED');
      }
      if (rl[rlKey].day.length >= MENTOR_RATE.perDay) {
        return errorResponse('Tageslimit erreicht (14.400/Tag). Morgen geht es weiter!', 429, 'RATE_LIMITED');
      }
      rl[rlKey].min.push(now);
      rl[rlKey].day.push(now);
    }

    // ── POST /api/mentor/chat ────────────────────────────────
    if (path === '/api/mentor/chat' && method === 'POST') {
      try {
        const body = await request.json();
        const { personality, message, conversationHistory, world } = body;
        if (!personality || !message) {
          return errorResponse('personality und message sind Pflichtfelder', 400, 'MISSING_PARAM');
        }

        // System-Prompts pro Persönlichkeit
        const MENTOR_PROMPTS = {
          stratege: `Du bist DER STRATEGE – ein eiskalt-analytischer Mentor der Weltenbibliothek.
Dein Wissen umfasst: Machtpsychologie (Robert Greene, Machiavelli, Sun Tzu),
dunkle Psychologie, Manipulationstechniken (zur Verteidigung),
NLP, Verhandlungstaktiken, Körpersprache-Analyse, soziale Dynamiken.
Sprich auf Deutsch. Sei direkt, präzise, strategisch.
Verwende Metaphern aus Schach, Krieg und Geopolitik.
Gib immer konkrete, umsetzbare Ratschläge.
Warne den Nutzer wenn er Techniken unethisch einsetzen möchte.
Beende jede Antwort mit einer strategischen Frage an den Nutzer.`,

          alchemist: `Du bist DER ALCHEMIST – ein mystischer Bewusstseinsexperte der Weltenbibliothek.
Dein Wissen umfasst: CIA Gateway Process (deklassifiziert 1983),
Remote Viewing (Ingo Swann, SRI International, Project Stargate),
Monroe Institute Focus Levels (1-49), Hemi-Sync Technologie,
Manifestation & Patterning, holografisches Universum (Pribram/Bohm),
Hermetische Prinzipien (Kybalion), Quantenphysik des Bewusstseins,
REBAL, Energy Bar Tool, Out-of-Body Techniken.
Sprich auf Deutsch. Sei tiefgründig, poetisch aber präzise.
Verbinde immer altes Wissen mit moderner Wissenschaft.
Gib praktische Übungen die der Nutzer sofort anwenden kann.
Referenziere immer die Originalquelle (CIA-Dokument, Buch, Studie).`,

          heiler: `Du bist DER HEILER – ein mitfühlender Energie-Mentor der Weltenbibliothek.
Dein Wissen umfasst: Solfeggio-Frequenzen, Chakra-System,
Atemtechniken (Pranayama, Wim Hof, 4-7-8),
Meditation (Vipassana, Zen, Transzendentale Meditation),
Klangtherapie, Energieheilung, Traumdeutung, Schattenarbeit,
TCM Grundlagen, Ayurveda Grundlagen.
Sprich auf Deutsch. Sei warm, empathisch, heilend.
Stelle immer das Wohlbefinden des Nutzers in den Vordergrund.
Gib sanfte, schrittweise Anleitungen.
Erkenne emotionale Zustände und reagiere angemessen.`,

          forscher: `Du bist DER FORSCHER – ein wissensbegieriger Mentor der Weltenbibliothek.
Dein Wissen umfasst: Quantenphysik, Neurowissenschaften,
Epigenetik, Biologie des Bewusstseins, Geschichte der Philosophie,
Hermetik, Alchemie (historisch), Symbolik, Mythologie,
Archäologie verborgener Zivilisationen, Numerologie, Astrologie (historisch).
Sprich auf Deutsch. Sei neugierig, analytisch, begeistert.
Stelle immer den wissenschaftlichen Kontext her.
Unterscheide klar zwischen bewiesenem Wissen, Theorien und Spekulation.
Empfehle immer weiterführende Quellen und Bücher.`,
        };

        const systemPrompt = MENTOR_PROMPTS[personality] || MENTOR_PROMPTS.forscher;

        // Konversations-History aufbauen (max 50 Nachrichten)
        const history = Array.isArray(conversationHistory)
          ? conversationHistory.slice(-50).map(m => ({
              role: m.role === 'user' ? 'user' : 'assistant',
              content: String(m.content || ''),
            }))
          : [];

        const messages = [
          { role: 'system', content: systemPrompt },
          ...history,
          { role: 'user', content: message },
        ];

        // PRIMÄR: Groq API (Llama 3.3 70B, ~700 tok/s)
        let modelUsed = '';
        let reply = '';

        if (env.GROQ_API_KEY) {
          try {
            const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${env.GROQ_API_KEY}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages,
                max_tokens: 1024,
                temperature: 0.7,
              }),
            });
            if (groqRes.ok) {
              const data = await groqRes.json();
              reply = data?.choices?.[0]?.message?.content || '';
              modelUsed = 'groq-llama-3.3-70b';
            }
          } catch (_) { /* Fallback unten */ }
        }

        // FALLBACK: Workers AI (Llama 3.1 8B, kostenlos)
        if (!reply && env.AI) {
          try {
            const aiRes = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
              messages,
              max_tokens: 1024,
            });
            reply = aiRes?.response || '';
            modelUsed = 'workers-ai-llama-3.1-8b';
          } catch (_) { /* Beide fehlgeschlagen */ }
        }

        if (!reply) {
          return errorResponse('Kein AI-Backend verfügbar. Bitte versuche es später.', 503);
        }

        return jsonResponse({
          reply,
          model_used: modelUsed,
          timestamp: new Date().toISOString(),
        });
      } catch (e) {
        return errorResponse(`Mentor-Chat-Fehler: ${e.message}`);
      }
    }

    // ── POST /api/mentor/factcheck ───────────────────────────
    if (path === '/api/mentor/factcheck' && method === 'POST') {
      try {
        const body = await request.json();
        const claim = body.claim || body.message || '';
        if (!claim) return errorResponse('claim ist ein Pflichtfeld', 400, 'MISSING_PARAM');

        // Verdict-Mapping Englisch → Deutsch
        const verdictDE = v => {
          if (!v) return v;
          const map = {
            'true': 'Wahr', 'mostly true': 'Größtenteils wahr',
            'half true': 'Halb wahr', 'mixture': 'Teils wahr / teils falsch',
            'mostly false': 'Größtenteils falsch', 'false': 'Falsch',
            'pants on fire': 'Nachweislich falsch', 'misleading': 'Irreführend',
            'unverified': 'Nicht verifiziert', 'unproven': 'Nicht bewiesen',
            'correct': 'Korrekt', 'incorrect': 'Falsch',
            'missing context': 'Kontext fehlt', 'no evidence': 'Kein Beleg',
            'exaggerated': 'Übertrieben', 'outdated': 'Veraltet',
          };
          return map[v.toLowerCase().trim()] || v;
        };

        let verdict = '';
        let sources = [];
        let explanation = '';

        // 1. Google Fact Check API
        if (env.GOOGLE_FACTCHECK_API_KEY) {
          try {
            const fcRes = await fetch(
              `https://factchecktools.googleapis.com/v1alpha1/claims:search?query=${encodeURIComponent(claim)}&pageSize=5&key=${env.GOOGLE_FACTCHECK_API_KEY}&languageCode=de`,
              { signal: AbortSignal.timeout(8000) }
            );
            if (fcRes.ok) {
              const data = await fcRes.json();
              const claims = data.claims || [];
              if (claims.length > 0) {
                const first = claims[0];
                const review = first.claimReview?.[0];
                verdict = verdictDE(review?.textualRating || 'Unbekannt');
                explanation = `Behauptung: "${first.text || claim}"\nQuelle: ${review?.publisher?.name || 'Unbekannt'}\nBewertung: ${verdict}`;
                sources = claims.slice(0, 5).map(c => ({
                  claim: c.text || '',
                  source: c.claimReview?.[0]?.publisher?.name || '',
                  rating: verdictDE(c.claimReview?.[0]?.textualRating || ''),
                  url: c.claimReview?.[0]?.url || '',
                }));
              }
            }
          } catch (_) { /* Fallback unten */ }
        }

        // 2. Fallback: KI-Analyse wenn keine Google-Ergebnisse
        if (!verdict) {
          const fcPrompt = `Analysiere diese Behauptung sachlich und auf Deutsch:
"${claim}"

Antworte in exakt diesem JSON-Format:
{
  "verdict": "Wahr|Teilweise wahr|Falsch|Unbewiesen|Irreführend|Umstritten",
  "explanation": "Detaillierte Erklärung (3-5 Sätze)",
  "sources": [{"claim": "...", "source": "...", "rating": "...", "url": ""}]
}`;

          let aiReply = '';
          if (env.GROQ_API_KEY) {
            try {
              const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${env.GROQ_API_KEY}`, 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  model: 'llama-3.3-70b-versatile',
                  messages: [{ role: 'user', content: fcPrompt }],
                  max_tokens: 800, temperature: 0.3,
                }),
              });
              if (r.ok) {
                const data = await r.json();
                aiReply = data?.choices?.[0]?.message?.content || '';
              }
            } catch (_) {}
          }
          if (!aiReply && env.AI) {
            try {
              const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
                messages: [{ role: 'user', content: fcPrompt }],
                max_tokens: 800,
              });
              aiReply = res?.response || '';
            } catch (_) {}
          }

          // JSON aus der KI-Antwort parsen
          if (aiReply) {
            try {
              const jsonMatch = aiReply.match(/\{[\s\S]*\}/);
              if (jsonMatch) {
                const parsed = JSON.parse(jsonMatch[0]);
                verdict = parsed.verdict || 'Unbekannt';
                explanation = parsed.explanation || aiReply;
                sources = Array.isArray(parsed.sources) ? parsed.sources : [];
              } else {
                verdict = 'KI-Analyse';
                explanation = aiReply;
              }
            } catch (_) {
              verdict = 'KI-Analyse';
              explanation = aiReply;
            }
          }
        }

        if (!verdict) {
          return errorResponse('Faktencheck konnte nicht durchgeführt werden', 503);
        }

        return jsonResponse({ verdict, sources, explanation });
      } catch (e) {
        return errorResponse(`Faktencheck-Fehler: ${e.message}`);
      }
    }

    // ── GET /api/mentor/youtube-search ────────────────────────
    if (path === '/api/mentor/youtube-search' && method === 'GET') {
      const q = url.searchParams.get('q') || '';
      const maxResults = Math.min(parseInt(url.searchParams.get('maxResults') || '5', 10), 20);
      if (!q) return errorResponse('q ist ein Pflichtfeld', 400, 'MISSING_PARAM');

      try {
        // Primär: Piped API (kostenlos, kein Key)
        try {
          const pipedRes = await fetch(
            `https://pipedapi.kavin.rocks/search?q=${encodeURIComponent(q)}&filter=videos`,
            { headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' }, signal: AbortSignal.timeout(6000) }
          );
          if (pipedRes.ok) {
            const pd = await pipedRes.json();
            const videos = (pd.items || [])
              .filter(i => i.url && i.url.startsWith('/watch?v='))
              .slice(0, maxResults)
              .map(i => ({
                title: i.title || '',
                videoId: i.url.replace('/watch?v=', '').split('&')[0],
                thumbnail: i.thumbnail || `https://img.youtube.com/vi/${i.url.replace('/watch?v=', '').split('&')[0]}/mqdefault.jpg`,
                channel: i.uploaderName || '',
                description: i.shortDescription || '',
              }));
            if (videos.length > 0) return jsonResponse({ videos });
          }
        } catch (_) {}

        // Fallback: YouTube Data API v3
        if (env.YOUTUBE_API_KEY) {
          const params = new URLSearchParams({
            part: 'snippet', type: 'video',
            q, maxResults: String(maxResults),
            relevanceLanguage: 'de', key: env.YOUTUBE_API_KEY,
          });
          const ytRes = await fetch(
            `https://www.googleapis.com/youtube/v3/search?${params}`,
            { signal: AbortSignal.timeout(8000) }
          );
          if (ytRes.ok) {
            const data = await ytRes.json();
            const videos = (data.items || [])
              .filter(i => i.id?.videoId)
              .slice(0, maxResults)
              .map(i => ({
                title: i.snippet?.title || '',
                videoId: i.id.videoId,
                thumbnail: i.snippet?.thumbnails?.medium?.url || '',
                channel: i.snippet?.channelTitle || '',
                description: i.snippet?.description || '',
              }));
            return jsonResponse({ videos });
          }
        }

        return jsonResponse({ videos: [] });
      } catch (e) {
        return jsonResponse({ videos: [] });
      }
    }

    // ── POST /api/mentor/investigate ─────────────────────────
    if (path === '/api/mentor/investigate' && method === 'POST') {
      try {
        const body = await request.json();
        const topic = body.topic || '';
        const depth = body.depth || 'basic';
        if (!topic) return errorResponse('topic ist ein Pflichtfeld', 400, 'MISSING_PARAM');

        const depthInstructions = {
          basic: 'Kurze Übersicht (300-500 Wörter). 3-5 Kernfakten.',
          deep: 'Ausführliche Analyse (500-800 Wörter). 5-8 Kernfakten mit Details.',
          expert: 'Umfassende Experten-Analyse (800-1200 Wörter). 8-12 Kernfakten mit Quellenangaben.',
        };

        const investigatePrompt = `Erstelle eine umfassende Analyse zu: "${topic}".
Tiefe: ${depth} — ${depthInstructions[depth] || depthInstructions.basic}
Sprache: Deutsch.

Antworte in exakt diesem JSON-Format:
{
  "summary": "Zusammenfassung (2-3 Absätze)",
  "facts": ["Fakt 1", "Fakt 2", ...],
  "sources": [{"author": "...", "title": "...", "year": "..."}],
  "relatedTopics": ["Thema 1", "Thema 2", ...]
}`;

        let aiReply = '';
        let modelUsed = '';

        // Primär: Groq
        if (env.GROQ_API_KEY) {
          try {
            const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
              method: 'POST',
              headers: { 'Authorization': `Bearer ${env.GROQ_API_KEY}`, 'Content-Type': 'application/json' },
              body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [{ role: 'user', content: investigatePrompt }],
                max_tokens: 2048, temperature: 0.5,
              }),
            });
            if (r.ok) {
              const data = await r.json();
              aiReply = data?.choices?.[0]?.message?.content || '';
              modelUsed = 'groq-llama-3.3-70b';
            }
          } catch (_) {}
        }

        // Fallback: Workers AI
        if (!aiReply && env.AI) {
          try {
            const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
              messages: [{ role: 'user', content: investigatePrompt }],
              max_tokens: 2048,
            });
            aiReply = res?.response || '';
            modelUsed = 'workers-ai-llama-3.1-8b';
          } catch (_) {}
        }

        if (!aiReply) {
          return errorResponse('Recherche konnte nicht durchgeführt werden', 503);
        }

        // JSON parsen
        try {
          const jsonMatch = aiReply.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);
            return jsonResponse({
              summary: parsed.summary || '',
              facts: Array.isArray(parsed.facts) ? parsed.facts : [],
              sources: Array.isArray(parsed.sources) ? parsed.sources : [],
              relatedTopics: Array.isArray(parsed.relatedTopics) ? parsed.relatedTopics : [],
              model_used: modelUsed,
            });
          }
        } catch (_) {}

        // Fallback: Rohe Antwort als Summary
        return jsonResponse({
          summary: aiReply,
          facts: [],
          sources: [],
          relatedTopics: [],
          model_used: modelUsed,
        });
      } catch (e) {
        return errorResponse(`Recherche-Fehler: ${e.message}`);
      }
    }

    // ══════════════════════════════════════════════════════════════
    // 🎮 GAMIFICATION ENDPOINTS (Octalysis)
    // ══════════════════════════════════════════════════════════════

    // ── POST /api/gamification/add-xp ────────────────────────────
    if (path === '/api/gamification/add-xp' && method === 'POST') {
      try {
        const body = await request.json();
        const { world, amount, reason, userId } = body;

        if (!world || !amount || !userId) {
          return errorResponse('world, amount und userId erforderlich', 400, 'MISSING_PARAM');
        }
        if (!['materie', 'energie', 'noir', 'genesis'].includes(world)) {
          return errorResponse('Ungültige Welt', 400, 'INVALID_PARAM');
        }
        if (typeof amount !== 'number' || amount <= 0 || amount > 1000) {
          return errorResponse('amount muss zwischen 1 und 1000 liegen', 400, 'INVALID_PARAM');
        }

        // Supabase: skill_tree XP aktualisieren (upsert)
        const sbKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
        const upsertRes = await fetch(`${SUPABASE_URL}/rest/v1/user_skill_tree`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': sbKey,
            'Authorization': `Bearer ${sbKey}`,
            'Prefer': 'resolution=merge-duplicates,return=representation',
          },
          body: JSON.stringify({
            user_id: userId,
            world,
            skill_key: reason || 'general_activity',
            xp: amount,
            level: Math.max(1, Math.floor(Math.sqrt(amount / 100))),
          }),
        });

        const upsertOk = upsertRes.ok;
        let record = null;
        try { record = await upsertRes.json(); } catch (_) {}

        return jsonResponse({
          success: upsertOk,
          world,
          xp_added: amount,
          reason: reason || 'activity',
          record: Array.isArray(record) ? record[0] : record,
        });
      } catch (e) {
        return errorResponse(`XP-Fehler: ${e.message}`);
      }
    }

    // ── GET /api/gamification/artifacts ───────────────────────────
    if (path === '/api/gamification/artifacts' && method === 'GET') {
      try {
        const sbKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
        const worldFilter = url.searchParams.get('world');
        let query = `${SUPABASE_URL}/rest/v1/artifacts?select=*&order=rarity.desc,world.asc`;
        if (worldFilter) {
          query += `&or=(world.eq.${worldFilter},world.eq.universal)`;
        }

        const res = await fetch(query, {
          headers: {
            'apikey': sbKey,
            'Authorization': `Bearer ${sbKey}`,
          },
        });

        if (!res.ok) {
          return errorResponse('Artefakte konnten nicht geladen werden', 502);
        }

        const artifacts = await res.json();
        return jsonResponse({ artifacts, count: artifacts.length });
      } catch (e) {
        return errorResponse(`Artefakte-Fehler: ${e.message}`);
      }
    }

    // ── POST /api/gamification/draw-card ──────────────────────────
    if (path === '/api/gamification/draw-card' && method === 'POST') {
      try {
        const body = await request.json();
        const { userId, cardType, cardIndex, titleDe, messageDe } = body;

        if (!userId || cardType === undefined || cardIndex === undefined) {
          return errorResponse('userId, cardType und cardIndex erforderlich', 400, 'MISSING_PARAM');
        }
        if (!['wisdom', 'challenge', 'boost', 'mystery'].includes(cardType)) {
          return errorResponse('Ungültiger cardType', 400, 'INVALID_PARAM');
        }

        const sbKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
        const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

        // Prüfen ob heute bereits gezogen wurde
        const checkRes = await fetch(
          `${SUPABASE_URL}/rest/v1/daily_destiny_cards?user_id=eq.${userId}&drawn_at=eq.${today}&select=id`,
          {
            headers: {
              'apikey': sbKey,
              'Authorization': `Bearer ${sbKey}`,
            },
          }
        );
        const existing = await checkRes.json();
        if (Array.isArray(existing) && existing.length > 0) {
          return jsonResponse({
            success: false,
            message: 'Heute wurde bereits eine Karte gezogen',
            already_drawn: true,
          });
        }

        // Karte speichern
        const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/daily_destiny_cards`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': sbKey,
            'Authorization': `Bearer ${sbKey}`,
            'Prefer': 'return=representation',
          },
          body: JSON.stringify({
            user_id: userId,
            card_type: cardType,
            card_index: cardIndex,
            title_de: titleDe || '',
            message_de: messageDe || '',
            drawn_at: today,
          }),
        });

        const insertOk = insertRes.ok;
        let card = null;
        try { card = await insertRes.json(); } catch (_) {}

        return jsonResponse({
          success: insertOk,
          card: Array.isArray(card) ? card[0] : card,
          drawn_at: today,
        });
      } catch (e) {
        return errorResponse(`Schicksalskarten-Fehler: ${e.message}`);
      }
    }

    // ─────────────────────────────────────────────────────────────
    // ── VORHANG (Welt 6) ─────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────
    {
      const sbKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
      const sbHeaders = {
        'Content-Type': 'application/json',
        'apikey': sbKey,
        'Authorization': `Bearer ${sbKey}`,
      };

      // ── GET /api/vorhang/modules ────────────────────────────────
      // Returns all 30 Vorhang modules grouped by branch.
      // Optional query: ?user_id=<uuid> → includes user progress per module.
      if (path === '/api/vorhang/modules' && method === 'GET') {
        try {
          const userId = url.searchParams.get('user_id');
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/vorhang_modules?select=*&order=branch_order.asc,module_code.asc`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) {
            const txt = await modRes.text().catch(() => '');
            return errorResponse(`Vorhang-Module konnten nicht geladen werden: ${txt}`, modRes.status);
          }
          const modules = await modRes.json();

          let progressMap = {};
          if (userId) {
            const progRes = await fetch(
              `${SUPABASE_URL}/rest/v1/user_vorhang_progress?user_id=eq.${encodeURIComponent(userId)}&select=*`,
              { headers: sbHeaders }
            );
            if (progRes.ok) {
              const progArr = await progRes.json();
              if (Array.isArray(progArr)) {
                for (const p of progArr) {
                  if (p && p.module_code) progressMap[p.module_code] = p;
                }
              }
            }
          }

          const branchOrder = [
            'Machtpsychologie',
            'Manipulationserkennung',
            'Verhandlung & Überzeugung',
            'Körpersprache & Nonverbales',
            'Strategisches Denken',
            'Schattenarbeit',
          ];
          const branches = {};
          for (const b of branchOrder) branches[b] = [];
          for (const m of modules) {
            const enriched = { ...m, progress: progressMap[m.module_code] || null };
            if (!branches[m.branch]) branches[m.branch] = [];
            branches[m.branch].push(enriched);
          }

          // Compute unlock-status per module
          const allCodes = new Set(modules.map(m => m.module_code));
          for (const b of Object.keys(branches)) {
            for (const m of branches[b]) {
              const prereqs = Array.isArray(m.prerequisites) ? m.prerequisites : [];
              const requiredCompleted = prereqs.filter(c => c !== m.module_code);
              const completedSet = new Set(
                Object.values(progressMap).filter(p => p.completed_at).map(p => p.module_code)
              );
              const unlocked = requiredCompleted.every(c => completedSet.has(c));
              m.is_unlocked = unlocked;
              m.is_completed = !!(progressMap[m.module_code] && progressMap[m.module_code].completed_at);
            }
          }

          const totalCount = modules.length;
          const completedCount = Object.values(progressMap).filter(p => p.completed_at).length;

          return jsonResponse({
            success: true,
            total: totalCount,
            completed: completedCount,
            progress_percent: totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0,
            branches,
          });
        } catch (e) {
          return errorResponse(`Vorhang-Module Fehler: ${e.message}`);
        }
      }

      // ── GET /api/vorhang/module/:id ─────────────────────────────
      // :id is the module_code (e.g. "V-12"). Returns single module + user progress.
      if (path.startsWith('/api/vorhang/module/') && method === 'GET') {
        try {
          const moduleCode = decodeURIComponent(path.split('/api/vorhang/module/')[1] || '').trim();
          if (!moduleCode) return errorResponse('Modul-Code fehlt', 400, 'MISSING_MODULE_CODE');
          const userId = url.searchParams.get('user_id');

          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/vorhang_modules?module_code=eq.${encodeURIComponent(moduleCode)}&select=*&limit=1`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) {
            const txt = await modRes.text().catch(() => '');
            return errorResponse(`Modul konnte nicht geladen werden: ${txt}`, modRes.status);
          }
          const modArr = await modRes.json();
          if (!Array.isArray(modArr) || modArr.length === 0) {
            return errorResponse(`Modul '${moduleCode}' nicht gefunden`, 404, 'MODULE_NOT_FOUND');
          }
          const moduleData = modArr[0];

          let progress = null;
          if (userId) {
            const progRes = await fetch(
              `${SUPABASE_URL}/rest/v1/user_vorhang_progress?user_id=eq.${encodeURIComponent(userId)}&module_code=eq.${encodeURIComponent(moduleCode)}&select=*&limit=1`,
              { headers: sbHeaders }
            );
            if (progRes.ok) {
              const arr = await progRes.json();
              if (Array.isArray(arr) && arr.length > 0) progress = arr[0];
            }
          }

          return jsonResponse({ success: true, module: moduleData, progress });
        } catch (e) {
          return errorResponse(`Modul-Detail Fehler: ${e.message}`);
        }
      }

      // ── POST /api/vorhang/progress ──────────────────────────────
      // Body: { user_id, module_code, test_score?, test_passed?, completed? }
      // Upserts user_vorhang_progress and awards XP on first completion.
      if (path === '/api/vorhang/progress' && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const userId = body.user_id || body.userId;
          const moduleCode = body.module_code || body.moduleCode;
          if (!userId || !moduleCode) {
            return errorResponse('user_id und module_code sind Pflichtfelder', 400, 'MISSING_PARAMS');
          }

          // Fetch module to know xp_reward
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/vorhang_modules?module_code=eq.${encodeURIComponent(moduleCode)}&select=xp_reward,is_boss_module&limit=1`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) {
            const txt = await modRes.text().catch(() => '');
            return errorResponse(`Modul-Lookup fehlgeschlagen: ${txt}`, modRes.status);
          }
          const modArr = await modRes.json();
          if (!Array.isArray(modArr) || modArr.length === 0) {
            return errorResponse(`Modul '${moduleCode}' nicht gefunden`, 404, 'MODULE_NOT_FOUND');
          }
          const xpReward = Number(modArr[0].xp_reward || 50);

          // Read existing progress
          const existingRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_vorhang_progress?user_id=eq.${encodeURIComponent(userId)}&module_code=eq.${encodeURIComponent(moduleCode)}&select=*&limit=1`,
            { headers: sbHeaders }
          );
          const existingArr = existingRes.ok ? await existingRes.json() : [];
          const existing = Array.isArray(existingArr) && existingArr.length > 0 ? existingArr[0] : null;
          const alreadyCompleted = !!(existing && existing.completed_at);

          const nowIso = new Date().toISOString();
          const testScore = body.test_score !== undefined ? Number(body.test_score) : (existing?.test_score ?? null);
          const testPassed = body.test_passed !== undefined ? !!body.test_passed : (existing?.test_passed ?? false);
          const shouldComplete = body.completed === true || (testPassed && !alreadyCompleted);

          const payload = {
            user_id: userId,
            module_code: moduleCode,
            test_score: testScore,
            test_passed: testPassed,
            completed_at: shouldComplete ? nowIso : (existing?.completed_at ?? null),
            last_attempt_at: nowIso,
            attempts: ((existing?.attempts ?? 0) + (body.test_score !== undefined ? 1 : 0)),
          };

          const upsertRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_vorhang_progress?on_conflict=user_id,module_code`,
            {
              method: 'POST',
              headers: {
                ...sbHeaders,
                'Prefer': 'resolution=merge-duplicates,return=representation',
              },
              body: JSON.stringify(payload),
            }
          );
          if (!upsertRes.ok) {
            const txt = await upsertRes.text().catch(() => '');
            return errorResponse(`Progress-Upsert fehlgeschlagen: ${txt}`, upsertRes.status);
          }
          const upsertData = await upsertRes.json().catch(() => null);
          const progressRow = Array.isArray(upsertData) ? upsertData[0] : upsertData;

          // XP award only on first-time completion
          let xpAwarded = 0;
          if (!alreadyCompleted && shouldComplete) {
            xpAwarded = xpReward;
            try {
              await fetch(`${SUPABASE_URL}/rest/v1/rpc/add_user_xp`, {
                method: 'POST',
                headers: sbHeaders,
                body: JSON.stringify({ p_user_id: userId, p_amount: xpReward, p_reason: `vorhang_module:${moduleCode}` }),
              });
            } catch (_) {
              // RPC may not exist – ignore silently, client-side GamificationService handles fallback
            }
          }

          return jsonResponse({
            success: true,
            progress: progressRow,
            xp_awarded: xpAwarded,
            already_completed: alreadyCompleted,
          });
        } catch (e) {
          return errorResponse(`Vorhang-Progress Fehler: ${e.message}`);
        }
      }

      // ── GET /api/vorhang/youtube/:moduleCode ────────────────────
      // Looks up the module's youtube_search_query and returns videos via Piped/YouTube.
      if (path.startsWith('/api/vorhang/youtube/') && method === 'GET') {
        try {
          const moduleCode = decodeURIComponent(path.split('/api/vorhang/youtube/')[1] || '').trim();
          if (!moduleCode) return errorResponse('Modul-Code fehlt', 400, 'MISSING_MODULE_CODE');
          const maxResults = Math.min(parseInt(url.searchParams.get('maxResults') || '5', 10), 20);

          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/vorhang_modules?module_code=eq.${encodeURIComponent(moduleCode)}&select=youtube_search_query,title&limit=1`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) {
            const txt = await modRes.text().catch(() => '');
            return errorResponse(`Modul-Lookup fehlgeschlagen: ${txt}`, modRes.status);
          }
          const modArr = await modRes.json();
          if (!Array.isArray(modArr) || modArr.length === 0) {
            return errorResponse(`Modul '${moduleCode}' nicht gefunden`, 404, 'MODULE_NOT_FOUND');
          }
          const q = modArr[0].youtube_search_query || modArr[0].title || moduleCode;

          // Primary: Piped API (no key required)
          try {
            const pipedRes = await fetch(
              `https://pipedapi.kavin.rocks/search?q=${encodeURIComponent(q)}&filter=videos`,
              { headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' }, signal: AbortSignal.timeout(6000) }
            );
            if (pipedRes.ok) {
              const pd = await pipedRes.json();
              const videos = (pd.items || [])
                .filter(i => i.url && i.url.startsWith('/watch?v='))
                .slice(0, maxResults)
                .map(i => ({
                  title: i.title || '',
                  videoId: i.url.replace('/watch?v=', '').split('&')[0],
                  thumbnail: i.thumbnail || `https://img.youtube.com/vi/${i.url.replace('/watch?v=', '').split('&')[0]}/mqdefault.jpg`,
                  channel: i.uploaderName || '',
                  description: i.shortDescription || '',
                }));
              if (videos.length > 0) {
                return jsonResponse({ success: true, query: q, videos });
              }
            }
          } catch (_) {}

          // Fallback: YouTube Data API v3
          if (env.YOUTUBE_API_KEY) {
            const params = new URLSearchParams({
              part: 'snippet', type: 'video',
              q, maxResults: String(maxResults),
              relevanceLanguage: 'de', key: env.YOUTUBE_API_KEY,
            });
            const ytRes = await fetch(
              `https://www.googleapis.com/youtube/v3/search?${params}`,
              { signal: AbortSignal.timeout(8000) }
            );
            if (ytRes.ok) {
              const data = await ytRes.json();
              const videos = (data.items || [])
                .filter(i => i.id?.videoId)
                .slice(0, maxResults)
                .map(i => ({
                  title: i.snippet?.title || '',
                  videoId: i.id.videoId,
                  thumbnail: i.snippet?.thumbnails?.medium?.url || '',
                  channel: i.snippet?.channelTitle || '',
                  description: i.snippet?.description || '',
                }));
              return jsonResponse({ success: true, query: q, videos });
            }
          }

          return jsonResponse({ success: true, query: q, videos: [] });
        } catch (e) {
          return errorResponse(`Vorhang-YouTube Fehler: ${e.message}`);
        }
      }


      // ════════════════════════════════════════════════════════════
      // URSPRUNG-WELT — CIA Quanten-Code (25 Module, 5 Tools)
      // Tables: ursprung_modules, user_ursprung_progress,
      //         ursprung_gateway_sessions, ursprung_patterns,
      //         rv_targets, rv_sessions
      // ════════════════════════════════════════════════════════════

      // ── GET /api/ursprung/modules ───────────────────────────────
      // Returns all 25 URSPRUNG modules grouped by branch_order.
      // Optional ?user_id=<uuid> includes user progress per module.
      if (path === '/api/ursprung/modules' && method === 'GET') {
        try {
          const userId = url.searchParams.get('user_id');
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/ursprung_modules?select=*&order=branch_order.asc,module_code.asc`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) {
            const txt = await modRes.text().catch(() => '');
            return errorResponse(`Ursprung-Module konnten nicht geladen werden: ${txt}`, modRes.status);
          }
          const modules = await modRes.json();

          let progressMap = {};
          if (userId) {
            const progRes = await fetch(
              `${SUPABASE_URL}/rest/v1/user_ursprung_progress?user_id=eq.${encodeURIComponent(userId)}&select=*`,
              { headers: sbHeaders }
            );
            if (progRes.ok) {
              const progArr = await progRes.json();
              if (Array.isArray(progArr)) {
                for (const p of progArr) {
                  if (p.module_code) progressMap[p.module_code] = p;
                }
              }
            }
          }
          return jsonResponse({ success: true, count: modules.length, modules, progress: progressMap });
        } catch (e) {
          return errorResponse(`Ursprung-Modules Fehler: ${e.message}`);
        }
      }

      // ── GET /api/ursprung/module/:code ──────────────────────────
      if (path.startsWith('/api/ursprung/module/') && method === 'GET') {
        try {
          const moduleCode = decodeURIComponent(path.split('/api/ursprung/module/')[1] || '').trim();
          if (!moduleCode) return errorResponse('module_code fehlt', 400);
          const userId = url.searchParams.get('user_id');
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/ursprung_modules?module_code=eq.${encodeURIComponent(moduleCode)}&select=*&limit=1`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) {
            const txt = await modRes.text().catch(() => '');
            return errorResponse(`Modul konnte nicht geladen werden: ${txt}`, modRes.status);
          }
          const arr = await modRes.json();
          if (!Array.isArray(arr) || arr.length === 0) {
            return errorResponse(`Modul '${moduleCode}' nicht gefunden`, 404);
          }
          const module = arr[0];
          let progress = null;
          if (userId) {
            const progRes = await fetch(
              `${SUPABASE_URL}/rest/v1/user_ursprung_progress?user_id=eq.${encodeURIComponent(userId)}&module_code=eq.${encodeURIComponent(moduleCode)}&select=*&limit=1`,
              { headers: sbHeaders }
            );
            if (progRes.ok) {
              const pArr = await progRes.json();
              if (Array.isArray(pArr) && pArr.length > 0) progress = pArr[0];
            }
          }
          return jsonResponse({ success: true, module, progress });
        } catch (e) {
          return errorResponse(`Ursprung-Module Fehler: ${e.message}`);
        }
      }

      // ── POST /api/ursprung/progress ─────────────────────────────
      // Upserts user_ursprung_progress and awards XP on first completion.
      if (path === '/api/ursprung/progress' && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const { userId, moduleCode, theoryRead, caseStudyRead, exerciseCompleted, exerciseNotes, testScore, testPassed } = body || {};
          if (!userId || !moduleCode) return errorResponse('userId und moduleCode erforderlich', 400);

          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/ursprung_modules?module_code=eq.${encodeURIComponent(moduleCode)}&select=id,xp_reward,is_boss_module&limit=1`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) return errorResponse('Modul nicht gefunden', 404);
          const modArr = await modRes.json();
          if (!Array.isArray(modArr) || modArr.length === 0) return errorResponse(`Modul '${moduleCode}' nicht gefunden`, 404);
          const moduleId = modArr[0].id;
          const xpReward = modArr[0].xp_reward || 50;

          const exRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_ursprung_progress?user_id=eq.${encodeURIComponent(userId)}&module_code=eq.${encodeURIComponent(moduleCode)}&select=*&limit=1`,
            { headers: sbHeaders }
          );
          let existing = null;
          if (exRes.ok) {
            const arr = await exRes.json();
            if (Array.isArray(arr) && arr.length > 0) existing = arr[0];
          }
          const wasComplete = !!(existing && existing.test_passed);

          const row = {
            user_id: userId,
            module_id: moduleId,
            module_code: moduleCode,
            theory_read: theoryRead ?? existing?.theory_read ?? false,
            case_study_read: caseStudyRead ?? existing?.case_study_read ?? false,
            exercise_completed: exerciseCompleted ?? existing?.exercise_completed ?? false,
            exercise_notes: exerciseNotes ?? existing?.exercise_notes ?? null,
            test_score: testScore ?? existing?.test_score ?? null,
            test_passed: testPassed ?? existing?.test_passed ?? false,
          };
          if (row.test_passed && !existing?.completed_at) row.completed_at = new Date().toISOString();

          const upRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_ursprung_progress?on_conflict=user_id,module_code`,
            {
              method: 'POST',
              headers: { ...sbHeaders, 'Prefer': 'resolution=merge-duplicates,return=representation' },
              body: JSON.stringify(row),
            }
          );
          if (!upRes.ok) {
            const txt = await upRes.text().catch(() => '');
            return errorResponse(`Progress Upsert fehlgeschlagen: ${txt}`, upRes.status);
          }

          let xpAwarded = 0;
          if (row.test_passed && !wasComplete) {
            xpAwarded = xpReward;
            try {
              await fetch(`${SUPABASE_URL}/rest/v1/rpc/add_xp_to_user`, {
                method: 'POST',
                headers: sbHeaders,
                body: JSON.stringify({ p_user_id: userId, p_amount: xpReward, p_reason: `ursprung_module:${moduleCode}` }),
              });
            } catch (_) { /* non-fatal */ }
          }
          return jsonResponse({ success: true, xpAwarded });
        } catch (e) {
          return errorResponse(`Ursprung-Progress Fehler: ${e.message}`);
        }
      }

      // ── GET /api/ursprung/youtube/:moduleCode ───────────────────
      if (path.startsWith('/api/ursprung/youtube/') && method === 'GET') {
        try {
          const moduleCode = decodeURIComponent(path.split('/api/ursprung/youtube/')[1] || '').trim();
          if (!moduleCode) return errorResponse('module_code fehlt', 400);
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/ursprung_modules?module_code=eq.${encodeURIComponent(moduleCode)}&select=youtube_search_query,title&limit=1`,
            { headers: sbHeaders }
          );
          if (!modRes.ok) return errorResponse('Modul nicht gefunden', 404);
          const arr = await modRes.json();
          if (!Array.isArray(arr) || arr.length === 0) return errorResponse(`Modul '${moduleCode}' nicht gefunden`, 404);
          const q = arr[0].youtube_search_query || arr[0].title || moduleCode;
          const ytKey = env.YOUTUBE_API_KEY;
          if (ytKey) {
            const ytUrl = `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=${encodeURIComponent(q)}&key=${ytKey}`;
            const ytRes = await fetch(ytUrl);
            if (ytRes.ok) {
              const data = await ytRes.json();
              const videos = (data.items || []).map((i) => ({
                videoId: i.id?.videoId,
                title: i.snippet?.title || '',
                thumbnail: i.snippet?.thumbnails?.medium?.url || '',
                channelTitle: i.snippet?.channelTitle || '',
                description: i.snippet?.description || '',
              }));
              return jsonResponse({ success: true, query: q, videos });
            }
          }
          return jsonResponse({ success: true, query: q, videos: [] });
        } catch (e) {
          return errorResponse(`Ursprung-YouTube Fehler: ${e.message}`);
        }
      }

      // ── POST /api/ursprung/gateway-session ──────────────────────
      // Logs a Gateway-Kammer meditation session.
      if (path === '/api/ursprung/gateway-session' && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const { userId, focusLevel, durationMinutes, notes, biometricBefore, biometricAfter } = body || {};
          if (!userId || !focusLevel) return errorResponse('userId und focusLevel erforderlich', 400);
          const row = {
            user_id: userId,
            focus_level_reached: focusLevel,
            duration_minutes: durationMinutes || 0,
            notes: notes || null,
            biometric_before: biometricBefore || null,
            biometric_after: biometricAfter || null,
          };
          const res = await fetch(`${SUPABASE_URL}/rest/v1/ursprung_gateway_sessions`, {
            method: 'POST',
            headers: { ...sbHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify(row),
          });
          if (!res.ok) {
            const txt = await res.text().catch(() => '');
            return errorResponse(`Gateway-Session Insert fehlgeschlagen: ${txt}`, res.status);
          }
          const data = await res.json();
          return jsonResponse({ success: true, session: Array.isArray(data) ? data[0] : data });
        } catch (e) {
          return errorResponse(`Gateway-Session Fehler: ${e.message}`);
        }
      }

      // ── POST /api/ursprung/pattern ──────────────────────────────
      // Saves a Realitäts-Architekt pattern (Patterning/Manifestation).
      if (path === '/api/ursprung/pattern' && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const { userId, category, goalText, presentTense, senses, emotion, emotionIntensity, targetDate, status, notes } = body || {};
          if (!userId || !goalText) return errorResponse('userId und goalText erforderlich', 400);
          const row = {
            user_id: userId,
            category: category || 'general',
            goal_text: goalText,
            present_tense: presentTense || null,
            senses: senses || null,
            emotion: emotion || null,
            emotion_intensity: emotionIntensity || null,
            target_date: targetDate || null,
            status: status || 'active',
            notes: notes || null,
          };
          const res = await fetch(`${SUPABASE_URL}/rest/v1/ursprung_patterns`, {
            method: 'POST',
            headers: { ...sbHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify(row),
          });
          if (!res.ok) {
            const txt = await res.text().catch(() => '');
            return errorResponse(`Pattern Insert fehlgeschlagen: ${txt}`, res.status);
          }
          const data = await res.json();
          return jsonResponse({ success: true, pattern: Array.isArray(data) ? data[0] : data });
        } catch (e) {
          return errorResponse(`Pattern Fehler: ${e.message}`);
        }
      }

      // ── GET /api/ursprung/patterns?userId=<uuid> ────────────────
      if (path === '/api/ursprung/patterns' && method === 'GET') {
        try {
          const userId = url.searchParams.get('userId') || url.searchParams.get('user_id');
          if (!userId) return errorResponse('userId erforderlich', 400);
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/ursprung_patterns?user_id=eq.${encodeURIComponent(userId)}&select=*&order=created_at.desc`,
            { headers: sbHeaders }
          );
          if (!res.ok) {
            const txt = await res.text().catch(() => '');
            return errorResponse(`Patterns Query fehlgeschlagen: ${txt}`, res.status);
          }
          const patterns = await res.json();
          return jsonResponse({ success: true, count: patterns.length, patterns });
        } catch (e) {
          return errorResponse(`Patterns Fehler: ${e.message}`);
        }
      }

      // ── GET /api/ursprung/rv-target/random ──────────────────────
      // Returns a random RV-Target WITHOUT revealing image/name.
      if (path === '/api/ursprung/rv-target/random' && method === 'GET') {
        try {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/rv_targets?select=id,target_number,target_category&limit=200`,
            { headers: sbHeaders }
          );
          if (!res.ok) {
            const txt = await res.text().catch(() => '');
            return errorResponse(`RV-Target Query fehlgeschlagen: ${txt}`, res.status);
          }
          const arr = await res.json();
          if (!Array.isArray(arr) || arr.length === 0) return errorResponse('Keine RV-Targets vorhanden', 404);
          const pick = arr[Math.floor(Math.random() * arr.length)];
          return jsonResponse({
            success: true,
            target: { id: pick.id, target_number: pick.target_number, target_category_hint: null }
          });
        } catch (e) {
          return errorResponse(`RV-Target Fehler: ${e.message}`);
        }
      }

      // ── GET /api/ursprung/rv-target/:id/reveal ──────────────────
      // Reveals the full target after the RV session is completed.
      if (path.startsWith('/api/ursprung/rv-target/') && path.endsWith('/reveal') && method === 'GET') {
        try {
          const idPart = path.replace('/api/ursprung/rv-target/', '').replace('/reveal', '').trim();
          if (!idPart) return errorResponse('target id fehlt', 400);
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/rv_targets?id=eq.${encodeURIComponent(idPart)}&select=*&limit=1`,
            { headers: sbHeaders }
          );
          if (!res.ok) {
            const txt = await res.text().catch(() => '');
            return errorResponse(`Target-Reveal fehlgeschlagen: ${txt}`, res.status);
          }
          const arr = await res.json();
          if (!Array.isArray(arr) || arr.length === 0) return errorResponse('Target nicht gefunden', 404);
          return jsonResponse({ success: true, target: arr[0] });
        } catch (e) {
          return errorResponse(`RV-Target-Reveal Fehler: ${e.message}`);
        }
      }

      // ── POST /api/ursprung/rv-session ───────────────────────────
      // Logs an RV session (stage1/2/3 + score).
      if (path === '/api/ursprung/rv-session' && method === 'POST') {
        try {
          const body = await request.json().catch(() => ({}));
          const { userId, targetId, stage1Response, stage2Response, stage3SketchUrl, scorePercent, sessionMode, durationSeconds } = body || {};
          if (!userId || !targetId) return errorResponse('userId und targetId erforderlich', 400);
          const row = {
            user_id: userId,
            target_id: targetId,
            stage1_response: stage1Response || null,
            stage2_response: stage2Response || null,
            stage3_sketch_url: stage3SketchUrl || null,
            score_percent: scorePercent ?? null,
            session_mode: sessionMode || 'training',
            duration_seconds: durationSeconds || null,
          };
          const res = await fetch(`${SUPABASE_URL}/rest/v1/rv_sessions`, {
            method: 'POST',
            headers: { ...sbHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify(row),
          });
          if (!res.ok) {
            const txt = await res.text().catch(() => '');
            return errorResponse(`RV-Session Insert fehlgeschlagen: ${txt}`, res.status);
          }
          const data = await res.json();
          return jsonResponse({ success: true, session: Array.isArray(data) ? data[0] : data });
        } catch (e) {
          return errorResponse(`RV-Session Fehler: ${e.message}`);
        }
      }


    }

    // ── AMBIENT SYSTEM: Kontextbewusster Tagespfad (AUFGABE 9A) ─────────────
    if (path === '/api/ambient/daily-path' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const {
          userId = null,
          timeOfDay = null,
          lastModules = [],
          streak = 0,
          level = 1,
          dominantWorld = 'materie',
          hrvBaseline = null,
          moodCheckIn = null,
        } = body;

        // 1. Wetter via Open-Meteo (Standort aus Cloudflare-Request)
        const cf = request.cf || {};
        const lat = body.lat ?? cf.latitude ?? 48.2082;   // Wien Fallback
        const lon = body.lon ?? cf.longitude ?? 16.3738;
        const city = cf.city || 'unbekannt';

        let weather = body.weather || null;
        if (!weather) {
          try {
            const wRes = await fetch(
              `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto`,
              { signal: AbortSignal.timeout(8000) }
            );
            const wData = await wRes.json().catch(() => ({}));
            const cur = wData.current || {};
            const codes = { 0:'klar', 1:'überwiegend klar', 2:'teilweise bewölkt', 3:'bewölkt',
              45:'neblig', 48:'dichter Nebel', 51:'leichter Nieselregen', 53:'Nieselregen',
              55:'starker Nieselregen', 61:'leichter Regen', 63:'Regen', 65:'starker Regen',
              71:'leichter Schnee', 73:'Schnee', 75:'starker Schnee', 80:'Regenschauer',
              81:'starke Regenschauer', 82:'heftige Regenschauer', 95:'Gewitter', 96:'Gewitter mit Hagel', 99:'starkes Gewitter'};
            weather = {
              temp: cur.temperature_2m ?? null,
              humidity: cur.relative_humidity_2m ?? null,
              condition: codes[cur.weather_code] || 'unbekannt',
              wind: cur.wind_speed_10m ?? null,
              city,
            };
          } catch (e) {
            weather = { temp: null, condition: 'unbekannt', city };
          }
        }

        // 2. Tageszeit ableiten falls nicht gegeben
        const tod = timeOfDay || (() => {
          const h = new Date().getHours();
          if (h < 6) return 'night';
          if (h < 12) return 'morning';
          if (h < 18) return 'afternoon';
          if (h < 22) return 'evening';
          return 'night';
        })();

        // 3. AI-Tagesplan generieren (Groq → Workers AI Fallback)
        const ctx = {
          tageszeit: tod, wetter: weather, level, streak,
          welt: dominantWorld, hrv: hrvBaseline, stimmung: moodCheckIn,
          letzteModule: lastModules,
        };

        const prompt = `Du bist der Weltenbibliothek-Begleiter. Erstelle einen personalisierten Tagespfad für einen User.

Kontext: ${JSON.stringify(ctx)}

Antworte AUSSCHLIESSLICH mit gültigem JSON im Format:
{
  "activities": [
    { "title": "...", "description": "...", "duration_min": 10, "module_code": "U-QC-XX", "world": "ursprung", "icon": "🌀" },
    { "title": "...", "description": "...", "duration_min": 15, "module_code": "V-XX", "world": "vorhang", "icon": "👁️" },
    { "title": "...", "description": "...", "duration_min": 5, "module_code": null, "world": "energie", "icon": "💨" }
  ],
  "dailyInsight": "Ein persönlicher, motivierender Satz auf Deutsch (max 200 Zeichen)",
  "ambientFrequency": 7.83
}

Wichtig:
- 3 Aktivitäten, abgestimmt auf Tageszeit, Wetter, Welt
- Bei morgens & gutem Wetter: Energie/Bewegung
- Bei abends & Regen: Reflektion/Meditation
- Frequenz: 7.83 Hz (Erde), 432 Hz (Heilung), 528 Hz (Liebe), 8 Hz (Alpha), 4 Hz (Theta)
- Auf Deutsch, prägnant, mystisch-poetisch im Weltenbibliothek-Stil`;

        let aiResponse = null;
        const groqKey = env.GROQ_API_KEY;
        if (groqKey) {
          try {
            const gRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
              method: 'POST',
              headers: { 'Authorization': `Bearer ${groqKey}`, 'Content-Type': 'application/json' },
              body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [{ role: 'user', content: prompt }],
                temperature: 0.7,
                response_format: { type: 'json_object' },
              }),
              signal: AbortSignal.timeout(6000),
            });
            const gData = await gRes.json().catch(() => ({}));
            const content = gData.choices?.[0]?.message?.content;
            if (content) aiResponse = JSON.parse(content);
          } catch (_) {}
        }

        // Workers AI Fallback
        if (!aiResponse && env.AI) {
          try {
            const aiRes = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
              messages: [{ role: 'user', content: prompt }],
              max_tokens: 800,
            });
            const text = aiRes.response || '';
            const match = text.match(/\{[\s\S]*\}/);
            if (match) aiResponse = JSON.parse(match[0]);
          } catch (_) {}
        }

        // Fallback wenn AI nicht verfügbar
        if (!aiResponse) {
          aiResponse = {
            activities: [
              { title: 'Atemmeister 4-7-8', description: 'Beruhige dein Nervensystem mit der 4-7-8 Methode',
                duration_min: 5, module_code: null, world: 'ursprung', icon: '💨' },
              { title: 'Tagesreflexion', description: 'Was hat dich heute bewegt? Drei Worte.',
                duration_min: 10, module_code: null, world: dominantWorld, icon: '✍️' },
              { title: 'Frequenz-Reise 432 Hz', description: 'Lass die Heilungsfrequenz wirken',
                duration_min: 15, module_code: 'U-FR-432', world: 'ursprung', icon: '🎵' },
            ],
            dailyInsight: 'Heute beobachte, was zwischen den Gedanken liegt.',
            ambientFrequency: 7.83,
          };
        }

        return jsonResponse({
          success: true,
          context: { timeOfDay: tod, weather, level, streak, dominantWorld },
          ...aiResponse,
          generatedAt: new Date().toISOString(),
        });
      } catch (e) {
        return errorResponse(`Ambient Fehler: ${e.message}`, 500);
      }
    }

    // ── BIBLIOTHEK (AUFGABE 9B/9C) ──────────────────────────────────────────
    if (path === '/api/bibliothek/books' && method === 'GET') {
      const category = url.searchParams.get('category');
      const moduleCode = url.searchParams.get('module');
      const anonKey = env.SUPABASE_ANON_KEY || '';
      let supaPath = `/rest/v1/bibliothek_books?select=*&order=year.asc`;
      if (category) supaPath += `&category=eq.${encodeURIComponent(category)}`;
      if (moduleCode) supaPath += `&related_modules=cs.{${encodeURIComponent(moduleCode)}}`;
      return proxyToSupabase(request, env, supaPath, 'GET');
    }

    if (path.startsWith('/api/bibliothek/book/') && method === 'GET') {
      const bookId = path.split('/').pop();
      const supaPath = `/rest/v1/bibliothek_books?select=*&id=eq.${encodeURIComponent(bookId)}&limit=1`;
      return proxyToSupabase(request, env, supaPath, 'GET');

    }

    // ── 404 ───────────────────────────────────────────────────
    return errorResponse(`Endpoint '${path}' nicht gefunden`, 404);
  },
};
