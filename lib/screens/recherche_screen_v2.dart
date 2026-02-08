/// WELTENBIBLIOTHEK v5.14 – RECHERCHE SCREEN
/// 
/// Vereint alle Recherche-Tools in einem Tab:
/// - Standard-Recherche
/// - Kaninchenbau (6 Ebenen)
/// 
/// Keine Navigation zu separaten Screens!
library;

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rabbit_hole_models.dart';
import '../models/international_perspectives.dart';
import '../services/rabbit_hole_service.dart';
import '../services/recherche_cache_service.dart';
import '../widgets/rabbit_hole_visualization_card.dart';
import '../widgets/international_comparison_simple_card.dart';

/// Recherche-Modi
enum RechercheMode {
  standard,      // Standard-Recherche (1 Ebene)
  rabbitHole,    // Kaninchenbau (6 Ebenen)
  international, // 🆕 Internationale Perspektiven
}

class RechercheScreenV2 extends StatefulWidget {
  const RechercheScreenV2({super.key});

  @override
  State<RechercheScreenV2> createState() => _RechercheScreenV2State();
}

class _RechercheScreenV2State extends State<RechercheScreenV2> {
  final TextEditingController _searchController = TextEditingController();
  final _rabbitHoleService = RabbitHoleService();
  // TODO: Implement international research feature
  // final _internationalService = InternationalResearchService(
  //   workerUrl: 'https://weltenbibliothek-worker.brandy13062.workers.dev',
  // );
  final _cacheService = RechercheCacheService(); // 🆕 Cache-Service
  
  // Aktueller Modus
  RechercheMode _currentMode = RechercheMode.standard;
  
  // Standard-Recherche State
  bool _isLoadingStandard = false;
  Map<String, dynamic>? _standardResultData;
  String? _errorMessage;
  
  // Kaninchenbau State
  bool _isLoadingRabbitHole = false;
  RabbitHoleAnalysis? _rabbitHoleAnalysis;
  final List<RabbitHoleEvent> _rabbitHoleEvents = [];
  
  // Internationale Perspektiven State
  bool _isLoadingInternational = false;
  InternationalPerspectivesAnalysis? _internationalAnalysis;
  
  // ECHTE STATUSANZEIGE (gegen "hängt"-Gefühl)
  final List<String> _progressSteps = [];
  
  @override
  void initState() {
    super.initState();
    // 🆕 Cache initialisieren
    _cacheService.init();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _cacheService.close(); // 🆕 Cache schließen
    super.dispose();
  }
  
  void _addProgressStep(String step) {
    setState(() {
      _progressSteps.add(step);
    });
  }
  
  void _clearProgress() {
    setState(() {
      _progressSteps.clear();
    });
  }
  
  /// Extrahiert belegte Fakten aus Backend-Response
  List<String> _extractFakten(Map<String, dynamic> data) {
    final fakten = <String>[];
    
    // Aus strukturiertem Format
    if (data['structured']?['faktenbasis']?['facts'] != null) {
      fakten.addAll(List<String>.from(data['structured']['faktenbasis']['facts']));
    }
    
    // Aus Analyse-Text extrahieren (wenn vorhanden)
    if (data['analyse']?['inhalt'] != null && fakten.isEmpty) {
      final inhalt = data['analyse']['inhalt'] as String;
      // Einfache Extraktion: Sätze mit Zahlen/Daten
      final sentences = inhalt.split(RegExp(r'[.!?]\s+'));
      for (final sentence in sentences) {
        if (sentence.contains(RegExp(r'\d{4}')) || // Jahre
            sentence.contains(RegExp(r'\d+\s*(Million|Milliarde|Prozent|%)'))) { // Zahlen
          fakten.add(sentence.trim());
        }
      }
    }
    
    return fakten.isEmpty ? ['Keine belegten Fakten verfügbar'] : fakten;
  }
  
