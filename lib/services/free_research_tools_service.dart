import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 🔍 FREE RESEARCH TOOLS SERVICE
/// v5.28.0 – Kostenlose professionelle Recherche-APIs
///
/// Integrierte APIs (alle kostenlos, kein API-Key nötig):
/// ──────────────────────────────────────────────────────
/// 1. Wikipedia REST API       – Artikel, Zusammenfassungen, Volltextsuche
/// 2. DuckDuckGo Instant API   – Schnellinfos, Definitionen, Infoboxen
/// 3. OpenAlex API             – 250M+ wissenschaftliche Paper (ex-MAG)
/// 4. arXiv API                – Preprints aus Physik, Mathe, CS, Bio, ...
/// 5. Internet Archive API     – Historische Webseiten, Wayback Machine
/// 6. Wikidata API             – Strukturierte Wissensdatenbank (Facts)
/// 7. CrossRef API             – DOI-Metadaten, Zitierungen, Autoren
/// 8. OpenLibrary API          – 20M+ Bücher, Autoren, Themen
/// 9. GeoNames API             – Geografische Daten, Länderinformationen (kostenlos mit Account)
///10. NewsAPI.org (kostenlos)  – Aktuelle Nachrichten (100 req/day free tier)

class FreeResearchToolsService {
  static const String _userAgent = 'Weltenbibliothek/5.28 (manuelbrandner85@github)';
  static const Duration _timeout = Duration(seconds: 15);

  // ─────────────────────────────────────────────
  // 1. WIKIPEDIA API
  // Offizielle REST API, kein Key nötig
  // ─────────────────────────────────────────────

