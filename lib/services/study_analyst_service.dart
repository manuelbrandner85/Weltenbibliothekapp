// Studien-Analyst-Service: Aggregiert Papers aus PubMed + Semantic Scholar
// und scort sie nach Qualität (Studientyp, Sample-Size, Citation-Count, TLDR).
//
// PubMed E-Utilities (kein API-Key): eutils.ncbi.nlm.nih.gov
// Semantic Scholar Graph API (kein API-Key, Rate-Limit): api.semanticscholar.org

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart' show Color, Colors;
import 'package:http/http.dart' as http;

class StudyPaper {
  final String id;
  final String source; // 'pubmed' | 'semantic'
  final String title;
  final List<String> authors;
  final String? abstractText;
  final int? year;
  final String? journal;
  final int? citationCount;
  final int? influentialCitationCount;
  final String? tldr; // Semantic Scholar auto-tldr
  final List<String> fields; // Topics
  final String? doi;
  final String? url;
  final String
      studyType; // 'rct' | 'meta' | 'review' | 'observational' | 'unknown'
  final int? sampleSize;
  final double qualityScore; // 0..1
  final Map<String, dynamic> raw;

  const StudyPaper({
    required this.id,
    required this.source,
    required this.title,
    required this.authors,
    this.abstractText,
    this.year,
    this.journal,
    this.citationCount,
    this.influentialCitationCount,
    this.tldr,
    required this.fields,
    this.doi,
    this.url,
    required this.studyType,
    this.sampleSize,
    required this.qualityScore,
    required this.raw,
  });

  String get sourceLabel => source == 'pubmed' ? 'PubMed' : 'Semantic Scholar';
  String get authorsShort {
    if (authors.isEmpty) return 'Anon.';
    if (authors.length == 1) return authors.first;
    if (authors.length == 2) return '${authors[0]}, ${authors[1]}';
    return '${authors.first} et al. (+${authors.length - 1})';
  }

  String get studyTypeLabel {
    switch (studyType) {
      case 'rct':
        return '🥇 RCT';
      case 'meta':
        return '🏆 Meta-Analyse';
      case 'review':
        return '📚 Review';
      case 'cohort':
        return '📊 Kohorte';
      case 'observational':
        return '👁️ Beobachtung';
      case 'case':
        return '📝 Fall-Studie';
      default:
        return '📄 Studie';
    }
  }

  Color get studyTypeColor {
    switch (studyType) {
      case 'rct':
        return const Color(0xFF66BB6A);
      case 'meta':
        return const Color(0xFFFFD54F);
      case 'review':
        return const Color(0xFF42A5F5);
      case 'cohort':
        return const Color(0xFF26C6DA);
      case 'observational':
        return const Color(0xFFAB47BC);
      case 'case':
        return const Color(0xFFFF7043);
      default:
        return Colors.white60;
    }
  }
}

class StudyAnalystService {
  static const Duration _timeout = Duration(seconds: 18);

