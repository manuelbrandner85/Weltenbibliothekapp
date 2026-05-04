/// 👤 AVATAR UPLOAD SERVICE
/// Handles avatar image selection, upload, and storage
///
/// Features:
/// - Image picker integration
/// - Image compression
/// - Upload to Cloudflare R2
/// - Local caching
/// - Avatar management
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception mit nutzerlesbarer deutscher Fehlermeldung. Wird von
/// [AvatarUploadService.uploadAvatarOrThrow] geworfen — Caller kann den Text
/// 1:1 im Error-Dialog anzeigen.
class AvatarUploadException implements Exception {
  final String message;
  AvatarUploadException(this.message);
  @override
  String toString() => message;
}

class AvatarUploadService {
  static const String _avatarKeyPrefix = 'user_avatar_';

  final ImagePicker _picker = ImagePicker();
  
  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kDebugMode) {
          debugPrint('🖼️ Image picked: ${image.path}');
        }
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error picking image: $e');
      }
      return null;
    }
  }
  
  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kDebugMode) {
          debugPrint('📸 Photo taken: ${image.path}');
        }
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error taking photo: $e');
      }
      return null;
    }
  }
  
  /// Upload avatar to Cloudflare R2 — Legacy-API mit null-Return bei Fehler.
  /// Bestehende Caller erwarten `String?`. Backward-compatible.
  /// Für Error-Dialogs lieber [uploadAvatarOrThrow] nutzen.
  Future<String?> uploadAvatar(File imageFile, String userId) async {
    try {
      return await uploadAvatarOrThrow(imageFile, userId);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ uploadAvatar swallowed: $e');
      return null;
    }
  }

  /// Upload avatar direkt zu Supabase Storage (Bucket: avatars).
  /// Pfad: {userId}/avatar.jpg — upsert:true ersetzt automatisch das alte Bild.
  /// Speichert die öffentliche URL in profiles.avatar_url.
  Future<String> uploadAvatarOrThrow(File imageFile, String userId) async {
    if (kDebugMode) debugPrint('⬆️ Uploading avatar for user $userId to Supabase Storage...');

    try {
      final client = Supabase.instance.client;

      if (client.auth.currentUser == null) {
        throw AvatarUploadException('Nicht eingeloggt — bitte erneut anmelden.');
      }

      final bytes = await imageFile.readAsBytes();
      // Dateiendung aus Pfad ermitteln, fallback auf jpg
      final ext = imageFile.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      final storagePath = '$userId/avatar.$safeExt';
      final mimeType = safeExt == 'png' ? 'image/png' : 'image/jpeg';

      // Altes Bild mit upsert:true überschreiben (gleicher Pfad)
      await client.storage.from('avatars').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(upsert: true, contentType: mimeType),
      );

      // Cache-Buster damit der Browser/App-Cache das neue Bild lädt
      final publicUrl = client.storage.from('avatars').getPublicUrl(storagePath);
      final avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // profiles.avatar_url in Supabase DB aktualisieren
      await client.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

      await saveAvatarUrl(userId, avatarUrl);
      if (kDebugMode) debugPrint('✅ Avatar uploaded: $avatarUrl');
      return avatarUrl;
    } on AvatarUploadException {
      rethrow;
    } on StorageException catch (e) {
      if (kDebugMode) debugPrint('❌ Supabase Storage error: $e');
      if (e.statusCode == '413') {
        throw AvatarUploadException('Bild zu groß. Bitte kleineres wählen.');
      }
      throw AvatarUploadException('Upload fehlgeschlagen: ${e.message}');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error uploading avatar: $e');
      throw AvatarUploadException(
        'Verbindung fehlgeschlagen. Bitte erneut versuchen.',
      );
    }
  }
  
  /// Save avatar URL to local storage
  Future<void> saveAvatarUrl(String userId, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_avatarKeyPrefix$userId', url);
      
      if (kDebugMode) {
        debugPrint('💾 Avatar URL saved locally');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving avatar URL: $e');
      }
    }
  }
  
  /// Get avatar URL from local storage
  Future<String?> getAvatarUrl(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_avatarKeyPrefix$userId');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting avatar URL: $e');
      }
      return null;
    }
  }
  
  /// Delete avatar aus Supabase Storage + profiles.avatar_url leeren.
  Future<bool> deleteAvatar(String userId) async {
    try {
      if (kDebugMode) debugPrint('🗑️ Deleting avatar for user $userId...');
      final client = Supabase.instance.client;
      // Alle gängigen Endungen versuchen
      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          await client.storage.from('avatars').remove(['$userId/avatar.$ext']);
        } catch (_) {}
      }
      await client.from('profiles').update({'avatar_url': null}).eq('id', userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_avatarKeyPrefix$userId');
      if (kDebugMode) debugPrint('✅ Avatar deleted');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error deleting avatar: $e');
      return false;
    }
  }
  
  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profilbild auswählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Avatar widget with cached image
  static Widget avatarWidget({
    String? avatarUrl,
    required String userName,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: size * 0.6,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.grey[600],
              ),
      ),
    );
  }
}
