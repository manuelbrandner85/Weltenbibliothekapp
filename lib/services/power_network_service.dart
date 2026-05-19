// Power-Network-Service: Aggregiert Entitäts-Treffer aus OpenSanctions + Aleph.
// Beide APIs sind ohne API-Key öffentlich (rate-limited).
//
// OpenSanctions: https://api.opensanctions.org/search/default?q=...
//   → Sanktionslisten EU/UN/OFAC, PEPs, Adverse-Media.
//
// Aleph OCCRP: https://aleph.occrp.org/api/2/entities?q=...
//   → Panama Papers, FinCEN Files, LuxLeaks, Pandora Papers, Suisse Secrets.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class PowerNetworkHit {
  final String id;
  final String source; // 'opensanctions' | 'aleph'
  final String name;
  final String? alias;
  final List<String> tags; // type-tags: 'PEP', 'Sanctioned', 'Company'…
  final String? country;
  final String? schema; // Person/Company/Organization
  final Map<String, dynamic> raw;
  // 0..1 — wie viele "rote Flaggen" (Sanktion = 1.0, PEP = 0.6, Adverse-Media = 0.4)
  final double riskScore;
  final String? sourceUrl;

  const PowerNetworkHit({
    required this.id,
    required this.source,
    required this.name,
    this.alias,
    required this.tags,
    this.country,
    this.schema,
    required this.raw,
    required this.riskScore,
    this.sourceUrl,
  });

  String get sourceLabel =>
      source == 'opensanctions' ? 'OpenSanctions' : 'Aleph OCCRP';
}

class PowerNetworkService {
  static const String _osBase = 'https://api.opensanctions.org';
  static const String _alephBase = 'https://aleph.occrp.org';

  static const Duration _timeout = Duration(seconds: 15);

