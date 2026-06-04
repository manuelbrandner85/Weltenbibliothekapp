// Vorhang core tool: "Symbol- & Logo-Decoder".
// Reads the public vorhang_symbols knowledge base from Supabase with a small
// local fallback so the decoder is never empty (offline / first launch).

import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

/// One decoded symbol: possible meanings, origin and cross-world references.
/// Plain Dart class (NO Dart 3 record types -- those break dart2js).
class VorhangSymbol {
  final String id;
  final String slug;
  final String name;
  final String? emoji;
  final String? imageUrl;
  final String? category;
  final String? shortMeaning;
  final List<String> meanings;
  final String? origin;

  /// Cross-references into the other worlds. Keys: 'materie','energie','ursprung'.
  final Map<String, String> crossWorldRefs;
  final List<String> keywords;

  const VorhangSymbol({
    required this.id,
    required this.slug,
    required this.name,
    this.emoji,
    this.imageUrl,
    this.category,
    this.shortMeaning,
    this.meanings = const [],
    this.origin,
    this.crossWorldRefs = const {},
    this.keywords = const [],
  });

  factory VorhangSymbol.fromJson(Map<String, dynamic> j) => VorhangSymbol(
        id: j['id'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        name: j['name'] as String? ?? '',
        emoji: j['emoji'] as String?,
        imageUrl: j['image_url'] as String?,
        category: j['category'] as String?,
        shortMeaning: j['short_meaning'] as String?,
        meanings: _stringList(j['meanings']),
        origin: j['origin'] as String?,
        crossWorldRefs: _stringMap(j['cross_world_refs']),
        keywords: _stringList(j['keywords']),
      );

  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
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

/// Singleton service mirroring [UrsprungTopicsService]: Supabase-first with a
/// resilient local fallback. Read-only on the client; content is curated by
/// content_editor+ via the Worker.
class VorhangSymbolsService {
  VorhangSymbolsService._();
  static final VorhangSymbolsService instance = VorhangSymbolsService._();

  /// Fetches symbols, optionally filtered by [searchQuery] (name / meaning /
  /// keywords) and [category]. Falls back to a built-in list on any error.
  Future<List<VorhangSymbol>> fetch({
    String? searchQuery,
    String? category,
  }) async {
    try {
      final client = supabase;
      // Keep the typed PostgrestFilterBuilder (var infers it) so the optional
      // filters chain without falling back to `dynamic` (avoids dynamic calls).
      var q = client.from('vorhang_symbols').select();
      if (category != null && category.trim().isNotEmpty) {
        q = q.eq('category', category.trim());
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final s = searchQuery.trim();
        q = q.or('name.ilike.%$s%,short_meaning.ilike.%$s%');
      }
      final res = await q.order('name', ascending: true);
      final list = (res as List)
          .map((e) =>
              VorhangSymbol.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isEmpty && (searchQuery == null || searchQuery.isEmpty)) {
        return _fallback;
      }
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Vorhang-Symbols fetch: $e');
      return _filteredFallback(searchQuery, category);
    }
  }

  List<VorhangSymbol> _filteredFallback(String? searchQuery, String? category) {
    Iterable<VorhangSymbol> items = _fallback;
    if (category != null && category.trim().isNotEmpty) {
      items = items.where((s) => s.category == category.trim());
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final s = searchQuery.trim().toLowerCase();
      items = items.where((sym) =>
          sym.name.toLowerCase().contains(s) ||
          (sym.shortMeaning ?? '').toLowerCase().contains(s) ||
          sym.keywords.any((k) => k.toLowerCase().contains(s)));
    }
    return items.toList();
  }

  /// Minimal offline fallback (mirrors the v120 seed). Keeps the tool usable
  /// before the first successful network fetch.
  static const List<VorhangSymbol> _fallback = [
    VorhangSymbol(
      id: 'fallback-all-seeing-eye',
      slug: 'all-seeing-eye',
      name: 'Allsehendes Auge',
      emoji: '👁️',
      category: 'Okkult',
      shortMeaning:
          'Auge in Dreieck/Strahlenkranz -- Symbol fuer Allwissenheit und Beobachtung.',
      meanings: [
        'Goettliche Vorsehung und Allwissenheit',
        'Wachsamkeit und Schutz',
        'In Verschwoerungs-Narrativen: verborgene Kontrolle / Ueberwachung',
      ],
      origin:
          'Christliche Ikonografie (Auge der Vorsehung); aufgegriffen in Freimaurer-Symbolik.',
      crossWorldRefs: {
        'materie': 'Ueberwachungsstaat und Panopticon',
        'energie': 'Drittes Auge / Ajna-Chakra',
        'ursprung': 'Auge des Ra / Horus in aegyptischer Mythologie',
      },
      keywords: ['auge', 'vorsehung', 'dreieck', 'ueberwachung'],
    ),
    VorhangSymbol(
      id: 'fallback-ouroboros',
      slug: 'ouroboros',
      name: 'Ouroboros',
      emoji: '🐍',
      category: 'Mythologie',
      shortMeaning:
          'Schlange, die sich in den eigenen Schwanz beisst -- Kreislauf und Ewigkeit.',
      meanings: [
        'Ewige Wiederkehr und Zyklus von Werden/Vergehen',
        'Einheit von Anfang und Ende',
        'Alchemistisches Symbol der Wandlung',
      ],
      origin: 'Altaegypten und Antike; zentrales Bild der Alchemie.',
      crossWorldRefs: {
        'materie': 'Geschlossene Systeme und Recycling',
        'energie': 'Karma und Wiedergeburt',
        'ursprung': 'Schoepfung aus dem Chaos / Weltenschlange',
      },
      keywords: ['schlange', 'kreislauf', 'ewigkeit', 'alchemie'],
    ),
  ];
}
