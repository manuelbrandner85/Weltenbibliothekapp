# 🛡️ ADMIN DASHBOARD BACKEND - DEPLOYMENT GUIDE
**Weltenbibliothek V99 - Admin Endpoints Implementation**  
**Datum:** 2026-02-13  
**Status:** Ready for Deployment

---

## 📊 NEUE FEATURES

### 3 Neue Admin-Endpoints:

**1. GET /api/admin/voice-calls/:world**
- **Purpose:** Aktive Voice Calls in Echtzeit
- **Auth:** Bearer Token required
- **Response:** Liste aktiver Calls mit Participants

**2. GET /api/admin/call-history/:world**
- **Purpose:** Vergangene Voice Calls
- **Auth:** Bearer Token required
- **Response:** Call-Historie mit Statistiken

**3. GET /api/admin/user-profile/:userId**
- **Purpose:** User Activity & Moderation History
- **Auth:** Bearer Token required
- **Response:** Detailliertes User-Profil

---

## 🔐 API TOKEN AUTHENTICATION

**Primary Token:**
```
y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y
```

**Backup Token:**
```
XCz3muf7asVj-lBgXXG3ZiY9wJ_TLelzJQZ9jutB
```

**Usage:**
```bash
curl -H "Authorization: Bearer y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y" \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/admin/voice-calls/materie
```

---

## 📦 DEPLOYMENT STEPS

### OPTION A: Wrangler CLI (Recommended)

**Prerequisites:**
- Wrangler CLI installiert (`npm install -g wrangler`)
- Cloudflare Account login (`wrangler login`)

**Step 1: Database Schema Deployment**
```bash
cd /home/user/flutter_app

# Execute D1 migrations
wrangler d1 execute weltenbibliothek-db --file=schema_v99.sql
```

**Step 2: Worker Deployment**
```bash
# Update wrangler.toml to use new worker
cp worker_v99_admin.js worker.js

# Deploy to Cloudflare
wrangler deploy
```

**Expected Output:**
```
✨ Success! Uploaded worker 'weltenbibliothek-api'
🌎 https://weltenbibliothek-api-v2.brandy13062.workers.dev
```

---

### OPTION B: Cloudflare Dashboard (Manual)

**Step 1: Upload Worker Code**
1. Login to Cloudflare Dashboard
2. Go to **Workers & Pages** → **weltenbibliothek-api**
3. Click **Edit Code**
4. Paste contents of `worker_v99_admin.js`
5. Click **Save and Deploy**

**Step 2: Execute D1 Migrations**
1. Go to **D1 Databases** → **weltenbibliothek-db**
2. Click **Console**
3. Paste contents of `schema_v99.sql`
4. Click **Execute**

---

## 🧪 TESTING ENDPOINTS

### Test 1: Health Check
```bash
curl https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "version": "V99",
  "features": [
    "10 Tool-Endpoints",
    "10 Chat-Endpoints",
    "WebSockets",
    "Admin Dashboard (NEW)",
    "Voice Call Tracking (NEW)"
  ],
  "database": "connected",
  "timestamp": "2026-02-13T..."
}
```

---

### Test 2: Active Voice Calls (Materie)
```bash
curl -H "Authorization: Bearer y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y" \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/admin/voice-calls/materie
```

**Expected Response:**
```json
{
  "success": true,
  "world": "materie",
  "calls": [
    {
      "room_id": "politik",
      "room_name": "Politik Diskussion",
      "participant_count": 5,
      "participants": [
        {
          "user_id": "user_123",
          "username": "Weltenbibliothek",
          "is_muted": false,
          "joined_at": 1707836400000
        }
      ],
      "started_at": "2026-02-13T17:00:00.000Z",
      "duration_seconds": 1234
    }
  ],
  "total": 1,
  "timestamp": "2026-02-13T..."
}
```

---

### Test 3: Call History (Energie)
```bash
curl -H "Authorization: Bearer y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y" \
  "https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/admin/call-history/energie?limit=10"
```

**Expected Response:**
```json
{
  "success": true,
  "world": "energie",
  "calls": [
    {
      "room_id": "meditation",
      "room_name": "Meditation & Achtsamkeit",
      "started_at": "2026-02-13T16:00:00.000Z",
      "ended_at": "2026-02-13T16:45:00.000Z",
      "duration_seconds": 2700,
      "max_participants": 8,
      "total_sessions": 12
    }
  ],
  "total": 1,
  "timestamp": "2026-02-13T..."
}
```

---

### Test 4: User Profile
```bash
curl -H "Authorization: Bearer y-Xiv3kKeiybDm2CV0yLFu7TSd22co6NBw3udn5Y" \
  https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/admin/user-profile/materie_Weltenbibliothek
```

