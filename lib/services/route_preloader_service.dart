import 'package:flutter/material.dart';

/// 🚀 Route Preloader Service
///
/// Pre-lädt häufig besuchte Screens im Hintergrund für instant Navigation
/// 
/// Features:
/// - Background Screen Building
/// - Smart Caching (LRU-basiert)
/// - Memory Management (max 5 Screens)
/// - Automatic Cleanup
class RoutePreloaderService {
  static final RoutePreloaderService _instance = RoutePreloaderService._internal();
  factory RoutePreloaderService() => _instance;
  RoutePreloaderService._internal();

  // Cache für pre-geladene Screens
  final Map<String, _PreloadedRoute> _cache = {};
  final List<String> _accessOrder = []; // LRU tracking
  
  static const int _maxCacheSize = 5; // Max 5 Screens im Cache
  static const Duration _cacheExpiration = Duration(minutes: 10);

  /// Screen vorladen
  /// 
  /// Beispiel:
  /// ```dart
  /// RoutePreloaderService().preload(
  ///   'event_detail',
  ///   () => EventDetailScreen(eventId: '123'),
  /// );
  /// ```
  void preload(String routeKey, Widget Function() builder) {
    // Check cache size und cleanup wenn nötig
    if (_cache.length >= _maxCacheSize) {
      _evictLeastRecentlyUsed();
    }

    _cache[routeKey] = _PreloadedRoute(
      widget: builder(),
      timestamp: DateTime.now(),
    );
    
    _accessOrder.remove(routeKey);
    _accessOrder.add(routeKey);
  }

  /// Pre-geladenen Screen abrufen
  /// 
  /// Returns null wenn nicht gecacht oder expired
  Widget? get(String routeKey) {
    final cached = _cache[routeKey];
    
    if (cached == null) return null;

    // Check Expiration
    final age = DateTime.now().difference(cached.timestamp);
    if (age > _cacheExpiration) {
      _cache.remove(routeKey);
      _accessOrder.remove(routeKey);
      return null;
    }

    // Update access order (LRU)
    _accessOrder.remove(routeKey);
    _accessOrder.add(routeKey);

    return cached.widget;
  }

  /// Screen aus Cache entfernen
  void invalidate(String routeKey) {
    _cache.remove(routeKey);
    _accessOrder.remove(routeKey);
  }

  /// Gesamten Cache leeren
  void clearAll() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// LRU Eviction: Entferne am wenigsten genutzten Screen
  void _evictLeastRecentlyUsed() {
    if (_accessOrder.isEmpty) return;
    
    final oldestKey = _accessOrder.first;
    _cache.remove(oldestKey);
    _accessOrder.removeAt(0);
  }

  /// Batch Pre-Loading für mehrere Screens
  /// 
  /// Beispiel:
  /// ```dart
  /// RoutePreloaderService().preloadBatch({
  ///   'chat': () => ChatScreen(),
  ///   'profile': () => ProfileScreen(),
  ///   'settings': () => SettingsScreen(),
  /// });
  /// ```
  void preloadBatch(Map<String, Widget Function()> routes) {
    routes.forEach((key, builder) {
      preload(key, builder);
    });
  }

  /// Check ob Route im Cache ist
  bool isCached(String routeKey) {
    return _cache.containsKey(routeKey);
  }

  /// Cache-Statistiken für Debugging
  Map<String, dynamic> getStats() {
    return {
      'cached_routes': _cache.length,
      'max_cache_size': _maxCacheSize,
      'cache_keys': _cache.keys.toList(),
      'access_order': _accessOrder,
      'expiration_minutes': _cacheExpiration.inMinutes,
    };
  }
}

/// Private Klasse für gecachte Routes
class _PreloadedRoute {
  final Widget widget;
  final DateTime timestamp;

  _PreloadedRoute({
    required this.widget,
    required this.timestamp,
  });
}

/// 🎯 Smart Route Preloader
/// 
/// Automatisches Pre-Loading basierend auf User-Verhalten
class SmartRoutePreloader {
  static final SmartRoutePreloader _instance = SmartRoutePreloader._internal();
  factory SmartRoutePreloader() => _instance;
  SmartRoutePreloader._internal();

  final RoutePreloaderService _preloader = RoutePreloaderService();
  final Map<String, int> _routeFrequency = {}; // Wie oft wurde Route besucht
  final Map<String, String> _routeTransitions = {}; // Von wo zu wo navigiert User

  /// Route-Besuch tracken
  void trackVisit(String currentRoute, String? previousRoute) {
    // Frequenz erhöhen
    _routeFrequency[currentRoute] = (_routeFrequency[currentRoute] ?? 0) + 1;

    // Transition tracken
    if (previousRoute != null) {
      final transitionKey = '$previousRoute->$currentRoute';
      _routeTransitions[transitionKey] = currentRoute;
    }

    // Smart Pre-Loading: Lade wahrscheinliche nächste Route
    _preloadLikelyNextRoute(currentRoute);
  }

  /// Lade wahrscheinliche nächste Route basierend auf Historie
  void _preloadLikelyNextRoute(String currentRoute) {
    // Finde häufigste Transition von aktueller Route
    final likelyNext = _findMostLikelyNext(currentRoute);
    
    if (likelyNext != null) {
      // TODO: Pre-load Route (benötigt Route-Builder Registry)
      debugPrint('🎯 Smart Pre-Loading: $likelyNext');
    }
  }

  /// Finde wahrscheinlichste nächste Route
  String? _findMostLikelyNext(String currentRoute) {
    final transitions = _routeTransitions.entries
        .where((e) => e.key.startsWith('$currentRoute->'))
        .toList();

    if (transitions.isEmpty) return null;

    // Zähle Vorkommen jeder Ziel-Route
    final Map<String, int> nextRouteCounts = {};
    for (var transition in transitions) {
      final nextRoute = transition.value;
      nextRouteCounts[nextRoute] = (nextRouteCounts[nextRoute] ?? 0) + 1;
    }

    // Finde häufigste
    var maxCount = 0;
    String? mostLikely;
    nextRouteCounts.forEach((route, count) {
      if (count > maxCount) {
        maxCount = count;
        mostLikely = route;
      }
    });

    return mostLikely;
  }

  /// Häufigste Routes (für Pre-Warming beim App-Start)
  List<String> getMostFrequentRoutes({int limit = 3}) {
    final sorted = _routeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Statistiken
  Map<String, dynamic> getStats() {
    return {
      'total_routes': _routeFrequency.length,
      'total_transitions': _routeTransitions.length,
      'most_frequent': getMostFrequentRoutes(limit: 5),
      'route_frequency': _routeFrequency,
    };
  }
}