  Future<List<StudyPaper>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final results = await Future.wait([
      _searchSemantic(q, limit: limit),
      _searchPubMed(q, limit: limit),
    ]);
    final all = [...results[0], ...results[1]];
    // Dedup grob über DOI oder Title-Lowercase
    final seen = <String>{};
    final out = <StudyPaper>[];
    for (final p in all) {
      final key = (p.doi != null && p.doi!.isNotEmpty)
          ? p.doi!.toLowerCase()
          : p.title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (seen.add(key)) out.add(p);
    }
    out.sort((a, b) {
      final r = b.qualityScore.compareTo(a.qualityScore);
      if (r != 0) return r;
      return (b.citationCount ?? 0).compareTo(a.citationCount ?? 0);
    });
    return out;
  }

  Future<List<StudyPaper>> _searchSemantic(String q, {int limit = 20}) async {
    try {
      final uri =
          Uri.parse('https://api.semanticscholar.org/graph/v1/paper/search')
              .replace(queryParameters: {
        'query': q,
        'limit': '$limit',
        'fields':
            'title,abstract,authors,year,citationCount,influentialCitationCount,tldr,venue,fieldsOfStudy,externalIds,publicationTypes',
      });
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('SemanticScholar ${res.statusCode}');
        return const [];
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final papers = (data['data'] as List?) ?? const [];
      return papers.map((p) {
        final m = p as Map<String, dynamic>;
        final authors = ((m['authors'] as List?) ?? const [])
            .map((a) => ((a as Map<String, dynamic>)['name'] as String?) ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        final fields =
            ((m['fieldsOfStudy'] as List?) ?? const []).cast<String>().toList();
        final pubTypes = ((m['publicationTypes'] as List?) ?? const [])
            .cast<String>()
            .toList();
        final tldr = (m['tldr'] as Map?)?.cast<String, dynamic>();
        final tldrText = tldr?['text'] as String?;
        final extIds =
            (m['externalIds'] as Map?)?.cast<String, dynamic>() ?? const {};
        final doi = extIds['DOI'] as String?;
        final type = _detectStudyType(
          (m['title'] as String? ?? '') +
              ' ' +
              (m['abstract'] as String? ?? '') +
              ' ' +
              pubTypes.join(' '),
        );
        final citation = (m['citationCount'] as int?) ?? 0;
        final influential = (m['influentialCitationCount'] as int?) ?? 0;
        final score = _qualityScore(
          type: type,
          year: m['year'] as int?,
          citation: citation,
          influential: influential,
        );
        return StudyPaper(
          id: 'ss:${m['paperId']}',
          source: 'semantic',
          title: (m['title'] as String?) ?? '',
          authors: authors,
          abstractText: m['abstract'] as String?,
          year: m['year'] as int?,
          journal: (m['venue'] as String?)?.toString(),
          citationCount: citation,
          influentialCitationCount: influential,
          tldr: tldrText,
          fields: fields,
          doi: doi,
          url: doi != null && doi.isNotEmpty
              ? 'https://doi.org/$doi'
              : 'https://www.semanticscholar.org/paper/${m['paperId']}',
          studyType: type,
          sampleSize: _extractSampleSize(m['abstract'] as String? ?? ''),
          qualityScore: score,
          raw: m,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('SemanticScholar error: $e');
      return const [];
    }
  }

  Future<List<StudyPaper>> _searchPubMed(String q, {int limit = 20}) async {
    try {
      // 1. ESearch: get IDs
      final searchUri = Uri.parse(
              'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi')
          .replace(queryParameters: {
        'db': 'pubmed',
        'term': q,
        'retmode': 'json',
        'retmax': '$limit',
        'sort': 'relevance',
      });
      final searchRes = await http.get(searchUri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (searchRes.statusCode != 200) return const [];
      final searchData = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final esr =
          (searchData['esearchresult'] as Map?)?.cast<String, dynamic>();
      final ids = ((esr?['idlist'] as List?) ?? const []).cast<String>();
      if (ids.isEmpty) return const [];

      // 2. ESummary: details
      final sumUri = Uri.parse(
              'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi')
          .replace(queryParameters: {
        'db': 'pubmed',
        'id': ids.join(','),
        'retmode': 'json',
      });
      final sumRes = await http.get(sumUri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (sumRes.statusCode != 200) return const [];
      final sumData = jsonDecode(sumRes.body) as Map<String, dynamic>;
      final result =
          (sumData['result'] as Map?)?.cast<String, dynamic>() ?? const {};
      return ids
          .map((id) {
            final m = (result[id] as Map?)?.cast<String, dynamic>();
            if (m == null) return null;
            final authors = ((m['authors'] as List?) ?? const [])
                .map((a) =>
                    ((a as Map<String, dynamic>)['name'] as String?) ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            final yearStr = m['pubdate'] as String? ?? '';
            final yearMatch = RegExp(r'(\d{4})').firstMatch(yearStr);
            final year =
                yearMatch != null ? int.tryParse(yearMatch.group(1)!) : null;
            final pubTypeList =
                ((m['pubtype'] as List?) ?? const []).cast<String>();
            final fullTitle = m['title'] as String? ?? '';
            final type =
                _detectStudyType('$fullTitle ${pubTypeList.join(" ")}');
            final score = _qualityScore(
              type: type,
              year: year,
              citation: null,
              influential: null,
            );
            return StudyPaper(
              id: 'pm:$id',
              source: 'pubmed',
              title: fullTitle.replaceAll(RegExp(r'<[^>]+>'), ''),
              authors: authors,
              abstractText: null, // ESummary hat keinen Abstract, müsste efetch
              year: year,
              journal: m['fulljournalname'] as String?,
              citationCount: null,
              influentialCitationCount: null,
              tldr: null,
              fields: const [],
              doi: ((m['articleids'] as List?) ?? const [])
                  .cast<Map>()
                  .firstWhere((x) => x['idtype'] == 'doi',
                      orElse: () => {})['value'] as String?,
              url: 'https://pubmed.ncbi.nlm.nih.gov/$id/',
              studyType: type,
              sampleSize: null,
              qualityScore: score,
              raw: m,
            );
          })
          .whereType<StudyPaper>()
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('PubMed error: $e');
      return const [];
    }
  }

  // Detect study type from text (title + abstract + pubtypes)
  String _detectStudyType(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'meta[\s-]?analy').hasMatch(t)) return 'meta';
    if (RegExp(r'systematic\s+review').hasMatch(t)) return 'review';
    if (RegExp(
            r'\brct\b|randomi[sz]ed\s+controlled\s+trial|randomi[sz]ed\s+clinical\s+trial')
        .hasMatch(t)) return 'rct';
    if (RegExp(r'cohort\s+study').hasMatch(t)) return 'cohort';
    if (RegExp(r'case\s+report|case\s+series').hasMatch(t)) return 'case';
    if (RegExp(r'\breview\b').hasMatch(t)) return 'review';
    if (RegExp(r'observational\s+study|cross[\s-]?sectional|case[\s-]?control')
        .hasMatch(t)) return 'observational';
    return 'unknown';
  }

  int? _extractSampleSize(String abstract) {
    // Hint: "n=1234" oder "1234 patients" oder "1,234 participants"
    final m =
        RegExp(r'(?:n\s*=\s*|N\s*=\s*)(\d[\d,]{1,8})').firstMatch(abstract);
    if (m != null) {
      return int.tryParse(m.group(1)!.replaceAll(',', ''));
    }
    final m2 = RegExp(
            r'(\d[\d,]{1,8})\s+(?:patients|participants|subjects|individuals)',
            caseSensitive: false)
        .firstMatch(abstract);
    if (m2 != null) {
      return int.tryParse(m2.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  double _qualityScore({
    required String type,
    int? year,
    int? citation,
    int? influential,
  }) {
    double score = 0;
    // Study-Type-Gewicht (Evidence-Pyramide)
    switch (type) {
      case 'meta':
        score += 0.4;
        break;
      case 'review':
        score += 0.3;
        break;
      case 'rct':
        score += 0.35;
        break;
      case 'cohort':
        score += 0.25;
        break;
      case 'observational':
        score += 0.15;
        break;
      case 'case':
        score += 0.05;
        break;
      default:
        score += 0.1;
    }
    // Aktualität (max 0.2 für jünger als 5 Jahre)
    if (year != null) {
      final age = DateTime.now().year - year;
      score += (0.2 * (1 - (age / 25).clamp(0, 1)));
    }
    // Zitierungen log10-scaling (max 0.3)
    if (citation != null && citation > 0) {
      final s = (math.log(citation + 1) / math.log(1000)).clamp(0.0, 1.0);
      score += 0.3 * s;
    } else if (citation == null) {
      score += 0.15; // unknown — neutral
    }
    // Influential citations bonus (max 0.1)
    if (influential != null && influential > 0) {
      score += (influential / 100).clamp(0.0, 0.1);
    }
    return score.clamp(0.0, 1.0);
  }
}
