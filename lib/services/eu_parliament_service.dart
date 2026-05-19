// EU-Parlament-Service: Holt letzte Plenar-Abstimmungen + MEP-Listen.
// Nutzt HowTheyVote.eu (offene Public-API, basiert auf EP-Open-Data).
//
// API-Docs: https://howtheyvote.eu/api/

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class EuVote {
  final int id;
  final String title;
  final String? description;
  final DateTime? date;
  final String result; // 'ADOPTED' | 'REJECTED' | etc.
  final int? forVotes;
  final int? againstVotes;
  final int? abstainVotes;
  final List<String> categories;
  final String? referenceText;

  const EuVote({
    required this.id,
    required this.title,
    this.description,
    this.date,
    required this.result,
    this.forVotes,
    this.againstVotes,
    this.abstainVotes,
    required this.categories,
    this.referenceText,
  });

  bool get isAdopted => result.toUpperCase() == 'ADOPTED';
  String get resultLabel => isAdopted
      ? '✅ ANGENOMMEN'
      : (result.toUpperCase() == 'REJECTED' ? '❌ ABGELEHNT' : '⚖️ $result');
  String get resultColor => isAdopted
      ? 'green'
      : (result.toUpperCase() == 'REJECTED' ? 'red' : 'amber');

  int? get total {
    if (forVotes == null && againstVotes == null && abstainVotes == null)
      return null;
    return (forVotes ?? 0) + (againstVotes ?? 0) + (abstainVotes ?? 0);
  }

  double get forRatio {
    final t = total;
    if (t == null || t == 0) return 0;
    return (forVotes ?? 0) / t;
  }

  String get fmtDate {
    if (date == null) return '?';
    final d = date!.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}

class EuMep {
  final int id;
  final String firstName;
  final String lastName;
  final String? country;
  final String? group; // EP-Gruppe: EPP, S&D, Renew, Greens, ID, ECR, Left, NI
  final String? imageUrl;

  const EuMep({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.country,
    this.group,
    this.imageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();
}

class EuParliamentService {
  static const String _base = 'https://howtheyvote.eu/api';
  static const Duration _timeout = Duration(seconds: 18);

  Future<List<EuVote>> getRecentVotes({int limit = 30}) async {
    try {
      final uri = Uri.parse('$_base/votes')
          .replace(queryParameters: {'limit': '$limit'});
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('HowTheyVote ${res.statusCode}');
        return const [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results =
          (data['results'] as List?) ?? (data['data'] as List?) ?? const [];
      return results.map(_parseVote).whereType<EuVote>().toList();
    } catch (e) {
      if (kDebugMode) debugPrint('HowTheyVote votes error: $e');
      return const [];
    }
  }

  Future<List<EuVote>> searchVotes(String query, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$_base/votes')
          .replace(queryParameters: {'q': query, 'limit': '$limit'});
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results =
          (data['results'] as List?) ?? (data['data'] as List?) ?? const [];
      return results.map(_parseVote).whereType<EuVote>().toList();
    } catch (e) {
      if (kDebugMode) debugPrint('HowTheyVote search error: $e');
      return const [];
    }
  }

  Future<EuVote?> getVoteDetail(int voteId) async {
    try {
      final uri = Uri.parse('$_base/votes/$voteId');
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return _parseVote(data);
    } catch (e) {
      if (kDebugMode) debugPrint('HowTheyVote detail error: $e');
      return null;
    }
  }

  Future<List<EuMep>> getMembers({int limit = 200}) async {
    try {
      final uri = Uri.parse('$_base/members')
          .replace(queryParameters: {'limit': '$limit'});
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results =
          (data['results'] as List?) ?? (data['data'] as List?) ?? const [];
      return results.map((r) {
        final m = r as Map<String, dynamic>;
        final country = (m['country'] as Map?)?.cast<String, dynamic>();
        final group = (m['group'] as Map?)?.cast<String, dynamic>();
        return EuMep(
          id: (m['id'] as num?)?.toInt() ?? 0,
          firstName: (m['first_name'] as String?) ?? '',
          lastName: (m['last_name'] as String?) ?? '',
          country: country?['label'] as String? ?? country?['code'] as String?,
          group: group?['short_label'] as String? ?? group?['label'] as String?,
          imageUrl: m['photo_url'] as String?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('HowTheyVote members error: $e');
      return const [];
    }
  }

  EuVote? _parseVote(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    DateTime? date;
    final dateStr = raw['date'] as String? ?? raw['timestamp'] as String?;
    if (dateStr != null) {
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {}
    }
    final stats = (raw['stats'] as Map?)?.cast<String, dynamic>();
    final categories = ((raw['geo_areas'] as List?) ?? const [])
        .map((c) => ((c as Map<String, dynamic>)['label'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return EuVote(
      id: (raw['id'] as num?)?.toInt() ?? 0,
      title: (raw['display_title'] as String?) ??
          (raw['title'] as String?) ??
          'Abstimmung',
      description: raw['description'] as String?,
      date: date,
      result: (raw['result'] as String?) ?? 'unknown',
      forVotes: (stats?['for'] as num?)?.toInt(),
      againstVotes: (stats?['against'] as num?)?.toInt(),
      abstainVotes: (stats?['abstention'] as num?)?.toInt(),
      categories: categories,
      referenceText: raw['reference'] as String?,
    );
  }
}
