// Ursprung core tool: "Zeitleiste der Menschheitsursprünge".
// Reads the public ursprung_timeline knowledge base from Supabase with a small
// local fallback so the timeline is never empty (offline / first launch).

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// One timeline entry. Plain Dart class (NO Dart 3 record types).
class UrsprungTimelineEntry {
  final String id;
  final String slug;
  final int sortOrder;
  final String? era;
  final String? yearLabel;
  final String title;

  /// One of: 'schoepfungsmythos', 'urkultur', 'offene_frage'.
  final String category;
  final String? summary;
  final String? details;

  /// Cross-references into the other worlds. Keys: 'materie','energie','vorhang'.
  final Map<String, String> crossWorldRefs;
  final List<String> keywords;

  const UrsprungTimelineEntry({
    required this.id,
    required this.slug,
    required this.sortOrder,
    this.era,
    this.yearLabel,
    required this.title,
    this.category = 'urkultur',
    this.summary,
    this.details,
    this.crossWorldRefs = const {},
    this.keywords = const [],
  });

  factory UrsprungTimelineEntry.fromJson(Map<String, dynamic> j) =>
      UrsprungTimelineEntry(
        id: j['id'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
        era: j['era'] as String?,
        yearLabel: j['year_label'] as String?,
        title: j['title'] as String? ?? '',
        category: j['category'] as String? ?? 'urkultur',
        summary: j['summary'] as String?,
        details: j['details'] as String?,
        crossWorldRefs: _stringMap(j['cross_world_refs']),
        keywords: _stringList(j['keywords']),
      );

  static List<String> _stringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, String> _stringMap(dynamic v) {
    if (v is Map) {
      final out = <String, String>{};
      v.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          out[key.toString()] = value.toString();
        }
      });
      return out;
    }
    return const {};
  }
}

/// Singleton service: Supabase-first with a resilient local fallback.
/// Read-only on the client; content is curated by content_editor+.
class UrsprungTimelineService {
  UrsprungTimelineService._();
  static final UrsprungTimelineService instance = UrsprungTimelineService._();

  /// Human-readable labels for the three categories (German UI).
  static const Map<String, String> categoryLabels = {
    'schoepfungsmythos': 'Schoepfungsmythen',
    'urkultur': 'Urkulturen',
    'offene_frage': 'Offene Fragen',
  };

  /// Fetches all entries ordered chronologically, optionally filtered by
  /// [category]. Falls back to a built-in list on any error.
  Future<List<UrsprungTimelineEntry>> fetch({String? category}) async {
    try {
      final client = supabase;
      // var keeps the typed PostgrestFilterBuilder (avoids dynamic calls).
      var q = client.from('ursprung_timeline').select();
      if (category != null && category.trim().isNotEmpty) {
        q = q.eq('category', category.trim());
      }
      final res = await q.order('sort_order', ascending: true);
      final list = (res as List)
          .map((e) => UrsprungTimelineEntry.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isEmpty && category == null) return _fallback;
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Ursprung-Timeline fetch: $e');
      if (category == null) return _fallback;
      return _fallback.where((e) => e.category == category).toList();
    }
  }

  /// Minimal offline fallback (mirrors the v121 seed head). Keeps the timeline
  /// usable before the first successful network fetch.
  static const List<UrsprungTimelineEntry> _fallback = [
    UrsprungTimelineEntry(
      id: 'fallback-urknall',
      slug: 'urknall',
      sortOrder: 10,
      era: 'Kosmischer Ursprung',
      yearLabel: 'vor ca. 13,8 Mrd. Jahren',
      title: 'Der Urknall',
      category: 'offene_frage',
      summary:
          'Raum, Zeit und Materie entstehen aus einem extrem dichten Anfangszustand.',
      details:
          'Die Kosmologie beschreibt die Expansion ab einem Anfangszustand -- aber was davor war, bleibt offen.',
      crossWorldRefs: {
        'materie': 'Kosmologie und Big-Bang-Physik',
        'energie': 'Schoepfung aus dem Einen / Urschwingung',
        'vorhang': 'Deutungshoheit ueber den Anfang',
      },
      keywords: ['urknall', 'kosmos', 'anfang'],
    ),
    UrsprungTimelineEntry(
      id: 'fallback-goebekli-tepe',
      slug: 'goebekli-tepe',
      sortOrder: 40,
      era: 'Jungsteinzeit',
      yearLabel: 'ca. 9600 v. Chr.',
      title: 'Goebekli Tepe',
      category: 'urkultur',
      summary:
          'Aeltestes bekanntes monumentales Heiligtum -- von Jaegern und Sammlern errichtet.',
      details:
          'Stellt die Annahme in Frage, dass erst Sesshaftigkeit Tempel ermoeglichte.',
      crossWorldRefs: {
        'materie': 'Archaeologie und Datierung',
        'energie': 'Heilige Orte und Ritual',
        'vorhang': 'Verschuettetes Wissen ueber unsere Vergangenheit',
      },
      keywords: ['goebekli tepe', 'tempel', 'jungsteinzeit'],
    ),
  ];
}