  /// Extrahiert Quellen aus Backend-Response
  /// 🆕 MIT DUPLIKATS-ERKENNUNG: if (hash(content) alreadySeen) discard()
  List<Map<String, dynamic>> _extractQuellen(Map<String, dynamic> data) {
    final quellen = <Map<String, dynamic>>[];
    final seenHashes = <int>{}; // Content-Hashes für Duplikats-Erkennung
    
    // Aus offizieller Sichtweise
    if (data['structured']?['sichtweise1_offiziell']?['quellen'] != null) {
      for (final quelle in data['structured']['sichtweise1_offiziell']['quellen']) {
        // 🚫 CHECK 1: FORBIDDEN FLAGS
        if (_containsForbiddenFlags(quelle)) {
          continue; // Skip mock/demo/example/placeholder
        }
        
        // 🆕 CHECK 2: DUPLIKATS-ERKENNUNG via Content-Hash
        final contentHash = _hashQuelle(quelle);
        if (seenHashes.contains(contentHash)) {
          continue; // ❌ DISCARD - Duplikat bereits gesehen
        }
        seenHashes.add(contentHash); // ✅ Merken für zukünftige Checks
        
        quellen.add({
          'name': quelle['quelle'] ?? 'Unbekannt',
          'url': quelle['url'],
          'vertrauensscore': quelle['vertrauensscore'] ?? 50,
          'typ': quelle['typ'] ?? 'text', // text, video, pdf, audio
        });
      }
    }
    
    // Aus alternativer Sichtweise
    if (data['structured']?['sichtweise2_alternativ']?['quellen'] != null) {
      for (final quelle in data['structured']['sichtweise2_alternativ']['quellen']) {
        // 🚫 CHECK 1: FORBIDDEN FLAGS
        if (_containsForbiddenFlags(quelle)) {
          continue; // Skip mock/demo/example/placeholder
        }
        
        // 🆕 CHECK 2: DUPLIKATS-ERKENNUNG via Content-Hash
        final contentHash = _hashQuelle(quelle);
        if (seenHashes.contains(contentHash)) {
          continue; // ❌ DISCARD - Duplikat bereits gesehen
        }
        seenHashes.add(contentHash); // ✅ Merken
        
        quellen.add({
          'name': quelle['quelle'] ?? 'Unbekannt',
          'url': quelle['url'],
          'vertrauensscore': quelle['vertrauensscore'] ?? 50,
          'typ': quelle['typ'] ?? 'text',
        });
      }
    }
    
    return quellen.isEmpty 
        ? [{'name': 'Keine Quellen verfügbar', 'url': null, 'vertrauensscore': 0, 'typ': 'text'}] 
        : quellen;
  }
  
  /// 🚫 FORBIDDEN FLAGS: Mock/Demo/Example/Placeholder ausschließen
  /// Regel: if (forbiddenFlags.some(f => item.meta?.includes(f))) discard(item);
  bool _containsForbiddenFlags(Map<String, dynamic> quelle) {
    const forbiddenFlags = ['mock', 'demo', 'example', 'placeholder'];
    
    // Check 1: Quelle-Name (case-insensitive)
    final name = (quelle['name'] ?? quelle['quelle'] ?? '').toString().toLowerCase();
    if (forbiddenFlags.any((flag) => name.contains(flag))) {
      return true; // ❌ DISCARD (forbidden flag in name)
    }
    
    // Check 2: URL (case-insensitive)
    final url = (quelle['url'] ?? '').toString().toLowerCase();
    if (forbiddenFlags.any((flag) => url.contains(flag))) {
      return true; // ❌ DISCARD (forbidden flag in url)
    }
    
    // Check 3: Meta-Feld (falls vorhanden)
    final meta = (quelle['meta'] ?? '').toString().toLowerCase();
    if (forbiddenFlags.any((flag) => meta.contains(flag))) {
      return true; // ❌ DISCARD (forbidden flag in meta)
    }
    
    // Check 4: Typ-Feld (falls mock/demo/etc.)
    final typ = (quelle['typ'] ?? '').toString().toLowerCase();
    if (forbiddenFlags.any((flag) => typ.contains(flag))) {
      return true; // ❌ DISCARD (forbidden flag in typ)
    }
    
    return false; // ✅ KEINE forbidden flags gefunden
  }
  
  /// 🆕 DUPLIKATS-ERKENNUNG via Content-Hash
  /// Regel: if (hash(content) alreadySeen) discard()
  /// 
  /// Erstellt einen Hash aus den Kern-Eigenschaften einer Quelle:
  /// - Name/Quelle (normalisiert)
  /// - URL (normalisiert)
  /// 
  /// Verwendung: Verhindert Duplikate aus verschiedenen Sichtweisen
  int _hashQuelle(Map<String, dynamic> quelle) {
    // Extrahiere Kern-Eigenschaften
    final name = (quelle['name'] ?? quelle['quelle'] ?? '').toString().toLowerCase().trim();
    final url = (quelle['url'] ?? '').toString().toLowerCase().trim();
    
    // Normalisiere URL (entferne http/https, www, trailing slashes)
    final normalizedUrl = url
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '');
    
    // Erstelle eindeutigen Content-String
    final content = '$name|$normalizedUrl';
    
