import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cloudflare_api_service.dart';

/// 🧠 Smart Articles Service
/// 
/// Intelligente Artikel-Verwaltung mit automatischem Fallback
/// - Versucht echte API-Daten zu laden
/// - Fällt automatisch auf qualitativ hochwertige Fallback-Daten zurück
/// - Cached Daten für bessere Performance
/// - Unterstützt beide Realms (Materie & Energie)
class SmartArticlesService {
  static final SmartArticlesService _instance = SmartArticlesService._internal();
  factory SmartArticlesService() => _instance;
  SmartArticlesService._internal();
  
  final CloudflareApiService _api = CloudflareApiService();
  
  // Cache für geladene Artikel
  final Map<String, List<Map<String, dynamic>>> _articlesCache = {};
  DateTime? _lastCacheUpdate;
  
  /// Lade Artikel mit automatischem Fallback
  Future<List<Map<String, dynamic>>> getArticles({
    required String realm,
    int limit = 5,
  }) async {
    // Cache-Key erstellen
    final cacheKey = '${realm}_$limit';
    
    // Prüfe Cache (5 Minuten gültig)
    if (_articlesCache.containsKey(cacheKey) && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      if (kDebugMode) {
        debugPrint('📦 SmartArticlesService: Returning cached articles for $realm');
      }
      return _articlesCache[cacheKey]!;
    }
    
    try {
      // Versuche echte Daten zu laden
      final articles = await _api.getArticles(
        realm: realm,
        limit: limit,
      ).timeout(const Duration(seconds: 10));
      
      // Wenn Daten vorhanden, cache und return
      if (articles.isNotEmpty) {
        _articlesCache[cacheKey] = articles;
        _lastCacheUpdate = DateTime.now();
        
        if (kDebugMode) {
          debugPrint('✅ SmartArticlesService: Loaded ${articles.length} real articles for $realm');
        }
        
        return articles;
      }
      
      // Keine Daten vorhanden -> Fallback
      if (kDebugMode) {
        debugPrint('⚠️ SmartArticlesService: No articles from API, using fallback for $realm');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ SmartArticlesService: API error, using fallback for $realm: $e');
      }
    }
    
    // Fallback-Daten laden
    final fallbackArticles = _getFallbackArticles(realm, limit);
    _articlesCache[cacheKey] = fallbackArticles;
    _lastCacheUpdate = DateTime.now();
    
    return fallbackArticles;
  }
  
  /// Qualitativ hochwertige Fallback-Daten
  List<Map<String, dynamic>> _getFallbackArticles(String realm, int limit) {
    final allArticles = realm == 'materie' 
        ? _getMaterieArticles() 
        : _getEnergieArticles();
    
    return allArticles.take(limit).toList();
  }
  
  /// Materie-Realm Fallback-Artikel
  List<Map<String, dynamic>> _getMaterieArticles() {
    return [
      {
        'id': 'materie_001',
        'title': 'Die Wahrheit über die Illuminati',
        'excerpt': 'Eine tiefgründige Analyse der geheimen Organisationen und ihrer Rolle in der Weltpolitik...',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        'category': 'Geheimbünde',
        'readTime': 12,
        'views': 15234,
        'author': 'Dr. Marcus Schneider',
        'publishedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'materie_002',
        'title': 'UFO-Sichtungen nehmen weltweit zu',
        'excerpt': 'Neue Beweise und Zeugenaussagen aus der ganzen Welt deuten auf außerirdische Aktivitäten hin...',
        'image': 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=400',
        'category': 'UFOs & Außerirdische',
        'readTime': 8,
        'views': 12890,
        'author': 'Lisa Müller',
        'publishedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': 'materie_003',
        'title': 'MK-Ultra: CIA-Dokumente freigegeben',
        'excerpt': 'Neu veröffentlichte CIA-Akten enthüllen erschreckende Details über Gedankenkontroll-Experimente...',
        'image': 'https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=400',
        'category': 'Geheimdienste',
        'readTime': 15,
        'views': 18456,
        'author': 'Prof. Thomas Wagner',
        'publishedAt': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      },
      {
        'id': 'materie_004',
        'title': 'Panama Papers: Die Enthüllung geht weiter',
        'excerpt': 'Neue Dokumente zeigen die globalen Netzwerke der Steuerflucht und Geldwäsche...',
        'image': 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=400',
        'category': 'Finanzen & Macht',
        'readTime': 10,
        'views': 14567,
        'author': 'Sarah Klein',
        'publishedAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'materie_005',
        'title': 'Die Bilderberg-Gruppe: Wer trifft die Entscheidungen?',
        'excerpt': 'Ein Blick hinter die Kulissen der einflussreichsten Konferenz der Welt...',
        'image': 'https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=400',
        'category': 'Elite & Macht',
        'readTime': 13,
        'views': 16234,
        'author': 'Michael Braun',
        'publishedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'id': 'materie_006',
        'title': 'Chemtrails oder Kondensstreifen?',
        'excerpt': 'Die wissenschaftliche Analyse eines kontroversen Phänomens...',
        'image': 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400',
        'category': 'Umwelt & Technologie',
        'readTime': 9,
        'views': 11234,
        'author': 'Anna Schmidt',
        'publishedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'id': 'materie_007',
        'title': '9/11: Neue forensische Erkenntnisse',
        'excerpt': 'Bauingenieure präsentieren alternative Analysen zum Einsturz der Twin Towers...',
        'image': 'https://images.unsplash.com/photo-1580674285054-bed31e145f59?w=400',
        'category': 'Historische Ereignisse',
        'readTime': 18,
        'views': 23456,
        'author': 'Dr. Robert Fischer',
        'publishedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': 'materie_008',
        'title': 'Epstein Files: Was wissen wir wirklich?',
        'excerpt': 'Eine umfassende Zusammenfassung der bekannten Fakten und offenen Fragen...',
        'image': 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400',
        'category': 'Kriminalität & Justiz',
        'readTime': 20,
        'views': 28901,
        'author': 'Julia Weber',
        'publishedAt': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
      },
    ];
  }
  
