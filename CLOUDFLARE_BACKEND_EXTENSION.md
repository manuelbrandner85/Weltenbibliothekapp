# 🚀 CLOUDFLARE WORKER BACKEND-ERWEITERUNG

## 📋 Übersicht

Diese Dokumentation beschreibt die komplette Backend-Erweiterung für:
1. **📸 Media-Upload** (Bilder & Videos)
2. **💬 Chat-Reaktionen** (Emoji-Reactions)

---

## 1️⃣ MEDIA-UPLOAD API

### **Features**:
- ✅ Bild-Upload (JPG, PNG, WebP)
- ✅ Video-Upload (MP4, WebM)
- ✅ Cloudflare R2 Storage
- ✅ CDN-Auslieferung
- ✅ Größenlimits (5 MB Bilder, 50 MB Videos)
- ✅ Automatische Validierung
- ✅ Datei-Tracking in D1 Database

### **API Endpoints**:

#### **1. Upload Media**
```http
POST /api/media/upload
Content-Type: multipart/form-data

FormData:
- file: Binary (Image/Video File)
- type: 'image' | 'video'
- worldType: 'materie' | 'energie'
- username: string

Response (201 Created):
{
  "success": true,
  "mediaUrl": "https://cdn.weltenbibliothek.com/energie/user123/1234567890-abc123.jpg",
  "mediaType": "image",
  "fileName": "energie/user123/1234567890-abc123.jpg",
  "fileSize": 1024000,
  "uploadedAt": "2025-01-19T16:30:00Z"
}

Error (400 Bad Request):
{
  "success": false,
  "error": "Datei zu groß. Maximum: 5 MB"
}
```

#### **2. Get Media**
```http
GET /api/media/:fileName

Response: Binary File (Image/Video)
Headers:
- Content-Type: image/jpeg | video/mp4
- Cache-Control: public, max-age=31536000
```

#### **3. Delete Media**
```http
DELETE /api/media/:fileName?username=currentUser

Response (200 OK):
{
  "success": true,
  "message": "Datei gelöscht"
}

Error (403 Forbidden):
{
  "success": false,
  "error": "Keine Berechtigung"
}
```

### **D1 Database Schema**:

```sql
CREATE TABLE IF NOT EXISTS media_uploads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file_name TEXT NOT NULL UNIQUE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK(media_type IN ('image', 'video')),
  world_type TEXT NOT NULL CHECK(world_type IN ('materie', 'energie')),
  username TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  original_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  
  INDEX idx_username (username),
  INDEX idx_world_type (world_type),
  INDEX idx_created_at (created_at)
);
```

### **R2 Bucket Configuration**:

```toml
# wrangler.toml

[[r2_buckets]]
binding = "MEDIA_BUCKET"
bucket_name = "weltenbibliothek-media"
preview_bucket_name = "weltenbibliothek-media-preview"
```

### **Datei-Struktur in R2**:

```
weltenbibliothek-media/
├── materie/
│   ├── user123/
│   │   ├── 1234567890-abc123.jpg
│   │   └── 1234567891-def456.mp4
│   └── user456/
│       └── 1234567892-ghi789.png
└── energie/
    ├── user789/
    │   └── 1234567893-jkl012.jpg
    └── ...
```

---

## 2️⃣ CHAT-REAKTIONEN API

### **Features**:
- ✅ Reaktionen hinzufügen (18 Emojis)
- ✅ Reaktionen entfernen
- ✅ Reaktionen zählen
- ✅ User-Reaktionen tracken
- ✅ Duplikat-Prävention
- ✅ Automatische Löschung bei Nachrichten-Löschung

### **Erlaubte Emojis**:

```javascript
// Standard
👍 ❤️ 😂 😮 😢 🙏

// Energie
✨ 🔥 💡 🎯 🌟 ⚡

// Materie
📚 🔍 🧠 💭 🗣️ 👁️
```

### **API Endpoints**:

