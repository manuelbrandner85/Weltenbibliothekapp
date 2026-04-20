import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 🎬 VIDEO SERVICE - Video Upload mit Kompression
class VideoService {
  static const int maxDurationSeconds = 120; // 2 Minuten
  static const int maxSizeMB = 10;
  
  /// Video vom Gerät auswählen
  static Future<XFile?> pickVideo() async {
    final picker = ImagePicker();
    try {
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: maxDurationSeconds),
      );
      
      if (video != null) {
        // Check file size
        final bytes = await video.readAsBytes();
        final sizeMB = bytes.length / (1024 * 1024);
        
        if (sizeMB > maxSizeMB) {
          if (kDebugMode) {
            debugPrint('⚠️ Video zu groß: ${sizeMB.toStringAsFixed(1)} MB (Max: $maxSizeMB MB)');
          }
          return null;
        }
        
        if (kDebugMode) {
          debugPrint('✅ Video ausgewählt: ${video.name} (${sizeMB.toStringAsFixed(1)} MB)');
        }
      }
      
      return video;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video-Auswahl Fehler: $e');
      }
      return null;
    }
  }
  
  /// Video mit Kamera aufnehmen
  static Future<XFile?> recordVideo() async {
    final picker = ImagePicker();
    try {
      final video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: maxDurationSeconds),
      );
      return video;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video-Aufnahme Fehler: $e');
      }
      return null;
    }
  }
  
  /// Video-Metadaten extrahieren
  static Future<Map<String, dynamic>?> getVideoMetadata(XFile video) async {
    try {
      final bytes = await video.readAsBytes();
      final sizeMB = bytes.length / (1024 * 1024);
      
      return {
        'name': video.name,
        'size': bytes.length,
        'sizeMB': sizeMB,
        'path': video.path,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Video-Metadaten Fehler: $e');
      }
      return null;
    }
  }
}

/// 🎥 GIF SERVICE - GIF-Suche mit Tenor API
class GifService {
  static const String tenorApiKey = 'AIzaSyAyimkuYQYF_FXVALexPuGQctUWRURdCYQ'; // Demo Key
  static const String baseUrl = 'https://tenor.googleapis.com/v2';
  
  /// Trending GIFs laden
  static Future<List<Map<String, dynamic>>> getTrendingGifs({int limit = 20}) async {
    try {
      final url = '$baseUrl/featured?key=$tenorApiKey&limit=$limit&media_filter=gif';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((gif) {
          final media = gif['media_formats']['gif'];
          return {
            'id': gif['id'],
            'title': gif['content_description'] ?? 'GIF',
            'url': media['url'],
            'preview': media['url'],
            'width': media['dims'][0],
            'height': media['dims'][1],
          };
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Trending GIFs Fehler: $e');
      }
    }
    
    return [];
  }
  
  /// GIFs nach Query suchen
  static Future<List<Map<String, dynamic>>> searchGifs(String query, {int limit = 20}) async {
    if (query.isEmpty) return getTrendingGifs(limit: limit);
    
    try {
      final url = '$baseUrl/search?key=$tenorApiKey&q=$query&limit=$limit&media_filter=gif';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((gif) {
          final media = gif['media_formats']['gif'];
          return {
            'id': gif['id'],
            'title': gif['content_description'] ?? query,
            'url': media['url'],
            'preview': media['url'],
            'width': media['dims'][0],
            'height': media['dims'][1],
          };
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ GIF-Suche Fehler: $e');
      }
    }
    
    return [];
  }
  
  /// GIF-Kategorien
  static List<String> getCategories() {
    return [
      'Trending',
      'Funny',
      'Reaction',
      'Love',
      'Sad',
      'Happy',
      'Dance',
      'Celebration',
      'Animals',
      'Nature',
    ];
  }
}

/// 📸 MULTI-IMAGE SERVICE - Multiple Bilder Upload
class MultiImageService {
  static const int maxImages = 5;
  static const int maxSizeMBPerImage = 2;
  
  /// Multiple Bilder auswählen
  static Future<List<XFile>> pickMultipleImages() async {
    final picker = ImagePicker();
    try {
      final images = await picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      
      if (images.length > maxImages) {
        if (kDebugMode) {
          debugPrint('⚠️ Zu viele Bilder: ${images.length} (Max: $maxImages)');
        }
        return images.take(maxImages).toList();
      }
      
      // Filter zu große Bilder
      final validImages = <XFile>[];
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final sizeMB = bytes.length / (1024 * 1024);
        
        if (sizeMB <= maxSizeMBPerImage) {
          validImages.add(image);
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ Bild zu groß übersprungen: ${image.name} (${sizeMB.toStringAsFixed(1)} MB)');
          }
        }
      }
      
      if (kDebugMode) {
        debugPrint('✅ ${validImages.length} Bilder ausgewählt');
      }
      
      return validImages;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Multi-Image Auswahl Fehler: $e');
      }
      return [];
    }
  }
  
  /// Einzelnes Bild zur Liste hinzufügen
  static Future<XFile?> pickSingleImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final sizeMB = bytes.length / (1024 * 1024);
        
        if (sizeMB > maxSizeMBPerImage) {
          if (kDebugMode) {
            debugPrint('⚠️ Bild zu groß: ${sizeMB.toStringAsFixed(1)} MB');
          }
          return null;
        }
      }
      
      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Single-Image Auswahl Fehler: $e');
      }
      return null;
    }
  }
  
  /// Bild mit Kamera aufnehmen
  static Future<XFile?> takePhoto() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Foto-Aufnahme Fehler: $e');
      }
      return null;
    }
  }
}

/// 📊 MEDIA METADATA - Gemeinsame Metadaten-Extraktion
class MediaMetadataService {
  static Future<Map<String, dynamic>> getImageMetadata(XFile image) async {
    final bytes = await image.readAsBytes();
    final sizeMB = bytes.length / (1024 * 1024);
    
    return {
      'name': image.name,
      'size': bytes.length,
      'sizeMB': sizeMB,
      'path': image.path,
      'type': 'image',
    };
  }
  
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
