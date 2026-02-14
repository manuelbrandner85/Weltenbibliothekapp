import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/storage/unified_storage_service.dart';

class ContentManagementService {
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all content for a world
  static Future<List<Map<String, dynamic>>> getContent(
    String world, {
    String? status,
    int limit = 50,
  }) async {
    try {
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);

      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No username found for world: $world');
        }
        return [];
      }

      final url = Uri.parse('$_baseUrl/api/admin/content/$world?limit=$limit${status != null ? '&status=$status' : ''}');

      if (kDebugMode) {
        debugPrint('📝 Loading content: $world (status: $status)');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
      ).timeout(
        _timeout,
        onTimeout: () => throw TimeoutException('Get content timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> content = data['content'] ?? [];

        if (kDebugMode) {
          debugPrint('✅ Content loaded: ${content.length} items');
        }

        return content.cast<Map<String, dynamic>>();
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Content load failed: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return [];
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Admin content: Keine Internetverbindung');
      }
      return [];
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Admin content: Timeout - $e');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content load error: $e');
      }
      return [];
    }
  }

  /// Toggle featured status
  static Future<bool> toggleFeature(String world, String contentId) async {
    try {
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);

      if (username == null || username.isEmpty) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/api/admin/content/$world/$contentId/feature');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException('Feature-Toggle Timeout (30s)');
        },
      );

      if (kDebugMode && response.statusCode == 200) {
        debugPrint('✅ Feature toggle successful');
      }

      return response.statusCode == 200;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Feature toggle: Keine Internetverbindung');
      }
      return false;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Feature toggle: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Feature toggle error: $e');
      }
      return false;
    }
  }

  /// Toggle verified status
  static Future<bool> toggleVerify(String world, String contentId) async {
    try {
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);

      if (username == null || username.isEmpty) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/api/admin/content/$world/$contentId/verify');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException('Verify-Toggle Timeout (30s)');
        },
      );

      if (kDebugMode && response.statusCode == 200) {
        debugPrint('✅ Verify toggle successful');
      }

      return response.statusCode == 200;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Verify toggle: Keine Internetverbindung');
      }
      return false;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Verify toggle: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Verify toggle error: $e');
      }
      return false;
    }
  }

  /// Delete content
  static Future<bool> deleteContent(String world, String contentId) async {
    try {
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);

      if (username == null || username.isEmpty) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/api/admin/content/$world/$contentId');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException('Content-Delete Timeout (30s)');
        },
      );

      if (kDebugMode && response.statusCode == 200) {
        debugPrint('✅ Content deleted successfully');
      }

      return response.statusCode == 200;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content delete: Keine Internetverbindung');
      }
      return false;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content delete: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content delete error: $e');
      }
      return false;
    }
  }

  /// Create new content
  static Future<bool> createContent({
    required String world,
    required String title,
    required String body,
    String? category,
  }) async {
    try {
      final storage = UnifiedStorageService();
      final username = storage.getUsername(world);

      if (username == null || username.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ No username found for world: $world');
        }
        return false;
      }

      final url = Uri.parse('$_baseUrl/api/content/create');

      if (kDebugMode) {
        debugPrint('📝 Creating content: $title by $username');
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $username',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'world': world,
          'title': title,
          'content_body': body,
          'category': category,
        }),
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException('Content-Create Timeout (30s)');
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Content created successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Content creation failed: ${response.statusCode}');
          debugPrint('   Response: ${response.body}');
        }
        return false;
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content create: Keine Internetverbindung');
      }
      return false;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content create: $e');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Content creation error: $e');
      }
      return false;
    }
  }

  /// Get public content (no auth required)
  static Future<List<Map<String, dynamic>>> getPublicContent(
    String world, {
    int limit = 50,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/content/$world?limit=$limit');

      if (kDebugMode) {
        debugPrint('📚 Loading public content: $world');
      }

      final response = await http.get(url).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException('Public-Content Timeout (30s)');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> content = data['content'] ?? [];

        if (kDebugMode) {
          debugPrint('✅ Public content loaded: ${content.length} items');
        }

        return content.cast<Map<String, dynamic>>();
      } else {
        if (kDebugMode) {
          debugPrint('⚠️  Public content load failed: ${response.statusCode}');
        }
        return [];
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Public content: Keine Internetverbindung');
      }
      return [];
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Public content: $e');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Public content load error: $e');
      }
      return [];
    }
  }
}