#### **1. Add Reaction**
```http
POST /chat/messages/:messageId/reactions
Content-Type: application/json

Body:
{
  "emoji": "👍",
  "username": "currentUser"
}

Response (201 Created):
{
  "success": true,
  "reaction": {
    "id": 123,
    "messageId": "msg_456",
    "emoji": "👍",
    "username": "currentUser",
    "createdAt": "2025-01-19T16:30:00Z"
  },
  "counts": {
    "👍": 5,
    "❤️": 3
  }
}

Error (409 Conflict):
{
  "success": false,
  "error": "Du hast bereits mit diesem Emoji reagiert"
}
```

#### **2. Remove Reaction**
```http
DELETE /chat/messages/:messageId/reactions/:emoji?username=currentUser

Response (200 OK):
{
  "success": true,
  "message": "Reaktion entfernt",
  "counts": {
    "👍": 4,
    "❤️": 3
  }
}
```

#### **3. Get All Reactions**
```http
GET /chat/messages/:messageId/reactions

Response (200 OK):
{
  "success": true,
  "messageId": "msg_456",
  "reactions": [
    {
      "emoji": "👍",
      "count": 5,
      "usernames": ["user1", "user2", "user3", "user4", "user5"]
    },
    {
      "emoji": "❤️",
      "count": 3,
      "usernames": ["user6", "user7", "user8"]
    }
  ],
  "totalReactions": 8
}
```

#### **4. Get User Reactions**
```http
GET /chat/messages/:messageId/reactions/user/:username

Response (200 OK):
{
  "success": true,
  "messageId": "msg_456",
  "username": "currentUser",
  "reactions": [
    {
      "emoji": "👍",
      "created_at": "2025-01-19T16:30:00Z"
    }
  ]
}
```

### **D1 Database Schema**:

```sql
CREATE TABLE IF NOT EXISTS chat_reactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  message_id TEXT NOT NULL,
  emoji TEXT NOT NULL,
  username TEXT NOT NULL,
  created_at TEXT NOT NULL,
  
  -- Verhindere Duplikate
  UNIQUE(message_id, username, emoji),
  
  -- Foreign Key
  FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
  
  -- Indizes
  INDEX idx_message_id (message_id),
  INDEX idx_username (username),
  INDEX idx_emoji (emoji),
  INDEX idx_created_at (created_at)
);

-- Trigger: Auto-Delete
CREATE TRIGGER IF NOT EXISTS delete_reactions_on_message_delete
AFTER DELETE ON chat_messages
FOR EACH ROW
BEGIN
  DELETE FROM chat_reactions WHERE message_id = OLD.id;
END;
```

---

## 📱 FLUTTER INTEGRATION

### **1. CloudflareApiService erweitern**:

```dart
// lib/services/cloudflare_api_service.dart

class CloudflareApiService {
  static const String baseUrl = 'https://weltenbibliothek-community-api.brandy13062.workers.dev';
  static const String apiToken = 'your-api-token';
  
  // ===========================
  // MEDIA UPLOAD
  // ===========================
  
  Future<Map<String, dynamic>> uploadMedia({
    required File file,
    required String type, // 'image' oder 'video'
    required String worldType, // 'materie' oder 'energie'
    required String username,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/media/upload'),
    );
    
    request.headers['Authorization'] = 'Bearer $apiToken';
    
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
    
    request.fields['type'] = type;
    request.fields['worldType'] = worldType;
    request.fields['username'] = username;
    
    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 201) {
      return json.decode(responseData);
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }
  
  Future<void> deleteMedia(String fileName, String username) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/media/$fileName?username=$username'),
      headers: {'Authorization': 'Bearer $apiToken'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }
  
  // ===========================
  // CHAT REACTIONS
  // ===========================
  
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
  
  Future<void> removeReaction(String messageId, String emoji, String username) async {
    final encodedEmoji = Uri.encodeComponent(emoji);
    final response = await http.delete(
      Uri.parse('$baseUrl/chat/messages/$messageId/reactions/$encodedEmoji?username=$username'),
      headers: {'Authorization': 'Bearer $apiToken'},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to remove reaction: ${response.statusCode}');
    }
  }
  
  Future<Map<String, dynamic>> getReactions(String messageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/messages/$messageId/reactions'),
      headers: {'Authorization': 'Bearer $apiToken'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load reactions: ${response.statusCode}');
    }
  }
}
```

