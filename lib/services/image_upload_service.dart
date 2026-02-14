import 'dart:convert';
import 'dart:async';  // ✅ TimeoutException
import 'dart:io';  // ✅ SocketException
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Cloudflare Image Upload Service
/// Uploads profile images to Cloudflare R2 or Images
class ImageUploadService {
  // Cloudflare Worker Endpoint für Image Upload
  static const String uploadEndpoint = 
      'https://weltenbibliothek-api-v2.brandy13062.workers.dev/api/media/upload';
  
  // Singleton Pattern
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();
  
  /// Upload image to Cloudflare
  /// Returns CDN URL on success
  Future<String> uploadProfileImage({
    required XFile imageFile,
    required String userId,
    String? profileType, // 'materie' oder 'energie'
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 Starting image upload for user: $userId');
      }
      
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      if (kDebugMode) {
        debugPrint('📦 Image size: ${bytes.length} bytes (${(bytes.length / 1024).toStringAsFixed(2)} KB)');
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadEndpoint));
      
      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // ⚠️ Worker erwartet 'file' nicht 'image'
          bytes,
          filename: '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      // Add metadata
      request.fields['user_id'] = userId;
      if (profileType != null) {
        request.fields['profile_type'] = profileType;
      }
      
      // Send request with longer timeout (60 seconds)
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout after 60 seconds - please check your connection');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) {
        debugPrint('📡 Upload Status: ${response.statusCode}');
        debugPrint('📦 Upload Response Body: ${response.body}');
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // 🐛 DEBUG: Print full response
        if (kDebugMode) {
          debugPrint('✅ Upload Response Data: $data');
        }
        
        final imageUrl = data['media_url'] as String?; // ⚠️ Worker gibt 'media_url' zurück
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Image uploaded successfully: $imageUrl');
          }
          return imageUrl;
        } else {
          if (kDebugMode) {
            debugPrint('❌ No media_url in response: $data');
          }
          throw Exception('No media_url in response');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Upload failed: ${response.statusCode}');
          debugPrint('❌ Response: ${response.body}');
        }
        throw Exception('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Upload error: $e');
      }
      rethrow;
    }
  }
  
  /// Upload image with base64 encoding (fallback method)
  Future<String> uploadProfileImageBase64({
    required String base64Image,
    required String userId,
    String? profileType,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 Starting base64 image upload for user: $userId');
      }
      
      final response = await http.post(
        Uri.parse(uploadEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'user_id': userId,
          'profile_type': profileType,
          'encoding': 'base64',
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final imageUrl = data['url'] as String?;
        
        if (imageUrl != null) {
          if (kDebugMode) {
            debugPrint('✅ Image uploaded successfully: $imageUrl');
          }
          return imageUrl;
        } else {
          throw Exception('No URL in response');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Upload failed: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Upload error: $e');
      }
      rethrow;
    }
  }
  
  /// Delete image from Cloudflare
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      if (kDebugMode) {
        debugPrint('🗑️ Deleting image: $imageUrl');
      }
      
      final response = await http.delete(
        Uri.parse('$uploadEndpoint/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': imageUrl}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Image deleted successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Delete failed: ${response.statusCode}');
        }
        return false;
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Network: Keine Internetverbindung');
      }
      return false;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Timeout: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Delete error: $e $e');
      }
      return false;
    }
  }
}
