import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'storage_service.dart';
import 'user_auth_service.dart';

/// 🌍 PHASE 4: Universal Content Management Service
/// 
/// Verwaltet ALLE editierbaren Inhalte für ALLE Welten und Screens
/// - 85 Screens über 3 Welten
/// - Alle Buttons, Texte, Icons, Farben
/// - Zentrale JSON-basierte Konfiguration
/// - Hot-Reload ohne App-Neustart
class UniversalContentService {
  static final UniversalContentService _instance = UniversalContentService._internal();
  factory UniversalContentService() => _instance;
  UniversalContentService._internal();

  // Storage
  final StorageService _storage = StorageService();
  
  // Content Cache
  Map<String, dynamic> _contentCache = {};
  bool _isInitialized = false;

  /// Initialize the service (load all content)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        debugPrint('🌍 [UniversalContent] Initializing...');
      }
      
      // Load from storage
      final data = await _storage.getData('universal_content');
      if (data != null) {
        _contentCache = json.decode(data);
        if (kDebugMode) {
          debugPrint('✅ [UniversalContent] Loaded ${_contentCache.length} screens');
        }
      } else {
        // Initialize with default content
        _contentCache = _getDefaultContent();
        await _saveContent();
        if (kDebugMode) {
          debugPrint('🆕 [UniversalContent] Created default content');
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] Init error: $e');
      }
    }
  }

  /// Get content for a specific screen
  Map<String, dynamic> getScreenContent(String screenId) {
    return _contentCache[screenId] ?? {};
  }

  /// Get button label
  String getButtonLabel(String screenId, String buttonId, {String? fallback}) {
    final screenContent = getScreenContent(screenId);
    final buttons = screenContent['buttons'] as Map<String, dynamic>?;
    return buttons?[buttonId]?['label'] ?? fallback ?? buttonId;
  }

  /// Get button tooltip
  String getButtonTooltip(String screenId, String buttonId, {String? fallback}) {
    final screenContent = getScreenContent(screenId);
    final buttons = screenContent['buttons'] as Map<String, dynamic>?;
    return buttons?[buttonId]?['tooltip'] ?? fallback ?? '';
  }

  /// Get text content
  String getText(String screenId, String textId, {String? fallback}) {
    final screenContent = getScreenContent(screenId);
    final texts = screenContent['texts'] as Map<String, dynamic>?;
    return texts?[textId] ?? fallback ?? textId;
  }

  /// Get screen title
  String getScreenTitle(String screenId, {String? fallback}) {
    final screenContent = getScreenContent(screenId);
    return screenContent['title'] ?? fallback ?? screenId;
  }

  /// Update button
  Future<void> updateButton(
    String screenId,
    String buttonId,
    Map<String, dynamic> data,
  ) async {
    final screenContent = getScreenContent(screenId);
    if (!screenContent.containsKey('buttons')) {
      screenContent['buttons'] = {};
    }
    
    screenContent['buttons'][buttonId] = data;
    _contentCache[screenId] = screenContent;
    
    await _saveContent();
    
    if (kDebugMode) {
      debugPrint('🔲 [UniversalContent] Updated button: $screenId/$buttonId');
    }
  }

  /// Update text
  Future<void> updateText(
    String screenId,
    String textId,
    String content,
  ) async {
    final screenContent = getScreenContent(screenId);
    if (!screenContent.containsKey('texts')) {
      screenContent['texts'] = {};
    }
    
    screenContent['texts'][textId] = content;
    _contentCache[screenId] = screenContent;
    
    await _saveContent();
    
    if (kDebugMode) {
      debugPrint('📝 [UniversalContent] Updated text: $screenId/$textId');
    }
  }

  /// Update screen title
  Future<void> updateScreenTitle(
    String screenId,
    String title,
  ) async {
    final screenContent = getScreenContent(screenId);
    screenContent['title'] = title;
    _contentCache[screenId] = screenContent;
    
    await _saveContent();
    
    if (kDebugMode) {
      debugPrint('📱 [UniversalContent] Updated screen title: $screenId');
    }
  }

  /// Save all content to storage
  Future<void> _saveContent() async {
    try {
      await _storage.saveData(
        'universal_content',
        json.encode(_contentCache),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] Save error: $e');
      }
    }
  }

  /// Get default content for all screens
  Map<String, dynamic> _getDefaultContent() {
    return {
      // ENERGIE-WELT
      'energie_chat': {
        'title': '💬 ENERGIE LIVE-CHAT',
        'world': 'energie',
        'buttons': {
          'send': {'label': 'Senden', 'tooltip': 'Nachricht senden'},
          'voice': {'label': 'Voice', 'tooltip': 'Sprachnachricht aufnehmen'},
          'attach': {'label': 'Anhängen', 'tooltip': 'Datei anhängen'},
          'search': {'label': 'Suchen', 'tooltip': 'Nachrichten durchsuchen'},
          'edit_mode': {'label': 'Edit', 'tooltip': 'Edit-Modus aktivieren'},
          'sandbox': {'label': 'Sandbox', 'tooltip': 'Sandbox-Modus aktivieren'},
          'publish': {'label': 'Publish', 'tooltip': 'Änderungen veröffentlichen'},
        },
        'texts': {
          'input_hint': 'Schreibe eine Nachricht...',
          'empty_title': 'Noch keine Nachrichten',
          'empty_subtitle': 'Starte die Konversation',
        },
      },
      'meditation_timer': {
        'title': '🧘 Meditation Timer',
        'world': 'energie',
        'buttons': {
          'start': {'label': 'Starten', 'tooltip': 'Meditation beginnen'},
          'pause': {'label': 'Pause', 'tooltip': 'Pausieren'},
          'stop': {'label': 'Stoppen', 'tooltip': 'Beenden'},
          'reset': {'label': 'Reset', 'tooltip': 'Timer zurücksetzen'},
        },
        'texts': {
          'duration_label': 'Dauer',
          'sound_label': 'Ambient Sound',
        },
      },
      'astral_journal': {
        'title': '🌙 Astralreise Tagebuch',
        'world': 'energie',
        'buttons': {
          'save': {'label': 'Speichern', 'tooltip': 'Eintrag speichern'},
          'delete': {'label': 'Löschen', 'tooltip': 'Eintrag löschen'},
          'share': {'label': 'Teilen', 'tooltip': 'Mit Community teilen'},
        },
        'texts': {
          'title_hint': 'Titel der Erfahrung...',
          'description_hint': 'Beschreibe deine Erfahrung...',
        },
      },
      
      // MATERIE-WELT
      'materie_home': {
        'title': '🌍 MATERIE-WELT',
        'world': 'materie',
        'buttons': {
          'research': {'label': 'Forschung', 'tooltip': 'Forschungsthemen'},
          'community': {'label': 'Community', 'tooltip': 'Community Feed'},
          'library': {'label': 'Bibliothek', 'tooltip': 'Wissensbibliothek'},
        },
        'texts': {
          'welcome': 'Willkommen in der Materie-Welt',
          'subtitle': 'Entdecke verborgenes Wissen',
        },
      },
      
      // SPIRIT-WELT
      'spirit_home': {
        'title': '✨ SPIRIT-WELT',
        'world': 'spirit',
        'buttons': {
          'oracle': {'label': 'Orakel', 'tooltip': 'Tages-Orakel'},
          'tarot': {'label': 'Tarot', 'tooltip': 'Tarot-Lesung'},
          'astrology': {'label': 'Astrologie', 'tooltip': 'Horoskop'},
          'numerology': {'label': 'Numerologie', 'tooltip': 'Numerologie-Analyse'},
        },
        'texts': {
          'welcome': 'Willkommen in der Spirit-Welt',
          'moon_phase': 'Aktuelle Mondphase:',
        },
      },
    };
  }

  /// Get all screen IDs
  List<String> getAllScreenIds() {
    return _contentCache.keys.toList();
  }

  /// Get all screens for a specific world
  List<String> getScreensByWorld(String world) {
    return _contentCache.entries
        .where((entry) => entry.value['world'] == world)
        .map((entry) => entry.key)
        .toList();
  }

  /// Export all content as JSON
  String exportContent() {
    return json.encode(_contentCache);
  }

  /// Import content from JSON
  Future<void> importContent(String jsonContent) async {
    try {
      _contentCache = json.decode(jsonContent);
      await _saveContent();
      
      if (kDebugMode) {
        debugPrint('📥 [UniversalContent] Imported content');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] Import error: $e');
      }
    }
  }

  /// 🔒 CRITICAL: Prüft ob User Edit-Rechte hat
  /// NUR "Weltenbibliothekedit" darf Content editieren!
  Future<bool> canEditContent() async {
    try {
      final username = await UserAuthService.getUsername();
      
      // Nur "Weltenbibliothekedit" hat Edit-Rechte
      final hasEditRights = username == 'Weltenbibliothekedit';
      
      if (kDebugMode) {
        debugPrint('🔒 [UniversalContent] User "$username" has edit rights: $hasEditRights');
      }
      
      return hasEditRights;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] canEditContent error: $e');
      }
      return false;
    }
  }

  /// Get current user role (for UI display)
  Future<String> getCurrentUserRole() async {
    try {
      final username = await UserAuthService.getUsername();
      
      // Weltenbibliothekedit = content_editor
      if (username == 'Weltenbibliothekedit') {
        return 'content_editor';
      }
      
      // Weltenbibliothek = root_admin
      if (username == 'Weltenbibliothek') {
        return 'root_admin';
      }
      
      return 'user';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] getCurrentUserRole error: $e');
      }
      return 'user';
    }
  }

  /// Get current username (for UI display)
  Future<String> getCurrentUsername() async {
    try {
      final username = await UserAuthService.getUsername();
      return username ?? 'Gast';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] getCurrentUsername error: $e');
      }
      return 'Gast';
    }
  }

  /// 📥 GET CACHED GENERIC CONTENT (für EditWrapper)
  Map<String, dynamic>? getCachedGenericContent(String contentId) {
    try {
      // contentId format: 'world.screen.section.element'
      // z.B. 'energie.chat.appbar.title'
      final parts = contentId.split('.');
      
      if (parts.length < 2) return null;
      
      // First part is typically world, second is screen
      final screenKey = '${parts[0]}_${parts[1]}';
      final screenContent = _contentCache[screenKey];
      
      if (screenContent == null) return null;
      
      // Navigate through the hierarchy
      dynamic current = screenContent;
      for (int i = 2; i < parts.length; i++) {
        if (current is Map) {
          current = current[parts[i]];
        } else {
          return null;
        }
      }
      
      return {'value': current};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] getCachedGenericContent error: $e');
      }
      return null;
    }
  }

  /// 💾 SAVE GENERIC CONTENT (für EditWrapper)
  Future<void> saveGenericContent(
    String contentId,
    dynamic value, {
    String? contentType,
  }) async {
    try {
      // contentId format: 'world.screen.section.element'
      final parts = contentId.split('.');
      
      if (parts.length < 2) {
        throw Exception('Invalid contentId format: $contentId');
      }
      
      // Get screen key
      final screenKey = '${parts[0]}_${parts[1]}';
      
      // Ensure screen exists
      if (!_contentCache.containsKey(screenKey)) {
        _contentCache[screenKey] = {
          'title': parts[1],
          'world': parts[0],
        };
      }
      
      final screenContent = _contentCache[screenKey];
      
      // Navigate to parent and set value
      dynamic current = screenContent;
      for (int i = 2; i < parts.length - 1; i++) {
        if (!current.containsKey(parts[i])) {
          current[parts[i]] = {};
        }
        current = current[parts[i]];
      }
      
      // Set the final value
      if (parts.length > 2) {
        current[parts.last] = value;
      } else {
        screenContent[parts.last] = value;
      }
      
      // Save to storage
      await _saveContent();
      
      if (kDebugMode) {
        debugPrint('💾 [UniversalContent] Saved: $contentId = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [UniversalContent] saveGenericContent error: $e');
      }
      rethrow;
    }
  }

  /// Singleton instance getter
  static UniversalContentService get instance => _instance;
}