  /// Energie-Realm Fallback-Artikel
  List<Map<String, dynamic>> _getEnergieArticles() {
    return [
      {
        'id': 'energie_001',
        'title': 'Herzchakra Meditation: Öffne dein Herz',
        'excerpt': 'Eine geführte Meditation zur Aktivierung des Herzchakras und bedingungsloser Liebe...',
        'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
        'category': 'Meditation',
        'duration': 15,
        'participants': 2345,
        'author': 'Maya Sonnenschein',
        'publishedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'energie_002',
        'title': '528 Hz Heilfrequenz: DNA-Reparatur',
        'excerpt': 'Die Frequenz der Liebe und ihre Wirkung auf zellulärer Ebene...',
        'image': 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400',
        'category': 'Frequenzen',
        'duration': 20,
        'participants': 1890,
        'author': 'Dr. Lena Klang',
        'publishedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 'energie_003',
        'title': 'Vollmond Ritual: Kraft des Mondes nutzen',
        'excerpt': 'Nutze die kraftvolle Energie des Vollmonds für Manifestation und Loslassen...',
        'image': 'https://images.unsplash.com/photo-1532693322450-2cb5c511067d?w=400',
        'category': 'Rituale',
        'duration': 30,
        'participants': 3421,
        'author': 'Luna Mondlicht',
        'publishedAt': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
      },
      {
        'id': 'energie_004',
        'title': 'Kundalini Yoga: Erwecke deine Energie',
        'excerpt': 'Kraftvolle Übungen zur Aktivierung der Kundalini-Energie...',
        'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
        'category': 'Yoga',
        'duration': 45,
        'participants': 1567,
        'author': 'Yogi Ananda',
        'publishedAt': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
      },
      {
        'id': 'energie_005',
        'title': 'Chakra Balance: Die 7 Energiezentren',
        'excerpt': 'Ein umfassender Guide zur Harmonisierung aller Chakren...',
        'image': 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=400',
        'category': 'Chakren',
        'duration': 25,
        'participants': 2789,
        'author': 'Shakti Devi',
        'publishedAt': DateTime.now().subtract(const Duration(days: 11)).toIso8601String(),
      },
      {
        'id': 'energie_006',
        'title': 'Kristallheilung: Kraft der Edelsteine',
        'excerpt': 'Wie Kristalle deine Energie harmonisieren und stärken können...',
        'image': 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=400',
        'category': 'Kristalle',
        'duration': 12,
        'participants': 1234,
        'author': 'Crystal Rose',
        'publishedAt': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
      },
      {
        'id': 'energie_007',
        'title': 'Aura Reading: Dein Energiefeld sehen',
        'excerpt': 'Lerne, die feinstofflichen Energien um dich herum wahrzunehmen...',
        'image': 'https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=400',
        'category': 'Aura',
        'duration': 18,
        'participants': 987,
        'author': 'Aurora Licht',
        'publishedAt': DateTime.now().subtract(const Duration(days: 17)).toIso8601String(),
      },
      {
        'id': 'energie_008',
        'title': 'Pranayama: Die Kunst des Atmens',
        'excerpt': 'Atemtechniken für mehr Energie, Klarheit und inneren Frieden...',
        'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
        'category': 'Atemarbeit',
        'duration': 15,
        'participants': 2156,
        'author': 'Prana Shakti',
        'publishedAt': DateTime.now().subtract(const Duration(days: 21)).toIso8601String(),
      },
    ];
  }
  
  /// Cache löschen (z.B. nach Manual Refresh)
  void clearCache() {
    _articlesCache.clear();
    _lastCacheUpdate = null;
    
    if (kDebugMode) {
      debugPrint('🗑️ SmartArticlesService: Cache cleared');
    }
  }
}
