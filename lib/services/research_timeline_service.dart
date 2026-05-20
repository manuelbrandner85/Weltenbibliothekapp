// Research-Timeline-Service (R1).
// Liefert TimelineEvents aus der Supabase-Tabelle 'research_timeline'
// (Migration v97). Cached lokal fuer Offline-Fallback.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

class TimelineEventV2 {
  final String id;
  final String title;
  final String dateDisplay;
  final DateTime dateSort;
  final String description;
  final String category;
  final List<String> sources;
  final Color color;
  final String? iconName;
  final String? imageUrl;
  final bool verified;
  final String? suggestedBy;

  const TimelineEventV2({
    required this.id,
    required this.title,
    required this.dateDisplay,
    required this.dateSort,
    required this.description,
    required this.category,
    required this.sources,
    required this.color,
    this.iconName,
    this.imageUrl,
    this.verified = false,
    this.suggestedBy,
  });

  factory TimelineEventV2.fromJson(Map<String, dynamic> j) {
    final colorHex = j['color_hex'] as String? ?? '#E53935';
    final colorValue =
        int.tryParse(colorHex.replaceFirst('#', ''), radix: 16) ?? 0xE53935;
    final rawSources = j['sources'];
    final sources = rawSources is List
        ? rawSources.map((e) => e.toString()).toList()
        : <String>[];
    return TimelineEventV2(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      dateDisplay: j['date_display'] as String? ?? '',
      dateSort:
          DateTime.tryParse(j['date_sort'] as String? ?? '') ?? DateTime(1970),
      description: j['description'] as String? ?? '',
      category: j['category'] as String? ?? 'conspiracy',
      sources: sources,
      color: Color(0xFF000000 | colorValue),
      iconName: j['icon_name'] as String?,
      imageUrl: j['image_url'] as String?,
      verified: j['verified'] == true,
      suggestedBy: j['suggested_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date_display': dateDisplay,
        'date_sort': dateSort.toIso8601String(),
        'description': description,
        'category': category,
        'sources': sources,
        'color_hex':
            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        'icon_name': iconName,
        'image_url': imageUrl,
        'verified': verified,
        'suggested_by': suggestedBy,
      };
}

class ResearchTimelineService {
  ResearchTimelineService._();
  static final ResearchTimelineService instance = ResearchTimelineService._();

  static const _cacheKey = 'research_timeline_cache_v1';

  /// Holt Events aus Supabase mit optionalen Filtern + Pagination.
  /// Faellt bei Netz-/Auth-Fehler auf Cache zurueck.
  Future<List<TimelineEventV2>> fetchEvents({
    String? category,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final client = supabase;
      dynamic query = client.from('research_timeline').select();
      if (category != null && category != 'all') {
        query = query.eq('category', category);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('title.ilike.%$q%,description.ilike.%$q%');
      }
      final res = await query
          .order('date_sort', ascending: false)
          .range(offset, offset + limit - 1);
      final list = (res as List)
          .map((e) =>
              TimelineEventV2.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      // Erfolgreich -> Cache aktualisieren (nur wenn keine Filter aktiv).
      if (category == null &&
          (searchQuery == null || searchQuery.isEmpty) &&
          offset == 0) {
        await _saveCache(list);
      }
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Timeline fetch: $e');
      // Cache-Fallback
      return _loadCache();
    }
  }

  /// Schreibt einen User-Vorschlag in die Tabelle.
  /// Wegen RLS muss der User authentifiziert sein.
  Future<bool> suggestEvent({
    required String title,
    required String dateDisplay,
    required DateTime dateSort,
    required String description,
    required String category,
    required List<String> sources,
    String? suggestedBy,
  }) async {
    try {
      final client = supabase;
      await client.from('research_timeline').insert({
        'title': title,
        'date_display': dateDisplay,
        'date_sort': dateSort.toIso8601String().substring(0, 10),
        'description': description,
        'category': category,
        'sources': sources,
        'suggested_by': suggestedBy ?? client.auth.currentUser?.id,
        'verified': false,
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Timeline suggest: $e');
      return false;
    }
  }

  Future<void> _saveCache(List<TimelineEventV2> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = events.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<TimelineEventV2>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return [];
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(TimelineEventV2.fromJson).toList();
    } catch (_) {
      return [];
    }
  }
}
