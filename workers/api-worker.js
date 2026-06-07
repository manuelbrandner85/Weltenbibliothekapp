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

function jsonResponse(data, status = 200, cacheSeconds = 0) {
  // v5.44.2: optionaler Edge-Cache via Cache-Control: s-maxage.
  // s-maxage = nur CF-Edge cached (Browser cached nicht), perfekt fuer
  // semi-statische Endpunkte wie Artikel-Listen, Room-Listen, Statistiken.
  // Reduziert Worker-Quota-Verbrauch massiv da CF die Antwort 1x serviert
  // statt jedes Mal den Worker auszufuehren.
  const headers = cacheSeconds > 0
    ? { ...CORS_HEADERS, 'Cache-Control': `public, s-maxage=${cacheSeconds}` }
    : CORS_HEADERS;
  return new Response(JSON.stringify(data), {
    status,
    headers,
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

// ══════════════════════════════════════════════════════════════════════════
// ADMIN-AUTH-HELPER (v106 -- Audit-Fix A1/A2/A4)
// ══════════════════════════════════════════════════════════════════════════
//
// Vorher: /api/admin/* + /api/push/(broadcast|send-*) akzeptierten body.admin
// als Klartext-Username und vertrauten dem -- Jeder konnte bannen/promoten/
// XP-vergeben/Massen-Spam senden indem er body.admin='Weltenbibliothek'
// schickte. Auth-Bypass.
//
// Jetzt: Caller muss sich mit X-Admin-Username + X-Admin-Token authen-
// tifizieren. Token = HMAC-SHA256(username, env.ADMIN_AUTH_SECRET).
// Server validiert (a) Token-Korrektheit (b) Rolle aus profiles.role.
// Bei kompromittiertem Geraet wird der User serverseitig automatisch
// blockiert wenn profiles.role auf 'user' zurueckgesetzt wird -- der
// Token allein reicht NICHT.
//
// Tokens werden client-seitig in AdminAuthService aus dem AdminStateNotifier
// gepullt und in allen Worker-Calls als Header mitgegeben.

const ADMIN_ROLES = new Set(['root_admin', 'admin', 'moderator', 'content_editor']);
const HIGH_PRIVILEGE = new Set(['root_admin', 'admin']);
const SUPER_PRIVILEGE = new Set(['root_admin']);

async function _hmacSha256Hex(secret, message) {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw', enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(message));
  return [...new Uint8Array(sig)]
    .map(b => b.toString(16).padStart(2, '0')).join('');
}

// v124: Pseudonymer Geraete/IP-Fingerprint fuer Multi-Account-Erkennung.
// Schreibt KEINE Klartext-IP -- nur HMAC-Hash mit ADMIN_AUTH_SECRET.
// Fire-and-forget: Fehler werden geschluckt, damit die eigentliche Aktion
// (Activity-Log etc.) nie blockiert. Retention 90 Tage via Cron.
async function recordProfileSession(profileId, request, env, svcHeaders) {
  if (!profileId) return;
  try {
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const ua = request.headers.get('User-Agent') || 'unknown';
    const secret = env.ADMIN_AUTH_SECRET ||
        env.SUPABASE_SERVICE_ROLE_KEY || 'fallback-do-not-use';
    const ipHash = await _hmacSha256Hex(secret, `ip:${ip}`);
    const uaHash = await _hmacSha256Hex(secret, `ua:${ua}`);
    await fetch(
      `${SUPABASE_URL}/rest/v1/profile_sessions?on_conflict=profile_id,ip_hash,ua_hash`,
      {
        method: 'POST',
        headers: {
          ...svcHeaders,
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
        body: JSON.stringify({
          profile_id: String(profileId),
          ip_hash: ipHash,
          ua_hash: uaHash,
          last_seen: new Date().toISOString(),
        }),
      },
    );
  } catch (_) {
    /* fire-and-forget -- session tracking ist best-effort */
  }
}

// base64url -> Uint8Array (JWT segments use URL-safe base64 without padding).
function _b64urlToBytes(s) {
  s = s.replace(/-/g, '+').replace(/_/g, '/');
  const pad = s.length % 4;
  if (pad) s += '='.repeat(4 - pad);
  const bin = atob(s);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

// base64url segment -> parsed JSON (JWT header/payload). Wirft nie.
function _b64urlToJson(seg) {
  try {
    return JSON.parse(new TextDecoder().decode(_b64urlToBytes(seg)));
  } catch (_) {
    return null;
  }
}

// In-memory JWKS cache (per Worker-Isolate). Supabase rotiert die ECC-Signier-
// schluessel selten; 1h TTL haelt Netzwerk-Calls minimal ohne Stale-Risiko.
let _jwksCache = { keys: null, exp: 0 };

/**
 * Laedt die oeffentlichen JWT-Signier-Schluessel (JWKS) des Supabase-Projekts.
 * Diese sind oeffentlich -- es ist KEIN Secret noetig. Ergebnis wird gecacht.
 * @returns {Promise<Array|null>} Array von JWKs oder null bei Fehler.
 */
async function _getSupabaseJwks() {
  const now = Date.now();
  if (_jwksCache.keys && now < _jwksCache.exp) return _jwksCache.keys;
  try {
    const resp = await fetch(
      `${SUPABASE_URL}/auth/v1/.well-known/jwks.json`,
      { cf: { cacheTtl: 3600, cacheEverything: true } }
    );
    if (!resp.ok) return _jwksCache.keys; // alten Cache behalten falls vorhanden
    const data = await resp.json();
    const keys = Array.isArray(data && data.keys) ? data.keys : [];
    if (keys.length) {
      _jwksCache = { keys, exp: now + 3600 * 1000 };
    }
    return keys.length ? keys : _jwksCache.keys;
  } catch (_) {
    return _jwksCache.keys;
  }
}

/**
 * AUTH-REFACTOR Phase 2 (additiv, NICHT erzwingend):
 * Verifiziert ein Supabase Anon-JWT LOKAL und liefert den dekodierten Payload
 * ({ sub, role, exp, ... }). sub ist die kanonische auth.uid().
 *
 * Unterstuetzt beide Signatur-Verfahren:
 *  - ES256 (ECC P-256): aktueller Supabase-Signier-Schluessel. Verifikation
 *    via oeffentlichem JWKS -- KEIN Secret noetig.
 *  - HS256: alter Legacy-Schluessel (nur fuer noch gueltige Alt-Tokens).
 *    Fallback gegen SUPABASE_JWT_SECRET, nur falls gesetzt.
 *
 * Gibt null zurueck wenn: kein X-Supabase-Token Header, falsches Format,
 * unbekannter Algorithmus, ungueltige Signatur oder abgelaufen. In Phase 2
 * (Vorbereitung) wird das Ergebnis nur geloggt -- spaeter gated es
 * user-scoped Endpoints gegen Impersonation.
 */
async function verifyAnonJwt(request, env) {
  const token = (request.headers.get('X-Supabase-Token') || '').trim();
  if (!token) return null;
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const header = _b64urlToJson(parts[0]);
  if (!header) return null;
  const signingInput = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const sig = _b64urlToBytes(parts[2]);
  try {
    let ok = false;
    if (header.alg === 'ES256') {
      // Asymmetrisch: oeffentlichen Schluessel per kid aus JWKS waehlen.
      const keys = await _getSupabaseJwks();
      if (!keys || !keys.length) return null;
      const jwk = keys.find(k => k.kid === header.kid) || keys[0];
      if (!jwk) return null;
      const key = await crypto.subtle.importKey(
        'jwk', jwk,
        { name: 'ECDSA', namedCurve: 'P-256' },
        false, ['verify']
      );
      ok = await crypto.subtle.verify(
        { name: 'ECDSA', hash: 'SHA-256' }, key, sig, signingInput
      );
    } else if (header.alg === 'HS256') {
      // Legacy symmetrisch: nur moeglich wenn Secret gesetzt ist.
      const secret = env.SUPABASE_JWT_SECRET || '';
      if (!secret) return null;
      const key = await crypto.subtle.importKey(
        'raw', new TextEncoder().encode(secret),
        { name: 'HMAC', hash: 'SHA-256' },
        false, ['verify']
      );
      ok = await crypto.subtle.verify('HMAC', key, sig, signingInput);
    } else {
      return null; // unbekannter Algorithmus
    }
    if (!ok) return null;
    const payload = _b64urlToJson(parts[1]);
    if (!payload) return null;
    if (payload.exp && Date.now() / 1000 > payload.exp) return null;
    return payload;
  } catch (_) {
    return null;
  }
}

/**
 * AUTH-REFACTOR Phase 2 telemetry: vergleicht die client-behauptete Identitaet
 * (X-User-ID) gegen den verifizierten JWT-sub und LOGGT einen Mismatch.
 * Erzwingt nichts (kein 403) -- dient nur dazu, vor der Umstellung auf
 * Enforcement zu messen wie oft echte vs. gefaelschte Identitaeten auftreten.
 * Best-effort, niemals werfen.
 */
async function logIdentityTelemetry(request, env) {
  try {
    const payload = await verifyAnonJwt(request, env);
    if (!payload) return; // kein/ungueltiges JWT -> Legacy-Pfad, nichts zu tun.
    const sub = String(payload.sub || '');
    const claimed = (request.headers.get('X-User-ID') || '').trim();
    const looksUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(claimed);
    // Nur loggen wenn claimed AUCH wie eine UUID aussieht und abweicht --
    // legacy 'user_<ts>'-IDs weichen erwartungsgemaess ab und sind kein Angriff.
    if (looksUuid && sub && claimed && claimed !== sub) {
      console.warn(`[auth-phase2] identity mismatch: claimed=${claimed} jwt.sub=${sub} path=${new URL(request.url).pathname}`);
    }
  } catch (_) { /* best-effort */ }
}

/**
 * Validiert dass der Caller ein Admin ist und liefert seinen profiles-Eintrag.
 *
 * @returns {Object|null} {userId, username, role, isAdmin, isRootAdmin,
 *                         isHighPrivilege} oder null bei Fehler.
 *
 * Header-Schema:
 *   X-Admin-Username: <username>
 *   X-Admin-Token:    <HMAC-SHA256(username, ADMIN_AUTH_SECRET)>
 *
 * Bei fehlendem ADMIN_AUTH_SECRET (z.B. lokales Dev ohne secret) wird
 * ein Warn-Log produziert UND der Caller wird zurueckgewiesen --
 * niemals fail-open im Production-Worker.
 */
async function verifyAdminCaller(request, env) {
  const username = (request.headers.get('X-Admin-Username') || '').trim();
  const token = (request.headers.get('X-Admin-Token') || '').trim();
  if (!username || !token) return null;

  const secret = env.ADMIN_AUTH_SECRET || '';
  if (!secret) {
    console.warn('verifyAdminCaller: ADMIN_AUTH_SECRET fehlt -- Auth wird abgelehnt');
    return null;
  }

  // Konstante-Zeit-Vergleich des Tokens
  const expected = await _hmacSha256Hex(secret, username.toLowerCase());
  if (expected.length !== token.length) return null;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= expected.charCodeAt(i) ^ token.charCodeAt(i);
  }
  if (diff !== 0) return null;

  // Rolle live aus profiles holen -- nicht aus dem Token!
  // Damit wirken Demotions sofort, kein Token-Refresh noetig.
  const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || '';
  if (!svcKey) return null;
  try {
    const headers = {
      apikey: svcKey,
      Authorization: `Bearer ${svcKey}`,
    };
    // Identity-Chain-Fix: erst per username queryen (Standardfall fuer
    // echte Supabase-Auth-User UND InvisibleAuth-User die ein Profil
    // mit z.B. 'Weltenbibliothek' angelegt haben). Wenn das leer ist
    // UND der Header-Wert wie eine InvisibleAuth-ID aussieht
    // ('user_<ts>_<rand>'), nochmal per legacy_user_id versuchen.
    // Damit funktioniert HMAC fuer beide Identity-Quellen.
    let res = await fetch(
      `${env.SUPABASE_URL}/rest/v1/profiles?username=eq.${encodeURIComponent(username)}&select=id,role,is_banned,username,legacy_user_id&limit=1`,
      { headers }
    );
    if (!res.ok) return null;
    let rows = await res.json();
    if ((!Array.isArray(rows) || rows.length === 0) &&
        username.startsWith('user_')) {
      res = await fetch(
        `${env.SUPABASE_URL}/rest/v1/profiles?legacy_user_id=eq.${encodeURIComponent(username)}&select=id,role,is_banned,username,legacy_user_id&limit=1`,
        { headers }
      );
      if (!res.ok) return null;
      rows = await res.json();
    }
    if (!Array.isArray(rows) || rows.length === 0) {
      console.warn(`verifyAdminCaller: no profile for username='${username}'`);
      return null;
    }
    const row = rows[0];
    if (row.is_banned === true) return null;
    const role = String(row.role || 'user');
    if (!ADMIN_ROLES.has(role)) {
      console.warn(`verifyAdminCaller: profile found but role='${role}' not admin`);
      return null;
    }
    return {
      userId: row.id,
      username: row.username || username,
      role,
      isAdmin: ADMIN_ROLES.has(role),
      isHighPrivilege: HIGH_PRIVILEGE.has(role),
      isRootAdmin: SUPER_PRIVILEGE.has(role),
    };
  } catch (e) {
    console.error('verifyAdminCaller error:', e);
    return null;
  }
}

/**
 * AUDIT-FIX B14: Rate-Limiter fuer Admin-Mutationen.
 *
 * Schreibt einen Counter pro (admin_id, action, minute-bucket) in
 * admin_rate_limits. Bei Ueberschreitung wird der Aufruf mit 429
 * abgewiesen. Standard-Limit: 30 Mutationen pro Minute pro Admin
 * (genug fuer normale Bedienung, blockiert Massenbans-Spam).
 *
 * Best-effort: Bei Supabase-Fehler wird das Limit ignoriert (kein
 * Fail-Closed, weil sonst legitime Admin-Aktionen gestoppt waeren).
 */
async function checkAdminRateLimit(env, adminId, action, { perMinute = 30 } = {}) {
  try {
    const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || '';
    if (!svcKey || !adminId) return { ok: true };
    const bucket = new Date();
    bucket.setSeconds(0, 0);
    const bucketIso = bucket.toISOString();

    // Read current count
    const readRes = await fetch(
      `${env.SUPABASE_URL}/rest/v1/admin_rate_limits?admin_id=eq.${adminId}&action=eq.${encodeURIComponent(action)}&bucket_minute=eq.${encodeURIComponent(bucketIso)}&select=count&limit=1`,
      { headers: { apikey: svcKey, Authorization: `Bearer ${svcKey}` } }
    );
    const rows = readRes.ok ? await readRes.json().catch(() => []) : [];
    const currentCount = (rows[0]?.count) || 0;
    if (currentCount >= perMinute) {
      return { ok: false, count: currentCount, limit: perMinute };
    }

    // Upsert (increment)
    fetch(`${env.SUPABASE_URL}/rest/v1/admin_rate_limits`, {
      method: 'POST',
      headers: {
        apikey: svcKey,
        Authorization: `Bearer ${svcKey}`,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: JSON.stringify({
        admin_id: adminId,
        action,
        bucket_minute: bucketIso,
        count: currentCount + 1,
      }),
    }).catch(() => {});

    return { ok: true, count: currentCount + 1 };
  } catch (_) {
    return { ok: true }; // fail-open on infra error
  }
}

/**
 * Schreibt eine Zeile ins admin_audit_log -- mit dem TATSAECHLICHEN
 * Tabellen-Schema (admin_username, action, target_identity, target_username,
 * world, room_name, details jsonb).
 *
 * Frueherer Code schrieb actor_id/target_type/target_id/payload -- diese
 * Spalten existieren NICHT, daher schlugen alle Audit-Inserts (ban, unban,
 * promote, delete, role-change...) silent fehl (fire-and-forget .catch).
 * Diese Helper-Funktion normalisiert auf das echte Schema.
 *
 * Fire-and-forget: gibt kein await zurueck, Fehler werden geschluckt.
 */
function logAudit(svcHeaders, fields) {
  try {
    fetch(`${SUPABASE_URL}/rest/v1/admin_audit_log`, {
      method: 'POST',
      headers: {
        ...svcHeaders,
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: JSON.stringify({
        admin_username: fields.admin_username || 'unknown',
        action: fields.action || 'unknown',
        target_identity:
          fields.target_id != null ? String(fields.target_id) : null,
        target_username: fields.target_username || null,
        world: fields.world || null,
        room_name: fields.room_name || null,
        details: fields.details || {},
      }),
    }).catch(() => {});
  } catch (_) { /* never throw from audit logging */ }
}

/**
 * Resolves any user ID to the profiles.id UUID.
 * Legacy InvisibleAuth IDs ('user_*') are stored in profiles.legacy_user_id.
 * Returns the UUID string, or null if no matching profile found.
 * Used by all admin action endpoints so that legacy IDs work transparently.
 */
async function resolveProfileUuid(userId, svcHeaders) {
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId)) {
    return userId;
  }
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?legacy_user_id=eq.${encodeURIComponent(userId)}&select=id&limit=1`,
      { headers: svcHeaders },
    );
    if (!res.ok) return null;
    const rows = await res.json().catch(() => []);
    return (Array.isArray(rows) && rows.length > 0) ? rows[0].id : null;
  } catch (_) { return null; }
}

/**
 * v117: Liefert die aktiven Restriction-Scopes eines Users.
 * Sucht in user_restrictions per user_id ODER username (InvisibleAuth-User
 * haben keine UUID-Identitaet im Chat-POST, daher Match auch ueber username).
 * Abgelaufene befristete Sperren (expires_at < now, !is_permanent) zaehlen NICHT.
 * Gibt ein Set-aehnliches Array eindeutiger scope-Strings zurueck.
 */
async function getActiveRestrictionScopes(svcHeaders, { userId, username } = {}) {
  const ors = [];
  if (userId) ors.push(`user_id.eq.${encodeURIComponent(userId)}`);
  if (username) ors.push(`username.eq.${encodeURIComponent(username)}`);
  if (ors.length === 0) return [];
  try {
    const nowIso = new Date().toISOString();
    // expires_at IS NULL (permanent) ODER expires_at > now (noch aktiv).
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/user_restrictions?or=(${ors.join(',')})` +
        `&or=(is_permanent.eq.true,expires_at.is.null,expires_at.gt.${nowIso})` +
        `&select=scope`,
      { headers: svcHeaders },
    );
    if (!res.ok) return [];
    const rows = await res.json().catch(() => []);
    if (!Array.isArray(rows)) return [];
    return [...new Set(rows.map((r) => r.scope).filter(Boolean))];
  } catch (_) {
    return [];
  }
}

/**
 * v117: SHA-256-Hex einer normalisierten Identitaet (username|name|gebdatum|gebort),
 * lowercased + getrimmt. Dient als Match-Schluessel fuer die Loesch-Blacklist
 * (deleted_identities). Gleiche Person -> gleicher Hash, auch ohne PII im Klartext.
 */
async function identityHash({ username, fullName, birthDate, birthPlace } = {}) {
  const norm = (s) => String(s || '').trim().toLowerCase();
  const material = [norm(username), norm(fullName), norm(birthDate), norm(birthPlace)].join('|');
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(material));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * v117: Prueft ob eine Anmelde-Identitaet auf der Loesch-Blacklist steht.
 * Match per username (exakt, lowercased) ODER kombiniertem identity_hash.
 * Eintraege mit reactivation_status='approved' blockieren NICHT mehr.
 * Gibt das blockierende deleted_identities-Row zurueck oder null.
 */
async function findBlacklistedIdentity(svcHeaders, { username, fullName, birthDate, birthPlace } = {}) {
  try {
    const hash = await identityHash({ username, fullName, birthDate, birthPlace });
    const unameLower = String(username || '').trim().toLowerCase();
    const ors = [`identity_hash.eq.${encodeURIComponent(hash)}`];
    if (unameLower) ors.push(`username_lower.eq.${encodeURIComponent(unameLower)}`);
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/deleted_identities?or=(${ors.join(',')})` +
        `&reactivation_status=neq.approved&select=id,username_lower,reactivation_status&limit=1`,
      { headers: svcHeaders },
    );
    if (!res.ok) return null;
    const rows = await res.json().catch(() => []);
    return (Array.isArray(rows) && rows.length > 0) ? rows[0] : null;
  } catch (_) {
    return null;
  }
}

/**
 * v117: Benachrichtigt alle Admins/Root-Admins (In-App + FCM-Queue) ueber ein
 * Ereignis (z.B. neuer Reaktivierungs-/Einspruchs-Antrag). Fire-and-forget.
 */
async function notifyAdmins(svcHeaders, title, body, data = {}) {
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?role=in.(admin,root_admin,root-admin)&select=id&limit=50`,
      { headers: svcHeaders },
    );
    if (!res.ok) return;
    const admins = await res.json().catch(() => []);
    if (!Array.isArray(admins)) return;
    await Promise.all(admins.flatMap((a) => {
      if (!a.id) return [];
      const notifRow = { user_id: a.id, type: 'admin_alert', title, body, data };
      const queueRow = { user_id: a.id, title, body, data, status: 'pending' };
      return [
        fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
          method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify(notifRow),
        }).catch(() => {}),
        fetch(`${SUPABASE_URL}/rest/v1/notification_queue`, {
          method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify(queueRow),
        }).catch(() => {}),
      ];
    }));
  } catch (_) { /* best-effort */ }
}

/**
 * v115: Enqueued eine Push-Notification (In-App + FCM-Queue) ausserhalb des
 * fetch-Handlers (z.B. im Cron). Spiegelt die pushNotif-Closure-Logik:
 * InvisibleAuth-IDs (user_*) -> legacy_user_id, sonst user_id.
 * Fire-and-forget, schluckt Fehler.
 */
async function enqueuePush(pushAuth, userId, type, title, body, data = {}) {
  if (!userId) return;
  const h = { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' };
  const isLegacy = String(userId).startsWith('user_');
  const queueRow = isLegacy
    ? { legacy_user_id: userId, title, body, data, status: 'pending' }
    : { user_id: userId, title, body, data, status: 'pending' };
  const notifRow = isLegacy
    ? { legacy_user_id: userId, type, title, body, data }
    : { user_id: userId, type, title, body, data };
  await Promise.all([
    fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
      method: 'POST', headers: h, body: JSON.stringify(notifRow),
    }).catch(() => {}),
    fetch(`${SUPABASE_URL}/rest/v1/notification_queue`, {
      method: 'POST', headers: h, body: JSON.stringify(queueRow),
    }).catch(() => {}),
  ]);
}

/** Convenience: 403 wenn nicht-admin, sonst null. */
async function requireAdmin(request, env, { needHighPrivilege = false, needRootAdmin = false } = {}) {
  const caller = await verifyAdminCaller(request, env);
  if (!caller) {
    return {
      caller: null,
      response: errorResponse('Admin-Auth erforderlich (X-Admin-Username + X-Admin-Token Header)', 403, 'admin_auth_required'),
    };
  }
  if (needRootAdmin && !caller.isRootAdmin) {
    return {
      caller,
      response: errorResponse('Root-Admin erforderlich', 403, 'root_admin_required'),
    };
  }
  if (needHighPrivilege && !caller.isHighPrivilege) {
    return {
      caller,
      response: errorResponse('Admin oder Root-Admin erforderlich', 403, 'high_privilege_required'),
    };
  }
  return { caller, response: null };
}


const DE_WORDS = /\b(und|der|die|das|ist|von|auf|zu|für|nicht|mit|einen|einem|eine|des|den|wird|wurde|sind|hat|haben|kann|dass|als|aber|auch|nach|bei|über|durch|im|am|es|er|sie|wir|ihr|was|wie|wenn|dann|noch|nur|alle|sehr|mehr|so|da|hier|jetzt|schon|ihm|ihn|dem|diesem|seiner|ihrer|eines|welche|andere|andere)\b/i;

// Bisheriger Google-Translate-Hack (translate.googleapis.com/translate_a/single)
// wurde von Google massiv rate-limited und scheiterte 90% der Zeit leise.
// Neuer Pfad: Workers-AI m2m100 (kostenlos, zuverlaessig).
// Fallback: Original-Text zurueckgeben (besser als Crash).
async function translateToDe(text, env) {
  if (!text || text.trim().length < 5) return text || '';
  if (DE_WORDS.test(text)) return text; // bereits Deutsch
  if (!env?.AI) return text; // ohne Workers-AI: Original zurueck
  try {
    const trimmed = text.slice(0, 1500);
    const aiRes = await env.AI.run('@cf/meta/m2m100-1.2b', {
      text: trimmed,
      source_lang: 'en',
      target_lang: 'de',
    });
    const translated = aiRes?.translated_text;
    return (translated && translated.trim()) ? translated : text;
  } catch (_) {
    return text;
  }
}

async function translateItems(items, fields, env) {
  if (!items || items.length === 0) return items || [];
  // Batch via Worker-AI llama (1 Call) ist wesentlich schneller als
  // pro-Item-m2m100 wenn viele Items zu uebersetzen sind.
  // Fuer kleine Mengen (<= 3) oder ohne AI: pro-Item m2m100.
  const total = items.length * fields.length;
  if (total <= 3 || !env?.AI) {
    return Promise.all(items.map(async item => {
      const vals = await Promise.all(
        fields.map(f => translateToDe(item[f] || '', env))
      );
      const out = { ...item };
      fields.forEach((f, i) => { out[f] = vals[i]; });
      return out;
    }));
  }
  // Batch: alle Strings sammeln, 1 Llama-Call, zurueck mappen.
  const strings = [];
  const refs = []; // {itemIdx, field}
  items.forEach((item, idx) => {
    fields.forEach(f => {
      const v = (item[f] || '').toString();
      if (v.trim().length >= 5 && !DE_WORDS.test(v)) {
        strings.push(v.slice(0, 300).replace(/\n/g, ' '));
        refs.push({ itemIdx: idx, field: f });
      }
    });
  });
  if (strings.length === 0) return items;
  try {
    const numbered = strings.map((s, i) => `${i + 1}. ${s}`).join('\n');
    const aiRes = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [
        { role: 'system', content: 'Du übersetzt nummerierte englische Texte ins Deutsche. Gib NUR die Übersetzungen in der gleichen Nummerierung zurück, ohne Kommentare. Behalte Eigennamen und Firmennamen unverändert.' },
        { role: 'user', content: numbered },
      ],
      max_tokens: 1500,
    });
    const text = aiRes?.response || '';
    const out = items.map(it => ({ ...it }));
    refs.forEach((ref, i) => {
      const match = text.match(new RegExp(`(?:^|\\n)\\s*${i + 1}\\.\\s*(.+?)(?=(?:\\n\\s*\\d+\\.)|$)`, 's'));
      if (match) out[ref.itemIdx][ref.field] = match[1].trim();
    });
    return out;
  } catch (_) {
    return items;
  }
}

// Supabase-Proxy mit optionalem Auth-Token
async function proxyToSupabase(request, env, path, method, body, userToken, cacheSeconds = 0) {
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
  return jsonResponse(data, res.status, cacheSeconds);
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

// v103 (1.5): Daily Wisdom-Spruechepool. 30 Eintraege fuer
// abwechslungsreichen Cron-Versand. Auswahl via Math.random.
const DAILY_WISDOM = [
  'Wissen ist nicht Macht. Anwendung von Wissen ist Macht.',
  'Wer die Wahrheit sucht, darf sich nicht von Bequemlichkeit aufhalten lassen.',
  'Stille ist der erste Schritt zur Erkenntnis.',
  'Das groesste Geheimnis ist die einfache Wahrheit, die niemand sehen will.',
  'Frage immer nach dem Warum, bevor du das Was glaubst.',
  'Jede Quelle hat eine Quelle. Geh weiter zurueck.',
  'Bewusstsein ist das einzige, das wir wirklich besitzen.',
  'Skepsis ist die hoechste Form von Respekt vor der Wahrheit.',
  'Wer denkt, ist nie allein.',
  'Verbindungen sehen wo andere nur Chaos sehen -- das ist der Weg.',
  'Die Welt veraendert sich, wenn du dich veraenderst.',
  'Was du fokussierst, waechst -- waehle bewusst.',
  'Die Antwort liegt selten in den Schlagzeilen.',
  'Manchmal ist Schweigen das lauteste Argument.',
  'Sei kritisch. Auch gegenueber dieser Botschaft.',
  'Wahrheit braucht keinen Konsens, aber Mut zur Einsamkeit.',
  'Lerne deine Werkzeuge kennen, bevor du sie benutzt.',
  'Achtsamkeit ist Widerstand.',
  'Das, was wir nicht hinterfragen, hat uns bereits.',
  'Jeder Schritt zaehlt, auch der kleine.',
  'Information ohne Kontext ist Manipulation.',
  'Geduld ist die unsichtbare Superkraft.',
  'Die besten Detektive sehen das, was nicht da ist.',
  'Wer fragt, fuehrt das Gespraech.',
  'Heute ist ein guter Tag, etwas Neues zu wissen.',
  'Vertraue der Quelle erst, wenn du sie ueberprueft hast.',
  'Mit jedem Atemzug entsteht eine neue Moeglichkeit.',
  'Bequeme Geschichten sind selten wahr.',
  'Daten luegen nicht -- ihre Interpreten schon.',
  'Wer langsam liest, sieht mehr.',
];

/// v103 Helper: enqueue a push to ALL subscribers of a topic.
/// Used by cron triggers and topic-broadcast endpoints. Falls back to
/// global broadcast when no subscribers have the topic in their
/// device_info -> topics array (legacy clients).
async function sendPushToTopic(env, pushAuth, topic, title, body, data) {
  try {
    const topicFilter =
        `device_info->topics=cs.["${topic.replace(/"/g, '\\"')}"]`;
    let recRes = await fetch(
      `${SUPABASE_URL}/rest/v1/push_subscriptions?select=user_id&is_active=eq.true&${topicFilter}&limit=5000`,
      { headers: pushAuth },
    );
    let recipients = recRes.ok ? await recRes.json().catch(() => []) : [];
    if (!Array.isArray(recipients) || recipients.length === 0) {
      recRes = await fetch(
        `${SUPABASE_URL}/rest/v1/push_subscriptions?select=user_id&is_active=eq.true&limit=5000`,
        { headers: pushAuth },
      );
      recipients = recRes.ok ? await recRes.json().catch(() => []) : [];
    }
    const userIds = (Array.isArray(recipients) ? recipients : [])
      .map(r => r.user_id)
      .filter(id => id && !String(id).startsWith('00000000-'));
    if (userIds.length === 0) {
      return { sent: 0, failed: 0, topic };
    }
    const now = new Date().toISOString();
    const rows = userIds.map(uid => ({
      user_id: uid,
      title,
      body,
      data: { ...(data || {}), topic, source: 'cron_topic' },
      status: 'pending',
      created_at: now,
    }));
    const insRes = await fetch(
      `${SUPABASE_URL}/rest/v1/notification_queue`,
      {
        method: 'POST',
        headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
        body: JSON.stringify(rows),
      },
    );
    if (!insRes.ok) {
      return { sent: 0, failed: userIds.length, topic, error: `HTTP ${insRes.status}` };
    }
    try { await dispatchPushQueue(env, pushAuth); } catch (_) {}
    return { sent: userIds.length, failed: 0, topic };
  } catch (e) {
    return { sent: 0, failed: 0, topic, error: e.message };
  }
}
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
  const b64 = String(pem)
    // 2026-06-07 ROBUSTHEIT: literal \n / \r (Backslash+Buchstabe, zwei
    // Zeichen) entfernen. Haeufigster FCM-in-Worker-Bug: der private_key
    // im Secret enthaelt escaped Newlines (z.B. weil das JSON doppelt
    // ge-stringified oder via Editor eingefuegt wurde). Ohne das bleibt
    // "\n" im Base64 stehen und atob wirft InvalidCharacterError.
    .replace(/\\r\\n/g, '')
    .replace(/\\n/g, '')
    .replace(/\\r/g, '')
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
  let raw = env.FCM_SERVICE_ACCOUNT;
  if (!raw) return null;
  let sa;
  try {
    if (typeof raw === 'string') {
      // 2026-06-07 ROBUSTHEIT: umschliessende Quotes + Whitespace trimmen
      // (z.B. wenn das Secret versehentlich mit Anfuehrungszeichen oder
      // fuehrendem Newline gespeichert wurde).
      raw = raw.trim();
      if ((raw.startsWith('"') && raw.endsWith('"')) ||
          (raw.startsWith("'") && raw.endsWith("'"))) {
        raw = raw.slice(1, -1);
      }
      sa = JSON.parse(raw);
      // Doppelt-kodiertes JSON (JSON.parse liefert nochmal einen String).
      if (typeof sa === 'string') sa = JSON.parse(sa);
    } else {
      sa = raw;
    }
  } catch (e) {
    throw new Error(`FCM_SERVICE_ACCOUNT ist kein gültiges JSON: ${e.message}`);
  }
  if (!sa || !sa.client_email || !sa.private_key || !sa.project_id) {
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

// ──────────────────────────────────────────────────────────────────────
// 🔢 Numerology daily energy push (Verbesserung 5)
// ──────────────────────────────────────────────────────────────────────
// Berechnet fuer alle Profile mit Geburtsdatum den persoenlichen Tag und
// queued eine FCM-Notification. Wird einmal pro UTC-Tag ausgefuehrt --
// Schutz via Marker-Row in notification_queue mit type='numerology_daily'
// im data-JSON.
function _reduceDigit(n) {
  while (n > 9) {
    let s = 0;
    while (n > 0) {
      s += n % 10;
      n = Math.floor(n / 10);
    }
    n = s;
  }
  return n;
}

function _calcPersonalDay(birthIso, now) {
  // birthIso = "YYYY-MM-DD" oder ISO datetime
  const d = new Date(birthIso);
  if (Number.isNaN(d.getTime())) return null;
  const birthDay = _reduceDigit(d.getUTCDate());
  const birthMonth = _reduceDigit(d.getUTCMonth() + 1);
  const yr = _reduceDigit(now.getUTCFullYear());
  const personalYear = _reduceDigit(birthDay + birthMonth + yr);
  const personalMonth =
      _reduceDigit(personalYear + _reduceDigit(now.getUTCMonth() + 1));
  const personalDay =
      _reduceDigit(personalMonth + _reduceDigit(now.getUTCDate()));
  return personalDay;
}

const _DAILY_ENERGY_TEXTS = {
  1: [
    'Heute strahlt Pionierenergie! Starte etwas Neues.',
    'Tag der Initiative -- geh voran!',
    'Die 1 ruft: Sei mutig und eigenstaendig!',
  ],
  2: [
    'Harmonie-Tag: Pflege deine Beziehungen.',
    'Diplomatie und Feingefuehl sind heute deine Staerken.',
    'Die 2 fluestert: Hoere zu und vermittle.',
  ],
  3: [
    'Kreativitaets-Explosion! Druecke dich aus.',
    'Freude und Ausdruck stehen heute im Fokus.',
    'Die 3 singt: Erschaffe etwas Schoenes!',
  ],
  4: [
    'Strukturtag: Ordne und organisiere.',
    'Heute lohnt sich fleissige Arbeit doppelt.',
    'Die 4 spricht: Baue solide Fundamente.',
  ],
  5: [
    'Abenteuer-Tag! Sei offen fuer Neues.',
    'Veraenderung liegt in der Luft -- umarme sie!',
    'Die 5 ruft: Brich aus der Routine aus!',
  ],
  6: [
    'Familien- und Liebestag.',
    'Fuersorge und Verantwortung tragen heute Fruechte.',
    'Die 6 waermt: Gib und empfange Liebe.',
  ],
  7: [
    'Tag der inneren Einkehr und Analyse.',
    'Meditation und Stille bringen heute Klarheit.',
    'Die 7 schweigt: Hoere nach innen.',
  ],
  8: [
    'Manifestations-Tag! Denke gross.',
    'Materieller Fokus bringt heute Ergebnisse.',
    'Die 8 manifestiert: Dein Erfolg wartet.',
  ],
  9: [
    'Tag des Loslassens und der Vollendung.',
    'Mitgefuehl und Dienst am Naechsten erfuellen heute.',
    'Die 9 vollendet: Lass los, was nicht mehr dient.',
  ],
};

async function dispatchDailyNumerology(env, pushAuth) {
  const now = new Date();
  // Nur einmal pro Tag -- pruefe Marker in notification_queue.
  const today = now.toISOString().slice(0, 10);
  const checkRes = await fetch(
    `${SUPABASE_URL}/rest/v1/notification_queue?select=id&data->>type=eq.numerology_daily&created_at=gte.${today}T00:00:00Z&limit=1`,
    { headers: pushAuth },
  );
  if (checkRes.ok) {
    const arr = await checkRes.json().catch(() => []);
    if (Array.isArray(arr) && arr.length > 0) {
      return { skipped: 'already_queued_today' };
    }
  }

  // Profile mit Geburtsdatum + aktivem Push-Opt-In holen.
  // numerology_push_enabled ist optional -- wenn Spalte fehlt, fallback
  // auf alle mit birth_date (Backward-compatibility).
  let profiles = [];
  let usedFallback = false;
  const tryRes = await fetch(
    `${SUPABASE_URL}/rest/v1/profiles?select=id,legacy_user_id,birth_date&birth_date=not.is.null&numerology_push_enabled=eq.true&limit=2000`,
    { headers: pushAuth },
  );
  if (tryRes.ok) {
    profiles = await tryRes.json().catch(() => []);
  } else {
    usedFallback = true;
    const fbRes = await fetch(
      `${SUPABASE_URL}/rest/v1/profiles?select=id,legacy_user_id,birth_date&birth_date=not.is.null&limit=2000`,
      { headers: pushAuth },
    );
    if (fbRes.ok) profiles = await fbRes.json().catch(() => []);
  }
  if (!Array.isArray(profiles) || profiles.length === 0) {
    return { queued: 0, total: 0, fallback: usedFallback };
  }

  let queued = 0;
  const variantIndex = (now.getUTCDate() + now.getUTCMonth()) % 3;
  for (const p of profiles) {
    if (!p.id || !p.birth_date) continue;
    const pd = _calcPersonalDay(p.birth_date, now);
    if (pd == null || pd < 1 || pd > 9) continue;
    const variants = _DAILY_ENERGY_TEXTS[pd] || [];
    const body = variants[variantIndex] || variants[0] || '';
    const title = `Deine Tagesenergie: ${pd}`;
    try {
      const insertRes = await fetch(
        `${SUPABASE_URL}/rest/v1/notification_queue`,
        {
          method: 'POST',
          headers: {
            ...pushAuth,
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: JSON.stringify({
            user_id: p.id,
            legacy_user_id: p.legacy_user_id || null,
            title,
            body: body.substring(0, 120),
            data: {
              type: 'numerology_daily',
              personal_day: pd,
              date: today,
            },
            status: 'pending',
          }),
        },
      );
      if (insertRes.ok) queued++;
    } catch (_) {
      // ignore individual failures
    }
  }
  return { queued, total: profiles.length, fallback: usedFallback };
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
  // v96: legacy_user_id mitselectieren -- InvisibleAuth-User haben user_id NULL.
  // v104: scheduled_at-Filter -- nur Zeilen die JETZT oder frueher faellig sind.
  //   scheduled_at IS NULL -> sofort (default)
  //   scheduled_at <= now    -> faellig
  //   scheduled_at > now     -> noch warten, wird in spaeterem Cron geholt
  const nowIso = new Date().toISOString();
  const fetchRes = await fetch(
    `${SUPABASE_URL}/rest/v1/notification_queue?or=(status.eq.pending,and(status.eq.failed,attempts.lt.3))&or=(scheduled_at.is.null,scheduled_at.lte.${nowIso})&select=id,user_id,legacy_user_id,title,body,data,attempts&order=created_at.asc&limit=100`,
    { headers: pushAuth }
  );
  const rows = await fetchRes.json().catch(() => []);
  const list = Array.isArray(rows) ? rows : [];
  if (list.length === 0) return { drained: 0, sent: 0, failed: 0, fcmEnabled: true };

  // 3. Für jede Queue-Zeile: FCM-Tokens des Users laden und senden.
  //
  // AUDIT-FIX A7: Race-Condition geschlossen. Vorher konnte ein zweiter
  // gleichzeitig laufender Cron-Job dieselben pending-Rows lesen und den
  // gleichen Push 2x zustellen. Jetzt: atomarer Claim per
  // PATCH ?id=eq.<id>&status=eq.pending -- PostgREST uebersetzt das in
  // UPDATE ... WHERE id=X AND status='pending', was zeilenweise atomar ist.
  // Wenn die Row schon von einem anderen Cron auf 'processing' geschoben
  // wurde, gibt PATCH ein leeres Array zurueck -> wir skippen.
  let sent = 0;
  let failed = 0;
  for (const row of list) {
    // Atomarer Claim: setze pending -> processing nur wenn noch pending.
    const claimRes = await fetch(
      `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${row.id}&status=eq.pending`,
      {
        method: 'PATCH',
        headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=representation' },
        body: JSON.stringify({ status: 'processing' }),
      }
    );
    const claimed = claimRes.ok ? await claimRes.json().catch(() => []) : [];
    if (!Array.isArray(claimed) || claimed.length === 0) {
      // Row wurde bereits von einem parallelen Cron geclaimt -- skip.
      continue;
    }

    let deliveryOk = false;
    // v96 KRITISCH-FIX: lese aus user_devices (v91), NICHT push_subscriptions
    // (v13). Die App registriert nur in user_devices -- der alte
    // push_subscriptions-Pfad war daher leer und niemand bekam Push.
    // user_devices.profile_id matched profiles.id (UUID) bei Web-Auth;
    // user_devices.legacy_user_id matched InvisibleAuth-IDs.
    const lookupColumn = row.user_id ? 'profile_id' : 'legacy_user_id';
    const lookupValue = row.user_id || row.legacy_user_id || '';

    // AUDIT-FIX B7: User-Push-Preferences respektieren. Wenn der User den
    // Typ (z.B. 'admin_broadcast', 'mention', 'achievement') opt-out hat,
    // wird der Push uebersprungen aber als 'sent' markiert (kein Retry).
    // Default = alles enabled wenn keine Row existiert.
    const pushType = (row.data && (row.data.type || row.data.kind)) || 'generic';
    let prefAllow = true;
    let dndActive = false;
    try {
      const prefRes = await fetch(
        `${SUPABASE_URL}/rest/v1/user_push_preferences?${lookupColumn === 'profile_id' ? 'user_id' : 'legacy_user_id'}=eq.${encodeURIComponent(lookupValue)}&select=disabled_types,dnd_until&limit=1`,
        { headers: pushAuth }
      );
      if (prefRes.ok) {
        const prefRows = await prefRes.json().catch(() => []);
        const pref = Array.isArray(prefRows) ? prefRows[0] : null;
        if (pref) {
          const disabled = Array.isArray(pref.disabled_types) ? pref.disabled_types : [];
          if (disabled.includes(pushType)) prefAllow = false;
          if (pref.dnd_until && new Date(pref.dnd_until) > new Date()) dndActive = true;
        }
      }
    } catch (_) { /* best-effort */ }

    if (!prefAllow || dndActive) {
      console.log(`push skip pref/dnd: type=${pushType} user=${lookupValue}`);
      // Markiere als 'sent' (kein Retry) und gehe zur naechsten Row.
      await fetch(
        `${SUPABASE_URL}/rest/v1/notification_queue?id=eq.${row.id}`,
        {
          method: 'PATCH',
          headers: { ...pushAuth, 'Content-Type': 'application/json' },
          body: JSON.stringify({
            status: 'sent',
            processed_at: new Date().toISOString(),
            attempts: (row.attempts || 0) + 1,
          }),
        }
      );
      sent++;
      continue;
    }

    // AUDIT-FIX 2026-06-07: Token-Tabellen- UND Identitaets-Mismatch behoben.
    // Der Client registriert FCM-Token mal in user_devices (v91+) und mal in
    // push_subscriptions (v13). Ausserdem kennt ein InvisibleAuth-Client nur
    // seine legacy_user_id, registriert sein Geraet also unter
    // legacy_user_id -- ein Broadcast enqueued die Notification aber unter
    // der profiles.id (UUID). Frueher matchte der Dispatch nur EINE Spalte.
    // Jetzt: BEIDE Tabellen UND BEIDE Identitaeten (user_id + legacy_user_id)
    // werden abgefragt und die Tokens zusammengefuehrt.
    const tokenSet = new Set();
    const collectTokens = async (urlStr, label) => {
      try {
        const res = await fetch(urlStr, { headers: pushAuth });
        const arr = await res.json().catch(() => []);
        for (const s of (Array.isArray(arr) ? arr : [])) {
          if (s.fcm_token) tokenSet.add(s.fcm_token);
        }
      } catch (e) { console.warn(`${label} lookup:`, e.message); }
    };
    // user_devices ueber profile_id (UUID)
    if (row.user_id) {
      await collectTokens(
        `${SUPABASE_URL}/rest/v1/user_devices?profile_id=eq.${encodeURIComponent(row.user_id)}&fcm_token=not.is.null&select=fcm_token`,
        'user_devices.profile_id');
    }
    // user_devices ueber legacy_user_id (InvisibleAuth)
    if (row.legacy_user_id) {
      await collectTokens(
        `${SUPABASE_URL}/rest/v1/user_devices?legacy_user_id=eq.${encodeURIComponent(row.legacy_user_id)}&fcm_token=not.is.null&select=fcm_token`,
        'user_devices.legacy');
    }
    // push_subscriptions (nur user_id=UUID, Spalte ist uuid-typisiert)
    if (row.user_id) {
      await collectTokens(
        `${SUPABASE_URL}/rest/v1/push_subscriptions?user_id=eq.${encodeURIComponent(row.user_id)}&fcm_token=not.is.null&is_active=eq.true&select=fcm_token`,
        'push_subscriptions');
    }
    const tokens = [...tokenSet];

    // AUDIT-FIX C9: FCM-Limits einhalten -- Title 150, Body 240 Zeichen.
    const trimmedTitle = String(row.title || '').slice(0, 150);
    const trimmedBody = String(row.body || '').slice(0, 240);

    if (tokens.length === 0) {
      // Kein FCM-Token für diesen User → als 'sent' markieren (kein Gerät registriert)
      console.warn(`push skip: ${lookupColumn}=${lookupValue} hat kein aktives fcm_token`);
    } else {
      for (const token of tokens) {
        try {
          const r = await sendFcmMessage(fcm.accessToken, fcm.projectId, token, trimmedTitle, trimmedBody, row.data || {});
          if (r.ok) {
            deliveryOk = true;
            console.log(`FCM ok: ${lookupColumn}=${lookupValue}`);
          } else if (r.status === 404 || r.status === 410) {
            // Token invalid / unregistered → aus BEIDEN Tabellen entfernen.
            console.warn(`FCM token invalid (${r.status}), entferne: ${token.slice(0, 20)}…`);
            await fetch(
              `${SUPABASE_URL}/rest/v1/user_devices?fcm_token=eq.${encodeURIComponent(token)}`,
              { method: 'DELETE', headers: pushAuth }
            ).catch(() => {});
            await fetch(
              `${SUPABASE_URL}/rest/v1/push_subscriptions?fcm_token=eq.${encodeURIComponent(token)}`,
              { method: 'PATCH', headers: { ...pushAuth, 'Content-Type': 'application/json' }, body: JSON.stringify({ is_active: false }) }
            ).catch(() => {});
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

// ══════════════════════════════════════════════════════════════════════════
// SHARED AI CORE (2026-06-07) -- 5-Quellen-Kette fuer ALLE Endpunkte.
// Groq -> Gemini 2.0 Flash -> OpenRouter -> Workers-AI 70b -> 8b.
// Top-Level damit /recherche, /api/virgil/chat, Modul-Werkstatt, Video-KI,
// Moderation etc. dieselbe robuste Pipeline teilen.
// ══════════════════════════════════════════════════════════════════════════

// Robuste JSON-Extraktion: schneidet das erste balancierte {} oder [] aus
// einem KI-Text heraus (auch wenn Prosa/Markdown drumherum steht).
function extractJson(text) {
  if (!text) return null;
  let t = String(text).trim();
  const fence = t.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (fence) t = fence[1].trim();
  const start = t.search(/[\{\[]/);
  if (start < 0) return null;
  const open = t[start];
  const close = open === '{' ? '}' : ']';
  let depth = 0, inStr = false, esc = false;
  for (let i = start; i < t.length; i++) {
    const c = t[i];
    if (esc) { esc = false; continue; }
    if (c === '\\') { esc = true; continue; }
    if (c === '"') { inStr = !inStr; continue; }
    if (inStr) continue;
    if (c === open) depth++;
    else if (c === close) {
      depth--;
      if (depth === 0) {
        try { return JSON.parse(t.slice(start, i + 1)); } catch (_) { return null; }
      }
    }
  }
  return null;
}

// Interner Multi-Quellen-Call. jsonMode=true -> Gemini responseMimeType JSON
// + extractJson; jsonMode=false -> roher Text-Output. Gibt bei JSON-Mode das
// geparste Objekt zurueck, sonst den String. null/'' bei Totalausfall.
async function _aiCall(env, systemMsg, userMsg, maxTokens, jsonMode) {
  const sys = jsonMode
    ? systemMsg + '\n\nWICHTIG: Antworte AUSSCHLIESSLICH mit gueltigem JSON. ' +
        'Kein Markdown, keine Code-Fences, keine Erklaerung, kein Text davor oder danach.'
    : systemMsg;
  const pick = (content) => jsonMode ? extractJson(content) : (content || '').trim() || null;

  const tryOpenAi = async (apiUrl, apiKey, model, extraHeaders = {}) => {
    try {
      const r = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json', ...extraHeaders },
        body: JSON.stringify({
          model,
          messages: [{ role: 'system', content: sys }, { role: 'user', content: userMsg }],
          temperature: 0.6,
          max_tokens: maxTokens,
        }),
        signal: AbortSignal.timeout(28000),
      });
      if (r.ok) {
        const data = await r.json();
        return pick(data?.choices?.[0]?.message?.content || '');
      }
    } catch (_) { /* fall through */ }
    return null;
  };

  // 1) Groq
  if (env.GROQ_API_KEY) {
    const out = await tryOpenAi('https://api.groq.com/openai/v1/chat/completions',
      env.GROQ_API_KEY, 'llama-3.3-70b-versatile');
    if (out) return out;
  }
  // 2) Gemini 2.0 Flash
  if (env.GEMINI_API_KEY) {
    try {
      const genConfig = { temperature: 0.6, maxOutputTokens: maxTokens };
      if (jsonMode) genConfig.responseMimeType = 'application/json';
      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${encodeURIComponent(env.GEMINI_API_KEY)}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: sys }] },
            contents: [{ role: 'user', parts: [{ text: userMsg }] }],
            generationConfig: genConfig,
          }),
          signal: AbortSignal.timeout(28000),
        },
      );
      if (r.ok) {
        const data = await r.json();
        const out = pick(data?.candidates?.[0]?.content?.parts?.[0]?.text || '');
        if (out) return out;
      }
    } catch (_) { /* fall through */ }
  }
  // 3) OpenRouter (free)
  if (env.OPENROUTER_API_KEY) {
    const out = await tryOpenAi('https://openrouter.ai/api/v1/chat/completions',
      env.OPENROUTER_API_KEY, 'meta-llama/llama-3.3-70b-instruct:free',
      { 'HTTP-Referer': 'https://weltenbibliothek-api.brandy13062.workers.dev', 'X-Title': 'Weltenbibliothek' });
    if (out) return out;
  }
  // 4+5) Workers-AI
  if (env.AI) {
    const models = ['@cf/meta/llama-3.3-70b-instruct-fp8-fast', '@cf/meta/llama-3.1-8b-instruct'];
    for (const model of models) {
      for (let attempt = 0; attempt < 2; attempt++) {
        try {
          const res = await env.AI.run(model, {
            messages: [{ role: 'system', content: sys }, { role: 'user', content: userMsg }],
            max_tokens: maxTokens,
          });
          const out = pick(res?.response || '');
          if (out) return out;
        } catch (_) { /* naechster Versuch */ }
      }
    }
  }
  return null;
}

// Oeffentliche Helfer: aiJson (JSON-Objekt/Array) + aiText (Freitext).
// A4: verstaendliche Fehlermeldung statt technischem Text -- propagiert in
// alle KI-Endpunkte (Modul-/Tool-Generierung, Dossier, Uebersetzung ...).
const AI_BUSY_MSG = 'Die KI ist gerade ausgelastet oder nicht erreichbar. Bitte in ein paar Sekunden erneut versuchen.';
async function aiJson(env, systemMsg, userMsg, maxTokens = 1200) {
  const out = await _aiCall(env, systemMsg, userMsg, maxTokens, true);
  if (out == null) throw new Error(AI_BUSY_MSG);
  return out;
}
async function aiText(env, systemMsg, userMsg, maxTokens = 800) {
  const out = await _aiCall(env, systemMsg, userMsg, maxTokens, false);
  if (out == null) throw new Error(AI_BUSY_MSG);
  return out;
}

// ── Modul-Werkstatt: Welt-Schema (Top-Level, von Endpunkten + Cron geteilt) ──
const WORKSHOP_BRANCHES = {
  materie: ['Recherche-Grundlagen', 'Netzwerk-Analyse', 'Quellenkritik', 'Geopolitik & Macht', 'Wirtschaft & Finanzen', 'Desinformation erkennen'],
  energie: ['Energiearbeit', 'Meditation & Stille', 'Chakren & Aura', 'Manifestation', 'Intuition & Wahrnehmung', 'Heilung & Balance'],
  vorhang: ['Machtpsychologie', 'Manipulationserkennung', 'Verhandlung & Überzeugung', 'Körpersprache & Nonverbales', 'Strategisches Denken', 'Schattenarbeit'],
  ursprung: ['gateway_foundation', 'focus_levels', 'energy_tools', 'patterning_manifestation', 'remote_viewing'],
};
const WORKSHOP_WORLDS = ['materie', 'energie', 'vorhang', 'ursprung'];
const WORLD_CODE_PREFIX = { materie: 'M-', energie: 'E-', vorhang: 'V-', ursprung: 'U-' };
// Thematischer Kontext je Welt -- damit die KI WELT-PASSENDE Tool-Vorschlaege macht
// (nicht nur generisch nach dem Welt-Namen). Wird in tools/idea + tools/scan genutzt.
const WORLD_TOOL_CONTEXT = {
  vorhang: 'die "Vorhang"-Welt: Machtpsychologie, Manipulationserkennung, Verhandlung & Ueberzeugung, Koerpersprache, strategisches Denken, Schattenarbeit. Passende Tools: interaktive Analysen, Selbsttests, Checklisten, Trainer, Detektoren.',
  ursprung: 'die "Ursprung"-Welt: Bewusstsein, Gateway-Erfahrungen, Focus-Levels, Remote Viewing, Hermetik/Mystik, Manifestation, holografisches Universum/Simulation. Passende Tools: gefuehrte Sessions, Timer, Protokoll-/Journal-Tools, Wahrnehmungs-Trainer, Rechner.',
  materie: 'die "Materie"-Welt: Recherche/OSINT, Netzwerk-Analyse, Quellenkritik, Geopolitik & Macht, Wirtschaft & Finanzen, Desinformation erkennen. Passende Tools: Recherche-Helfer, Daten-Lookups, Live-Monitore, Verifikations-Tools.',
  energie: 'die "Energie"-Welt: Energiearbeit, Meditation, Chakren & Aura, Numerologie/Astrologie, Manifestation, Intuition, Heilung & Balance. Passende Tools: Rechner, Orakel, Meditations-/Timer-Tools, Kalender, Selbstreflexion.',
};
function normWorld(w) { return WORKSHOP_WORLDS.includes(w) ? w : 'vorhang'; }
function tableForWorld(w) { return `${normWorld(w)}_modules`; }

// W1: Quiz-Fragen normalisieren -> [{question, options:[4], answer_index}].
function normTestQuestions(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.slice(0, 8).map((q) => {
    const opts = Array.isArray(q?.options) ? q.options.map((o) => String(o)).slice(0, 6) : [];
    let ai = Number.isInteger(q?.answer_index) ? q.answer_index : 0;
    if (ai < 0 || ai >= opts.length) ai = 0;
    return { question: String(q?.question || '').slice(0, 400), options: opts, answer_index: ai };
  }).filter((q) => q.question && q.options.length >= 2);
}

// W8: Quellen normalisieren -> [{title, url}].
function normSources(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.slice(0, 8).map((s) => ({
    title: String(s?.title || s?.name || '').slice(0, 200),
    url: String(s?.url || s?.link || '').slice(0, 500),
  })).filter((s) => s.title);
}

// Liefert die in der Welt tatsaechlich vorhandenen Bereiche (Branches).
async function fetchExistingBranches(tbl, svcHeaders) {
  try {
    const r = await fetch(`${SUPABASE_URL}/rest/v1/${tbl}?select=branch`, { headers: svcHeaders });
    if (!r.ok) return [];
    const rows = await r.json().catch(() => []);
    return [...new Set((Array.isArray(rows) ? rows : []).map((x) => String(x.branch || '').trim()).filter(Boolean))];
  } catch (_) { return []; }
}

// Intelligente Bereich-Zuordnung: matched den KI-Branch case-insensitiv auf einen
// bestehenden Bereich (damit Themen die zu Machtpsychologie passen DORT landen,
// statt einen fast gleichen neuen Bereich anzulegen).
function matchExistingBranch(branch, existing) {
  const b = String(branch || '').trim().toLowerCase();
  if (!b) return null;
  for (const e of existing) {
    if (String(e).trim().toLowerCase() === b) return e; // exakter Treffer (Case)
  }
  return null;
}

// Stellt sicher, dass ein Modul Quiz-Fragen hat (Pflicht fuer Vorhang/Ursprung).
// Generiert sie bei Bedarf in einem fokussierten Zweitschritt aus der Theorie.
async function ensureTestQuestions(env, existing, ctx) {
  const cur = normTestQuestions(existing);
  if (cur.length >= 3) return cur;
  try {
    const sys = 'Erstelle 4 Multiple-Choice-Quiz-Fragen zum Lern-Modul. ' +
      'Antworte AUSSCHLIESSLICH als JSON-Array, je { "question", "options": [4 Antworten], "answer_index": 0-3 }. Deutsch.';
    const user = `Titel: ${ctx.title || ''}\n\nTheorie:\n${(ctx.theory_content || '').slice(0, 3000)}`;
    const arr = await aiJson(env, sys, user, 1200);
    const q = normTestQuestions(Array.isArray(arr) ? arr : (arr.test_questions || arr.questions));
    return q.length >= 3 ? q : cur;
  } catch (_) { return cur; }
}

// W5: Snapshot des aktuellen Modulstands in module_versions sichern (vor Edit).
// Best-effort -- ein Fehler hier darf das Speichern nicht blockieren.
async function snapshotModule(world, tbl, code, svcHeaders, username) {
  try {
    const r = await fetch(
      `${SUPABASE_URL}/rest/v1/${tbl}?module_code=eq.${encodeURIComponent(code)}&limit=1`,
      { headers: svcHeaders });
    if (!r.ok) return;
    const arr = await r.json().catch(() => []);
    const cur = Array.isArray(arr) && arr[0];
    if (!cur) return; // existiert noch nicht -> nichts zu sichern
    await fetch(`${SUPABASE_URL}/rest/v1/module_versions`, {
      method: 'POST',
      headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
      body: JSON.stringify({ world, module_code: code, snapshot: cur, created_by: username || null }),
    });
  } catch (_) { /* best-effort */ }
}

// ══════════════════════════════════════════════════════════════════════════
// B1: KI-AUTO-SCAN (Cron, 2026-06-07)
// Periodischer Hintergrund-Scan, der pro Tag EINE Welt prueft und Modul-
// Vorschlaege in module_suggestions schreibt (Status pending) -- erscheinen
// dann automatisch im Admin-Dashboard zur Bestaetigung. Quota-schonend:
// nur 1 Welt/Tag, Quality-Check (gratis) + 1 KI-Vorschlag.
// ══════════════════════════════════════════════════════════════════════════
async function runAutoScanCron(env, svcHeaders) {
  // W7: Konfiguration beachten (enabled + erlaubte Welten).
  let allowedWorlds = WORKSHOP_WORLDS;
  try {
    const cr = await fetch(`${SUPABASE_URL}/rest/v1/module_scan_config?id=eq.1&limit=1`, { headers: svcHeaders });
    const carr = cr.ok ? await cr.json().catch(() => []) : [];
    const cfg = Array.isArray(carr) && carr[0];
    if (cfg) {
      if (cfg.enabled === false) return { skipped: 'disabled' };
      if (Array.isArray(cfg.worlds) && cfg.worlds.length > 0) {
        allowedWorlds = cfg.worlds.filter((w) => WORKSHOP_WORLDS.includes(w));
        if (allowedWorlds.length === 0) allowedWorlds = WORKSHOP_WORLDS;
      }
    }
  } catch (_) { /* Default: alle Welten, aktiviert */ }

  // Welt rotiert nach Tag-im-Jahr -> jede erlaubte Welt der Reihe nach.
  const dayOfYear = Math.floor((Date.now() - Date.UTC(new Date().getUTCFullYear(), 0, 0)) / 86400000);
  const world = allowedWorlds[dayOfYear % allowedWorlds.length];
  const tbl = tableForWorld(world);
  const branches = WORKSHOP_BRANCHES[world];

  const listR = await fetch(
    `${SUPABASE_URL}/rest/v1/${tbl}?select=module_code,branch,title,subtitle,xp_reward,theory_content,case_study,exercise_description&order=branch.asc`,
    { headers: svcHeaders },
  );
  const existing = listR.ok ? (await listR.json().catch(() => [])) : [];
  const rowsToInsert = [];

  // Quality-Check (gratis, keine KI).
  const placeholderRe = /(\[einfuegen\]|\[bitte ergaenzen\]|\.\.\.tbd|TODO|XXX|Lorem ipsum)/i;
  for (const m of existing) {
    const findings = [];
    if (!m.theory_content || m.theory_content.trim().length < 200) findings.push(`Theorie zu kurz (${(m.theory_content || '').length} Zeichen)`);
    if (!m.case_study || m.case_study.trim().length < 80) findings.push('Fallstudie fehlt/zu kurz');
    if (!m.exercise_description || m.exercise_description.trim().length < 50) findings.push('Uebung fehlt/zu kurz');
    for (const f of ['title', 'theory_content', 'case_study', 'exercise_description']) {
      if (m[f] && placeholderRe.test(String(m[f]))) findings.push(`${f} enthaelt Platzhalter`);
    }
    if (findings.length > 0) {
      rowsToInsert.push({
        world, kind: 'quality', status: 'pending', target_module_code: m.module_code,
        title: m.title || m.module_code, branch: m.branch, quality_findings: findings,
        rationale: `${findings.length} Qualitaets-Problem(e) in ${m.module_code}`, created_by: 'cron:auto-scan',
      });
    }
  }

  // 1 neues Modul fuer den schwaechsten Branch (KI).
  try {
    const perBranch = {};
    for (const b of branches) perBranch[b] = 0;
    for (const m of existing) if (perBranch[m.branch] !== undefined) perBranch[m.branch]++;
    const weakest = Object.entries(perBranch).sort((a, b) => a[1] - b[1])[0]?.[0] || branches[0];
    const titles = existing.map(m => m.title).filter(Boolean).join('; ');
    const idea = await aiJson(env,
      `Du planst ein neues Lern-Modul fuer die Weltenbibliothek (Welt: ${world}, Branch: ${weakest}). ` +
      'Antworte als JSON-Objekt: { "topic": "...", "rationale": "kurze Begruendung auf Deutsch" }.',
      `Bereits vorhanden: ${titles || '(keine)'}\n\nWelches Modul fehlt im Branch "${weakest}"?`, 400);
    const topic = String(idea.topic || '').trim();
    if (topic.length >= 3) {
      const mod = await aiJson(env,
        'Du bist Lehrredaktion der Weltenbibliothek. Erstelle ein vollstaendiges Lern-Modul. ' +
        'Antworte als JSON: title, subtitle, theory_content (300-600 Worte, Markdown), case_study (150-300 Worte), exercise_description (100-250 Worte), xp_reward (50-200). Deutsch.',
        `Thema: ${topic}\nBranch: ${weakest}`, 3000);
      rowsToInsert.push({
        world, kind: 'new', status: 'pending', branch: weakest,
        title: String(mod.title || topic).slice(0, 120),
        subtitle: String(mod.subtitle || '').slice(0, 240),
        theory_content: String(mod.theory_content || ''),
        case_study: String(mod.case_study || ''),
        exercise_description: String(mod.exercise_description || ''),
        xp_reward: Math.max(50, Math.min(200, Math.round(Number(mod.xp_reward) || 100))),
        rationale: String(idea.rationale || `Fuellt Luecke im Branch "${weakest}"`).slice(0, 500),
        created_by: 'cron:auto-scan',
      });
    }
  } catch (e) { console.warn(`[auto-scan/new] ${e.message}`); }

  if (rowsToInsert.length > 0) {
    // Alte cron-Vorschlaege dieser Welt verwerfen (idempotent).
    await fetch(
      `${SUPABASE_URL}/rest/v1/module_suggestions?world=eq.${world}&status=eq.pending&created_by=eq.cron:auto-scan`,
      { method: 'DELETE', headers: svcHeaders },
    ).catch(() => {});
    await fetch(`${SUPABASE_URL}/rest/v1/module_suggestions`, {
      method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
      body: JSON.stringify(rowsToInsert),
    });
  }
  return { world, created: rowsToInsert.length };
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
    // 🔢 Tagesenergie (Verbesserung 5): einmal pro UTC-Tag um ~07:00.
    // Cron schiesst alle 5 min, also nur in der 07:00..07:04-Slot pruefen.
    try {
      const nowUTC = new Date();
      if (nowUTC.getUTCHours() === 7 && nowUTC.getUTCMinutes() < 5) {
        const res = await dispatchDailyNumerology(env, pushAuth);
        console.log('cron numerology-daily:', JSON.stringify(res));
      }
    } catch (e) {
      console.error('cron numerology-daily failed:', e.message);
    }
    // 🤖 B1: KI-Auto-Scan -- einmal pro UTC-Tag um ~07:30 (eine Welt/Tag).
    try {
      const nowUTC = new Date();
      if (nowUTC.getUTCHours() === 7 && nowUTC.getUTCMinutes() >= 30 && nowUTC.getUTCMinutes() < 35) {
        const res = await runAutoScanCron(env, pushAuth);
        console.log('cron auto-scan:', JSON.stringify(res));
      }
    } catch (e) {
      console.error('cron auto-scan failed:', e.message);
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

        // 2026-06-07: Stau-Schutz. Pending-Zeilen die nie zugestellt wurden
        // (z.B. weil FCM falsch konfiguriert ist und der Dispatcher skippt)
        // wachsen sonst unbegrenzt. Aelter als 3 Tage -> als 'failed'
        // markieren, damit sie vom 7-Tage-Cleanup oben erfasst werden.
        const staleCutoff = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
          .toISOString();
        const staleRes = await fetch(
          `${SUPABASE_URL}/rest/v1/notification_queue?status=eq.pending&created_at=lt.${staleCutoff}`,
          {
            method: 'PATCH',
            headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              status: 'failed',
              last_error: 'stale: nie zugestellt (>3 Tage)',
              processed_at: new Date().toISOString(),
            }),
          },
        );
        console.log('cron stale-pending-aging:', staleRes.status);
      }
    } catch (e) {
      console.error('cron queue-cleanup failed:', e.message);
    }

    // ⏳ v115 (Feature A): Auto-Expiry befristeter Bans. Jeder Cron-Tick
    // (alle 5 min) sucht abgelaufene, NICHT-permanente Bans und hebt sie auf:
    //   1. profiles.is_banned = false
    //   2. admin_bans-Zeile loeschen
    //   3. Push an den User + Audit-Log
    try {
      const nowIso = new Date().toISOString();
      const expRes = await fetch(
        `${SUPABASE_URL}/rest/v1/admin_bans?is_permanent=eq.false&expires_at=not.is.null&expires_at=lte.${encodeURIComponent(nowIso)}&select=id,user_id,username&limit=100`,
        { headers: pushAuth },
      );
      const expired = expRes.ok ? await expRes.json().catch(() => []) : [];
      if (Array.isArray(expired) && expired.length > 0) {
        for (const ban of expired) {
          const uid = ban.user_id;
          if (!uid) continue;
          // 1. Profil entsperren
          await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(uid)}`,
            {
              method: 'PATCH',
              headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
              body: JSON.stringify({ is_banned: false }),
            },
          ).catch(() => {});
          // 2. Ban-Zeile entfernen
          await fetch(
            `${SUPABASE_URL}/rest/v1/admin_bans?id=eq.${encodeURIComponent(ban.id)}`,
            { method: 'DELETE', headers: pushAuth },
          ).catch(() => {});
          // 3. Push + Audit
          try {
            await enqueuePush(pushAuth, uid, 'system', '✅ Sperre abgelaufen',
              'Deine befristete Kontosperre ist abgelaufen. Du kannst wieder teilnehmen.',
              { type: 'unbanned', auto: true });
          } catch (_) {}
          logAudit(pushAuth, {
            admin_username: 'system',
            action: 'ban_expired',
            target_id: uid,
            target_username: ban.username || null,
            details: { auto: true },
          });
        }
        console.log('cron ban-expiry:', expired.length, 'bans aufgehoben');
      }
    } catch (e) {
      console.error('cron ban-expiry failed:', e.message);
    }

    // 🔒 v124: profile_sessions 90-Tage-Retention. Loescht alles wo
    // last_seen aelter als 90 Tage ist. Laeuft 1x pro Stunde (UTC :00).
    try {
      const nowUTC = new Date();
      if (nowUTC.getUTCMinutes() < 5) {
        const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
            .toISOString();
        const delRes = await fetch(
          `${SUPABASE_URL}/rest/v1/profile_sessions?last_seen=lt.${encodeURIComponent(cutoff)}`,
          { method: 'DELETE', headers: { ...pushAuth, 'Prefer': 'return=minimal' } },
        );
        if (delRes.ok) {
          console.log('cron profile-sessions-retention: ok');
        }
      }
    } catch (e) {
      console.error('cron profile-sessions-retention failed:', e.message);
    }

    // 💡 v103 (1.5) Daily Wisdom -- 08:00 UTC each day. Picks one of 30
    // wisdom snippets and sends to topic 'daily_wisdom'.
    try {
      const nowUTC = new Date();
      if (nowUTC.getUTCHours() === 8 && nowUTC.getUTCMinutes() < 5) {
        const wisdom = DAILY_WISDOM[
          Math.floor(Math.random() * DAILY_WISDOM.length)
        ];
        const result = await sendPushToTopic(
          env, pushAuth,
          'daily_wisdom',
          '💡 Tägliche Weisheit',
          wisdom,
          { type: 'daily_wisdom' },
        );
        console.log('cron daily-wisdom:', JSON.stringify(result));
      }
    } catch (e) {
      console.error('cron daily-wisdom failed:', e.message);
    }

    // 📊 v103 (1.6) Weekly Summary -- Sunday 10:00 UTC. Aggregates
    // counts (new users, messages last 7 days) and broadcasts.
    try {
      const nowUTC = new Date();
      if (nowUTC.getUTCDay() === 0 &&
          nowUTC.getUTCHours() === 10 &&
          nowUTC.getUTCMinutes() < 5) {
        const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
          .toISOString();
        const [usersRes, msgsRes] = await Promise.all([
          fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id&created_at=gte.${cutoff}&limit=1`,
            { headers: { ...pushAuth, 'Prefer': 'count=exact' } },
          ),
          fetch(
            `${SUPABASE_URL}/rest/v1/chat_messages?select=id&created_at=gte.${cutoff}&limit=1`,
            { headers: { ...pushAuth, 'Prefer': 'count=exact' } },
          ),
        ]);
        const newUsers = parseInt(
          usersRes.headers.get('content-range')?.split('/')[1] || '0',
        );
        const newMsgs = parseInt(
          msgsRes.headers.get('content-range')?.split('/')[1] || '0',
        );
        const summary =
          'Letzte 7 Tage: ' + newUsers + ' neue User · ' +
          newMsgs + ' Nachrichten.';
        const result = await sendPushToTopic(
          env, pushAuth,
          'weekly_summary',
          '📊 Dein Wochenrückblick',
          summary,
          { type: 'weekly_summary', new_users: newUsers, messages: newMsgs },
        );
        console.log('cron weekly-summary:', JSON.stringify(result));
      }
    } catch (e) {
      console.error('cron weekly-summary failed:', e.message);
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

    // ── Invite-Deep-Link: GET /join?room=...&world=... ────────
    // Serves an HTML page that immediately redirects to the custom-scheme
    // deep link. Because HTTPS URLs are clickable in WhatsApp/SMS while
    // "weltenbibliothek://" scheme links are not.
    if (path === '/join' && method === 'GET') {
      const room = (url.searchParams.get('room') || '').trim();
      const world = (url.searchParams.get('world') || 'materie').trim();
      const worldLabel = { materie: 'Materie', energie: 'Energie', vorhang: 'Vorhang', ursprung: 'Ursprung' }[world] || 'Weltenbibliothek';
      if (!room) {
        return new Response('Fehlender Parameter: room', { status: 400 });
      }
      const deepLink = `weltenbibliothek://live?room=${encodeURIComponent(room)}&world=${encodeURIComponent(world)}`;
      const html = `<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Weltenbibliothek - Live-Call</title>
  <style>
    body{margin:0;background:#0a0a14;color:#eee;font-family:system-ui,sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:24px}
    h1{color:#c084fc;font-size:1.5rem;margin-bottom:.5rem}
    p{color:#aaa;margin:.5rem 0}
    a.btn{display:inline-block;margin-top:1.5rem;padding:14px 32px;border-radius:14px;background:#7c3aed;color:#fff;font-size:1rem;font-weight:600;text-decoration:none}
    .room{color:#e2e8f0;font-weight:600}
  </style>
  <script>
    setTimeout(function(){window.location.href="${deepLink}";},400);
  </script>
</head>
<body>
  <h1>Weltenbibliothek</h1>
  <p>Du wurdest in einen Live-Call eingeladen!</p>
  <p>Welt: <span class="room">${worldLabel}</span></p>
  <p>Raum: <span class="room">${room}</span></p>
  <a class="btn" href="${deepLink}">App oeffnen &amp; beitreten</a>
  <p style="margin-top:2rem;font-size:.8rem;color:#666">Noch keine App? Bitte nach dem Download-Link fragen.</p>
</body>
</html>`;
      return new Response(html, {
        headers: { 'Content-Type': 'text/html;charset=utf-8', 'Cache-Control': 'no-store' },
      });
    }

    // AUTH-REFACTOR Phase 2 (additiv): nicht-blockierende Identity-Telemetrie.
    // Misst Impersonation-Versuche via verifiziertem Anon-JWT (ES256 gegen das
    // oeffentliche JWKS -- kein Secret noetig), ohne irgendetwas zu erzwingen.
    try { ctx.waitUntil(logIdentityTelemetry(request, env)); } catch (_) { /* best-effort */ }

    // ── Error Report (Client-Side) ────────────────────────────
    // Akzeptiert FlutterErrorDetails-aehnliche Payloads vom Client
    // und schreibt sie in Supabase Tabelle 'client_errors'. Best-effort.
    if (path === '/api/error-report' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const payload = {
          error: String(body.error || '').slice(0, 4000),
          library: String(body.library || '').slice(0, 200),
          stack: String(body.stack || '').slice(0, 8000),
          context: String(body.context || '').slice(0, 1000),
          platform: String(body.platform || '').slice(0, 50),
          client_timestamp: body.timestamp || null,
          received_at: new Date().toISOString(),
        };
        // Fire-and-forget Insert -- bei fehlender Tabelle ignorieren
        await fetch(`${env.SUPABASE_URL}/rest/v1/client_errors`, {
          method: 'POST',
          headers: {
            apikey: env.SUPABASE_SERVICE_ROLE_KEY,
            Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
            'Content-Type': 'application/json',
            Prefer: 'return=minimal',
          },
          body: JSON.stringify(payload),
        }).catch(() => {});
        return jsonResponse({ ok: true });
      } catch (e) {
        return jsonResponse({ ok: false, error: String(e) }, 200);
      }
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

        // ── PHASE 2: KI-Zusammenfassung (5-Quellen-Kette: Groq->Gemini->...) ──
        // A3 (2026-06-07): nutzt jetzt aiText statt nur llama-3.1-8b -> deutlich
        // bessere, sachlichere deutsche Zusammenfassungen.
        let aiSummary = null;
        if (allResults.length > 0) {
          try {
            const context = allResults.slice(0, 6).map(r => `${r.title}: ${r.snippet}`).join('\n');
            aiSummary = await aiText(
              env,
              'Du bist ein sachlicher Recherche-Assistent. Fasse die Suchergebnisse in 3-5 Saetzen auf Deutsch zusammen. Nur belegbare Aussagen, keine Spekulation, keine Floskeln.',
              `Suchanfrage: "${query}"\n\nErgebnisse:\n${context}`,
              500,
            );
          } catch (aiErr) {
            // AI ist optional - kein Error
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

    // ── Rabbit-Hole: KI-generierte Kaninchenbau-Pfade (A1, 2026-06-07) ──
    // Vorher nur Stub (leere connections). Jetzt: die KI schlaegt 6 konkrete
    // weiterfuehrende Verbindungen vor, jede mit Typ, Aufhaenger und einem
    // fertigen Suchbegriff zum Tiefer-Graben.
    if (path.startsWith('/api/rabbit-hole')) {
      try {
        let topic = '';
        if (method === 'POST') {
          const body = await request.json().catch(() => ({}));
          topic = (body.topic || body.query || '').toString().trim();
        } else {
          topic = decodeURIComponent(
            path.replace('/api/rabbit-hole/', '').replace('/api/rabbit-hole', '')
          ).trim();
        }
        if (!topic) return jsonResponse({ topic: '', paths: [], connections: [] });

        const system = [
          'Du bist VIRGIL, ein investigativer Recherche-Begleiter.',
          'Zu einem Ausgangsthema schlaegst du weiterfuehrende Recherche-Pfade vor --',
          'das, was einen Menschen "tiefer in den Kaninchenbau" zieht.',
          'Antworte als JSON-Objekt mit dem Feld "paths": Array von genau 6 Objekten.',
          'Jedes Objekt: {',
          '  "label": kurzer Titel der Verbindung (2-5 Worte),',
          '  "type": einer aus "person"|"organisation"|"ereignis"|"ort"|"konzept"|"geldfluss"|"dokument",',
          '  "hook": EIN Satz warum das spannend/relevant ist (sachlich, kein Clickbait),',
          '  "query": ein praeziser Suchbegriff zum Weitergraben (Eigennamen bevorzugt)',
          '}.',
          'Vielfalt: verschiedene Typen mischen. Sachlich bleiben, keine erfundenen Fakten.',
          'Alles auf Deutsch.',
        ].join('\n');
        const user = `Ausgangsthema: "${topic}"\nSchlage 6 weiterfuehrende Recherche-Pfade vor.`;

        let paths = [];
        try {
          const parsed = await aiJson(env, system, user, 1000);
          const raw = Array.isArray(parsed) ? parsed : (parsed.paths || parsed.connections || []);
          paths = (Array.isArray(raw) ? raw : []).slice(0, 6).map((p) => ({
            label: (p.label || p.title || '').toString().slice(0, 80),
            type: (p.type || 'konzept').toString().toLowerCase(),
            hook: (p.hook || p.why || p.reason || '').toString().slice(0, 240),
            query: (p.query || p.next_query || p.label || '').toString().slice(0, 120),
          })).filter((p) => p.label && p.query);
        } catch (_) { paths = []; }

        return jsonResponse({ topic, paths, connections: paths, depth: 1 });
      } catch (e) {
        return errorResponse(`Rabbit-Hole-Fehler: ${e.message}`);
      }
    }

    // ── KI-Dossier: strukturierter Recherche-Report (A2, 2026-06-07) ──
    // POST /api/kaninchenbau/dossier  Body: { topic, context }
    //   context = aggregierte Kurzfassung der geladenen Karten (Client baut es).
    // Liefert ein strukturiertes Dossier (Markdown) + Abschnitte als JSON.
    if (path === '/api/kaninchenbau/dossier' && method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const topic = (body.topic || '').toString().trim();
        const context = (body.context || '').toString().slice(0, 12000);
        if (!topic) return errorResponse('topic fehlt', 400);

        const system = [
          'Du bist ein investigativer Analyst. Erstelle aus den vorliegenden',
          'Recherche-Daten ein strukturiertes Dossier. Streng sachlich, nur was die',
          'Daten hergeben; markiere Unsicheres als solches. Kein Clickbait.',
          'Antworte als JSON-Objekt:',
          '{',
          '  "summary": 3-4 Saetze Gesamtbild,',
          '  "actors": [ { "name", "role" } ]  (Schluesselakteure, max 8),',
          '  "money": [ String ]  (Geld-/Macht-Verbindungen, max 6),',
          '  "contradictions": [ String ]  (Widersprueche/Ungereimtheiten, max 6),',
          '  "open_questions": [ String ]  (offene Fragen zum Weitergraben, max 6),',
          '  "markdown": vollstaendiges Dossier als Markdown (## Abschnitte)',
          '}.',
          'Alles auf Deutsch.',
        ].join('\n');
        const user = `Thema: "${topic}"\n\nRecherche-Daten:\n${context || '(keine zusaetzlichen Daten -- nutze Allgemeinwissen, kennzeichne das)'}`;

        const d = await aiJson(env, system, user, 2200);
        return jsonResponse({
          success: true,
          topic,
          summary: (d.summary || '').toString(),
          actors: Array.isArray(d.actors) ? d.actors.slice(0, 8) : [],
          money: Array.isArray(d.money) ? d.money.slice(0, 6) : [],
          contradictions: Array.isArray(d.contradictions) ? d.contradictions.slice(0, 6) : [],
          open_questions: Array.isArray(d.open_questions) ? d.open_questions.slice(0, 6) : [],
          markdown: (d.markdown || '').toString(),
        });
      } catch (e) {
        return errorResponse(`Dossier-Fehler: ${e.message}`);
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
      // v5.44.2: 120s Edge-Cache - Artikel-Liste ist semi-statisch.
      return proxyToSupabase(request, env, supaPath, 'GET', null, null, 120);
    }

    // ── Tages-Featured ────────────────────────────────────────
    if (path === '/api/daily-featured') {
      const world = url.searchParams.get('world') || 'materie';
      const supaPath = `/rest/v1/articles?select=*&is_published=eq.true&world=eq.${world}&order=created_at.desc&limit=1`;
      // v5.44.2: 600s Edge-Cache - Tages-Featured aendert sich nur taeglich.
      return proxyToSupabase(request, env, supaPath, 'GET', null, null, 600);
    }

    // ── POST /api/reports  (User-Reports einreichen — public) ──
    // Body: { user_id?, username?, type, severity?, title, body?, target_id?, screenshot_url?, context? }
    if (path === '/api/reports' && method === 'POST') {
      try {
        const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
        const body = await request.json().catch(() => ({}));
        const type = String(body.type || '').toLowerCase();
        if (!['bug','content','feedback','voice'].includes(type)) {
          return errorResponse('type muss bug|content|feedback|voice sein', 400);
        }
        const title = String(body.title || '').trim().slice(0, 200);
        if (!title) return errorResponse('title pflicht', 400);
        const payload = {
          user_id: body.user_id ? String(body.user_id).slice(0, 200) : null,
          username: body.username ? String(body.username).slice(0, 80) : null,
          type,
          severity: ['low','medium','high','critical'].includes(body.severity) ? body.severity : 'medium',
          title,
          body: body.body ? String(body.body).slice(0, 4000) : null,
          target_id: body.target_id ? String(body.target_id).slice(0, 200) : null,
          screenshot_url: body.screenshot_url ? String(body.screenshot_url).slice(0, 500) : null,
          context: body.context && typeof body.context === 'object' ? body.context : {},
        };
        const r = await fetch(`${SUPABASE_URL}/rest/v1/user_reports`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': svcKey,
            'Authorization': `Bearer ${svcKey}`,
            'Prefer': 'return=representation',
          },
          body: JSON.stringify(payload),
        });
        if (!r.ok) {
          const txt = await r.text().catch(() => '');
          return errorResponse(`Supabase ${r.status}: ${txt.substring(0, 200)}`);
        }
        const created = await r.json().catch(() => []);
        return jsonResponse({ success: true, report: Array.isArray(created) ? created[0] : created });
      } catch (e) { return errorResponse(`Report-Insert-Fehler: ${e.message}`); }
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

          // v117: Chat-Sperren durchsetzen. Scopes 'chat'/'all' -> ablehnen.
          // 'shadow_mute' -> Erfolg vortaeuschen, aber NICHT speichern (nur der
          // Sender glaubt er postet; niemand sonst sieht die Nachricht).
          {
            const chatSvcKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;
            const chatHeaders = {
              'Content-Type': 'application/json',
              'apikey': chatSvcKey, 'Authorization': `Bearer ${chatSvcKey}`,
            };
            const uname = body.username || null;
            const scopes = await getActiveRestrictionScopes(chatHeaders, { userId: rawUserId, username: uname });
            if (scopes.includes('all') || scopes.includes('chat')) {
              return jsonResponse(
                { success: false, error: 'Du bist aktuell vom Chat gesperrt.', code: 'chat_restricted' },
                403);
            }
            if (scopes.includes('shadow_mute')) {
              // Optimistisches Echo zurueckgeben, aber nichts persistieren.
              return jsonResponse({ success: true, message: {
                id: `shadow-${Date.now()}`,
                room_id: body.roomId || body.room_id || '',
                user_id: finalUserId, username: uname || 'Anonym',
                content: body.message || body.content || '',
                message: body.message || body.content || '',
                created_at: new Date().toISOString(),
              } });
            }
          }

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
        // v5.44.7: media_url als kanonisches Feld - Client erwartet das.
        // url bleibt fuer Rueckwaertskompatibilitaet.
        return jsonResponse({
          media_url: publicUrl,
          url: publicUrl,
          key,
        });
      } catch (e) {
        return errorResponse(`Voice-Upload-Fehler: ${e.message}`);
      }
    }

    // ── Chat Räume ────────────────────────────────────────────
    if (path === '/voice/rooms' || path === '/api/chat/rooms') {
      const world = url.searchParams.get('realm') || url.searchParams.get('world');
      let supaPath = '/rest/v1/chat_rooms?select=*&is_active=eq.true&order=name.asc';
      if (world) supaPath += `&world=eq.${world}`;
      // v5.44.2: 60s Edge-Cache - Raum-Liste aendert sich selten.
      return proxyToSupabase(request, env, supaPath, 'GET', null, null, 60);
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
          // v95: Kein hardcoded Fallback-Passwort mehr -- wenn das Secret
          // ROOT_ADMIN_PASSWORD fehlt, ist der Root-Admin-Login deaktiviert.
          // Bei fehlendem Secret wird ein 503 zurueckgegeben statt eines
          // bekannten Passworts zu akzeptieren.
          const ADMIN_USERNAME = 'weltenbibliothek';
          const ADMIN_PASSWORD = env.ROOT_ADMIN_PASSWORD;
          if (body.username && body.username.toLowerCase() === ADMIN_USERNAME) {
            if (!ADMIN_PASSWORD) {
              return jsonResponse({
                success: false,
                error: 'Root-Admin-Login serverseitig nicht konfiguriert. ' +
                       'ROOT_ADMIN_PASSWORD muss via wrangler secret gesetzt werden.',
              }, 503);
            }
            if (!body.password || body.password !== ADMIN_PASSWORD) {
              return jsonResponse({ success: false, error: 'Falsches Admin-Passwort.' }, 403);
            }
          }
          // Passwort nicht in die DB schreiben
          delete body.password;

          // v5.44.3: InvisibleAuth-User schicken ihre client-generierte ID
          // im Feld 'userId'. Mappe auf profiles.legacy_user_id.
          const incomingUserId = body.userId || body.user_id || body.id;
          let legacyUserId = null;
          let knownUuid = null;
          if (incomingUserId && typeof incomingUserId === 'string') {
            const looksLikeUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(incomingUserId);
            if (looksLikeUuid) knownUuid = incomingUserId;
            else legacyUserId = incomingUserId;
          }
          // ID-Felder vom Client immer entfernen damit profiles.id auto-generiert
          // wird (gen_random_uuid()) - vermeidet UUID-Validierungsfehler.
          delete body.userId;
          delete body.user_id;
          delete body.id;

          // v118 KRITISCH: Body gegen die echten profiles-Spalten sanitisieren.
          // Frueher sendete der Materie-Client das Feld 'name' -- das gibt es
          // in profiles NICHT -> PostgREST lehnte den INSERT mit 42703 ab und
          // das Profil persistierte NIE (verlorene User). Wir mappen bekannte
          // Aliasse und verwerfen alles, was keine echte Spalte ist.
          {
            const ALIAS = {
              name: 'display_name', displayName: 'display_name',
              fullName: 'full_name', firstName: 'birth_first_name',
              lastName: 'birth_last_name', avatarUrl: 'avatar_url',
              avatarEmoji: 'avatar_emoji', birthDate: 'birth_date',
              birthPlace: 'birth_place', birthTime: 'birth_time',
              // world_preference existiert NICHT als Spalte -- auf 'world'
              // mappen, sonst lehnt PostgREST den INSERT/PATCH mit 42703 ab.
              world_preference: 'world',
            };
            for (const [from, to] of Object.entries(ALIAS)) {
              if (body[from] !== undefined) {
                if (body[to] === undefined || body[to] === null) body[to] = body[from];
                delete body[from];
              }
            }
            const PROFILE_COLS = new Set([
              'username', 'display_name', 'avatar_url', 'avatar_emoji', 'bio',
              'world', 'role', 'full_name', 'birth_date',
              'birth_time', 'birth_place', 'birth_latitude', 'birth_longitude',
              'timezone_offset_hours', 'birth_time_unknown', 'gender',
              'birth_first_name', 'birth_middle_names', 'birth_last_name',
              'numerology_push_enabled', 'legacy_user_id', 'is_banned',
            ]);
            for (const k of Object.keys(body)) {
              if (!PROFILE_COLS.has(k)) delete body[k];
            }
            // role NIE vom Client uebernehmen (Privilege-Escalation). Die
            // INSERT-Branch setzt role='user' explizit; bestehende Profile
            // behalten ihre Rolle (PATCH ohne role).
            delete body.role;
          }

          const anonKey = env.SUPABASE_ANON_KEY || '';
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;

          // v5.44.3+v92: Username IMMUTABLE. Lookup-Strategie:
          //   1. Existing-Profil per legacy_user_id ODER known UUID finden
          //   2. Wenn gefunden -> PATCH ohne username-Feld
          //      (Trigger enforce_username_immutability haut sonst zurueck)
          //   3. Wenn nicht gefunden -> INSERT mit allen Feldern inkl. username
          let existing = null;
          if (knownUuid) {
            const lookup = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?select=id,username,role,legacy_user_id&id=eq.${knownUuid}&limit=1`,
              { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
            );
            const arr = await lookup.json().catch(() => []);
            if (Array.isArray(arr) && arr.length > 0) existing = arr[0];
          }
          if (!existing && legacyUserId) {
            const lookup = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?select=id,username,role,legacy_user_id&legacy_user_id=eq.${encodeURIComponent(legacyUserId)}&limit=1`,
              { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
            );
            const arr = await lookup.json().catch(() => []);
            if (Array.isArray(arr) && arr.length > 0) existing = arr[0];
          }

          // v117: Neu-Registrierung gegen die Loesch-Blacklist pruefen.
          // Nur bei echtem INSERT (kein existing) und nicht fuer den Root-Admin.
          if (!existing && body.username &&
              body.username.toLowerCase() !== ADMIN_USERNAME) {
            const blHeaders = { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` };
            const hit = await findBlacklistedIdentity(blHeaders, {
              username: body.username,
              fullName: body.full_name || body.fullName ||
                [body.first_name, body.last_name].filter(Boolean).join(' '),
              birthDate: body.birth_date || body.birthDate,
              birthPlace: body.birth_place || body.birthPlace,
            });
            if (hit) {
              return jsonResponse({
                success: false,
                code: 'identity_blocked',
                error: 'Dieser Account wurde geloescht. Eine Neuanmeldung mit ' +
                       'diesen Daten ist gesperrt. Du kannst eine Freischaltung ' +
                       'beantragen.',
                reactivation_status: hit.reactivation_status || 'blocked',
              }, 403);
            }
          }

          let res;
          if (existing) {
            // UPDATE: username NIE veraendern (immutable). Root-Admin-Sonderfall
            // wird durch DB-Trigger gehandled - wir lassen username sicherheits-
            // halber im PATCH-Body komplett raus.
            const isRootAdmin = (existing.role || '').toLowerCase().replace('-', '_') === 'root_admin';
            const patchBody = { ...body };
            if (!isRootAdmin) {
              delete patchBody.username;
              delete patchBody.legacy_user_id; // legacy_user_id ist auch immutable
            }
            res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${existing.id}`, {
              method: 'PATCH',
              headers: {
                'Content-Type': 'application/json',
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
                'Prefer': 'return=representation',
              },
              body: JSON.stringify(patchBody),
            });
          } else {
            // INSERT: neuer User, alles inkl. username erlaubt.
            const insertBody = { ...body };
            if (legacyUserId) insertBody.legacy_user_id = legacyUserId;
            // Neue Profile bekommen explizit role='user'.
            insertBody.role = 'user';
            res = await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'apikey': serviceKey,
                'Authorization': `Bearer ${serviceKey}`,
                'Prefer': 'return=representation',
              },
              body: JSON.stringify(insertBody),
            });
          }
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

      // ── POST /api/profile/username-change-request (v92) ────────────────
      // Body: { userId, requested_username, reason? }
      // Erlaubt User einen Username-Wechsel zu beantragen. Pro User max
      // 1 pending Request gleichzeitig (DB-Constraint).
      if (method === 'POST' && parts[3] === 'username-change-request' && parts.length === 4) {
        try {
          const body = await request.json().catch(() => ({}));
          const incomingUserId = body.userId || body.user_id;
          const requested = String(body.requested_username || '').trim();
          const reason = String(body.reason || '').slice(0, 500);

          if (!incomingUserId) return errorResponse('userId fehlt', 400);
          if (!requested || requested.length < 3 || requested.length > 32) {
            return errorResponse('requested_username muss 3-32 Zeichen sein', 400);
          }
          if (!/^[a-zA-Z0-9_.\-]+$/.test(requested)) {
            return errorResponse(
              'requested_username darf nur Buchstaben/Zahlen/._- enthalten', 400
            );
          }

          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
          const svcH = { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` };

          // Lookup Profil
          const looksLikeUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(incomingUserId);
          const lookupCol = looksLikeUuid ? 'id' : 'legacy_user_id';
          const lookup = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,username,legacy_user_id,role&${lookupCol}=eq.${encodeURIComponent(incomingUserId)}&limit=1`,
            { headers: svcH }
          );
          const arr = await lookup.json().catch(() => []);
          const profile = Array.isArray(arr) && arr.length > 0 ? arr[0] : null;
          if (!profile) return errorResponse('Profil nicht gefunden', 404);

          // Prefer: Username schon frei? Wenn ja, bei root_admin DIREKT anwenden
          // sonst Antrag stellen.
          const isRootAdmin = (profile.role || '').toLowerCase() === 'root_admin';
          if (isRootAdmin) {
            // Direkt-Update (Trigger laesst root_admin durch)
            const patchRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${profile.id}`, {
              method: 'PATCH', headers: { ...svcH, 'Prefer': 'return=representation' },
              body: JSON.stringify({ username: requested }),
            });
            if (!patchRes.ok) {
              const t = await patchRes.text().catch(() => '');
              return errorResponse(`Direkt-Update fehlgeschlagen: ${t.slice(0, 200)}`);
            }
            return jsonResponse({
              success: true, direct: true, message: 'root_admin: direkt geaendert',
              new_username: requested,
            });
          }

          // Username schon belegt?
          const taken = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id&username=eq.${encodeURIComponent(requested)}&limit=1`,
            { headers: svcH }
          );
          const takenArr = await taken.json().catch(() => []);
          if (Array.isArray(takenArr) && takenArr.length > 0) {
            return errorResponse('Username bereits vergeben', 409);
          }

          // Insert Request
          const insertRes = await fetch(
            `${SUPABASE_URL}/rest/v1/username_change_requests`,
            {
              method: 'POST', headers: { ...svcH, 'Prefer': 'return=representation' },
              body: JSON.stringify({
                profile_id: profile.id,
                legacy_user_id: profile.legacy_user_id,
                current_username: profile.username,
                requested_username: requested,
                reason: reason || null,
                status: 'pending',
              }),
            }
          );
          if (!insertRes.ok) {
            const t = await insertRes.text().catch(() => '');
            // 23505 = unique_violation -> User hat schon einen pending Request
            if (t.includes('23505') || t.includes('one_pending_per_user')) {
              return errorResponse('Du hast bereits einen offenen Antrag', 409);
            }
            return errorResponse(`Antrag-Speicherung fehlgeschlagen: ${t.slice(0, 200)}`);
          }
          const reqData = await insertRes.json().catch(() => []);
          return jsonResponse({
            success: true, direct: false,
            message: 'Antrag eingereicht - wartet auf Admin-Approval',
            request: Array.isArray(reqData) ? reqData[0] : reqData,
          });
        } catch (e) {
          return errorResponse(`Username-Change-Request-Fehler: ${e.message}`);
        }
      }

      // ── GET /api/profile/my-username-request?userId=XXX ────────────────
      // Liefert aktuellen pending Request (oder null) fuer einen User.
      if (method === 'GET' && parts[3] === 'my-username-request') {
        try {
          const incomingUserId = url.searchParams.get('userId');
          if (!incomingUserId) return errorResponse('userId fehlt', 400);
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
          const looksLikeUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(incomingUserId);
          const lookupCol = looksLikeUuid ? 'profile_id' : 'legacy_user_id';
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/username_change_requests?select=*&${lookupCol}=eq.${encodeURIComponent(incomingUserId)}&status=eq.pending&limit=1`,
            { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
          );
          const arr = await r.json().catch(() => []);
          return jsonResponse({ request: Array.isArray(arr) && arr.length > 0 ? arr[0] : null });
        } catch (e) {
          return errorResponse(`My-Request-Fehler: ${e.message}`);
        }
      }

      // GET: Profil nach Username
      // v118: select=* damit ALLE Felder (full_name, birth_*, gender, ...)
      // zurueckkommen -- frueher fehlten sie -> Energie-Profil wurde
      // unvollstaendig (ohne Geburtsdaten) abgerufen.
      const username = parts[4];
      if (username) {
        const supaPath = `/rest/v1/profiles?select=*&username=eq.${encodeURIComponent(username)}&limit=1`;
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

      // GET /api/push/pending?user_id=UUID_or_legacy_id
      // Supports both UUID users and InvisibleAuth legacy_user_id ("user_<ts>_<rand>").
      if (method === 'GET' && path.includes('/pending')) {
        const userId = url.searchParams.get('user_id') || path.split('/').pop();
        if (!userId || userId === 'pending') {
          return jsonResponse({ notifications: [], count: 0 });
        }
        try {
          // Legacy IDs start with "user_" and go in the legacy_user_id column.
          const isLegacy = String(userId).startsWith('user_');
          const filter = isLegacy
            ? `legacy_user_id=eq.${encodeURIComponent(userId)}`
            : `user_id=eq.${encodeURIComponent(userId)}`;
          const fetchRes = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue?${filter}&status=eq.pending&select=*&order=created_at.asc&limit=50`,
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

      // AUDIT-FIX A4: Admin-Push-Endpoints (send-to-user, send-to-topic,
      // broadcast, schedule, test-suite) brauchen Admin-Auth. Vorher konnte
      // jeder mit Worker-URL Massen-Pushes verschicken.
      //
      // Subscribe/Unsubscribe/Register/Token-Update bleiben offen
      // (user-initiated, FCM-Token-Sync).
      const isAdminPushPath =
        path.endsWith('/test-suite') ||
        path.endsWith('/schedule') ||
        path.endsWith('/send-to-user') ||
        path.endsWith('/send-to-topic') ||
        (path.endsWith('/broadcast') && !path.includes('/admin/'));

      let pushCaller = null;
      if (isAdminPushPath) {
        const check = await requireAdmin(request, env);
        if (check.response) return check.response;
        pushCaller = check.caller;
      }

      // POST /api/push/test-suite → sendet alle 18 Test-Push-Notifications
      // serverseitig nacheinander (1s Abstand). App muss NICHT offen sein --
      // der Worker drained jeden Push sofort via FCM, sobald er in der
      // notification_queue ist.
      //
      // Body: { user_id: "<uuid oder user_<ts>_<rand>>" }
      // v103: Push-Test-Suite -- nach erfolgreicher Verifikation entfernbar.
      if (method === 'POST' && path.endsWith('/test-suite')) {
        const suiteBody = await request.json().catch(() => ({}));
        const userId = suiteBody?.user_id;
        if (!userId) return errorResponse('user_id required', 400);
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);

        const tests = [
          { id: '1.1', type: 'materie_breaking', title: '🔥 [TEST 1/18] Materie Breaking News', body: 'Test: Breaking-News-Push aus der Materie-Welt funktioniert!' },
          { id: '1.2', type: 'materie_research', title: '🔍 [TEST 2/18] Neue Recherche', body: 'Test: Recherche-Push aus der Materie-Welt funktioniert!' },
          { id: '1.3', type: 'energie_meditation', title: '🧘 [TEST 3/18] Meditation Update', body: 'Test: Meditations-Push aus der Energie-Welt funktioniert!' },
          { id: '1.4', type: 'energie_astral', title: '✨ [TEST 4/18] Astralreisen Update', body: 'Test: Astralreisen-Push aus der Energie-Welt funktioniert!' },
          { id: '1.5', type: 'daily_wisdom', title: '💡 [TEST 5/18] Tägliche Weisheit', body: 'Test: "Wissen ist der Schlüssel" -- Push funktioniert!' },
          { id: '1.6', type: 'weekly_summary', title: '📊 [TEST 6/18] Wöchentliche Zusammenfassung', body: 'Test: Wochen-Recap-Push funktioniert!' },
          { id: '2.1', type: 'chat_message', title: '💬 [TEST 7/18] Neue Chat-Nachricht', body: 'Test: Chat-Nachricht-Push funktioniert!' },
          { id: '2.2', type: 'chat_mention', title: '📢 [TEST 8/18] Du wurdest erwähnt!', body: 'Test: Mention-Push funktioniert!' },
          { id: '3.1', type: 'achievement', title: '🏆 [TEST 9/18] Achievement freigeschaltet!', body: 'Test: Achievement-Push funktioniert!' },
          { id: '3.2', type: 'level_up', title: '⬆️ [TEST 10/18] LEVEL UP!', body: 'Test: Level-Up-Push funktioniert!' },
          { id: '4.1', type: 'admin_ban', title: '🚫 [TEST 11/18] Account gesperrt', body: 'Test: Ban-Push funktioniert! (Kein echter Ban)' },
          { id: '4.2', type: 'admin_unban', title: '✅ [TEST 12/18] Sperre aufgehoben', body: 'Test: Unban-Push funktioniert!' },
          { id: '4.3', type: 'admin_warning', title: '⚠️ [TEST 13/18] Verwarnung', body: 'Test: Verwarnungs-Push funktioniert! (Kein echter Strike)' },
          { id: '4.4', type: 'admin_mute', title: '🔇 [TEST 14/18] Stummgeschaltet', body: 'Test: Mute-Push funktioniert! (Kein echter Mute)' },
          { id: '4.5', type: 'admin_role_change', title: '🛡️ [TEST 15/18] Rolle geändert', body: 'Test: Rollenwechsel-Push funktioniert! (Keine echte Änderung)' },
          { id: '5.1', type: 'admin_broadcast', title: '📢 [TEST 16/18] Admin-Ankündigung', body: 'Test: Broadcast-Push funktioniert!' },
          { id: '6.1', type: 'admin_xp_grant', title: '⭐ [TEST 17/18] +50 XP erhalten!', body: 'Test: XP-Grant-Push funktioniert! (Keine echten XP)' },
          { id: '8.1', type: 'scheduled_test', title: '⏰ [TEST 18/18] Alle Tests abgeschlossen!', body: 'Test: Scheduled-Push funktioniert! 🎉 Alle 18 Push-Typen getestet!' },
        ];

        // InvisibleAuth-IDs starten mit 'user_' und gehen in legacy_user_id.
        const isLegacy = String(userId).startsWith('user_');
        const idField = isLegacy ? 'legacy_user_id' : 'user_id';
        const results = [];
        let sent = 0;
        let failed = 0;
        const startedAt = new Date().toISOString();

        for (let i = 0; i < tests.length; i++) {
          const t = tests[i];
          try {
            const queueRow = {
              [idField]: userId,
              title: t.title,
              body: t.body,
              data: {
                type: t.type,
                test: true,
                test_id: t.id,
                test_index: i + 1,
                test_total: tests.length,
                timestamp: new Date().toISOString(),
              },
              status: 'pending',
            };
            const ins = await fetch(
              `${SUPABASE_URL}/rest/v1/notification_queue`,
              {
                method: 'POST',
                headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
                body: JSON.stringify(queueRow),
              }
            );
            if (!ins.ok) {
              const txt = await ins.text().catch(() => '');
              throw new Error(`HTTP ${ins.status}: ${txt.substring(0, 100)}`);
            }
            // Sofort dispatchen damit FCM-Push nicht auf den naechsten
            // Cron wartet (sonst bis zu 5 Min Verzoegerung pro Push).
            try {
              await dispatchPushQueue(env, pushAuth);
            } catch (_) { /* dispatch non-fatal */ }
            results.push({ id: t.id, success: true });
            sent++;
          } catch (e) {
            results.push({ id: t.id, success: false, error: e.message });
            failed++;
          }
          // 1 Sekunde Abstand zwischen Pushes
          if (i < tests.length - 1) {
            await new Promise(r => setTimeout(r, 1000));
          }
        }

        return jsonResponse({
          success: true,
          user_id: userId,
          id_field: idField,
          sent,
          failed,
          total: tests.length,
          started_at: startedAt,
          finished_at: new Date().toISOString(),
          results,
        });
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

      // ════════════════════════════════════════════════════════════
      // v103 PRODUCTION PUSH ENDPOINTS
      // ════════════════════════════════════════════════════════════

      // POST /api/push/schedule
      // Body: { target_user_id, type, title, body, data, scheduled_at }
      // scheduled_at: ISO8601 in der Zukunft. Wird in notification_queue
      // mit status=pending eingetragen; der naechste Cron-Run der nach
      // scheduled_at faellt holt sie via OR(scheduled_at IS NULL,
      // scheduled_at <= NOW()) und sendet via FCM.
      // v103 (8.1): zeitgesteuerte Pushes ohne Durable Objects.
      if (method === 'POST' && path.endsWith('/schedule')) {
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
        try {
          const targetUserId = body?.target_user_id || body?.user_id;
          const title = (body?.title || '').toString().trim();
          const msgBody = (body?.body || '').toString().trim();
          const type = body?.type || 'scheduled';
          const data = body?.data || {};
          const scheduledAt = body?.scheduled_at;
          if (!targetUserId || !title || !msgBody || !scheduledAt) {
            return errorResponse(
              'target_user_id, title, body, scheduled_at required', 400);
          }
          // Validiere scheduled_at -- muss ISO + in der Zukunft.
          const ts = Date.parse(scheduledAt);
          if (Number.isNaN(ts)) {
            return errorResponse('scheduled_at must be ISO8601', 400);
          }
          if (ts < Date.now() - 60_000) {
            return errorResponse(
              'scheduled_at must be in the future', 400);
          }
          const isLegacy = String(targetUserId).startsWith('user_');
          const row = isLegacy
            ? {
                legacy_user_id: targetUserId,
                title,
                body: msgBody,
                data: { ...data, type, scheduled: true },
                status: 'pending',
                scheduled_at: new Date(ts).toISOString(),
              }
            : {
                user_id: targetUserId,
                title,
                body: msgBody,
                data: { ...data, type, scheduled: true },
                status: 'pending',
                scheduled_at: new Date(ts).toISOString(),
              };
          const ins = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue`,
            {
              method: 'POST',
              headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=representation' },
              body: JSON.stringify(row),
            },
          );
          if (!ins.ok) {
            const txt = await ins.text().catch(() => '');
            return errorResponse(`Schedule ${ins.status}: ${txt.slice(0, 200)}`);
          }
          const inserted = await ins.json().catch(() => null);
          return jsonResponse({
            success: true,
            scheduled_at: new Date(ts).toISOString(),
            row: Array.isArray(inserted) ? inserted[0] : inserted,
          });
        } catch (e) {
          return errorResponse(`schedule failed: ${e.message}`);
        }
      }

      // POST /api/push/send-to-user
      // Body: { target_user_id, type, title, body, data }
      // Enqueues a push for ONE user (UUID or InvisibleAuth-ID), then
      // immediately drains the queue so FCM fires within seconds.
      if (method === 'POST' && path.endsWith('/send-to-user')) {
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
        try {
          const targetUserId = body?.target_user_id || body?.user_id;
          const type = body?.type || 'system';
          const title = (body?.title || '').toString().trim();
          const msgBody = (body?.body || '').toString().trim();
          const data = body?.data || {};
          if (!targetUserId || !title || !msgBody) {
            return errorResponse('target_user_id, title, body required', 400);
          }
          // Username-lookup falls targetUserId wie ein Username aussieht
          // (kein UUID, kein 'user_' Prefix).
          let resolvedId = targetUserId;
          const looksLikeUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(targetUserId);
          const isLegacy = String(targetUserId).startsWith('user_');
          if (!looksLikeUuid && !isLegacy) {
            try {
              const lookup = await fetch(
                `${SUPABASE_URL}/rest/v1/profiles?select=id,legacy_user_id&username=eq.${encodeURIComponent(targetUserId)}&limit=1`,
                { headers: pushAuth },
              );
              const rows = await lookup.json().catch(() => []);
              if (Array.isArray(rows) && rows.length > 0) {
                resolvedId = rows[0].id || rows[0].legacy_user_id || targetUserId;
              }
            } catch (_) {}
          }
          const useLegacy = String(resolvedId).startsWith('user_');
          const queueRow = useLegacy
            ? { legacy_user_id: resolvedId, title, body: msgBody, data: { ...data, type }, status: 'pending' }
            : { user_id: resolvedId, title, body: msgBody, data: { ...data, type }, status: 'pending' };
          const ins = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue`,
            {
              method: 'POST',
              headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
              body: JSON.stringify(queueRow),
            }
          );
          if (!ins.ok) {
            const txt = await ins.text().catch(() => '');
            return errorResponse(`Enqueue ${ins.status}: ${txt.slice(0, 200)}`);
          }
          // Immediate dispatch.
          try {
            await dispatchPushQueue(env, pushAuth);
          } catch (_) {}
          return jsonResponse({ success: true, target_user_id: resolvedId, type });
        } catch (e) {
          return errorResponse(`send-to-user failed: ${e.message}`);
        }
      }

      // POST /api/push/send-to-topic
      // Body: { topic, title, body, data }
      // Lookup all active push_subscriptions where device_info->topics
      // contains the topic, enqueue one push each, dispatch.
      if (method === 'POST' && path.endsWith('/send-to-topic')) {
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
        try {
          const topic = (body?.topic || '').toString().trim();
          const title = (body?.title || '').toString().trim();
          const msgBody = (body?.body || '').toString().trim();
          const data = body?.data || {};
          if (!topic || !title || !msgBody) {
            return errorResponse('topic, title, body required', 400);
          }
          // Query subscribers. device_info is JSONB; check ->topics ?| array.
          // Fallback: if no rows match the topic filter, treat as broadcast
          // (legacy clients without topics field still receive global pushes).
          const topicFilter =
            `device_info->topics=cs.["${topic.replace(/"/g, '\\"')}"]`;
          let recRes = await fetch(
            `${SUPABASE_URL}/rest/v1/push_subscriptions?select=user_id&is_active=eq.true&${topicFilter}&limit=5000`,
            { headers: pushAuth },
          );
          let recipients = recRes.ok ? await recRes.json().catch(() => []) : [];
          if (!Array.isArray(recipients) || recipients.length === 0) {
            // Fallback: kein Topic-Filter -> ALLE aktiven Subscriber.
            recRes = await fetch(
              `${SUPABASE_URL}/rest/v1/push_subscriptions?select=user_id&is_active=eq.true&limit=5000`,
              { headers: pushAuth },
            );
            recipients = recRes.ok ? await recRes.json().catch(() => []) : [];
          }
          const userIds = (Array.isArray(recipients) ? recipients : [])
            .map(r => r.user_id)
            .filter(id => id && !String(id).startsWith('00000000-'));
          if (userIds.length === 0) {
            return jsonResponse({ success: true, sent: 0, failed: 0, topic, note: 'no subscribers' });
          }
          const now = new Date().toISOString();
          const rows = userIds.map(uid => ({
            user_id: uid,
            title,
            body: msgBody,
            data: { ...data, type: data?.type || 'topic', topic, source: 'push_topic' },
            status: 'pending',
            created_at: now,
          }));
          const insRes = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue`,
            {
              method: 'POST',
              headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
              body: JSON.stringify(rows),
            },
          );
          if (!insRes.ok) {
            const txt = await insRes.text().catch(() => '');
            return errorResponse(`Enqueue ${insRes.status}: ${txt.slice(0, 200)}`);
          }
          try { await dispatchPushQueue(env, pushAuth); } catch (_) {}
          return jsonResponse({ success: true, sent: userIds.length, failed: 0, topic });
        } catch (e) {
          return errorResponse(`send-to-topic failed: ${e.message}`);
        }
      }

      // POST /api/push/broadcast
      // Body: { title, body, data }   -- admin field IGNORED (vom Auth-Header)
      // Sends to ALL active subscribers. Logs admin_audit_log.
      if (method === 'POST' && path.endsWith('/broadcast') && !path.includes('/admin/')) {
        if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
        // AUDIT-FIX A4 + B1: Caller-Identitaet aus verifiziertem Header,
        // NICHT aus body.admin (client-controllable). High-Privilege fuer
        // Broadcast (alle User) -- nur admin/root_admin, keine Moderators.
        if (!pushCaller || !pushCaller.isHighPrivilege) {
          return errorResponse('Broadcast erfordert Admin oder Root-Admin', 403);
        }
        try {
          const title = (body?.title || '').toString().trim();
          const msgBody = (body?.body || '').toString().trim();
          const data = body?.data || {};
          const adminUsername = pushCaller.username;
          if (!title || !msgBody) {
            return errorResponse('title, body required', 400);
          }
          const recRes = await fetch(
            `${SUPABASE_URL}/rest/v1/push_subscriptions?select=user_id&is_active=eq.true&limit=5000`,
            { headers: pushAuth },
          );
          const recipients = recRes.ok ? await recRes.json().catch(() => []) : [];
          const userIds = (Array.isArray(recipients) ? recipients : [])
            .map(r => r.user_id)
            .filter(id => id && !String(id).startsWith('00000000-'));
          if (userIds.length === 0) {
            return jsonResponse({ success: true, sent: 0, failed: 0, note: 'no subscribers' });
          }
          const now = new Date().toISOString();
          const rows = userIds.map(uid => ({
            user_id: uid,
            title,
            body: msgBody,
            data: { ...data, type: 'admin_broadcast', source: 'push_broadcast', admin: adminUsername },
            status: 'pending',
            created_at: now,
          }));
          const insRes = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue`,
            {
              method: 'POST',
              headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
              body: JSON.stringify(rows),
            },
          );
          if (!insRes.ok) {
            const txt = await insRes.text().catch(() => '');
            return errorResponse(`Enqueue ${insRes.status}: ${txt.slice(0, 200)}`);
          }
          // Audit log (best-effort, v115: korrektes Schema via logAudit).
          logAudit(pushAuth, {
            admin_username: adminUsername,
            action: 'push_broadcast',
            target_id: 'all',
            details: { title, body: msgBody, recipients: userIds.length },
          });
          try { await dispatchPushQueue(env, pushAuth); } catch (_) {}
          return jsonResponse({ success: true, sent: userIds.length, failed: 0 });
        } catch (e) {
          return errorResponse(`broadcast failed: ${e.message}`);
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

    // ── Presence: online users (for livestream invite picker) ──
    // GET /api/presence/online?exclude=<user_id>
    // Returns app users with last_seen_at within the last 15 minutes.
    if (path === '/api/presence/online' && method === 'GET') {
      try {
        const anonKey = env.SUPABASE_ANON_KEY || '';
        const excludeId = url.searchParams.get('exclude') || '';
        const cutoff = new Date(Date.now() - 15 * 60 * 1000).toISOString();
        const res = await fetch(
          `${SUPABASE_URL}/rest/v1/profiles?select=id,username,avatar_url,last_seen_at` +
            `&last_seen_at=gte.${encodeURIComponent(cutoff)}` +
            `&username=not.is.null` +
            `&order=last_seen_at.desc&limit=50`,
          { headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` } }
        );
        const rows = await res.json().catch(() => []);
        const safe = Array.isArray(rows) ? rows : [];
        const users = safe
          .filter((p) => String(p.id) !== excludeId)
          .map((p) => ({
            user_id: p.id,
            username: p.username,
            avatar_url: p.avatar_url || null,
            last_seen: p.last_seen_at || null,
          }));
        return jsonResponse({ users, count: users.length });
      } catch (e) {
        return jsonResponse({ users: [], count: 0 });
      }
    }

    // ── LiveKit invite: push notification to selected users ────
    // POST /api/livekit/invite
    // Body: { from_name, room_name, world, target_user_ids: [...] }
    if (path === '/api/livekit/invite' && method === 'POST') {
      const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || '';
      const anonKey = env.SUPABASE_ANON_KEY || '';
      const pushAuth = serviceKey
        ? { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` }
        : { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` };
      if (!serviceKey) return errorResponse('SERVICE_ROLE_KEY required', 500);
      try {
        const body = await request.json().catch(() => ({}));
        const fromName = (body?.from_name || '').toString();
        const roomName = (body?.room_name || '').toString().trim();
        const world = (body?.world || '').toString();
        const targetIds = Array.isArray(body?.target_user_ids)
          ? body.target_user_ids
          : [];
        if (!roomName || targetIds.length === 0) {
          return errorResponse('room_name and target_user_ids required', 400);
        }
        // Build one notification_queue row per target. Mirror send-to-user:
        // legacy 'user_' ids use legacy_user_id, UUIDs use user_id.
        const rows = targetIds.map((id) => {
          const base = {
            title: '🎙️ Live-Einladung',
            body: `${fromName || 'Jemand'} lädt dich in einen Live-Call ein`,
            data: { type: 'livekit_invite', room_name: roomName, world, from_name: fromName },
            status: 'pending',
          };
          return String(id).startsWith('user_')
            ? { legacy_user_id: id, ...base }
            : { user_id: id, ...base };
        });
        const ins = await fetch(
          `${SUPABASE_URL}/rest/v1/notification_queue`,
          {
            method: 'POST',
            headers: { ...pushAuth, 'Content-Type': 'application/json', 'Prefer': 'return=minimal' },
            body: JSON.stringify(rows),
          }
        );
        if (!ins.ok) {
          const txt = await ins.text().catch(() => '');
          return errorResponse(`Enqueue ${ins.status}: ${txt.slice(0, 200)}`);
        }
        // Immediate dispatch.
        try {
          await dispatchPushQueue(env, pushAuth);
        } catch (_) {}
        return jsonResponse({ success: true, invited: targetIds.length });
      } catch (e) {
        return errorResponse(`livekit invite failed: ${e.message}`);
      }
    }

    // ── Nutzer-Suche fuer Einladungssheet ─────────────────────
    // GET /api/users/search?q=<query>&limit=20
    // Gibt Nutzerliste zurueck (gefiltert nach Username-Prefix, case-insensitive).
    if (path === '/api/users/search' && method === 'GET') {
      try {
        const q = (url.searchParams.get('q') || '').trim();
        const lim = Math.min(parseInt(url.searchParams.get('limit') || '20', 10), 50);
        const anonKey = env.SUPABASE_ANON_KEY || '';
        const filter = q.length >= 1
          ? `&username=ilike.${encodeURIComponent(q + '*')}`
          : '';
        const res = await fetch(
          `${SUPABASE_URL}/rest/v1/profiles?select=id,username,avatar_url,last_seen_at&username=not.is.null${filter}&order=username.asc&limit=${lim}`,
          { headers: { 'apikey': anonKey, 'Authorization': `Bearer ${anonKey}` } }
        );
        const rows = await res.json().catch(() => []);
        const safe = Array.isArray(rows) ? rows : [];
        const now = Date.now();
        const users = safe.map(p => ({
          user_id: p.id,
          username: p.username,
          avatar_url: p.avatar_url || null,
          is_online: p.last_seen_at
            ? (now - new Date(p.last_seen_at).getTime()) < 15 * 60 * 1000
            : false,
        }));
        return jsonResponse({ users, count: users.length });
      } catch (e) {
        return jsonResponse({ users: [], count: 0 });
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
      const caller = await verifyAdminCaller(request, env);
      if (!caller) return errorResponse('Nicht autorisiert', 403);
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

    // ════════════════════════════════════════════════════════════════
    // v117: Oeffentliche User-Endpoints (Notification-Loeschen + Antraege).
    // Kein Admin-Gate. InvisibleAuth-tauglich: userId kann UUID oder
    // legacy user_<ts> sein. Schreiben via service_role (RLS-Bypass), aber
    // streng auf die mitgelieferte Identitaet beschraenkt.
    // ════════════════════════════════════════════════════════════════
    if (path.startsWith('/api/notifications') || path.startsWith('/api/account/')) {
      const pubKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
      const pubHeaders = {
        'Content-Type': 'application/json',
        'apikey': pubKey,
        'Authorization': `Bearer ${pubKey}`,
      };

      // Helper: notifications-Filter fuer eine (Invisible)Auth-Identitaet.
      const notifIdentityFilter = (uid) => String(uid).startsWith('user_')
        ? `legacy_user_id=eq.${encodeURIComponent(uid)}`
        : `user_id=eq.${encodeURIComponent(uid)}`;

      // ── DELETE /api/notifications/all?userId=X  (alle loeschen) ──────
      if (method === 'DELETE' && path === '/api/notifications/all') {
        const uid = url.searchParams.get('userId');
        if (!uid) return errorResponse('userId fehlt', 400);
        await fetch(`${SUPABASE_URL}/rest/v1/notifications?${notifIdentityFilter(uid)}`,
          { method: 'DELETE', headers: pubHeaders }).catch(() => {});
        return jsonResponse({ success: true });
      }

      // ── DELETE /api/notifications/:id?userId=X  (eine loeschen) ──────
      if (method === 'DELETE' && /^\/api\/notifications\/[^/]+\/?$/.test(path) &&
          path !== '/api/notifications/mark-read') {
        const id = path.split('/')[3];
        const uid = url.searchParams.get('userId');
        if (!id || !uid) return errorResponse('id/userId fehlt', 400);
        // Nur loeschen wenn die Notification der mitgelieferten Identitaet gehoert.
        const res = await fetch(
          `${SUPABASE_URL}/rest/v1/notifications?id=eq.${encodeURIComponent(id)}&${notifIdentityFilter(uid)}`,
          { method: 'DELETE', headers: { ...pubHeaders, 'Prefer': 'return=minimal' } });
        return jsonResponse({ success: res.ok });
      }

      // ── GET /api/notifications?userId=X&unreadOnly=&limit= ───────────
      // Liest die In-App-Notifications via service_role (umgeht RLS).
      // KRITISCH fuer InvisibleAuth-User: die haben kein auth.uid(), koennen
      // die notifications-Tabelle also NICHT direkt via Supabase lesen
      // (RLS-Policy auth.uid()=user_id schlaegt fehl). Der Worker liefert
      // die Daten identitaetsgefiltert (user_id ODER legacy_user_id).
      if (method === 'GET' && path === '/api/notifications') {
        const uid = url.searchParams.get('userId');
        if (!uid) return errorResponse('userId fehlt', 400);
        const unreadOnly = url.searchParams.get('unreadOnly') === 'true';
        const limit = Math.min(
          parseInt(url.searchParams.get('limit') || '100', 10) || 100, 200);
        let q = `${SUPABASE_URL}/rest/v1/notifications?${notifIdentityFilter(uid)}&order=created_at.desc&limit=${limit}`;
        if (unreadOnly) q += `&or=(is_read.is.false,is_read.is.null)`;
        const r = await fetch(q, { headers: pubHeaders });
        const rows = r.ok ? await r.json().catch(() => []) : [];
        return jsonResponse({
          success: true,
          notifications: Array.isArray(rows) ? rows : [],
        });
      }

      // ── POST /api/notifications/mark-read  { userId, id? } ───────────
      // id gesetzt -> diese eine; sonst ALLE ungelesenen des Users.
      // Setzt beide Gelesen-Spalten (is_read + read_at) konsistent.
      if (method === 'POST' && path === '/api/notifications/mark-read') {
        const body = await request.json().catch(() => ({}));
        const uid = body.userId;
        if (!uid) return errorResponse('userId fehlt', 400);
        const patch = { is_read: true, read_at: new Date().toISOString() };
        let target = `${SUPABASE_URL}/rest/v1/notifications?${notifIdentityFilter(uid)}`;
        if (body.id) {
          target += `&id=eq.${encodeURIComponent(body.id)}`;
        } else {
          target += `&or=(is_read.is.false,is_read.is.null)`;
        }
        const r = await fetch(target, {
          method: 'PATCH',
          headers: { ...pubHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify(patch),
        });
        return jsonResponse({ success: r.ok });
      }

      // ── GET /api/account/identity-lookup ────────────────────────────
      // Auto-Fill: findet zu Vor+Nachname den bereits hinterlegten Username.
      // Zusaetzlich Blacklist-Vorabpruefung fuer die Registrierung.
      // Query: firstName, lastName [, username, birthDate, birthPlace]
      if (method === 'GET' && path === '/api/account/identity-lookup') {
        const firstName = (url.searchParams.get('firstName') || '').trim();
        const lastName = (url.searchParams.get('lastName') || '').trim();
        const username = (url.searchParams.get('username') || '').trim();
        const birthDate = (url.searchParams.get('birthDate') || '').trim();
        const birthPlace = (url.searchParams.get('birthPlace') || '').trim();
        const fullName = [firstName, lastName].filter(Boolean).join(' ').trim();

        let matchedUsername = null;
        let matchedWorld = null;
        if (fullName.length >= 3) {
          try {
            // Case-insensitive Exakt-Match auf full_name.
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?full_name=ilike.${encodeURIComponent(fullName)}` +
                `&select=username,world&limit=1`,
              { headers: pubHeaders });
            if (r.ok) {
              const rows = await r.json().catch(() => []);
              if (Array.isArray(rows) && rows.length > 0) {
                matchedUsername = rows[0].username || null;
                matchedWorld = rows[0].world || null;
              }
            }
          } catch (_) {}
        }

        // Blacklist-Check (geloeschte Identitaet).
        let blacklisted = false;
        let reactivationStatus = null;
        if (fullName.length >= 3 || username.length >= 3) {
          const hit = await findBlacklistedIdentity(pubHeaders, {
            username: username || matchedUsername,
            fullName, birthDate, birthPlace,
          });
          if (hit) {
            blacklisted = true;
            reactivationStatus = hit.reactivation_status || 'blocked';
          }
        }

        return jsonResponse({
          success: true,
          matched_username: matchedUsername,
          matched_world: matchedWorld,
          blacklisted,
          reactivation_status: reactivationStatus,
        });
      }

      // ── GET /api/account/restrictions?userId=X  (eigene Sperren) ─────
      if (method === 'GET' && path === '/api/account/restrictions') {
        const uid = url.searchParams.get('userId');
        const uname = url.searchParams.get('username');
        if (!uid && !uname) return jsonResponse({ success: true, restrictions: [] });
        const resolved = uid ? (await resolveProfileUuid(uid, pubHeaders) ?? uid) : null;
        const scopes = await getActiveRestrictionScopes(pubHeaders, { userId: resolved, username: uname });
        // Detail-Zeilen (Grund + Ablauf) fuer die Anzeige.
        const ors = [];
        if (resolved) ors.push(`user_id.eq.${encodeURIComponent(resolved)}`);
        if (uname) ors.push(`username.eq.${encodeURIComponent(uname)}`);
        let rows = [];
        if (ors.length) {
          const nowIso = new Date().toISOString();
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/user_restrictions?or=(${ors.join(',')})` +
              `&or=(is_permanent.eq.true,expires_at.is.null,expires_at.gt.${nowIso})` +
              `&select=scope,reason,is_permanent,expires_at,created_at`,
            { headers: pubHeaders });
          rows = r.ok ? await r.json().catch(() => []) : [];
        }
        return jsonResponse({ success: true, scopes, restrictions: rows });
      }

      // ── POST /api/account/reactivation-request ──────────────────────
      // Body: { username, full_name?, birth_date?, birth_place?, message? }
      if (method === 'POST' && path === '/api/account/reactivation-request') {
        let body = {};
        try { body = await request.json(); } catch (_) {}
        const username = String(body?.username || '').trim();
        if (!username) return errorResponse('username fehlt', 400);
        await fetch(`${SUPABASE_URL}/rest/v1/account_requests`, {
          method: 'POST', headers: { ...pubHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify({
            type: 'reactivation', username,
            full_name: body?.full_name || null, birth_date: body?.birth_date || null,
            birth_place: body?.birth_place || null,
            message: String(body?.message || '').slice(0, 1000), status: 'pending',
          }),
        }).catch(() => {});
        // Blacklist-Eintrag(e) auf 'requested' setzen (sichtbar fuer Admin).
        const unameLower = username.toLowerCase();
        fetch(`${SUPABASE_URL}/rest/v1/deleted_identities?username_lower=eq.${encodeURIComponent(unameLower)}&reactivation_status=eq.blocked`, {
          method: 'PATCH', headers: pubHeaders,
          body: JSON.stringify({ reactivation_status: 'requested' }),
        }).catch(() => {});
        await notifyAdmins(pubHeaders, '🔓 Reaktivierungs-Antrag',
          `${username} moechte das geloeschte Konto reaktivieren.`,
          { type: 'reactivation_request', username });
        return jsonResponse({ success: true });
      }

      // ── POST /api/account/appeal  (Einspruch gegen Sperre) ──────────
      // Body: { userId, username?, scope?, message }
      if (method === 'POST' && path === '/api/account/appeal') {
        let body = {};
        try { body = await request.json(); } catch (_) {}
        const userId = String(body?.userId || '').trim();
        if (!userId) return errorResponse('userId fehlt', 400);
        await fetch(`${SUPABASE_URL}/rest/v1/account_requests`, {
          method: 'POST', headers: { ...pubHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify({
            type: 'appeal', user_id: userId, username: body?.username || null,
            restriction_scope: body?.scope || null,
            message: String(body?.message || '').slice(0, 1000), status: 'pending',
          }),
        }).catch(() => {});
        await notifyAdmins(pubHeaders, '⚖️ Einspruch eingegangen',
          `${body?.username || userId} legt Einspruch gegen eine Sperre ein.`,
          { type: 'appeal_request', user_id: userId });
        return jsonResponse({ success: true });
      }

      // ── POST /api/account/self-delete-request  (Selbst-Loeschung) ───
      // Body: { userId, username?, full_name?, birth_date?, birth_place?, message? }
      if (method === 'POST' && path === '/api/account/self-delete-request') {
        let body = {};
        try { body = await request.json(); } catch (_) {}
        const userId = String(body?.userId || '').trim();
        if (!userId) return errorResponse('userId fehlt', 400);
        await fetch(`${SUPABASE_URL}/rest/v1/account_requests`, {
          method: 'POST', headers: { ...pubHeaders, 'Prefer': 'return=minimal' },
          body: JSON.stringify({
            type: 'self_deletion', user_id: userId, username: body?.username || null,
            full_name: body?.full_name || null, birth_date: body?.birth_date || null,
            birth_place: body?.birth_place || null,
            message: String(body?.message || '').slice(0, 1000), status: 'pending',
          }),
        }).catch(() => {});
        await notifyAdmins(pubHeaders, '🗑️ Loeschungs-Antrag',
          `${body?.username || userId} beantragt die Loeschung des eigenen Kontos.`,
          { type: 'self_deletion_request', user_id: userId });
        return jsonResponse({ success: true });
      }
      // Faellt durch zu 404 wenn kein public-Endpoint matched.
    }

    // ── Admin Benutzer-Aktionen ───────────────────────────────
    if (path.startsWith('/api/admin/')) {
      // AUDIT-FIX A1: Auth-Bypass geschlossen. Jeder /api/admin/*-Call muss
      // X-Admin-Username + X-Admin-Token mitschicken, der HMAC wird vom
      // Worker gegen env.ADMIN_AUTH_SECRET verifiziert UND die Rolle wird
      // live aus profiles.role gelesen (kein Token-Trust). Bei Demotion
      // wirkt der Entzug sofort beim naechsten Request.
      //
      // Ausnahmen (oeffentliche admin-readonly Endpoints):
      //   /api/admin/audit/recent  -- Mod-Audit-Read, separater Gate unten
      //   /api/admin/dashboard     -- nur Stats, separater Gate unten
      // Diese fragen weiter unten explizit nochmal nach.
      const callerCheck = await requireAdmin(request, env);
      if (callerCheck.response) return callerCheck.response;
      const caller = callerCheck.caller;

      const svcKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
      const svcHeaders = {
        'Content-Type': 'application/json',
        'apikey': svcKey,
        'Authorization': `Bearer ${svcKey}`,
      };

      // Helper: Notification in beiden Tabellen speichern (In-App + FCM-Queue)
      // v96: InvisibleAuth-tauglich. Wenn userId mit 'user_' beginnt, ist
      // es eine InvisibleAuth-ID -> wir setzen legacy_user_id statt
      // user_id (UUID). Sonst normal UUID-Pfad.
      const pushNotif = async (userId, type, title, body, data = {}) => {
        if (!userId || !svcKey) return;
        const h = svcHeaders;
        const isLegacy = String(userId).startsWith('user_');
        const queueRow = isLegacy
          ? { legacy_user_id: userId, title, body, data, status: 'pending' }
          : { user_id: userId, title, body, data, status: 'pending' };
        const notifRow = isLegacy
          ? { legacy_user_id: userId, type, title, body, data }
          : { user_id: userId, type, title, body, data };
        await Promise.all([
          fetch(`${SUPABASE_URL}/rest/v1/notifications`, {
            method: 'POST', headers: { ...h, 'Prefer': 'return=minimal' },
            body: JSON.stringify(notifRow),
          }).catch(() => {}),
          fetch(`${SUPABASE_URL}/rest/v1/notification_queue`, {
            method: 'POST', headers: { ...h, 'Prefer': 'return=minimal' },
            body: JSON.stringify(queueRow),
          }).catch(() => {}),
        ]);
      };

      // ── VIDEO-ARCHIV (Mediathek) ──────────────────────────────────────
      // Admin pflegt YouTube-Videos in archive_videos ein. Es wird NIE ein
      // Video heruntergeladen/re-gehostet -- nur die YouTube-Video-ID +
      // Metadaten gespeichert, der Client bettet via youtube_player_flutter
      // ein. Nur status='confirmed' ist fuer Nutzer sichtbar (RLS).
      const VIDEO_WORLDS = new Set(['materie', 'energie', 'vorhang', 'ursprung']);
      const VIDEO_STATUSES = new Set(['pending', 'confirmed', 'rejected']);

      // Serien-Erkennung: entfernt Teil/Part/Folge/Episode/Kapitel-Marker +
      // "#N" / "(1/5)" am Titel-Ende, damit "Die Macht Teil 2" auf den
      // Basis-Titel "Die Macht" reduziert wird (= gleicher Stamm wie Teil 1).
      // Gibt den getrimmten Basis-Titel zurueck, oder '' wenn kein Marker da war.
      const stripSeriesMarker = (rawTitle) => {
        const t = String(rawTitle || '').trim();
        if (!t) return '';
        let base = t
          .replace(
            /[\s\-–—|:,.]*\b(teil|part|pt|folge|episode|ep|kapitel|chapter|vol|volume)\.?\s*\d+\b.*$/i,
            ''
          )
          .replace(/[\s\-–—|:,.]*[#(]\s*\d+\s*(\/\s*\d+)?\s*\)?\s*$/i, '')
          .trim();
        // Trailing-Trennzeichen abschneiden.
        base = base.replace(/[\s\-–—|:,.]+$/, '').trim();
        // Nur als Serie werten, wenn ein Marker tatsaechlich entfernt wurde
        // und der Basis-Titel noch sinnvoll lang ist.
        if (base.length >= 4 && base.toLowerCase() !== t.toLowerCase()) {
          return base;
        }
        return '';
      };

      // Extract the 11-char YouTube video id from a URL or raw id.
      const extractYoutubeId = (input) => {
        const s = String(input || '').trim();
        if (!s) return null;
        // Raw 11-char id (allowed chars: A-Za-z0-9_-)
        if (/^[A-Za-z0-9_-]{11}$/.test(s)) return s;
        // Try common URL shapes
        const patterns = [
          /[?&]v=([A-Za-z0-9_-]{11})/, // watch?v=ID
          /youtu\.be\/([A-Za-z0-9_-]{11})/, // youtu.be/ID
          /\/embed\/([A-Za-z0-9_-]{11})/, // /embed/ID
          /\/shorts\/([A-Za-z0-9_-]{11})/, // /shorts/ID
          /\/live\/([A-Za-z0-9_-]{11})/, // /live/ID
        ];
        for (const re of patterns) {
          const m = s.match(re);
          if (m) return m[1];
        }
        return null;
      };

      // Best-effort: fetch title + thumbnail from YouTube oEmbed (no API key).
      const fetchYoutubeOembed = async (videoId) => {
        try {
          const r = await fetch(
            `https://www.youtube.com/oembed?url=${encodeURIComponent(
              'https://www.youtube.com/watch?v=' + videoId
            )}&format=json`
          );
          if (!r.ok) return null;
          const j = await r.json().catch(() => null);
          if (!j) return null;
          return {
            title: j.title || null,
            author_name: j.author_name || null,
            thumbnail_url:
              j.thumbnail_url ||
              `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`,
          };
        } catch (_) {
          return null;
        }
      };

      // Keyword-Heuristik als letzter Fallback (ohne KI). Liefert worlds[] +
      // Kategorie aus dem Titel/Kanalnamen. Bewusst grob -- nur Notnagel.
      const heuristicClassify = (text) => {
        const t = String(text || '').toLowerCase();
        const has = (words) => words.some((w) => t.includes(w));
        const worlds = [];
        if (
          has([
            'ufo', 'ufologie', 'uap', 'beweis', 'doku', 'recherche',
            'geheim', 'akte', 'whistleblow', 'geopolit', 'geschichte',
            'wissenschaft', 'physik', 'experiment', 'studie',
          ])
        ) {
          worlds.push('materie');
        }
        if (
          has([
            'meditation', 'chakra', 'frequenz', 'heilung', 'energie',
            'astral', 'manifest', 'bewusstsein', 'achtsamkeit', 'spirit',
            'aura', 'reiki', 'solfeggio', 'atem',
          ])
        ) {
          worlds.push('energie');
        }
        if (
          has([
            'propaganda', 'manipulation', 'macht', 'elite', 'kontrolle',
            'medien', 'narrativ', 'psychologie', 'strategie', 'agenda',
            'lobby', 'zensur',
          ])
        ) {
          worlds.push('vorhang');
        }
        if (
          has([
            'ursprung', 'remote viewing', 'gateway', 'hermet', 'mystik',
            'holograf', 'hologramm', 'schöpfung', 'schoepfung', 'seele',
            'matrix', 'simulation', 'quelle',
          ])
        ) {
          worlds.push('ursprung');
        }
        if (worlds.length === 0) worlds.push('materie');

        let category = 'Video';
        if (has(['doku', 'dokumentation'])) category = 'Doku';
        else if (has(['interview', 'gespräch', 'gespraech'])) {
          category = 'Interview';
        } else if (has(['vortrag', 'talk', 'lecture'])) category = 'Vortrag';
        else if (has(['meditation', 'geführt', 'gefuehrt'])) {
          category = 'Meditation';
        } else if (has(['wissenschaft', 'physik', 'studie'])) {
          category = 'Wissenschaft';
        }
        return { worlds, category };
      };

      // KI-gestuetzte Klassifikation: Titel + Kanal -> worlds[] + Kategorie.
      // GROQ-first (Llama 3.3 70B), Workers-AI-Fallback (Llama 3.1 8B),
      // Keyword-Heuristik als letzter Notnagel. Gibt immer ein valides
      // Ergebnis zurueck (nie null).
      const classifyVideo = async (title, author) => {
        const text = `${title || ''} ${author ? '(Kanal: ' + author + ')' : ''}`.trim();
        const systemPrompt =
          'Du bist ein Klassifikator fuer eine spirituell-investigative Wissensplattform mit vier Welten. ' +
          'Ordne ein YouTube-Video anhand von Titel und Kanal einer oder mehreren Welten zu und schlage eine kurze deutsche Kategorie vor.\n\n' +
          'Welten:\n' +
          '- materie: harte Recherche, Wissenschaft, Fakten, Geopolitik, Geschichte, UFOs/UAP, investigative Dokus.\n' +
          '- energie: Spiritualitaet, Meditation, Chakren, Frequenzen, Heilung, Astralreisen, Manifestation, Bewusstsein.\n' +
          '- vorhang: verdeckte Machtstrukturen, Propaganda, Medien-Manipulation, Psychologie der Macht, Strategie.\n' +
          '- ursprung: Ursprung von Bewusstsein/Mensch, Remote Viewing, Hermetik, Mystik, holografisches Universum, Simulation.\n\n' +
          'Antworte AUSSCHLIESSLICH mit kompaktem JSON ohne Markdown:\n' +
          '{"worlds":["..."],"category":"..."}\n' +
          'Maximal 2 Welten, nur die Slugs materie/energie/vorhang/ursprung. Kategorie max. 2 Woerter.';

        const parseAi = (raw) => {
          if (!raw) return null;
          try {
            const m = String(raw).match(/\{[\s\S]*\}/);
            if (!m) return null;
            const obj = JSON.parse(m[0]);
            const worlds = Array.isArray(obj.worlds)
              ? obj.worlds
                  .map((w) => String(w).toLowerCase().trim())
                  .filter((w) => VIDEO_WORLDS.has(w))
              : [];
            if (worlds.length === 0) return null;
            const category =
              obj.category && String(obj.category).trim()
                ? String(obj.category).trim().slice(0, 40)
                : null;
            return { worlds: worlds.slice(0, 2), category };
          } catch (_) {
            return null;
          }
        };

        // 1) GROQ
        if (env.GROQ_API_KEY) {
          try {
            const r = await fetch(
              'https://api.groq.com/openai/v1/chat/completions',
              {
                method: 'POST',
                headers: {
                  Authorization: `Bearer ${env.GROQ_API_KEY}`,
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  model: 'llama-3.3-70b-versatile',
                  messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: `Video: "${text}"` },
                  ],
                  max_tokens: 120,
                  temperature: 0.2,
                }),
              }
            );
            if (r.ok) {
              const d = await r.json().catch(() => null);
              const parsed = parseAi(d?.choices?.[0]?.message?.content);
              if (parsed) return { ...parsed, source: 'groq' };
            }
          } catch (_) {}
        }

        // 2) Workers AI
        if (env.AI) {
          try {
            const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
              messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: `Video: "${text}"` },
              ],
              max_tokens: 120,
            });
            const parsed = parseAi(res?.response);
            if (parsed) return { ...parsed, source: 'workers-ai' };
          } catch (_) {}
        }

        // 3) Heuristik
        return { ...heuristicClassify(text), source: 'heuristic' };
      };

      // ── POST /api/admin/videos/suggest  (KI-Vorschlag Welt + Kategorie) ─
      // Body: { youtube_url | youtube_video_id }
      // Liefert Titel/Thumbnail (oEmbed) + vorgeschlagene worlds[] + Kategorie.
      if (method === 'POST' && path === '/api/admin/videos/suggest') {
        try {
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const videoId = extractYoutubeId(
            body.youtube_video_id || body.youtube_url
          );
          if (!videoId) {
            return errorResponse(
              'Ungueltige YouTube-URL oder Video-ID',
              400,
              'invalid_youtube_id'
            );
          }
          const meta = await fetchYoutubeOembed(videoId);
          const title = meta?.title || '';
          let suggestion = await classifyVideo(title, meta?.author_name);

          // Serien-Erkennung: wenn der Titel ein "Teil 2"/"Part 3"/... ist,
          // nach einem bereits eingepflegten Geschwister-Video mit gleichem
          // Basis-Titel suchen und dessen Kategorie + Welten uebernehmen.
          // So landet "Teil 2" automatisch in derselben Kategorie wie "Teil 1".
          const base = stripSeriesMarker(title);
          if (base) {
            try {
              const sibRes = await fetch(
                `${SUPABASE_URL}/rest/v1/archive_videos` +
                  `?youtube_title=ilike.${encodeURIComponent(base + '*')}` +
                  `&select=category,worlds,youtube_title&order=created_at.desc&limit=1`,
                { headers: svcHeaders }
              );
              if (sibRes.ok) {
                const sibs = await sibRes.json().catch(() => []);
                if (Array.isArray(sibs) && sibs.length > 0) {
                  const sib = sibs[0];
                  const sibWorlds = Array.isArray(sib.worlds) ? sib.worlds : [];
                  suggestion = {
                    worlds: sibWorlds.length ? sibWorlds : suggestion.worlds,
                    category: sib.category || suggestion.category,
                    source: 'series_sibling',
                  };
                }
              }
            } catch (_) { /* Serie best-effort -- Heuristik bleibt Fallback */ }
          }

          return jsonResponse({
            success: true,
            video_id: videoId,
            title: title || null,
            thumbnail_url:
              meta?.thumbnail_url ||
              `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`,
            worlds: suggestion.worlds,
            category: suggestion.category,
            source: suggestion.source,
            series_base: base || null,
          });
        } catch (e) {
          return errorResponse(`Vorschlag-Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/videos/search  (YouTube-Suche fuer Admin) ──────
      // ?q=Suchbegriff &max_results=8
      // Robust: Piped API zuerst (kostenlos, kein Key, keine Quota), dann
      // YouTube Data API v3 als Fallback (falls YOUTUBE_API_KEY gesetzt).
      // Grund: Die YouTube Data API hat nur 10k Units/Tag -- eine Suche
      // kostet 100 Units -> nach ~100 Suchen liefert sie 403/quotaExceeded
      // und der Admin saehe "keine Videos". Piped umgeht das komplett.
      if (method === 'GET' && path === '/api/admin/videos/search') {
        try {
          const q = (url.searchParams.get('q') || '').trim();
          const maxResults = Math.min(
            10,
            parseInt(url.searchParams.get('max_results') || '8')
          );
          if (!q) {
            return errorResponse('Suchbegriff erforderlich', 400, 'missing_query');
          }

          let videos = [];

          // 1) Piped API (kostenlos, kein API-Key). Mehrere Spiegel, da
          //    einzelne Instanzen zeitweise down/rate-limited sein koennen.
          const pipedHosts = [
            'https://pipedapi.kavin.rocks',
            'https://pipedapi.adminforge.de',
            'https://api-piped.mha.fi',
          ];
          for (const host of pipedHosts) {
            try {
              const pr = await fetch(
                `${host}/search?q=${encodeURIComponent(q)}&filter=videos`,
                {
                  headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' },
                  signal: AbortSignal.timeout(7000),
                }
              );
              if (!pr.ok) continue;
              const pd = await pr.json();
              videos = (pd.items || [])
                .filter((i) => i.url && i.url.startsWith('/watch?v='))
                .slice(0, maxResults)
                .map((i) => {
                  const vid = i.url.replace('/watch?v=', '').split('&')[0];
                  return {
                    video_id: vid,
                    title: i.title || '',
                    thumbnail_url:
                      i.thumbnail ||
                      `https://img.youtube.com/vi/${vid}/mqdefault.jpg`,
                    channel_title: i.uploaderName || null,
                  };
                })
                .filter((v) => v.video_id.length > 0);
              if (videos.length > 0) break;
            } catch (_) { /* naechster Spiegel */ }
          }

          // 2) Fallback: YouTube Data API v3 (falls Key gesetzt + Piped leer).
          if (videos.length === 0 && env.YOUTUBE_API_KEY) {
            try {
              const apiRes = await fetch(
                'https://www.googleapis.com/youtube/v3/search' +
                `?part=snippet&type=video&q=${encodeURIComponent(q)}` +
                `&maxResults=${maxResults}&key=${env.YOUTUBE_API_KEY}`,
                { signal: AbortSignal.timeout(8000) }
              );
              if (apiRes.ok) {
                const apiData = await apiRes.json();
                videos = (apiData.items || []).map((item) => ({
                  video_id: item.id.videoId,
                  title: item.snippet.title,
                  thumbnail_url:
                    item.snippet.thumbnails?.medium?.url ||
                    item.snippet.thumbnails?.default?.url ||
                    null,
                  channel_title: item.snippet.channelTitle || null,
                }));
              }
            } catch (_) { /* Piped war schon leer -> unten leere Liste */ }
          }

          return jsonResponse({ success: true, videos, query: q });
        } catch (e) {
          return errorResponse(`Suche fehlgeschlagen: ${e.message}`);
        }
      }

      // ── POST /api/admin/videos/ai-suggest  (C1: KI-Video-Vorschlaege) ──
      // Body: { world }. KI erzeugt Suchbegriffe pro Branch, sucht via Piped,
      // liefert passende Kandidaten-Videos (mit Branch-Hinweis).
      if (method === 'POST' && path === '/api/admin/videos/ai-suggest') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Content-Editor-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const branches = WORKSHOP_BRANCHES[world] || [];
          // KI: 5 konkrete YouTube-Suchbegriffe (deutsch) fuer diese Welt.
          let queries = [];
          try {
            const sys = `Du schlaegst YouTube-Suchbegriffe fuer Lern-Videos der Welt "${world}" vor ` +
              `(Themen: ${branches.join(', ')}). Antworte als JSON-Array von 5 praezisen deutschen Suchbegriffen (je 2-5 Worte).`;
            const arr = await aiJson(env, sys, 'Schlage 5 Suchbegriffe vor.', 300);
            queries = (Array.isArray(arr) ? arr : []).map(String).slice(0, 5);
          } catch (_) { queries = branches.slice(0, 5); }

          // Bereits vorhandene Video-IDs (Duplikate vermeiden).
          const existR = await fetch(
            `${SUPABASE_URL}/rest/v1/archive_videos?select=youtube_video_id`,
            { headers: svcHeaders });
          const existIds = new Set(
            (existR.ok ? await existR.json().catch(() => []) : [])
              .map((v) => v.youtube_video_id));

          const pipedHosts = ['https://pipedapi.kavin.rocks', 'https://pipedapi.adminforge.de', 'https://api-piped.mha.fi'];
          // Findet 1 noch nicht vorhandenes Video fuer eine Suche.
          // 1) Piped (kostenlos), 2) YouTube Data API (Fallback wenn Key gesetzt).
          const searchOne = async (q) => {
            for (const host of pipedHosts) {
              try {
                const pr = await fetch(`${host}/search?q=${encodeURIComponent(q)}&filter=videos`,
                  { headers: { 'User-Agent': 'WeltenbibliothekApp/1.0' }, signal: AbortSignal.timeout(7000) });
                if (!pr.ok) continue;
                const pd = await pr.json();
                const items = (pd.items || []).filter((i) => i.url && i.url.startsWith('/watch?v='));
                for (const i of items) {
                  const vid = i.url.replace('/watch?v=', '').split('&')[0];
                  if (vid && !existIds.has(vid)) {
                    return { video_id: vid, title: i.title || '',
                      thumbnail_url: i.thumbnail || `https://img.youtube.com/vi/${vid}/mqdefault.jpg`,
                      channel_title: i.uploaderName || null, query: q };
                  }
                }
              } catch (_) { /* naechster Spiegel */ }
            }
            // YouTube Data API Fallback
            if (env.YOUTUBE_API_KEY) {
              try {
                const yr = await fetch(
                  'https://www.googleapis.com/youtube/v3/search' +
                  `?part=snippet&type=video&q=${encodeURIComponent(q)}&maxResults=5&key=${env.YOUTUBE_API_KEY}`,
                  { signal: AbortSignal.timeout(8000) });
                if (yr.ok) {
                  const yd = await yr.json();
                  for (const it of (yd.items || [])) {
                    const vid = it.id?.videoId;
                    if (vid && !existIds.has(vid)) {
                      return { video_id: vid, title: it.snippet?.title || '',
                        thumbnail_url: it.snippet?.thumbnails?.medium?.url || `https://img.youtube.com/vi/${vid}/mqdefault.jpg`,
                        channel_title: it.snippet?.channelTitle || null, query: q };
                    }
                  }
                }
              } catch (_) { /* leer */ }
            }
            return null;
          };

          const candidates = [];
          for (const q of queries) {
            const found = await searchOne(q);
            if (found) { existIds.add(found.video_id); candidates.push(found); }
          }
          // Diagnose-Hinweis wenn gar nichts gefunden (Piped down + kein YT-Key).
          const note = candidates.length === 0
            ? (env.YOUTUBE_API_KEY ? 'Keine neuen Treffer' : 'Piped nicht erreichbar und kein YOUTUBE_API_KEY gesetzt')
            : null;
          return jsonResponse({ success: true, world, candidates, note });
        } catch (e) { return errorResponse(`Video-KI-Vorschlag-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/videos/batch  (C2: Batch-Freigabe/-Ablehnung) ──
      // Body: { ids: [...], action: 'confirm'|'reject'|'delete' }
      //   oder { action, all_pending: true } -> alle pending-Videos.
      if (method === 'POST' && path === '/api/admin/videos/batch') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Content-Editor-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const action = String(body?.action || '');
          if (!['confirm', 'reject', 'delete'].includes(action)) {
            return errorResponse('action muss confirm|reject|delete sein', 400);
          }
          let ids = Array.isArray(body?.ids) ? body.ids.map(String) : [];
          // all_pending: IDs aller pending-Videos laden.
          if (body?.all_pending === true) {
            const pr = await fetch(
              `${SUPABASE_URL}/rest/v1/archive_videos?status=eq.pending&select=id`,
              { headers: svcHeaders });
            ids = (pr.ok ? await pr.json().catch(() => []) : []).map((v) => v.id);
          }
          if (ids.length === 0) return jsonResponse({ success: true, count: 0 });
          const idList = ids.map(encodeURIComponent).join(',');

          let res;
          if (action === 'delete') {
            res = await fetch(`${SUPABASE_URL}/rest/v1/archive_videos?id=in.(${idList})`,
              { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
          } else {
            const status = action === 'confirm' ? 'confirmed' : 'rejected';
            res = await fetch(`${SUPABASE_URL}/rest/v1/archive_videos?id=in.(${idList})`,
              { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify({ status }) });
          }
          if (!res.ok && res.status !== 204) {
            return errorResponse(`Batch-${action} fehlgeschlagen: ${res.status}`);
          }
          logAudit(svcHeaders, { admin_username: caller.username, action: `video_batch_${action}`, details: { count: ids.length } });
          return jsonResponse({ success: true, count: ids.length, action });
        } catch (e) { return errorResponse(`Batch-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/videos/quality  (C4: KI-Qualitaetscheck) ──
      // Body: { title, channel? } -> { score, verdict, clickbait, reasons }
      if (method === 'POST' && path === '/api/admin/videos/quality') {
        if (!['admin', 'root_admin', 'content_editor', 'moderator'].includes(caller.role)) {
          return errorResponse('Keine Berechtigung', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const title = String(body?.title || '').slice(0, 300);
          const channel = String(body?.channel || '').slice(0, 120);
          if (!title) return errorResponse('title fehlt', 400);
          const sys = [
            'Du bewertest die Serioesitaet eines YouTube-Videos anhand von Titel + Kanal.',
            'Antworte als JSON-Objekt:',
            '{ "score": 0-100 (Serioesitaet/Qualitaet), "verdict": einer aus "serioes"|"unsicher"|"clickbait",',
            '  "clickbait": true|false, "reasons": [ kurze Stichpunkte auf Deutsch, max 4 ] }.',
          ].join('\n');
          const q = await aiJson(env, sys, `Titel: ${title}\nKanal: ${channel || '(unbekannt)'}`, 300);
          return jsonResponse({
            success: true,
            score: Math.max(0, Math.min(100, Math.round(Number(q.score) || 50))),
            verdict: ['serioes', 'unsicher', 'clickbait'].includes((q.verdict || '').toLowerCase()) ? q.verdict.toLowerCase() : 'unsicher',
            clickbait: q.clickbait === true,
            reasons: Array.isArray(q.reasons) ? q.reasons.map(String).slice(0, 4) : [],
          });
        } catch (e) { return errorResponse(`Quality-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/videos  (Liste fuer Admin-Review, alle Status) ──
      // ?world=... &status=pending|confirmed|rejected|all &limit=200
      if (method === 'GET' && path === '/api/admin/videos') {
        try {
          const world = url.searchParams.get('world');
          const status = url.searchParams.get('status') || 'all';
          const limit = Math.min(
            500,
            parseInt(url.searchParams.get('limit') || '200')
          );
          let filter = '';
          if (world && VIDEO_WORLDS.has(world)) {
            filter += `&worlds=cs.{${world}}`;
          }
          if (status !== 'all' && VIDEO_STATUSES.has(status)) {
            filter += `&status=eq.${status}`;
          }
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/archive_videos?select=*${filter}&order=created_at.desc&limit=${limit}`,
            { headers: svcHeaders }
          );
          if (!res.ok) return errorResponse(`Supabase ${res.status}`, res.status);
          const rows = await res.json().catch(() => []);
          return jsonResponse({
            success: true,
            videos: Array.isArray(rows) ? rows : [],
          });
        } catch (e) {
          return errorResponse(`Video-Liste-Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/videos  (Video einpflegen) ────────────────────
      // Body: { youtube_url|youtube_video_id, raw_title?, youtube_title?,
      //         thumbnail_url?, category?, worlds:[...], status? }
      // Fehlende Titel/Thumbnail werden best-effort via oEmbed gefuellt.
      if (method === 'POST' && path === '/api/admin/videos') {
        try {
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}

          const videoId = extractYoutubeId(
            body.youtube_video_id || body.youtube_url
          );
          if (!videoId) {
            return errorResponse(
              'Ungueltige YouTube-URL oder Video-ID',
              400,
              'invalid_youtube_id'
            );
          }

          // Worlds validieren -- mindestens eine gueltige Welt.
          const worlds = Array.isArray(body.worlds)
            ? body.worlds.filter((w) => VIDEO_WORLDS.has(String(w)))
            : [];
          if (worlds.length === 0) {
            return errorResponse(
              'Mindestens eine gueltige Welt erforderlich (materie/energie/vorhang/ursprung)',
              400,
              'invalid_worlds'
            );
          }

          // Status: content_editor darf nur 'pending'/'confirmed' setzen.
          let status = VIDEO_STATUSES.has(body.status) ? body.status : 'pending';
          if (status === 'rejected') status = 'pending';

          // Titel/Thumbnail best-effort aus oEmbed nachladen wenn nicht gesetzt.
          let youtubeTitle = body.youtube_title || null;
          let thumbnailUrl = body.thumbnail_url || null;
          if (!youtubeTitle || !thumbnailUrl) {
            const meta = await fetchYoutubeOembed(videoId);
            if (meta) {
              youtubeTitle = youtubeTitle || meta.title;
              thumbnailUrl = thumbnailUrl || meta.thumbnail_url;
            }
          }
          thumbnailUrl =
            thumbnailUrl ||
            `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`;

          const row = {
            youtube_video_id: videoId,
            raw_title:
              body.raw_title != null
                ? String(body.raw_title).slice(0, 500)
                : youtubeTitle,
            youtube_title: youtubeTitle
              ? String(youtubeTitle).slice(0, 500)
              : null,
            thumbnail_url: thumbnailUrl,
            category: body.category
              ? String(body.category).slice(0, 80)
              : null,
            worlds,
            status,
            created_at: new Date().toISOString(),
          };

          const res = await fetch(`${SUPABASE_URL}/rest/v1/archive_videos`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify(row),
          });
          if (!res.ok) {
            const t = await res.text().catch(() => '');
            return errorResponse(`Insert-Fehler: ${res.status} ${t.slice(0, 200)}`);
          }
          const inserted = await res.json().catch(() => []);
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'video_create',
            target_id: Array.isArray(inserted) ? inserted[0]?.id : null,
            details: { youtube_video_id: videoId, worlds, status },
          });
          return jsonResponse({
            success: true,
            video: Array.isArray(inserted) ? inserted[0] : null,
          });
        } catch (e) {
          return errorResponse(`Video-Insert-Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/videos/:id/confirm  (sichtbar schalten) ───────
      if (
        method === 'POST' &&
        path.startsWith('/api/admin/videos/') &&
        path.endsWith('/confirm')
      ) {
        try {
          const id = path.split('/')[4];
          if (!id) return errorResponse('Video-ID fehlt', 400);
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/archive_videos?id=eq.${encodeURIComponent(id)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify({ status: 'confirmed' }),
            }
          );
          if (!res.ok) return errorResponse(`Confirm-Fehler: ${res.status}`);
          const rows = await res.json().catch(() => []);
          if (!Array.isArray(rows) || rows.length === 0) {
            return errorResponse('Video nicht gefunden', 404);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'video_confirm',
            target_id: id,
          });
          return jsonResponse({ success: true, video: rows[0] });
        } catch (e) {
          return errorResponse(`Confirm-Fehler: ${e.message}`);
        }
      }

      // ── PATCH /api/admin/videos/:id  (Kategorie + Welten nachbearbeiten) ─
      // Body: { category?, worlds?: [...] }. Root-Admin/Content-Editor/Admin
      // koennen ein bereits eingepflegtes Video umkategorisieren oder die
      // Welten-Zuordnung aendern.
      if (
        method === 'PATCH' &&
        path.startsWith('/api/admin/videos/') &&
        path.split('/').length === 5
      ) {
        try {
          const id = path.split('/')[4];
          if (!id) return errorResponse('Video-ID fehlt', 400);
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const patch = {};
          if (body.category !== undefined) {
            patch.category = body.category
              ? String(body.category).slice(0, 80)
              : null;
          }
          if (Array.isArray(body.worlds)) {
            const worlds = body.worlds.filter((w) => VIDEO_WORLDS.has(String(w)));
            if (worlds.length === 0) {
              return errorResponse(
                'Mindestens eine gueltige Welt erforderlich',
                400,
                'invalid_worlds'
              );
            }
            patch.worlds = worlds;
          }
          // C3: Video <-> Modul-Verknuepfung. module_code='' loest die Bindung.
          if (body.module_code !== undefined) {
            const code = String(body.module_code || '').trim().toUpperCase();
            patch.module_code = code || null;
            patch.module_world = code
              ? (VIDEO_WORLDS.has(String(body.module_world)) ? String(body.module_world) : null)
              : null;
          }
          if (Object.keys(patch).length === 0) {
            return errorResponse('Nichts zu aendern (category/worlds/module)', 400);
          }
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/archive_videos?id=eq.${encodeURIComponent(id)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify(patch),
            }
          );
          if (!res.ok) {
            const t = await res.text().catch(() => '');
            return errorResponse(`Update-Fehler: ${res.status} ${t.slice(0, 200)}`);
          }
          const rows = await res.json().catch(() => []);
          if (!Array.isArray(rows) || rows.length === 0) {
            return errorResponse('Video nicht gefunden', 404);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'video_update',
            target_id: id,
            details: patch,
          });
          return jsonResponse({ success: true, video: rows[0] });
        } catch (e) {
          return errorResponse(`Update-Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/videos/:id/reject  (ausblenden, nicht loeschen) ─
      if (
        method === 'POST' &&
        path.startsWith('/api/admin/videos/') &&
        path.endsWith('/reject')
      ) {
        try {
          const id = path.split('/')[4];
          if (!id) return errorResponse('Video-ID fehlt', 400);
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/archive_videos?id=eq.${encodeURIComponent(id)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify({ status: 'rejected' }),
            }
          );
          if (!res.ok) return errorResponse(`Reject-Fehler: ${res.status}`);
          const rows = await res.json().catch(() => []);
          if (!Array.isArray(rows) || rows.length === 0) {
            return errorResponse('Video nicht gefunden', 404);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'video_reject',
            target_id: id,
          });
          return jsonResponse({ success: true, video: rows[0] });
        } catch (e) {
          return errorResponse(`Reject-Fehler: ${e.message}`);
        }
      }

      // ── DELETE /api/admin/videos/:id  (endgueltig entfernen) ──────────
      if (
        method === 'DELETE' &&
        path.startsWith('/api/admin/videos/') &&
        path.split('/').length === 5
      ) {
        try {
          const id = path.split('/')[4];
          if (!id) return errorResponse('Video-ID fehlt', 400);
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/archive_videos?id=eq.${encodeURIComponent(id)}`,
            {
              method: 'DELETE',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            }
          );
          if (!res.ok) return errorResponse(`Delete-Fehler: ${res.status}`);
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'video_delete',
            target_id: id,
          });
          return jsonResponse({ success: true, deleted: id });
        } catch (e) {
          return errorResponse(`Delete-Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/articles  (globale Artikel-Liste fuer Admin) ──
      // ?world=materie|energie|vorhang|ursprung  optional Filter
      // ?status=published|unpublished|all  (default: all)
      // ?limit=100
      if (method === 'GET' && path === '/api/admin/articles') {
        try {
          const world = url.searchParams.get('world');
          const status = url.searchParams.get('status') || 'all';
          const limit = Math.min(200, parseInt(url.searchParams.get('limit') || '100'));
          let filter = '';
          if (world && ['materie','energie','vorhang','ursprung'].includes(world)) {
            filter += `&world=eq.${world}`;
          }
          if (status === 'published') filter += '&is_published=eq.true';
          else if (status === 'unpublished') filter += '&is_published=eq.false';
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/articles?select=id,title,content,world,is_published,is_featured,created_at,updated_at,author_id,profiles(username)${filter}&order=created_at.desc&limit=${limit}`,
            { headers: svcHeaders }
          );
          if (!res.ok) return errorResponse(`Supabase ${res.status}`, res.status);
          const rows = await res.json().catch(() => []);
          return jsonResponse({ success: true, articles: Array.isArray(rows) ? rows : [] });
        } catch (e) { return errorResponse(`articles-Fehler: ${e.message}`); }
      }

      // ── PATCH /api/admin/articles/:id  (Artikel-Felder editieren) ──
      // Body: { title?, content?, excerpt?, is_published?, is_featured? }
      if (method === 'PATCH' && /^\/api\/admin\/articles\/[^/]+$/.test(path)) {
        try {
          const articleId = path.split('/')[4];
          if (!articleId) return errorResponse('articleId fehlt', 400);
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const allowed = ['title', 'content', 'excerpt', 'is_published', 'is_featured'];
          const patch = {};
          for (const k of allowed) {
            if (k in body) patch[k] = body[k];
          }
          if (Object.keys(patch).length === 0) return errorResponse('Keine Felder zum Aktualisieren', 400);
          patch.updated_at = new Date().toISOString();
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/articles?id=eq.${encodeURIComponent(articleId)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify(patch),
            }
          );
          if (!res.ok) {
            const err = await res.text().catch(() => '');
            return errorResponse(`Update fehlgeschlagen: ${err}`, res.status);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'article_edit',
            target_id: articleId,
            details: { fields: Object.keys(patch).filter(k => k !== 'updated_at') },
          });
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`article-PATCH-Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // B3: KI-ARTIKEL-WERKSTATT (2026-06-07)
      //   POST /api/admin/article-workshop/generate { topic, world }
      //   POST /api/admin/article-workshop/expand   { title, content, world }
      //   POST /api/admin/article-workshop/save     { title, content, world, ... }
      // ════════════════════════════════════════════════════════════════
      if (method === 'POST' && path.startsWith('/api/admin/article-workshop/')) {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Content-Editor-Rolle erforderlich', 403);
        }
        const action = path.split('/').pop();
        const worldList = ['materie', 'energie', 'vorhang', 'ursprung'];
        const worldContextMap = {
          materie: 'Recherche, Geopolitik, Wirtschaft, Aufklaerung, kritisches Denken',
          energie: 'Spiritualitaet, Energiearbeit, Meditation, Bewusstsein, Heilung',
          vorhang: 'Machtpsychologie, Manipulation, Strategie, Menschenkenntnis',
          ursprung: 'Bewusstsein, Gateway-Erfahrungen, Manifestation, Remote Viewing',
        };
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = worldList.includes(body?.world) ? body.world : 'materie';

          if (action === 'generate') {
            const topic = String(body?.topic || '').trim();
            if (topic.length < 3) return errorResponse('topic fehlt', 400);
            const system = [
              'Du bist Redakteur der Weltenbibliothek-App.',
              `Thema-Welt: ${world} (${worldContextMap[world]}).`,
              'Schreibe einen fundierten, sachlichen Artikel. Kein Clickbait, keine Floskeln.',
              'Antworte als JSON-Objekt:',
              '{ "title" (max 90 Zeichen), "excerpt" (1-2 Saetze Teaser),',
              '  "content" (600-1200 Worte, Markdown: ## Ueberschriften, **fett**, Listen),',
              '  "category" (1 Wort), "tags" (Array aus 3-6 Schlagworten) }.',
              'Alles auf Deutsch.',
            ].join('\n');
            const a = await aiJson(env, system, `Thema: ${topic}`, 2400);
            return jsonResponse({
              success: true,
              article: {
                title: String(a.title || topic).slice(0, 200),
                excerpt: String(a.excerpt || '').slice(0, 400),
                content: String(a.content || ''),
                category: String(a.category || '').slice(0, 60),
                tags: Array.isArray(a.tags) ? a.tags.map(String).slice(0, 6) : [],
                world,
              },
            });
          }

          if (action === 'expand') {
            const title = String(body?.title || '').trim();
            const content = String(body?.content || '').trim();
            if (!title && !content) return errorResponse('title/content noetig', 400);
            const system = [
              'Du baust einen bestehenden Artikel der Weltenbibliothek substantiell aus.',
              'Vertiefe Argumente, ergaenze Beispiele/Quellenhinweise, behalte Thema + Stil bei.',
              'Antworte als JSON-Objekt: { "title", "excerpt", "content" (Markdown), "category", "tags" (Array) }. Deutsch.',
            ].join('\n');
            const a = await aiJson(env, system, `Titel: ${title}\n\nInhalt:\n${content}`, 2600);
            return jsonResponse({
              success: true,
              article: {
                title: String(a.title || title).slice(0, 200),
                excerpt: String(a.excerpt || '').slice(0, 400),
                content: String(a.content || content),
                category: String(a.category || '').slice(0, 60),
                tags: Array.isArray(a.tags) ? a.tags.map(String).slice(0, 6) : [],
                world,
              },
            });
          }

          if (action === 'save') {
            const title = String(body?.title || '').trim();
            const content = String(body?.content || '').trim();
            if (!title) return errorResponse('title pflicht', 400);
            const editId = body?.edit_id ? String(body.edit_id) : null;
            const isPublished = body?.is_published !== false;
            const category = body?.category ? String(body.category).slice(0, 60) : null;
            const tags = Array.isArray(body?.tags) ? body.tags.map(String).slice(0, 8) : [];
            const excerpt = body?.excerpt ? String(body.excerpt).slice(0, 400) : null;

            if (editId) {
              const patch = { title, content, world, category, tags, updated_at: new Date().toISOString() };
              if (excerpt) patch.excerpt = excerpt;
              const r = await fetch(`${SUPABASE_URL}/rest/v1/articles?id=eq.${encodeURIComponent(editId)}`,
                { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify(patch) });
              if (!r.ok) return errorResponse(`Artikel-Update ${r.status}`, r.status);
              logAudit(svcHeaders, { admin_username: caller.username, action: 'article_ai_update', target_id: editId, details: { world } });
              return jsonResponse({ success: true, action: 'updated', id: editId });
            }

            // Slug aus Titel + kurzer Zufallssuffix (Eindeutigkeit).
            const slug = title.toLowerCase()
              .replace(/[äöüß]/g, (c) => ({ 'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss' }[c]))
              .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60)
              + '-' + Math.random().toString(36).slice(2, 7);
            const row = {
              title, slug, content, world,
              username: caller.username || 'Redaktion',
              category, tags,
              is_published: isPublished,
              published_at: isPublished ? new Date().toISOString() : null,
            };
            const r = await fetch(`${SUPABASE_URL}/rest/v1/articles`,
              { method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=representation' }, body: JSON.stringify(row) });
            if (!r.ok) { const t = await r.text().catch(() => ''); return errorResponse(`Artikel-Insert ${r.status}: ${t.slice(0, 200)}`, r.status); }
            const created = await r.json().catch(() => []);
            logAudit(svcHeaders, { admin_username: caller.username, action: 'article_ai_create', target_id: created?.[0]?.id, details: { world, slug } });
            return jsonResponse({ success: true, action: 'created', id: created?.[0]?.id, slug });
          }

          return errorResponse('Unbekannte Aktion', 404);
        } catch (e) { return errorResponse(`article-workshop ${action} Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/push/stats  (Zustellstatistiken notification_queue) ──
      if (method === 'GET' && path === '/api/admin/push/stats') {
        try {
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
          const svcH = { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}`, 'Prefer': 'count=exact' };
          const [sentRes, failedRes, pendingRes] = await Promise.all([
            fetch(`${SUPABASE_URL}/rest/v1/notification_queue?status=eq.sent&select=id`, { headers: svcH }),
            fetch(`${SUPABASE_URL}/rest/v1/notification_queue?status=eq.failed&select=id`, { headers: svcH }),
            fetch(`${SUPABASE_URL}/rest/v1/notification_queue?status=eq.pending&select=id`, { headers: svcH }),
          ]);
          const getCount = (res) => {
            const h = res.headers.get('content-range');
            if (h) { const m = h.match(/\/(\d+)/); if (m) return parseInt(m[1]); }
            return 0;
          };
          const since7d = new Date(Date.now() - 7 * 86400000).toISOString();
          const recentRes = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue?created_at=gte.${since7d}&select=status,created_at`,
            { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
          );
          const recentRows = recentRes.ok ? await recentRes.json().catch(() => []) : [];
          const byDay = {};
          for (const r of (Array.isArray(recentRows) ? recentRows : [])) {
            const d = (r.created_at || '').substring(0, 10);
            if (!d) continue;
            byDay[d] = byDay[d] || { sent: 0, failed: 0, pending: 0 };
            byDay[d][r.status] = (byDay[d][r.status] || 0) + 1;
          }
          const daily = [];
          for (let i = 6; i >= 0; i--) {
            const d = new Date(Date.now() - i * 86400000).toISOString().substring(0, 10);
            daily.push({ date: d, ...(byDay[d] || { sent: 0, failed: 0, pending: 0 }) });
          }
          // 2026-06-07: FCM-Konfigurationsstatus mitliefern, damit das
          // Dashboard sofort sieht ob echte Pushes ueberhaupt rausgehen
          // koennen. 'ok' = Secret valide, 'invalid' = gesetzt aber
          // fehlerhaft (haeufigste Ursache fuer "Push kommt nicht an"),
          // 'missing' = kein Secret (nur In-App-Polling).
          let fcmStatus = 'missing';
          let fcmError = null;
          try {
            const tok = await getFcmAccessToken(env);
            fcmStatus = tok ? 'ok' : 'missing';
          } catch (e) {
            fcmStatus = 'invalid';
            fcmError = e.message;
          }
          // Geraete-Zahl (ohne Tokens kann kein Push zugestellt werden).
          let deviceCount = 0;
          try {
            const devRes = await fetch(
              `${SUPABASE_URL}/rest/v1/user_devices?fcm_token=not.is.null&select=id`,
              { headers: svcH });
            deviceCount = getCount(devRes);
          } catch (_) {}
          return jsonResponse({
            success: true,
            total_sent: getCount(sentRes),
            total_failed: getCount(failedRes),
            total_pending: getCount(pendingRes),
            fcm_status: fcmStatus,
            fcm_error: fcmError,
            registered_devices: deviceCount,
            daily,
          });
        } catch (e) { return errorResponse(`push-stats-Fehler: ${e.message}`); }
      }

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

      // ── POST /api/admin/push/broadcast  (Admin sendet Push an Zielgruppe) ──
      // Body: { target: 'all'|'materie'|'energie'|'user', userId?, title, body, deeplink? }
      // Enqueued Notifications in notification_queue für alle Empfänger,
      // Cron-Dispatcher drained sie via FCM innerhalb von max. 5 Min.
      if (method === 'POST' && path === '/api/admin/push/broadcast') {
        try {
          const anonKey = env.SUPABASE_ANON_KEY || '';
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;
          const svcH = { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` };
          const body = await request.json();
          const target = (body.target || 'all').toString();
          const title = (body.title || '').toString().trim();
          const msgBody = (body.body || '').toString().trim();
          const deeplink = (body.deeplink || '').toString();
          if (!title || !msgBody) return errorResponse('title und body sind pflicht', 400);

          // Empfänger-Liste aus profiles holen.
          // world_preference-Spalte existiert nicht -> nur world filtern.
          // v103 Phase 4e: 'admins' und 'active' als neue Targets.
          let filter = '';
          if (target === 'materie' || target === 'energie' || target === 'vorhang' || target === 'ursprung') {
            filter = `&world=eq.${target}`;
          } else if (target === 'user' && body.userId) {
            filter = `&id=eq.${body.userId}`;
          } else if (target === 'admins') {
            // Alle Admin-Rollen
            filter = `&role=in.(admin,root_admin,root-admin,moderator,content_editor)`;
          } else if (target === 'active') {
            // Aktive User: last_seen_at in den letzten 7 Tagen
            const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 3600 * 1000).toISOString();
            filter = `&last_seen_at=gte.${sevenDaysAgo}`;
          }
          // AUDIT-FIX 2026-06-07: auch legacy_user_id mitziehen, damit
          // InvisibleAuth-User (Geraet unter legacy_user_id registriert)
          // den Broadcast erhalten. Der Dispatcher matcht beide Identitaeten.
          const recRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,legacy_user_id${filter}&limit=5000`,
            { headers: svcH }
          );
          if (!recRes.ok) return errorResponse(`Empfänger-Fetch ${recRes.status}`);
          const recipients = await recRes.json().catch(() => []);
          const valid = (Array.isArray(recipients) ? recipients : [])
            .filter(r => r.id && !r.id.startsWith('00000000-'));
          if (valid.length === 0) {
            return jsonResponse({ success: true, enqueued: 0, target, note: 'keine Empfänger' });
          }

          // Bulk-Insert in notification_queue (data.type=admin_broadcast damit
          // der Client-Pref-Filter + Realtime greift).
          const now = new Date().toISOString();
          const rows = valid.map(r => ({
            user_id: r.id,
            legacy_user_id: r.legacy_user_id || null,
            title,
            body: msgBody,
            data: deeplink
              ? { deeplink, type: 'admin_broadcast', source: 'admin_broadcast' }
              : { type: 'admin_broadcast', source: 'admin_broadcast' },
            status: 'pending',
            created_at: now,
          }));
          const userIds = valid.map(r => r.id);
          const insRes = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue`,
            { method: 'POST', headers: { ...svcH, 'Prefer': 'return=minimal' }, body: JSON.stringify(rows) }
          );
          if (!insRes.ok) {
            const txt = await insRes.text().catch(() => '');
            return errorResponse(`Enqueue ${insRes.status}: ${txt.substring(0, 200)}`);
          }
          return jsonResponse({ success: true, enqueued: userIds.length, target });
        } catch (e) { return errorResponse(`Broadcast-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/push/history  (Verlauf/Statistik leeren, Admin+) ──
      // ?scope=broadcast (default) -> nur admin_broadcast-Eintraege
      // ?scope=failed            -> alle fehlgeschlagenen Queue-Zeilen
      //                             (raeumt den "Push-Fehler"-Zaehler im Dashboard)
      // ?scope=pending           -> alle ausstehenden Queue-Zeilen
      //                             (raeumt den "Ausstehend"-Zaehler, z.B. stuck-Backlog)
      // ?scope=all               -> alle erledigten (sent+failed) Queue-Zeilen
      // ?scope=everything        -> ALLE Queue-Zeilen (sent+failed+pending) - Voll-Reset
      if (method === 'DELETE' && path === '/api/admin/push/history') {
        try {
          if (!['admin', 'root_admin'].includes(caller.role)) {
            return errorResponse('Keine Berechtigung', 403);
          }
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
          const svcH = { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` };
          const scope = url.searchParams.get('scope') || 'broadcast';
          let filter;
          if (scope === 'failed') {
            filter = 'status=eq.failed';
          } else if (scope === 'pending') {
            filter = 'status=eq.pending';
          } else if (scope === 'all') {
            filter = 'status=in.(sent,failed)';
          } else if (scope === 'everything') {
            // Voll-Reset: alle Zeilen. PostgREST verlangt einen Filter -> id!=null
            // matched alle Zeilen (id ist NOT NULL).
            filter = 'id=not.is.null';
          } else {
            filter = 'data->>source=eq.admin_broadcast';
          }
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue?${filter}`,
            { method: 'DELETE', headers: svcH },
          );
          if (!res.ok && res.status !== 204) {
            return errorResponse(`Loeschen fehlgeschlagen: ${res.status}`);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'push_history_clear',
            details: { scope },
          });
          return jsonResponse({ success: true, scope });
        } catch (e) { return errorResponse(`History-Delete-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/push/history  (letzte 50 broadcast-Aktionen) ──
      if (method === 'GET' && path === '/api/admin/push/history') {
        try {
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
          const svcH = { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` };
          // Group by title+body+created_at-minute → broadcast-aggregierter View
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/notification_queue?select=title,body,created_at,status&data->>source=eq.admin_broadcast&order=created_at.desc&limit=500`,
            { headers: svcH }
          );
          if (!res.ok) return errorResponse(`History ${res.status}`);
          const all = await res.json().catch(() => []);
          // Aggregate by (title, body, created_at[:16]) → 1 broadcast pro Minute
          const groups = new Map();
          for (const r of (Array.isArray(all) ? all : [])) {
            const key = `${r.title}|${r.body}|${(r.created_at || '').substring(0, 16)}`;
            if (!groups.has(key)) {
              groups.set(key, { title: r.title, body: r.body, created_at: r.created_at, sent: 0, failed: 0, pending: 0 });
            }
            const g = groups.get(key);
            const s = (r.status || 'pending');
            if (s === 'sent') g.sent++;
            else if (s === 'failed') g.failed++;
            else g.pending++;
          }
          const list = Array.from(groups.values()).slice(0, 50);
          return jsonResponse({ success: true, broadcasts: list });
        } catch (e) { return errorResponse(`History-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/users  (ALLE Welten · für Admin-Dashboard) ──
      // SERVICE_ROLE_KEY umgeht RLS — Client kann sonst keine fremden
      // Profile sehen. Inkl. last_seen_at + world, gefiltert
      // System-Profile (id 00000000-...) raus.
      // world_preference-Spalte wurde aus dem Schema entfernt — robustly
      // versuche zuerst mit, dann ohne (Fallback bei 42703 column not exist).
      if (method === 'GET' && path === '/api/admin/users') {
        try {
          // v95: Kein Anon-Fallback mehr -- ohne SERVICE_ROLE_KEY wuerde der
          // Endpoint via RLS nur die eigene Profile-Zeile zurueckgeben oder
          // (schlimmer) gar nichts. Lieber explizit 503 statt geheime
          // User-Liste mit anonymem Token zu exponieren.
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY;
          if (!serviceKey) {
            return errorResponse(
              'SUPABASE_SERVICE_ROLE_KEY fehlt -- Admin-User-Endpoint deaktiviert. ' +
              'Service-Role-Secret muss via wrangler secret put gesetzt werden.',
              503,
            );
          }
          // v5.44.7: legacy_user_id (v91) + xp dazu, damit InvisibleAuth-User
          // korrekt erscheinen + Admin XP-Statistik sieht.
          // v123: shadow_banned + muted_until fuer neue Moderation-Features.
          const baseCols = ['id','username','display_name','role','is_banned','avatar_url','avatar_emoji','created_at'];
          // world_preference existiert nicht (entfernt) -> nicht mehr anfragen.
          // xp existiert ab v128. Restliche optionalCols bleiben fuer den
          // 42703-Fallback-Loop defensiv erhalten.
          // v123: shadow_banned + muted_until fuer Moderation-Features.
          const optionalCols = ['world','last_seen_at','legacy_user_id','xp','full_name','shadow_banned','muted_until'];
          // Versuche zuerst mit allen Spalten, droppe optional bei 42703.
          let cols = [...baseCols, ...optionalCols];
          let res;
          // v5.44.7: Pagination via Range-Header, weil Supabase REST per
          // Default max 1000 Rows liefert - 'limit' alleine reicht nicht.
          // Wir holen bis zu 5000 Rows in einer Anfrage.
          for (let attempt = 0; attempt < optionalCols.length + 2; attempt++) {
            res = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?select=${cols.join(',')}&order=created_at.desc&limit=5000`,
              { headers: {
                  'Content-Type': 'application/json',
                  'apikey': serviceKey,
                  'Authorization': `Bearer ${serviceKey}`,
                  'Range-Unit': 'items',
                  'Range': '0-4999',
                  'Prefer': 'count=exact',
                } }
            );
            if (res.ok) break;
            const txt = await res.text().catch(() => '');
            // 42703 = undefined_column → droppe die im Fehler genannte Optional-Spalte
            if (txt.includes('42703')) {
              const dropped = optionalCols.find(c => txt.includes(c) && cols.includes(c));
              if (dropped) {
                cols = cols.filter(c => c !== dropped);
                continue;
              }
            }
            return errorResponse(`Supabase ${res.status}: ${txt.substring(0, 200)}`);
          }
          if (!res || !res.ok) return errorResponse('Supabase: alle Fallbacks gescheitert');
          const totalHeader = res.headers.get('Content-Range') || '';
          const all = await res.json().catch(() => []);
          const list = Array.isArray(all) ? all : [];

          // v115 (Feature B): Verwarnungs-Counts pro User aggregieren --
          // eine einzige Query statt N. Wird ins User-Tile als Badge gezeigt.
          const warnCounts = {};
          try {
            const wRes = await fetch(
              `${SUPABASE_URL}/rest/v1/admin_warnings?select=user_id&limit=5000`,
              { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } },
            );
            if (wRes.ok) {
              const wRows = await wRes.json().catch(() => []);
              for (const w of (Array.isArray(wRows) ? wRows : [])) {
                if (w.user_id) warnCounts[w.user_id] = (warnCounts[w.user_id] || 0) + 1;
              }
            }
          } catch (_) { /* best-effort, Counts sind optional */ }

          // v5.44.7 KEINE Filterung mehr nach role='system' weil das echte
          // User mit administrativen Rollen ausschloss. NUR System-Profile
          // (id 00000000-...) bleiben gefiltert.
          // v117: 'source' wird server-seitig bestimmt -- legacy_user_id
          // vorhanden = App (InvisibleAuth), sonst = Web (Supabase-Auth).
          // Frueher riet der Client anhand der id-Form, aber profiles.id ist
          // IMMER eine UUID -> dadurch wurde JEDER als 'web' angezeigt.
          const filtered = list
            .filter(u => !(u.id || '').startsWith('00000000-'))
            .map(u => ({
              profile_id: u.id,
              user_id: u.id,
              legacy_user_id: u.legacy_user_id || null,
              username: u.username || '(ohne Username)',
              display_name: u.display_name || u.full_name || '',
              role: u.role || 'user',
              is_banned: u.is_banned || false,
              avatar_url: u.avatar_url,
              avatar_emoji: u.avatar_emoji || null,
              created_at: u.created_at || '',
              world: u.world || null,
              last_seen_at: u.last_seen_at || null,
              xp: u.xp || 0,
              full_name: u.full_name || null,
              warning_count: warnCounts[u.id] || 0,
              source: (u.legacy_user_id && String(u.legacy_user_id).length > 0)
                ? 'app' : 'web',
              shadow_banned: u.shadow_banned || false,
              muted_until: u.muted_until || null,
              // v123: Bot-suspect heuristic: account < 24h AND warning_count > 0
              is_bot_suspect: (() => {
                if (!u.created_at) return false;
                const ageSec = (Date.now() - new Date(u.created_at).getTime()) / 1000;
                return ageSec < 86400 && (warnCounts[u.id] || 0) > 0;
              })(),
            }));

          // v117: Genehmigte Web-Zugangs-Antraege (web_access_requests) als
          // Web-User mit anzeigen. Diese registrieren sich ueber die Web-App
          // und haben (noch) keine profiles-Zeile -> tauchten bisher gar
          // nicht im Dashboard auf. is_web_only=true markiert sie, damit die
          // UI weiss dass User-Aktionen (Ban/Delete) hier nicht greifen.
          let webUsers = [];
          try {
            const profileUsernames = new Set(
              list.map(u => (u.username || '').toLowerCase()).filter(Boolean));
            const webRes = await fetch(
              `${SUPABASE_URL}/rest/v1/web_access_requests?status=eq.approved` +
                `&select=id,display_name,requested_at,last_login_at&order=requested_at.desc&limit=1000`,
              { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } });
            if (webRes.ok) {
              const webRows = await webRes.json().catch(() => []);
              webUsers = (Array.isArray(webRows) ? webRows : [])
                // Wer schon ein echtes Profil mit gleichem Namen hat, nicht doppeln.
                .filter(w => !profileUsernames.has((w.display_name || '').toLowerCase()))
                .map(w => ({
                  profile_id: w.id,
                  user_id: w.id,
                  legacy_user_id: null,
                  username: w.display_name || '(Web-User)',
                  display_name: w.display_name || '',
                  role: 'user',
                  is_banned: false,
                  avatar_url: null,
                  avatar_emoji: null,
                  created_at: w.requested_at || '',
                  world: null,
                  last_seen_at: w.last_login_at || null,
                  xp: 0,
                  full_name: null,
                  warning_count: 0,
                  source: 'web',
                  is_web_only: true,
                }));
            }
          } catch (_) { /* best-effort */ }

          const merged = [...filtered, ...webUsers];
          return jsonResponse({
            success: true,
            users: merged,
            total: merged.length,
            total_in_db: totalHeader,
            debug: {
              loaded: list.length,
              profiles: filtered.length,
              web_only: webUsers.length,
              app: filtered.filter(u => u.source === 'app').length,
              web: filtered.filter(u => u.source === 'web').length,
            },
          });
        } catch (e) { return errorResponse(`Users-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/users/:world ─────────────────────────
      // v115: Regex anchored auf genau EIN Segment nach /users/ damit
      // Sub-Routen wie /users/:id/warnings|notes|status NICHT faelschlich
      // hier landen (die werden weiter unten spezifisch behandelt).
      if (method === 'GET' && /^\/api\/admin\/users\/[^/]+\/?$/.test(path) && !path.includes('/status')) {
        try {
          const world = path.split('/')[4];
          const anonKey = env.SUPABASE_ANON_KEY || '';
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || anonKey;
          // world_preference-Spalte existiert nicht -> nur nach world filtern.
          // (Frueher zweiter Request gegen world_preference schlug bei jedem
          //  Dashboard-Load mit 42703 fehl und kostete einen Worker-Subrequest.)
          const res1 = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,username,display_name,full_name,role,is_banned,avatar_url,avatar_emoji,created_at,legacy_user_id,last_seen_at&world=eq.${world}&order=created_at.desc&limit=5000`,  // avatar_emoji now exists after migration v14
            { headers: { 'Content-Type': 'application/json', 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
          );
          const data1 = await res1.json().catch(() => []);
          // Deduplicate by id
          const allProfiles = [...(Array.isArray(data1) ? data1 : [])];
          const seen = new Set();
          const unique = allProfiles.filter(u => { if (seen.has(u.id)) return false; seen.add(u.id); return true; });
          const users = unique.map(u => ({
            profile_id: u.id, user_id: u.id,
            legacy_user_id: u.legacy_user_id || null,
            username: u.username || '(ohne Username)',
            display_name: u.display_name || u.full_name || '',
            full_name: u.full_name || null,
            role: u.role || 'user', is_banned: u.is_banned || false,
            avatar_url: u.avatar_url, avatar_emoji: u.avatar_emoji || null,
            created_at: u.created_at || '',
            last_seen_at: u.last_seen_at || null,
          }));
          return jsonResponse({ success: true, users, total: users.length });
        } catch (e) { return errorResponse(`Users-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/audit/:world ─────────────────────────
      // Merge-Quelle 1: admin_audit_log (echtes Audit-Log, ab v76).
      // Merge-Quelle 2: chat_messages (edited/deleted) als historisches
      // Aktivitäts-Feed. Beide werden zusammengeführt + nach Zeit sortiert.
      // v100: world='all' -> kein Welt-Filter, alle Eintraege zurueck.
      if (method === 'GET' && path.match(/\/api\/admin\/audit\/\w+/)) {
        try {
          const world = path.split('/')[4];
          const limit = parseInt(url.searchParams.get('limit') || '100', 10);
          const isAllWorlds = world === 'all';
          const auditFilter = isAllWorlds
            ? ''
            : `or=(world.eq.${world},world.is.null)&`;

          const [auditRes, editedRes, deletedRes] = await Promise.all([
            fetch(
              `${SUPABASE_URL}/rest/v1/admin_audit_log?${auditFilter}order=created_at.desc&limit=${limit}`,
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

      // ── DELETE /api/admin/audit/:world ──────────────────────
      // Loescht Audit-/Log-Eintraege. NUR root_admin.
      //   ?id=audit_<uuid>  -> einzelnen Eintrag loeschen
      //   ?all=true         -> alle Eintraege loeschen (world!='all' -> nur
      //                        dieser World + welt-lose Eintraege)
      // edit_/del_-Eintraege stammen aus chat_messages und sind hier nicht
      // loeschbar (nur das echte admin_audit_log).
      if (method === 'DELETE' && path.match(/\/api\/admin\/audit\/\w+/)) {
        try {
          if (caller.role !== 'root_admin') {
            return errorResponse('Nur Root-Admin darf Audit-Logs loeschen', 403, 'insufficient_privilege');
          }
          const world = path.split('/')[4];
          const rawId = url.searchParams.get('id');
          const clearAll = url.searchParams.get('all') === 'true';

          if (rawId) {
            // Prefix 'audit_' entfernen -> echte admin_audit_log.id.
            const realId = rawId.startsWith('audit_') ? rawId.slice(6) : rawId;
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/admin_audit_log?id=eq.${encodeURIComponent(realId)}`,
              { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
            if (!r.ok) {
              const t = await r.text().catch(() => '');
              return errorResponse(`Audit-Delete-Fehler: ${r.status} ${t.slice(0, 200)}`);
            }
            logAudit(svcHeaders, { admin_username: caller.username, action: 'audit_delete_one', target_id: realId, details: {} });
            return jsonResponse({ success: true, action: 'deleted', id: realId });
          }

          if (clearAll) {
            const isAllWorlds = world === 'all';
            const filter = isAllWorlds
              ? 'id=not.is.null'
              : `or=(world.eq.${encodeURIComponent(world)},world.is.null)`;
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/admin_audit_log?${filter}`,
              { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
            if (!r.ok) {
              const t = await r.text().catch(() => '');
              return errorResponse(`Audit-Clear-Fehler: ${r.status} ${t.slice(0, 200)}`);
            }
            return jsonResponse({ success: true, action: 'cleared', world });
          }

          return errorResponse('id oder all=true erforderlich', 400);
        } catch (e) { return errorResponse(`Audit-Delete-Fehler: ${e.message}`); }
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

      // ── GET /api/admin/reports ──────────────────────────────
      // Liste user_reports (filterbar via ?status=open|reviewing|resolved|dismissed
      // und ?type=bug|content|feedback|voice).
      if (method === 'GET' && path === '/api/admin/reports') {
        try {
          const status = url.searchParams.get('status');
          const type = url.searchParams.get('type');
          const limit = Math.max(1, Math.min(200, parseInt(url.searchParams.get('limit') || '50')));
          let q = `${SUPABASE_URL}/rest/v1/user_reports?select=*&order=created_at.desc&limit=${limit}`;
          if (status && status !== 'all') q += `&status=eq.${encodeURIComponent(status)}`;
          if (type && type !== 'all') q += `&type=eq.${encodeURIComponent(type)}`;
          const r = await fetch(q, { headers: svcHeaders });
          if (!r.ok) {
            const txt = await r.text().catch(() => '');
            return errorResponse(`Supabase ${r.status}: ${txt.substring(0, 200)}`);
          }
          const rows = await r.json().catch(() => []);

          // Counts pro Status für Filter-Badges
          const countsRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_reports?select=status,type&limit=2000`,
            { headers: svcHeaders }
          );
          const allRows = countsRes.ok ? (await countsRes.json().catch(() => [])) : [];
          const counts = { open: 0, reviewing: 0, resolved: 0, dismissed: 0 };
          const byType = { bug: 0, content: 0, feedback: 0, voice: 0 };
          for (const x of allRows) {
            if (counts[x.status] != null) counts[x.status]++;
            if (byType[x.type] != null) byType[x.type]++;
          }
          return jsonResponse({ success: true, reports: rows, counts, by_type: byType });
        } catch (e) { return errorResponse(`Reports-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/reports/triage  (B2: KI-Moderation, 2026-06-07) ──
      // Body: { title, body?, type? }  -> klassifiziert eine Meldung.
      // Returns: { severity, action, summary }.
      if (method === 'POST' && path === '/api/admin/reports/triage') {
        try {
          if (!['admin', 'root_admin', 'moderator'].includes(caller.role)) {
            return errorResponse('Keine Berechtigung', 403);
          }
          const body = await request.json().catch(() => ({}));
          const title = String(body.title || '').slice(0, 300);
          const text = String(body.body || '').slice(0, 3000);
          const type = String(body.type || 'content');
          if (!title && !text) return errorResponse('title oder body noetig', 400);

          const system = [
            'Du bist Moderations-Assistent einer Community-App. Klassifiziere eine Nutzer-Meldung.',
            'Antworte als JSON-Objekt:',
            '{',
            '  "severity": einer aus "niedrig"|"mittel"|"hoch"|"kritisch",',
            '  "action": kurzer konkreter Handlungsvorschlag fuer den Moderator (1 Satz, Deutsch),',
            '  "summary": 1-Satz-Zusammenfassung der Meldung (Deutsch)',
            '}.',
            'kritisch = Gewaltandrohung/illegale Inhalte/akute Gefahr. hoch = Hassrede/Belaestigung.',
            'mittel = Spam/Regelverstoss. niedrig = Feedback/Bagatelle.',
          ].join('\n');
          const user = `Meldungstyp: ${type}\nTitel: ${title}\nInhalt: ${text || '(kein Text)'}`;
          const c = await aiJson(env, system, user, 300);
          const sev = ['niedrig', 'mittel', 'hoch', 'kritisch'].includes((c.severity || '').toLowerCase())
            ? c.severity.toLowerCase() : 'mittel';
          return jsonResponse({
            success: true,
            severity: sev,
            action: String(c.action || '').slice(0, 300),
            summary: String(c.summary || '').slice(0, 300),
          });
        } catch (e) { return errorResponse(`Triage-Fehler: ${e.message}`); }
      }

      // ── PATCH /api/admin/reports/:id  (Status setzen + reviewer) ──
      if (method === 'PATCH' && path.startsWith('/api/admin/reports/')) {
        try {
          const reportId = path.split('/')[4];
          if (!reportId) return errorResponse('reportId fehlt', 400);
          const body = await request.json().catch(() => ({}));
          const newStatus = String(body.status || '').trim();
          const note = body.resolution_note ? String(body.resolution_note).slice(0, 500) : null;
          const reviewer = caller.username; // AUDIT-FIX B1: aus verifiziertem Header
          if (!['open','reviewing','resolved','dismissed'].includes(newStatus)) {
            return errorResponse('status invalid', 400);
          }
          const patch = {
            status: newStatus,
            reviewed_by: reviewer,
            reviewed_at: new Date().toISOString(),
          };
          if (note) patch.resolution_note = note;
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/user_reports?id=eq.${encodeURIComponent(reportId)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify(patch),
            }
          );
          if (!r.ok) {
            const txt = await r.text().catch(() => '');
            return errorResponse(`Supabase ${r.status}: ${txt.substring(0, 200)}`);
          }
          // Audit-Log
          fetch(`${SUPABASE_URL}/rest/v1/admin_audit_log`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              admin_username: reviewer,
              action: `report_${newStatus}`,
              target_identity: reportId,
              details: { resolution_note: note },
            }),
          }).catch(() => {});
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`Reports-PATCH-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/reports[/:id]  (Meldungen loeschen) ──
      // Admin + Root-Admin.  /api/admin/reports/:id -> einzeln
      //                      /api/admin/reports?all=true -> alle (opt. ?status=)
      if (method === 'DELETE' && path.startsWith('/api/admin/reports')) {
        try {
          if (!['admin', 'root_admin'].includes(caller.role)) {
            return errorResponse('Admin-Rolle erforderlich um Meldungen zu loeschen', 403, 'insufficient_privilege');
          }
          const parts = path.split('/');
          const reportId = parts[4]; // undefined bei /api/admin/reports
          if (reportId) {
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/user_reports?id=eq.${encodeURIComponent(reportId)}`,
              { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
            if (!r.ok) {
              const t = await r.text().catch(() => '');
              return errorResponse(`Report-Delete-Fehler: ${r.status} ${t.slice(0, 200)}`);
            }
            logAudit(svcHeaders, { admin_username: caller.username, action: 'report_delete_one', target_id: reportId, details: {} });
            return jsonResponse({ success: true, action: 'deleted', id: reportId });
          }
          if (url.searchParams.get('all') === 'true') {
            const status = url.searchParams.get('status');
            const filter = (status && status !== 'all')
              ? `status=eq.${encodeURIComponent(status)}`
              : 'id=not.is.null';
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/user_reports?${filter}`,
              { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
            if (!r.ok) {
              const t = await r.text().catch(() => '');
              return errorResponse(`Reports-Clear-Fehler: ${r.status} ${t.slice(0, 200)}`);
            }
            logAudit(svcHeaders, { admin_username: caller.username, action: 'report_clear', target_id: status || 'all', details: {} });
            return jsonResponse({ success: true, action: 'cleared' });
          }
          return errorResponse('reportId oder all=true erforderlich', 400);
        } catch (e) { return errorResponse(`Report-Delete-Fehler: ${e.message}`); }
      }

      // ── PATCH /api/admin/module/:type/:code  (Modul-Felder editieren) ──
      // type ∈ {vorhang, ursprung}; nur sichere Felder erlaubt.
      if (method === 'PATCH' && path.startsWith('/api/admin/module/')) {
        try {
          const parts = path.split('/');
          const moduleType = parts[4]; // vorhang|ursprung
          const moduleCode = parts[5];
          if (!['vorhang', 'ursprung'].includes(moduleType) || !moduleCode) {
            return errorResponse('Invalid module path', 400);
          }
          const tableName = `${moduleType}_modules`;
          const body = await request.json().catch(() => ({}));
          // Whitelist editierbare Felder
          const allowed = ['title', 'subtitle', 'theory_content', 'case_study',
            'exercise_description', 'exercise_duration_minutes', 'xp_reward',
            'youtube_search_query', 'audio_frequency_hz', 'test_questions'];
          const patch = {};
          for (const k of allowed) {
            if (k in body) patch[k] = body[k];
          }
          if (Object.keys(patch).length === 0) {
            return errorResponse('Keine editierbaren Felder gefunden', 400);
          }
          const reviewer = caller.username; // AUDIT-FIX B1: aus verifiziertem Header
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/${tableName}?module_code=eq.${encodeURIComponent(moduleCode)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify(patch),
            }
          );
          if (!r.ok) {
            const txt = await r.text().catch(() => '');
            return errorResponse(`Supabase ${r.status}: ${txt.substring(0, 200)}`);
          }
          const updated = await r.json().catch(() => []);
          fetch(`${SUPABASE_URL}/rest/v1/admin_audit_log`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              admin_username: reviewer,
              action: 'module_edit',
              target_identity: `${moduleType}:${moduleCode}`,
              details: { fields: Object.keys(patch) },
            }),
          }).catch(() => {});
          return jsonResponse({ success: true, module: Array.isArray(updated) ? updated[0] : updated });
        } catch (e) { return errorResponse(`Module-PATCH-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/module/:type/:code  (volles Modul-Detail) ──
      if (method === 'GET' && path.startsWith('/api/admin/module/')) {
        try {
          const parts = path.split('/');
          const moduleType = parts[4];
          const moduleCode = parts[5];
          if (!['vorhang', 'ursprung'].includes(moduleType) || !moduleCode) {
            return errorResponse('Invalid module path', 400);
          }
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/${moduleType}_modules?module_code=eq.${encodeURIComponent(moduleCode)}&limit=1`,
            { headers: svcHeaders }
          );
          if (!r.ok) return errorResponse(`Supabase ${r.status}`);
          const rows = await r.json().catch(() => []);
          if (rows.length === 0) return errorResponse('Modul nicht gefunden', 404);
          return jsonResponse({ success: true, module: rows[0] });
        } catch (e) { return errorResponse(`Module-GET-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/spirit-stats ─────────────────────────
      // Aggregiert spirit_readings nach Tool: Total, unique-User, last-7d.
      // Optional ?days=30 für anderes Zeitfenster.
      if (method === 'GET' && path === '/api/admin/spirit-stats') {
        try {
          const days = Math.max(1, Math.min(365, parseInt(url.searchParams.get('days') || '7')));
          const since = new Date(Date.now() - days * 86400000).toISOString();

          const fetchReadings = async (extra = '') => {
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/spirit_readings?select=user_id,tool,created_at${extra}&limit=20000`,
              { headers: svcHeaders }
            );
            if (!r.ok) return [];
            return (await r.json().catch(() => [])) || [];
          };

          const [allReadings, recentReadings] = await Promise.all([
            fetchReadings(),
            fetchReadings(`&created_at=gte.${since}`),
          ]);

          const aggregate = (rows) => {
            const byTool = {};
            for (const r of rows) {
              const t = r.tool || 'unknown';
              const e = byTool[t] || { tool: t, total: 0, users: new Set() };
              e.total++;
              if (r.user_id) e.users.add(r.user_id);
              byTool[t] = e;
            }
            return Object.values(byTool)
              .map(e => ({ tool: e.tool, total: e.total, unique_users: e.users.size }))
              .sort((a, b) => b.total - a.total);
          };

          // Pro Tag (für Sparkline der letzten N Tage)
          const perDay = {};
          for (const r of recentReadings) {
            const d = (r.created_at || '').substring(0, 10);
            if (!d) continue;
            perDay[d] = (perDay[d] || 0) + 1;
          }
          const dailyOut = [];
          for (let i = days - 1; i >= 0; i--) {
            const d = new Date(Date.now() - i * 86400000).toISOString().substring(0, 10);
            dailyOut.push({ date: d, count: perDay[d] || 0 });
          }

          const all = aggregate(allReadings);
          const recent = aggregate(recentReadings);
          const totalUsers = new Set(allReadings.map(r => r.user_id).filter(Boolean)).size;

          return jsonResponse({
            success: true,
            window_days: days,
            total_readings: allReadings.length,
            total_users: totalUsers,
            recent_readings: recentReadings.length,
            tools_all: all,
            tools_recent: recent,
            daily: dailyOut,
          });
        } catch (e) { return errorResponse(`Spirit-Stats-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/app-config ─────────────────────────
      // Liest app_config (Update-Konfiguration). Nur root_admin.
      if (method === 'GET' && path === '/api/admin/app-config') {
        if (!caller.isRootAdmin) return errorResponse('Nur Root-Admin', 403);
        try {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/app_config?select=*&order=platform.asc`,
            { headers: svcHeaders }
          );
          if (!res.ok) return errorResponse('Supabase-Fehler', res.status);
          const rows = await res.json().catch(() => []);
          return jsonResponse({ success: true, rows });
        } catch (e) { return errorResponse(`app-config-Fehler: ${e.message}`); }
      }

      // ── PATCH /api/admin/app-config ───────────────────────
      // Aktualisiert app_config-Zeile fuer eine Plattform. Nur root_admin.
      // Body: { platform, latest_version?, min_version?, apk_download_url?,
      //         changelog?, patch_changelog?, release_notes_url? }
      if (method === 'PATCH' && path === '/api/admin/app-config') {
        if (!caller.isRootAdmin) return errorResponse('Nur Root-Admin', 403);
        try {
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const platform = (body.platform || 'android').toLowerCase();
          if (!['android', 'ios'].includes(platform)) {
            return errorResponse('platform muss android oder ios sein', 400);
          }
          const allowed = ['latest_version','min_version','apk_download_url','changelog','patch_changelog','release_notes_url'];
          const updates = {};
          for (const k of allowed) {
            if (k in body && body[k] !== undefined) updates[k] = body[k];
          }
          if (Object.keys(updates).length === 0) {
            return errorResponse('Keine Felder zum Aktualisieren', 400);
          }
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/app_config?platform=eq.${platform}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify(updates),
            }
          );
          if (!res.ok) {
            const err = await res.text().catch(() => 'Fehler');
            return errorResponse(`Update fehlgeschlagen: ${err}`, res.status);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'app_config_update',
            target_id: platform,
            details: updates,
          });
          return jsonResponse({ success: true, platform, updated: updates });
        } catch (e) { return errorResponse(`app-config-Update-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/progress ─────────────────────────────
      // Aggregierte Modul-Fortschritte für Vorhang + Ursprung.
      // Pro Branch: total_modules, users_started, users_completed_all,
      // avg_completion_rate. Pro Modul: started/completed counts.
      // Komplett SERVICE_ROLE, umgeht RLS.
      if (method === 'GET' && path === '/api/admin/progress') {
        try {
          const fetchAll = async (table, cols = 'module_code,exercise_completed,test_passed,completed_at,user_id') => {
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/${table}?select=${cols}&limit=10000`,
              { headers: svcHeaders }
            );
            if (!r.ok) return [];
            return (await r.json().catch(() => [])) || [];
          };
          const fetchModules = async (table) => {
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/${table}?select=module_code,branch,title,subtitle,xp_reward&order=branch_order.asc&limit=200`,
              { headers: svcHeaders }
            );
            if (!r.ok) return [];
            return (await r.json().catch(() => [])) || [];
          };

          const [vorhangMods, ursprungMods, vorhangProg, ursprungProg] = await Promise.all([
            fetchModules('vorhang_modules'),
            fetchModules('ursprung_modules'),
            fetchAll('user_vorhang_progress'),
            fetchAll('user_ursprung_progress'),
          ]);

          const aggregate = (modules, progress) => {
            const byCode = {};
            for (const m of modules) {
              byCode[m.module_code] = {
                code: m.module_code,
                title: m.title || '',
                subtitle: m.subtitle || '',
                branch: m.branch || 'unknown',
                xp_reward: m.xp_reward || 0,
                started: 0,
                completed: 0,
                users_started: new Set(),
                users_completed: new Set(),
              };
            }
            for (const p of progress) {
              const e = byCode[p.module_code];
              if (!e) continue;
              if (p.user_id) e.users_started.add(p.user_id);
              e.started++;
              const done = (p.exercise_completed === true) || (p.test_passed === true) || !!p.completed_at;
              if (done) {
                e.completed++;
                if (p.user_id) e.users_completed.add(p.user_id);
              }
            }
            const modulesOut = Object.values(byCode).map(m => ({
              code: m.code, title: m.title, subtitle: m.subtitle, branch: m.branch,
              xp_reward: m.xp_reward,
              users_started: m.users_started.size,
              users_completed: m.users_completed.size,
              completion_rate: m.users_started.size > 0
                ? Math.round((m.users_completed.size / m.users_started.size) * 100)
                : 0,
            }));
            // Pro Branch aggregieren
            const byBranch = {};
            for (const m of modulesOut) {
              const b = byBranch[m.branch] || { branch: m.branch, modules: 0, users_started: new Set(), users_completed: new Set() };
              b.modules++;
              byBranch[m.branch] = b;
            }
            for (const p of progress) {
              if (!p.user_id) continue;
              const code = p.module_code;
              const mod = byCode[code];
              if (!mod) continue;
              const b = byBranch[mod.branch];
              if (!b) continue;
              b.users_started.add(p.user_id);
              const done = (p.exercise_completed === true) || (p.test_passed === true) || !!p.completed_at;
              if (done) b.users_completed.add(p.user_id);
            }
            const branchesOut = Object.values(byBranch).map(b => ({
              branch: b.branch,
              modules: b.modules,
              users_started: b.users_started.size,
              users_completed: b.users_completed.size,
            }));
            // Top + Stuck (Module mit mindestens 3 Startern, sortiert nach Rate)
            const withUsers = modulesOut.filter(m => m.users_started >= 3);
            const top = [...withUsers].sort((a, b) => b.completion_rate - a.completion_rate).slice(0, 8);
            const stuck = [...withUsers].sort((a, b) => a.completion_rate - b.completion_rate).slice(0, 8);
            return { total: modules.length, modules: modulesOut, branches: branchesOut, top, stuck };
          };

          return jsonResponse({
            success: true,
            vorhang: aggregate(vorhangMods, vorhangProg),
            ursprung: aggregate(ursprungMods, ursprungProg),
          });
        } catch (e) { return errorResponse(`Progress-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/users/:userId/detail ─────────────────
      // Aggregiert Profil, Modul-Fortschritt, Warnungen, Admin-Aktionen.
      if (method === 'GET' && /^\/api\/admin\/users\/[^/]+\/detail$/.test(path)) {
        try {
          const rawUserId = path.split('/')[4];
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;

          const [profileRes, progressRes, warningsRes, actionsRes] = await Promise.all([
            fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=*&limit=1`,
              { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/user_vorhang_progress?user_id=eq.${encodeURIComponent(userId)}&select=module_code,completed_at,exercise_completed,test_passed&order=completed_at.desc`,
              { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/admin_warnings?user_id=eq.${encodeURIComponent(userId)}&select=id,reason,created_at,admin_username&order=created_at.desc&limit=10`,
              { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/admin_audit_log?target_identity=eq.${encodeURIComponent(userId)}&select=action,details,created_at,admin_username&order=created_at.desc&limit=10`,
              { headers: svcHeaders }),
          ]);

          const profileData = profileRes.ok ? await profileRes.json().catch(() => []) : [];
          const profile = Array.isArray(profileData) ? profileData[0] || null : null;
          const progress = progressRes.ok ? await progressRes.json().catch(() => []) : [];
          const warnings = warningsRes.ok ? await warningsRes.json().catch(() => []) : [];
          const actions = actionsRes.ok ? await actionsRes.json().catch(() => []) : [];

          if (!profile) return errorResponse('Nutzer nicht gefunden', 404);

          const completedModules = (Array.isArray(progress) ? progress : []).filter(p => p.completed_at).length;
          const startedModules = Array.isArray(progress) ? progress.length : 0;

          return jsonResponse({
            success: true,
            profile,
            progress_summary: {
              started_modules: startedModules,
              completed_modules: completedModules,
              modules: progress,
            },
            warnings: Array.isArray(warnings) ? warnings : [],
            recent_actions: Array.isArray(actions) ? actions : [],
          });
        } catch (e) { return errorResponse(`Detail-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/push/user ───────────────────────────
      // Sendet Push-Benachrichtigung an einen einzelnen Nutzer.
      // Body: { username?, userId?, title, body, type? }
      if (method === 'POST' && path === '/api/admin/push/user') {
        try {
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const title = String(body.title || '').trim();
          const msgBody = String(body.body || '').trim();
          if (!title || !msgBody) return errorResponse('title und body pflicht', 400);

          let userId = body.userId;
          if (!userId && body.username) {
            // 2026-06-07: Suche nach Name ODER Benutzername. Reihenfolge:
            //   1) exakter username (case-insensitiv)
            //   2) exakter display_name / full_name (case-insensitiv)
            //   3) Teiltreffer (ilike) ueber username/display_name/full_name
            const q = String(body.username).trim();
            const enc = encodeURIComponent(q);
            const tryFetch = async (filter) => {
              const r = await fetch(
                `${SUPABASE_URL}/rest/v1/profiles?${filter}&select=id,username,display_name,full_name&limit=2`,
                { headers: svcHeaders });
              return r.ok ? (await r.json().catch(() => [])) : [];
            };
            // 1) exakter username
            let rows = await tryFetch(`username=ilike.${enc}`);
            // 2) exakter Name
            if (rows.length === 0) {
              rows = await tryFetch(`or=(display_name.ilike.${enc},full_name.ilike.${enc})`);
            }
            // 3) Teiltreffer
            if (rows.length === 0) {
              const wild = encodeURIComponent(`*${q}*`);
              rows = await tryFetch(`or=(username.ilike.${wild},display_name.ilike.${wild},full_name.ilike.${wild})`);
            }
            if (Array.isArray(rows) && rows.length > 1) {
              // Mehrdeutig -> Kandidaten zurueckmelden statt blind den ersten zu nehmen.
              const names = rows.map(r => r.username || r.display_name || r.full_name).filter(Boolean);
              return errorResponse(
                `Mehrere Treffer fuer "${q}": ${names.join(', ')}. Bitte praezisieren (@Username).`,
                409, 'ambiguous_recipient');
            }
            userId = Array.isArray(rows) && rows.length > 0 ? rows[0].id : null;
          }
          if (!userId) return errorResponse('Nutzer nicht gefunden (weder Name noch Benutzername)', 404);

          await pushNotif(userId, body.type || 'admin_message', title, msgBody,
            { source: 'admin_direct', admin: caller.username });
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'direct_push',
            target_id: userId,
            details: { title, body: msgBody, username: body.username || userId },
          });
          return jsonResponse({ success: true, userId });
        } catch (e) { return errorResponse(`Push-User-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/users/:userId/status ─────────────────
      if (method === 'GET' && path.includes('/status')) {
        try {
          const userId = path.split('/')[4];
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?select=id,username,role,is_banned&id=eq.${userId}&limit=1`, { headers: svcHeaders });
          const data = await res.json().catch(() => []);
          const p = Array.isArray(data) ? data[0] : {};
          return jsonResponse({ success: true, userId, banned: p?.is_banned || false, muted: false, role: p?.role || 'user' });
        } catch (e) { return jsonResponse({ success: true, userId: '', banned: false, muted: false }); }
      }

      // ── POST /api/admin/promote/:world/:userId ──────────────
      // Body kann { role: 'admin'|'root_admin'|'moderator'|'content_editor' }
      // enthalten. Default 'admin'.
      //
      // AUDIT-FIX A2: Privilege-Hierarchie. Nur Root-Admin darf zu Root-
      // Admin oder Admin promoten. Moderator darf hoechstens content_editor
      // oder moderator promoten. Verhindert Self-Escalation.
      if (method === 'POST' && path.includes('/promote')) {
        try {
          const parts = path.split('/');
          const rawUserId = parts[parts.length - 1];
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const allowed = ['user','moderator','content_editor','admin','root_admin'];
          const targetRole = allowed.includes(body.role) ? body.role : 'admin';

          // Hierarchy-Guard: caller.role muss > targetRole sein.
          // root_admin > admin > moderator/content_editor > user
          const callerLevel = caller.isRootAdmin ? 3 :
                              caller.role === 'admin' ? 2 :
                              (caller.role === 'moderator' || caller.role === 'content_editor') ? 1 : 0;
          const targetLevel = targetRole === 'root_admin' ? 3 :
                              targetRole === 'admin' ? 2 :
                              (targetRole === 'moderator' || targetRole === 'content_editor') ? 1 : 0;
          if (targetLevel >= callerLevel) {
            return errorResponse(
              `Promote zu '${targetRole}' erfordert hoehere Rolle als '${caller.role}'`,
              403, 'insufficient_privilege'
            );
          }

          // AUDIT-FIX B5: Selbst-Promote/Selbst-Demote blockieren
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Promotion ist nicht erlaubt', 403);
          }

          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify({ role: targetRole }),
          });
          if (res.ok) {
            const friendly = targetRole === 'root_admin' ? 'Root-Admin'
              : targetRole === 'admin' ? 'Admin'
              : targetRole === 'moderator' ? 'Moderator'
              : targetRole === 'content_editor' ? 'Content-Editor'
              : 'User';
            await pushNotif(userId, 'system', `🌟 Neue Rolle: ${friendly}`,
              `Ein Administrator hat dich zu ${friendly} befördert.`,
              { type: 'promoted', new_role: targetRole });
            // AUDIT-FIX B1: Audit-Log (v115: korrektes Schema via logAudit)
            logAudit(svcHeaders, {
              admin_username: caller.username,
              action: 'role_promote',
              target_id: userId,
              details: { new_role: targetRole, caller_role: caller.role },
            });
          }
          return jsonResponse({
            success: res.ok,
            new_role: targetRole,
            message: res.ok ? `User zu ${targetRole} befördert` : 'Fehler beim Befördern',
          });
        } catch (e) { return errorResponse(`Promote-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/demote/:world/:userId ───────────────
      // Body kann { role: 'user'|'moderator'|... } enthalten. Default 'user'.
      // AUDIT-FIX A2: Hierarchy-Guard. Niemand darf jemanden auf hoeheres
      // oder gleiches Level demoten als er selbst hat.
      if (method === 'POST' && path.includes('/demote')) {
        try {
          const parts = path.split('/');
          const rawUserId = parts[parts.length - 1];
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const allowed = ['user','moderator','content_editor','admin'];
          const targetRole = allowed.includes(body.role) ? body.role : 'user';

          // Hole aktuelle Rolle des Ziels -- nur jemand mit strikt hoeherer
          // Rolle als das Ziel-Aktuelle darf demoten.
          const tgtRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}&select=role&limit=1`,
            { headers: svcHeaders }
          );
          const tgtRows = tgtRes.ok ? await tgtRes.json().catch(() => []) : [];
          const currentTargetRole = (tgtRows[0]?.role) || 'user';
          const callerLevel = caller.isRootAdmin ? 3 :
                              caller.role === 'admin' ? 2 :
                              (caller.role === 'moderator' || caller.role === 'content_editor') ? 1 : 0;
          const targetCurrentLevel = currentTargetRole === 'root_admin' ? 3 :
                              currentTargetRole === 'admin' ? 2 :
                              (currentTargetRole === 'moderator' || currentTargetRole === 'content_editor') ? 1 : 0;
          if (targetCurrentLevel >= callerLevel) {
            return errorResponse(
              `Demote eines '${currentTargetRole}' erfordert hoehere Rolle als '${caller.role}'`,
              403, 'insufficient_privilege'
            );
          }
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Demote ist nicht erlaubt', 403);
          }
          const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify({ role: targetRole }),
          });
          if (res.ok) {
            await pushNotif(userId, 'system', 'ℹ️ Rollenänderung',
              `Deine Rolle wurde auf ${targetRole} angepasst.`,
              { type: 'demoted', new_role: targetRole });
          }
          return jsonResponse({
            success: res.ok,
            new_role: targetRole,
            message: res.ok ? `Auf ${targetRole} degradiert` : 'Fehler beim Degradieren',
          });
        } catch (e) { return errorResponse(`Demote-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/users/:userId  (Hard-Delete, v98) ─────────
      // Loescht profile-Zeile (cascades zu vielen FKs). Bei vorhandener
      // auth.users-Zeile (UUID id) wird zusaetzlich auth.admin.deleteUser
      // via Service-Role aufgerufen. Fuer reine InvisibleAuth-User reicht
      // der profile-DELETE.
      if (method === 'DELETE' && /^\/api\/admin\/users\/[^/]+\/?$/.test(path)) {
        try {
          if (!env.SUPABASE_SERVICE_ROLE_KEY) {
            return errorResponse('SUPABASE_SERVICE_ROLE_KEY fehlt', 503);
          }
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          // Resolve legacy 'user_*' IDs to the real profiles.id UUID.
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          // Self-delete guard: Root-Admins duerfen sich nicht selbst loeschen.
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Loeschung ist nicht erlaubt', 403, 'self_delete_forbidden');
          }
          const delReason = url.searchParams.get('reason') || null;

          // v117: Vor dem Loeschen Identitaet auf die Blacklist (deleted_identities)
          // schreiben -- verhindert Neuanmeldung mit gleichem Username/Name/
          // Geburtsdatum/-ort. Best-effort; blockiert das Loeschen nicht.
          let blProfile = null;
          try {
            const prof = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}` +
                `&select=username,full_name,birth_date,birth_place,legacy_user_id&limit=1`,
              { headers: svcHeaders });
            const profRows = prof.ok ? await prof.json().catch(() => []) : [];
            blProfile = profRows[0] || null;
          } catch (_) {}
          if (blProfile) {
            const norm = (s) => String(s || '').trim().toLowerCase() || null;
            const ih = await identityHash({
              username: blProfile.username, fullName: blProfile.full_name,
              birthDate: blProfile.birth_date, birthPlace: blProfile.birth_place,
            });
            fetch(`${SUPABASE_URL}/rest/v1/deleted_identities`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
              body: JSON.stringify({
                username_lower: norm(blProfile.username),
                full_name_lower: norm(blProfile.full_name),
                birth_date: blProfile.birth_date || null,
                birth_place_lower: norm(blProfile.birth_place),
                identity_hash: ih,
                original_user_id: blProfile.legacy_user_id || userId,
                deleted_by: caller.username,
                reason: delReason,
                reactivation_status: 'blocked',
              }),
            }).catch(() => {});
          }

          // 1. Profile-Zeile loeschen.
          const delProfile = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
            { method: 'DELETE', headers: svcHeaders },
          );

          // 2. Falls UUID-Form -> auch auth.users loeschen (Service-Role only).
          let authDeleted = false;
          const looksLikeUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);
          if (looksLikeUuid) {
            try {
              const authRes = await fetch(
                `${SUPABASE_URL}/auth/v1/admin/users/${userId}`,
                { method: 'DELETE', headers: {
                    'apikey': env.SUPABASE_SERVICE_ROLE_KEY,
                    'Authorization': `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
                  } },
              );
              authDeleted = authRes.ok;
            } catch (_) { /* auth-delete ist best-effort */ }
          }

          // Audit-Log (v115: korrektes Schema via logAudit)
          // AUDIT-FIX B13: Grund aus Query-Param mit ins Audit-Log.
          {
            logAudit(svcHeaders, {
              admin_username: caller.username,
              action: 'user_hard_delete',
              target_id: userId,
              details: {
                auth_deleted: authDeleted,
                looks_like_uuid: looksLikeUuid,
                reason: delReason,
                blacklisted: !!blProfile,
              },
            });
          }

          return jsonResponse({
            success: delProfile.ok,
            profile_deleted: delProfile.ok,
            auth_deleted: authDeleted,
            user_id: userId,
          });
        } catch (e) { return errorResponse(`Hard-Delete-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/sync  (v98) ───────────────────────────
      // Synchronisiert Profile-Zeilen mit auth.users. Fuer jeden auth.user
      // ohne profile-Eintrag wird einer angelegt. Antwortet mit Statistik.
      // Ausserdem werden anonyme Sessions (InvisibleAuth-Heartbeats die
      // username + legacy_user_id im Body schicken) in profiles upserted.
      if (method === 'POST' && path === '/api/admin/users/sync') {
        try {
          if (!env.SUPABASE_SERVICE_ROLE_KEY) {
            return errorResponse('SUPABASE_SERVICE_ROLE_KEY fehlt', 503);
          }
          const body = await request.json().catch(() => ({}));
          const extraUsers = Array.isArray(body.users) ? body.users : [];

          // 1. Alle auth.users holen (paginiert via admin API).
          let authUsers = [];
          try {
            const authRes = await fetch(
              `${SUPABASE_URL}/auth/v1/admin/users?page=1&per_page=1000`,
              { headers: {
                  'apikey': env.SUPABASE_SERVICE_ROLE_KEY,
                  'Authorization': `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
                } },
            );
            if (authRes.ok) {
              const data = await authRes.json().catch(() => ({}));
              authUsers = Array.isArray(data.users) ? data.users : (data || []);
            }
          } catch (_) { /* falls auth-admin fehlt, weiter mit extraUsers */ }

          // 2. Existierende profile-IDs holen.
          const existRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?select=id,legacy_user_id&limit=10000`,
            { headers: svcHeaders },
          );
          const existing = await existRes.json().catch(() => []);
          const existIds = new Set((Array.isArray(existing) ? existing : []).map(p => p.id));
          const existLegacy = new Set(
            (Array.isArray(existing) ? existing : [])
              .map(p => p.legacy_user_id)
              .filter(Boolean),
          );

          // 3. Fehlende Profile fuer auth.users anlegen.
          const toInsert = [];
          for (const u of authUsers) {
            if (!u || !u.id || existIds.has(u.id)) continue;
            const meta = u.user_metadata || {};
            const baseName = meta.username || meta.display_name ||
                (u.email ? u.email.split('@')[0] : null) || `user_${u.id.slice(0, 8)}`;
            toInsert.push({
              id: u.id,
              username: baseName,
              display_name: meta.display_name || baseName,
              role: 'user',
              is_banned: false,
              created_at: u.created_at || new Date().toISOString(),
              last_seen_at: u.last_sign_in_at || null,
            });
          }

          // 4. Zusaetzlich extraUsers (InvisibleAuth aus Client-Sync) upserten.
          for (const u of extraUsers) {
            if (!u || typeof u !== 'object') continue;
            const legacyId = String(u.legacy_user_id || u.user_id || '').trim();
            const username = String(u.username || '').trim();
            if (!legacyId || !username) continue;
            if (existLegacy.has(legacyId)) continue;
            // InvisibleAuth-Profile: id muss UUID sein. Wir koennen entweder
            // eine ableitbare UUID generieren oder Supabase eine geben lassen.
            // Variante: Insert ohne id -> DB generiert gen_random_uuid().
            toInsert.push({
              username,
              display_name: u.display_name || username,
              role: 'user',
              is_banned: false,
              legacy_user_id: legacyId,
              created_at: new Date().toISOString(),
              last_seen_at: u.last_seen_at || new Date().toISOString(),
            });
          }

          let inserted = 0;
          if (toInsert.length > 0) {
            const insRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal,resolution=ignore-duplicates' },
              body: JSON.stringify(toInsert),
            });
            if (insRes.ok) inserted = toInsert.length;
          }

          return jsonResponse({
            success: true,
            auth_users_seen: authUsers.length,
            extra_users_seen: extraUsers.length,
            profiles_before: existing.length || 0,
            profiles_inserted: inserted,
          });
        } catch (e) {
          return errorResponse(`Sync-Fehler: ${e.message}`);
        }
      }

      // ── DELETE /api/admin/delete/:world/:userId  (Legacy soft-delete) ──
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
      // v98-bugfix: vorher las path.split('/')[5] -> war immer "ban" (action),
      // nicht die userId. Damit PATCH'te der Worker eine nicht existierende
      // Zeile id=eq.ban und Ban schlug silent fehl. Jetzt [4] = userId.
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/ban')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;

          // AUDIT-FIX B14: Rate-Limit -- 30 Bans/min/Admin reicht fuer
          // legitime Bedienung, blockiert Spray-Ban-Attacken.
          const rl = await checkAdminRateLimit(env, caller.userId, 'ban', { perMinute: 30 });
          if (!rl.ok) {
            return errorResponse(
              `Rate-Limit erreicht (${rl.count}/${rl.limit} Bans pro Minute). Bitte warte eine Minute.`,
              429, 'rate_limited'
            );
          }

          // AUDIT-FIX B5: Self-Ban-Guard
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Ban ist nicht erlaubt', 403);
          }

          // AUDIT-FIX A2: Hierarchie -- niemand kann jemanden mit hoeherer
          // oder gleicher Rolle bannen.
          const tgtRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=role,username,is_banned&limit=1`,
            { headers: svcHeaders }
          );
          const tgtRows = tgtRes.ok ? await tgtRes.json().catch(() => []) : [];
          if (tgtRows.length === 0) return errorResponse('User nicht gefunden', 404);
          const targetCurrentRole = tgtRows[0]?.role || 'user';
          const callerLevel = caller.isRootAdmin ? 3 :
                              caller.role === 'admin' ? 2 :
                              (caller.role === 'moderator' || caller.role === 'content_editor') ? 1 : 0;
          const targetLevel = targetCurrentRole === 'root_admin' ? 3 :
                              targetCurrentRole === 'admin' ? 2 :
                              (targetCurrentRole === 'moderator' || targetCurrentRole === 'content_editor') ? 1 : 0;
          if (targetLevel >= callerLevel) {
            return errorResponse(
              `Kann '${targetCurrentRole}' nicht bannen (deine Rolle: '${caller.role}')`,
              403, 'insufficient_privilege'
            );
          }

          // AUDIT-FIX B4: Idempotenz -- wenn schon gebannt, nichts tun
          if (tgtRows[0]?.is_banned === true) {
            return jsonResponse({ success: true, action: 'already_banned', user_id: userId });
          }

          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify({ is_banned: true }),
            },
          );
          if (!res.ok) {
            const t = await res.text().catch(() => '');
            return errorResponse(`Ban-Fehler: ${res.status} ${t.slice(0, 200)}`);
          }
          const updated = await res.json().catch(() => []);
          if (!Array.isArray(updated) || updated.length === 0) {
            return errorResponse('User nicht gefunden', 404);
          }

          // AUDIT-FIX A6: Spiegel-Eintrag in admin_bans (v103-Tabelle) damit
          // Client-App und Worker dasselbe Ban-System nutzen. Best-effort.
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const reason = String(body?.reason || 'Admin-Ban').slice(0, 500);
          const expiresAt = body?.expires_at || null;
          // v115: kein expires_at -> permanenter Ban. Der Cron-Expiry-Scan
          // hebt nur befristete Bans (is_permanent=false) nach Ablauf auf.
          const isPermanent = !expiresAt;
          fetch(`${SUPABASE_URL}/rest/v1/admin_bans`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
            body: JSON.stringify({
              user_id: userId,
              username: updated[0]?.username || null,
              banned_by: caller.username,
              reason,
              is_permanent: isPermanent,
              expires_at: expiresAt,
              created_at: new Date().toISOString(),
            }),
          }).catch(() => {});

          await pushNotif(userId, 'system', '🚫 Konto gesperrt',
            `Dein Konto wurde gesperrt. Grund: ${reason}`,
            { type: 'banned', reason });

          // AUDIT-FIX B1: Audit-Log (v115: korrektes Schema via logAudit)
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'ban',
            target_id: userId,
            target_username: updated[0]?.username || null,
            details: { reason, expires_at: expiresAt },
          });
          return jsonResponse({ success: true, action: 'banned', user_id: userId });
        } catch (e) { return errorResponse(`Ban-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/unban ─────────────────
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/unban')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
            {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=representation' },
              body: JSON.stringify({ is_banned: false }),
            },
          );
          if (!res.ok) {
            const t = await res.text().catch(() => '');
            return errorResponse(`Unban-Fehler: ${res.status} ${t.slice(0, 200)}`);
          }
          const updated = await res.json().catch(() => []);
          if (!Array.isArray(updated) || updated.length === 0) {
            return errorResponse('User nicht gefunden', 404);
          }

          // AUDIT-FIX A6: Ban auch in admin_bans entfernen.
          fetch(`${SUPABASE_URL}/rest/v1/admin_bans?user_id=eq.${encodeURIComponent(userId)}`, {
            method: 'DELETE',
            headers: svcHeaders,
          }).catch(() => {});

          await pushNotif(userId, 'system', '✅ Sperre aufgehoben',
            'Deine Kontosperre wurde von einem Administrator aufgehoben.',
            { type: 'unbanned' });
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'unban',
            target_id: userId,
            target_username: updated[0]?.username || null,
          });
          return jsonResponse({ success: true, action: 'unbanned', user_id: userId });
        } catch (e) { return errorResponse(`Unban-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/mute ──────────────────
      // AUDIT-FIX B2: war ein No-Op-Stub (return success). Jetzt persistent
      // in admin_mutes via v106-Migration. Body: { reason?, duration_h? }
      if (method === 'POST' && path.includes('/mute') && !path.includes('/unmute')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Mute ist nicht erlaubt', 403);
          }
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const reason = String(body?.reason || 'Chat-Mute').slice(0, 500);
          const durationH = Math.max(1, Math.min(8760, Number(body?.duration_h) || 24));
          const expiresAt = new Date(Date.now() + durationH * 3600 * 1000).toISOString();

          fetch(`${SUPABASE_URL}/rest/v1/admin_mutes`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
            body: JSON.stringify({
              user_id: userId,
              muted_by: caller.userId,
              reason,
              expires_at: expiresAt,
              created_at: new Date().toISOString(),
            }),
          }).catch(() => {});

          await pushNotif(userId, 'system', '🔇 Stummgeschaltet',
            `Du wurdest fuer ${durationH}h stummgeschaltet. Grund: ${reason}`,
            { type: 'muted', reason, expires_at: expiresAt });

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'mute',
            target_id: userId,
            details: { reason, duration_h: durationH, expires_at: expiresAt },
          });

          return jsonResponse({ success: true, action: 'muted', user_id: userId, expires_at: expiresAt });
        } catch (e) { return errorResponse(`Mute-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/unmute ────────────────
      if (method === 'POST' && path.includes('/unmute')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          fetch(`${SUPABASE_URL}/rest/v1/admin_mutes?user_id=eq.${encodeURIComponent(userId)}`, {
            method: 'DELETE',
            headers: svcHeaders,
          }).catch(() => {});

          await pushNotif(userId, 'system', '🔊 Stummschaltung aufgehoben',
            'Du kannst wieder im Chat schreiben.',
            { type: 'unmuted' });

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'unmute',
            target_id: userId,
          });

          return jsonResponse({ success: true, action: 'unmuted', user_id: userId });
        } catch (e) { return errorResponse(`Unmute-Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v117 Feature: Granulare, kategorisierte Sperren (user_restrictions)
      // ════════════════════════════════════════════════════════════════
      const RESTRICTION_SCOPES = [
        'chat', 'livestream', 'direct_messages', 'shadow_mute',
        'create_articles', 'create_pins', 'comment', 'earn_xp',
        'spirit_tools', 'research_tools', 'all',
      ];
      const SCOPE_LABELS = {
        chat: 'Chat', livestream: 'Livestream', direct_messages: 'Direktnachrichten',
        shadow_mute: 'Shadow-Mute', create_articles: 'Artikel erstellen',
        create_pins: 'Pins erstellen', comment: 'Kommentieren',
        earn_xp: 'XP verdienen',
        spirit_tools: 'Spirit-Tools', research_tools: 'Recherche-Tools',
        all: 'Vollsperrung',
      };

      // ── GET /api/admin/users/:userId/restrictions ───────────────────
      if (method === 'GET' && path.includes('/users/') && path.endsWith('/restrictions')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/user_restrictions?user_id=eq.${encodeURIComponent(userId)}` +
              `&select=id,scope,reason,is_permanent,expires_at,created_by,created_at&order=created_at.desc`,
            { headers: svcHeaders },
          );
          const rows = res.ok ? await res.json().catch(() => []) : [];
          return jsonResponse({ success: true, restrictions: rows });
        } catch (e) { return errorResponse(`Restrictions-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/restrict ──────────────────────
      // Body: { scopes: string[], reason?, duration_h? }  (duration_h null/0 = permanent)
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/restrict')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Sperre ist nicht erlaubt', 403);
          }
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          let scopes = Array.isArray(body?.scopes) ? body.scopes : [];
          // 'all' impliziert Vollsperre -> nur diesen einen Scope speichern.
          if (scopes.includes('all')) scopes = ['all'];
          scopes = [...new Set(scopes.filter((s) => RESTRICTION_SCOPES.includes(s)))];
          if (scopes.length === 0) return errorResponse('Keine gueltigen scopes angegeben', 400);

          const reason = String(body?.reason || 'Admin-Sperre').slice(0, 500);
          const durationH = Number(body?.duration_h) || 0;
          const isPermanent = durationH <= 0;
          const expiresAt = isPermanent
            ? null
            : new Date(Date.now() + Math.min(8760, durationH) * 3600 * 1000).toISOString();

          // Username fuer Restriction-Match (InvisibleAuth-Chat-Posts) mitspeichern.
          let username = null;
          try {
            const pr = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=username&limit=1`,
              { headers: svcHeaders });
            const prRows = pr.ok ? await pr.json().catch(() => []) : [];
            username = prRows[0]?.username || null;
          } catch (_) {}

          const rowsToUpsert = scopes.map((scope) => ({
            user_id: userId, username, scope, reason,
            created_by: caller.username, is_permanent: isPermanent,
            expires_at: expiresAt, created_at: new Date().toISOString(),
          }));
          const upRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_restrictions?on_conflict=user_id,scope`,
            {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify(rowsToUpsert),
            });
          if (!upRes.ok) {
            const t = await upRes.text().catch(() => '');
            return errorResponse(`Sperr-Fehler: ${upRes.status} ${t.slice(0, 200)}`);
          }

          // 'all' spiegelt sich zusaetzlich in profiles.is_banned + admin_bans
          // (Backwards-Compat mit bestehendem Ban-System / Admin-Gate).
          if (scopes.includes('all')) {
            fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`, {
              method: 'PATCH', headers: svcHeaders,
              body: JSON.stringify({ is_banned: true }),
            }).catch(() => {});
            fetch(`${SUPABASE_URL}/rest/v1/admin_bans?on_conflict=user_id`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify({
                user_id: userId, username, banned_by: caller.username, reason,
                is_permanent: isPermanent, expires_at: expiresAt,
                created_at: new Date().toISOString(),
              }),
            }).catch(() => {});
          }

          const labels = scopes.map((s) => SCOPE_LABELS[s] || s).join(', ');
          const durTxt = isPermanent ? 'dauerhaft' : `fuer ${durationH}h`;
          // Shadow-Mute NICHT dem User mitteilen (sonst kein Shadow mehr).
          if (!(scopes.length === 1 && scopes[0] === 'shadow_mute')) {
            await pushNotif(userId, 'system', '🚫 Bereich gesperrt',
              `Folgende Bereiche wurden ${durTxt} gesperrt: ${labels}. Grund: ${reason}`,
              { type: 'restricted', scopes, reason, expires_at: expiresAt });
          }
          logAudit(svcHeaders, {
            admin_username: caller.username, action: 'restrict', target_id: userId,
            target_username: username, details: { scopes, reason, duration_h: durationH, expires_at: expiresAt },
          });
          return jsonResponse({ success: true, action: 'restricted', user_id: userId, scopes, expires_at: expiresAt });
        } catch (e) { return errorResponse(`Sperr-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/unrestrict ────────────────────
      // Body: { scopes: string[] }  -- leer/['all'] = alle Sperren aufheben
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/unrestrict')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          let scopes = Array.isArray(body?.scopes) ? body.scopes : [];
          scopes = [...new Set(scopes.filter((s) => RESTRICTION_SCOPES.includes(s)))];

          const liftAll = scopes.length === 0 || scopes.includes('all');
          if (liftAll) {
            await fetch(`${SUPABASE_URL}/rest/v1/user_restrictions?user_id=eq.${encodeURIComponent(userId)}`,
              { method: 'DELETE', headers: svcHeaders }).catch(() => {});
            // Vollsperre aufheben -> is_banned zuruecksetzen + admin_bans loeschen.
            fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`, {
              method: 'PATCH', headers: svcHeaders, body: JSON.stringify({ is_banned: false }),
            }).catch(() => {});
            fetch(`${SUPABASE_URL}/rest/v1/admin_bans?user_id=eq.${encodeURIComponent(userId)}`,
              { method: 'DELETE', headers: svcHeaders }).catch(() => {});
          } else {
            const inList = scopes.map((s) => encodeURIComponent(s)).join(',');
            await fetch(
              `${SUPABASE_URL}/rest/v1/user_restrictions?user_id=eq.${encodeURIComponent(userId)}&scope=in.(${inList})`,
              { method: 'DELETE', headers: svcHeaders }).catch(() => {});
          }

          await pushNotif(userId, 'system', '✅ Sperre aufgehoben',
            liftAll ? 'Alle Bereichs-Sperren wurden aufgehoben.'
                    : `Sperre aufgehoben fuer: ${scopes.map((s) => SCOPE_LABELS[s] || s).join(', ')}`,
            { type: 'unrestricted', scopes });
          logAudit(svcHeaders, {
            admin_username: caller.username, action: 'unrestrict', target_id: userId,
            details: { scopes: liftAll ? ['all'] : scopes },
          });
          return jsonResponse({ success: true, action: 'unrestricted', user_id: userId });
        } catch (e) { return errorResponse(`Entsperr-Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v117 Feature: Antrags-Inbox (Reaktivierung / Einspruch / Selbstloesch)
      // ════════════════════════════════════════════════════════════════

      // ── GET /api/admin/account-requests?status=pending ──────────────
      if (method === 'GET' && path === '/api/admin/account-requests') {
        try {
          const status = url.searchParams.get('status') || 'pending';
          const statusFilter = status === 'all' ? '' : `&status=eq.${encodeURIComponent(status)}`;
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/account_requests?select=*${statusFilter}&order=created_at.desc&limit=200`,
            { headers: svcHeaders });
          const rows = res.ok ? await res.json().catch(() => []) : [];
          return jsonResponse({ success: true, requests: rows });
        } catch (e) { return errorResponse(`Antrags-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/account-requests/:id/resolve ────────────────
      // Body: { action: 'approve' | 'reject' }
      if (method === 'POST' && /^\/api\/admin\/account-requests\/[^/]+\/resolve\/?$/.test(path)) {
        try {
          const reqId = path.split('/')[4];
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const action = body?.action === 'approve' ? 'approve' : 'reject';

          const getRes = await fetch(
            `${SUPABASE_URL}/rest/v1/account_requests?id=eq.${encodeURIComponent(reqId)}&select=*&limit=1`,
            { headers: svcHeaders });
          const reqRows = getRes.ok ? await getRes.json().catch(() => []) : [];
          if (reqRows.length === 0) return errorResponse('Antrag nicht gefunden', 404);
          const req = reqRows[0];

          if (action === 'approve') {
            if (req.type === 'reactivation') {
              // Blacklist-Eintrag(e) auf 'approved' setzen -> Neuanmeldung erlaubt.
              const ih = await identityHash({
                username: req.username, fullName: req.full_name,
                birthDate: req.birth_date, birthPlace: req.birth_place });
              const unameLower = String(req.username || '').trim().toLowerCase();
              const ors = [`identity_hash.eq.${encodeURIComponent(ih)}`];
              if (unameLower) ors.push(`username_lower.eq.${encodeURIComponent(unameLower)}`);
              fetch(`${SUPABASE_URL}/rest/v1/deleted_identities?or=(${ors.join(',')})`, {
                method: 'PATCH', headers: svcHeaders,
                body: JSON.stringify({ reactivation_status: 'approved' }),
              }).catch(() => {});
            } else if (req.type === 'appeal' && req.user_id) {
              // Sperre aufheben (gezielter Scope oder alle).
              if (req.restriction_scope && req.restriction_scope !== 'all') {
                fetch(`${SUPABASE_URL}/rest/v1/user_restrictions?user_id=eq.${encodeURIComponent(req.user_id)}&scope=eq.${encodeURIComponent(req.restriction_scope)}`,
                  { method: 'DELETE', headers: svcHeaders }).catch(() => {});
              } else {
                fetch(`${SUPABASE_URL}/rest/v1/user_restrictions?user_id=eq.${encodeURIComponent(req.user_id)}`,
                  { method: 'DELETE', headers: svcHeaders }).catch(() => {});
                fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(req.user_id)}`,
                  { method: 'PATCH', headers: svcHeaders, body: JSON.stringify({ is_banned: false }) }).catch(() => {});
                fetch(`${SUPABASE_URL}/rest/v1/admin_bans?user_id=eq.${encodeURIComponent(req.user_id)}`,
                  { method: 'DELETE', headers: svcHeaders }).catch(() => {});
              }
              await pushNotif(req.user_id, 'system', '✅ Einspruch angenommen',
                'Dein Einspruch wurde angenommen, die Sperre wurde aufgehoben.',
                { type: 'appeal_approved' });
            } else if (req.type === 'self_deletion' && req.user_id) {
              // Eigenes Konto auf Wunsch loeschen (inkl. Blacklist-Eintrag).
              const uid = await resolveProfileUuid(req.user_id, svcHeaders) ?? req.user_id;
              const ih = await identityHash({
                username: req.username, fullName: req.full_name,
                birthDate: req.birth_date, birthPlace: req.birth_place });
              const norm = (s) => String(s || '').trim().toLowerCase() || null;
              fetch(`${SUPABASE_URL}/rest/v1/deleted_identities`, {
                method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
                body: JSON.stringify({
                  username_lower: norm(req.username), full_name_lower: norm(req.full_name),
                  birth_date: req.birth_date || null, birth_place_lower: norm(req.birth_place),
                  identity_hash: ih, original_user_id: req.user_id,
                  deleted_by: caller.username, reason: 'Selbst-Loeschung',
                  reactivation_status: 'blocked',
                }),
              }).catch(() => {});
              fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(uid)}`,
                { method: 'DELETE', headers: svcHeaders }).catch(() => {});
            }
          }

          await fetch(`${SUPABASE_URL}/rest/v1/account_requests?id=eq.${encodeURIComponent(reqId)}`, {
            method: 'PATCH', headers: svcHeaders,
            body: JSON.stringify({
              status: action === 'approve' ? 'approved' : 'rejected',
              handled_by: caller.username, handled_at: new Date().toISOString(),
            }),
          }).catch(() => {});

          logAudit(svcHeaders, {
            admin_username: caller.username, action: `account_request_${action}`,
            target_id: req.user_id || req.username, details: { type: req.type, request_id: reqId },
          });
          return jsonResponse({ success: true, action, type: req.type });
        } catch (e) { return errorResponse(`Antrags-Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/deleted-identities ───────────────────────────
      if (method === 'GET' && path === '/api/admin/deleted-identities') {
        try {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/deleted_identities?select=*&order=deleted_at.desc&limit=200`,
            { headers: svcHeaders });
          const rows = res.ok ? await res.json().catch(() => []) : [];
          return jsonResponse({ success: true, identities: rows });
        } catch (e) { return errorResponse(`Blacklist-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/deleted-identities/:id  (Freigabe) ────────
      if (method === 'DELETE' && /^\/api\/admin\/deleted-identities\/[^/]+\/?$/.test(path)) {
        try {
          const id = path.split('/')[4];
          await fetch(`${SUPABASE_URL}/rest/v1/deleted_identities?id=eq.${encodeURIComponent(id)}`,
            { method: 'DELETE', headers: svcHeaders }).catch(() => {});
          logAudit(svcHeaders, {
            admin_username: caller.username, action: 'blacklist_remove', target_id: id,
          });
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`Blacklist-Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v115 Feature B: Verwarnungssystem (3 Verwarnungen = Auto-Ban)
      // ════════════════════════════════════════════════════════════════

      // ── GET /api/admin/users/:userId/warnings ───────────────────────
      // Liefert alle Verwarnungen eines Users + Count.
      if (method === 'GET' && path.includes('/users/') && path.endsWith('/warnings')) {
        try {
          const userId = path.split('/')[4];
          if (!userId) return errorResponse('userId fehlt', 400);
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_warnings?user_id=eq.${encodeURIComponent(userId)}&select=*&order=created_at.desc&limit=50`,
            { headers: svcHeaders },
          );
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({
            success: true,
            warnings: Array.isArray(rows) ? rows : [],
            count: Array.isArray(rows) ? rows.length : 0,
          });
        } catch (e) { return errorResponse(`Warnings-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/warn ──────────────────────────
      // Body: { reason: string }. Legt eine Verwarnung an. Bei der 3.
      // Verwarnung wird der User automatisch fuer 7 Tage gebannt.
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/warn')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Verwarnung ist nicht erlaubt', 403);
          }
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const reason = String(body?.reason || '').trim().slice(0, 500);
          if (reason.length < 3) {
            return errorResponse('Grund (min. 3 Zeichen) ist Pflicht', 400);
          }

          // Ziel-Username + bisherige Verwarnungen holen.
          const tgtRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=username&limit=1`,
            { headers: svcHeaders },
          );
          const tgtRows = tgtRes.ok ? await tgtRes.json().catch(() => []) : [];
          if (tgtRows.length === 0) return errorResponse('User nicht gefunden', 404);
          const targetUsername = tgtRows[0]?.username || null;

          // Verwarnung anlegen.
          const insRes = await fetch(`${SUPABASE_URL}/rest/v1/admin_warnings`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              user_id: userId,
              username: targetUsername,
              warned_by: caller.username,
              reason,
              created_at: new Date().toISOString(),
            }),
          });
          if (!insRes.ok) {
            const t = await insRes.text().catch(() => '');
            return errorResponse(`Verwarnung-Fehler: ${insRes.status} ${t.slice(0, 200)}`);
          }

          // Aktuelle Anzahl ermitteln (count=exact via Range-Header).
          const cntRes = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_warnings?user_id=eq.${encodeURIComponent(userId)}&select=id`,
            { headers: { ...svcHeaders, 'Prefer': 'count=exact', 'Range': '0-0' } },
          );
          const warnCount = parseInt(
            cntRes.headers.get('content-range')?.split('/')[1] || '1', 10);

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'warning',
            target_id: userId,
            target_username: targetUsername,
            details: { reason, warning_count: warnCount },
          });

          // 3-Strike: ab der 3. Verwarnung Auto-Ban (7 Tage).
          let autoBanned = false;
          if (warnCount >= 3) {
            const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000).toISOString();
            await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
              {
                method: 'PATCH',
                headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
                body: JSON.stringify({ is_banned: true }),
              },
            ).catch(() => {});
            fetch(`${SUPABASE_URL}/rest/v1/admin_bans`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify({
                user_id: userId,
                username: targetUsername,
                banned_by: 'system',
                reason: `Auto-Ban nach ${warnCount} Verwarnungen`,
                is_permanent: false,
                expires_at: expiresAt,
                created_at: new Date().toISOString(),
              }),
            }).catch(() => {});
            autoBanned = true;
            logAudit(svcHeaders, {
              admin_username: 'system',
              action: 'ban',
              target_id: userId,
              target_username: targetUsername,
              details: { reason: `Auto-Ban nach ${warnCount} Verwarnungen`, expires_at: expiresAt, auto: true },
            });
            await pushNotif(userId, 'system', '🚫 Konto gesperrt',
              `Du wurdest nach ${warnCount} Verwarnungen automatisch fuer 7 Tage gesperrt.`,
              { type: 'banned', auto: true });
          } else if (warnCount === 2) {
            // v117 Eskalation: 2. Verwarnung -> automatisch 24h Chat-Sperre.
            const chatExpires = new Date(Date.now() + 24 * 3600 * 1000).toISOString();
            fetch(`${SUPABASE_URL}/rest/v1/user_restrictions?on_conflict=user_id,scope`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify({
                user_id: userId, username: targetUsername, scope: 'chat',
                reason: `Auto-Chatsperre nach ${warnCount} Verwarnungen`,
                created_by: 'system', is_permanent: false,
                expires_at: chatExpires, created_at: new Date().toISOString(),
              }),
            }).catch(() => {});
            await pushNotif(userId, 'system', '⚠️ Verwarnung + Chat-Sperre',
              `Du wurdest verwarnt (${warnCount}/3) und fuer 24h vom Chat gesperrt. Grund: ${reason}`,
              { type: 'warning', count: warnCount, reason, auto_chat_block: true });
          } else {
            await pushNotif(userId, 'system', '⚠️ Verwarnung',
              `Du wurdest verwarnt (${warnCount}/3). Grund: ${reason}`,
              { type: 'warning', count: warnCount, reason });
          }

          return jsonResponse({
            success: true,
            warning_count: warnCount,
            auto_banned: autoBanned,
          });
        } catch (e) { return errorResponse(`Verwarnung-Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v115 Feature C: Interne Admin-Notizen pro User
      // ════════════════════════════════════════════════════════════════

      // ── GET /api/admin/users/:userId/notes ──────────────────────────
      if (method === 'GET' && path.includes('/users/') && path.endsWith('/notes')) {
        try {
          const userId = path.split('/')[4];
          if (!userId) return errorResponse('userId fehlt', 400);
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_user_notes?user_id=eq.${encodeURIComponent(userId)}&select=*&order=created_at.desc&limit=100`,
            { headers: svcHeaders },
          );
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({
            success: true,
            notes: Array.isArray(rows) ? rows : [],
          });
        } catch (e) { return errorResponse(`Notes-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/notes ─────────────────────────
      // Body: { note: string }
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/notes')) {
        try {
          const userId = path.split('/')[4];
          if (!userId) return errorResponse('userId fehlt', 400);
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const note = String(body?.note || '').trim().slice(0, 1000);
          if (note.length < 1) return errorResponse('Notiz darf nicht leer sein', 400);
          const insRes = await fetch(`${SUPABASE_URL}/rest/v1/admin_user_notes`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify({
              user_id: userId,
              note,
              author_username: caller.username,
              created_at: new Date().toISOString(),
            }),
          });
          if (!insRes.ok) {
            const t = await insRes.text().catch(() => '');
            return errorResponse(`Notes-Fehler: ${insRes.status} ${t.slice(0, 200)}`);
          }
          const created = await insRes.json().catch(() => []);
          return jsonResponse({
            success: true,
            note: Array.isArray(created) ? created[0] : created,
          });
        } catch (e) { return errorResponse(`Notes-Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/users/:userId/notes/:noteId ───────────────
      if (method === 'DELETE' && path.includes('/users/') && path.includes('/notes/')) {
        try {
          const parts = path.split('/');
          const noteId = parts[parts.length - 1];
          if (!noteId) return errorResponse('noteId fehlt', 400);
          await fetch(
            `${SUPABASE_URL}/rest/v1/admin_user_notes?id=eq.${encodeURIComponent(noteId)}`,
            { method: 'DELETE', headers: svcHeaders },
          );
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`Notes-Delete-Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/xp  (Admin vergibt XP manuell) ──
      // Body: { amount: int, reason: string, admin: string }
      // amount kann positiv (Bonus) oder negativ (Abzug) sein, |amount| ≤ 10000.
      // Versucht zuerst RPC add_user_xp; bei Fehler direkter PATCH auf profiles.xp.
      // Schreibt admin_audit_log und sendet In-App + Push-Benachrichtigung.
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/xp')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          const body = await request.json().catch(() => ({}));
          const amountRaw = Number(body.amount);
          if (!Number.isFinite(amountRaw) || amountRaw === 0) {
            return errorResponse('amount muss eine Zahl ≠ 0 sein', 400);
          }
          const amount = Math.max(-10000, Math.min(10000, Math.trunc(amountRaw)));
          const reason = String(body.reason || 'admin_grant').slice(0, 200);
          const adminUsername = caller.username; // AUDIT-FIX B1: aus verifiziertem Header

          // Versuch 1: RPC add_user_xp (atomares Increment).
          let newXp = null;
          let usedRpc = false;
          try {
            const rpcRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/add_user_xp`, {
              method: 'POST', headers: svcHeaders,
              body: JSON.stringify({ p_user_id: userId, p_amount: amount, p_reason: `admin:${reason}` }),
            });
            if (rpcRes.ok) {
              usedRpc = true;
              const r = await rpcRes.json().catch(() => null);
              if (typeof r === 'number') newXp = r;
              else if (r && typeof r === 'object' && 'xp' in r) newXp = r.xp;
            }
          } catch (_) { /* fall through to PATCH */ }

          // Versuch 2: Direkter PATCH wenn RPC nicht existiert.
          if (!usedRpc) {
            // Aktuellen XP lesen
            const cur = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=xp,username&limit=1`,
              { headers: svcHeaders }
            );
            const curData = await cur.json().catch(() => []);
            const curXp = Number((Array.isArray(curData) && curData[0]?.xp) || 0);
            newXp = Math.max(0, curXp + amount);
            const patch = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
              {
                method: 'PATCH',
                headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
                body: JSON.stringify({ xp: newXp }),
              }
            );
            if (!patch.ok) {
              const t = await patch.text().catch(() => '');
              return errorResponse(`XP-Patch fehlgeschlagen: ${t}`, patch.status);
            }
          }

          // Audit-Log (fire-and-forget)
          fetch(`${SUPABASE_URL}/rest/v1/admin_audit_log`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              admin_username: adminUsername,
              action: amount > 0 ? 'xp_grant' : 'xp_revoke',
              target_identity: userId,
              target_username: null,
              details: { amount, reason, new_xp: newXp, used_rpc: usedRpc },
            }),
          }).catch(() => {});

          // Push-Benachrichtigung an User
          if (amount > 0) {
            await pushNotif(userId, 'xp_grant', '✨ XP-Bonus erhalten',
              `Du hast ${amount} XP von einem Admin erhalten · ${reason}`,
              { type: 'xp_grant', amount, reason });
          } else {
            await pushNotif(userId, 'xp_revoke', '⚠️ XP-Anpassung',
              `Ein Admin hat ${amount} XP angepasst · ${reason}`,
              { type: 'xp_revoke', amount, reason });
          }

          return jsonResponse({
            success: true,
            action: amount > 0 ? 'xp_grant' : 'xp_revoke',
            amount, new_xp: newXp, used_rpc: usedRpc,
          });
        } catch (e) {
          return errorResponse(`XP-Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/username-change-requests (v92) ─────────────────
      // Liefert alle pending Username-Change-Requests fuer den Admin-Dashboard.
      if (method === 'GET' && path === '/api/admin/username-change-requests') {
        try {
          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/username_change_requests_pending?select=*`,
            { headers: { 'apikey': serviceKey, 'Authorization': `Bearer ${serviceKey}` } }
          );
          const arr = await r.json().catch(() => []);
          return jsonResponse({
            success: true,
            requests: Array.isArray(arr) ? arr : [],
            total: Array.isArray(arr) ? arr.length : 0,
          });
        } catch (e) {
          return errorResponse(`Requests-Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/username-change-requests/:id/approve|reject ────
      // Body: { admin?: string (Username des Entscheiders), note?: string }
      if (method === 'POST' &&
          path.startsWith('/api/admin/username-change-requests/') &&
          (path.endsWith('/approve') || path.endsWith('/reject'))) {
        try {
          const reqId = path.split('/')[4];
          const decision = path.endsWith('/approve') ? 'approved' : 'rejected';
          const body = await request.json().catch(() => ({}));
          const adminUsername = caller.username; // AUDIT-FIX B1: aus verifiziertem Header
          const note = String(body.note || '').slice(0, 500);

          const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY;
          const svcH = {
            'Content-Type': 'application/json',
            'apikey': serviceKey,
            'Authorization': `Bearer ${serviceKey}`,
          };

          // Fetch request
          const fetchReq = await fetch(
            `${SUPABASE_URL}/rest/v1/username_change_requests?id=eq.${reqId}&limit=1`,
            { headers: svcH }
          );
          const reqArr = await fetchReq.json().catch(() => []);
          if (!Array.isArray(reqArr) || reqArr.length === 0) {
            return errorResponse('Request nicht gefunden', 404);
          }
          const reqRow = reqArr[0];
          if (reqRow.status !== 'pending') {
            return errorResponse(`Request bereits ${reqRow.status}`, 400);
          }

          // Update status
          await fetch(
            `${SUPABASE_URL}/rest/v1/username_change_requests?id=eq.${reqId}`,
            {
              method: 'PATCH',
              headers: { ...svcH, 'Prefer': 'return=minimal' },
              body: JSON.stringify({
                status: decision,
                decided_by_username: adminUsername,
                decided_at: new Date().toISOString(),
                decision_note: note || null,
              }),
            }
          );

          // Bei Approval: Username direkt aendern (Trigger laesst durch wegen
          // approved Request <7 Tage alt). Aber sicherheitshalber selber als
          // Service-Role machen.
          if (decision === 'approved' && reqRow.profile_id) {
            // Pruefe ob neuer Name noch frei (race condition)
            const taken = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?select=id&username=eq.${encodeURIComponent(reqRow.requested_username)}&limit=1`,
              { headers: svcH }
            );
            const takenArr = await taken.json().catch(() => []);
            if (Array.isArray(takenArr) && takenArr.length > 0
                && takenArr[0].id !== reqRow.profile_id) {
              return errorResponse(
                'Username ist mittlerweile vergeben - Request abgelehnt', 409
              );
            }
            await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${reqRow.profile_id}`,
              {
                method: 'PATCH',
                headers: { ...svcH, 'Prefer': 'return=minimal' },
                body: JSON.stringify({ username: reqRow.requested_username }),
              }
            );
          }

          return jsonResponse({
            success: true,
            decision,
            request_id: reqId,
            new_username: decision === 'approved' ? reqRow.requested_username : null,
          });
        } catch (e) {
          return errorResponse(`Decision-Fehler: ${e.message}`);
        }
      }

      // ── PUT /api/admin/users/:userId/role  (v5.44.3 Admin Rolle aendern) ──
      // Body: { role: 'user'|'moderator'|'admin'|'content_editor'|'root_admin',
      //         admin?: string (Username des Admin der die Aenderung macht) }
      // Service-Role-Key umgeht RLS damit das Worker-Endpoint die einzige
      // Server-Seitige Schreib-Stelle fuer role bleibt (siehe v91 RLS-Policy
      // profiles_role_update_admin_only). Schreibt automatisch in
      // admin_audit_log via v91 trigger profiles_role_change_audit.
      if ((method === 'PUT' || method === 'POST') && path.includes('/users/') && path.endsWith('/role')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          const body = await request.json().catch(() => ({}));
          const newRole = String(body.role || '').toLowerCase().replace('-', '_');
          const allowedRoles = ['user', 'moderator', 'admin', 'content_editor', 'root_admin'];
          if (!allowedRoles.includes(newRole)) {
            return errorResponse(
              `role muss einer von ${allowedRoles.join(', ')} sein`, 400
            );
          }
          // AUDIT-FIX A2 + B5: Hierarchie + Selbst-Aenderung-Block
          if (String(userId) === String(caller.userId)) {
            return errorResponse('Selbst-Rollenaenderung ist nicht erlaubt', 403);
          }
          const callerLevel = caller.isRootAdmin ? 3 :
                              caller.role === 'admin' ? 2 :
                              (caller.role === 'moderator' || caller.role === 'content_editor') ? 1 : 0;
          const targetLevel = newRole === 'root_admin' ? 3 :
                              newRole === 'admin' ? 2 :
                              (newRole === 'moderator' || newRole === 'content_editor') ? 1 : 0;
          if (targetLevel >= callerLevel) {
            return errorResponse(
              `Rolle '${newRole}' erfordert hoehere Caller-Rolle als '${caller.role}'`,
              403, 'insufficient_privilege'
            );
          }
          const adminUsername = caller.username;

          // PATCH profiles via Service-Role
          const patchRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`,
            {
              method: 'PATCH',
              headers: {
                'Content-Type': 'application/json',
                'apikey': env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY}`,
                'Prefer': 'return=representation',
              },
              body: JSON.stringify({ role: newRole }),
            }
          );
          if (!patchRes.ok) {
            const t = await patchRes.text().catch(() => '');
            return errorResponse(
              `Rolle-Update fehlgeschlagen: ${patchRes.status} ${t.slice(0, 200)}`
            );
          }
          const data = await patchRes.json().catch(() => []);
          const updated = Array.isArray(data) ? data[0] : data;
          if (!updated) {
            return errorResponse('User nicht gefunden', 404);
          }

          // Audit-Log (v115: korrektes Schema via logAudit).
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'role_change_explicit',
            target_id: userId,
            details: { new_role: newRole, source: 'api/admin/users/role' },
          });

          return jsonResponse({
            success: true,
            user_id: userId,
            new_role: newRole,
            username: updated.username || null,
          });
        } catch (e) {
          return errorResponse(`Rolle-Update-Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/users/:userId/module-access ───────────────────────────
      // Liefert ALLE Admin-Overrides fuer einen User -- inkl. evtl. Altlasten
      // unter Legacy-IDs ('user_*'). Sucht parallel unter beiden IDs (UUID +
      // legacy) damit der Admin im UI sieht, wenn ein Eintrag unter einer
      // veralteten ID liegt (Task 2: Status-Anzeige im Dashboard).
      // user_id wird im Response explizit zurueckgegeben damit die UI die
      // Heuristik (UUID vs Legacy) anwenden kann.
      if (method === 'GET' && path.includes('/users/') && path.endsWith('/module-access')) {
        try {
          const userId = path.split('/')[4];
          if (!userId) return errorResponse('userId fehlt', 400);
          // Beide IDs ermitteln: was als Eingabe kam + die jeweils andere.
          const candidates = new Set([userId]);
          const uuid = await resolveProfileUuid(userId, svcHeaders);
          if (uuid) candidates.add(uuid);
          // Wenn Eingabe UUID war: zugehoerige legacy_user_id mitsuchen.
          if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId)) {
            try {
              const lr = await fetch(
                `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=legacy_user_id&limit=1`,
                { headers: svcHeaders },
              );
              if (lr.ok) {
                const arr = await lr.json().catch(() => []);
                const legacy = Array.isArray(arr) && arr[0]?.legacy_user_id;
                if (legacy) candidates.add(legacy);
              }
            } catch (_) {}
          }
          const idList = [...candidates].map(encodeURIComponent).join(',');
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_module_access?user_id=in.(${idList})&select=user_id,module_code,module_type,is_granted,granted_by,reason,created_at&order=created_at.desc`,
            { headers: svcHeaders },
          );
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({
            success: true,
            overrides: Array.isArray(rows) ? rows : [],
            // UI-Hinweise: kanonische UUID + alle abgefragten IDs.
            canonical_uuid: uuid,
            queried_ids: [...candidates],
          });
        } catch (e) { return errorResponse(`module-access GET Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/module-access ──────────────────────────
      // Setzt oder entfernt einen Modul-Override fuer einen User.
      // Body fuer setzen:   { module_code, module_type, is_granted, reason? }
      //   is_granted=true  → Force-Unlock (Prerequisites ignorieren)
      //   is_granted=false → Force-Block  (auch wenn Prerequisites erfuellt)
      // Body fuer entfernen: { module_code, action: 'remove' }
      //
      // Task 1 (2026-06-07): KANONISCHE UUID. Der Schreibpfad loest die
      // Eingabe-ID immer auf profiles.id (UUID) auf. Dadurch landet die
      // user_id-Spalte konsistent bei der UUID und der Lesepfad in
      // vorhang_service.dart (sucht via .inFilter ueber UUID + legacy)
      // matched IMMER. Verhindert das frueher beobachtete "Override
      // gespeichert aber User sieht nichts"-Problem.
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/module-access')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);

          // Nur Admin+ darf Modul-Overrides setzen (Moderatoren nicht).
          if (!['admin', 'root_admin'].includes(caller.role)) {
            return errorResponse('Keine Berechtigung: Modul-Overrides erfordern Admin-Rolle', 403);
          }

          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          const moduleCode = String(body?.module_code || '').trim().toUpperCase();
          if (!moduleCode) return errorResponse('module_code fehlt', 400);

          // ─── KANONISCHE UUID aufloesen ──────────────────────────────
          // Eingabe kann UUID ODER Legacy-ID ('user_*') sein -- die admin
          // user-list im Worker liefert beides je nach Datenstand. Wir
          // brauchen IMMER die profiles.id (UUID) damit der Lesepfad
          // konsistent matched.
          const canonicalUuid = await resolveProfileUuid(rawUserId, svcHeaders);
          // Wenn kein Profil-Match: Eingabe-ID als Fallback verwenden +
          // Warnung loggen (der User existiert evtl. nur in der alten
          // InvisibleAuth-Welt und wurde noch nie zu profiles syncronisiert).
          const writeUserId = canonicalUuid || rawUserId;
          if (!canonicalUuid) {
            console.warn(`[module-access] WARN: keine UUID fuer rawUserId='${rawUserId}' -- schreibe mit Fallback. User-Sync evtl. noetig.`);
          }

          // Remove-Aktion: ALLE Override-Zeilen fuer diesen User+Modul
          // loeschen -- auch evtl. Altlasten unter Legacy-ID, damit der
          // User wirklich auf die Prerequisite-Logik zurueckfaellt.
          if (body?.action === 'remove') {
            const removalIds = new Set([rawUserId]);
            if (canonicalUuid) removalIds.add(canonicalUuid);
            // Zusaetzlich legacy_user_id ermitteln wenn nur UUID bekannt war.
            if (canonicalUuid === rawUserId) {
              try {
                const lr = await fetch(
                  `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(canonicalUuid)}&select=legacy_user_id&limit=1`,
                  { headers: svcHeaders },
                );
                if (lr.ok) {
                  const arr = await lr.json().catch(() => []);
                  const legacy = Array.isArray(arr) && arr[0]?.legacy_user_id;
                  if (legacy) removalIds.add(legacy);
                }
              } catch (_) {}
            }
            const idList = [...removalIds].map(encodeURIComponent).join(',');
            await fetch(
              `${SUPABASE_URL}/rest/v1/admin_module_access?user_id=in.(${idList})&module_code=eq.${encodeURIComponent(moduleCode)}`,
              { method: 'DELETE', headers: svcHeaders },
            );
            logAudit(svcHeaders, {
              admin_username: caller.username,
              action: 'module_access_remove',
              target_id: writeUserId,
              details: { module_code: moduleCode, queried_ids: [...removalIds] },
            });
            return jsonResponse({ success: true, action: 'removed', module_code: moduleCode });
          }

          // Setzen: is_granted + module_type pflicht.
          const moduleType = String(body?.module_type || '').toLowerCase();
          if (!['vorhang', 'ursprung'].includes(moduleType)) {
            return errorResponse('module_type muss "vorhang" oder "ursprung" sein', 400);
          }
          if (typeof body?.is_granted !== 'boolean') {
            return errorResponse('is_granted (boolean) fehlt', 400);
          }
          const isGranted = body.is_granted;
          const reason = String(body?.reason || '').trim().slice(0, 300) || null;

          // Falls eine alte Zeile unter Legacy-ID existiert: erst loeschen,
          // damit nicht zwei widerspruechliche Zeilen entstehen.
          if (canonicalUuid && rawUserId !== canonicalUuid) {
            await fetch(
              `${SUPABASE_URL}/rest/v1/admin_module_access?user_id=eq.${encodeURIComponent(rawUserId)}&module_code=eq.${encodeURIComponent(moduleCode)}`,
              { method: 'DELETE', headers: svcHeaders },
            ).catch(() => {});
          }

          // UPSERT mit kanonischer UUID.
          const upsertRes = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_module_access?on_conflict=user_id,module_code`,
            {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=representation' },
              body: JSON.stringify({
                user_id: writeUserId,
                module_code: moduleCode,
                module_type: moduleType,
                is_granted: isGranted,
                granted_by: caller.username,
                reason,
                created_at: new Date().toISOString(),
              }),
            },
          );
          if (!upsertRes.ok) {
            const t = await upsertRes.text().catch(() => '');
            return errorResponse(`module-access UPSERT Fehler: ${upsertRes.status} ${t.slice(0, 200)}`);
          }

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: isGranted ? 'module_access_grant' : 'module_access_block',
            target_id: writeUserId,
            details: {
              module_code: moduleCode,
              module_type: moduleType,
              reason,
              uuid_resolved: !!canonicalUuid,
              raw_input_id: rawUserId,
            },
          });

          return jsonResponse({
            success: true,
            action: isGranted ? 'granted' : 'blocked',
            module_code: moduleCode,
            module_type: moduleType,
            stored_user_id: writeUserId,
            uuid_resolved: !!canonicalUuid,
          });
        } catch (e) { return errorResponse(`module-access POST Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/module-access/batch-all ────────────
      // Setzt is_granted fuer ALLE Module in BEIDEN Welten (vorhang + ursprung)
      // auf einmal. Body: { is_granted: bool }
      // v130: "Beide Welten" Bulk-Aktion.
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/module-access/batch-all')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          if (!['admin', 'root_admin'].includes(caller.role)) {
            return errorResponse('Admin-Rolle erforderlich', 403);
          }
          let body = {};
          try { body = await request.clone().json(); } catch (_) {}
          if (typeof body?.is_granted !== 'boolean') {
            return errorResponse('is_granted (boolean) fehlt', 400);
          }
          const isGranted = body.is_granted;
          const canonicalUuid = await resolveProfileUuid(rawUserId, svcHeaders);
          const writeUserId = canonicalUuid || rawUserId;

          // Alle Module beider Welten laden
          const [vhRaw, urRaw] = await Promise.all([
            fetch(`${SUPABASE_URL}/rest/v1/vorhang_modules?select=module_code`, { headers: svcHeaders })
              .then(r => r.ok ? r.json().catch(() => []) : []),
            fetch(`${SUPABASE_URL}/rest/v1/ursprung_modules?select=module_code`, { headers: svcHeaders })
              .then(r => r.ok ? r.json().catch(() => []) : []),
          ]);

          const rows = [
            ...((Array.isArray(vhRaw) ? vhRaw : []).map(m => ({
              user_id: writeUserId,
              module_code: m.module_code,
              module_type: 'vorhang',
              is_granted: isGranted,
              granted_by: caller.username,
              created_at: new Date().toISOString(),
            }))),
            ...((Array.isArray(urRaw) ? urRaw : []).map(m => ({
              user_id: writeUserId,
              module_code: m.module_code,
              module_type: 'ursprung',
              is_granted: isGranted,
              granted_by: caller.username,
              created_at: new Date().toISOString(),
            }))),
          ];

          if (rows.length === 0) return jsonResponse({ success: true, count: 0 });

          const upsRes = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_module_access?on_conflict=user_id,module_code`,
            {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify(rows),
            },
          );
          if (!upsRes.ok) {
            const t = await upsRes.text().catch(() => '');
            return errorResponse(`batch-all UPSERT Fehler: ${upsRes.status} ${t.slice(0, 200)}`);
          }

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: isGranted ? 'module_access_batch_grant' : 'module_access_batch_block',
            target_id: writeUserId,
            details: { count: rows.length, worlds: ['vorhang', 'ursprung'] },
          });

          return jsonResponse({
            success: true,
            count: rows.length,
            action: isGranted ? 'granted' : 'blocked',
            worlds: ['vorhang', 'ursprung'],
          });
        } catch (e) { return errorResponse(`batch-all Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v128 (2026-06-07): MODUL-WERKSTATT (Task 3)
      // KI-gestuetzte Modul-Erstellung & -Editierung im Admin-Dashboard.
      // ════════════════════════════════════════════════════════════════
      // Endpunkte:
      //   POST /api/admin/module-workshop/topics    -> KI-Themen-Vorschlaege
      //   POST /api/admin/module-workshop/generate  -> Vollst. Modul erstellen
      //   POST /api/admin/module-workshop/expand    -> Inhalte erweitern
      //   POST /api/admin/module-workshop/save      -> Persistieren in Tabelle
      //   GET  /api/admin/module-workshop/list      -> Vollst. Liste fuer Edit
      // Welt-Param: 'vorhang' oder 'ursprung' -> bestimmt die Tabelle.

      // WORKSHOP_BRANCHES / WORKSHOP_WORLDS / normWorld / tableForWorld sind
      // jetzt Top-Level (s.o.) damit auch der Cron-Auto-Scan sie nutzen kann.

      // workshopAiJson -> nutzt jetzt den globalen aiJson-Helper (5-Quellen-Kette).
      // Bleibt als duenner Alias erhalten damit die bestehenden Call-Sites
      // unveraendert weiterlaufen.
      const workshopAiJson = (systemMsg, userMsg, maxTokens = 1200) =>
        aiJson(env, systemMsg, userMsg, maxTokens);

      // ── POST /api/admin/module-workshop/topics ─────────────────────
      // Body: { hint: 'Freitext (kurz)', world: 'vorhang'|'ursprung' }
      // Returns: { suggestions: ['Thema 1', 'Thema 2', ...] }
      if (method === 'POST' && path === '/api/admin/module-workshop/topics') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const hint = String(body?.hint || '').trim().slice(0, 200);
          const world = normWorld(body?.world);
          const worldContextMap = {
            vorhang: 'die "Vorhang"-Welt: Machtpsychologie, Manipulationserkennung, Verhandlung, Koerpersprache, strategisches Denken, Schattenarbeit.',
            ursprung: 'die "Ursprung"-Welt: Bewusstsein, Gateway-Erfahrungen, Focus-Levels, Energie-Tools, Manifestation, Remote Viewing.',
            materie: 'die "Materie"-Welt: Recherche-Techniken, Netzwerk-Analyse, Quellenkritik, Geopolitik & Macht, Wirtschaft & Finanzen, Desinformation erkennen.',
            energie: 'die "Energie"-Welt: Energiearbeit, Meditation & Stille, Chakren & Aura, Manifestation, Intuition & Wahrnehmung, Heilung & Balance.',
          };
          const worldContext = worldContextMap[world] || worldContextMap.vorhang;
          const system = `Du hilfst beim Erstellen von Lern-Modulen fuer ${worldContext} Antworte AUSSCHLIESSLICH als JSON-Array von 5 Strings, je 3-8 Worte, auf Deutsch.`;
          const user = hint
            ? `Schlage 5 konkrete Modul-Themen vor, die zu folgendem Ausgangspunkt passen: "${hint}"`
            : `Schlage 5 spannende, noch nicht offensichtliche Modul-Themen vor.`;
          const arr = await workshopAiJson(system, user, 400);
          const suggestions = (Array.isArray(arr) ? arr : []).map(String).slice(0, 5);
          return jsonResponse({ success: true, suggestions });
        } catch (e) {
          return errorResponse(`Themen-Vorschlaege fehlgeschlagen: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/generate ───────────────────
      // Body: { topic: 'Lehrthema', world: 'vorhang'|'ursprung', branch?: '...' }
      // Returns: { module: { title, subtitle, branch, theory_content, case_study, exercise_description, xp_reward } }
      if (method === 'POST' && path === '/api/admin/module-workshop/generate') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const topic = String(body?.topic || '').trim();
          if (topic.length < 3) return errorResponse('topic fehlt', 400);
          const world = normWorld(body?.world);
          const tbl = tableForWorld(world);
          // Branch-Hinweis darf bestehend ODER ein komplett neues Thema sein.
          const branchHint = body?.branch ? String(body.branch).trim() : null;
          // Wenn der Admin explizit ein neues Thema will:
          const wantNewTheme = body?.new_theme === true;

          // Bestehende Bereiche der Welt laden (echte + Standard) fuer die
          // intelligente Zuordnung.
          const dbBranches = await fetchExistingBranches(tbl, svcHeaders);
          const allBranches = [...new Set([...dbBranches, ...WORKSHOP_BRANCHES[world]])];
          const branchList = allBranches.join(' | ');

          const system = [
            'Du bist Lehrredaktion fuer die Weltenbibliothek-App. Erstellst ein neues Lern-Modul (eine Lerneinheit).',
            'Ein "branch" ist der uebergeordnete Bereich/das Modul-Thema, dem die Lerneinheit zugeordnet wird.',
            'Schreibst praezise, sachlich, lebensnah. Kein Marketing-Sprech, keine Floskeln.',
            'Antworte AUSSCHLIESSLICH als JSON-Objekt mit den Feldern:',
            '  title (max 60 Zeichen),',
            '  subtitle (max 120 Zeichen),',
            wantNewTheme
              ? `  branch (Name eines KOMPLETT NEUEN Bereichs, 2-4 Worte; darf NICHT einer von diesen sein: ${branchList}),`
              : `  branch -- WICHTIG: Wenn der Inhalt thematisch zu einem dieser BESTEHENDEN Bereiche passt, nutze EXAKT diesen Namen: ${branchList}. NUR wenn er zu KEINEM passt, erfinde einen neuen, treffenden Bereich-Namen.`,
            '  theory_content (300-700 Worte, Markdown erlaubt: ## Ueberschriften, **fett**, Listen),',
            '  case_study (eine konkrete Fallgeschichte, 150-350 Worte),',
            '  exercise_description (1-3 praktische Uebungen, 100-300 Worte),',
            '  xp_reward (Integer zwischen 50 und 200, je nach Schwierigkeit),',
            '  test_questions (Array von 3-5 Quiz-Fragen, je { "question": "...", "options": [4 Antworten], "answer_index": 0-3 }),',
            '  sources (Array von 2-4 Quellen/Belegen, je { "title": "...", "url": "..." } -- seriose, real existierende Quellen).',
            'Inhalte auf Deutsch.',
          ].join('\n');
          const user = branchHint
            ? `Thema-Inhalt: ${topic}\nGewuenschter Bereich (branch): ${branchHint}\nErstelle die vollstaendige Lerneinheit.`
            : (wantNewTheme
              ? `Thema-Inhalt: ${topic}\nLege dafuer einen KOMPLETT NEUEN Bereich (branch) an und erstelle die vollstaendige Lerneinheit.`
              : `Thema-Inhalt: ${topic}\nOrdne es dem passenden BESTEHENDEN Bereich zu (oder neu, wenn nichts passt), und erstelle die vollstaendige Lerneinheit.`);
          const moduleData = await workshopAiJson(system, user, 4096);

          // ── Intelligente Bereich-Zuordnung ──
          let branch = String(moduleData.branch || '').trim() || branchHint || allBranches[0];
          if (!wantNewTheme) {
            // Auf bestehenden Bereich normalisieren (Case/Tippfehler-tolerant).
            const matched = matchExistingBranch(branch, allBranches);
            if (matched) branch = matched;
          }

          const xpRaw = Number(moduleData.xp_reward) || 100;
          const xp = Math.max(50, Math.min(200, Math.round(xpRaw)));

          // Tests fuer Vorhang/Ursprung garantieren (Pflicht laut Anforderung).
          let testQuestions = normTestQuestions(moduleData.test_questions);
          if ((world === 'vorhang' || world === 'ursprung') && testQuestions.length < 3) {
            testQuestions = await ensureTestQuestions(env, testQuestions, {
              title: moduleData.title || topic,
              theory_content: moduleData.theory_content || '',
            });
          }

          return jsonResponse({
            success: true,
            module: {
              title: String(moduleData.title || topic).slice(0, 120),
              subtitle: String(moduleData.subtitle || '').slice(0, 240),
              branch,
              theory_content: String(moduleData.theory_content || ''),
              case_study: String(moduleData.case_study || ''),
              exercise_description: String(moduleData.exercise_description || ''),
              xp_reward: xp,
              test_questions: testQuestions,
              sources: normSources(moduleData.sources),
            },
          });
        } catch (e) {
          return errorResponse(`Modul-Generierung fehlgeschlagen: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/expand ─────────────────────
      // Body: { world, current: { title, theory_content, case_study, exercise_description } }
      // Returns: { module: { title, subtitle, branch, theory_content, case_study, exercise_description, xp_reward } }
      if (method === 'POST' && path === '/api/admin/module-workshop/expand') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const branches = WORKSHOP_BRANCHES[world];
          const current = body?.current || {};
          if (!current.title || !current.theory_content) {
            return errorResponse('current.title + current.theory_content noetig', 400);
          }
          const system = [
            'Du verbesserst ein bestehendes Lern-Modul der Weltenbibliothek.',
            'Behalte den Charakter und Schwerpunkt bei, fuege aber substantielle Tiefe hinzu:',
            '  - Theory: ergaenze Mechanismen, Beispiele, Gegenargumente',
            '  - Case Study: konkrete Geschichte mit Personen, Daten, Wendung',
            '  - Uebungen: praxisnah, ohne Plattitueden',
            'Schreibst Deutsch, sachlich, ohne Marketing-Sprech.',
            'Antworte AUSSCHLIESSLICH als JSON-Objekt mit denselben Feldern wie Generate',
            '(inkl. test_questions [3-5 Quiz-Fragen je {question, options[4], answer_index}]',
            ' und sources [2-4 je {title, url}]).',
            `Branches: ${branches.join(' | ')}`,
          ].join('\n');
          const user = `Bestehender Inhalt:\n\nTitel: ${current.title}\nSubtitle: ${current.subtitle || ''}\nBranch: ${current.branch || ''}\n\nTheorie:\n${current.theory_content}\n\nFallstudie:\n${current.case_study || ''}\n\nUebung:\n${current.exercise_description || ''}\n\nBitte ausbauen.`;
          const moduleData = await workshopAiJson(system, user, 4096);
          const branch = branches.includes(moduleData.branch)
            ? moduleData.branch
            : (current.branch && branches.includes(current.branch) ? current.branch : branches[0]);
          const xpRaw = Number(moduleData.xp_reward) || Number(current.xp_reward) || 100;
          const xp = Math.max(50, Math.min(200, Math.round(xpRaw)));
          // Bestehende test_questions/sources behalten falls die KI keine liefert.
          const tq = normTestQuestions(moduleData.test_questions);
          const src = normSources(moduleData.sources);
          return jsonResponse({
            success: true,
            module: {
              title: String(moduleData.title || current.title).slice(0, 120),
              subtitle: String(moduleData.subtitle || current.subtitle || '').slice(0, 240),
              branch,
              theory_content: String(moduleData.theory_content || current.theory_content),
              case_study: String(moduleData.case_study || current.case_study || ''),
              exercise_description: String(moduleData.exercise_description || current.exercise_description || ''),
              xp_reward: xp,
              test_questions: tq.length > 0
                ? tq
                : (Array.isArray(current.test_questions) ? current.test_questions : []),
              sources: src.length > 0
                ? src
                : (Array.isArray(current.sources) ? current.sources : []),
            },
          });
        } catch (e) {
          return errorResponse(`Modul-Ausarbeitung fehlgeschlagen: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/translate (W4) ─────────────
      // Body: { module, target_lang }  -> uebersetzt Modul-Felder per KI.
      if (method === 'POST' && path === '/api/admin/module-workshop/translate') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const mod = body?.module || {};
          const langMap = { en: 'Englisch', tr: 'Tuerkisch', fr: 'Franzoesisch', es: 'Spanisch', ru: 'Russisch', ar: 'Arabisch' };
          const langCode = String(body?.target_lang || 'en').toLowerCase();
          const langName = langMap[langCode] || 'Englisch';
          const system = [
            `Du uebersetzt ein Lern-Modul vollstaendig nach ${langName}.`,
            'Behalte Markdown-Formatierung und Fachbegriffe sinnvoll bei.',
            'Antworte als JSON-Objekt mit EXAKT diesen Schluesseln (Werte uebersetzt):',
            '  title, subtitle, theory_content, case_study, exercise_description,',
            '  test_questions (Array {question, options[], answer_index unveraendert}).',
          ].join('\n');
          const payload = JSON.stringify({
            title: mod.title || '', subtitle: mod.subtitle || '',
            theory_content: mod.theory_content || '', case_study: mod.case_study || '',
            exercise_description: mod.exercise_description || '',
            test_questions: Array.isArray(mod.test_questions) ? mod.test_questions : [],
          });
          const tr = await aiJson(env, system, `Modul (JSON):\n${payload}`, 2600);
          return jsonResponse({
            success: true,
            lang: langCode,
            module: {
              ...mod,
              title: String(tr.title || mod.title || '').slice(0, 120),
              subtitle: String(tr.subtitle || mod.subtitle || '').slice(0, 240),
              theory_content: String(tr.theory_content || mod.theory_content || ''),
              case_study: String(tr.case_study || mod.case_study || ''),
              exercise_description: String(tr.exercise_description || mod.exercise_description || ''),
              test_questions: normTestQuestions(tr.test_questions).length > 0
                ? normTestQuestions(tr.test_questions)
                : (Array.isArray(mod.test_questions) ? mod.test_questions : []),
            },
          });
        } catch (e) {
          return errorResponse(`Uebersetzung fehlgeschlagen: ${e.message}`);
        }
      }

      // ── GET/POST /api/admin/module-workshop/scan-config (W7) ───────
      if (path === '/api/admin/module-workshop/scan-config') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          if (method === 'GET') {
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/module_scan_config?id=eq.1&limit=1`,
              { headers: svcHeaders });
            const arr = r.ok ? await r.json().catch(() => []) : [];
            const cfg = (Array.isArray(arr) && arr[0]) || { enabled: true, worlds: WORKSHOP_WORLDS };
            return jsonResponse({ success: true, config: cfg });
          }
          // POST: { enabled?, worlds? }
          const body = await request.clone().json().catch(() => ({}));
          const patch = { updated_at: new Date().toISOString(), updated_by: caller.username };
          if (typeof body?.enabled === 'boolean') patch.enabled = body.enabled;
          if (Array.isArray(body?.worlds)) {
            patch.worlds = body.worlds.filter((w) => WORKSHOP_WORLDS.includes(w));
          }
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/module_scan_config?id=eq.1`,
            { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=representation' }, body: JSON.stringify(patch) });
          if (!r.ok) return errorResponse(`scan-config Update ${r.status}`, r.status);
          const arr = await r.json().catch(() => []);
          return jsonResponse({ success: true, config: (Array.isArray(arr) && arr[0]) || patch });
        } catch (e) {
          return errorResponse(`scan-config Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/module-workshop/list?world=vorhang ──────────
      // Vollstaendige Liste inkl. theory_content fuer Edit-Ansicht.
      if (method === 'GET' && path === '/api/admin/module-workshop/list') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const world = normWorld(url.searchParams.get('world'));
          const tbl = tableForWorld(world);
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?select=module_code,branch,branch_order,title,subtitle,is_boss_module,xp_reward,prerequisites,theory_content,case_study,exercise_description,test_questions,sources,cover_image_url&order=branch_order.asc,module_code.asc`,
            { headers: svcHeaders },
          );
          if (!r.ok) {
            const t = await r.text().catch(() => '');
            return errorResponse(`module-workshop list: ${r.status} ${t.slice(0, 200)}`);
          }
          const rows = await r.json().catch(() => []);
          return jsonResponse({ success: true, modules: Array.isArray(rows) ? rows : [] });
        } catch (e) {
          return errorResponse(`module-workshop list Fehler: ${e.message}`);
        }
      }

      // ── DELETE /api/admin/module-workshop/module?world=&code= (W2) ──
      // Loescht ein Modul endgueltig. Nur Root-Admin.
      if (method === 'DELETE' && path === '/api/admin/module-workshop/module') {
        if (!caller.isRootAdmin) {
          return errorResponse('Nur Root-Admin darf Module loeschen', 403);
        }
        try {
          const world = normWorld(url.searchParams.get('world'));
          const code = String(url.searchParams.get('code') || '').trim().toUpperCase();
          if (!code) return errorResponse('code fehlt', 400);
          const tbl = tableForWorld(world);
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?module_code=eq.${encodeURIComponent(code)}`,
            { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } },
          );
          if (!r.ok && r.status !== 204) {
            const t = await r.text().catch(() => '');
            return errorResponse(`Loeschen fehlgeschlagen: ${r.status} ${t.slice(0, 200)}`);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'module_workshop_delete',
            target_id: code,
            details: { world },
          });
          return jsonResponse({ success: true, deleted: code });
        } catch (e) {
          return errorResponse(`module-workshop delete Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/reorder (W2) ──
      // Body: { world, order: [{ module_code, branch_order }, ...] }
      if (method === 'POST' && path === '/api/admin/module-workshop/reorder') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const tbl = tableForWorld(world);
          const order = Array.isArray(body?.order) ? body.order : [];
          if (order.length === 0) return errorResponse('order leer', 400);
          let updated = 0;
          for (const item of order) {
            const code = String(item?.module_code || '').trim().toUpperCase();
            const bo = Number(item?.branch_order);
            if (!code || !Number.isFinite(bo)) continue;
            const r = await fetch(
              `${SUPABASE_URL}/rest/v1/${tbl}?module_code=eq.${encodeURIComponent(code)}`,
              {
                method: 'PATCH',
                headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
                body: JSON.stringify({ branch_order: Math.round(bo) }),
              },
            );
            if (r.ok || r.status === 204) updated++;
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'module_workshop_reorder',
            target_id: world,
            details: { count: updated },
          });
          return jsonResponse({ success: true, updated });
        } catch (e) {
          return errorResponse(`module-workshop reorder Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/cover (W3: Cover per KI) ────
      // Body: { world, title, hint? } -> generiert ein Bild (Workers-AI),
      // legt es in R2 ab und liefert die oeffentliche URL.
      if (method === 'POST' && path === '/api/admin/module-workshop/cover') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          if (!env.AI) return errorResponse('Workers-AI nicht verfuegbar', 503);
          if (!env.R2_BUCKET) return errorResponse('Kein R2-Bucket konfiguriert', 503);
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const title = String(body?.title || '').trim();
          const hint = String(body?.hint || '').trim();
          if (!title) return errorResponse('title fehlt', 400);
          const styleMap = {
            vorhang: 'dark cinematic, psychological, dramatic lighting, deep red accents',
            ursprung: 'cosmic, ethereal, consciousness, soft glowing light, deep blue and violet',
            materie: 'investigative, documentary, network of connections, muted earthy tones',
            energie: 'spiritual, energy flow, aura, warm golden and turquoise light',
          };
          const prompt = `Cover artwork for a learning module titled "${title}". ${hint ? hint + '. ' : ''}` +
            `Style: ${styleMap[world] || styleMap.vorhang}. Abstract, symbolic, no text, no letters, high detail, 16:9.`;
          // flux-1-schnell liefert { image: base64 }.
          const aiRes = await env.AI.run('@cf/black-forest-labs/flux-1-schnell', {
            prompt: prompt.slice(0, 2000),
          });
          const b64 = aiRes && aiRes.image;
          if (!b64) return errorResponse('Bildgenerierung lieferte kein Bild', 502);
          // base64 -> Bytes
          const bin = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
          const key = `module-covers/${world}/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.png`;
          await env.R2_BUCKET.put(key, bin, { httpMetadata: { contentType: 'image/png' } });
          const publicUrl = `https://pub-${env.CF_ACCOUNT_ID || 'unknown'}.r2.dev/${key}`;
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'module_cover_generate',
            details: { world, title },
          });
          return jsonResponse({ success: true, cover_image_url: publicUrl });
        } catch (e) {
          return errorResponse(`Cover-Generierung fehlgeschlagen: ${e.message}`);
        }
      }

      // ── GET /api/admin/module-workshop/versions?world=&code= (W5) ──
      if (method === 'GET' && path === '/api/admin/module-workshop/versions') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const world = normWorld(url.searchParams.get('world'));
          const code = String(url.searchParams.get('code') || '').trim().toUpperCase();
          if (!code) return errorResponse('code fehlt', 400);
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/module_versions?world=eq.${encodeURIComponent(world)}&module_code=eq.${encodeURIComponent(code)}&select=id,created_at,created_by&order=created_at.desc&limit=20`,
            { headers: svcHeaders });
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({ success: true, versions: Array.isArray(rows) ? rows : [] });
        } catch (e) {
          return errorResponse(`versions Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/undo (W5) ──────────────────
      // Body: { world, code }. Stellt den letzten Snapshot wieder her und
      // entfernt ihn (mehrfaches Undo geht weiter zurueck).
      if (method === 'POST' && path === '/api/admin/module-workshop/undo') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const code = String(body?.code || '').trim().toUpperCase();
          if (!code) return errorResponse('code fehlt', 400);
          const tbl = tableForWorld(world);
          const vr = await fetch(
            `${SUPABASE_URL}/rest/v1/module_versions?world=eq.${encodeURIComponent(world)}&module_code=eq.${encodeURIComponent(code)}&select=id,snapshot&order=created_at.desc&limit=1`,
            { headers: svcHeaders });
          const varr = vr.ok ? await vr.json().catch(() => []) : [];
          const ver = Array.isArray(varr) && varr[0];
          if (!ver) return errorResponse('Keine fruehere Version vorhanden', 404);
          const snap = ver.snapshot || {};
          // id/created_at aus dem Snapshot entfernen (PK/Timestamps nicht ueberschreiben).
          const restore = { ...snap };
          delete restore.id;
          delete restore.created_at;
          delete restore.updated_at;
          const rr = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?module_code=eq.${encodeURIComponent(code)}`,
            { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify(restore) });
          if (!rr.ok) return errorResponse(`Wiederherstellen ${rr.status}`, rr.status);
          // verbrauchten Snapshot loeschen
          await fetch(`${SUPABASE_URL}/rest/v1/module_versions?id=eq.${encodeURIComponent(ver.id)}`,
            { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'module_workshop_undo',
            target_id: code,
            details: { world },
          });
          return jsonResponse({ success: true, restored: code });
        } catch (e) {
          return errorResponse(`undo Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/save ───────────────────────
      // Body: { world, module: {...}, edit_code?: 'V-31' }
      // Bei edit_code: UPDATE; sonst INSERT mit auto-generiertem module_code.
      // Inhalts-Check: Mindestlaengen + Pflichtfelder + KI-Platzhalter-Warnung.
      if (method === 'POST' && path === '/api/admin/module-workshop/save') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const tbl = tableForWorld(world);
          const mod = body?.module || {};
          const editCode = body?.edit_code ? String(body.edit_code).trim().toUpperCase() : null;

          // ── Inhalts-Check ─────────────────────────────────────────
          const errors = [];
          if (!mod.title || String(mod.title).trim().length < 3) errors.push('title fehlt oder zu kurz');
          // Branch darf bestehend ODER ein komplett neues Thema sein (Freitext).
          const branchName = String(mod.branch || '').trim();
          if (branchName.length < 2 || branchName.length > 60) errors.push('branch (Thema) fehlt oder ungueltig');
          if (!mod.theory_content || String(mod.theory_content).trim().length < 200) {
            errors.push('theory_content zu kurz (min 200 Zeichen)');
          }
          if (!mod.case_study || String(mod.case_study).trim().length < 80) {
            errors.push('case_study zu kurz (min 80 Zeichen)');
          }
          if (!mod.exercise_description || String(mod.exercise_description).trim().length < 50) {
            errors.push('exercise_description zu kurz (min 50 Zeichen)');
          }
          // KI-Platzhalter erkennen
          const placeholderRe = /(\[einfuegen\]|\[bitte ergaenzen\]|\.\.\.tbd|TODO|XXX|Lorem ipsum)/i;
          for (const f of ['title', 'subtitle', 'theory_content', 'case_study', 'exercise_description']) {
            if (mod[f] && placeholderRe.test(String(mod[f]))) {
              errors.push(`${f} enthaelt Platzhalter`);
            }
          }
          if (errors.length > 0) {
            return jsonResponse({ success: false, errors }, 400);
          }

          // ── module_code + branch_order bestimmen ──────────────────
          // Gesamte Tabelle einmal laden (Codes + Branch + Order).
          const allR = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?select=module_code,branch,branch_order`,
            { headers: svcHeaders },
          );
          const allRows = allR.ok ? (await allR.json().catch(() => [])) : [];
          const prefix = WORLD_CODE_PREFIX[world] || 'V-';

          let moduleCode = editCode;
          if (!moduleCode) {
            const nums = allRows
              .map(e => parseInt(String(e.module_code || '').replace(prefix, ''), 10))
              .filter(n => !isNaN(n));
            const nextNum = nums.length > 0 ? Math.max(...nums) + 1 : 1;
            // Zero-padded auf 2 Stellen (V-06) -> konsistent mit Bestand.
            moduleCode = `${prefix}${String(nextNum).padStart(2, '0')}`;
          }

          // branch_order = Position INNERHALB des Branches.
          // FIX: bisher faelschlich der Branch-Index -> Kollision (V-31 unter V-01).
          // Neu: bei neuem Modul ans Ende des (ggf. neuen) Branches; bei Edit
          // bestehende Order behalten.
          let branchOrder;
          if (editCode) {
            const cur = allRows.find(e => String(e.module_code).toUpperCase() === editCode);
            branchOrder = (cur && Number.isFinite(Number(cur.branch_order)))
              ? Number(cur.branch_order)
              : 1;
          } else {
            const inBranch = allRows
              .filter(e => String(e.branch || '').trim() === branchName)
              .map(e => Number(e.branch_order))
              .filter(n => Number.isFinite(n));
            branchOrder = inBranch.length > 0 ? Math.max(...inBranch) + 1 : 1;
          }

          // W5: Vor dem Ueberschreiben eines bestehenden Moduls Snapshot sichern.
          if (editCode) {
            await snapshotModule(world, tbl, moduleCode, svcHeaders, caller.username);
          }

          // Tests fuer Vorhang/Ursprung garantieren (Pflicht).
          let saveTests = normTestQuestions(mod.test_questions);
          if ((world === 'vorhang' || world === 'ursprung') && saveTests.length < 3) {
            saveTests = await ensureTestQuestions(env, saveTests, {
              title: mod.title, theory_content: mod.theory_content,
            });
          }

          // ── Schreiben (UPSERT bei edit, INSERT bei new) ───────────
          const row = {
            module_code: moduleCode,
            branch: branchName,
            branch_order: branchOrder,
            title: String(mod.title).trim(),
            subtitle: String(mod.subtitle || '').trim(),
            is_boss_module: !!mod.is_boss_module,
            xp_reward: Math.max(50, Math.min(200, Math.round(Number(mod.xp_reward) || 100))),
            prerequisites: Array.isArray(mod.prerequisites) ? mod.prerequisites : [],
            theory_content: String(mod.theory_content),
            case_study: String(mod.case_study),
            exercise_description: String(mod.exercise_description),
            // test_questions ist NOT NULL -> immer ein Array mitschicken.
            test_questions: saveTests,
            sources: normSources(mod.sources),
            // W3: Cover-Bild (optional).
            cover_image_url: mod.cover_image_url ? String(mod.cover_image_url).slice(0, 500) : null,
          };

          const saveRes = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?on_conflict=module_code`,
            {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=representation' },
              body: JSON.stringify(row),
            },
          );
          if (!saveRes.ok) {
            const t = await saveRes.text().catch(() => '');
            return errorResponse(`module-workshop save: ${saveRes.status} ${t.slice(0, 300)}`);
          }

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: editCode ? 'module_workshop_edit' : 'module_workshop_create',
            target_id: moduleCode,
            details: { world, branch: row.branch, title: row.title },
          });

          return jsonResponse({
            success: true,
            module_code: moduleCode,
            action: editCode ? 'updated' : 'created',
            world,
          });
        } catch (e) {
          return errorResponse(`module-workshop save Fehler: ${e.message}`);
        }
      }

      // ════════════════════════════════════════════════════════════════
      // v128b (2026-06-07): MODUL-WERKSTATT AUTOMATIK (Vorschlaege A/B/C/D)
      // Manueller Button-Scan statt Cron -> spart Worker-Quota.
      // ════════════════════════════════════════════════════════════════

      // ── POST /api/admin/module-workshop/scan ───────────────────────
      // Body: { world, modes: ['new','improve','quality'] }
      // Analysiert den Modul-Bestand und schreibt Vorschlaege in
      // module_suggestions (status=pending). Returns { created: { new, improve, quality } }.
      if (method === 'POST' && path === '/api/admin/module-workshop/scan') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = normWorld(body?.world);
          const modes = Array.isArray(body?.modes) ? body.modes : ['new', 'improve', 'quality'];
          const tbl = tableForWorld(world);
          const branches = WORKSHOP_BRANCHES[world];

          // Bestehende Module laden (fuer Analyse).
          const listR = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?select=module_code,branch,title,subtitle,xp_reward,theory_content,case_study,exercise_description&order=branch.asc,module_code.asc`,
            { headers: svcHeaders },
          );
          const existing = listR.ok ? (await listR.json().catch(() => [])) : [];
          const created = { new: 0, improve: 0, quality: 0 };
          const rowsToInsert = [];

          // ── Modus A: NEUE Module (Luecken pro Branch finden) ────────
          if (modes.includes('new')) {
            // Branch-Abdeckung zaehlen.
            const perBranch = {};
            for (const b of branches) perBranch[b] = 0;
            for (const m of existing) {
              if (perBranch[m.branch] !== undefined) perBranch[m.branch]++;
            }
            // Schwaechste 2 Branches gezielt fuellen.
            const weakest = Object.entries(perBranch)
              .sort((a, b) => a[1] - b[1])
              .slice(0, 2)
              .map(e => e[0]);
            const titles = existing.map(m => m.title).filter(Boolean).join('; ');
            try {
              const system = [
                'Du planst neue Lern-Module fuer die Weltenbibliothek-App.',
                'Schlage GENAU 2 Vorschlaege vor: 1x ein neues Modul in einem BESTEHENDEN Thema,',
                'und 1x ein komplett NEUES Thema (Bereich), falls ein ganzer Themenbereich fehlt.',
                'Antworte AUSSCHLIESSLICH als JSON-Array mit 2 Objekten:',
                '  { "topic": "...", "branch": "Thema-Name", "is_new_theme": true|false, "rationale": "kurze Begruendung auf Deutsch" }',
                `Bestehende Themen: ${branches.join(' | ')}.`,
                `Bevorzugt schwach abgedeckt: ${weakest.join(', ')}.`,
              ].join('\n');
              const user = `Bereits vorhandene Modul-Titel: ${titles || '(keine)'}\n\nWelche 2 Vorschlaege (1 bestehend, 1 neues Thema)?`;
              const ideas = await workshopAiJson(system, user, 600);
              for (const idea of (Array.isArray(ideas) ? ideas : []).slice(0, 2)) {
                const topic = String(idea.topic || '').trim();
                if (topic.length < 3) continue;
                // Branch darf bestehend ODER neues Thema sein.
                const branch = String(idea.branch || '').trim() || weakest[0];
                const isNewTheme = !branches.includes(branch);
                // Vollstaendiges Modul generieren.
                const genSystem = [
                  'Du bist Lehrredaktion der Weltenbibliothek. Erstelle ein vollstaendiges Lern-Modul.',
                  'Antworte AUSSCHLIESSLICH als JSON-Objekt mit: title, subtitle, theory_content (300-600 Worte, Markdown), case_study (150-300 Worte), exercise_description (100-250 Worte), xp_reward (50-200). Deutsch.',
                ].join('\n');
                const mod = await workshopAiJson(genSystem, `Thema: ${topic}\nBranch/Bereich: ${branch}`, 3000);
                rowsToInsert.push({
                  world, kind: 'new', status: 'pending',
                  title: String(mod.title || topic).slice(0, 120),
                  subtitle: String(mod.subtitle || '').slice(0, 240),
                  branch,
                  theory_content: String(mod.theory_content || ''),
                  case_study: String(mod.case_study || ''),
                  exercise_description: String(mod.exercise_description || ''),
                  xp_reward: Math.max(50, Math.min(200, Math.round(Number(mod.xp_reward) || 100))),
                  rationale: (isNewTheme ? '[NEUES THEMA] ' : '') +
                    String(idea.rationale || `Modul im Bereich "${branch}"`).slice(0, 480),
                  created_by: `scan:${caller.username}`,
                });
                created.new++;
              }
            } catch (e) {
              console.warn(`[scan/new] ${e.message}`);
            }
          }

          // ── Modus B: VERBESSERUNGEN (duenne Module finden) ──────────
          if (modes.includes('improve')) {
            // Module mit kurzem theory_content (< 400 Zeichen) = Kandidaten.
            const thin = existing
              .filter(m => (m.theory_content || '').length < 400)
              .slice(0, 2);
            for (const m of thin) {
              try {
                const system = [
                  'Du verbesserst ein bestehendes, zu duennes Lern-Modul der Weltenbibliothek.',
                  'Baue Theorie, Fallstudie und Uebung substantiell aus. Behalte das Thema bei.',
                  'Antworte AUSSCHLIESSLICH als JSON-Objekt mit: title, subtitle, theory_content (300-600 Worte), case_study (150-300 Worte), exercise_description (100-250 Worte), xp_reward (50-200). Deutsch.',
                ].join('\n');
                const user = `Bestehend:\nTitel: ${m.title}\nTheorie: ${m.theory_content || '(leer)'}\nFallstudie: ${m.case_study || '(leer)'}\nUebung: ${m.exercise_description || '(leer)'}\n\nBaue aus.`;
                const mod = await workshopAiJson(system, user, 3000);
                rowsToInsert.push({
                  world, kind: 'improve', status: 'pending',
                  target_module_code: m.module_code,
                  title: String(mod.title || m.title).slice(0, 120),
                  subtitle: String(mod.subtitle || m.subtitle || '').slice(0, 240),
                  branch: m.branch,
                  theory_content: String(mod.theory_content || ''),
                  case_study: String(mod.case_study || ''),
                  exercise_description: String(mod.exercise_description || ''),
                  xp_reward: Math.max(50, Math.min(200, Math.round(Number(mod.xp_reward) || m.xp_reward || 100))),
                  rationale: `Modul "${m.title}" hatte nur ${(m.theory_content || '').length} Zeichen Theorie -- ausgebaut.`,
                  created_by: `scan:${caller.username}`,
                });
                created.improve++;
              } catch (e) {
                console.warn(`[scan/improve ${m.module_code}] ${e.message}`);
              }
            }
          }

          // ── Modus C: QUALITAETS-CHECK (kein KI-Verbrauch) ───────────
          if (modes.includes('quality')) {
            const placeholderRe = /(\[einfuegen\]|\[bitte ergaenzen\]|\.\.\.tbd|TODO|XXX|Lorem ipsum)/i;
            for (const m of existing) {
              const findings = [];
              if (!m.title || m.title.trim().length < 3) findings.push('Titel fehlt oder zu kurz');
              if (!m.theory_content || m.theory_content.trim().length < 200) {
                findings.push(`Theorie zu kurz (${(m.theory_content || '').length} Zeichen)`);
              }
              if (!m.case_study || m.case_study.trim().length < 80) findings.push('Fallstudie fehlt/zu kurz');
              if (!m.exercise_description || m.exercise_description.trim().length < 50) findings.push('Uebung fehlt/zu kurz');
              if (!branches.includes(m.branch)) findings.push(`Branch "${m.branch}" ist ungueltig`);
              for (const f of ['title', 'subtitle', 'theory_content', 'case_study', 'exercise_description']) {
                if (m[f] && placeholderRe.test(String(m[f]))) findings.push(`${f} enthaelt Platzhalter`);
              }
              if (findings.length > 0) {
                rowsToInsert.push({
                  world, kind: 'quality', status: 'pending',
                  target_module_code: m.module_code,
                  title: m.title || m.module_code,
                  branch: m.branch,
                  quality_findings: findings,
                  rationale: `${findings.length} Qualitaets-Problem(e) in Modul ${m.module_code}`,
                  created_by: `scan:${caller.username}`,
                });
                created.quality++;
              }
            }
          }

          // Vor dem Insert: alte pending-Vorschlaege desselben Scans verwerfen,
          // damit keine Duplikate auflaufen (idempotenter Re-Scan).
          if (rowsToInsert.length > 0) {
            const kinds = [...new Set(rowsToInsert.map(r => r.kind))];
            await fetch(
              `${SUPABASE_URL}/rest/v1/module_suggestions?world=eq.${world}&status=eq.pending&kind=in.(${kinds.join(',')})`,
              { method: 'DELETE', headers: svcHeaders },
            ).catch(() => {});
            const insR = await fetch(`${SUPABASE_URL}/rest/v1/module_suggestions`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
              body: JSON.stringify(rowsToInsert),
            });
            if (!insR.ok) {
              const t = await insR.text().catch(() => '');
              return errorResponse(`Vorschlaege speichern fehlgeschlagen: ${insR.status} ${t.slice(0, 200)}`);
            }
          }

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'module_workshop_scan',
            target_id: world,
            details: { modes, created },
          });
          return jsonResponse({ success: true, created });
        } catch (e) {
          return errorResponse(`module-workshop scan Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/module-workshop/suggestions?world=&status= ──
      if (method === 'GET' && path === '/api/admin/module-workshop/suggestions') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const world = normWorld(url.searchParams.get('world'));
          const status = url.searchParams.get('status') || 'pending';
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/module_suggestions?world=eq.${world}&status=eq.${encodeURIComponent(status)}&order=created_at.desc`,
            { headers: svcHeaders },
          );
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({ success: true, suggestions: Array.isArray(rows) ? rows : [] });
        } catch (e) {
          return errorResponse(`suggestions GET Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/suggestions/:id/accept ─────
      // Nur Root-Admin darf Vorschlaege final veroeffentlichen.
      if (method === 'POST' && path.startsWith('/api/admin/module-workshop/suggestions/') && path.endsWith('/accept')) {
        if (!caller.isRootAdmin) {
          return errorResponse('Nur Root-Admin darf Vorschlaege veroeffentlichen', 403);
        }
        try {
          const id = path.split('/')[5];
          if (!id) return errorResponse('id fehlt', 400);
          const sr = await fetch(
            `${SUPABASE_URL}/rest/v1/module_suggestions?id=eq.${encodeURIComponent(id)}&limit=1`,
            { headers: svcHeaders },
          );
          const arr = sr.ok ? await sr.json().catch(() => []) : [];
          const sug = Array.isArray(arr) && arr[0];
          if (!sug) return errorResponse('Vorschlag nicht gefunden', 404);
          if (sug.status !== 'pending') return errorResponse('Vorschlag bereits bearbeitet', 409);

          const world = sug.world;
          const tbl = tableForWorld(world);

          // Quality-Findings haben keinen Inhalt -> nur als erledigt markieren.
          if (sug.kind === 'quality') {
            await fetch(`${SUPABASE_URL}/rest/v1/module_suggestions?id=eq.${encodeURIComponent(id)}`, {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
              body: JSON.stringify({ status: 'accepted', reviewed_at: new Date().toISOString(), reviewed_by: caller.username }),
            });
            return jsonResponse({ success: true, action: 'quality_acknowledged' });
          }

          // new/improve: in die Modul-Tabelle schreiben.
          const branches = WORKSHOP_BRANCHES[world];
          // Branch darf bestehend ODER neues Thema (Freitext aus dem Vorschlag) sein.
          const accBranch = String(sug.branch || '').trim() || branches[0];
          const prefix = WORLD_CODE_PREFIX[world] || 'V-';
          const exR = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?select=module_code,branch,branch_order`,
            { headers: svcHeaders },
          );
          const exAll = exR.ok ? (await exR.json().catch(() => [])) : [];

          let moduleCode = sug.target_module_code;
          if (!moduleCode) {
            const nums = exAll.map(e => parseInt(String(e.module_code || '').replace(prefix, ''), 10)).filter(n => !isNaN(n));
            const nextNum = nums.length > 0 ? Math.max(...nums) + 1 : 1;
            moduleCode = `${prefix}${String(nextNum).padStart(2, '0')}`;
          }
          // branch_order: bei improve bestehende behalten, sonst ans Branch-Ende.
          let accBranchOrder;
          if (sug.target_module_code) {
            const cur = exAll.find(e => String(e.module_code).toUpperCase() === String(moduleCode).toUpperCase());
            accBranchOrder = (cur && Number.isFinite(Number(cur.branch_order))) ? Number(cur.branch_order) : 1;
          } else {
            const inBranch = exAll.filter(e => String(e.branch || '').trim() === accBranch)
              .map(e => Number(e.branch_order)).filter(n => Number.isFinite(n));
            accBranchOrder = inBranch.length > 0 ? Math.max(...inBranch) + 1 : 1;
          }
          // Tests fuer Vorhang/Ursprung garantieren (Pflicht).
          let accTests = normTestQuestions(sug.test_questions);
          if ((world === 'vorhang' || world === 'ursprung') && sug.kind !== 'quality' && accTests.length < 3) {
            accTests = await ensureTestQuestions(env, accTests, {
              title: sug.title || moduleCode, theory_content: sug.theory_content || '',
            });
          }
          const row = {
            module_code: moduleCode,
            branch: accBranch,
            branch_order: accBranchOrder,
            title: sug.title || moduleCode,
            subtitle: sug.subtitle || '',
            is_boss_module: false,
            xp_reward: sug.xp_reward || 100,
            prerequisites: [],
            theory_content: sug.theory_content || '',
            case_study: sug.case_study || '',
            exercise_description: sug.exercise_description || '',
            // test_questions ist NOT NULL -> immer ein Array mitschicken.
            test_questions: accTests,
            sources: normSources(sug.sources),
          };
          // W5: Bei 'improve' (Ueberschreiben) vorher Snapshot sichern.
          if (sug.target_module_code) {
            await snapshotModule(world, tbl, moduleCode, svcHeaders, caller.username);
          }
          const saveR = await fetch(`${SUPABASE_URL}/rest/v1/${tbl}?on_conflict=module_code`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
            body: JSON.stringify(row),
          });
          if (!saveR.ok) {
            const t = await saveR.text().catch(() => '');
            return errorResponse(`Modul speichern fehlgeschlagen: ${saveR.status} ${t.slice(0, 200)}`);
          }
          await fetch(`${SUPABASE_URL}/rest/v1/module_suggestions?id=eq.${encodeURIComponent(id)}`, {
            method: 'PATCH',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({ status: 'accepted', reviewed_at: new Date().toISOString(), reviewed_by: caller.username }),
          });
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: sug.kind === 'new' ? 'suggestion_accept_new' : 'suggestion_accept_improve',
            target_id: moduleCode,
            details: { world, suggestion_id: id },
          });
          return jsonResponse({ success: true, action: sug.target_module_code ? 'updated' : 'created', module_code: moduleCode });
        } catch (e) {
          return errorResponse(`suggestion accept Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/suggestions/:id/reject ─────
      if (method === 'POST' && path.startsWith('/api/admin/module-workshop/suggestions/') && path.endsWith('/reject')) {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const id = path.split('/')[5];
          if (!id) return errorResponse('id fehlt', 400);
          await fetch(`${SUPABASE_URL}/rest/v1/module_suggestions?id=eq.${encodeURIComponent(id)}`, {
            method: 'PATCH',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({ status: 'rejected', reviewed_at: new Date().toISOString(), reviewed_by: caller.username }),
          });
          return jsonResponse({ success: true, action: 'rejected' });
        } catch (e) {
          return errorResponse(`suggestion reject Fehler: ${e.message}`);
        }
      }

      // ── POST /api/admin/module-workshop/tool-request ───────────────
      // Vorschlag D: LOGIK-Modul anfragen -> GitHub-Issue-Bruecke.
      // Body: { world?, title, description }
      // Wenn env.GITHUB_TOKEN gesetzt: Issue automatisch erstellen.
      // Sonst: vorbefuellte GitHub-Issue-URL zurueckgeben (Admin klickt selbst).
      if (method === 'POST' && path === '/api/admin/module-workshop/tool-request') {
        if (!caller.isRootAdmin) {
          return errorResponse('Nur Root-Admin darf Tool-Anfragen stellen', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const title = String(body?.title || '').trim().slice(0, 120);
          const description = String(body?.description || '').trim().slice(0, 2000);
          const world = body?.world || null;
          const mode = body?.mode === 'extend' ? 'extend' : 'new';
          const target = String(body?.target || '').trim().slice(0, 120);
          const refine = body?.refine !== false; // default: KI-Spezifikation erzeugen
          if (title.length < 3 || description.length < 10) {
            return errorResponse('Titel (min 3) und Beschreibung (min 10) noetig', 400);
          }

          // KI-Spezifikation erzeugen, damit das Issue fuer Claude Code direkt
          // umsetzbar ist (Zweck, Eingaben, Ausgaben, Daten, UI, Akzeptanz).
          let refinedSpec = '';
          if (refine) {
            try {
              const sys = [
                'Du bist Tech-Lead und schreibst eine praezise Umsetzungs-Spezifikation',
                'fuer ein interaktives Flutter-Tool/Feature der Weltenbibliothek-App.',
                mode === 'extend'
                  ? `Es geht um die ERWEITERUNG eines bestehenden Tools: "${target}".`
                  : 'Es geht um ein NEUES Tool/Feature.',
                'Schreibe auf Deutsch, strukturiert in Markdown mit Abschnitten:',
                '## Zweck, ## Nutzer-Interaktion, ## Eingaben, ## Ausgaben/Berechnung,',
                '## Datenquellen/Tabellen (falls noetig), ## UI-Skizze, ## Akzeptanzkriterien.',
                'Konkret, knapp, umsetzbar. Keine Floskeln.',
              ].join('\n');
              // Zeitlich begrenzen (9s): die KI-Spec ist optional -- wenn eine
              // KI-Quelle lahmt, darf der Endpunkt NICHT in den Client-Timeout
              // laufen (sonst "HTTP 0"). Issue wird dann ohne Spec erstellt.
              refinedSpec = await Promise.race([
                aiText(env, sys,
                  `Welt: ${world || 'unbestimmt'}\nTitel: ${title}\nWunsch: ${description}`,
                  900),
                new Promise((resolve) => setTimeout(() => resolve(''), 9000)),
              ]);
            } catch (_) { refinedSpec = ''; }
          }

          const repo = 'manuelbrandner85/Weltenbibliothekapp';
          const issueTitle = `[${mode === 'extend' ? 'Tool-Erweiterung' : 'Tool-Anfrage'}] ${title}`;
          const issueBody = [
            `## ${mode === 'extend' ? 'Erweiterung eines Tools' : 'Neues interaktives Tool/Feature'}`,
            '',
            `**Welt:** ${world || 'unbestimmt'}`,
            mode === 'extend' && target ? `**Bestehendes Tool:** ${target}` : '',
            `**Angefragt von:** @${caller.username}`,
            '',
            '### Wunsch (Original)',
            description,
            '',
            refinedSpec ? '### KI-Spezifikation' : '',
            refinedSpec,
            '',
            '---',
            '_Erstellt aus der Funktions-Werkstatt im Admin-Dashboard.',
            'Braucht echten Code + App-Build durch Claude Code._',
            '',
            '<!-- claude-code: bitte dieses Tool/Feature implementieren und einen PR oeffnen -->',
          ].filter((l) => l !== '').join('\n');

          let issueUrl = null;
          let autoCreated = false;
          if (env.GITHUB_TOKEN) {
            try {
              const ghR = await fetch(`https://api.github.com/repos/${repo}/issues`, {
                method: 'POST',
                headers: {
                  'Authorization': `Bearer ${env.GITHUB_TOKEN}`,
                  'Accept': 'application/vnd.github+json',
                  'User-Agent': 'WeltenbibliothekWorker',
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  title: issueTitle,
                  body: issueBody,
                  labels: ['module-tool-request', 'claude-code'],
                }),
              });
              if (ghR.ok) {
                const data = await ghR.json().catch(() => ({}));
                issueUrl = data.html_url || null;
                autoCreated = true;
              } else {
                console.warn(`[tool-request] GitHub API ${ghR.status}`);
              }
            } catch (e) {
              console.warn(`[tool-request] GitHub Fehler: ${e.message}`);
            }
          }

          // Fallback: vorbefuellte "new issue"-URL (kein Secret noetig).
          const prefillUrl = `https://github.com/${repo}/issues/new?title=${encodeURIComponent(issueTitle)}&body=${encodeURIComponent(issueBody)}&labels=module-tool-request,claude-code`;

          // In tool_requests protokollieren.
          await fetch(`${SUPABASE_URL}/rest/v1/tool_requests`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              world, title, description,
              status: autoCreated ? 'issue_created' : 'open',
              github_issue_url: issueUrl,
              requested_by: caller.username,
            }),
          }).catch(() => {});

          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'tool_request',
            target_id: title,
            details: { world, auto_created: autoCreated },
          });

          return jsonResponse({
            success: true,
            auto_created: autoCreated,
            issue_url: issueUrl,
            refined_spec: refinedSpec || null,
            // Wenn nicht auto-erstellt: Admin oeffnet diese URL und klickt "Submit".
            prefill_url: autoCreated ? null : prefillUrl,
          });
        } catch (e) {
          return errorResponse(`tool-request Fehler: ${e.message}`);
        }
      }

      // ════════════════════════════════════════════════════════════════
      // INHALTE-VERWALTUNG (Materie/Energie Tool-Inhalte direkt editieren)
      // Generischer, whitelisted CRUD ueber Inhalts-/Referenz-Tabellen.
      // ════════════════════════════════════════════════════════════════
      // Whitelist je Welt: nur diese Tabellen sind editierbar.
      const CONTENT_TABLES = {
        energie: [
          { table: 'dream_symbols', label: 'Traumsymbole' },
          { table: 'astrology_meanings', label: 'Astrologie-Bedeutungen' },
          { table: 'soul_number_meanings', label: 'Numerologie-Bedeutungen' },
          { table: 'hd_meanings', label: 'Human-Design-Lexikon' },
          { table: 'shamanic_power_animals', label: 'Krafttiere' },
          { table: 'shamanic_journey_guides', label: 'Schamanen-Reisen' },
          { table: 'moon_rituals', label: 'Mond-Rituale' },
          { table: 'ancestral_rituals', label: 'Ahnen-Rituale' },
          { table: 'chakra_symptoms', label: 'Chakra-Symptome' },
        ],
        materie: [],
      };
      const isContentTableAllowed = (world, tbl) =>
        (CONTENT_TABLES[world] || []).some((t) => t.table === tbl);

      // GET /api/admin/content/tables?world=energie
      if (method === 'GET' && path === '/api/admin/content/tables') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Content-Editor-Rolle erforderlich', 403);
        }
        const world = String(url.searchParams.get('world') || '').toLowerCase();
        return jsonResponse({ success: true, tables: CONTENT_TABLES[world] || [] });
      }

      // GET /api/admin/content/rows?world=&table=&limit=
      if (method === 'GET' && path === '/api/admin/content/rows') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Content-Editor-Rolle erforderlich', 403);
        }
        try {
          const world = String(url.searchParams.get('world') || '').toLowerCase();
          const tbl = String(url.searchParams.get('table') || '');
          const limit = Math.min(500, Math.max(1, parseInt(url.searchParams.get('limit') || '200')));
          if (!isContentTableAllowed(world, tbl)) return errorResponse('Tabelle nicht erlaubt', 403);
          const r = await fetch(
            `${SUPABASE_URL}/rest/v1/${tbl}?select=*&limit=${limit}&order=id.desc`,
            { headers: svcHeaders });
          if (!r.ok) {
            // Fallback ohne order (manche Tabellen haben keine id-Spalte)
            const r2 = await fetch(`${SUPABASE_URL}/rest/v1/${tbl}?select=*&limit=${limit}`, { headers: svcHeaders });
            const rows2 = r2.ok ? await r2.json().catch(() => []) : [];
            const cols2 = rows2[0] ? Object.keys(rows2[0]) : [];
            return jsonResponse({ success: true, rows: rows2, columns: cols2 });
          }
          const rows = await r.json().catch(() => []);
          const columns = rows[0] ? Object.keys(rows[0]) : [];
          return jsonResponse({ success: true, rows, columns });
        } catch (e) { return errorResponse(`content rows Fehler: ${e.message}`); }
      }

      // POST /api/admin/content/row  { world, table, row, id? }  -> upsert
      if (method === 'POST' && path === '/api/admin/content/row') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Content-Editor-Rolle erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const world = String(body?.world || '').toLowerCase();
          const tbl = String(body?.table || '');
          const row = body?.row && typeof body.row === 'object' ? body.row : null;
          const id = body?.id;
          if (!isContentTableAllowed(world, tbl)) return errorResponse('Tabelle nicht erlaubt', 403);
          if (!row) return errorResponse('row fehlt', 400);
          // id niemals ueberschreiben beim Update
          const payload = { ...row };
          delete payload.created_at;
          let res;
          if (id !== undefined && id !== null && id !== '') {
            delete payload.id;
            res = await fetch(`${SUPABASE_URL}/rest/v1/${tbl}?id=eq.${encodeURIComponent(id)}`,
              { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify(payload) });
          } else {
            delete payload.id;
            res = await fetch(`${SUPABASE_URL}/rest/v1/${tbl}`,
              { method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify(payload) });
          }
          if (!res.ok) { const t = await res.text().catch(() => ''); return errorResponse(`Speichern ${res.status}: ${t.slice(0, 200)}`, res.status); }
          logAudit(svcHeaders, { admin_username: caller.username, action: id ? 'content_update' : 'content_create', target_id: tbl, details: { world } });
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`content row Fehler: ${e.message}`); }
      }

      // DELETE /api/admin/content/row?world=&table=&id=
      if (method === 'DELETE' && path === '/api/admin/content/row') {
        if (!['admin', 'root_admin'].includes(caller.role)) {
          return errorResponse('Admin-Rolle erforderlich', 403);
        }
        try {
          const world = String(url.searchParams.get('world') || '').toLowerCase();
          const tbl = String(url.searchParams.get('table') || '');
          const id = url.searchParams.get('id');
          if (!isContentTableAllowed(world, tbl)) return errorResponse('Tabelle nicht erlaubt', 403);
          if (!id) return errorResponse('id fehlt', 400);
          const res = await fetch(`${SUPABASE_URL}/rest/v1/${tbl}?id=eq.${encodeURIComponent(id)}`,
            { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
          if (!res.ok && res.status !== 204) return errorResponse(`Loeschen ${res.status}`, res.status);
          logAudit(svcHeaders, { admin_username: caller.username, action: 'content_delete', target_id: tbl, details: { world, id } });
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`content delete Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // TOOL-WERKSTATT (T1-T4): Verzeichnis, KI-Vorschlaege, Auto-Bau, Status
      // ════════════════════════════════════════════════════════════════
      const GH_REPO = 'manuelbrandner85/Weltenbibliothekapp';

      // Hilfs-Funktion: GitHub-Issue automatisch erstellen (Vollautomatik T3).
      // Gibt { url, number } oder null (kein Token / Fehler).
      async function createToolIssue(env, { title, world, mode, target, description, spec }) {
        if (!env.GITHUB_TOKEN) return null;
        const issueTitle = `[${mode === 'extend' ? 'Tool-Erweiterung' : 'Neues Tool'}] ${title}`;
        const issueBody = [
          `## ${mode === 'extend' ? 'Erweiterung eines Tools' : 'Neues interaktives Tool/Feature'}`,
          '', `**Welt:** ${world || 'unbestimmt'}`,
          mode === 'extend' && target ? `**Bestehendes Tool:** ${target}` : '',
          '', '### Wunsch', description || '',
          spec ? '\n### KI-Spezifikation\n' + spec : '',
          '', '---', '<!-- claude-code: bitte dieses Tool/Feature implementieren und einen PR oeffnen -->',
        ].filter((l) => l !== '').join('\n');
        try {
          const r = await fetch(`https://api.github.com/repos/${GH_REPO}/issues`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${env.GITHUB_TOKEN}`, 'Accept': 'application/vnd.github+json', 'User-Agent': 'WeltenbibliothekWorker', 'Content-Type': 'application/json' },
            body: JSON.stringify({ title: issueTitle, body: issueBody, labels: ['module-tool-request', 'claude-code'] }),
          });
          if (r.ok) { const d = await r.json().catch(() => ({})); return { url: d.html_url || null, number: d.number || null }; }
        } catch (_) {}
        return null;
      }

      // ── GET /api/admin/tools?world=  (T1: Verzeichnis) ──
      if (method === 'GET' && path === '/api/admin/tools') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) return errorResponse('Keine Berechtigung', 403);
        try {
          const world = String(url.searchParams.get('world') || '').toLowerCase();
          const filter = world ? `&world=eq.${encodeURIComponent(world)}` : '';
          const r = await fetch(`${SUPABASE_URL}/rest/v1/app_tools?select=*${filter}&order=category.asc,name.asc`, { headers: svcHeaders });
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({ success: true, tools: Array.isArray(rows) ? rows : [] });
        } catch (e) { return errorResponse(`tools GET Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/tools  (T1: Tool anlegen/bearbeiten) ──
      if (method === 'POST' && path === '/api/admin/tools') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) return errorResponse('Keine Berechtigung', 403);
        try {
          const b = await request.clone().json().catch(() => ({}));
          const id = b?.id;
          const row = {
            world: String(b?.world || '').toLowerCase(),
            category: String(b?.category || 'Allgemein').slice(0, 60),
            name: String(b?.name || '').slice(0, 120),
            description: String(b?.description || '').slice(0, 600),
            content_table: b?.content_table ? String(b.content_table).slice(0, 80) : null,
            status: ['live', 'geplant', 'im_bau'].includes(b?.status) ? b.status : 'live',
            updated_at: new Date().toISOString(),
          };
          if (!row.world || !row.name) return errorResponse('world + name noetig', 400);
          let res;
          if (id) {
            res = await fetch(`${SUPABASE_URL}/rest/v1/app_tools?id=eq.${encodeURIComponent(id)}`,
              { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify(row) });
          } else {
            res = await fetch(`${SUPABASE_URL}/rest/v1/app_tools?on_conflict=world,name`,
              { method: 'POST', headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' }, body: JSON.stringify(row) });
          }
          if (!res.ok) { const t = await res.text().catch(() => ''); return errorResponse(`tools speichern ${res.status}: ${t.slice(0, 200)}`, res.status); }
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`tools POST Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/tools?id=  ──
      if (method === 'DELETE' && path === '/api/admin/tools') {
        if (!['admin', 'root_admin'].includes(caller.role)) return errorResponse('Admin-Rolle erforderlich', 403);
        try {
          const id = url.searchParams.get('id');
          if (!id) return errorResponse('id fehlt', 400);
          await fetch(`${SUPABASE_URL}/rest/v1/app_tools?id=eq.${encodeURIComponent(id)}`,
            { method: 'DELETE', headers: { ...svcHeaders, 'Prefer': 'return=minimal' } });
          return jsonResponse({ success: true });
        } catch (e) { return errorResponse(`tools DELETE Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/tools/idea  (KI-Vorschlag im Erstellen/Aendern-Formular) ──
      // Body: { world, mode: 'new'|'extend', target? }
      // -> { title, description }  (neuer Tool-Vorschlag ODER Verbesserungs-Idee).
      if (method === 'POST' && path === '/api/admin/tools/idea') {
        if (!['admin', 'root_admin', 'content_editor'].includes(caller.role)) {
          return errorResponse('Keine Berechtigung', 403);
        }
        try {
          const b = await request.clone().json().catch(() => ({}));
          const world = String(b?.world || '').toLowerCase();
          const mode = b?.mode === 'extend' ? 'extend' : 'new';
          const target = String(b?.target || '').trim();
          const worldCtx = WORLD_TOOL_CONTEXT[world] || `die "${world}"-Welt`;
          // Bestehende Tools als Kontext (Duplikate vermeiden / passend bleiben).
          const r = await fetch(`${SUPABASE_URL}/rest/v1/app_tools?select=name,description&world=eq.${encodeURIComponent(world)}`, { headers: svcHeaders });
          const existing = r.ok ? await r.json().catch(() => []) : [];
          const names = existing.map((t) => t.name).join(', ');
          let sys, user;
          if (mode === 'extend' && target) {
            const cur = existing.find((t) => String(t.name).toLowerCase() === target.toLowerCase());
            sys = `Du schlaegst eine konkrete, umsetzbare Verbesserung fuer ein bestehendes App-Tool aus ${worldCtx} vor. ` +
              'Antworte als JSON-Objekt: { "title": "kurzer Titel der Verbesserung", "description": "2-4 Saetze was konkret verbessert/ergaenzt wird" }. Deutsch.';
            user = `Welt: ${world}\nTool: ${target}\nAktuelle Beschreibung: ${cur?.description || '(unbekannt)'}\n\nSchlage EINE sinnvolle Verbesserung vor.`;
          } else {
            sys = `Du schlaegst EIN neues, passendes interaktives Tool fuer ${worldCtx} vor (kein Duplikat). ` +
              'Antworte als JSON-Objekt: { "title": "kurzer Tool-Name", "description": "2-4 Saetze was es tut, Eingaben/Ausgaben" }. Deutsch.';
            user = `Bestehende Tools: ${names || '(keine)'}\n\nSchlage ein neues Tool vor das gut zur Welt passt und noch fehlt.`;
          }
          const idea = await aiJson(env, sys, user, 600);
          return jsonResponse({
            success: true,
            title: String(idea.title || '').slice(0, 120),
            description: String(idea.description || '').slice(0, 1500),
          });
        } catch (e) { return errorResponse(`tools idea Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/tools/scan  (T2: KI schlaegt neue Tools vor) ──
      if (method === 'POST' && path === '/api/admin/tools/scan') {
        if (!['admin', 'root_admin'].includes(caller.role)) return errorResponse('Admin-Rolle erforderlich', 403);
        try {
          const b = await request.clone().json().catch(() => ({}));
          const world = String(b?.world || '').toLowerCase();
          if (!['materie', 'energie', 'vorhang', 'ursprung'].includes(world)) return errorResponse('world ungueltig', 400);
          const r = await fetch(`${SUPABASE_URL}/rest/v1/app_tools?select=name,category&world=eq.${world}`, { headers: svcHeaders });
          const existing = r.ok ? await r.json().catch(() => []) : [];
          const names = existing.map((t) => t.name).join(', ');
          const sys = [
            `Du planst neue interaktive Tools/Features fuer ${WORLD_TOOL_CONTEXT[world] || `die "${world}"-Welt`} (Weltenbibliothek-App).`,
            'Schlage GENAU 3 NEUE, konkrete Tools vor, die thematisch zur Welt passen und den Bestand sinnvoll ergaenzen (keine Duplikate).',
            'Antworte als JSON-Array von 3 Objekten:',
            '{ "name": "kurzer Tool-Name", "category": "Kategorie", "description": "1-2 Saetze was es tut", "rationale": "warum es fehlt/passt" }. Deutsch.',
          ].join('\n');
          const arr = await aiJson(env, sys, `Bestehende Tools: ${names || '(keine)'}\n\nWelche 3 Tools fehlen?`, 800);
          const ideas = (Array.isArray(arr) ? arr : []).slice(0, 3)
            .map((i) => ({
              world, category: String(i.category || 'Allgemein').slice(0, 60),
              name: String(i.name || '').slice(0, 120), description: String(i.description || '').slice(0, 400),
              rationale: String(i.rationale || '').slice(0, 400), status: 'pending',
            })).filter((i) => i.name);
          if (ideas.length > 0) {
            await fetch(`${SUPABASE_URL}/rest/v1/tool_suggestions`,
              { method: 'POST', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify(ideas) });
          }
          return jsonResponse({ success: true, created: ideas.length });
        } catch (e) { return errorResponse(`tools scan Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/tools/suggestions?world=  ──
      if (method === 'GET' && path === '/api/admin/tools/suggestions') {
        if (!['admin', 'root_admin'].includes(caller.role)) return errorResponse('Admin-Rolle erforderlich', 403);
        try {
          const world = String(url.searchParams.get('world') || '').toLowerCase();
          const filter = world ? `&world=eq.${encodeURIComponent(world)}` : '';
          const r = await fetch(`${SUPABASE_URL}/rest/v1/tool_suggestions?select=*&status=eq.pending${filter}&order=created_at.desc`, { headers: svcHeaders });
          const rows = r.ok ? await r.json().catch(() => []) : [];
          return jsonResponse({ success: true, suggestions: Array.isArray(rows) ? rows : [] });
        } catch (e) { return errorResponse(`tool-suggestions Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/tools/suggestions/:id/(accept|reject) (T2->T3) ──
      if (method === 'POST' && path.startsWith('/api/admin/tools/suggestions/') &&
          (path.endsWith('/accept') || path.endsWith('/reject'))) {
        if (!caller.isRootAdmin) return errorResponse('Nur Root-Admin', 403);
        try {
          const parts = path.split('/');
          const id = parts[5];
          const action = parts[6];
          const sr = await fetch(`${SUPABASE_URL}/rest/v1/tool_suggestions?id=eq.${encodeURIComponent(id)}&limit=1`, { headers: svcHeaders });
          const arr = sr.ok ? await sr.json().catch(() => []) : [];
          const sug = Array.isArray(arr) && arr[0];
          if (!sug) return errorResponse('Vorschlag nicht gefunden', 404);
          if (action === 'reject') {
            await fetch(`${SUPABASE_URL}/rest/v1/tool_suggestions?id=eq.${encodeURIComponent(id)}`,
              { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify({ status: 'rejected' }) });
            return jsonResponse({ success: true, action: 'rejected' });
          }
          // accept -> Issue auto-erstellen (Vollautomatik) + in app_tools als 'im_bau'
          const issue = await createToolIssue(env, {
            title: sug.name, world: sug.world, mode: 'new',
            description: sug.description, spec: sug.rationale,
          });
          await fetch(`${SUPABASE_URL}/rest/v1/tool_suggestions?id=eq.${encodeURIComponent(id)}`,
            { method: 'PATCH', headers: { ...svcHeaders, 'Prefer': 'return=minimal' }, body: JSON.stringify({ status: 'accepted', github_issue_url: issue?.url || null }) });
          // im Verzeichnis als geplant/im_bau vermerken
          await fetch(`${SUPABASE_URL}/rest/v1/app_tools?on_conflict=world,name`,
            { method: 'POST', headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify({ world: sug.world, category: sug.category || 'Allgemein', name: sug.name, description: sug.description || '', status: issue ? 'im_bau' : 'geplant' }) }).catch(() => {});
          logAudit(svcHeaders, { admin_username: caller.username, action: 'tool_suggestion_accept', target_id: sug.name, details: { world: sug.world, auto_issue: !!issue } });
          return jsonResponse({ success: true, action: 'accepted', auto_created: !!issue, issue_url: issue?.url || null });
        } catch (e) { return errorResponse(`tool-suggestion accept Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/tools/requests?world=  (T3: Status der Anfragen) ──
      if (method === 'GET' && path === '/api/admin/tools/requests') {
        if (!['admin', 'root_admin'].includes(caller.role)) return errorResponse('Admin-Rolle erforderlich', 403);
        try {
          const world = String(url.searchParams.get('world') || '').toLowerCase();
          const filter = world ? `&world=eq.${encodeURIComponent(world)}` : '';
          const r = await fetch(`${SUPABASE_URL}/rest/v1/tool_requests?select=*${filter}&order=created_at.desc&limit=30`, { headers: svcHeaders });
          const rows = r.ok ? await r.json().catch(() => []) : [];
          // Best-effort: GitHub-Issue-Status nachladen (offen/geschlossen + PR).
          const out = [];
          for (const req of (Array.isArray(rows) ? rows : [])) {
            let state = null, prUrl = null;
            const m = String(req.github_issue_url || '').match(/\/issues\/(\d+)/);
            if (m && env.GITHUB_TOKEN) {
              try {
                const gr = await fetch(`https://api.github.com/repos/${GH_REPO}/issues/${m[1]}`,
                  { headers: { 'Authorization': `Bearer ${env.GITHUB_TOKEN}`, 'Accept': 'application/vnd.github+json', 'User-Agent': 'WeltenbibliothekWorker' } });
                if (gr.ok) { const gd = await gr.json().catch(() => ({})); state = gd.state || null; prUrl = gd.pull_request?.html_url || null; }
              } catch (_) {}
            }
            out.push({ ...req, gh_state: state, pr_url: prUrl });
          }
          return jsonResponse({ success: true, requests: out });
        } catch (e) { return errorResponse(`tool-requests Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v123: NEW ENDPOINTS -- Shadow-ban, Temp-Mute, Bulk, Feature Flags,
      //   Announcements, Insights, Health (enriched).
      // ════════════════════════════════════════════════════════════════

      // ── POST /api/admin/users/:userId/shadow-ban ─────────────────
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/shadow-ban')) {
        if (!caller.isRootAdmin) return errorResponse('Root-Admin erforderlich', 403);
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          const body = await request.json().catch(() => ({}));
          const enable = body.enable !== false;
          const patchRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({ shadow_banned: enable }),
          });
          if (!patchRes.ok) return errorResponse(`Shadow-ban patch failed: ${patchRes.status}`);
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: enable ? 'shadow_ban' : 'shadow_unban',
            target_id: userId,
            details: { enable },
            undo_payload: JSON.stringify({ action: enable ? 'shadow_unban' : 'shadow_ban', user_id: userId }),
          });
          return jsonResponse({ success: true, shadow_banned: enable, user_id: userId });
        } catch (e) { return errorResponse(`Shadow-ban Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/:userId/temp-mute ──────────────────
      // duration_minutes=0 = unmute
      if (method === 'POST' && path.includes('/users/') && path.endsWith('/temp-mute')) {
        try {
          const rawUserId = path.split('/')[4];
          if (!rawUserId) return errorResponse('userId fehlt', 400);
          const userId = await resolveProfileUuid(rawUserId, svcHeaders) ?? rawUserId;
          const body = await request.json().catch(() => ({}));
          const durationMinutes = Math.max(0, Math.min(10080, Number(body.duration_minutes) || 60));
          const mutedUntil = durationMinutes > 0
            ? new Date(Date.now() + durationMinutes * 60 * 1000).toISOString()
            : null;
          const patchRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
            method: 'PATCH',
            headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
            body: JSON.stringify({ muted_until: mutedUntil }),
          });
          if (!patchRes.ok) return errorResponse(`Temp-mute patch failed: ${patchRes.status}`);
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: durationMinutes > 0 ? 'temp_mute' : 'temp_unmute',
            target_id: userId,
            details: { duration_minutes: durationMinutes, muted_until: mutedUntil, reason: body.reason },
            undo_payload: JSON.stringify({ action: 'temp_unmute', user_id: userId }),
          });
          return jsonResponse({ success: true, muted_until: mutedUntil, user_id: userId });
        } catch (e) { return errorResponse(`Temp-mute Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/bulk-warn ──────────────────────────
      if (method === 'POST' && path === '/api/admin/users/bulk-warn') {
        try {
          const body = await request.json().catch(() => ({}));
          const userIds = Array.isArray(body.user_ids) ? body.user_ids : [];
          const reason = String(body.reason || 'Regelverstoß (Bulk)').slice(0, 500);
          if (userIds.length === 0) return errorResponse('user_ids erforderlich', 400);
          let warned = 0;
          for (const rawUid of userIds) {
            try {
              const uid = await resolveProfileUuid(rawUid, svcHeaders) ?? rawUid;
              // Insert into admin_warnings
              await fetch(`${SUPABASE_URL}/rest/v1/admin_warnings`, {
                method: 'POST',
                headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
                body: JSON.stringify({
                  user_id: uid,
                  warned_by: caller.userId,
                  reason,
                  created_at: new Date().toISOString(),
                }),
              });
              warned++;
            } catch (_) {}
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'bulk_warn',
            details: { count: warned, reason, user_ids: userIds.slice(0, 10) },
          });
          return jsonResponse({ success: true, warned });
        } catch (e) { return errorResponse(`Bulk-warn Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/users/bulk-role ──────────────────────────
      if (method === 'POST' && path === '/api/admin/users/bulk-role') {
        try {
          const body = await request.json().catch(() => ({}));
          const userIds = Array.isArray(body.user_ids) ? body.user_ids : [];
          const newRole = String(body.role || '').toLowerCase().replace('-', '_');
          const allowedRoles = ['user', 'moderator', 'content_editor', 'admin', 'root_admin'];
          if (!allowedRoles.includes(newRole)) return errorResponse('Ungueltige Rolle', 400);
          if (userIds.length === 0) return errorResponse('user_ids erforderlich', 400);
          // Role hierarchy check
          const callerLevel = caller.isRootAdmin ? 3 : caller.role === 'admin' ? 2 : 1;
          const targetLevel = newRole === 'root_admin' ? 3 : newRole === 'admin' ? 2 : 1;
          if (targetLevel >= callerLevel) return errorResponse('Unzureichende Berechtigung', 403);
          let changed = 0;
          for (const rawUid of userIds) {
            try {
              const uid = await resolveProfileUuid(rawUid, svcHeaders) ?? rawUid;
              const res = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${uid}`, {
                method: 'PATCH',
                headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
                body: JSON.stringify({ role: newRole }),
              });
              if (res.ok) changed++;
            } catch (_) {}
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'bulk_role_change',
            details: { new_role: newRole, count: changed, user_ids: userIds.slice(0, 10) },
          });
          return jsonResponse({ success: true, changed, new_role: newRole });
        } catch (e) { return errorResponse(`Bulk-role Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/feature-flags ──────────────────────────────
      if (method === 'GET' && path === '/api/admin/feature-flags') {
        try {
          const res = await fetch(`${SUPABASE_URL}/rest/v1/feature_flags?select=*&order=key.asc`, {
            headers: svcHeaders,
          });
          const flags = res.ok ? await res.json() : [];
          return jsonResponse({ success: true, flags });
        } catch (e) { return errorResponse(`Feature-flags Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/feature-flags/:key ────────────────────────
      if (method === 'POST' && path.startsWith('/api/admin/feature-flags/')) {
        if (!caller.isRootAdmin) return errorResponse('Root-Admin erforderlich', 403);
        try {
          const key = path.split('/').pop();
          if (!key) return errorResponse('key fehlt', 400);
          const body = await request.json().catch(() => ({}));
          const enabled = body.enabled !== false;
          const world = body.world || null;
          const value = body.value || null;
          const upsertRes = await fetch(`${SUPABASE_URL}/rest/v1/feature_flags`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
            body: JSON.stringify({
              key,
              enabled,
              world,
              value,
              updated_by: caller.username,
              updated_at: new Date().toISOString(),
            }),
          });
          if (!upsertRes.ok) return errorResponse(`Feature-flag upsert failed: ${upsertRes.status}`);
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: enabled ? 'feature_flag_enable' : 'feature_flag_disable',
            details: { key, world, value },
            undo_payload: JSON.stringify({ action: enabled ? 'feature_flag_disable' : 'feature_flag_enable', key, world }),
          });
          return jsonResponse({ success: true, key, enabled });
        } catch (e) { return errorResponse(`Feature-flag Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/announcements ──────────────────────────────
      if (method === 'GET' && path === '/api/admin/announcements') {
        try {
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/scheduled_announcements?select=*&order=run_at.asc&limit=100`,
            { headers: svcHeaders }
          );
          const announcements = res.ok ? await res.json() : [];
          return jsonResponse({ success: true, announcements });
        } catch (e) { return errorResponse(`Announcements Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/announcements ─────────────────────────────
      if (method === 'POST' && path === '/api/admin/announcements') {
        try {
          const body = await request.json().catch(() => ({}));
          const title = String(body.title || '').slice(0, 200);
          const msgBody = String(body.body || '').slice(0, 2000);
          const runAt = body.run_at ? new Date(body.run_at).toISOString() : new Date(Date.now() + 3600000).toISOString();
          if (!title || !msgBody) return errorResponse('title und body erforderlich', 400);
          const insRes = await fetch(`${SUPABASE_URL}/rest/v1/scheduled_announcements`, {
            method: 'POST',
            headers: { ...svcHeaders, 'Prefer': 'return=representation' },
            body: JSON.stringify({
              title,
              body: msgBody,
              run_at: runAt,
              world: body.world || null,
              push: body.push === true,
              sent: false,
              created_by: caller.username,
            }),
          });
          const row = insRes.ok ? (await insRes.json())[0] : null;
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'announcement_scheduled',
            details: { title, run_at: runAt, world: body.world },
          });
          return jsonResponse({ success: insRes.ok, announcement: row });
        } catch (e) { return errorResponse(`Announcement Fehler: ${e.message}`); }
      }

      // ── DELETE /api/admin/announcements/:id ───────────────────────
      if (method === 'DELETE' && path.startsWith('/api/admin/announcements/')) {
        try {
          const id = path.split('/').pop();
          if (!id) return errorResponse('id fehlt', 400);
          const delRes = await fetch(
            `${SUPABASE_URL}/rest/v1/scheduled_announcements?id=eq.${id}&sent=eq.false`,
            { method: 'DELETE', headers: svcHeaders }
          );
          return jsonResponse({ success: delRes.ok });
        } catch (e) { return errorResponse(`Announcement-Delete Fehler: ${e.message}`); }
      }

      // ── POST /api/admin/audit-log/:id/undo ──────────────────────
      if (method === 'POST' && path.includes('/audit-log/') && path.endsWith('/undo')) {
        if (!caller.isRootAdmin) return errorResponse('Root-Admin erforderlich', 403);
        try {
          const parts = path.split('/');
          const entryId = parts[parts.length - 2];
          // Fetch entry to get undo_payload
          const res = await fetch(
            `${SUPABASE_URL}/rest/v1/admin_audit_log?id=eq.${encodeURIComponent(entryId)}&select=*&limit=1`,
            { headers: svcHeaders }
          );
          const rows = res.ok ? await res.json() : [];
          const entry = rows[0];
          if (!entry) return errorResponse('Eintrag nicht gefunden', 404);
          const undoPayload = entry.undo_payload;
          if (!undoPayload) return errorResponse('Keine Undo-Information vorhanden', 422);
          let payload;
          try { payload = typeof undoPayload === 'string' ? JSON.parse(undoPayload) : undoPayload; } catch (_) {
            return errorResponse('Undo-Payload konnte nicht geparst werden', 422);
          }
          // Execute undo based on action
          const undoAction = payload.action;
          if (undoAction === 'shadow_unban' || undoAction === 'shadow_ban') {
            const enable = undoAction === 'shadow_ban';
            await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${payload.user_id}`, {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
              body: JSON.stringify({ shadow_banned: enable }),
            });
          } else if (undoAction === 'temp_unmute') {
            await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${payload.user_id}`, {
              method: 'PATCH',
              headers: { ...svcHeaders, 'Prefer': 'return=minimal' },
              body: JSON.stringify({ muted_until: null }),
            });
          } else if (undoAction === 'feature_flag_enable' || undoAction === 'feature_flag_disable') {
            const enable = undoAction === 'feature_flag_enable';
            await fetch(`${SUPABASE_URL}/rest/v1/feature_flags`, {
              method: 'POST',
              headers: { ...svcHeaders, 'Prefer': 'resolution=merge-duplicates,return=minimal' },
              body: JSON.stringify({ key: payload.key, enabled: enable, world: payload.world, updated_by: caller.username, updated_at: new Date().toISOString() }),
            });
          } else {
            return errorResponse(`Undo fuer Aktion '${undoAction}' nicht unterstuetzt`, 422);
          }
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: `undo_${entry.action || 'action'}`,
            details: { original_entry_id: entryId, undo_action: undoAction },
          });
          return jsonResponse({ success: true, undo_action: undoAction });
        } catch (e) { return errorResponse(`Undo Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/insights ───────────────────────────────────
      if (method === 'GET' && path === '/api/admin/insights') {
        try {
          // Parallel fetch for all insights data.
          const now = new Date();
          const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).toISOString();
          const weekAgo = new Date(Date.now() - 7 * 86400000).toISOString();
          const [usersRes, todayRes, weekRes, activityRes, videosRes] = await Promise.allSettled([
            fetch(`${SUPABASE_URL}/rest/v1/profiles?select=count&head=true`, { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/profiles?select=count&created_at=gte.${todayStart}&head=true`, { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/profiles?select=count&created_at=gte.${weekAgo}&head=true`, { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/user_activity_log?select=world,created_at&created_at=gte.${weekAgo}&limit=5000`, { headers: svcHeaders }),
            fetch(`${SUPABASE_URL}/rest/v1/archive_videos?select=youtube_title,worlds&status=eq.confirmed&order=created_at.desc&limit=5`, { headers: svcHeaders }),
          ]);

          const totalUsers = usersRes.status === 'fulfilled' && usersRes.value.ok
            ? parseInt(usersRes.value.headers.get('content-range')?.split('/')[1] || '0')
            : 0;
          const usersToday = todayRes.status === 'fulfilled' && todayRes.value.ok
            ? parseInt(todayRes.value.headers.get('content-range')?.split('/')[1] || '0')
            : 0;
          const usersWeek = weekRes.status === 'fulfilled' && weekRes.value.ok
            ? parseInt(weekRes.value.headers.get('content-range')?.split('/')[1] || '0')
            : 0;

          // World comparison from activity log
          const activityRows = activityRes.status === 'fulfilled' && activityRes.value.ok
            ? await activityRes.value.json() : [];
          const worldCounts = {};
          for (const row of activityRows) {
            const w = row.world || 'unknown';
            worldCounts[w] = (worldCounts[w] || 0) + 1;
          }
          const worlds = {};
          for (const [w, count] of Object.entries(worldCounts)) {
            worlds[w] = { users: 0, active_today: count };
          }

          // Heatmap from activity log (hour x weekday)
          const heatmap = [];
          const heatmapCells = {};
          for (const row of activityRows) {
            try {
              const dt = new Date(row.created_at);
              const wd = dt.getDay() || 7; // 1=Mon, 7=Sun
              const h = dt.getHours();
              const k = `${wd}-${h}`;
              heatmapCells[k] = (heatmapCells[k] || 0) + 1;
            } catch (_) {}
          }
          for (const [k, count] of Object.entries(heatmapCells)) {
            const [wd, h] = k.split('-').map(Number);
            heatmap.push({ weekday: wd, hour: h, count });
          }

          // Top videos
          const topVideos = videosRes.status === 'fulfilled' && videosRes.value.ok
            ? (await videosRes.value.json()).map(v => ({ title: v.youtube_title, plays: 0 }))
            : [];

          return jsonResponse({
            success: true,
            growth: {
              total_users: totalUsers,
              users_today: usersToday,
              users_week: usersWeek,
              daily_new: [],
            },
            heatmap,
            worlds,
            top_articles: [],
            top_videos: topVideos,
          });
        } catch (e) { return errorResponse(`Insights Fehler: ${e.message}`); }
      }

      // ── GET /api/admin/health (enriched) ──────────────────────────
      if (method === 'GET' && path === '/api/admin/health') {
        try {
          const checks = await Promise.allSettled([
            fetch(`${SUPABASE_URL}/rest/v1/profiles?select=count&limit=1`, { headers: svcHeaders, signal: AbortSignal.timeout(5000) }),
          ]);
          const dbOk = checks[0].status === 'fulfilled' && checks[0].value.ok;
          return jsonResponse({
            success: true,
            services: {
              supabase: { status: dbOk ? 'green' : 'red', label: dbOk ? 'Verbunden' : 'Fehler' },
              worker: { status: 'green', label: 'Laufend' },
            },
            timestamp: new Date().toISOString(),
          });
        } catch (e) { return errorResponse(`Health Fehler: ${e.message}`); }
      }

      // ════════════════════════════════════════════════════════════════
      // v124: SENSITIVE ADMIN -- Impersonation (read-only) + IP/Device-Linking
      // ════════════════════════════════════════════════════════════════

      // ── POST /api/admin/impersonation/start ──────────────────────
      // Body: { target_user_id }
      // Schreibt Audit-Eintrag (action='impersonation_view') und gibt OK
      // zurueck. Der Client zeigt danach einen read-only Snapshot des Users
      // an -- KEIN echter Login-Wechsel, keine Schreibrechte.
      if (method === 'POST' && path === '/api/admin/impersonation/start') {
        if (!caller.isRootAdmin) {
          return errorResponse('Root-Admin erforderlich', 403);
        }
        try {
          const body = await request.clone().json().catch(() => ({}));
          const targetId = String(body.target_user_id || '').trim();
          if (!targetId) return errorResponse('target_user_id fehlt', 400);
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'impersonation_view',
            target_id: targetId,
            details: {
              reason: String(body.reason || '').slice(0, 240) || null,
              read_only: true,
            },
          });
          return jsonResponse({
            success: true,
            target_user_id: targetId,
            read_only: true,
          });
        } catch (e) {
          return errorResponse(`Impersonation-Start Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/users/:userId/linked-accounts ─────────────
      // Findet andere Profile die SHA256-gleiche ip_hash oder ua_hash
      // teilen. Liefert pseudonyme Treffer (nur Profil-ID/Username/Avatar,
      // KEINE Klartext-IPs). Root-Admin only. 90-Tage-Fenster.
      if (method === 'GET' && path.startsWith('/api/admin/users/') &&
          path.endsWith('/linked-accounts')) {
        if (!caller.isRootAdmin) {
          return errorResponse('Root-Admin erforderlich', 403);
        }
        try {
          const userId = path.split('/')[4];
          if (!userId) return errorResponse('userId fehlt', 400);

          // Audit log fuer DSGVO-Nachweis: jede Abfrage protokollieren.
          logAudit(svcHeaders, {
            admin_username: caller.username,
            action: 'linked_accounts_query',
            target_id: userId,
            details: {},
          });

          // 1) Alle Sessions des Ziel-Users holen (max 200, last 90d).
          const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
              .toISOString();
          const ownRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profile_sessions?profile_id=eq.${encodeURIComponent(userId)}&last_seen=gte.${encodeURIComponent(cutoff)}&select=ip_hash,ua_hash,first_seen,last_seen&order=last_seen.desc&limit=200`,
            { headers: svcHeaders },
          );
          const ownSessions = ownRes.ok ? await ownRes.json().catch(() => []) : [];
          if (!Array.isArray(ownSessions) || ownSessions.length === 0) {
            return jsonResponse({
              success: true,
              linked: [],
              own_sessions: 0,
              note: 'Keine Sessions in den letzten 90 Tagen.',
            });
          }
          const ipHashes = [...new Set(ownSessions.map(s => s.ip_hash))];

          // 2) Andere Profile mit gleicher ip_hash finden.
          const ipList = ipHashes
              .slice(0, 50)
              .map(h => `"${h}"`)
              .join(',');
          const matchRes = await fetch(
            `${SUPABASE_URL}/rest/v1/profile_sessions?ip_hash=in.(${ipList})&profile_id=neq.${encodeURIComponent(userId)}&last_seen=gte.${encodeURIComponent(cutoff)}&select=profile_id,ip_hash,ua_hash,first_seen,last_seen&order=last_seen.desc&limit=500`,
            { headers: svcHeaders },
          );
          const matches = matchRes.ok ? await matchRes.json().catch(() => []) : [];

          // 3) Aggregieren pro profile_id.
          const byProfile = new Map();
          for (const m of matches) {
            const pid = m.profile_id;
            if (!byProfile.has(pid)) {
              byProfile.set(pid, {
                profile_id: pid,
                shared_ips: new Set(),
                shared_uas: new Set(),
                first_seen: m.first_seen,
                last_seen: m.last_seen,
                hit_count: 0,
              });
            }
            const agg = byProfile.get(pid);
            agg.shared_ips.add(m.ip_hash);
            agg.shared_uas.add(m.ua_hash);
            agg.hit_count += 1;
            if (m.last_seen > agg.last_seen) agg.last_seen = m.last_seen;
            if (m.first_seen < agg.first_seen) agg.first_seen = m.first_seen;
          }
          const linkedIds = [...byProfile.keys()].slice(0, 50);

          // 4) Anreichern: username/role/avatar fuer Anzeige (kein PII darueber hinaus).
          let profilesById = {};
          if (linkedIds.length > 0) {
            const idList = linkedIds.map(i => encodeURIComponent(i)).join(',');
            const profRes = await fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=in.(${idList})&select=id,username,display_name,role,avatar_emoji,created_at`,
              { headers: svcHeaders },
            );
            const profRows = profRes.ok ? await profRes.json().catch(() => []) : [];
            for (const p of profRows) {
              profilesById[p.id] = p;
            }
          }
          const linked = linkedIds.map(pid => {
            const agg = byProfile.get(pid);
            const profile = profilesById[pid] || {};
            return {
              profile_id: pid,
              username: profile.username || null,
              display_name: profile.display_name || null,
              role: profile.role || null,
              avatar_emoji: profile.avatar_emoji || null,
              created_at: profile.created_at || null,
              shared_ip_count: agg.shared_ips.size,
              shared_ua_count: agg.shared_uas.size,
              hit_count: agg.hit_count,
              first_seen: agg.first_seen,
              last_seen: agg.last_seen,
            };
          });

          return jsonResponse({
            success: true,
            own_sessions: ownSessions.length,
            linked,
            window_days: 90,
          });
        } catch (e) {
          return errorResponse(`Linked-Accounts Fehler: ${e.message}`);
        }
      }

      // ── GET /api/admin/users/:userId/impersonation-snapshot ──────
      // Read-only Snapshot fuer "View as User" -- nur Daten die der User
      // selber sehen wuerde: Aktivitaet, Notification-Prefs, Module-Progress.
      if (method === 'GET' && path.startsWith('/api/admin/users/') &&
          path.endsWith('/impersonation-snapshot')) {
        if (!caller.isRootAdmin) {
          return errorResponse('Root-Admin erforderlich', 403);
        }
        try {
          const userId = path.split('/')[4];
          if (!userId) return errorResponse('userId fehlt', 400);

          const [actRes, prefRes, progRes] = await Promise.allSettled([
            fetch(
              `${SUPABASE_URL}/rest/v1/user_activity_log?user_id=eq.${encodeURIComponent(userId)}&select=kind,world,label,created_at&order=created_at.desc&limit=30`,
              { headers: svcHeaders },
            ),
            // Profile selection: stick to fields that are guaranteed to exist
            // post-v128. notification_preferences / locale may not exist on
            // every schema -- the snapshot is best-effort.
            fetch(
              `${SUPABASE_URL}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=xp,world,created_at,last_seen_at`,
              { headers: svcHeaders },
            ),
            fetch(
              `${SUPABASE_URL}/rest/v1/user_module_progress?user_id=eq.${encodeURIComponent(userId)}&select=module_code,status,progress_percent,updated_at&order=updated_at.desc&limit=20`,
              { headers: svcHeaders },
            ),
          ]);

          const activity = actRes.status === 'fulfilled' && actRes.value.ok
              ? await actRes.value.json().catch(() => []) : [];
          const prefRows = prefRes.status === 'fulfilled' && prefRes.value.ok
              ? await prefRes.value.json().catch(() => []) : [];
          const modules = progRes.status === 'fulfilled' && progRes.value.ok
              ? await progRes.value.json().catch(() => []) : [];

          return jsonResponse({
            success: true,
            user_id: userId,
            read_only: true,
            activity: Array.isArray(activity) ? activity : [],
            prefs: Array.isArray(prefRows) && prefRows.length > 0
                ? prefRows[0] : {},
            modules: Array.isArray(modules) ? modules : [],
          });
        } catch (e) {
          return errorResponse(`Snapshot Fehler: ${e.message}`);
        }
      }

      // ── POST /api/activity/log  (v95 Echtzeit Activity Tracking) ──
      // Body: { user_id?, username?, kind, world, label, metadata?, xp, ts }
      // Schreibt in user_activity_log + addiert xp via fn_add_xp (RPC).
      // Idempotenz: keine -- die App soll selbst dedupen (z.B. tool_open
      // pro Session max 1x).
      if (method === 'POST' && path === '/api/activity/log') {
        try {
          const data = await request.json().catch(() => null);
          if (!data) return errorResponse('Invalid JSON', 400);
          const serviceKey =
              env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY || '';
          if (!serviceKey) return errorResponse('Service-Key fehlt', 500);
          const auth = {
            'Content-Type': 'application/json',
            'apikey': serviceKey,
            'Authorization': `Bearer ${serviceKey}`,
          };
          const userId = data.user_id || null;
          const username = data.username || null;
          const xp = Math.max(0, Math.min(500, Number(data.xp) || 0));

          // 1) Activity-Row einfuegen (best-effort).
          const insertRes = await fetch(
              `${SUPABASE_URL}/rest/v1/user_activity_log`, {
            method: 'POST',
            headers: { ...auth, 'Prefer': 'return=minimal' },
            body: JSON.stringify({
              user_id: userId,
              username,
              kind: String(data.kind || 'custom').substring(0, 40),
              world: String(data.world || 'meta').substring(0, 20),
              label: String(data.label || '').substring(0, 120),
              metadata: data.metadata || {},
              xp,
              created_at: data.ts || new Date().toISOString(),
            }),
          });
          const inserted = insertRes.ok;

          // 2) XP addieren -- nur wenn user_id (UUID) vorhanden.
          let xpAdded = false;
          if (xp > 0 && userId) {
            try {
              const rpcRes = await fetch(
                  `${SUPABASE_URL}/rest/v1/rpc/fn_add_user_xp`, {
                method: 'POST',
                headers: auth,
                body: JSON.stringify({
                  p_user_id: userId,
                  p_amount: xp,
                  p_source: data.label || data.kind || 'activity',
                }),
              });
              xpAdded = rpcRes.ok;
            } catch (_) { /* RPC fehlt eventuell -- okay */ }
          }
          // v124: pseudonymer Device-Fingerprint fuer Multi-Account-Erkennung.
          // Best-effort -- blockiert nie das Activity-Log.
          if (userId) {
            // Awaited NICHT -- fire-and-forget damit die App-Antwort nicht
            // auf das Upsert wartet. Crypto+REST kann 20-30ms kosten.
            ctx.waitUntil?.(recordProfileSession(userId, request, env, auth));
          }
          return jsonResponse({
            success: inserted,
            xp_added: xpAdded,
          });
        } catch (e) {
          return errorResponse(`Activity-Log-Fehler: ${e.message}`);
        }
      }

      // ── POST /api/devices/register  (v5.44.3 FCM-Token Persistenz) ──
      // Body: { fcm_token, platform: 'android'|'ios'|'web', profile_id?,
      //         legacy_user_id?, app_version?, device_model? }
      // Mindestens eines von profile_id ODER legacy_user_id muss gesetzt sein.
      // Upsert auf fcm_token - 1 Token = 1 Device (egal welcher User).
      if (method === 'POST' && path === '/api/devices/register') {
        try {
          const body = await request.json().catch(() => ({}));
          const fcmToken = String(body.fcm_token || '').trim();
          const platform = String(body.platform || '').toLowerCase();
          const profileId = body.profile_id || null;
          const legacyUserId = body.legacy_user_id || null;
          if (!fcmToken) return errorResponse('fcm_token fehlt', 400);
          if (!['android', 'ios', 'web'].includes(platform)) {
            return errorResponse('platform muss android|ios|web sein', 400);
          }
          if (!profileId && !legacyUserId) {
            return errorResponse(
              'profile_id ODER legacy_user_id muss gesetzt sein', 400
            );
          }

          const upsertRes = await fetch(
            `${SUPABASE_URL}/rest/v1/user_devices?on_conflict=fcm_token`,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'apikey': env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_ANON_KEY}`,
                'Prefer': 'resolution=merge-duplicates,return=representation',
              },
              body: JSON.stringify({
                fcm_token: fcmToken,
                profile_id: profileId,
                legacy_user_id: legacyUserId,
                platform,
                app_version: body.app_version || null,
                device_model: body.device_model || null,
                last_seen_at: new Date().toISOString(),
              }),
            }
          );
          if (!upsertRes.ok) {
            const t = await upsertRes.text().catch(() => '');
            return errorResponse(
              `Device-Register fehlgeschlagen: ${upsertRes.status} ${t.slice(0, 200)}`
            );
          }
          const data = await upsertRes.json().catch(() => []);
          return jsonResponse({
            success: true,
            device: Array.isArray(data) ? data[0] : data,
          });
        } catch (e) {
          return errorResponse(`Device-Register-Fehler: ${e.message}`);
        }
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
        // v5.44.7: InvisibleAuth-User haben TEXT-id (user_<ts>_<rand>),
        // nicht UUID - patche dann via legacy_user_id statt id.
        if (userId && userId !== 'unknown') {
          const looksLikeUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);
          const lookupCol = looksLikeUuid ? 'id' : 'legacy_user_id';
          await fetch(
            `${SUPABASE_URL}/rest/v1/profiles?${lookupCol}=eq.${encodeURIComponent(userId)}`,
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

        // v5.44.7: media_url als kanonisches Feld (Client erwartet das,
        // siehe image_upload_service.dart Zeile 81). avatar_url + url
        // bleiben fuer Rueckwaertskompatibilitaet.
        return jsonResponse({
          media_url: publicUrl,
          avatar_url: publicUrl,
          url: publicUrl,
          path: fileName,
          ...data,
        });
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
        // v5.44.7: media_url als kanonisches Feld - Client erwartet das.
        // url bleibt fuer Rueckwaertskompatibilitaet.
        return jsonResponse({
          media_url: publicUrl,
          url: publicUrl,
          key,
        });
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

    // ── Knowledge-Graph Auto-Connect (L4) ─────────────────────
    // POST /api/knowledge/connect-suggest  { nodes: [{id, label, description?}, ...] }
    // Schlägt sinnvolle Verbindungen zwischen vorhandenen Knoten vor.
    if (path === '/api/knowledge/connect-suggest' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const { nodes } = await request.json();
        if (!Array.isArray(nodes) || nodes.length < 2) {
          return errorResponse('Mindestens 2 Knoten erforderlich', 400);
        }
        const list = nodes
          .slice(0, 30)
          .map((n) => `- ${n.id}: ${n.label || ''}${n.description ? ' — ' + n.description.substring(0, 120) : ''}`)
          .join('\n');
        const systemPrompt = 'Du erkennst nicht-triviale Verbindungen zwischen Wissens-Knoten. Antworte AUSSCHLIESSLICH als JSON-Array mit Objekten {"from": "<id>", "to": "<id>", "reason": "<kurzer Grund>"}, maximal 8 Verbindungen, keine Erklärungen drumherum.';
        const userMsg = `Knoten:\n${list}\n\nWelche Verbindungen siehst du?`;
        const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userMsg },
          ],
          max_tokens: 500,
        });
        const raw = (res?.response || '').trim();
        let suggestions = [];
        try {
          const m = raw.match(/\[[\s\S]*\]/);
          if (m) {
            const arr = JSON.parse(m[0]);
            suggestions = arr
              .filter((s) => s && s.from && s.to && s.from !== s.to)
              .slice(0, 8);
          }
        } catch (_) { /* empty fallback */ }
        return jsonResponse({ suggestions, model: 'llama-3.1-8b-instruct' });
      } catch (e) {
        return errorResponse(`Connect-Suggest fehlgeschlagen: ${e.message}`);
      }
    }

    // ── Crystal-Identifier via Workers AI Vision (H4) ─────────
    // POST /api/crystal/identify  { imageBase64 } → { name, confidence, properties }
    if (path === '/api/crystal/identify' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const { imageBase64 } = await request.json();
        if (!imageBase64) return errorResponse('imageBase64 fehlt', 400);
        // LLava-Vision-Modell: bild + frage → text
        const bytes = Uint8Array.from(atob(imageBase64), (c) => c.charCodeAt(0));
        const res = await env.AI.run('@cf/llava-hf/llava-1.5-7b-hf', {
          image: Array.from(bytes),
          prompt:
            'You see a crystal or gemstone. Identify it. Reply ONLY in this JSON format with no extra prose: {"name": "...", "confidence": 0.0-1.0, "properties": ["...", "..."]}. The name should be in German if possible (e.g. "Amethyst", "Rosenquarz").',
          max_tokens: 200,
        });
        const raw = (res?.description || res?.response || '').toString().trim();
        let parsed = { name: 'Unbekannt', confidence: 0, properties: [] };
        try {
          const m = raw.match(/\{[\s\S]*\}/);
          if (m) parsed = JSON.parse(m[0]);
        } catch (_) {
          parsed = { name: raw.substring(0, 60), confidence: 0.3, properties: [] };
        }
        return jsonResponse({ ...parsed, model: 'llava-1.5-7b' });
      } catch (e) {
        return errorResponse(`Crystal-Vision fehlgeschlagen: ${e.message}`);
      }
    }

    // ── Spirit: Combo-Synthese aus mehreren Tool-Ergebnissen (G2) ──
    // POST /api/spirit/synthesize  { readings: [{tool, summary}, ...] }
    if (path === '/api/spirit/synthesize' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const { readings } = await request.json();
        if (!Array.isArray(readings) || readings.length === 0) {
          return errorResponse('readings fehlen', 400);
        }
        const text = readings
          .filter((r) => r && r.tool && r.summary)
          .map((r) => `[${r.tool}] ${r.summary}`)
          .join('\n');
        const systemPrompt = 'Du bist ein erfahrener spiritueller Mentor und Synthesizer. Aus mehreren Tool-Ergebnissen erkennst du das übergreifende Thema, die zentrale Lebensaufgabe und einen konkreten nächsten Schritt für die Person. Antworte auf Deutsch, maximal 4 Absätze, warmherzig aber präzise.';
        const res = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: `Hier sind meine letzten Readings:\n\n${text}\n\nWas sagen sie zusammen?` },
          ],
          max_tokens: 600,
        });
        return jsonResponse({
          synthesis: (res?.response || '').trim(),
          model: 'llama-3.1-8b-instruct',
        });
      } catch (e) {
        return errorResponse(`Synthese fehlgeschlagen: ${e.message}`);
      }
    }

    // ── Spirit TTS via Workers AI (G3) ────────────────────────
    // POST /api/spirit/tts  { text, voice }
    // Workers AI MeloTTS: @cf/myshell-ai/melotts
    if (path === '/api/spirit/tts' && method === 'POST') {
      if (!env.AI) return errorResponse('Workers AI nicht konfiguriert', 503);
      try {
        const { text, voice } = await request.json();
        if (!text) return errorResponse('text fehlt', 400);
        const clamped = String(text).substring(0, 1500);
        const res = await env.AI.run('@cf/myshell-ai/melotts', {
          prompt: clamped,
          lang: (voice || 'de-DE').toLowerCase().startsWith('de') ? 'DE' : 'EN',
        });
        // Workers AI gibt typischerweise { audio: <bytes/base64> } zurück.
        // Wir laden direkt in R2 hoch wenn möglich, sonst geben wir
        // base64-data-URL zurück (Quick-Path).
        let audioUrl = null;
        if (env.R2_BUCKET && res && res.audio) {
          const buf = typeof res.audio === 'string'
            ? Uint8Array.from(atob(res.audio), (c) => c.charCodeAt(0))
            : res.audio;
          const key = `tts/${Date.now()}.mp3`;
          await env.R2_BUCKET.put(key, buf, {
            httpMetadata: { contentType: 'audio/mpeg' },
          });
          audioUrl = `https://pub-${env.CF_ACCOUNT_ID || 'unknown'}.r2.dev/${key}`;
        } else if (res && res.audio) {
          audioUrl = `data:audio/mpeg;base64,${
            typeof res.audio === 'string' ? res.audio : btoa(String.fromCharCode(...res.audio))
          }`;
        }
        return jsonResponse({ audioUrl, model: 'melotts' });
      } catch (e) {
        return errorResponse(`TTS fehlgeschlagen: ${e.message}`);
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
        const maxTokens = Math.min(body.max_tokens || 700, 1500);

        // A4 (2026-06-07): RAG-Kontext. Der Client kann `context` (Zusammen-
        // fassung der geladenen Recherche-Karten) + `topic` mitschicken.
        // Virgil beantwortet Fragen dann AUF BASIS dieser Daten statt generisch.
        const topic = (body.topic || '').toString().trim();
        const context = (body.context || '').toString().slice(0, 8000);

        let system = body.system || 'Du bist VIRGIL, ein investigativer KI-Begleiter der Weltenbibliothek. Antworte auf Deutsch, knapp, praezise und sachlich.';
        if (context) {
          system += `\n\nDir liegen aktuelle Recherche-Daten${topic ? ` zum Thema "${topic}"` : ''} vor. ` +
            'Beziehe deine Antwort primaer auf diese Daten. Wenn etwas nicht in den Daten steht, sage das offen statt zu spekulieren. ' +
            'Nenne bei konkreten Aussagen die jeweilige Quelle/Karte.\n\n--- RECHERCHE-DATEN ---\n' + context + '\n--- ENDE DATEN ---';
        }

        // Konversation zu einem User-Prompt verflachen (aiText nimmt 1 User-Msg).
        let userMsg;
        if (messages.length <= 1) {
          userMsg = (messages[0]?.content || '').toString();
        } else {
          userMsg = messages
            .map((m) => `${m.role === 'assistant' ? 'VIRGIL' : 'NUTZER'}: ${m.content}`)
            .join('\n') + '\n\nVIRGIL:';
        }
        if (!userMsg.trim()) return errorResponse('Keine Nachricht', 400);

        // 5-Quellen-Kette (Groq -> Gemini -> OpenRouter -> Workers-AI).
        const answer = await aiText(env, system, userMsg, maxTokens);
        return jsonResponse({ answer, model: 'multi-source-chain' });
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

    // ── Translate-Endpoint: Workers-AI m2m100 primary, LibreTranslate fallback ──
    // Workers-AI ist kostenlos (gehoert zum Free-Plan-Kontingent), m2m100 ist
    // ein Multi-Sprach-Modell von Meta. Bei Fehler: LibreTranslate als Backup.
    if (path === '/api/translate' && method === 'POST') {
      try {
        const { text, source = 'en', target = 'de' } = await request.json();
        if (!text) return errorResponse('text fehlt', 400);

        // 1) Primary: Workers-AI (kostenlos, schnell, zuverlaessig)
        if (env.AI) {
          try {
            const aiRes = await env.AI.run('@cf/meta/m2m100-1.2b', {
              text: String(text).slice(0, 4000),
              source_lang: source === 'auto' ? 'en' : source,
              target_lang: target,
            });
            const translated = aiRes?.translated_text || '';
            if (translated) {
              return jsonResponse({ translated, source, target, model: 'workers-ai-m2m100' });
            }
          } catch (_) { /* fall through */ }
        }

        // 2) Fallback: LibreTranslate public instance
        try {
          const r = await fetch('https://libretranslate.de/translate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ q: text, source: source === 'en' ? 'auto' : source, target, format: 'text' }),
            signal: AbortSignal.timeout(12000),
          });
          if (r.ok) {
            const data = await r.json();
            return jsonResponse({ translated: data.translatedText || '', source, target, model: 'libretranslate' });
          }
        } catch (_) { /* fall through */ }

        return errorResponse('Keine Uebersetzung verfuegbar', 503);
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

    // ── Batch-Übersetzung Englisch→Deutsch ──
    // Priority: Groq (1 Call) -> Workers-AI llama (1 Call) -> Items unuebersetzt
    if (path === '/api/translate/batch' && method === 'POST') {
      try {
        const { items } = await request.json();
        if (!Array.isArray(items) || items.length === 0) {
          return jsonResponse({ translated: [] });
        }
        const numbered = items.map((s, i) => `${i + 1}. ${String(s).replace(/\n/g, ' ').slice(0, 300)}`).join('\n');
        const systemMsg = 'Du übersetzt nummerierte englische Texte ins Deutsche. Gib NUR die Übersetzungen in der gleichen Nummerierung zurück, ohne Kommentare. Behalte Eigennamen und Firmennamen unverändert.';
        const parseNumbered = (text) => items.map((orig, i) => {
          const match = text.match(new RegExp(`(?:^|\\n)\\s*${i + 1}\\.\\s*(.+?)(?=(?:\\n\\s*\\d+\\.)|$)`, 's'));
          return match ? match[1].trim() : orig;
        });

        // 1) Primary: Groq (am schnellsten + akkuratesten)
        if (env.GROQ_API_KEY) {
          try {
            const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${env.GROQ_API_KEY}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [
                  { role: 'system', content: systemMsg },
                  { role: 'user', content: numbered },
                ],
                temperature: 0.3,
                max_tokens: 1500,
              }),
              signal: AbortSignal.timeout(20000),
            });
            if (r.ok) {
              const data = await r.json();
              const text = data?.choices?.[0]?.message?.content || '';
              if (text) return jsonResponse({ translated: parseNumbered(text), model: 'groq-llama-3.3-70b' });
            }
          } catch (_) { /* fall through */ }
        }

        // 2) Fallback: Workers-AI llama-3.1-8b (kostenlos)
        if (env.AI) {
          try {
            const aiRes = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
              messages: [
                { role: 'system', content: systemMsg },
                { role: 'user', content: numbered },
              ],
              max_tokens: 1500,
            });
            const text = aiRes?.response || '';
            if (text) return jsonResponse({ translated: parseNumbered(text), model: 'workers-ai-llama-3.1-8b' });
          } catch (_) { /* fall through */ }
        }

        // 3) Letzte Option: unuebersetzt zurueck
        return jsonResponse({ translated: items, fallback: true });
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
      const arxivPapers = await translateItems(arxivRaw, ['title', 'summary'], env);

      const europeanaRaw = europeana?.items?.slice(0, 5).map(it => ({
        title: it.title?.[0] || '',
        provider: it.dataProvider?.[0] || '',
        year: it.year?.[0] || '',
        url: it.guid,
      })) || [];
      const europeanaTranslated = await translateItems(europeanaRaw, ['title'], env);

      const gdeltRaw = gdelt?.articles?.slice(0, 10).map(a => ({
        title: a.title || '',
        url: a.url,
        domain: a.domain,
        date: a.seendate,
      })) || [];
      const gdeltTranslated = await translateItems(gdeltRaw, ['title'], env);

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
        const items = await translateItems(itemsRaw, ['title'], env);
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
        const results = await translateItems(sanctionsRaw, ['notes'], env);
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
        const results = await translateItems(alephRaw, ['name', 'summary'], env);
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
        const papers = await translateItems(papersRaw, ['title'], env);
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
        const papers = await translateItems(papersRaw, ['title', 'abstract'], env);
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
        const docs = await translateItems(docsRaw, ['title', 'description'], env);
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
        const votes = await translateItems(votesRaw, ['title'], env);
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
        const translated = await translateItems(items, ['title', 'description'], env);
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
        const translated = await translateItems(items, ['name', 'description'], env);
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
        const translated = await translateItems(items, ['caseName', 'snippet'], env);
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
        const translated = await translateItems(items, ['title', 'description'], env);
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
        const translated = await translateItems(items, ['title', 'description'], env);
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

        const translated = await translateItems([...archiveDocs, ...links.filter(l => !archiveDocs.length)], ['title', 'description'], env);
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
        const translated = await translateItems(items, ['title', 'description'], env);
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
        const translated = await translateItems(items, ['title', 'conclusion'], env);
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
        const translated = await translateItems(items, ['title'], env);
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
        const translated = await translateItems(archiveItems, ['title', 'snippet'], env);
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
        const translated = await translateItems(raw, ['title'], env);
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

        // ── KV-Cache fuer wiederholte Anfragen ────────────────
        // Nur cachen wenn keine Konversations-History (deterministisches
        // System-Prompt + User-Message → identische Antwort erwartet).
        // Schont Worker-Quota + Groq-Tokens dramatisch.
        const cacheable = !conversationHistory ||
            (Array.isArray(conversationHistory) && conversationHistory.length === 0);
        let cacheKey = null;
        if (cacheable && env.MENTOR_CACHE) {
          try {
            const keyMaterial = `${personality}|${world || ''}|${message}`;
            const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(keyMaterial));
            const hash = [...new Uint8Array(buf)]
              .map(b => b.toString(16).padStart(2, '0'))
              .join('')
              .substring(0, 32);
            cacheKey = `mentor:${hash}`;
            const cached = await env.MENTOR_CACHE.get(cacheKey, { type: 'json' });
            if (cached && cached.reply) {
              return new Response(JSON.stringify({
                reply: cached.reply,
                model_used: `${cached.model_used || 'cached'}+cache`,
                timestamp: new Date().toISOString(),
                cached: true,
              }), {
                status: 200,
                headers: {
                  'Content-Type': 'application/json',
                  'X-Cache': 'HIT',
                  'Access-Control-Allow-Origin': '*',
                },
              });
            }
          } catch (_) { /* Cache-Lookup darf nie Anfrage blockieren */ }
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

        // 🎭 L1: Welt-spezifische Persona via systemPrompt-Override aus
        // dem Client (MentorPersonas.systemPrompt(world)). Wenn nicht
        // mitgeschickt: Fallback auf personality-basierte MENTOR_PROMPTS.
        const systemPrompt = (typeof body.systemPrompt === 'string'
              && body.systemPrompt.length > 30)
          ? body.systemPrompt
          : (MENTOR_PROMPTS[personality] || MENTOR_PROMPTS.forscher);

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

        // Schreibe Cache (fire-and-forget, 7 Tage TTL).
        if (cacheable && cacheKey && env.MENTOR_CACHE) {
          try {
            env.MENTOR_CACHE.put(cacheKey,
              JSON.stringify({ reply, model_used: modelUsed }),
              { expirationTtl: 604800 } // 7d
            ).catch(() => {});
          } catch (_) {}
        }

        return new Response(JSON.stringify({
          reply,
          model_used: modelUsed,
          timestamp: new Date().toISOString(),
        }), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'X-Cache': cacheable ? 'MISS' : 'BYPASS',
            'Access-Control-Allow-Origin': '*',
          },
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
          // U2: nur Metadaten laden (kein theory_content/case_study/
          // exercise_description/test_questions) -> Payload 264 KB -> ~35 KB.
          // Voller Inhalt wird lazy via /api/vorhang/module/:id nachgeladen.
          const listColumns =
            'id,module_code,branch,branch_order,title,subtitle,' +
            'xp_reward,is_boss_module,prerequisites';
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/vorhang_modules?select=${listColumns}&order=branch_order.asc,module_code.asc`,
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
          // U2: nur Metadaten laden (kein theory_content/case_study/
          // exercise_description/test_questions) -> kleinere Payload.
          // Voller Inhalt wird lazy via /api/ursprung/module/:id nachgeladen.
          const ursprungListColumns =
            'id,module_code,branch,branch_order,title,subtitle,' +
            'xp_reward,is_boss_module,prerequisites';
          const modRes = await fetch(
            `${SUPABASE_URL}/rest/v1/ursprung_modules?select=${ursprungListColumns}&order=branch_order.asc,module_code.asc`,
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
          // BUGFIX: Client sends snake_case (user_id, module_code, test_*). Accept
          // both naming conventions, identical to the working Vorhang endpoint.
          // Previously only camelCase was read -> userId/moduleCode were undefined
          // -> 400 -> completed_at never written -> next module never unlocked.
          const userId = body.user_id || body.userId;
          const moduleCode = body.module_code || body.moduleCode;
          const theoryRead = body.theory_read ?? body.theoryRead;
          const caseStudyRead = body.case_study_read ?? body.caseStudyRead;
          const exerciseCompleted = body.exercise_completed ?? body.exerciseCompleted;
          const exerciseNotes = body.exercise_notes ?? body.exerciseNotes;
          const testScore = body.test_score ?? body.testScore;
          const testPassed = body.test_passed ?? body.testPassed;
          if (!userId || !moduleCode) return errorResponse('user_id und module_code sind Pflichtfelder', 400, 'MISSING_PARAMS');

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
          // "already completed" is based on completed_at presence (consistent with
          // Vorhang and with the unlock computation in ursprung_service.dart).
          const alreadyCompleted = !!(existing && existing.completed_at);

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
          const shouldComplete = row.test_passed && !alreadyCompleted;
          if (shouldComplete) row.completed_at = new Date().toISOString();
          else if (existing?.completed_at) row.completed_at = existing.completed_at;

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
          const upData = await upRes.json().catch(() => null);
          const progressRow = Array.isArray(upData) ? upData[0] : upData;

          let xpAwarded = 0;
          if (shouldComplete) {
            xpAwarded = xpReward;
            // BUGFIX: RPC is add_user_xp (add_xp_to_user does not exist). Same
            // signature the Vorhang endpoint uses.
            try {
              await fetch(`${SUPABASE_URL}/rest/v1/rpc/add_user_xp`, {
                method: 'POST',
                headers: sbHeaders,
                body: JSON.stringify({ p_user_id: userId, p_amount: xpReward, p_reason: `ursprung_module:${moduleCode}` }),
              });
            } catch (_) { /* non-fatal */ }
          }
          // BUGFIX: return xp_awarded + already_completed (snake_case) which the
          // client reads (ursprung_lesson_screen.dart).
          return jsonResponse({
            success: true,
            progress: progressRow,
            xp_awarded: xpAwarded,
            already_completed: alreadyCompleted,
          });
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

        // 1. Wetter via Open-Meteo
        //    Priorität für die Koordinaten:
        //    a) Client-übergebene lat/lon (echtes GPS)  → genauester Wert
        //    b) Cloudflare-IP-Geolokation              → ungenau (Carrier)
        //    c) Hardcoded Wien-Fallback
        const cf = request.cf || {};
        const clientCoords = (typeof body.lat === 'number' && typeof body.lon === 'number');
        const lat = clientCoords ? body.lat : (cf.latitude ?? 48.2082);
        const lon = clientCoords ? body.lon : (cf.longitude ?? 16.3738);
        // Wenn Client-GPS gegeben: cf.city ist FALSCH (Carrier-Gateway).
        // Dann lieber reverse-geocoden — sonst cf.city nutzen.
        let city = clientCoords ? null : (cf.city || 'unbekannt');

        let weather = body.weather || null;
        if (!weather) {
          try {
            const tasks = [
              fetch(
                `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=auto`,
                { signal: AbortSignal.timeout(8000) }
              ),
            ];
            // Reverse-Geocode nur wenn Client-GPS gegeben und city fehlt.
            // Open-Meteo Geocoding hat keinen reverse-endpoint; daher BigDataCloud
            // free tier — limit 50k/Monat ohne Key.
            if (clientCoords) {
              tasks.push(fetch(
                `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=de`,
                { signal: AbortSignal.timeout(5000) }
              ));
            }
            const [wRes, geoRes] = await Promise.all(tasks);
            const wData = await wRes.json().catch(() => ({}));
            const cur = wData.current || {};
            const codes = { 0:'klar', 1:'überwiegend klar', 2:'teilweise bewölkt', 3:'bewölkt',
              45:'neblig', 48:'dichter Nebel', 51:'leichter Nieselregen', 53:'Nieselregen',
              55:'starker Nieselregen', 61:'leichter Regen', 63:'Regen', 65:'starker Regen',
              71:'leichter Schnee', 73:'Schnee', 75:'starker Schnee', 80:'Regenschauer',
              81:'starke Regenschauer', 82:'heftige Regenschauer', 95:'Gewitter', 96:'Gewitter mit Hagel', 99:'starkes Gewitter'};
            if (clientCoords && geoRes && geoRes.ok) {
              const g = await geoRes.json().catch(() => ({}));
              city = g.city || g.locality || g.principalSubdivision || 'Position';
            }
            weather = {
              temp: cur.temperature_2m ?? null,
              humidity: cur.relative_humidity_2m ?? null,
              condition: codes[cur.weather_code] || 'unbekannt',
              wind: cur.wind_speed_10m ?? null,
              city: city || 'unbekannt',
              source: clientCoords ? 'gps' : 'ip',
            };
          } catch (e) {
            weather = { temp: null, condition: 'unbekannt', city: city || 'unbekannt', source: clientCoords ? 'gps' : 'ip' };
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

    // ── R-X10: Konflikt-Datenbank (ACLED bevorzugt, GDELT als freier Fallback) ─
    // GET /api/intel/conflict?country=Ukraine&limit=50
    if (path === '/api/intel/conflict' && method === 'GET') {
      const country = url.searchParams.get('country') || '';
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);

      // Premium path: ACLED (wenn Secrets gesetzt)
      if (env.ACLED_ACCESS_TOKEN && env.ACLED_EMAIL) {
        try {
          const params = new URLSearchParams({
            key: env.ACLED_ACCESS_TOKEN,
            email: env.ACLED_EMAIL,
            limit: String(limit),
            fields: 'event_date|event_type|sub_event_type|country|location|latitude|longitude|fatalities|notes',
            'order': 'event_date:desc',
          });
          if (country) params.set('country', country);
          const r = await fetch(`https://api.acleddata.com/acled/read?${params}`, {
            signal: AbortSignal.timeout(10000),
          });
          if (!r.ok) return jsonResponse({ error: `ACLED HTTP ${r.status}`, events: [] });
          const data = await r.json();
          return jsonResponse({ events: data.data || [], count: data.count || 0 });
        } catch (e) {
          return errorResponse(`ACLED-Abfrage fehlgeschlagen: ${e.message}`, 502);
        }
      }

      // Free fallback: GDELT DOC API (kein API-Key noetig)
      try {
        const q = country
          ? `${country} conflict violence protest riot attack`
          : 'conflict violence war protest';
        const r = await fetch(
          `https://api.gdeltproject.org/api/v2/doc/doc?query=${encodeURIComponent(q)}&mode=artlist&maxrecords=${limit}&format=json`,
          { signal: AbortSignal.timeout(12000) }
        );
        if (!r.ok) return jsonResponse({ events: [], count: 0 });
        const data = await r.json();
        const articles = Array.isArray(data.articles) ? data.articles : [];
        const events = articles.map(a => {
          const raw = a.seendate || '';
          const event_date = raw.length >= 8
            ? `${raw.slice(0, 4)}-${raw.slice(4, 6)}-${raw.slice(6, 8)}`
            : new Date().toISOString().slice(0, 10);
          const t = (a.title || '').toLowerCase();
          let event_type = 'Meldung';
          if (/\b(battle|gefecht|kampf|krieg|war)\b/.test(t)) event_type = 'Battle';
          else if (/\b(explos|bomben|rakete|missile|airstrike)\b/.test(t)) event_type = 'Explosion/Remote violence';
          else if (/\b(protest|demonst|march)\b/.test(t)) event_type = 'Protests';
          else if (/\b(riot|unruhen|aufstand)\b/.test(t)) event_type = 'Riots';
          else if (/\b(attack|angriff|gewalt|violence|shooting|schusswaf)\b/.test(t)) event_type = 'Violence against civilians';
          return {
            event_type,
            sub_event_type: a.domain || '',
            location: country || a.sourcecountry || '',
            event_date,
            fatalities: 0,
            notes: a.title || '',
          };
        });
        return jsonResponse({ events, count: events.length, source: 'GDELT' });
      } catch (e) {
        return jsonResponse({ events: [], count: 0, error: `GDELT: ${e.message}` });
      }
    }

    // ── R-X11: Waldbrand-Satelliten (NASA FIRMS bevorzugt, EONET als freier Fallback)
    // GET /api/intel/wildfires?days=1&region=world
    if (path === '/api/intel/wildfires' && method === 'GET') {
      const days = Math.min(parseInt(url.searchParams.get('days') || '1'), 7);

      // Premium path: NASA FIRMS (wenn API-Key gesetzt)
      if (env.NASA_FIRMS_API_KEY) {
        const region = url.searchParams.get('region') || 'world';
        try {
          const csvUrl = `https://firms.modaps.eosdis.nasa.gov/api/area/csv/${env.NASA_FIRMS_API_KEY}/VIIRS_SNPP_NRT/${region}/${days}`;
          const r = await fetch(csvUrl, { signal: AbortSignal.timeout(12000) });
          if (!r.ok) return jsonResponse({ error: `FIRMS HTTP ${r.status}`, fires: [] });
          const text = await r.text();
          const lines = text.trim().split('\n');
          if (lines.length < 2) return jsonResponse({ fires: [], count: 0 });
          const headers = lines[0].split(',').map(h => h.trim());
          const fires = [];
          for (let i = 1; i < Math.min(lines.length, 301); i++) {
            const cols = lines[i].split(',');
            if (cols.length < headers.length) continue;
            const entry = {};
            headers.forEach((h, idx) => { entry[h] = cols[idx]?.trim() || ''; });
            fires.push(entry);
          }
          return jsonResponse({ fires, count: fires.length, totalRows: lines.length - 1 });
        } catch (e) {
          return errorResponse(`FIRMS-Abfrage fehlgeschlagen: ${e.message}`, 502);
        }
      }

      // Free fallback: NASA EONET (kein API-Key noetig, offizielle NASA-Events)
      try {
        const eonetDays = Math.max(days * 30, 30); // EONET nutzt Tage seit Beginn
        const r = await fetch(
          `https://eonet.gsfc.nasa.gov/api/v3/events?category=wildfires&status=open&limit=200&days=${eonetDays}`,
          { signal: AbortSignal.timeout(12000) }
        );
        if (!r.ok) return jsonResponse({ fires: [], count: 0 });
        const data = await r.json();
        const fires = (data.events || []).flatMap(ev => {
          // EONET events can have multiple geometry points (track); use the latest
          const geoms = ev.geometry || [];
          const geom = geoms[geoms.length - 1] || {};
          const coords = geom.coordinates || [0, 0];
          return [{
            latitude: String(coords[1] || 0),
            longitude: String(coords[0] || 0),
            frp: '120',  // EONET hat kein FRP; Median-Wert als Platzhalter
            acq_date: (geom.date || new Date().toISOString()).slice(0, 10),
            acq_time: '0000',
            country_id: '',
            confidence: 'n',
            title: ev.title || '',
          }];
        });
        return jsonResponse({ fires, count: fires.length, totalRows: fires.length, source: 'NASA EONET' });
      } catch (e) {
        return jsonResponse({ fires: [], count: 0, error: `EONET: ${e.message}` });
      }
    }

    // ── R-X12: Luftqualitaet (OpenAQ v3 bevorzugt, v2 als freier Fallback) ────
    // GET /api/intel/airquality?city=Berlin&limit=20
    if (path === '/api/intel/airquality' && method === 'GET') {
      const city = url.searchParams.get('city') || '';
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 100);

      // Premium path: OpenAQ v3 (wenn API-Key gesetzt)
      if (env.OPENAQ_API_KEY) {
        try {
          const params = new URLSearchParams({ limit: String(limit), order_by: 'lastUpdated', sort_order: 'desc' });
          if (city) params.set('city', city);
          const r = await fetch(`https://api.openaq.org/v3/locations?${params}`, {
            headers: { 'X-API-Key': env.OPENAQ_API_KEY },
            signal: AbortSignal.timeout(10000),
          });
          if (!r.ok) return jsonResponse({ error: `OpenAQ HTTP ${r.status}`, results: [] });
          const data = await r.json();
          const results = (data.results || []).map(loc => ({
            id: loc.id,
            name: loc.name,
            city: loc.locality || loc.city || '',
            country: loc.country?.code || '',
            lat: loc.coordinates?.latitude,
            lon: loc.coordinates?.longitude,
            lastUpdated: loc.datetimeLast?.local || loc.lastUpdated || '',
            sensors: (loc.sensors || []).map(s => ({
              name: s.name,
              parameter: s.parameter?.name || '',
              unit: s.parameter?.units || '',
            })),
          }));
          return jsonResponse({ results, count: results.length });
        } catch (e) {
          return errorResponse(`OpenAQ-Abfrage fehlgeschlagen: ${e.message}`, 502);
        }
      }

      // Free fallback: OpenAQ v2 (kein API-Key noetig)
      try {
        const params = new URLSearchParams({
          limit: String(limit),
          order_by: 'lastUpdated',
          sort: 'desc',
        });
        if (city) params.set('city', city);
        const r = await fetch(`https://api.openaq.org/v2/latest?${params}`, {
          headers: { 'Accept': 'application/json' },
          signal: AbortSignal.timeout(10000),
        });
        if (!r.ok) return jsonResponse({ results: [], error: `OpenAQ v2 HTTP ${r.status}` });
        const data = await r.json();
        const results = (data.results || []).map(loc => ({
          id: loc.id || 0,
          name: loc.location || loc.name || '',
          city: loc.city || '',
          country: loc.country || '',
          lat: loc.coordinates?.latitude,
          lon: loc.coordinates?.longitude,
          lastUpdated: loc.lastUpdated || '',
          sensors: (loc.parameters || []).map(p => ({
            name: p.parameter || '',
            parameter: p.parameter || '',
            unit: p.unit || '',
          })),
        }));
        return jsonResponse({ results, count: results.length, source: 'OpenAQ v2' });
      } catch (e) {
        return jsonResponse({ results: [], error: `OpenAQ v2: ${e.message}` });
      }
    }

    // ── R-X13: Internet-Ausfaelle (CF Radar bevorzugt, IODA als freier Fallback)
    // GET /api/intel/outages?limit=20
    if (path === '/api/intel/outages' && method === 'GET') {
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 100);

      // Premium path: Cloudflare Radar (wenn Token gesetzt)
      if (env.CLOUDFLARE_RADAR_API_TOKEN) {
        try {
          const params = new URLSearchParams({ limit: String(limit), format: 'json' });
          const r = await fetch(`https://api.cloudflare.com/client/v4/radar/annotations/outages?${params}`, {
            headers: {
              'Authorization': `Bearer ${env.CLOUDFLARE_RADAR_API_TOKEN}`,
              'Content-Type': 'application/json',
            },
            signal: AbortSignal.timeout(10000),
          });
          if (!r.ok) return jsonResponse({ error: `CF Radar HTTP ${r.status}`, outages: [] });
          const data = await r.json();
          const outages = (data.result?.annotations || []).map(a => ({
            id: a.id,
            asn: a.asn,
            asnName: a.asnName || '',
            location: a.locationName || '',
            country: a.countryCode || '',
            startDate: a.startDate || '',
            endDate: a.endDate || '',
            description: a.description || '',
            scope: a.scope || '',
            eventType: a.eventType || '',
          }));
          return jsonResponse({ outages, count: outages.length });
        } catch (e) {
          return errorResponse(`CF-Radar-Abfrage fehlgeschlagen: ${e.message}`, 502);
        }
      }

      // Free fallback: IODA API (Internet Outage Detection and Analysis, CAIDA/Georgia Tech)
      // Kein API-Key noetig. Erkennt BGP-Routing-Anomalien als Proxy fuer Ausfaelle.
      try {
        const now = Math.floor(Date.now() / 1000);
        const from = now - 7 * 24 * 3600; // letzte 7 Tage
        const r = await fetch(
          `https://api.ioda.caida.org/v2/outages/alerts?from=${from}&until=${now}&limit=${limit}`,
          {
            headers: { 'Accept': 'application/json' },
            signal: AbortSignal.timeout(10000),
          }
        );
        if (!r.ok) return jsonResponse({ outages: [], count: 0 });
        const body = await r.json();
        // IODA gibt entweder ein Array oder { data: [...] } zurueck
        const alerts = Array.isArray(body) ? body
          : Array.isArray(body.data) ? body.data
          : Array.isArray(body.alerts) ? body.alerts
          : [];
        const outages = alerts.map(a => {
          const entity = a.entity || {};
          const type = entity.type || a.type || 'country';
          const name = entity.name || a.name || entity.code || '';
          const fromTs = a.from || a.time || now;
          const untilTs = a.until || (fromTs + 3600);
          return {
            id: `${type}-${entity.code || name}-${fromTs}`,
            asn: 0,
            asnName: type === 'asn' ? name : '',
            location: name,
            country: type === 'country' ? name : (entity.code || ''),
            startDate: new Date(fromTs * 1000).toISOString().slice(0, 10),
            endDate: new Date(untilTs * 1000).toISOString().slice(0, 10),
            description: `${a.datasource || 'bgp'}: Score ${(+(a.value || 0)).toFixed(1)}`,
            scope: type,
            eventType: a.condition || 'outage',
          };
        });
        return jsonResponse({ outages, count: outages.length, source: 'IODA/CAIDA' });
      } catch (e) {
        return jsonResponse({ outages: [], count: 0, error: `IODA: ${e.message}` });
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // R-WELT: Key-freie Welt-Werkzeuge (alle ohne API-Key, offene Datenquellen)
    // Einheitliche Antwort: { items: [...], count, source }
    // ═══════════════════════════════════════════════════════════════════════

    // ── MATERIE: Erdbeben-Radar (USGS, kein Key) ─────────────────────────────
    // GET /api/intel/earthquakes?min=2.5
    if (path === '/api/intel/earthquakes' && method === 'GET') {
      const min = url.searchParams.get('min') || '2.5';
      const feed = ['1.0', '2.5', '4.5', 'significant'].includes(min) ? min : '2.5';
      try {
        const r = await fetch(
          `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/${feed}_day.geojson`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const items = (data.features || []).slice(0, 120).map(f => {
          const p = f.properties || {};
          const c = (f.geometry && f.geometry.coordinates) || [0, 0, 0];
          return {
            title: p.place || 'Unbekannter Ort',
            mag: p.mag,
            time: p.time ? new Date(p.time).toISOString() : '',
            lat: c[1], lon: c[0], depth: c[2],
            tsunami: p.tsunami === 1,
            url: p.url || '',
          };
        });
        return jsonResponse({ items, count: items.length, source: 'USGS' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `USGS: ${e.message}` });
      }
    }

    // ── MATERIE: Asteroiden-Anflug (JPL SSD Close-Approach, kein Key) ─────────
    // GET /api/intel/asteroids
    if (path === '/api/intel/asteroids' && method === 'GET') {
      try {
        const r = await fetch(
          'https://ssd-api.jpl.nasa.gov/cad.api?date-min=now&date-max=%2B60&dist-max=0.05&sort=date',
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const fields = data.fields || [];
        const idx = (n) => fields.indexOf(n);
        const iDes = idx('des'), iCd = idx('cd'), iDist = idx('dist'),
          iV = idx('v_rel'), iH = idx('h');
        const items = (data.data || []).slice(0, 80).map(row => {
          const distAu = parseFloat(row[iDist] || '0');
          return {
            name: row[iDes] || '?',
            date: row[iCd] || '',
            distLd: +(distAu * 389.17).toFixed(2), // Mond-Distanzen
            distKm: Math.round(distAu * 149597871),
            vRel: +(parseFloat(row[iV] || '0')).toFixed(1),
            h: parseFloat(row[iH] || '0'), // absolute Helligkeit ~ Groesse
          };
        });
        return jsonResponse({ items, count: items.length, source: 'NASA/JPL SSD' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `JPL: ${e.message}` });
      }
    }

    // ── MATERIE: Vulkan-Aktivitaet (NASA EONET, kein Key) ────────────────────
    // GET /api/intel/volcanoes
    if (path === '/api/intel/volcanoes' && method === 'GET') {
      try {
        const r = await fetch(
          'https://eonet.gsfc.nasa.gov/api/v3/events?category=volcanoes&status=open&limit=100',
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const items = (data.events || []).map(ev => {
          const g = (ev.geometry || [])[((ev.geometry || []).length - 1)] || {};
          const c = g.coordinates || [0, 0];
          return {
            title: ev.title || 'Vulkan',
            date: (g.date || '').slice(0, 10),
            lat: c[1], lon: c[0],
            link: (ev.sources && ev.sources[0] && ev.sources[0].url) || ev.link || '',
          };
        });
        return jsonResponse({ items, count: items.length, source: 'NASA EONET' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `EONET: ${e.message}` });
      }
    }

    // ── MATERIE+ENERGIE: Weltraumwetter / Geomagnetik (NOAA SWPC, kein Key) ───
    // GET /api/intel/spaceweather
    if (path === '/api/intel/spaceweather' && method === 'GET') {
      try {
        const r = await fetch(
          'https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json',
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const rows = await r.json();
        const body = Array.isArray(rows) ? rows.slice(1) : [];
        const items = body.slice(-24).reverse().map(row => {
          const kp = parseFloat(row[1] || '0');
          let level = 'Ruhig';
          if (kp >= 8) level = 'Schwerer Sturm (G4-G5)';
          else if (kp >= 7) level = 'Starker Sturm (G3)';
          else if (kp >= 6) level = 'Sturm (G2)';
          else if (kp >= 5) level = 'Geomagn. Sturm (G1)';
          else if (kp >= 4) level = 'Unruhig';
          return { time: row[0] || '', kp, level };
        });
        return jsonResponse({ items, count: items.length, source: 'NOAA SWPC' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `SWPC: ${e.message}` });
      }
    }

    // ── ENERGIE: Mondphasen (FarmSense, kein Key) ────────────────────────────
    // GET /api/intel/moon
    if (path === '/api/intel/moon' && method === 'GET') {
      try {
        const now = Math.floor(Date.now() / 1000);
        const ds = [];
        for (let i = 0; i < 8; i++) ds.push(`d=${now + i * 86400}`);
        const r = await fetch(
          `https://api.farmsense.net/v1/moonphases/?${ds.join('&')}`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const phaseDe = {
          'New Moon': 'Neumond', 'Waxing Crescent': 'Zunehmende Sichel',
          'First Quarter': 'Erstes Viertel', 'Waxing Gibbous': 'Zunehmender Mond',
          'Full Moon': 'Vollmond', 'Waning Gibbous': 'Abnehmender Mond',
          'Last Quarter': 'Letztes Viertel', 'Waning Crescent': 'Abnehmende Sichel',
          '3rd Quarter': 'Letztes Viertel',
        };
        const items = (Array.isArray(data) ? data : []).map((m, i) => ({
          date: new Date((now + i * 86400) * 1000).toISOString().slice(0, 10),
          phase: phaseDe[m.Phase] || m.Phase || '',
          illumination: Math.round((parseFloat(m.Illumination || '0')) * 100),
          age: Math.round(parseFloat(m.Age || '0')),
          name: (m.Moon && m.Moon[0]) || '',
        }));
        return jsonResponse({ items, count: items.length, source: 'FarmSense' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `Moon: ${e.message}` });
      }
    }

    // ── ENERGIE: Tages-Mantra / Zitate (ZenQuotes, kein Key) ─────────────────
    // GET /api/intel/mantra
    if (path === '/api/intel/mantra' && method === 'GET') {
      try {
        const r = await fetch('https://zenquotes.io/api/quotes', {
          signal: AbortSignal.timeout(10000),
        });
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const items = (Array.isArray(data) ? data : []).slice(0, 20).map(q => ({
          quote: q.q || '',
          author: q.a || 'Unbekannt',
        })).filter(x => x.quote);
        return jsonResponse({ items, count: items.length, source: 'ZenQuotes' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `Mantra: ${e.message}` });
      }
    }

    // ── VORHANG: Lobby-Radar (GDELT, kein Key) ───────────────────────────────
    // GET /api/intel/lobby
    // ── VORHANG: Leaks-Suche (GDELT, kein Key) ───────────────────────────────
    // GET /api/intel/leaks
    if ((path === '/api/intel/lobby' || path === '/api/intel/leaks') && method === 'GET') {
      const isLobby = path.endsWith('lobby');
      const q = isLobby
        ? 'lobbying corporate influence government policy donation'
        : 'leak whistleblower classified documents exposed revealed';
      try {
        const r = await fetch(
          `https://api.gdeltproject.org/api/v2/doc/doc?query=${encodeURIComponent(q)}&mode=artlist&maxrecords=60&sort=datedesc&format=json`,
          { signal: AbortSignal.timeout(12000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const items = (Array.isArray(data.articles) ? data.articles : []).map(a => {
          const raw = a.seendate || '';
          const date = raw.length >= 8
            ? `${raw.slice(0, 4)}-${raw.slice(4, 6)}-${raw.slice(6, 8)}`
            : '';
          return {
            title: a.title || '',
            domain: a.domain || '',
            country: a.sourcecountry || '',
            date,
            url: a.url || '',
          };
        }).filter(x => x.title);
        return jsonResponse({ items, count: items.length, source: 'GDELT' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `GDELT: ${e.message}` });
      }
    }

    // ── URSPRUNG: Artenvielfalt (GBIF, kein Key) ─────────────────────────────
    // GET /api/intel/species?q=
    if (path === '/api/intel/species' && method === 'GET') {
      const q = url.searchParams.get('q') || '';
      try {
        const params = new URLSearchParams({
          limit: '50', mediaType: 'StillImage',
        });
        if (q) params.set('q', q);
        const r = await fetch(`https://api.gbif.org/v1/occurrence/search?${params}`, {
          signal: AbortSignal.timeout(10000),
        });
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const seen = new Set();
        const items = [];
        for (const o of (data.results || [])) {
          const name = o.species || o.scientificName || '';
          if (!name || seen.has(name)) continue;
          seen.add(name);
          const media = (o.media || [])[0] || {};
          items.push({
            species: name,
            sciName: o.scientificName || '',
            kingdom: o.kingdom || '',
            country: o.country || '',
            date: (o.eventDate || '').slice(0, 10),
            img: media.identifier || '',
          });
          if (items.length >= 40) break;
        }
        return jsonResponse({ items, count: items.length, source: 'GBIF' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `GBIF: ${e.message}` });
      }
    }

    // ── URSPRUNG: Sternenhimmel heute (visibleplanets.dev, kein Key) ──────────
    // GET /api/intel/starsky?lat=51&lon=10
    if (path === '/api/intel/starsky' && method === 'GET') {
      const lat = url.searchParams.get('lat') || '51.16';
      const lon = url.searchParams.get('lon') || '10.45';
      try {
        const r = await fetch(
          `https://api.visibleplanets.dev/v3?latitude=${lat}&longitude=${lon}`,
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const items = (data.data || []).map(p => ({
          name: p.name || '',
          constellation: p.constellation || '',
          altitude: typeof p.altitude === 'number' ? +p.altitude.toFixed(1) : null,
          azimuth: typeof p.azimuth === 'number' ? +p.azimuth.toFixed(0) : null,
          magnitude: p.magnitude,
          nakedEye: p.nakedEyeObject === true,
        }));
        return jsonResponse({ items, count: items.length, source: 'visibleplanets.dev' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `Sky: ${e.message}` });
      }
    }

    // ── URSPRUNG: Naturphaenomene weltweit (NASA EONET, kein Key) ─────────────
    // GET /api/intel/naturevents
    if (path === '/api/intel/naturevents' && method === 'GET') {
      try {
        const r = await fetch(
          'https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=100',
          { signal: AbortSignal.timeout(10000) }
        );
        if (!r.ok) return jsonResponse({ items: [], count: 0 });
        const data = await r.json();
        const catDe = {
          'Severe Storms': 'Schwerer Sturm', 'Sea and Lake Ice': 'Meer-/See-Eis',
          'Drought': 'Duerre', 'Floods': 'Ueberschwemmung', 'Earthquakes': 'Erdbeben',
          'Landslides': 'Erdrutsch', 'Snow': 'Schnee', 'Dust and Haze': 'Staub/Dunst',
          'Water Color': 'Wasserfaerbung', 'Temperature Extremes': 'Temperatur-Extrem',
          'Manmade': 'Menschgemacht', 'Wildfires': 'Waldbrand', 'Volcanoes': 'Vulkan',
        };
        const items = (data.events || [])
          .filter(ev => !(ev.categories || []).some(c => c.title === 'Wildfires'))
          .map(ev => {
            const g = (ev.geometry || [])[((ev.geometry || []).length - 1)] || {};
            const c = g.coordinates || [0, 0];
            const cat = (ev.categories || [])[0] || {};
            return {
              title: ev.title || '',
              category: catDe[cat.title] || cat.title || 'Ereignis',
              date: (g.date || '').slice(0, 10),
              lat: c[1], lon: c[0],
            };
          });
        return jsonResponse({ items, count: items.length, source: 'NASA EONET' });
      } catch (e) {
        return jsonResponse({ items: [], count: 0, error: `EONET: ${e.message}` });
      }
    }


    // ── 404 ───────────────────────────────────────────────────
    return errorResponse(`Endpoint '${path}' nicht gefunden`, 404);
  },
};
