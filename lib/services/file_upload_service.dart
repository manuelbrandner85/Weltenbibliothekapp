/// 📁 File Upload Service
/// Handles file uploads to Cloudflare R2 Storage
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'cloudflare_api_service.dart';

class FileUploadService extends ChangeNotifier {
  static final FileUploadService _instance = FileUploadService._internal();
  factory FileUploadService() => _instance;
  FileUploadService._internal();

  final String _baseUrl = CloudflareApiService.chatFeaturesApiUrl;
  
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _lastUploadedUrl;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get lastUploadedUrl => _lastUploadedUrl;

  /// Pick file from device
  Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        withData: kIsWeb, // Load bytes on web
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FileUpload] Pick error: $e');
      }
      return null;
    }
  }

  /// Upload file to Cloudflare R2
  Future<String?> uploadFile({
    required PlatformFile file,
    String folder = 'uploads',
  }) async {
    try {
      _isUploading = true;
      _uploadProgress = 0.0;
      notifyListeners();

      // Get file bytes
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else {
        // Mobile: Read from path
        // fileBytes = await File(file.path!).readAsBytes();
        if (kDebugMode) {
          debugPrint('⚠️ [FileUpload] Mobile upload not implemented');
        }
        return null;
      }

      if (fileBytes == null) {
        throw Exception('Failed to read file bytes');
      }

      // Prepare multipart request
      final uri = Uri.parse('$_baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: file.name,
        ),
      );

      request.fields['folder'] = folder;
      request.fields['size'] = fileBytes.length.toString();

      if (kDebugMode) {
        debugPrint('📤 [FileUpload] Uploading: ${file.name} (${fileBytes.length} bytes)');
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastUploadedUrl = data['url'];
        _uploadProgress = 1.0;

        if (kDebugMode) {
          debugPrint('✅ [FileUpload] Uploaded: $_lastUploadedUrl');
        }

        _isUploading = false;
        notifyListeners();
        return _lastUploadedUrl;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FileUpload] Upload error: $e');
      }
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get file info from URL
  Future<Map<String, dynamic>?> getFileInfo(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/file-info?url=$url'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FileUpload] Get file info error: $e');
      }
      return null;
    }
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get file extension
  static String getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is image
  static bool isImageFile(String filename) {
    final ext = getFileExtension(filename);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  /// Check if file is document
  static bool isDocumentFile(String filename) {
    final ext = getFileExtension(filename);
    return ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(ext);
  }

  /// Check if file is video
  static bool isVideoFile(String filename) {
    final ext = getFileExtension(filename);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }
}
