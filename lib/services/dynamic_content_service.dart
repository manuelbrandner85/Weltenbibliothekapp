/// Dynamic Content Service - Vollständiges Live-Edit-System
/// 
/// Lädt und cached alle dynamischen Inhalte vom Backend
/// Unterstützt Offline-Modus, Versionierung, Live-Updates
library;

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/dynamic_ui_models.dart';
import 'user_auth_service.dart';
import 'storage_service.dart';

/// Dynamic Content Service - Singleton
class DynamicContentService {
  static final DynamicContentService _instance = DynamicContentService._internal();
  factory DynamicContentService() => _instance;
  DynamicContentService._internal();

  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  // Cache
  final Map<String, DynamicScreen> _screenCache = {};
  final Map<String, DynamicTab> _tabCache = {};
  final Map<String, DynamicTool> _toolCache = {};
  final Map<String, DynamicMarker> _markerCache = {};
  final Map<String, DynamicTextStyle> _styleCache = {};
  final Map<String, FeatureFlag> _featureFlagCache = {};
  
  // Version Control
  final List<ContentVersion> _versionHistory = [];
  final Map<String, List<ContentVersion>> _entityVersions = {}; // entityId -> versions
  
  // Sandbox Mode (für Content Editors)
  bool _sandboxMode = false;
  final Map<String, dynamic> _sandboxChanges = {}; // Temporäre Änderungen vor Publish
  