  /// Wikipedia-Zusammenfassung für einen Begriff
  Future<WikipediaSummary?> getWikipediaSummary(String query, {String lang = 'de'}) async {
    try {
      final encoded = Uri.encodeComponent(query.replaceAll(' ', '_'));
      final url = 'https://$lang.wikipedia.org/api/rest_v1/page/summary/$encoded';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': _userAgent},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WikipediaSummary.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wikipedia API: $e');
      return null;
    }
  }

  /// Wikipedia-Volltextsuche
  Future<List<WikipediaSearchResult>> searchWikipedia(String query, {
    String lang = 'de',
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=search&format=json&srsearch=${Uri.encodeComponent(query)}'
        '&srlimit=$limit&srinfo=totalhits&srprop=snippet|titlesnippet',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['query']?['search'] as List? ?? [];
        return results.map((r) => WikipediaSearchResult.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wikipedia Search: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 2. DUCKDUCKGO INSTANT ANSWER API
  // Kein Key, kein Rate-Limit (fair use)
  // ─────────────────────────────────────────────

  Future<DuckDuckGoResult?> getDuckDuckGoInstant(String query) async {
    try {
      final url = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}'
        '&format=json&no_html=1&skip_disambig=1',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DuckDuckGoResult.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ DuckDuckGo API: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 3. OPENALEX API
  // 250M+ wissenschaftliche Arbeiten, kein Key nötig
  // ─────────────────────────────────────────────

  Future<List<OpenAlexWork>> searchOpenAlex(String query, {int limit = 10}) async {
    try {
      final url = Uri.parse(
        'https://api.openalex.org/works'
        '?search=${Uri.encodeComponent(query)}'
        '&per-page=$limit'
        '&sort=cited_by_count:desc'
        '&select=id,title,publication_year,doi,cited_by_count,open_access,primary_location',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List? ?? [];
        return results.map((r) => OpenAlexWork.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OpenAlex API: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 4. ARXIV API
  // Kostenlos, kein Key, XML oder JSON
  // ─────────────────────────────────────────────

  Future<List<ArxivPaper>> searchArxiv(String query, {
    int maxResults = 10,
    String sortBy = 'relevance', // 'relevance' | 'lastUpdatedDate' | 'submittedDate'
  }) async {
    try {
      final url = Uri.parse(
        'https://export.arxiv.org/api/query'
        '?search_query=all:${Uri.encodeComponent(query)}'
        '&max_results=$maxResults'
        '&sortBy=$sortBy'
        '&sortOrder=descending',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        return _parseArxivXml(response.body);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ arXiv API: $e');
      return [];
    }
  }

  List<ArxivPaper> _parseArxivXml(String xml) {
    final papers = <ArxivPaper>[];
    // Simple XML parsing (kein xml-package nötig für diese Struktur)
    final entryRegex = RegExp(r'<entry>(.*?)</entry>', dotAll: true);
    final matches = entryRegex.allMatches(xml);

    for (final match in matches) {
      final entry = match.group(1) ?? '';
      final id = _extractXml(entry, 'id')?.replaceAll('http://arxiv.org/abs/', '') ?? '';
      final title = _extractXml(entry, 'title')?.trim() ?? '';
      final summary = _extractXml(entry, 'summary')?.trim() ?? '';
      final published = _extractXml(entry, 'published') ?? '';

      final authorMatches = RegExp(r'<name>(.*?)</name>').allMatches(entry);
      final authors = authorMatches.map((m) => m.group(1) ?? '').toList();

      if (id.isNotEmpty && title.isNotEmpty) {
        papers.add(ArxivPaper(
          id: id,
          title: title,
          summary: summary.length > 300 ? '${summary.substring(0, 300)}...' : summary,
          authors: authors,
          published: published,
          url: 'https://arxiv.org/abs/$id',
          pdfUrl: 'https://arxiv.org/pdf/$id',
        ));
      }
    }
    return papers;
  }

  String? _extractXml(String xml, String tag) {
    final match = RegExp('<$tag[^>]*>(.*?)</$tag>', dotAll: true).firstMatch(xml);
    return match?.group(1)?.trim();
  }

  // ─────────────────────────────────────────────
  // 5. INTERNET ARCHIVE (Wayback Machine)
  // ─────────────────────────────────────────────

  Future<WaybackResult?> getWaybackMachineUrl(String url) async {
    try {
      final apiUrl = Uri.parse(
        'https://archive.org/wayback/available?url=${Uri.encodeComponent(url)}',
      );
      final response = await http.get(apiUrl, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WaybackResult.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wayback Machine: $e');
      return null;
    }
  }

  /// Internet Archive Volltext-Suche
  Future<List<ArchiveSearchResult>> searchInternetArchive(String query, {int rows = 10}) async {
    try {
      final url = Uri.parse(
        'https://archive.org/advancedsearch.php'
        '?q=${Uri.encodeComponent(query)}'
        '&fl=identifier,title,description,date,mediatype'
        '&rows=$rows&page=1&output=json',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = data['response']?['docs'] as List? ?? [];
        return docs.map((d) => ArchiveSearchResult.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Archive.org: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 6. WIKIDATA API
  // Strukturierte Fakten, kein Key
  // ─────────────────────────────────────────────

  Future<WikidataEntity?> getWikidataEntity(String searchQuery) async {
    try {
      // Erst Entity-ID suchen
      final searchUrl = Uri.parse(
        'https://www.wikidata.org/w/api.php'
        '?action=wbsearchentities&search=${Uri.encodeComponent(searchQuery)}'
        '&language=de&format=json&limit=1',
      );
      final searchResp = await http.get(searchUrl, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (searchResp.statusCode != 200) return null;
      final searchData = jsonDecode(searchResp.body);
      final searchResults = searchData['search'] as List? ?? [];
      if (searchResults.isEmpty) return null;

      final entityId = searchResults[0]['id'] as String;

      // Dann Entity laden
      final entityUrl = Uri.parse(
        'https://www.wikidata.org/w/api.php'
        '?action=wbgetentities&ids=$entityId&format=json'
        '&languages=de|en&props=labels|descriptions|sitelinks',
      );
      final entityResp = await http.get(entityUrl, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (entityResp.statusCode != 200) return null;
      final entityData = jsonDecode(entityResp.body);
      final entity = entityData['entities']?[entityId];
      if (entity == null) return null;

      return WikidataEntity.fromJson(entityId, entity);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Wikidata: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 7. CROSSREF API
  // DOI-Metadaten und Literatursuche
  // ─────────────────────────────────────────────

  Future<List<CrossRefWork>> searchCrossRef(String query, {int rows = 10}) async {
    try {
      final url = Uri.parse(
        'https://api.crossref.org/works'
        '?query=${Uri.encodeComponent(query)}'
        '&rows=$rows'
        '&sort=relevance'
        '&select=DOI,title,author,published,type,container-title,abstract',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['message']?['items'] as List? ?? [];
        return items.map((i) => CrossRefWork.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ CrossRef: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // 8. OPEN LIBRARY API
  // ─────────────────────────────────────────────

  Future<List<OpenLibraryBook>> searchOpenLibrary(String query, {int limit = 10}) async {
    try {
      final url = Uri.parse(
        'https://openlibrary.org/search.json'
        '?q=${Uri.encodeComponent(query)}'
        '&limit=$limit'
        '&fields=key,title,author_name,first_publish_year,subject,language',
      );
      final response = await http.get(url, headers: {'User-Agent': _userAgent}).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = data['docs'] as List? ?? [];
        return docs.map((d) => OpenLibraryBook.fromJson(d)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ OpenLibrary: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // KOMBINIERTE UNIVERSAL-SUCHE
  // Alle APIs parallel abfragen
  // ─────────────────────────────────────────────

  Future<UniversalResearchResult> universalSearch(
    String query, {
    bool includeScientific = true,
    bool includeBooks = false,
    bool includeArchive = false,
  }) async {
    final futures = <String, Future>{
      'wikipedia': searchWikipedia(query, limit: 5),
      'duckduckgo': getDuckDuckGoInstant(query),
      'wikidata': getWikidataEntity(query),
    };

    if (includeScientific) {
      futures['arxiv'] = searchArxiv(query, maxResults: 5);
      futures['openalex'] = searchOpenAlex(query, limit: 5);
    }
    if (includeBooks) {
      futures['books'] = searchOpenLibrary(query, limit: 5);
    }
    if (includeArchive) {
      futures['archive'] = searchInternetArchive(query, rows: 5);
    }

    final results = await Future.wait(futures.values);
    final keys = futures.keys.toList();
    final resultMap = <String, dynamic>{};
    for (var i = 0; i < keys.length; i++) {
      resultMap[keys[i]] = results[i];
    }

    return UniversalResearchResult(
      query: query,
      wikipediaResults: resultMap['wikipedia'] as List<WikipediaSearchResult>? ?? [],
      duckDuckGo: resultMap['duckduckgo'] as DuckDuckGoResult?,
      wikidataEntity: resultMap['wikidata'] as WikidataEntity?,
      arxivPapers: resultMap['arxiv'] as List<ArxivPaper>? ?? [],
      openAlexWorks: resultMap['openalex'] as List<OpenAlexWork>? ?? [],
      books: resultMap['books'] as List<OpenLibraryBook>? ?? [],
      archiveResults: resultMap['archive'] as List<ArchiveSearchResult>? ?? [],
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class WikipediaSummary {
  final String title;
  final String extract;
  final String? thumbnail;
  final String url;

  const WikipediaSummary({
    required this.title,
    required this.extract,
    this.thumbnail,
    required this.url,
  });

  factory WikipediaSummary.fromJson(Map<String, dynamic> json) {
    return WikipediaSummary(
      title: json['title'] as String? ?? '',
      extract: json['extract'] as String? ?? '',
      thumbnail: (json['thumbnail'] as Map<String, dynamic>?)?['source'] as String?,
      url: (json['content_urls'] as Map<String, dynamic>?)?['mobile']?['page'] as String?
          ?? 'https://de.wikipedia.org/wiki/${json['title']}',
    );
  }
}

class WikipediaSearchResult {
  final String title;
  final String snippet;
  final int pageid;

  const WikipediaSearchResult({
    required this.title,
    required this.snippet,
    required this.pageid,
  });

  factory WikipediaSearchResult.fromJson(Map<String, dynamic> json) {
    // Strip HTML tags from snippet
    final rawSnippet = json['snippet'] as String? ?? '';
    final cleanSnippet = rawSnippet.replaceAll(RegExp(r'<[^>]*>'), '');
    return WikipediaSearchResult(
      title: json['title'] as String? ?? '',
      snippet: cleanSnippet,
      pageid: json['pageid'] as int? ?? 0,
    );
  }

  String get url => 'https://de.wikipedia.org/?curid=$pageid';
}

class DuckDuckGoResult {
  final String heading;
  final String abstractText;
  final String abstractSource;
  final String abstractUrl;
  final List<DuckDuckGoRelated> relatedTopics;

  const DuckDuckGoResult({
    required this.heading,
    required this.abstractText,
    required this.abstractSource,
    required this.abstractUrl,
    required this.relatedTopics,
  });

  factory DuckDuckGoResult.fromJson(Map<String, dynamic> json) {
    final related = (json['RelatedTopics'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((t) => t['Text'] != null && (t['Text'] as String).isNotEmpty)
        .take(5)
        .map((t) => DuckDuckGoRelated(
              text: t['Text'] as String? ?? '',
              url: t['FirstURL'] as String? ?? '',
            ))
        .toList();

    return DuckDuckGoResult(
      heading: json['Heading'] as String? ?? '',
      abstractText: json['AbstractText'] as String? ?? '',
      abstractSource: json['AbstractSource'] as String? ?? '',
      abstractUrl: json['AbstractURL'] as String? ?? '',
      relatedTopics: related,
    );
  }

  bool get hasContent => abstractText.isNotEmpty || heading.isNotEmpty;
}

class DuckDuckGoRelated {
  final String text;
  final String url;
  const DuckDuckGoRelated({required this.text, required this.url});
}

class OpenAlexWork {
  final String id;
  final String title;
  final int? year;
  final String? doi;
  final int citedByCount;
  final bool isOpenAccess;
  final String? pdfUrl;

  const OpenAlexWork({
    required this.id,
    required this.title,
    this.year,
    this.doi,
    required this.citedByCount,
    required this.isOpenAccess,
    this.pdfUrl,
  });

  factory OpenAlexWork.fromJson(Map<String, dynamic> json) {
    final oa = json['open_access'] as Map<String, dynamic>?;
    return OpenAlexWork(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unbekannter Titel',
      year: json['publication_year'] as int?,
      doi: json['doi'] as String?,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      isOpenAccess: oa?['is_oa'] as bool? ?? false,
      pdfUrl: oa?['oa_url'] as String?,
    );
  }

  String get displayUrl => doi != null ? 'https://doi.org/$doi' : id;
}

class ArxivPaper {
  final String id;
  final String title;
  final String summary;
  final List<String> authors;
  final String published;
  final String url;
  final String pdfUrl;

  const ArxivPaper({
    required this.id,
    required this.title,
    required this.summary,
    required this.authors,
    required this.published,
    required this.url,
    required this.pdfUrl,
  });

  String get authorsDisplay => authors.take(3).join(', ') + (authors.length > 3 ? ' et al.' : '');
  String get yearDisplay => published.length >= 4 ? published.substring(0, 4) : published;
}

class WaybackResult {
  final bool available;
  final String? url;
  final String? timestamp;

  const WaybackResult({required this.available, this.url, this.timestamp});

  factory WaybackResult.fromJson(Map<String, dynamic> json) {
    final snapshot = json['archived_snapshots']?['closest'] as Map<String, dynamic>?;
    return WaybackResult(
      available: snapshot?['available'] as bool? ?? false,
      url: snapshot?['url'] as String?,
      timestamp: snapshot?['timestamp'] as String?,
    );
  }
}

class ArchiveSearchResult {
  final String identifier;
  final String title;
  final String? description;
  final String? date;
  final String mediatype;

  const ArchiveSearchResult({
    required this.identifier,
    required this.title,
    this.description,
    this.date,
    required this.mediatype,
  });

  factory ArchiveSearchResult.fromJson(Map<String, dynamic> json) {
    return ArchiveSearchResult(
      identifier: json['identifier'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      date: json['date'] as String?,
      mediatype: json['mediatype'] as String? ?? 'texts',
    );
  }

  String get url => 'https://archive.org/details/$identifier';
}

class WikidataEntity {
  final String id;
  final String? labelDe;
  final String? labelEn;
  final String? descriptionDe;
  final String? descriptionEn;
  final String? wikipediaUrl;

  const WikidataEntity({
    required this.id,
    this.labelDe,
    this.labelEn,
    this.descriptionDe,
    this.descriptionEn,
    this.wikipediaUrl,
  });

  factory WikidataEntity.fromJson(String id, Map<String, dynamic> json) {
    final labels = json['labels'] as Map<String, dynamic>? ?? {};
    final descs = json['descriptions'] as Map<String, dynamic>? ?? {};
    final sitelinks = json['sitelinks'] as Map<String, dynamic>? ?? {};
    final dewiki = sitelinks['dewiki'] as Map<String, dynamic>?;

    return WikidataEntity(
      id: id,
      labelDe: (labels['de'] as Map<String, dynamic>?)?['value'] as String?,
      labelEn: (labels['en'] as Map<String, dynamic>?)?['value'] as String?,
      descriptionDe: (descs['de'] as Map<String, dynamic>?)?['value'] as String?,
      descriptionEn: (descs['en'] as Map<String, dynamic>?)?['value'] as String?,
      wikipediaUrl: dewiki != null
          ? 'https://de.wikipedia.org/wiki/${dewiki['title']}'
          : null,
    );
  }

  String get displayLabel => labelDe ?? labelEn ?? id;
  String get displayDescription => descriptionDe ?? descriptionEn ?? '';
}

class CrossRefWork {
  final String? doi;
  final String title;
  final List<String> authors;
  final String? publishedYear;
  final String? journal;
  final String? abstract;

  const CrossRefWork({
    this.doi,
    required this.title,
    required this.authors,
    this.publishedYear,
    this.journal,
    this.abstract,
  });

  factory CrossRefWork.fromJson(Map<String, dynamic> json) {
    final titleList = json['title'] as List? ?? [];
    final authorList = json['author'] as List? ?? [];
    final published = json['published'] as Map<String, dynamic>?;
    final dateParts = published?['date-parts'] as List?;
    final journalList = json['container-title'] as List? ?? [];

    return CrossRefWork(
      doi: json['DOI'] as String?,
      title: titleList.isNotEmpty ? titleList[0] as String : 'Unbekannt',
      authors: authorList
          .take(3)
          .map((a) => '${(a as Map)['given'] ?? ''} ${a['family'] ?? ''}'.trim())
          .toList(),
      publishedYear: dateParts?.isNotEmpty == true && (dateParts![0] as List).isNotEmpty
          ? (dateParts[0] as List)[0].toString()
          : null,
      journal: journalList.isNotEmpty ? journalList[0] as String : null,
      abstract: json['abstract'] as String?,
    );
  }

  String get displayUrl => doi != null ? 'https://doi.org/$doi' : '';
}

class OpenLibraryBook {
  final String key;
  final String title;
  final List<String> authors;
  final int? firstPublishYear;
  final List<String> subjects;
  final List<String> languages;

  const OpenLibraryBook({
    required this.key,
    required this.title,
    required this.authors,
    this.firstPublishYear,
    required this.subjects,
    required this.languages,
  });

  factory OpenLibraryBook.fromJson(Map<String, dynamic> json) {
    return OpenLibraryBook(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: (json['author_name'] as List? ?? []).cast<String>().take(3).toList(),
      firstPublishYear: json['first_publish_year'] as int?,
      subjects: (json['subject'] as List? ?? []).cast<String>().take(5).toList(),
      languages: (json['language'] as List? ?? []).cast<String>().take(3).toList(),
    );
  }

  String get url => 'https://openlibrary.org${key.replaceAll('/works/', '/books/')}';
}

class UniversalResearchResult {
  final String query;
  final List<WikipediaSearchResult> wikipediaResults;
  final DuckDuckGoResult? duckDuckGo;
  final WikidataEntity? wikidataEntity;
  final List<ArxivPaper> arxivPapers;
  final List<OpenAlexWork> openAlexWorks;
  final List<OpenLibraryBook> books;
  final List<ArchiveSearchResult> archiveResults;

  const UniversalResearchResult({
    required this.query,
    required this.wikipediaResults,
    this.duckDuckGo,
    this.wikidataEntity,
    required this.arxivPapers,
    required this.openAlexWorks,
    required this.books,
    required this.archiveResults,
  });

  int get totalResults =>
      wikipediaResults.length +
      arxivPapers.length +
      openAlexWorks.length +
      books.length +
      archiveResults.length;

  bool get hasScientificContent => arxivPapers.isNotEmpty || openAlexWorks.isNotEmpty;
  bool get hasWikiContent => wikipediaResults.isNotEmpty || duckDuckGo?.hasContent == true;
}