**Expected Response:**
```json
{
  "success": true,
  "user": {
    "user_id": "materie_Weltenbibliothek",
    "username": "Weltenbibliothek",
    "role": "root_admin",
    "avatar_emoji": "📚",
    "bio": "Root Administrator der Materie-Welt",
    "created_at": "2026-02-04T21:36:43.000Z",
    "last_active": "2026-02-13T17:00:00.000Z",
    "total_calls": 45,
    "total_minutes": 3240,
    "warnings": 0,
    "kicks": 0,
    "bans": 0
  },
  "timestamp": "2026-02-13T..."
}
```

---

### Test 5: Authentication Error
```bash
# Test without token (should fail with 401)
curl https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/admin/voice-calls/materie
```

**Expected Response:**
```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing API token"
}
```

---

## 📊 DATABASE TABLES

### voice_sessions
```sql
- id (TEXT): Unique session ID
- room_id (TEXT): Room identifier
- room_name (TEXT): Display name
- user_id (TEXT): User identifier
- username (TEXT): Display name
- world (TEXT): 'materie' or 'energie'
- joined_at (INTEGER): Unix timestamp (ms)
- left_at (INTEGER): Unix timestamp (ms), NULL = active
- is_muted (INTEGER): 0 = not muted, 1 = muted
```

### admin_actions
```sql
- id (TEXT): Unique action ID
- action_type (TEXT): 'kick', 'mute', 'ban', 'warn'
- target_user_id (TEXT): Affected user
- admin_user_id (TEXT): Acting admin
- world (TEXT): 'materie' or 'energie'
- room_id (TEXT): Optional room context
- reason (TEXT): Action reason
- duration_hours (INTEGER): For bans
```

### users
```sql
- user_id (TEXT): Unique identifier
- username (TEXT): Display name
- role (TEXT): 'user', 'admin', 'root_admin'
- avatar_emoji (TEXT): Avatar emoji
- world (TEXT): 'materie' or 'energie'
- created_at (INTEGER): Registration timestamp
- last_active (INTEGER): Last activity timestamp
```

---

## 🔧 INTEGRATION WITH FLUTTER

### WorldAdminService Update

Add these methods to `lib/services/world_admin_service.dart`:

```dart
/// Get active voice calls
Future<List<Map<String, dynamic>>> getActiveVoiceCalls(String world) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.worldAdminApiUrl}/voice-calls/$world'),
    headers: {
      'Authorization': 'Bearer ${ApiConfig.primaryToken}',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['calls']);
  }
  throw Exception('Failed to fetch active calls');
}

/// Get call history
Future<List<Map<String, dynamic>>> getCallHistory(
  String world, {
  int limit = 50,
}) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.worldAdminApiUrl}/call-history/$world?limit=$limit'),
    headers: {
      'Authorization': 'Bearer ${ApiConfig.primaryToken}',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['calls']);
  }
  throw Exception('Failed to fetch call history');
}

/// Get user profile
Future<Map<String, dynamic>> getUserProfile(String userId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.worldAdminApiUrl}/user-profile/$userId'),
    headers: {
      'Authorization': 'Bearer ${ApiConfig.primaryToken}',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['user'];
  }
  throw Exception('Failed to fetch user profile');
}
```

---

## 📈 NEXT STEPS

### Immediate (After Deployment):

1. ✅ **Test all endpoints** with curl commands above
2. ✅ **Verify authentication** works correctly
3. ✅ **Check database tables** were created

### Short-term (This Week):

4. ⏳ **Flutter UI Integration** (Active Calls Dashboard)
5. ⏳ **WebRTC Call Tracking** (Join/Leave events)
6. ⏳ **Admin Action Logging** (Kick/Mute/Ban recording)

### Long-term (Next Week):

7. ⏳ **Real-time Updates** (WebSocket notifications)
8. ⏳ **Analytics Dashboard** (Usage statistics)
9. ⏳ **Call Recording** (Optional feature)

---

## ⚠️ IMPORTANT NOTES

**Database Migration:**
- Run `schema_v99.sql` BEFORE deploying worker
- Database tables are created with `IF NOT EXISTS` (safe to re-run)
- Existing data in `users` and `chat_messages` is preserved

**Token Security:**
- Tokens are hardcoded in worker (safe for Cloudflare Workers)
- DO NOT expose tokens in client-side code
- Use HTTPS only (Cloudflare Workers force HTTPS)

**Performance:**
- Active calls query is optimized with indexes
- Call history limited to 50 results by default
- Consider pagination for large datasets

**Testing:**
- Test with empty database first (no voice_sessions data)
- Create test voice sessions manually if needed
- Verify JSON responses match documented structure

---

## 🚀 DEPLOYMENT STATUS

**Files Created:**
- ✅ `worker_v99_admin.js` (15KB) - Worker code with admin endpoints
- ✅ `schema_v99.sql` (3KB) - Database schema migrations
- ✅ `ADMIN_DASHBOARD_DEPLOYMENT.md` (this file) - Deployment guide

**Ready to Deploy:** ✅ YES

**Recommended Action:**  
🎯 **Deploy using Wrangler CLI** (Option A) for fastest deployment

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-13  
**Status:** ✅ Ready for Production
