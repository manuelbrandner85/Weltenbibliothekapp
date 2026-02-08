import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/live_feed_entry.dart';
import '../models/deutsche_rss_quellen.dart';
import 'cors_proxy_service.dart';

/// 🇩🇪 RSS Parser Service - Deutsche Feeds mit PARALLELEM LADEN
/// Performance-Optimierung: Alle Feeds gleichzeitig laden statt sequenziell
class RSSParserService {
  final http.Client _client = http.Client();
  
  /// ⚡ PARALLELES LADEN - Alle Feeds gleichzeitig (5-10x schneller!)
  Future<List<LiveFeedEntry>> parseLimitedFeedsParallel(
    FeedWorld welt, {
    int maxSources = 3,
  }) async {
    final sources = welt == FeedWorld.materie 
        ? deutscheMaterieQuellen 
        : deutscheEnergieQuellen;
    
    // Nur erste maxSources Quellen
    final limitedSources = sources.take(maxSources).toList();
    
    if (kDebugMode) {
      debugPrint('⚡ PARALLEL-MODUS: Lade $maxSources Quellen gleichzeitig für ${welt.name}');
    }
    
    // 🚀 PARALLEL laden mit Future.wait statt sequenziell
    final startTime = DateTime.now();
    
    final List<Future<List<LiveFeedEntry>>> futures = limitedSources.map(
      (source) => parseFeed(source).catchError((e) {
        if (kDebugMode) {
          debugPrint('❌ Fehler bei ${source.name}: $e');
        }
        return <LiveFeedEntry>[];
      })
    ).toList();
    
    // Warte auf ALLE Feeds gleichzeitig
    final results = await Future.wait(futures);
    
    final duration = DateTime.now().difference(startTime);
    
    // Flatten und sortieren
    final allEntries = results.expand((list) => list).toList();
    allEntries.sort((a, b) => b.fetchTimestamp.compareTo(a.fetchTimestamp));
    
    if (kDebugMode) {
      debugPrint('⚡ PARALLEL-LADEN abgeschlossen:');
      debugPrint('   - ${allEntries.length} Feeds in ${duration.inMilliseconds}ms');
      debugPrint('   - Durchschnitt: ${duration.inMilliseconds ~/ maxSources}ms pro Quelle');
    }
    
    return allEntries;
  }
  