  /// =========================================================================
  /// INITIALIZATION
  /// =========================================================================
  
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('🔄 [DynamicContent] Initializing...');
    }
    
    // Load from cache first (offline support)
    await _loadFromCache();
    
    // Then fetch latest from backend
    await refreshAllContent();
    
    if (kDebugMode) {
      debugPrint('✅ [DynamicContent] Initialized');
      debugPrint('   Screens: ${_screenCache.length}');
      debugPrint('   Tabs: ${_tabCache.length}');
      debugPrint('   Tools: ${_toolCache.length}');
      debugPrint('   Markers: ${_markerCache.length}');
      debugPrint('   Styles: ${_styleCache.length}');
    }
  }
  
  /// =========================================================================
  /// CACHE MANAGEMENT
  /// =========================================================================
  
  Future<void> _loadFromCache() async {
    try {
      final storage = StorageService();
      
      // Load screens
      final screensJson = await storage.getData('dynamic_screens');
      if (screensJson != null) {
        final screens = json.decode(screensJson) as List;
        for (var s in screens) {
          final screen = DynamicScreen.fromJson(s);
          _screenCache[screen.id] = screen;
        }
      }
      
      // Load tabs
      final tabsJson = await storage.getData('dynamic_tabs');
      if (tabsJson != null) {
        final tabs = json.decode(tabsJson) as List;
        for (var t in tabs) {
          final tab = DynamicTab.fromJson(t);
          _tabCache[tab.id] = tab;
        }
      }
      
      // Load tools
      final toolsJson = await storage.getData('dynamic_tools');
      if (toolsJson != null) {
        final tools = json.decode(toolsJson) as List;
        for (var t in tools) {
          final tool = DynamicTool.fromJson(t);
          _toolCache[tool.id] = tool;
        }
      }
      
      // Load markers
      final markersJson = await storage.getData('dynamic_markers');
      if (markersJson != null) {
        final markers = json.decode(markersJson) as List;
        for (var m in markers) {
          final marker = DynamicMarker.fromJson(m);
          _markerCache[marker.id] = marker;
        }
      }
      
      // Load styles
      final stylesJson = await storage.getData('dynamic_styles');
      if (stylesJson != null) {
        final styles = json.decode(stylesJson) as List;
        for (var s in styles) {
          final style = DynamicTextStyle.fromJson(s);
          _styleCache[style.id] = style;
        }
      }
      
      // Load feature flags
      final flagsJson = await storage.getData('feature_flags');
      if (flagsJson != null) {
        final flags = json.decode(flagsJson) as List;
        for (var f in flags) {
          final flag = FeatureFlag.fromJson(f);
          _featureFlagCache[flag.id] = flag;
        }
      }
      
      if (kDebugMode) {
        debugPrint('📦 [DynamicContent] Loaded from cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Cache load error: $e');
      }
    }
  }
  
  Future<void> _saveToCache() async {
    try {
      final storage = StorageService();
      
      // Save screens
      await storage.saveData(
        'dynamic_screens',
        json.encode(_screenCache.values.map((s) => s.toJson()).toList()),
      );
      
      // Save tabs
      await storage.saveData(
        'dynamic_tabs',
        json.encode(_tabCache.values.map((t) => t.toJson()).toList()),
      );
      
      // Save tools
      await storage.saveData(
        'dynamic_tools',
        json.encode(_toolCache.values.map((t) => t.toJson()).toList()),
      );
      
      // Save markers
      await storage.saveData(
        'dynamic_markers',
        json.encode(_markerCache.values.map((m) => m.toJson()).toList()),
      );
      
      // Save styles
      await storage.saveData(
        'dynamic_styles',
        json.encode(_styleCache.values.map((s) => s.toJson()).toList()),
      );
      
      // Save feature flags
      await storage.saveData(
        'feature_flags',
        json.encode(_featureFlagCache.values.map((f) => f.toJson()).toList()),
      );
      
      if (kDebugMode) {
        debugPrint('💾 [DynamicContent] Saved to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Cache save error: $e');
      }
    }
  }
  
  /// =========================================================================
  /// CONTENT FETCHING
  /// =========================================================================
  
  Future<void> refreshAllContent() async {
    try {
      await Future.wait([
        _fetchScreens(),
        _fetchTabs(),
        _fetchTools(),
        _fetchMarkers(),
        _fetchStyles(),
        _fetchFeatureFlags(),
      ]);
      
      await _saveToCache();
      
      if (kDebugMode) {
        debugPrint('🔄 [DynamicContent] Refreshed all content');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DynamicContent] Refresh error: $e');
      }
    }
  }
  
  Future<void> _fetchScreens() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/screens'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final screens = (data['screens'] as List)
            .map((s) => DynamicScreen.fromJson(s))
            .toList();
        
        _screenCache.clear();
        for (var screen in screens) {
          _screenCache[screen.id] = screen;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Fetch screens error: $e');
      }
    }
  }
  
  Future<void> _fetchTabs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/tabs'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tabs = (data['tabs'] as List)
            .map((t) => DynamicTab.fromJson(t))
            .toList();
        
        _tabCache.clear();
        for (var tab in tabs) {
          _tabCache[tab.id] = tab;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Fetch tabs error: $e');
      }
    }
  }
  
  Future<void> _fetchTools() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/tools'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tools = (data['tools'] as List)
            .map((t) => DynamicTool.fromJson(t))
            .toList();
        
        _toolCache.clear();
        for (var tool in tools) {
          _toolCache[tool.id] = tool;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Fetch tools error: $e');
      }
    }
  }
  
  Future<void> _fetchMarkers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/markers'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final markers = (data['markers'] as List)
            .map((m) => DynamicMarker.fromJson(m))
            .toList();
        
        _markerCache.clear();
        for (var marker in markers) {
          _markerCache[marker.id] = marker;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Fetch markers error: $e');
      }
    }
  }
  
  Future<void> _fetchStyles() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/styles'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final styles = (data['styles'] as List)
            .map((s) => DynamicTextStyle.fromJson(s))
            .toList();
        
        _styleCache.clear();
        for (var style in styles) {
          _styleCache[style.id] = style;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Fetch styles error: $e');
      }
    }
  }
  
  Future<void> _fetchFeatureFlags() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/feature-flags'),
        headers: await _getHeaders(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final flags = (data['flags'] as List)
            .map((f) => FeatureFlag.fromJson(f))
            .toList();
        
        _featureFlagCache.clear();
        for (var flag in flags) {
          _featureFlagCache[flag.id] = flag;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [DynamicContent] Fetch feature flags error: $e');
      }
    }
  }
  
  /// =========================================================================
  /// GETTERS
  /// =========================================================================
  
  DynamicScreen? getScreen(String id) {
    return _sandboxMode && _sandboxChanges.containsKey('screen_$id')
        ? DynamicScreen.fromJson(_sandboxChanges['screen_$id'])
        : _screenCache[id];
  }
  
  List<DynamicScreen> getScreensByWorld(String world) {
    return _screenCache.values
        .where((s) => s.world == world && s.enabled)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }
  
  DynamicTab? getTab(String id) {
    return _sandboxMode && _sandboxChanges.containsKey('tab_$id')
        ? DynamicTab.fromJson(_sandboxChanges['tab_$id'])
        : _tabCache[id];
  }
  
  List<DynamicTab> getTabsByWorld(String world) {
    return _tabCache.values
        .where((t) => t.enabled)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
  
  DynamicTool? getTool(String id) {
    return _sandboxMode && _sandboxChanges.containsKey('tool_$id')
        ? DynamicTool.fromJson(_sandboxChanges['tool_$id'])
        : _toolCache[id];
  }
  
  List<DynamicTool> getToolsByWorldAndRoom(String world, String room) {
    return _toolCache.values
        .where((t) => t.world == world && t.room == room && t.enabled)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
  
  DynamicMarker? getMarker(String id) {
    return _sandboxMode && _sandboxChanges.containsKey('marker_$id')
        ? DynamicMarker.fromJson(_sandboxChanges['marker_$id'])
        : _markerCache[id];
  }
  
  List<DynamicMarker> getMarkersByCategory(String category) {
    return _markerCache.values
        .where((m) => m.category == category)
        .toList();
  }
  
  DynamicTextStyle? getStyle(String id) {
    return _sandboxMode && _sandboxChanges.containsKey('style_$id')
        ? DynamicTextStyle.fromJson(_sandboxChanges['style_$id'])
        : _styleCache[id];
  }
  
  FeatureFlag? getFeatureFlag(String id) {
    return _featureFlagCache[id];
  }
  
  bool isFeatureEnabled(String flagId, {String? userRole}) {
    final flag = _featureFlagCache[flagId];
    return flag?.isActive(userRole: userRole) ?? false;
  }
  
  /// =========================================================================
  /// SANDBOX MODE (Content Editor Preview)
  /// =========================================================================
  
  void enableSandboxMode() {
    _sandboxMode = true;
    _sandboxChanges.clear();
    if (kDebugMode) {
      debugPrint('🏖️ [DynamicContent] Sandbox mode enabled');
    }
  }
  
  void disableSandboxMode() {
    _sandboxMode = false;
    _sandboxChanges.clear();
    if (kDebugMode) {
      debugPrint('🏖️ [DynamicContent] Sandbox mode disabled');
    }
  }
  
  void updateInSandbox(String entityType, String entityId, Map<String, dynamic> data) {
    _sandboxChanges['${entityType}_$entityId'] = data;
    if (kDebugMode) {
      debugPrint('🏖️ [DynamicContent] Sandbox update: $entityType/$entityId');
    }
  }
  
  Future<bool> publishSandboxChanges() async {
    if (!_sandboxMode || _sandboxChanges.isEmpty) return false;
    
    try {
      // Publish all sandbox changes to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/api/content/bulk-update'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'changes': _sandboxChanges,
          'publish_immediately': true,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        // Refresh content from backend
        await refreshAllContent();
        
        // Clear sandbox
        _sandboxChanges.clear();
        _sandboxMode = false;
        
        if (kDebugMode) {
          debugPrint('✅ [DynamicContent] Sandbox changes published');
        }
        
        return true;
      }
      
      return false;
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Publish error: $e $e');
      }
      return false;
    }
  }
  
  /// =========================================================================
  /// CONTENT UPDATES (Content Editor Only)
  /// =========================================================================
  
  Future<bool> updateScreen(DynamicScreen screen) async {
    try {
      final version = await _createVersion(
        entityType: 'screen',
        entityId: screen.id,
        changeType: 'update',
        oldValue: _screenCache[screen.id]?.toJson() ?? {},
        newValue: screen.toJson(),
        changeDescription: 'Screen updated: ${screen.title.content}',
      );
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/content/screens/${screen.id}'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'screen': screen.toJson(),
          'version': version.toJson(),
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        _screenCache[screen.id] = screen;
        await _saveToCache();
        return true;
      }
      
      return false;
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Update screen error: $e $e');
      }
      return false;
    }
  }
  
  Future<bool> updateTab(DynamicTab tab) async {
    try {
      final version = await _createVersion(
        entityType: 'tab',
        entityId: tab.id,
        changeType: 'update',
        oldValue: _tabCache[tab.id]?.toJson() ?? {},
        newValue: tab.toJson(),
        changeDescription: 'Tab updated: ${tab.label.content}',
      );
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/content/tabs/${tab.id}'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tab': tab.toJson(),
          'version': version.toJson(),
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        _tabCache[tab.id] = tab;
        await _saveToCache();
        return true;
      }
      
      return false;
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Update tab error: $e $e');
      }
      return false;
    }
  }
  
  Future<bool> updateTool(DynamicTool tool) async {
    try {
      final version = await _createVersion(
        entityType: 'tool',
        entityId: tool.id,
        changeType: 'update',
        oldValue: _toolCache[tool.id]?.toJson() ?? {},
        newValue: tool.toJson(),
        changeDescription: 'Tool updated: ${tool.title.content}',
      );
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/content/tools/${tool.id}'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tool': tool.toJson(),
          'version': version.toJson(),
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        _toolCache[tool.id] = tool;
        await _saveToCache();
        return true;
      }
      
      return false;
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Update tool error: $e $e');
      }
      return false;
    }
  }
  
  Future<bool> updateMarker(DynamicMarker marker) async {
    try {
      final version = await _createVersion(
        entityType: 'marker',
        entityId: marker.id,
        changeType: 'update',
        oldValue: _markerCache[marker.id]?.toJson() ?? {},
        newValue: marker.toJson(),
        changeDescription: 'Marker updated: ${marker.title.content}',
      );
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/content/markers/${marker.id}'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'marker': marker.toJson(),
          'version': version.toJson(),
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        _markerCache[marker.id] = marker;
        await _saveToCache();
        return true;
      }
      
      return false;
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Update marker error: $e $e');
      }
      return false;
    }
  }
  
  Future<bool> updateTextStyle(DynamicTextStyle style) async {
    try {
      final version = await _createVersion(
        entityType: 'style',
        entityId: style.id,
        changeType: 'update',
        oldValue: _styleCache[style.id]?.toJson() ?? {},
        newValue: style.toJson(),
        changeDescription: 'Style updated: ${style.name}',
      );
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/content/styles/${style.id}'),
        headers: {
          ...await _getHeaders(),
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'style': style.toJson(),
          'version': version.toJson(),
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request Timeout (15s)');
        },
      );
      
      if (response.statusCode == 200) {
        _styleCache[style.id] = style;
        await _saveToCache();
        return true;
      }
      
      return false;
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Update style error: $e $e');
      }
      return false;
    }
  }
  
  /// =========================================================================
  /// VERSION CONTROL & HISTORY
  /// =========================================================================
  
  Future<ContentVersion> _createVersion({
    required String entityType,
    required String entityId,
    required String changeType,
    required Map<String, dynamic> oldValue,
    required Map<String, dynamic> newValue,
    required String changeDescription,
  }) async {
    final username = await UserAuthService.getUsername() ?? 'unknown';
    final userId = await UserAuthService.getUserId() ?? 'unknown';
    
    final version = ContentVersion(
      versionId: '${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      editorId: userId,
      editorName: username,
      changeDescription: changeDescription,
      oldValue: oldValue,
      newValue: newValue,
      changeType: changeType,
      entityType: entityType,
      entityId: entityId,
    );
    
    _versionHistory.add(version);
    _entityVersions.putIfAbsent(entityId, () => []).add(version);
    
    return version;
  }
  
  List<ContentVersion> getVersionHistory({String? entityId}) {
    if (entityId != null) {
      return _entityVersions[entityId] ?? [];
    }
    return List.from(_versionHistory)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  Future<bool> revertToVersion(ContentVersion version) async {
    try {
      // Restore old value
      final oldData = version.oldValue;
      
      switch (version.entityType) {
        case 'screen':
          final screen = DynamicScreen.fromJson(oldData);
          return await updateScreen(screen);
        case 'tab':
          final tab = DynamicTab.fromJson(oldData);
          return await updateTab(tab);
        case 'tool':
          final tool = DynamicTool.fromJson(oldData);
          return await updateTool(tool);
        case 'marker':
          final marker = DynamicMarker.fromJson(oldData);
          return await updateMarker(marker);
        case 'style':
          final style = DynamicTextStyle.fromJson(oldData);
          return await updateTextStyle(style);
        default:
          return false;
      }
    } on SocketException {
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
        debugPrint('❌ [DynamicContent] Revert error: $e $e');
      }
      return false;
    }
  }
  
  /// =========================================================================
  /// HELPERS
  /// =========================================================================
  
  Future<Map<String, String>> _getHeaders() async {
    final username = await UserAuthService.getUsername() ?? 'unknown';
    final userId = await UserAuthService.getUserId() ?? 'unknown';
    final role = await _getUserRole();
    
    return {
      'X-User-ID': userId,
      'X-Username': username,
      'X-Role': role,
    };
  }
  
  Future<String> _getUserRole() async {
    final username = await UserAuthService.getUsername();
    if (username == 'Weltenbibliothek') return 'root_admin';
    if (username == 'Weltenbibliothekedit') return 'content_editor';
    return 'user';
  }
  
  /// =========================================================================
  /// EDIT MODE SUPPORT (for EditModeService)
  /// =========================================================================
  
  /// Check if current user can edit content
  Future<bool> canEditContent() async {
    final role = await _getUserRole();
    return role == 'root_admin' || role == 'content_editor';
  }
  
  /// Get current user role
  Future<String> getCurrentUserRole() async {
    return await _getUserRole();
  }
  
  /// Check if sandbox mode is enabled
  bool isSandboxMode() {
    return _sandboxMode;
  }
}
