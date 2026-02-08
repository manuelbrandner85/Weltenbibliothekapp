/// 📊 PRIVACY-FRIENDLY ANALYTICS SERVICE
/// Local analytics without external tracking
/// 
/// Features:
/// - Local event tracking
/// - User statistics
/// - Usage patterns
/// - Privacy-first (no external services)
/// - GDPR compliant
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic>? properties;
  final DateTime timestamp;
  
  AnalyticsEvent({
    required this.name,
    this.properties,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'] as String,
      properties: json['properties'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class PrivacyAnalyticsService {
  static const String _eventsKey = 'analytics_events';
  static const String _statsKey = 'analytics_stats';
  static const int _maxEvents = 1000; // Keep last 1000 events
  
  /// Track event
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    try {
      final event = AnalyticsEvent(
        name: eventName,
        properties: properties,
      );
      
      // Save event
      await _saveEvent(event);
      
      // Update stats
      await _updateStats(eventName);
      
      if (kDebugMode) {
        debugPrint('📊 Event tracked: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error tracking event: $e');
      }
    }
  }
  
  /// Save event to local storage
  Future<void> _saveEvent(AnalyticsEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsKey);
      
      List<Map<String, dynamic>> events = [];
      if (eventsJson != null) {
        events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));
      }
      
      events.add(event.toJson());
      
      // Keep only last N events
      if (events.length > _maxEvents) {
        events = events.sublist(events.length - _maxEvents);
      }
      
      await prefs.setString(_eventsKey, jsonEncode(events));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving event: $e');
      }
    }
  }
  
  /// Update statistics
  Future<void> _updateStats(String eventName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);
      
      Map<String, dynamic> stats = {};
      if (statsJson != null) {
        stats = Map<String, dynamic>.from(jsonDecode(statsJson));
      }
      
      // Increment event count
      stats[eventName] = (stats[eventName] ?? 0) + 1;
      
      // Update total events
      stats['_total'] = (stats['_total'] ?? 0) + 1;
      
      // Update last event time
      stats['_last_event'] = DateTime.now().toIso8601String();
      
      await prefs.setString(_statsKey, jsonEncode(stats));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating stats: $e');
      }
    }
  }
  
  /// Get all events
  Future<List<AnalyticsEvent>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsKey);
      
      if (eventsJson == null) return [];
      
      final eventsList = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));
      return eventsList.map((e) => AnalyticsEvent.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting events: $e');
      }
      return [];
    }
  }
  
  /// Get statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);
      
      if (statsJson == null) return {};
      
      return Map<String, dynamic>.from(jsonDecode(statsJson));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting stats: $e');
      }
      return {};
    }
  }
  
  /// Get event count
  Future<int> getEventCount(String eventName) async {
    final stats = await getStats();
    return stats[eventName] ?? 0;
  }
  
  /// Get total events
  Future<int> getTotalEvents() async {
    final stats = await getStats();
    return stats['_total'] ?? 0;
  }
  
  /// Get events by date range
  Future<List<AnalyticsEvent>> getEventsByDateRange(DateTime start, DateTime end) async {
    final allEvents = await getEvents();
    return allEvents.where((e) {
      return e.timestamp.isAfter(start) && e.timestamp.isBefore(end);
    }).toList();
  }
  
  /// Get top events
  Future<List<MapEntry<String, int>>> getTopEvents({int limit = 10}) async {
    final stats = await getStats();
    
    // Remove meta keys
    stats.remove('_total');
    stats.remove('_last_event');
    
    // Sort by count
    final entries = stats.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return entries.take(limit).map((e) {
      return MapEntry(e.key, e.value as int);
    }).toList();
  }
  
  /// Clear all analytics data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_eventsKey);
      await prefs.remove(_statsKey);
      
      if (kDebugMode) {
        debugPrint('🗑️ All analytics data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing analytics: $e');
      }
    }
  }
  
  /// Common event names
  static const String eventAppOpen = 'app_open';
  static const String eventScreenView = 'screen_view';
  static const String eventSearch = 'search';
  static const String eventShare = 'share';
  static const String eventBookmark = 'bookmark';
  static const String eventChatMessage = 'chat_message';
  static const String eventVoiceMessage = 'voice_message';
  static const String eventPdfView = 'pdf_view';
  static const String eventMapView = 'map_view';
}
