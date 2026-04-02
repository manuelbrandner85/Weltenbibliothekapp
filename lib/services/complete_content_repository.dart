import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_auth_service.dart';

/// 🏗️ COMPLETE CONTENT REPOSITORY - 100% Content-Driven Architecture
/// 
/// Lädt KOMPLETTE App-Definition vom Backend
/// KEINE hardcoded UI-Elemente mehr
/// ALLE Inhalte aus JSON-Struktur
/// 
/// Features:
/// - Lädt komplette Content-Definition beim App-Start
/// - Cached lokal für Offline-Support
/// - Synchronisiert Änderungen zum Backend
/// - Benachrichtigt UI bei Updates
/// - Version Control & Rollback
/// - Global persistent für alle Nutzer
class CompleteContentRepository {
  static final CompleteContentRepository _instance = CompleteContentRepository._internal();
  factory CompleteContentRepository() => _instance;
  CompleteContentRepository._internal();

  static CompleteContentRepository get instance => _instance;

  // Backend URL
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // Cache
  Map<String, dynamic>? _completeContent;
  bool _isInitialized = false;
  bool _isLoading = false;
  
  // Listeners für Content-Updates
  final List<VoidCallback> _listeners = [];
  
  // Hive Box für lokalen Cache
  Box? _cacheBox;

