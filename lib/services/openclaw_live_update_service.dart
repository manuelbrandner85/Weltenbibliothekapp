import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 🔄 OPENCLAW LIVE-UPDATE SERVICE
/// 
/// Ermöglicht Live-Updates der App OHNE Rebuild:
/// - Remote Config (Texte, Farben, Feature-Flags)
/// - Dynamic UI (Buttons, Screens, Layouts)
/// - Feature Toggles (Features an/aus schalten)
/// - Content Updates (Artikel, Bilder, Videos)
/// - A/B Testing
/// 
/// WORKFLOW:
/// 1. OpenClaw Agent pusht Änderungen zum Gateway
/// 2. App pollt alle 60s oder bei App-Start
/// 3. Änderungen werden sofort angewendet
/// 4. Kein App-Rebuild nötig!

class OpenClawLiveUpdateService {
  static final OpenClawLiveUpdateService _instance = OpenClawLiveUpdateService._internal();
  factory OpenClawLiveUpdateService() => _instance;
  OpenClawLiveUpdateService._internal();

  // Gateway URL
  static const String _gatewayUrl = 'http://72.62.154.95:50074';
  
  // Cache
  Map<String, dynamic> _remoteConfig = {};
  Map<String, dynamic> _dynamicFeatures = {};
  Map<String, bool> _featureFlags = {};
  
  // State
  bool _isInitialized = false;
  Timer? _pollTimer;
  
  // Stream für Live-Updates
  final _updateStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get updateStream => _updateStreamController.stream;

  /// 🚀 Initialisierung - Beim App-Start aufrufen
  Future<void> initialize({String? projectId = 'weltenbibliothek'}) async {
    if (_isInitialized) return;
    
    try {
      // 1. Cache laden
      await _loadFromCache();
      
      // 2. Erste Updates holen
      await fetchUpdates(projectId: projectId);
      
      // 3. Polling starten (alle 60 Sekunden)
      _startPolling(projectId: projectId);
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ OpenClaw Live-Update Service initialized');
        debugPrint('   Remote Config Keys: ${_remoteConfig.keys.length}');
        debugPrint('   Dynamic Features: ${_dynamicFeatures.keys.length}');
        debugPrint('   Feature Flags: ${_featureFlags.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Live-Update init error: $e');
      }
    }
  }

  /// 🔄 Updates vom Gateway holen
  Future<void> fetchUpdates({String? projectId = 'weltenbibliothek'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_gatewayUrl/api/live-updates/$projectId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Updates anwenden
        if (data['remoteConfig'] != null) {
          _remoteConfig = data['remoteConfig'] as Map<String, dynamic>;
        }
        
        if (data['dynamicFeatures'] != null) {
          _dynamicFeatures = data['dynamicFeatures'] as Map<String, dynamic>;
        }
        
        if (data['featureFlags'] != null) {
          final flags = data['featureFlags'] as Map<String, dynamic>;
          _featureFlags = flags.map((key, value) => MapEntry(key, value as bool));
        }
        
        // Cache speichern
        await _saveToCache();
        
        // Event auslösen
        _updateStreamController.add({
          'type': 'update',
          'timestamp': DateTime.now().toIso8601String(),
          'config': _remoteConfig,
          'features': _dynamicFeatures,
          'flags': _featureFlags,
        });
        
        if (kDebugMode) {
          debugPrint('✅ Live-Updates fetched: ${data.keys.length} categories');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Fetch updates error: $e');
      }
    }
  }

  /// 🏁 Polling starten
  void _startPolling({String? projectId = 'weltenbibliothek'}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchUpdates(projectId: projectId);
    });
  }

  /// 💾 Cache laden
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final configJson = prefs.getString('openclaw_remote_config');
      if (configJson != null) {
        _remoteConfig = json.decode(configJson) as Map<String, dynamic>;
      }
      
      final featuresJson = prefs.getString('openclaw_dynamic_features');
      if (featuresJson != null) {
        _dynamicFeatures = json.decode(featuresJson) as Map<String, dynamic>;
      }
      
      final flagsJson = prefs.getString('openclaw_feature_flags');
      if (flagsJson != null) {
        final flags = json.decode(flagsJson) as Map<String, dynamic>;
        _featureFlags = flags.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Load cache error: $e');
      }
    }
  }

  /// 💾 Cache speichern
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('openclaw_remote_config', json.encode(_remoteConfig));
      await prefs.setString('openclaw_dynamic_features', json.encode(_dynamicFeatures));
      await prefs.setString('openclaw_feature_flags', json.encode(_featureFlags));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Save cache error: $e');
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Remote Config
  // ═══════════════════════════════════════════════════════════════════════════

  /// 📝 String-Wert aus Remote Config
  String getString(String key, {String defaultValue = ''}) {
    return _remoteConfig[key]?.toString() ?? defaultValue;
  }

  /// 🔢 Int-Wert aus Remote Config
  int getInt(String key, {int defaultValue = 0}) {
    final value = _remoteConfig[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 🔢 Double-Wert aus Remote Config
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _remoteConfig[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// ✅ Bool-Wert aus Remote Config
  bool getBool(String key, {bool defaultValue = false}) {
    final value = _remoteConfig[key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// 🎨 JSON-Objekt aus Remote Config
  Map<String, dynamic>? getJson(String key) {
    final value = _remoteConfig[key];
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        return json.decode(value) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Feature Flags
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🚩 Feature-Flag prüfen
  bool isFeatureEnabled(String featureName) {
    return _featureFlags[featureName] ?? false;
  }

  /// 🚩 Alle Feature-Flags
  Map<String, bool> getAllFeatureFlags() {
    return Map.from(_featureFlags);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Dynamic Features
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🎨 Dynamic Feature holen
  Map<String, dynamic>? getDynamicFeature(String featureName) {
    final feature = _dynamicFeatures[featureName];
    if (feature is Map<String, dynamic>) return feature;
    return null;
  }

  /// 🎨 Alle Dynamic Features
  Map<String, dynamic> getAllDynamicFeatures() {
    return Map.from(_dynamicFeatures);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🧹 Cleanup
  void dispose() {
    _pollTimer?.cancel();
    _updateStreamController.close();
  }
}
