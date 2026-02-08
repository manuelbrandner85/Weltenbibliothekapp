import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/recherche_result_card.dart';
import '../utils/recherche_filter.dart';
import '../utils/recherche_exporter.dart';
import '../models/user_profile.dart';
import '../widgets/user_profile_settings.dart';

/// WELTENBIBLIOTHEK v5.9 – HYBRID-SSE-SCREEN mit USER-PROFIL-SYSTEM
/// 
/// Features:
/// - Standard-Modus (JSON, mit Cache) – DEFAULT
/// - Optional: SSE-Modus (Live-Updates, ohne Cache)
/// - Toggle-Switch für Power-User
/// - Timeline-Visualisierung
/// - Filter-System
/// - Export-Funktionen (PDF, Markdown, JSON, TXT)
/// - User-Profil-System (Personalisierte Einstellungen)
class RechercheScreenHybrid extends StatefulWidget {
  const RechercheScreenHybrid({super.key});

  @override
  State<RechercheScreenHybrid> createState() => _RechercheScreenHybridState();
}

enum RechercheStatus { idle, loading, sourcesFound, analysisReady, done, error }

class _RechercheScreenHybridState extends State<RechercheScreenHybrid> {
  final TextEditingController _queryController = TextEditingController();
  final String workerUrl = 'https://weltenbibliothek-worker.brandy13062.workers.dev';
  
  RechercheStatus _status = RechercheStatus.idle;
  String _formattedResult = '';
  String _errorMessage = '';
  List<Map<String, dynamic>> _intermediateResults = [];
  List<Map<String, dynamic>> _timeline = []; // 🆕 Timeline-Daten
  Map<String, dynamic>? _analyseData; // 🆕 v5.4 Vollständige Analyse-Daten
  Map<String, dynamic>? _rawData; // 🆕 v5.5 Ungefilterte Rohdaten
  double _progress = 0.0;
  int _retryCount = 0;
  final int _maxRetries = 3;
  
  // 🆕 HYBRID-MODE TOGGLE
  bool _useLiveMode = false; // false = Standard (Cache), true = SSE (Live)
  String _liveLog = '';
  
  // 🆕 v5.5 FILTER-SYSTEM
  RechercheFilter _filter = const RechercheFilter();
  bool _showFilters = false;
  