  /// Initialize Repository - MUST be called at app start
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        debugPrint('🏗️ [ContentRepository] Initializing...');
      }
      
      // Open Hive cache box
      _cacheBox = await Hive.openBox('complete_content_cache');
      
      // Load from cache first (for offline support)
      final cachedContent = _cacheBox?.get('complete_content');
      if (cachedContent != null) {
        _completeContent = json.decode(cachedContent);
        if (kDebugMode) {
          debugPrint('✅ [ContentRepository] Loaded from cache: v${_completeContent?['version']}');
        }
      }
      
      // Load from backend (overwrites cache if newer)
      await _loadFromBackend();
      
      _isInitialized = true;
      
      // Notify listeners
      _notifyListeners();
      
      if (kDebugMode) {
        debugPrint('✅ [ContentRepository] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Init error: $e');
      }
      // Continue with cached content if available
      _isInitialized = true;
    }
  }

  /// Load complete content from backend
  Future<void> _loadFromBackend() async {
    if (_isLoading) return;
    
    _isLoading = true;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/complete'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'];
        final isDefault = data['is_default'] ?? false;
        
        // Update content
        _completeContent = content;
        
        // Cache locally
        await _cacheBox?.put('complete_content', json.encode(content));
        
        if (kDebugMode) {
          debugPrint('✅ [ContentRepository] Loaded from backend: v${content['version']} (default: $isDefault)');
        }
        
        // Notify listeners
        _notifyListeners();
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [ContentRepository] Backend returned ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Load from backend failed: $e');
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Save complete content to backend (for Content Editor)
  Future<bool> saveCompleteContent(Map<String, dynamic> content, {String? changeDescription}) async {
    try {
      // Get user credentials
      final username = await UserAuthService.getUsername();
      final userId = await UserAuthService.getUserId();
      
      // Only Weltenbibliothekedit can save
      if (username != 'Weltenbibliothekedit') {
        if (kDebugMode) {
          debugPrint('❌ [ContentRepository] User $username cannot save content');
        }
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/content/complete'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-ID': userId ?? 'unknown',
          'X-Username': username ?? 'unknown',
          'X-Role': 'content_editor',
        },
        body: json.encode({
          'content': content,
          'change_description': changeDescription ?? 'Updated complete content',
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          // Update local content
          _completeContent = data['content'];
          
          // Update cache
          await _cacheBox?.put('complete_content', json.encode(data['content']));
          
          if (kDebugMode) {
            debugPrint('✅ [ContentRepository] Saved to backend: v${data['content']['version']}');
          }
          
          // Notify listeners
          _notifyListeners();
          
          return true;
        }
      }
      
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Save failed: ${response.statusCode}');
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Save error: $e');
      }
      return false;
    }
  }

  /// Get complete content
  Map<String, dynamic>? get completeContent => _completeContent;
  
  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get app config
  Map<String, dynamic>? get appConfig => _completeContent?['app_config'];
  
  /// Get theme
  Map<String, dynamic>? get theme => appConfig?['theme'];
  
  /// Get typography
  Map<String, dynamic>? get typography => appConfig?['typography'];
  
  /// Get feature flags
  Map<String, dynamic>? get featureFlags => appConfig?['feature_flags'];
  
  /// Get worlds
  Map<String, dynamic>? get worlds => _completeContent?['worlds'];
  
  /// Get specific world
  Map<String, dynamic>? getWorld(String worldId) {
    return worlds?[worldId];
  }
  
  /// Get world metadata
  Map<String, dynamic>? getWorldMetadata(String worldId) {
    return getWorld(worldId)?['metadata'];
  }
  
  /// Get world screens
  Map<String, dynamic>? getWorldScreens(String worldId) {
    return getWorld(worldId)?['screens'];
  }
  
  /// Get specific screen
  Map<String, dynamic>? getScreen(String worldId, String screenId) {
    return getWorldScreens(worldId)?[screenId];
  }
  
  /// Get screen appbar config
  Map<String, dynamic>? getScreenAppBar(String worldId, String screenId) {
    return getScreen(worldId, screenId)?['appbar'];
  }
  
  /// Get screen tabs
  List<dynamic>? getScreenTabs(String worldId, String screenId) {
    return getScreen(worldId, screenId)?['tabs'];
  }
  
  /// Get screen input area config
  Map<String, dynamic>? getScreenInputArea(String worldId, String screenId) {
    return getScreen(worldId, screenId)?['input_area'];
  }
  
  /// Get screen empty state
  Map<String, dynamic>? getScreenEmptyState(String worldId, String screenId) {
    return getScreen(worldId, screenId)?['empty_state'];
  }
  
  /// Get screen tools
  List<dynamic>? getScreenTools(String worldId, String screenId) {
    return getScreen(worldId, screenId)?['tools'];
  }
  
  /// Get global components
  Map<String, dynamic>? get globalComponents => _completeContent?['global_components'];
  
  /// Get dialogs
  Map<String, dynamic>? get dialogs => globalComponents?['dialogs'];
  
  /// Get error messages
  Map<String, dynamic>? get errorMessages => globalComponents?['error_messages'];

  /// Update specific content value (for inline editing)
  Future<bool> updateContentValue(String path, dynamic value, {String? changeDescription}) async {
    try {
      if (_completeContent == null) return false;
      
      // Parse path (e.g., "worlds.energie.screens.live_chat.appbar.title")
      final parts = path.split('.');
      
      // Navigate to parent
      dynamic current = _completeContent;
      for (int i = 0; i < parts.length - 1; i++) {
        if (current is Map && current.containsKey(parts[i])) {
          current = current[parts[i]];
        } else {
          if (kDebugMode) {
            debugPrint('❌ [ContentRepository] Path not found: ${parts.sublist(0, i + 1).join('.')}');
          }
          return false;
        }
      }
      
      // Set value
      if (current is Map) {
        current[parts.last] = value;
        
        // Save to backend
        return await saveCompleteContent(
          _completeContent!,
          changeDescription: changeDescription ?? 'Updated $path',
        );
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Update value error: $e');
      }
      return false;
    }
  }

  /// Refresh content from backend
  Future<void> refresh() async {
    await _loadFromBackend();
  }

  /// Add listener for content updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Get version history
  Future<List<Map<String, dynamic>>> getVersionHistory() async {
    try {
      final username = await UserAuthService.getUsername();
      final userId = await UserAuthService.getUserId();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/complete/versions'),
        headers: {
          'X-User-ID': userId ?? 'unknown',
          'X-Username': username ?? 'unknown',
          'X-Role': 'content_editor',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['versions'] ?? []);
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Load versions error: $e');
      }
      return [];
    }
  }

  /// Rollback to specific version
  Future<bool> rollbackToVersion(String versionId) async {
    try {
      final username = await UserAuthService.getUsername();
      final userId = await UserAuthService.getUserId();
      
      if (username != 'Weltenbibliothekedit') {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/content/complete/rollback/$versionId'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-ID': userId ?? 'unknown',
          'X-Username': username ?? 'unknown',
          'X-Role': 'content_editor',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          _completeContent = data['content'];
          await _cacheBox?.put('complete_content', json.encode(data['content']));
          
          _notifyListeners();
          
          if (kDebugMode) {
            debugPrint('✅ [ContentRepository] Rolled back to version $versionId');
          }
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ContentRepository] Rollback error: $e');
      }
      return false;
    }
  }

  /// Dispose
  void dispose() {
    _listeners.clear();
  }
}