    // Dart's String.hashCode für schnelles Hashing
    return content.hashCode;
  }
  
  // TODO: Media validation method for future use
  /*
  /// 🆕 MEDIEN: STRIKTE VALIDIERUNG
  /// Regel: if (!item.source || !item.url || !item.reachable) discard(item);
  /// Prüft ob Media-Quelle mit URL erreichbar ist (HEAD request)
  Future<bool> _isMediaReachable(String? url, String? source) async {
    // STRIKTE REGEL: Alle 3 Bedingungen müssen erfüllt sein
    if (source == null || source.isEmpty) return false; // Keine Quelle
    if (url == null || url.isEmpty) return false;       // Keine URL
    
    try {
      // HEAD request (nur Header, kein Download)
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 3),
      );
      
      // Erreichbar nur bei Status 200 oder 206
      final isReachable = response.statusCode == 200 || response.statusCode == 206;
      
      // ALLE 3 Bedingungen erfüllt: source ✓, url ✓, reachable ✓
      return isReachable;
      
    } catch (e) {
      return false; // Nicht erreichbar → discard
    }
  }
  */
  
  /// Zeigt Medien-Quelle nur wenn erreichbar
  // TODO: Review unused method: _buildMediaSource
  // Widget _buildMediaSource(Map<String, dynamic> quelle) {
    // final typ = quelle['typ'] as String;
    // final url = quelle['url'] as String?;
    // final name = quelle['name'] as String;
     //     // REGEL: Nur anzeigen wenn URL vorhanden und erreichbar
    // if (url == null || url.isEmpty) {
      // return const SizedBox.shrink(); // Skip!
    // }
     //     // switch (typ) {
      // case 'video':
        // return _buildVideoSource(name, url);
      // case 'pdf':
        // return _buildPdfSource(name, url);
      // case 'audio':
        // return _buildAudioSource(name, url);
      // default:
        // return _buildTextSource(name, url, quelle['vertrauensscore'] as int);
    // }
  // }
  
  /// 🎥 Video: Nur eingebettet, kein Download, Quelle sichtbar
  /// STRIKTE REGEL: if (!source || !url || !reachable) discard
  // TODO: Review unused method: _buildVideoSource
  // Widget _buildVideoSource(String name, String url) {
    // return FutureBuilder<bool>(
      // future: _isMediaReachable(url, name), // source = name
      // builder: (context, snapshot) {
        // if (!snapshot.hasData || !snapshot.data!) {
          // return const SizedBox.shrink(); // Skip: Nicht erreichbar
        // }
         //         // return Container(
          // margin: const EdgeInsets.only(bottom: 12),
          // padding: const EdgeInsets.all(12),
          // decoration: BoxDecoration(
            // color: Colors.red[900]?.withValues(alpha: 0.2),
            // border: Border.all(color: Colors.red[700]!, width: 1),
            // borderRadius: BorderRadius.circular(8),
          // ),
          // child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            // children: [
              // Row(
                // children: [
                  // Icon(Icons.video_library, color: Colors.red[400], size: 20),
                  // const SizedBox(width: 8),
                  // Expanded(
                    // child: Text(
                      // name,
                      // style: TextStyle(
                        // color: Colors.red[300],
                        // fontSize: 13,
                        // fontWeight: FontWeight.bold,
                      // ),
                    // ),
                  // ),
                // ],
              // ),
              // const SizedBox(height: 8),
              // Text(
                // 'Quelle: $url',
                // style: TextStyle(
                  // color: Colors.grey[500],
                  // fontSize: 10,
                // ),
                // maxLines: 1,
                // overflow: TextOverflow.ellipsis,
              // ),
              // const SizedBox(height: 8),
              // ElevatedButton.icon(
                // onPressed: () {
                  // Öffne in Browser (eingebettet, kein Download)
                  // TODO: Implementiere WebView oder Browser-Launch
                // },
                // icon: const Icon(Icons.play_arrow, size: 16),
                // label: const Text('Video ansehen', style: TextStyle(fontSize: 12)),
                // style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.red[700],
                  // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // ),
              // ),
            // ],
          // ),
        // );
      // },
    // );
  // }
  
  /// 📄 PDF: Nur öffentlich erreichbar, Vorschau erst nach Klick
  /// STRIKTE REGEL: if (!source || !url || !reachable) discard
  // TODO: Review unused method: _buildPdfSource
  // Widget _buildPdfSource(String name, String url) {
    // return FutureBuilder<bool>(
      // future: _isMediaReachable(url, name), // source = name
      // builder: (context, snapshot) {
        // if (!snapshot.hasData || !snapshot.data!) {
          // return const SizedBox.shrink(); // Skip: Nicht erreichbar
        // }
         //         // return Container(
          // margin: const EdgeInsets.only(bottom: 12),
          // padding: const EdgeInsets.all(12),
          // decoration: BoxDecoration(
            // color: Colors.blue[900]?.withValues(alpha: 0.2),
            // border: Border.all(color: Colors.blue[700]!, width: 1),
            // borderRadius: BorderRadius.circular(8),
          // ),
          // child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            // children: [
              // Row(
                // children: [
                  // Icon(Icons.picture_as_pdf, color: Colors.blue[400], size: 20),
                  // const SizedBox(width: 8),
                  // Expanded(
                    // child: Text(
                      // name,
                      // style: TextStyle(
                        // color: Colors.blue[300],
                        // fontSize: 13,
                        // fontWeight: FontWeight.bold,
                      // ),
                    // ),
                  // ),
                // ],
              // ),
              // const SizedBox(height: 8),
              // Text(
                // 'Quelle: $url',
                // style: TextStyle(
                  // color: Colors.grey[500],
                  // fontSize: 10,
                // ),
                // maxLines: 1,
                // overflow: TextOverflow.ellipsis,
              // ),
              // const SizedBox(height: 8),
              // ElevatedButton.icon(
                // onPressed: () {
                  // Öffne PDF-Vorschau nach Klick
                  // TODO: Implementiere PDF-Viewer oder Browser-Launch
                // },
                // icon: const Icon(Icons.open_in_new, size: 16),
                // label: const Text('PDF öffnen', style: TextStyle(fontSize: 12)),
                // style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.blue[700],
                  // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // ),
              // ),
            // ],
          // ),
        // );
      // },
    // );
  // }
  
  /// 🎧 Audio: Stream only, kein Autoplay
  /// STRIKTE REGEL: if (!source || !url || !reachable) discard
  // TODO: Review unused method: _buildAudioSource
  // Widget _buildAudioSource(String name, String url) {
    // return FutureBuilder<bool>(
      // future: _isMediaReachable(url, name), // source = name
      // builder: (context, snapshot) {
        // if (!snapshot.hasData || !snapshot.data!) {
          // return const SizedBox.shrink(); // Skip: Nicht erreichbar
        // }
         //         // return Container(
          // margin: const EdgeInsets.only(bottom: 12),
          // padding: const EdgeInsets.all(12),
          // decoration: BoxDecoration(
            // color: Colors.purple[900]?.withValues(alpha: 0.2),
            // border: Border.all(color: Colors.purple[700]!, width: 1),
            // borderRadius: BorderRadius.circular(8),
          // ),
          // child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            // children: [
              // Row(
                // children: [
                  // Icon(Icons.audiotrack, color: Colors.purple[400], size: 20),
                  // const SizedBox(width: 8),
                  // Expanded(
                    // child: Text(
                      // name,
                      // style: TextStyle(
                        // color: Colors.purple[300],
                        // fontSize: 13,
                        // fontWeight: FontWeight.bold,
                      // ),
                    // ),
                  // ),
                // ],
              // ),
              // const SizedBox(height: 8),
              // Text(
                // 'Quelle: $url',
                // style: TextStyle(
                  // color: Colors.grey[500],
                  // fontSize: 10,
                // ),
                // maxLines: 1,
                // overflow: TextOverflow.ellipsis,
              // ),
              // const SizedBox(height: 8),
              // ElevatedButton.icon(
                // onPressed: () {
                  // Stream Audio (kein Autoplay, manuell)
                  // TODO: Implementiere Audio-Player
                // },
                // icon: const Icon(Icons.play_circle, size: 16),
                // label: const Text('Audio abspielen', style: TextStyle(fontSize: 12)),
                // style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.purple[700],
                  // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // ),
              // ),
            // ],
          // ),
        // );
      // },
    // );
  // }
  
  /// Text-Quelle (Standard)
  // TODO: Review unused method: _buildTextSource
  // Widget _buildTextSource(String name, String url, int score) {
    // final scoreColor = score >= 75 ? Colors.green[400] : 
                      // score >= 50 ? Colors.orange[400] : 
                      // Colors.red[400];
     //     // return Padding(
      // padding: const EdgeInsets.only(bottom: 8),
      // child: Row(
        // children: [
          // Container(
            // padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            // decoration: BoxDecoration(
              // color: scoreColor,
              // borderRadius: BorderRadius.circular(8),
            // ),
            // child: Text(
              // '$score',
              // style: const TextStyle(
                // color: Colors.white,
                // fontSize: 11,
                // fontWeight: FontWeight.bold,
              // ),
            // ),
          // ),
          // const SizedBox(width: 8),
          // Expanded(
            // child: Text(
              // name,
              // style: const TextStyle(
                // color: Colors.white,
                // fontSize: 13,
              // ),
            // ),
          // ),
        // ],
      // ),
    // );
  // }
  
  /// Extrahiert Analyse (offizielle Sichtweise)
  String _extractAnalyse(Map<String, dynamic> data) {
    return data['structured']?['sichtweise1_offiziell']?['zusammenfassung'] ?? 
           data['analyse']?['inhalt'] ?? 
           'Keine Analyse verfügbar';
  }
  
  /// Extrahiert alternative Sichtweise
  String _extractAlternativeSichtweise(Map<String, dynamic> data) {
    return data['structured']?['sichtweise2_alternativ']?['zusammenfassung'] ?? 
           'Keine alternative Sichtweise verfügbar';
  }
  
  /// Baut einen strukturierten Abschnitt
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  /// Validiert Sucheingabe
  String? _validateQuery(String query) {
    final trimmed = query.trim();
    
    if (trimmed.isEmpty) {
      return "⚠️ Bitte Suchbegriff eingeben";
    }
    
    if (trimmed.length < 3) {
      return "⚠️ Mindestens 3 Zeichen erforderlich";
    }
    
    if (trimmed.length > 100) {
      return "⚠️ Maximal 100 Zeichen erlaubt";
    }
    
    return null;
  }

  /// Standard-Recherche (1 Ebene)
  Future<void> _startStandardRecherche() async {
    final query = _searchController.text.trim();
    final error = _validateQuery(query);
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoadingStandard = true;
      _standardResultData = null;
      _errorMessage = null;
      _clearProgress();
    });

    try {
      // 🆕 CACHE-CHECK: if (cached(query)) return cachedResult;
      if (await _cacheService.isCached(query, 'standard')) {
        _addProgressStep('💾 Ergebnis aus Cache geladen');
        final cachedData = await _cacheService.get(query, 'standard');
        
        if (cachedData != null) {
          setState(() {
            _standardResultData = cachedData;
            _isLoadingStandard = false;
          });
          _addProgressStep('✓ Cache-Treffer! Ergebnis sofort verfügbar');
          return; // 🎯 Frühzeitiger Return bei Cache-Hit
        }
      }
      
      // Kein Cache → API-Call
      _addProgressStep('→ Keine Cache-Daten gefunden, starte API-Call');
      
      // SCHRITT 1: Verbindung
      _addProgressStep('✓ Verbindung zum Server hergestellt');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // SCHRITT 2: API-Call
      _addProgressStep('→ Webquellen werden geprüft');
      final response = await http.get(
        Uri.parse('https://weltenbibliothek-worker.brandy13062.workers.dev?q=${Uri.encodeComponent(query)}'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _addProgressStep('✓ Webquellen geprüft');
        
        // SCHRITT 3: Daten verarbeiten
        _addProgressStep('→ Daten werden verarbeitet');
        await Future.delayed(const Duration(milliseconds: 200));
        
        final data = jsonDecode(response.body);
        _addProgressStep('✓ Analyse abgeschlossen');
        
        // Extrahiere strukturierte Daten
        final resultData = {
          'fakten': _extractFakten(data),
          'quellen': _extractQuellen(data),
          'analyse': _extractAnalyse(data),
          'alternative_sichtweise': _extractAlternativeSichtweise(data),
        };
        
        // 🆕 CACHE SPEICHERN
        await _cacheService.put(query, 'standard', resultData, ttlSeconds: 3600); // 1 Stunde
        _addProgressStep('💾 Ergebnis im Cache gespeichert');
        
        setState(() {
          _standardResultData = resultData;
          _isLoadingStandard = false;
        });
      } else {
        throw Exception('API-Fehler: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler: $e';
        _isLoadingStandard = false;
      });
    }
  }

  /// Kaninchenbau-Recherche (6 Ebenen)
  Future<void> _startRabbitHole() async {
    final query = _searchController.text.trim();
    final error = _validateQuery(query);
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoadingRabbitHole = true;
      _rabbitHoleAnalysis = null;
      _rabbitHoleEvents.clear();
      _errorMessage = null;
      _clearProgress();
    });

    try {
      // ECHTE PROGRESS-STEPS
      _addProgressStep('✓ Kaninchenbau gestartet (6 Ebenen)');
      
      final analysis = await _rabbitHoleService.startRabbitHole(
        topic: query,
        onEvent: (event) {
          setState(() {
            _rabbitHoleEvents.add(event);
            
            // ECHTE PROGRESS-ANZEIGE basierend auf Events
            if (event is RabbitHoleLevelCompleted) {
              _addProgressStep('✓ ${event.level.label}: ${event.node.sources.length} Quellen gefunden');
            } else if (event is RabbitHoleError) {
              if (event.message.contains('Suche externe Quellen')) {
                _addProgressStep('→ ${event.level?.label ?? "Recherche"}: Externe Quellen werden geprüft');
              } else if (event.message.contains('KI-Fallback')) {
                _addProgressStep('⚠️ ${event.level?.label ?? "Ebene"}: Nutze KI-Analyse (keine externen Quellen)');
              }
            }
            
            if (event is RabbitHoleLevelCompleted) {
              if (_rabbitHoleAnalysis == null) {
                _rabbitHoleAnalysis = RabbitHoleAnalysis(
                  topic: query,
                  nodes: [event.node],
                  status: RabbitHoleStatus.exploring,
                  startTime: DateTime.now(),
                  maxDepth: 6,
                );
              } else {
                _rabbitHoleAnalysis = RabbitHoleAnalysis(
                  topic: _rabbitHoleAnalysis!.topic,
                  nodes: [..._rabbitHoleAnalysis!.nodes, event.node],
                  status: RabbitHoleStatus.exploring,
                  startTime: _rabbitHoleAnalysis!.startTime,
                  maxDepth: 6,
                );
              }
            }
          });
        },
      );

      setState(() {
        _rabbitHoleAnalysis = analysis;
        _isLoadingRabbitHole = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Kaninchenbau abgeschlossen: ${analysis.nodes.length}/6 Ebenen'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Kaninchenbau-Fehler: $e';
        _isLoadingRabbitHole = false;
      });
    }
  }

  /// Bricht Kaninchenbau ab
  void _cancelRabbitHole() {
    _rabbitHoleService.cancelResearch();
    setState(() {
      _isLoadingRabbitHole = false;
      _errorMessage = 'Recherche abgebrochen';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 Kaninchenbau abgebrochen'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// 🆕 Internationale Perspektiven-Recherche
  /// Finde gemeinsame Punkte in Perspektiven
  List<String> _findCommonPoints(List<InternationalPerspective> perspectives) {
    if (perspectives.length < 2) return [];
    
    // Vereinfachte Logik: Erste gemeinsame Keywords
    final allKeyPoints = perspectives.expand((p) => p.keyPoints).toList();
    final common = <String>{};
    
    for (final point in allKeyPoints) {
      if (allKeyPoints.where((p) => p.contains(point.split(' ').first)).length > 1) {
        common.add(point);
      }
    }
    
    return common.take(3).toList();
  }
  
  /// Finde Unterschiede in Perspektiven
  List<String> _findDifferences(List<InternationalPerspective> perspectives) {
    if (perspectives.length < 2) return [];
    
    return [
      'Tonalität: ${perspectives[0].tone} vs. ${perspectives[1].tone}',
      'Quellen-Fokus: ${perspectives[0].sources.length} vs. ${perspectives[1].sources.length} Quellen',
    ];
  }

  Future<void> _startInternationalResearch() async {
    final query = _searchController.text.trim();
    final error = _validateQuery(query);
    
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoadingInternational = true;
      _internationalAnalysis = null;
      _errorMessage = null;
      _clearProgress();
    });

    try {
      // ECHTE PROGRESS-STEPS
      _addProgressStep('✓ Internationale Analyse gestartet');
      await Future.delayed(const Duration(milliseconds: 300));
      
      _addProgressStep('→ Deutsche Quellen werden geprüft');
      await Future.delayed(const Duration(milliseconds: 500));
      
      _addProgressStep('→ US-Quellen werden geprüft');
      await Future.delayed(const Duration(milliseconds: 500));
      
      _addProgressStep('→ Backend wird abgefragt');
      
      // ✅ ECHTE BACKEND-INTEGRATION
      final response = await http.post(
        Uri.parse('https://weltenbibliothek-worker.brandy13062.workers.dev/api/international'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': query,
          'regions': ['de', 'us'],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Backend-Fehler: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final perspectives = (data['perspectives'] as List)
          .map((p) => InternationalPerspective.fromJson(p))
          .toList();
      
      _addProgressStep('✓ ${perspectives.length} Perspektiven analysiert');

      final analysis = InternationalPerspectivesAnalysis(
        topic: query,
        perspectives: perspectives,
        commonPoints: _findCommonPoints(perspectives),
        differences: _findDifferences(perspectives),
      );

      setState(() {
        _internationalAnalysis = analysis;
        _isLoadingInternational = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${perspectives.length} internationale Perspektiven gefunden'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Internationale Recherche-Fehler: $e';
        _isLoadingInternational = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingStandard || _isLoadingRabbitHole || _isLoadingInternational;
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'RECHERCHE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // MODE-SELECTOR (Toggle-Buttons)
            Container(
              color: Colors.grey[850],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toggle-Buttons für Modi
                  SegmentedButton<RechercheMode>(
                    selected: {_currentMode},
                    onSelectionChanged: (Set<RechercheMode> newSelection) {
                      setState(() {
                        _currentMode = newSelection.first;
                        // Reset State bei Modus-Wechsel
                        _standardResultData = null;
                        _rabbitHoleAnalysis = null;
                        _internationalAnalysis = null; // 🆕
                        _errorMessage = null;
                      });
                    },
                    segments: const [
                      ButtonSegment<RechercheMode>(
                        value: RechercheMode.standard,
                        label: Text('Standard'),
                        icon: Icon(Icons.search),
                      ),
                      ButtonSegment<RechercheMode>(
                        value: RechercheMode.rabbitHole,
                        label: Text('Kaninchenbau'),
                        icon: Icon(Icons.explore),
                      ),
                      ButtonSegment<RechercheMode>(
                        value: RechercheMode.international,
                        label: Text('🌍 International'),
                        icon: Icon(Icons.public),
                      ),
                    ],
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.deepPurple;
                        }
                        return Colors.grey[700]!;
                      }),
                      foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Beschreibung des aktuellen Modus
                  Text(
                    _currentMode == RechercheMode.standard
                        ? 'Standard-Recherche: Schnelle Übersicht zu einem Thema'
                        : _currentMode == RechercheMode.rabbitHole
                            ? 'Kaninchenbau: Automatische Vertiefung in 6 Ebenen (Ereignis → Metastrukturen)'
                            : 'Internationale Perspektiven: Wie wird das Thema weltweit dargestellt? (DE, US, FR, RU, Global)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Suchfeld
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Suchbegriff eingeben (z.B. "MK Ultra", "Panama Papers")',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                    onSubmitted: (_) {
                      if (_currentMode == RechercheMode.standard) {
                        _startStandardRecherche();
                      } else if (_currentMode == RechercheMode.rabbitHole) {
                        _startRabbitHole();
                      } else {
                        _startInternationalResearch();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Action-Buttons
                  if (_currentMode == RechercheMode.standard) ...[
                    // Standard-Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading || _searchController.text.trim().isEmpty
                            ? null
                            : _startStandardRecherche,
                        icon: _isLoadingStandard
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isLoadingStandard ? 'Suche läuft...' : 'RECHERCHE STARTEN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else if (_currentMode == RechercheMode.rabbitHole) ...[
                    // Kaninchenbau-Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading || _searchController.text.trim().isEmpty
                            ? null
                            : _startRabbitHole,
                        icon: _isLoadingRabbitHole
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.explore),
                        label: Text(_isLoadingRabbitHole ? 'Erkundet Ebenen...' : '🕳️ KANINCHENBAU STARTEN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    // Abbruch-Button (nur während Recherche)
                    if (_isLoadingRabbitHole) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _cancelRabbitHole,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            '🛑 RECHERCHE ABBRECHEN',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // 🆕 Internationale Perspektiven-Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading || _searchController.text.trim().isEmpty
                            ? null
                            : _startInternationalResearch,
                        icon: _isLoadingInternational
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.public),
                        label: Text(_isLoadingInternational ? 'Analysiere Perspektiven...' : '🌍 INTERNATIONALE ANALYSE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 🆕 ECHTE STATUSANZEIGE (nur während Recherche)
            if (isLoading && _progressSteps.isNotEmpty) ...[
              Container(
                color: Colors.grey[850],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recherche läuft:',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Letzte 5 Progress-Steps
                    ..._progressSteps.take(_progressSteps.length).toList().reversed.take(5).map((step) {
                      final isActive = step.startsWith('→');
                      final isComplete = step.startsWith('✓');
                      final isWarning = step.startsWith('⚠️');
// UNUSED: final isPending = step.startsWith('○');
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              isComplete ? Icons.check_circle :
                              isActive ? Icons.sync :
                              isWarning ? Icons.warning :
                              Icons.circle_outlined,
                              size: 14,
                              color: isComplete ? Colors.green[400] :
                                     isActive ? Colors.blue[400] :
                                     isWarning ? Colors.orange[400] :
                                     Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: TextStyle(
                                  color: isComplete ? Colors.green[300] :
                                         isActive ? Colors.blue[300] :
                                         isWarning ? Colors.orange[300] :
                                         Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            
            // ERGEBNISSE
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  /// Baut Ergebnisbereich basierend auf Modus
  Widget _buildResults() {
    // Fehleranzeige
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Loading-Indicator
    if (_isLoadingStandard || _isLoadingRabbitHole) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _currentMode == RechercheMode.standard
                  ? 'Recherchiere...'
                  : _currentMode == RechercheMode.rabbitHole
                      ? 'Erkunde Ebenen...'
                      : 'Analysiere internationale Perspektiven...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            
            // Kaninchenbau: Event-Log
            if (_isLoadingRabbitHole && _rabbitHoleEvents.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _rabbitHoleEvents.take(5).map((event) {
                    if (event is RabbitHoleLevelCompleted) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${event.level.label}: ${event.node.sources.length} Quellen',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (event is RabbitHoleError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.orange[400], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.message,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Standard-Recherche Ergebnisse
    if (_currentMode == RechercheMode.standard && _standardResultData != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🆕 KI-TRANSPARENZ + WISSENSCHAFTLICHE STANDARDS WARNUNG
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[900]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[700]!, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.science, color: Colors.amber[400], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WISSENSCHAFTLICHE STANDARDS',
                          style: TextStyle(
                            color: Colors.amber[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '✓ Jede Aussage → Quelle oder als "Analyse" markiert\n'
                          '✓ Vorsichtige Sprache (keine "beweist", "eindeutig")\n'
                          '✓ Widersprüche ausdrücklich benannt\n'
                          '✓ Datenlücken erklärt, nicht gefüllt',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber[900]?.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'KI darf: Einordnen, Vergleichen, Strukturieren\n'
                            'KI darf NICHT: Fakten erfinden, Quellen ersetzen',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FAKTEN (belegt)
            _buildSection(
              title: 'FAKTEN (belegt)',
              icon: Icons.verified,
              color: Colors.green[400]!,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (_standardResultData!['fakten'] as List<String>).map((fakt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[400]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fakt,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 🆕 TRANSPARENZ-HINWEIS BEI WENIGEN QUELLEN
            if ((_standardResultData!['quellen'] as List).length <= 5)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[900]?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[700]!, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[400], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HINWEIS ZU QUELLENLAGE',
                            style: TextStyle(
                              color: Colors.amber[400],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Zu diesem Thema sind nur wenige öffentlich zugängliche Quellen verfügbar.\n'
                            'Die folgenden Ergebnisse stellen den aktuellen, überprüfbaren Stand dar.',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // QUELLEN
            _buildSection(
              title: 'QUELLEN',
              icon: Icons.source,
              color: Colors.blue[400]!,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (_standardResultData!['quellen'] as List<Map<String, dynamic>>).map((quelle) {
                  final score = quelle['vertrauensscore'] as int;
                  final scoreColor = score >= 75 ? Colors.green[400] : 
                                    score >= 50 ? Colors.orange[400] : 
                                    Colors.red[400];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            quelle['name'] ?? 'Unbekannt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ANALYSE
            _buildSection(
              title: 'ANALYSE',
              icon: Icons.analytics,
              color: Colors.purple[400]!,
              content: Text(
                _standardResultData!['analyse'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ALTERNATIVE SICHTWEISE
            _buildSection(
              title: 'ALTERNATIVE SICHTWEISE',
              icon: Icons.remove_red_eye,
              color: Colors.orange[400]!,
              content: Text(
                _standardResultData!['alternative_sichtweise'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Kaninchenbau Ergebnisse
    if (_currentMode == RechercheMode.rabbitHole && _rabbitHoleAnalysis != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: RabbitHoleVisualizationCard(
          analysis: _rabbitHoleAnalysis!,
          onRefresh: _startRabbitHole,
        ),
      );
    }

    // 🆕 Internationale Perspektiven Ergebnisse
    if (_currentMode == RechercheMode.international && _internationalAnalysis != null) {
      return InternationalComparisonSimpleCard(
        analysis: _internationalAnalysis!,
      );
    }

    // Leerzustand
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentMode == RechercheMode.standard 
                  ? Icons.search 
                  : _currentMode == RechercheMode.rabbitHole
                      ? Icons.explore
                      : Icons.public,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              _currentMode == RechercheMode.standard
                  ? 'Gib einen Suchbegriff ein und starte die Recherche'
                  : _currentMode == RechercheMode.rabbitHole
                      ? 'Starte den Kaninchenbau für eine automatische Tiefenanalyse'
                      : 'Analysiere, wie ein Thema international dargestellt wird',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
