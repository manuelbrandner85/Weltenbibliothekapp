import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'cloudflare_api_service.dart';

/// Cloudflare R2-basierter User Content Service
/// Ersetzt Firebase Storage
class CloudflareUserContentService {
  static String get baseUrl => ApiConfig.baseUrl;
  final CloudflareApiService _api = CloudflareApiService();
  
  // Singleton
  static final CloudflareUserContentService _instance = CloudflareUserContentService._internal();
  factory CloudflareUserContentService() => _instance;
  CloudflareUserContentService._internal();

  /// Upload file to Cloudflare R2
  Future<Map<String, dynamic>> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
    required String type, // 'image', 'video', or 'audio'
    required String userId,
  }) async {
    try {
      // FIX: Use named parameters with all required fields
      final result = await _api.uploadFile(
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
        type: type,
        userId: userId,
      );
      return result;
    } catch (e) {
      debugPrint('⚠️ Upload error: $e');
      rethrow;
    }
  }

  /// Create user content entry
  Future<Map<String, dynamic>> createUserContent({
    required String userId,
    required String realm, // 'materie' or 'energie'
    required String contentType, // 'image', 'video', 'audio'
    required String title,
    required String fileUrl,
    String? description,
    String? thumbnailUrl,
    int? fileSize,
    List<String>? tags,
  }) async {
    try {
      final result = await _api.createUserContent({
        'user_id': userId,
        'realm': realm,
        'content_type': contentType,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'thumbnail_url': thumbnailUrl,
        'file_size': fileSize ?? 0,
        'tags': tags ?? [],
      });
      return result;
    } catch (e) {
      debugPrint('⚠️ Create content error: $e');
      rethrow;
    }
  }

  /// Get user content feed
  Future<List<Map<String, dynamic>>> getUserContent({
    String? realm,
    String? type,
    int limit = 20,
  }) async {
    try {
      final results = await _api.getUserContent(
        realm: realm,
        type: type,
        limit: limit,
      );
      return results;
    } catch (e) {
      debugPrint('⚠️ Get content error: $e');
      return [];
    }
  }

  /// Upload image/video with automatic processing
  Future<Map<String, dynamic>> uploadMedia({
    required List<int> fileBytes,
    required String fileName,
    required String userId,
    required String realm,
    required String title,
    String? description,
    List<String>? tags,
  }) async {
    try {
      // 1. Upload file to R2
      debugPrint('📤 Uploading file to R2...');
      final mediaType = _getMediaType(fileName);
      final uploadResult = await uploadFile(
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: _getContentType(fileName),
        type: mediaType, // 'image', 'video', or 'audio'
        userId: userId,
      );

      final fileUrl = '$baseUrl${uploadResult['fileUrl']}';
      final fileSize = uploadResult['fileSize'] as int;

      // 2. Create content entry in database
      debugPrint('💾 Creating content entry...');
      final contentResult = await createUserContent(
        userId: userId,
        realm: realm,
        contentType: _getMediaType(fileName),
        title: title,
        fileUrl: fileUrl,
        description: description,
        fileSize: fileSize,
        tags: tags,
      );

      debugPrint('✅ Media uploaded successfully!');
      return contentResult;
    } catch (e) {
      debugPrint('❌ Upload media error: $e');
      rethrow;
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'application/octet-stream';
    }
  }

  String _getMediaType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return 'image';
    } else if (['mp4', 'webm', 'mov'].contains(ext)) {
      return 'video';
    } else if (['mp3', 'wav', 'ogg'].contains(ext)) {
      return 'audio';
    }
    return 'image'; // default
  }

  /// Like content
  Future<void> likeContent(String contentId) async {
    // This would require additional API endpoint
    debugPrint('👍 Liked content: $contentId');
  }

  /// Report content
  Future<void> reportContent(String contentId, String reason) async {
    // This would require additional API endpoint
    debugPrint('🚫 Reported content: $contentId - $reason');
  }
}