### **2. CreatePostDialog Media-Upload aktivieren**:

```dart
// lib/widgets/create_post_dialog.dart

import 'package:image_picker/image_picker.dart';
import 'dart:io';

Future<void> _pickMedia(String mediaType) async {
  final ImagePicker picker = ImagePicker();
  
  if (mediaType == 'Bild') {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      // Upload zu Cloudflare
      try {
        final uploadResult = await CloudflareApiService().uploadMedia(
          file: File(image.path),
          type: 'image',
          worldType: widget.worldType.name,
          username: _currentUser.username,
        );
        
        setState(() {
          _selectedMediaPath = uploadResult['mediaUrl'];
          _mediaType = 'image';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Bild hochgeladen!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Upload fehlgeschlagen: $e')),
        );
      }
    }
  }
}
```

### **3. Chat Reactions aktivieren**:

```dart
// lib/screens/materie/materie_live_chat_screen.dart

Future<void> _addReaction(String messageId, String emoji) async {
  try {
    await CloudflareApiService().addReaction(
      messageId,
      emoji,
      _username,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text('$emoji '),
              Text('Reaktion gespeichert!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fehler: $e')),
      );
    }
  }
}
```

---

## 🚀 DEPLOYMENT

### **1. Cloudflare R2 Bucket erstellen**:

```bash
# Login zu Cloudflare
wrangler login

# R2 Bucket erstellen
wrangler r2 bucket create weltenbibliothek-media

# Bucket-ID notieren
```

### **2. D1 Database Schema ausführen**:

```bash
# Media Uploads Table
wrangler d1 execute weltenbibliothek-db --file=./schema-media.sql

# Chat Reactions Table
wrangler d1 execute weltenbibliothek-db --file=./schema-reactions.sql
```

### **3. Worker Code deployen**:

```bash
# Code zu Worker hinzufügen
# 1. Kopiere media-upload.js
# 2. Kopiere chat-reactions.js
# 3. Update routes.js

# Deploy
wrangler deploy
```

### **4. CDN konfigurieren**:

```bash
# Cloudflare Dashboard → R2 → Bucket Settings
# - Public Access: Enable
# - Custom Domain: cdn.weltenbibliothek.com
# - CORS: Allow *
```

---

## 📈 TESTING

### **Media Upload testen**:

```bash
curl -X POST https://weltenbibliothek-community-api.brandy13062.workers.dev/api/media/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test-image.jpg" \
  -F "type=image" \
  -F "worldType=materie" \
  -F "username=testuser"
```

### **Chat Reactions testen**:

```bash
# Add Reaction
curl -X POST https://weltenbibliothek-community-api.brandy13062.workers.dev/chat/messages/msg123/reactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"emoji":"👍","username":"testuser"}'

# Get Reactions
curl https://weltenbibliothek-community-api.brandy13062.workers.dev/chat/messages/msg123/reactions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🎯 NEXT STEPS

1. ✅ **Code-Dateien deployen**:
   - `cloudflare_worker_media_upload.js`
   - `cloudflare_worker_chat_reactions.js`

2. ✅ **Flutter App aktualisieren**:
   - CloudflareApiService erweitern
   - CreatePostDialog aktivieren
   - Chat Screens aktivieren

3. ✅ **Testing**:
   - Media-Upload testen
   - Reaktionen testen
   - Error Handling prüfen

4. ✅ **Production**:
   - API Token sichern
   - Rate Limiting aktivieren
   - Monitoring einrichten

---

**🎉 Backend-Erweiterung komplett dokumentiert und bereit für Deployment!**