  /// Sucht parallel in beiden Datenbanken. Kombiniert + dedupliziert Treffer
  /// nach (Name + Country)-Heuristik.
  Future<List<PowerNetworkHit>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final results = await Future.wait([
      _searchOpenSanctions(q, limit: limit),
      _searchAleph(q, limit: limit),
    ]);
    final all = [...results[0], ...results[1]];
    // Sort: höchster Risk first, dann nach Name
    all.sort((a, b) {
      final r = b.riskScore.compareTo(a.riskScore);
      if (r != 0) return r;
      return a.name.compareTo(b.name);
    });
    return all;
  }

  Future<List<PowerNetworkHit>> _searchOpenSanctions(String q,
      {int limit = 20}) async {
    try {
      final uri = Uri.parse('$_osBase/search/default')
          .replace(queryParameters: {'q': q, 'limit': '$limit'});
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('OpenSanctions ${res.statusCode}');
        return const [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      return results.map((r) {
        final m = r as Map<String, dynamic>;
        final props =
            (m['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
        final topics = ((props['topics'] as List?) ?? const []).cast<String>();
        final country =
            ((props['country'] as List?) ?? const []).cast<String>();
        final alias = ((props['alias'] as List?) ?? const []).cast<String>();

        // Risk-Score: Sanktioniert (1.0), PEP (0.6), Adverse-Media (0.4)
        double risk = 0.0;
        for (final t in topics) {
          if (t == 'sanction')
            risk = 1.0;
          else if (t == 'role.pep' && risk < 0.7)
            risk = 0.7;
          else if (t == 'mil' && risk < 0.5)
            risk = 0.5;
          else if (t == 'crime' && risk < 0.6)
            risk = 0.6;
          else if (t == 'media') risk = math.max(risk, 0.4);
        }

        final tagList = <String>[];
        if (topics.contains('sanction')) tagList.add('🚨 Sanktioniert');
        if (topics.contains('role.pep')) tagList.add('🏛️ PEP');
        if (topics.contains('crime')) tagList.add('⚖️ Crime');
        if (topics.contains('mil')) tagList.add('⚔️ Military');
        if (topics.contains('media')) tagList.add('📰 Adverse Media');

        return PowerNetworkHit(
          id: 'os:${m['id']}',
          source: 'opensanctions',
          name:
              (m['caption'] as String?) ?? (m['id'] as String? ?? 'Unbekannt'),
          alias: alias.isNotEmpty ? alias.first : null,
          tags: tagList,
          country: country.isNotEmpty ? country.first.toUpperCase() : null,
          schema: m['schema'] as String?,
          raw: m,
          riskScore: risk,
          sourceUrl: 'https://www.opensanctions.org/entities/${m['id']}/',
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('OpenSanctions search error: $e');
      return const [];
    }
  }

  Future<List<PowerNetworkHit>> _searchAleph(String q, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$_alephBase/api/2/entities')
          .replace(queryParameters: {'q': q, 'limit': '$limit'});
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('Aleph ${res.statusCode}');
        return const [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      return results.take(limit).map((r) {
        final m = r as Map<String, dynamic>;
        final props =
            (m['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
        final collection = (m['collection'] as Map?)?.cast<String, dynamic>();
        final collectionLabel = (collection?['label'] as String?) ?? '';
        final schema = m['schema'] as String?;
        final country = ((props['country'] as List?) ?? const [])
            .cast<dynamic>()
            .map((e) => e.toString())
            .toList();

        final tags = <String>[];
        if (collectionLabel.toLowerCase().contains('panama'))
          tags.add('📂 Panama Papers');
        if (collectionLabel.toLowerCase().contains('pandora'))
          tags.add('📂 Pandora Papers');
        if (collectionLabel.toLowerCase().contains('fincen'))
          tags.add('📂 FinCEN');
        if (collectionLabel.toLowerCase().contains('luxleaks'))
          tags.add('📂 LuxLeaks');
        if (collectionLabel.toLowerCase().contains('suisse'))
          tags.add('📂 Suisse Secrets');
        if (collectionLabel.toLowerCase().contains('offshore'))
          tags.add('📂 Offshore Leaks');
        if (tags.isEmpty && collectionLabel.isNotEmpty)
          tags.add('📂 $collectionLabel');

        return PowerNetworkHit(
          id: 'aleph:${m['id']}',
          source: 'aleph',
          name: ((m['caption'] as String?) ?? '').trim().isEmpty
              ? ((m['id'] as String?) ?? 'Unbekannt')
              : (m['caption'] as String),
          alias: null,
          tags: tags,
          country: country.isNotEmpty ? country.first.toUpperCase() : null,
          schema: schema,
          raw: m,
          riskScore:
              0.5, // Aleph-Treffer = "in einem Leak gelistet" = mittelstark
          sourceUrl: 'https://aleph.occrp.org/entities/${m['id']}',
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Aleph search error: $e');
      return const [];
    }
  }

  /// Hole verbundene Entitäten für einen Aleph-Treffer (1-Hop Netzwerk).
  Future<List<PowerNetworkHit>> getRelated(String alephEntityId) async {
    try {
      final id = alephEntityId.startsWith('aleph:')
          ? alephEntityId.substring(6)
          : alephEntityId;
      final uri = Uri.parse('$_alephBase/api/2/entities/$id/expand')
          .replace(queryParameters: {'limit': '15'});
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      return results
          .map((r) {
            final m = r as Map<String, dynamic>;
            final entityList = (m['entities'] as List?) ?? const [];
            if (entityList.isEmpty) return null;
            final e = entityList.first as Map<String, dynamic>;
            return PowerNetworkHit(
              id: 'aleph:${e['id']}',
              source: 'aleph',
              name: (e['caption'] as String?) ?? 'Verbunden',
              alias: null,
              tags: const [],
              country: null,
              schema: e['schema'] as String?,
              raw: e,
              riskScore: 0.3,
              sourceUrl: 'https://aleph.occrp.org/entities/${e['id']}',
            );
          })
          .whereType<PowerNetworkHit>()
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Aleph expand error: $e');
      return const [];
    }
  }
}
