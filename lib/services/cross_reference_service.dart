// Cross-Reference-Service (R7).
// Parallel-Suche ueber 12 Quellen: Wikidata, Wikipedia, OpenAlex, PubMed,
// GDELT, Guardian, CrossRef, arXiv, Internet Archive, Research-Timeline,
// Semantic Scholar + Open Library.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'free_api_service.dart';
import 'research_timeline_service.dart';
import 'supabase_service.dart';

class CrossReferenceResult {
  final List<WikidataEntry> wikidataEntries;
  final List<WikiSearchEntry> wikipediaArticles;
  final List<OpenAlexWork> openAlexWorks;
  final List<PubMedStudy> pubmedStudies;
  final List<GdeltArticle> gdeltArticles;
  final List<GuardianArticle> guardianArticles;
  final List<TimelineEventV2> timelineEvents;
  final List<CrossRefWork> crossRefWorks;
  final List<ArxivEntry> arxivPapers;
  final List<InternetArchiveDoc> archiveDocs;
  final List<SemanticScholarPaper> semanticScholarPapers;
  final List<OpenLibraryBook> openLibraryBooks;
  final int totalCount;
  final Duration searchDuration;

  const CrossReferenceResult({
    required this.wikidataEntries,
    required this.wikipediaArticles,
    required this.openAlexWorks,
    required this.pubmedStudies,
    required this.gdeltArticles,
    required this.guardianArticles,
    required this.timelineEvents,
    required this.crossRefWorks,
    required this.arxivPapers,
    required this.archiveDocs,
    required this.semanticScholarPapers,
    required this.openLibraryBooks,
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

    // Alle 12 Quellen parallel anstossen.
    final results = await Future.wait<dynamic>([
      api
          .fetchWikidataEntries(query, limit: 8)
          .catchError((_) => <WikidataEntry>[]),
      api
          .fetchWikipediaArticles(query, limit: 8)
          .catchError((_) => <WikiSearchEntry>[]),
      api
          .fetchOpenAlexWorks(query, limit: 8)
          .catchError((_) => <OpenAlexWork>[]),
      api
          .fetchPubMedStudies(query, limit: 6)
          .catchError((_) => <PubMedStudy>[]),
      api
          .fetchGdeltEvents(query: query, limit: 8)
          .catchError((_) => <GdeltArticle>[]),
      api
          .fetchGuardianNews(query, limit: 6)
          .catchError((_) => <GuardianArticle>[]),
      api
          .fetchCrossRefWorks(query, limit: 8)
          .catchError((_) => <CrossRefWork>[]),
      api.fetchArxivPapers(query, limit: 6).catchError((_) => <ArxivEntry>[]),
      api
          .fetchInternetArchiveDocs(query, limit: 6)
          .catchError((_) => <InternetArchiveDoc>[]),
      _searchTimeline(query),
      api
          .fetchSemanticScholarPapers(query, limit: 6)
          .catchError((_) => <SemanticScholarPaper>[]),
      api
          .fetchOpenLibraryBooks(query, limit: 6)
          .catchError((_) => <OpenLibraryBook>[]),
    ]);

    sw.stop();

    final wikidata = (results[0] as List).cast<WikidataEntry>();
    final wikipedia = (results[1] as List).cast<WikiSearchEntry>();
    final openAlex = (results[2] as List).cast<OpenAlexWork>();
    final pubmed = (results[3] as List).cast<PubMedStudy>();
    final gdelt = (results[4] as List).cast<GdeltArticle>();
    final guardian = (results[5] as List).cast<GuardianArticle>();
    final crossRef = (results[6] as List).cast<CrossRefWork>();
    final arxiv = (results[7] as List).cast<ArxivEntry>();
    final archive = (results[8] as List).cast<InternetArchiveDoc>();
    final timeline = (results[9] as List).cast<TimelineEventV2>();
    final semanticScholar = (results[10] as List).cast<SemanticScholarPaper>();
    final openLibrary = (results[11] as List).cast<OpenLibraryBook>();

    final total =
        wikidata.length +
        wikipedia.length +
        openAlex.length +
        pubmed.length +
        gdelt.length +
        guardian.length +
        crossRef.length +
        arxiv.length +
        archive.length +
        timeline.length +
        semanticScholar.length +
        openLibrary.length;

    return CrossReferenceResult(
      wikidataEntries: wikidata,
      wikipediaArticles: wikipedia,
      openAlexWorks: openAlex,
      pubmedStudies: pubmed,
      gdeltArticles: gdelt,
      guardianArticles: guardian,
      timelineEvents: timeline,
      crossRefWorks: crossRef,
      arxivPapers: arxiv,
      archiveDocs: archive,
      semanticScholarPapers: semanticScholar,
      openLibraryBooks: openLibrary,
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
          .map(
            (e) =>
                TimelineEventV2.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Timeline-Search: $e');
      return [];
    }
  }
}
