/// Content API Service - OTA Content Management
/// 
/// Enables admins to manage app content (tabs, tools, markers) dynamically
/// without app rebuilds.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'user_auth_service.dart';

/// Content API Service for OTA updates
class ContentApiService {
  static final ContentApiService _instance = ContentApiService._internal();
  factory ContentApiService() => _instance;
  ContentApiService._internal();

  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  /// Get current user's role for permission checks
  Future<String?> _getCurrentRole() async {
    final username = await UserAuthService.getUsername(world: 'energie');
    if (username == null) return null;
    
    // Check if user is admin
    if (username == 'Weltenbibliothek') return 'root_admin';
    if (username == 'Weltenbibliothekedit') return 'content_editor';
    
    return 'user';
  }
  
  /// Get tabs for a world
  Future<List<Map<String, dynamic>>> getTabs(String world) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/tabs?world=$world'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['tabs'] ?? []);
      }
      
      if (kDebugMode) {
        debugPrint('⚠️ ContentAPI: Get tabs failed: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Get tabs error: $e');
      }
      return [];
    }
  }
  
  /// Create new tab (admin only)
  Future<Map<String, dynamic>?> createTab({
    required String world,
    required String name,
    required String icon,
    String? description,
  }) async {
    try {
      final role = await _getCurrentRole();
      if (role != 'root_admin' && role != 'content_editor') {
        if (kDebugMode) {
          debugPrint('⚠️ ContentAPI: No permission to create tab');
        }
        return null;
      }
      
      final username = await UserAuthService.getUsername(world: world);
      final userId = await UserAuthService.getUserId();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/content/tabs'),
        headers: {
          'Content-Type': 'application/json',
          'X-World': world,
          'X-User-ID': userId ?? 'unknown',
          'X-Username': username ?? 'unknown',
          'X-Role': role ?? 'user',
        },
        body: json.encode({
          'world': world,
          'name': name,
          'icon': icon,
          'description': description,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          debugPrint('✅ ContentAPI: Tab created: ${data['tab']['id']}');
        }
        return data['tab'];
      }
      
      if (kDebugMode) {
        debugPrint('⚠️ ContentAPI: Create tab failed: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Create tab error: $e');
      }
      return null;
    }
  }
  
  /// Update existing tab (admin only)
  Future<bool> updateTab({
    required String tabId,
    String? name,
    String? icon,
    String? description,
  }) async {
    try {
      final role = await _getCurrentRole();
      if (role != 'root_admin' && role != 'content_editor') {
        return false;
      }
      
      final username = await UserAuthService.getUsername(world: 'energie');
      final userId = await UserAuthService.getUserId();
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/content/tabs/$tabId'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-ID': userId ?? 'unknown',
          'X-Username': username ?? 'unknown',
          'X-Role': role ?? 'user',
        },
        body: json.encode({
          'name': name,
          'icon': icon,
          'description': description,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Update tab error: $e');
      }
      return false;
    }
  }
  
  /// Delete tab (admin only)
  Future<bool> deleteTab(String tabId) async {
    try {
      final role = await _getCurrentRole();
      if (role != 'root_admin' && role != 'content_editor') {
        return false;
      }
      
      final username = await UserAuthService.getUsername(world: 'energie');
      final userId = await UserAuthService.getUserId();
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/content/tabs/$tabId'),
        headers: {
          'X-User-ID': userId ?? 'unknown',
          'X-Username': username ?? 'unknown',
          'X-Role': role ?? 'user',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Delete tab error: $e');
      }
      return false;
    }
  }
  
  /// Get tools for a specific room
  Future<List<Map<String, dynamic>>> getTools(String world, String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/tools?world=$world&room=$roomId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['tools'] ?? []);
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Get tools error: $e');
      }
      return [];
    }
  }
  
  /// Get markers by category
  Future<List<Map<String, dynamic>>> getMarkers(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/markers?category=$category'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['markers'] ?? []);
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Get markers error: $e');
      }
      return [];
    }
  }
  
  /// Get change logs (admin only)
  Future<List<Map<String, dynamic>>> getChangeLogs({
    String? entityType,
    String? entityId,
    int limit = 50,
  }) async {
    try {
      final role = await _getCurrentRole();
      if (role != 'root_admin' && role != 'content_editor') {
        return [];
      }
      
      var url = '$_baseUrl/api/content/change-logs?limit=$limit';
      if (entityType != null) url += '&entity_type=$entityType';
      if (entityId != null) url += '&entity_id=$entityId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Role': role ?? 'user',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? []);
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ContentAPI: Get change logs error: $e');
      }
      return [];
    }
  }
  
  /// Check if current user can edit content
  Future<bool> canEditContent() async {
    final role = await _getCurrentRole();
    return role == 'root_admin' || role == 'content_editor';
  }
}