  /// Parst RSS Feed von URL (mit CORS-Proxy auf Web)
  Future<List<LiveFeedEntry>> parseFeed(DeutscheRSSQuelle source) async {
    try {
      // 🌐 PROFESSIONELL: Nutze CORS-Proxy auf Web
      final feedContent = await CORSProxyService.fetchFeed(source.rssUrl);
      
      if (feedContent.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Leerer Feed-Content für ${source.name}');
        }
        return [];
      }
      
      // ⚠️ XML-Parsing mit PROFESSIONELLER Fehlerbehandlung (Namespace-Probleme)
      xml.XmlDocument? document;
      try {
        document = xml.XmlDocument.parse(feedContent);
      } catch (e) {
        // CRITICAL FIX: Namespace-Fehler abfangen
        final errorMsg = e.toString();
        if (errorMsg.contains('_Namespace') || errorMsg.contains('Unsupported operation')) {
          if (kDebugMode) {
            debugPrint('⚠️ XML-Namespace-Fehler für ${source.name} - überspringe Feed');
          }
          return []; // Leeres Ergebnis statt Crash
        }
        if (kDebugMode) {
          debugPrint('❌ XML-Parse-Fehler für ${source.name}: $e');
        }
        return [];
      }
      
      final items = document.findAllElements('item');
      
      final List<LiveFeedEntry> entries = [];
      
      for (final item in items.take(5)) {
        try {
          final titleElement = item.findElements('title').firstOrNull;
          final descriptionElement = item.findElements('description').firstOrNull;
          final linkElement = item.findElements('link').firstOrNull;
          final pubDateElement = item.findElements('pubDate').firstOrNull;
          
          if (titleElement == null || linkElement == null) continue;
          
          final title = titleElement.innerText;
          final description = descriptionElement?.innerText ?? '';
          final link = linkElement.innerText;
          final pubDateStr = pubDateElement?.innerText;
          
          // 🇩🇪 Deutsche Quellen - keine Übersetzung nötig!
          final cleanTitle = _cleanText(title);
          final cleanDescription = _extractSummary(description, 250);
          
          DateTime publishDate = DateTime.now();
          if (pubDateStr != null && pubDateStr.isNotEmpty) {
            try {
              publishDate = DateTime.parse(pubDateStr);
            } catch (e) {
              // Fallback: versuche RFC 822 Format
              try {
                publishDate = _parseRFC822Date(pubDateStr);
              } catch (e2) {
                if (kDebugMode) {
                  debugPrint('Date parse failed: $pubDateStr');
                }
              }
            }
          }
          
          // Erstelle Feed-Entry basierend auf Welt
          if (source.welt == FeedWorld.materie) {
            entries.add(MaterieFeedEntry(
              feedId: 'rss_${source.name.replaceAll(' ', '_')}_${entries.length}',
              titel: cleanTitle, // 🇩🇪 Bereits deutsch!
              quelle: source.name, // 🇩🇪 Deutsche Quelle
              sourceUrl: link,
              quellentyp: source.typ,
              fetchTimestamp: DateTime.now(),
              lastChecked: DateTime.now(),
              updateType: _isNew(publishDate) ? UpdateType.neu : UpdateType.unveraendert,
              thema: source.thema, // 🇩🇪 Bereits deutsch!
              tiefeLevel: _calculateTiefeLevel(description),
              zusammenfassung: cleanDescription, // 🇩🇪 Bereits deutsch!
              zentraleFragestellung: _generateQuestion(cleanTitle),
              alternativeNarrative: [],
              historischerKontext: '',
              empfohleneVerknuepfungen: [],
            ));
          } else {
            entries.add(EnergieFeedEntry(
              feedId: 'rss_${source.name.replaceAll(' ', '_')}_${entries.length}',
              titel: cleanTitle, // 🇩🇪 Bereits deutsch!
              quelle: source.name, // 🇩🇪 Deutsche Quelle
              sourceUrl: link,
              quellentyp: source.typ,
              fetchTimestamp: DateTime.now(),
              lastChecked: DateTime.now(),
              updateType: _isNew(publishDate) ? UpdateType.neu : UpdateType.unveraendert,
              spiritThema: source.thema, // 🇩🇪 Bereits deutsch!
              symbolSchwerpunkte: _extractSymbols(cleanTitle, cleanDescription),
              numerischeBezuege: [],
              archetypen: _extractArchetypes(cleanTitle, cleanDescription),
              symbolischeEinordnung: cleanDescription, // 🇩🇪 Bereits deutsch!
              reflexionsfragen: [
                'Welche Bedeutung hat dieses Thema für meine spirituelle Entwicklung?',
                'Wie kann ich diese Erkenntnisse in mein Leben integrieren?',
              ],
              verknuepfungMitModulen: [],
            ));
          }
        } catch (itemError) {
          if (kDebugMode) {
            debugPrint('Error parsing item: $itemError');
          }
          continue;
        }
      }
      
      return entries;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RSS Parse Error for ${source.name}: $e');
      }
      return [];
    }
  }
  
  /// Parst alle Quellen einer Welt (für Hintergrund-Updates)
  Future<List<LiveFeedEntry>> parseAllFeeds(FeedWorld welt) async {
    final sources = welt == FeedWorld.materie 
        ? deutscheMaterieQuellen 
        : deutscheEnergieQuellen;
    final allEntries = <LiveFeedEntry>[];
    
    for (final source in sources) {
      final entries = await parseFeed(source);
      allEntries.addAll(entries);
    }
    
    // Sortiere nach Datum (neueste zuerst)
    allEntries.sort((a, b) => b.fetchTimestamp.compareTo(a.fetchTimestamp));
    
    return allEntries;
  }
  
  /// Parst RFC 822 Datum (z.B. "Mon, 30 Dec 2024 10:30:00 +0100")
  DateTime _parseRFC822Date(String dateStr) {
    // Einfacher Parser für gängige RSS-Datumsformate
    try {
      final parts = dateStr.split(' ');
      if (parts.length >= 4) {
        final day = int.tryParse(parts[1]) ?? 1;
        final month = _monthToNumber(parts[2]);
        final year = int.tryParse(parts[3]) ?? DateTime.now().year;
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Fallback
    }
    return DateTime.now();
  }
  
  int _monthToNumber(String month) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    return months[month] ?? 1;
  }
  
  /// Bereinigt Text von HTML
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
  
  /// Prüft ob Entry neu ist (letzte 7 Tage)
  bool _isNew(DateTime publishDate) {
    final now = DateTime.now();
    final difference = now.difference(publishDate);
    return difference.inDays <= 7;
  }
  
  /// Berechnet Tiefe-Level basierend auf Text-Länge
  int _calculateTiefeLevel(String text) {
    final cleanText = _cleanText(text);
    if (cleanText.length > 1000) return 5;
    if (cleanText.length > 700) return 4;
    if (cleanText.length > 400) return 3;
    if (cleanText.length > 200) return 2;
    return 1;
  }
  
  /// Extrahiert Zusammenfassung
  String _extractSummary(String html, int maxLength) {
    final text = _cleanText(html);
    
    if (text.length <= maxLength) return text;
    
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Generiert zentrale Fragestellung
  String _generateQuestion(String title) {
    return 'Was bedeutet "$title" für unser Verständnis der aktuellen Situation?';
  }
  
  /// Extrahiert Symbole aus Text
  List<String> _extractSymbols(String title, String description) {
    final symbols = <String>[];
    final text = '${_cleanText(title)} ${_cleanText(description)}'.toLowerCase();
    
    const symbolKeywords = {
      'kabbala': 'Kabbala',
      'baum': 'Lebensbaum',
      'sephiroth': 'Sephiroth',
      'symbol': 'Symbol',
      'geometrie': 'Geometrie',
      'mandala': 'Mandala',
      'chakra': 'Chakra',
      'meditation': 'Meditation',
      'yoga': 'Yoga',
      'spirituell': 'Spiritualität',
    };
    
    for (final entry in symbolKeywords.entries) {
      if (text.contains(entry.key)) {
        symbols.add(entry.value);
      }
    }
    
    return symbols.isEmpty ? ['Spiritualität'] : symbols.take(3).toList();
  }
  
  /// Extrahiert Archetypen
  List<String> _extractArchetypes(String title, String description) {
    final archetypes = <String>[];
    final text = '${_cleanText(title)} ${_cleanText(description)}'.toLowerCase();
    
    const archetypeKeywords = {
      'schatten': 'Schatten',
      'licht': 'Licht',
      'weise': 'Weiser',
      'seele': 'Seele',
      'geist': 'Geist',
      'herz': 'Herz',
    };
    
    for (final entry in archetypeKeywords.entries) {
      if (text.contains(entry.key)) {
        archetypes.add(entry.value);
      }
    }
    
    return archetypes.isEmpty ? ['Suchender'] : archetypes.take(3).toList();
  }
  
  void dispose() {
    _client.close();
  }
}
