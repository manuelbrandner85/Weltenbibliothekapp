/**
 * 📸 MEDIA UPLOAD API
 * Cloudflare Worker Extension für weltenbibliothek-community-api
 * 
 * Features:
 * - Bild-Upload (JPG, PNG, WebP)
 * - Video-Upload (MP4, WebM)
 * - Cloudflare R2 Storage
 * - CDN-Auslieferung
 * - Größenlimits & Validierung
 */

import { Router } from 'itty-router';

// ===========================
// KONFIGURATION
// ===========================

const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB
const MAX_VIDEO_SIZE = 50 * 1024 * 1024; // 50 MB
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/webm'];

// ===========================
// R2 BUCKET HELPER
// ===========================

/**
 * Generiere eindeutigen Dateinamen
 */
function generateFileName(originalName, worldType, username) {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(7);
  const ext = originalName.split('.').pop();
  return `${worldType}/${username}/${timestamp}-${random}.${ext}`;
}

/**
 * Validiere Datei-Upload
 */
function validateFile(file, type) {
  const isImage = type === 'image';
  const maxSize = isImage ? MAX_IMAGE_SIZE : MAX_VIDEO_SIZE;
  const allowedTypes = isImage ? ALLOWED_IMAGE_TYPES : ALLOWED_VIDEO_TYPES;
  
  if (file.size > maxSize) {
    throw new Error(`Datei zu groß. Maximum: ${maxSize / 1024 / 1024} MB`);
  }
  
  if (!allowedTypes.includes(file.type)) {
    throw new Error(`Nicht erlaubter Dateityp: ${file.type}`);
  }
  
  return true;
}

// ===========================
// API ROUTES
// ===========================

/**
 * POST /api/media/upload
 * Upload Bild oder Video zu R2 Storage
 * 
 * FormData Body:
 * - file: File (Binary)
 * - type: 'image' | 'video'
 * - worldType: 'materie' | 'energie'
 * - username: string
 */
export async function handleMediaUpload(request, env) {
  try {
    // Parse FormData
    const formData = await request.formData();
    const file = formData.get('file');
    const type = formData.get('type'); // 'image' oder 'video'
    const worldType = formData.get('worldType'); // 'materie' oder 'energie'
    const username = formData.get('username');
    
    // Validierung
    if (!file) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Keine Datei hochgeladen'
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    if (!['image', 'video'].includes(type)) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Ungültiger Typ. Erlaubt: image, video'
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    if (!['materie', 'energie'].includes(worldType)) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Ungültiger worldType. Erlaubt: materie, energie'
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Datei validieren
    try {
      validateFile(file, type);
    } catch (error) {
      return new Response(JSON.stringify({
        success: false,
        error: error.message
      }), { status: 400, headers: { 'Content-Type': 'application/json' } });
    }
    
    // Dateinamen generieren
    const fileName = generateFileName(file.name, worldType, username);
    
    // Upload zu R2
    await env.MEDIA_BUCKET.put(fileName, file.stream(), {
      httpMetadata: {
        contentType: file.type,
      },
      customMetadata: {
        uploadedBy: username,
        worldType: worldType,
        originalName: file.name,
        uploadDate: new Date().toISOString(),
      }
    });
    
    // CDN-URL generieren
    const mediaUrl = `https://cdn.weltenbibliothek.com/${fileName}`;
    
    // In D1 Database speichern (für Tracking)
    await env.DB.prepare(`
      INSERT INTO media_uploads (
        file_name, media_url, media_type, world_type, 
        username, file_size, original_name, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `).bind(
      fileName,
      mediaUrl,
      type,
      worldType,
      username,
      file.size,
      file.name
    ).run();
    
    // Erfolgsantwort
    return new Response(JSON.stringify({
      success: true,
      mediaUrl: mediaUrl,
      mediaType: type,
      fileName: fileName,
      fileSize: file.size,
      uploadedAt: new Date().toISOString()
    }), {
      status: 201,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Media Upload Error:', error);
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
 * GET /api/media/:fileName
 * Hole Datei aus R2 Storage
 */
export async function handleMediaGet(request, env) {
  try {
    const url = new URL(request.url);
    const fileName = url.pathname.split('/').pop();
    
    // Hole aus R2
    const object = await env.MEDIA_BUCKET.get(fileName);
    
    if (!object) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Datei nicht gefunden'
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Sende Datei
    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set('Cache-Control', 'public, max-age=31536000'); // 1 Jahr Cache
    
    return new Response(object.body, { headers });
    
  } catch (error) {
    console.error('Media Get Error:', error);
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
 * DELETE /api/media/:fileName
 * Lösche Datei aus R2 Storage
 */
export async function handleMediaDelete(request, env) {
  try {
    const url = new URL(request.url);
    const fileName = url.pathname.split('/').pop();
    const username = url.searchParams.get('username');
    
    // Prüfe Berechtigung (nur eigene Dateien löschen)
    const result = await env.DB.prepare(`
      SELECT username FROM media_uploads WHERE file_name = ?
    `).bind(fileName).first();
    
    if (!result || result.username !== username) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Keine Berechtigung'
      }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Lösche aus R2
    await env.MEDIA_BUCKET.delete(fileName);
    
    // Lösche aus Database
    await env.DB.prepare(`
      DELETE FROM media_uploads WHERE file_name = ?
    `).bind(fileName).run();
    
    return new Response(JSON.stringify({
      success: true,
      message: 'Datei gelöscht'
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    console.error('Media Delete Error:', error);
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
// DATABASE SCHEMA
// ===========================

/**
 * D1 SQL Schema für Media Tracking
 * 
 * Führe aus in Cloudflare Dashboard:
 */

/*
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
*/

// ===========================
// WRANGLER CONFIGURATION
// ===========================

/**
 * Füge zu wrangler.toml hinzu:
 * 
 * [[r2_buckets]]
 * binding = "MEDIA_BUCKET"
 * bucket_name = "weltenbibliothek-media"
 * preview_bucket_name = "weltenbibliothek-media-preview"
 * 
 * [[d1_databases]]
 * binding = "DB"
 * database_name = "weltenbibliothek-db"
 * database_id = "your-d1-database-id"
 */

// ===========================
// ROUTER INTEGRATION
// ===========================

/**
 * Füge zu routes.js hinzu:
 * 
 * import { handleMediaUpload, handleMediaGet, handleMediaDelete } from './media-upload.js';
 * 
 * router.post('/api/media/upload', handleMediaUpload);
 * router.get('/api/media/:fileName', handleMediaGet);
 * router.delete('/api/media/:fileName', handleMediaDelete);
 */

export default {
  handleMediaUpload,
  handleMediaGet,
  handleMediaDelete
};
