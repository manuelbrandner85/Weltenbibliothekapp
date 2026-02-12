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
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarUploadService {
  static const String _avatarKeyPrefix = 'user_avatar_';
  static const String _backendUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
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
  
  /// Upload avatar to Cloudflare R2
  Future<String?> uploadAvatar(File imageFile, String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('⬆️ Uploading avatar for user $userId...');
      }
      
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Upload to backend
      final response = await http.post(
        Uri.parse('$_backendUrl/api/avatar/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'image_data': base64Image,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final avatarUrl = data['avatar_url'] as String;
        
        // Save to local storage
        await saveAvatarUrl(userId, avatarUrl);
        
        if (kDebugMode) {
          debugPrint('✅ Avatar uploaded: $avatarUrl');
        }
        
        return avatarUrl;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Upload failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading avatar: $e');
      }
      return null;
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
  
  /// Delete avatar
  Future<bool> deleteAvatar(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ Deleting avatar for user $userId...');
      }
      
      // Delete from backend
      final response = await http.delete(
        Uri.parse('$_backendUrl/api/avatar/$userId'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Delete from local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_avatarKeyPrefix$userId');
        
        if (kDebugMode) {
          debugPrint('✅ Avatar deleted');
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting avatar: $e');
      }
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