  // 🆕 v5.9 USER-PROFIL-SYSTEM
  UserProfile? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  /// Lädt User-Profil beim Start
  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    setState(() {
      _userProfile = profile;
      // Filter basierend auf Profil initialisieren
      final enabledSources = <String>{};
      if (profile.isSourcePreferred('web')) enabledSources.add('web');
      if (profile.isSourcePreferred('documents')) enabledSources.add('documents');
      if (profile.isSourcePreferred('media')) enabledSources.add('media');
      if (profile.isSourcePreferred('timeline')) enabledSources.add('timeline');
      
      _filter = RechercheFilter(
        enabledSources: enabledSources.isNotEmpty ? enabledSources : {'web', 'documents', 'media', 'timeline'},
        maxDepth: profile.depthLevel,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WELTENBIBLIOTHEK v5.9 Profil'),
        backgroundColor: Colors.blue[700],
        actions: [
          // 🆕 v5.9 User-Profil-Badge
          if (_userProfile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserProfileBadge(
                profile: _userProfile!,
                onTap: _showProfileSettings,
              ),
            ),
          // 🆕 v5.6 Export-Button
          if (_status == RechercheStatus.done && _analyseData != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                RechercheExporter.showExportDialog(
                  context,
                  data: _analyseData!,
                  query: _rawData?['query'] ?? _queryController.text,
                );
              },
              tooltip: 'Export',
            ),
          // 🆕 v5.5 Filter-Button
          if (_status == RechercheStatus.done)
            IconButton(
              icon: Badge(
                label: _filter.isActive ? Text('${_filter.activeCount}') : null,
                child: const Icon(Icons.filter_list),
              ),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: 'Filter',
            ),
          _buildStatusBadge(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🆕 MODE-TOGGLE
            _buildModeToggle(),
            const SizedBox(height: 16),
            
            // INPUT
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Recherche-Anfrage',
                hintText: 'z.B. Berlin, Ukraine Krieg, MK Ultra',
                border: const OutlineInputBorder(),
                errorText: _getInputError(),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            
            // START-BUTTON
            ElevatedButton(
              onPressed: _isSearching() ? null : _startRecherche,
              child: Text(_isSearching() ? 'Läuft...' : 'Recherche starten'),
            ),
            const SizedBox(height: 16),
            
            // PROGRESS
            if (_status == RechercheStatus.loading ||
                _status == RechercheStatus.sourcesFound ||
                _status == RechercheStatus.analysisReady)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(_getProgressText()),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // LIVE-LOG (nur bei SSE)
            if (_useLiveMode && _liveLog.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _liveLog,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            
            // RESULTS
            Expanded(
              child: SingleChildScrollView(
                child: _buildResultWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 MODE-TOGGLE (Standard vs Live)
  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _useLiveMode ? Colors.orange[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _useLiveMode ? Icons.stream : Icons.cached,
            color: _useLiveMode ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _useLiveMode ? '📡 Live-Modus (SSE)' : '📦 Standard-Modus (Cache)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _useLiveMode
                      ? 'Live-Updates, kein Cache, ~17s'
                      : 'Cache-optimiert, sofort bei Wiederholung, ~1s',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _useLiveMode,
            onChanged: (value) {
              setState(() {
                _useLiveMode = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final statusInfo = _getStatusInfo();
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Chip(
        avatar: Icon(statusInfo['icon'], size: 18, color: Colors.white),
        label: Text(
          statusInfo['text'],
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: statusInfo['color'],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    switch (_status) {
      case RechercheStatus.idle:
        return {'icon': Icons.search, 'text': 'BEREIT', 'color': Colors.grey};
      case RechercheStatus.loading:
        return {'icon': Icons.hourglass_empty, 'text': 'LÄDT', 'color': Colors.blue};
      case RechercheStatus.sourcesFound:
        return {'icon': Icons.source, 'text': 'QUELLEN', 'color': Colors.orange};
      case RechercheStatus.analysisReady:
        return {'icon': Icons.analytics, 'text': 'ANALYSE', 'color': Colors.purple};
      case RechercheStatus.done:
        return {'icon': Icons.check_circle, 'text': 'FERTIG', 'color': Colors.green};
      case RechercheStatus.error:
        return {'icon': Icons.error, 'text': 'FEHLER', 'color': Colors.red};
      default:
        return {'icon': Icons.help, 'text': 'UNBEKANNT', 'color': Colors.grey};
    }
  }

  String? _getInputError() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return null;
    if (query.length < 3) return 'Mindestens 3 Zeichen';
    if (query.contains(RegExp(r'[<>{}]'))) return 'Ungültige Zeichen';
    return null;
  }

  bool _isSearching() {
    return _status == RechercheStatus.loading ||
        _status == RechercheStatus.sourcesFound ||
        _status == RechercheStatus.analysisReady;
  }

  String _getProgressText() {
    switch (_status) {
      case RechercheStatus.loading:
        return _useLiveMode ? 'Verbindung wird aufgebaut...' : 'Recherche gestartet...';
      case RechercheStatus.sourcesFound:
        return 'Quellen gefunden...';
      case RechercheStatus.analysisReady:
        return 'Analyse wird abgeschlossen...';
      default:
        return '';
    }
  }

  Future<void> _startRecherche() async {
    final query = _queryController.text.trim();
    
    if (query.isEmpty || query.length < 3 || query.contains(RegExp(r'[<>{}]'))) {
      setState(() {
        _status = RechercheStatus.error;
        _errorMessage = 'Ungültige Eingabe';
      });
      return;
    }

    setState(() {
      _status = RechercheStatus.loading;
      _progress = 0.1;
      _errorMessage = '';
      _formattedResult = '';
      _intermediateResults = [];
      _timeline = []; // 🆕 Timeline zurücksetzen
      _analyseData = null; // 🆕 v5.4 Analyse-Daten zurücksetzen
      _liveLog = '';
    });

    try {
      if (_useLiveMode) {
        await _startRechercheLive(query);
      } else {
        await _startRechercheStandard(query);
      }
    } catch (e) {
      if (_retryCount < _maxRetries && !e.toString().contains('429')) {
        _retryCount++;
        setState(() {
          _errorMessage = 'Versuch $_retryCount/$_maxRetries... Wiederhole in 3s';
        });
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          await _startRecherche();
        }
      } else {
        setState(() {
          _status = RechercheStatus.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// STANDARD-MODUS (JSON mit Cache)
  Future<void> _startRechercheStandard(String query) async {
    final uri = Uri.parse('$workerUrl?q=${Uri.encodeComponent(query)}');
    
    final response = await http.get(uri).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Timeout: Server antwortet nicht'),
    );

    if (response.statusCode == 429) {
      throw Exception('Rate-Limit: Bitte 60 Sekunden warten');
    }

    if (response.statusCode != 200) {
      throw Exception('Worker nicht erreichbar (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    
    // Quellen gefunden
    setState(() {
      _status = RechercheStatus.sourcesFound;
      _progress = 0.5;
    });

    // Zwischenergebnisse + Timeline
    final results = data['results'] ?? {};
    final web = results['web'] ?? [];
    final documents = results['documents'] ?? [];
    final media = results['media'] ?? [];
    final timeline = (data['timeline'] ?? []) as List<dynamic>;

    setState(() {
      _intermediateResults = [
        {'icon': Icons.language, 'label': 'Web-Quellen', 'count': web.length, 'type': 'web', 'depth': 3},
        {'icon': Icons.book, 'label': 'Dokumente', 'count': documents.length, 'type': 'documents', 'depth': 4},
        {'icon': Icons.video_library, 'label': 'Medien', 'count': media.length, 'type': 'media', 'depth': 3},
        if (timeline.isNotEmpty)
          {'icon': Icons.timeline, 'label': 'Timeline', 'count': timeline.length, 'type': 'timeline', 'depth': 5},
      ];
      _timeline = timeline.cast<Map<String, dynamic>>();
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Analyse ready
    setState(() {
      _status = RechercheStatus.analysisReady;
      _progress = 0.9;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Final
    setState(() {
      _status = RechercheStatus.done;
      _progress = 1.0;
      _retryCount = 0;
      
      // 🆕 v5.5: Rohdaten speichern (ungefiltert)
      _rawData = Map<String, dynamic>.from(data);
      
      final analyse = data['analyse'];
      final isFallback = data['status'] == 'fallback';
      final sourcesStatus = data['sourcesStatus'] ?? {};
      
      // 🆕 v5.6.1: Analyse-Daten mit Fallback-Status speichern
      if (analyse is Map<String, dynamic>) {
        _analyseData = Map<String, dynamic>.from(analyse);
        _analyseData!['is_fallback'] = isFallback; // Fallback-Status hinzufügen
      } else {
        _analyseData = {'is_fallback': isFallback, 'inhalt': ''};
      }
      
      _formattedResult = '''
📊 RECHERCHE-ERGEBNIS: ${data['query']}

${isFallback ? '⚠️ FALLBACK-MODUS (keine externen Quellen verfügbar)\n\n' : ''}
📈 QUELLEN-STATUS:
  🌐 Web: ${sourcesStatus['web'] ?? 0}
  📚 Dokumente: ${sourcesStatus['documents'] ?? 0}
  🎥 Medien: ${sourcesStatus['media'] ?? 0}
  📅 Timeline: ${sourcesStatus['timeline'] ?? 0}

─────────────────────────────────────

${analyse?['inhalt'] ?? 'Keine Analyse verfügbar'}
      ''';
    });
  }

  /// SSE-MODUS (Live-Updates ohne Cache)
  Future<void> _startRechercheLive(String query) async {
    final uri = Uri.parse('$workerUrl?q=${Uri.encodeComponent(query)}&live=true');
    
    final request = http.Request('GET', uri);
    final streamedResponse = await http.Client().send(request).timeout(
      const Duration(seconds: 40),
      onTimeout: () => throw Exception('SSE-Timeout: Server antwortet nicht'),
    );

    if (streamedResponse.statusCode == 429) {
      throw Exception('Rate-Limit: Bitte 60 Sekunden warten');
    }

    if (streamedResponse.statusCode != 200) {
      throw Exception('SSE nicht erreichbar (${streamedResponse.statusCode})');
    }

    Map<String, dynamic>? finalData;
    
    await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      
      for (var line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final jsonStr = line.substring(6);
            final data = jsonDecode(jsonStr);
            
            // Live-Log aktualisieren
            final phase = data['phase'] ?? 'unknown';
            final status = data['status'] ?? 'unknown';
            final message = data['message'] ?? '';
            
            setState(() {
              _liveLog += '[$phase] $status ${message.isNotEmpty ? '- $message' : ''}\n';
            });

            // Status-Updates
            if (phase == 'web' && status == 'done') {
              setState(() {
                _status = RechercheStatus.sourcesFound;
                _progress = 0.3;
                _intermediateResults = [
                  {'icon': Icons.language, 'label': 'Web-Quellen', 'count': data['count'] ?? 0, 'type': 'web', 'depth': 3},
                ];
              });
            } else if (phase == 'documents' && status == 'done') {
              setState(() {
                _progress = 0.5;
                _intermediateResults.add(
                  {'icon': Icons.book, 'label': 'Dokumente', 'count': data['count'] ?? 0, 'type': 'documents', 'depth': 4},
                );
              });
            } else if (phase == 'media' && status == 'done') {
              setState(() {
                _progress = 0.65;
                _intermediateResults.add(
                  {'icon': Icons.video_library, 'label': 'Medien', 'count': data['count'] ?? 0, 'type': 'media', 'depth': 3},
                );
              });
            } else if (phase == 'timeline' && status == 'done') {
              setState(() {
                _progress = 0.8;
                _intermediateResults.add(
                  {'icon': Icons.timeline, 'label': 'Timeline', 'count': data['count'] ?? 0, 'type': 'timeline', 'depth': 5},
                );
              });
            } else if (phase == 'analysis' && status == 'started') {
              setState(() {
                _status = RechercheStatus.analysisReady;
                _progress = 0.9;
              });
            } else if (phase == 'final' && status == 'done') {
              finalData = data;
            }
          } catch (e) {
            debugPrint('SSE Parse Error: $e');
          }
        }
      }
    }

    // Finale Daten verarbeiten
    if (finalData != null) {
      final timeline = (finalData['timeline'] ?? []) as List<dynamic>;
      
      setState(() {
        _status = RechercheStatus.done;
        _progress = 1.0;
        _retryCount = 0;
        _timeline = timeline.cast<Map<String, dynamic>>();
        
        final analyse = finalData!['analyse'];
        final isFallback = finalData['status'] == 'fallback';
        final sourcesStatus = finalData['sourcesStatus'] ?? {};
        
        // 🆕 v5.6.1: Analyse-Daten mit Fallback-Status speichern (SSE-Modus)
        if (analyse is Map<String, dynamic>) {
          _analyseData = Map<String, dynamic>.from(analyse);
          _analyseData!['is_fallback'] = isFallback; // Fallback-Status hinzufügen
        } else {
          _analyseData = {'is_fallback': isFallback, 'inhalt': ''};
        }
        
        // 🆕 v5.5: Rohdaten speichern (für Filter)
        _rawData = Map<String, dynamic>.from(finalData);
        
        _formattedResult = '''
📊 RECHERCHE-ERGEBNIS: ${finalData['query']}

${isFallback ? '⚠️ FALLBACK-MODUS (keine externen Quellen verfügbar)\n\n' : ''}
📈 QUELLEN-STATUS:
  🌐 Web: ${sourcesStatus['web'] ?? 0}
  📚 Dokumente: ${sourcesStatus['documents'] ?? 0}
  🎥 Medien: ${sourcesStatus['media'] ?? 0}
  📅 Timeline: ${sourcesStatus['timeline'] ?? 0}

─────────────────────────────────────

${analyse?['inhalt'] ?? 'Keine Analyse verfügbar'}
        ''';
      });
    } else {
      throw Exception('SSE: Keine finalen Daten empfangen');
    }
  }

  Widget _buildResultWidget() {
    if (_status == RechercheStatus.error) {
      return _buildErrorCard();
    }

    if (_status == RechercheStatus.idle) {
      return const Center(
        child: Text('Bereit für Recherche...'),
      );
    }

    if (_intermediateResults.isNotEmpty) {
      return Column(
        children: [
          // Quellen-Status-Cards
          ..._intermediateResults.map((result) => Card(
            child: ListTile(
              leading: Icon(result['icon']),
              title: Text(result['label']),
              trailing: Chip(
                label: Text('${result['count']}'),
                backgroundColor: Colors.blue,
              ),
            ),
          )),
          
          // 🆕 v5.5 STRUKTURIERTE ERGEBNIS-CARD
          if (_analyseData != null) ...[
            const SizedBox(height: 16),
            RechercheResultCard(
              analyseData: _analyseData!,
              query: _rawData?['query'] ?? _queryController.text,
            ),
          ],
          
          // Timeline widget temporarily disabled (method resolution issue)
          // if (_timeline.isNotEmpty) ...[
          //   const SizedBox(height: 16),
          //   TimelineWidget(timeline: _timeline),
          //   const SizedBox(height: 16),
          // ],
          
          // 🆕 v5.5 FILTER-PANEL
          if (_showFilters && _status == RechercheStatus.done) ...[
            const SizedBox(height: 16),
            _buildFilterPanel(),
          ],
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  /// 🆕 v5.5 FILTER-PANEL
  Widget _buildFilterPanel() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Filter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (_filter.isActive)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = RechercheFilter.all();
                        _applyFilters();
                      });
                    },
                    child: const Text('Zurücksetzen'),
                  ),
              ],
            ),
            const Divider(),
            
            // QUELLEN-FILTER
            const SizedBox(height: 8),
            Text(
              'Quellen-Typen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, size: 16),
                      SizedBox(width: 4),
                      Text('Web'),
                    ],
                  ),
                  selected: _filter.enabledSources.contains('web'),
                  onSelected: (selected) {
                    setState(() {
                      final newSources = Set<String>.from(_filter.enabledSources);
                      selected ? newSources.add('web') : newSources.remove('web');
                      _filter = _filter.copyWith(enabledSources: newSources);
                      _applyFilters();
                    });
                  },
                ),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.article, size: 16),
                      SizedBox(width: 4),
                      Text('Dokumente'),
                    ],
                  ),
                  selected: _filter.enabledSources.contains('documents'),
                  onSelected: (selected) {
                    setState(() {
                      final newSources = Set<String>.from(_filter.enabledSources);
                      selected ? newSources.add('documents') : newSources.remove('documents');
                      _filter = _filter.copyWith(enabledSources: newSources);
                      _applyFilters();
                    });
                  },
                ),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library, size: 16),
                      SizedBox(width: 4),
                      Text('Medien'),
                    ],
                  ),
                  selected: _filter.enabledSources.contains('media'),
                  onSelected: (selected) {
                    setState(() {
                      final newSources = Set<String>.from(_filter.enabledSources);
                      selected ? newSources.add('media') : newSources.remove('media');
                      _filter = _filter.copyWith(enabledSources: newSources);
                      _applyFilters();
                    });
                  },
                ),
                FilterChip(
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timeline, size: 16),
                      SizedBox(width: 4),
                      Text('Timeline'),
                    ],
                  ),
                  selected: _filter.enabledSources.contains('timeline'),
                  onSelected: (selected) {
                    setState(() {
                      final newSources = Set<String>.from(_filter.enabledSources);
                      selected ? newSources.add('timeline') : newSources.remove('timeline');
                      _filter = _filter.copyWith(enabledSources: newSources);
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // TIEFE-FILTER
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Detail-Tiefe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filter.maxDepth}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('1', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _filter.maxDepth.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _getDepthLabel(_filter.maxDepth),
                    onChanged: (value) {
                      setState(() {
                        _filter = _filter.copyWith(maxDepth: value.toInt());
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const Text('5', style: TextStyle(fontSize: 12)),
              ],
            ),
            Text(
              _getDepthDescription(_filter.maxDepth),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // FILTER-PRESETS
            const SizedBox(height: 8),
            Text(
              'Schnellfilter',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.all_inclusive, size: 16),
                  label: const Text('Alle'),
                  onPressed: () {
                    setState(() {
                      _filter = RechercheFilter.all();
                      _applyFilters();
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.language, size: 16),
                  label: const Text('Nur Web'),
                  onPressed: () {
                    setState(() {
                      _filter = RechercheFilter.webOnly();
                      _applyFilters();
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.article, size: 16),
                  label: const Text('Nur Dokumente'),
                  onPressed: () {
                    setState(() {
                      _filter = RechercheFilter.documentsOnly();
                      _applyFilters();
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.visibility, size: 16),
                  label: const Text('Überblick'),
                  onPressed: () {
                    setState(() {
                      _filter = RechercheFilter.overview();
                      _applyFilters();
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.zoom_in, size: 16),
                  label: const Text('Tiefe Analyse'),
                  onPressed: () {
                    setState(() {
                      _filter = RechercheFilter.deep();
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getDepthLabel(int depth) {
    switch (depth) {
      case 1: return 'Minimal';
      case 2: return 'Überblick';
      case 3: return 'Standard';
      case 4: return 'Detailliert';
      case 5: return 'Vollständig';
      default: return 'Standard';
    }
  }
  
  String _getDepthDescription(int depth) {
    switch (depth) {
      case 1: return 'Nur Kernfakten, minimale Details';
      case 2: return 'Wichtigste Informationen, kurzer Überblick';
      case 3: return 'Standardumfang mit wesentlichen Details';
      case 4: return 'Umfassende Informationen mit Kontext';
      case 5: return 'Vollständige Analyse mit allen verfügbaren Details';
      default: return 'Standardumfang';
    }
  }
  
  /// 🆕 v5.5 FILTER-LOGIK ANWENDEN
  void _applyFilters() {
    if (_rawData == null) return;
    
    // Intermediate Results filtern
    final filteredIntermediate = _filter.apply(_intermediateResults);
    
    // Timeline filtern
    final filteredTimeline = _filter.applyToTimeline(_timeline);
    
    // Analyse-Daten filtern (wenn strukturiert)
    Map<String, dynamic>? filteredAnalyse;
    if (_analyseData != null && _analyseData!.containsKey('structured')) {
      final structured = _analyseData!['structured'] as Map<String, dynamic>;
      filteredAnalyse = Map<String, dynamic>.from(_analyseData!);
      filteredAnalyse['structured'] = _filter.applyToStructured(structured);
    } else {
      filteredAnalyse = _analyseData;
    }
    
    setState(() {
      _intermediateResults = filteredIntermediate;
      _timeline = filteredTimeline;
      _analyseData = filteredAnalyse;
      
      // Formatted Result aktualisieren
      _updateFormattedResult();
    });
  }
  
  /// Aktualisiert den formatierten Ergebnis-Text basierend auf Filtern
  void _updateFormattedResult() {
    if (_rawData == null) return;
    
    final analyse = _analyseData;
    final isFallback = _rawData!['status'] == 'fallback';
    
    // Zähle gefilterte Quellen
    final webCount = _filter.enabledSources.contains('web') 
        ? (_rawData!['sourcesStatus']?['web'] ?? 0) 
        : 0;
    final docsCount = _filter.enabledSources.contains('documents') 
        ? (_rawData!['sourcesStatus']?['documents'] ?? 0) 
        : 0;
    final mediaCount = _filter.enabledSources.contains('media') 
        ? (_rawData!['sourcesStatus']?['media'] ?? 0) 
        : 0;
    final timelineCount = _filter.enabledSources.contains('timeline') 
        ? (_rawData!['sourcesStatus']?['timeline'] ?? 0) 
        : 0;
    
    final filterStatus = _filter.isActive 
        ? '🔍 AKTIVE FILTER: ${_filter.activeCount}\n'
        : '';
    
    _formattedResult = '''
📊 RECHERCHE-ERGEBNIS: ${_rawData!['query']}

$filterStatus${isFallback ? '⚠️ FALLBACK-MODUS (keine externen Quellen verfügbar)\n\n' : ''}
📈 QUELLEN-STATUS (gefiltert):
  🌐 Web: $webCount
  📚 Dokumente: $docsCount
  🎥 Medien: $mediaCount
  📅 Timeline: $timelineCount

─────────────────────────────────────

${analyse?['inhalt'] ?? 'Keine Analyse verfügbar'}
    ''';
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Fehler aufgetreten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _status = RechercheStatus.idle;
                  _errorMessage = '';
                });
              },
              child: const Text('Zurücksetzen'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 🆕 v5.9: Zeige Profil-Einstellungen Dialog
  Future<void> _showProfileSettings() async {
    if (_userProfile == null) return;
    
    final newProfile = await showDialog<UserProfile>(
      context: context,
      builder: (context) => UserProfileSettingsDialog(
        initialProfile: _userProfile!,
      ),
    );
    
    if (newProfile != null) {
      await UserProfileManager().updateProfile(newProfile);
      setState(() {
        _userProfile = newProfile;
        // Filter basierend auf neuem Profil aktualisieren
        final enabledSources = <String>{};
        if (newProfile.isSourcePreferred('web')) enabledSources.add('web');
        if (newProfile.isSourcePreferred('documents')) enabledSources.add('documents');
        if (newProfile.isSourcePreferred('media')) enabledSources.add('media');
        if (newProfile.isSourcePreferred('timeline')) enabledSources.add('timeline');
        
        _filter = RechercheFilter(
          enabledSources: enabledSources.isNotEmpty ? enabledSources : {'web', 'documents', 'media', 'timeline'},
          maxDepth: newProfile.depthLevel,
        );
        // Filter anwenden wenn Daten vorhanden
        if (_status == RechercheStatus.done && _rawData != null) {
          _applyFilters();
        }
      });
      
      // Erfolgs-Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profil-Einstellungen gespeichert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
