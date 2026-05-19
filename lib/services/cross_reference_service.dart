// Cross-Reference-Service (R7).
// Parallel-Suche ueber 7 Quellen: Wikidata, OpenAlex, PubMed, GDELT,
// Guardian, CrossRef + research_timeline (Supabase).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'free_api_service.dart';
import 'research_timeline_service.dart';
import 'supabase_service.dart';

class CrossReferenceResult {
  final List<WikidataEntry> wikidataEntries;
  final List<OpenAlexWork> openAlexWorks;
  final List<PubMedStudy> pubmedStudies;
  final List<GdeltArticle> gdeltArticles;
  final List<GuardianArticle> guardianArticles;
  final List<TimelineEventV2> timelineEvents;
  final List<CrossRefWork> crossRefWorks;
  final int totalCount;
  final Duration searchDuration;

  const CrossReferenceResult({
    required this.wikidataEntries,
    required this.openAlexWorks,
    required this.pubmedStudies,
    required this.gdeltArticles,
    required this.guardianArticles,
    required this.timelineEvents,
    required this.crossRefWorks,
    required this.totalCount,
    required this.searchDuration,
  });

  bool get isEmpty => totalCount == 0;
}

class CrossReferenceService {
  CrossReferenceService._();
  static final CrossReferenceService instance = CrossReferenceService._();

  Future<CrossReferenceResult> searchAll(String query) async {
    final sw = Stopwatch()..start();
    final api = FreeApiService.instance;

    // Alle 7 Quellen parallel anstossen.
    final results = await Future.wait<dynamic>([
      api
          .fetchWikidataEntries(query, limit: 10)
          .catchError((_) => <WikidataEntry>[]),
      api
          .fetchOpenAlexWorks(query, limit: 10)
          .catchError((_) => <OpenAlexWork>[]),
      api
          .fetchPubMedStudies(query, limit: 8)
          .catchError((_) => <PubMedStudy>[]),
      api.fetchGdeltEvents(query: query).catchError((_) => <GdeltArticle>[]),
      api
          .fetchGuardianNews(query, limit: 8)
          .catchError((_) => <GuardianArticle>[]),
      api
          .fetchCrossRefWorks(query, limit: 10)
          .catchError((_) => <CrossRefWork>[]),
      _searchTimeline(query),
    ]);

    sw.stop();

    final wikidata = (results[0] as List).cast<WikidataEntry>();
    final openAlex = (results[1] as List).cast<OpenAlexWork>();
    final pubmed = (results[2] as List).cast<PubMedStudy>();
    final gdelt = (results[3] as List).cast<GdeltArticle>();
    final guardian = (results[4] as List).cast<GuardianArticle>();
    final crossRef = (results[5] as List).cast<CrossRefWork>();
    final timeline = (results[6] as List).cast<TimelineEventV2>();

    final total = wikidata.length +
        openAlex.length +
        pubmed.length +
        gdelt.length +
        guardian.length +
        crossRef.length +
        timeline.length;

    return CrossReferenceResult(
      wikidataEntries: wikidata,
      openAlexWorks: openAlex,
      pubmedStudies: pubmed,
      gdeltArticles: gdelt,
      guardianArticles: guardian,
      timelineEvents: timeline,
      crossRefWorks: crossRef,
      totalCount: total,
      searchDuration: sw.elapsed,
    );
  }

  Future<List<TimelineEventV2>> _searchTimeline(String query) async {
    try {
      final client = supabase;
      final q = query.trim();
      if (q.isEmpty) return [];
      final res = await client
          .from('research_timeline')
          .select()
          .or('title.ilike.%$q%,description.ilike.%$q%')
          .eq('verified', true)
          .limit(10);
      return (res as List)
          .map((e) =>
              TimelineEventV2.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Timeline-Search: $e');
      return [];
    }
  }
}
