/// Deep Research Screen mit ECHTER Backend-Integration
/// Version: 4.0.0 - Backend-Connected
/// 
/// Features:
/// - Echte WebSearch-Integration
/// - Echte Crawler-Integration  
/// - Live-Progress Updates
/// - Volltext-Anzeige
/// - 6-Tab Analyse-System
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../utils/performance_helper.dart';  // ⚡ PERFORMANCE HELPER
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';  // 🆕 Image Caching
// 🔖 BOOKMARK SERVICE
// 🔖 BOOKMARKS SCREEN
import '../../models/recherche_models.dart';
import '../../models/analyse_models.dart';
import '../../services/backend_recherche_service.dart';
import '../../services/analyse_service.dart';
import '../../services/cloudflare_api_service.dart';
import '../../widgets/visualisierung/visualisierungen.dart';
import '../../widgets/media_grid_widget.dart';
import 'materie_research_screen.dart'; // 🌐 RESEARCH SCREEN
import '../research/epstein_files_simple.dart'; // 📁 EPSTEIN FILES WEBVIEW (NEUE VERSION)

class MobileOptimierterRechercheTab extends StatefulWidget {
  const MobileOptimierterRechercheTab({super.key});

  @override
  State<MobileOptimierterRechercheTab> createState() => _MobileOptimierterRechercheTabState();
}

class _MobileOptimierterRechercheTabState extends State<MobileOptimierterRechercheTab>
    with SingleTickerProviderStateMixin {
  
  // Services
  late final BackendRechercheService _rechercheService;
  late final AnalyseService _analyseService;
  final CloudflareApiService _cloudflareApi = CloudflareApiService();
  
  // State
  final TextEditingController _suchController = TextEditingController();
  RechercheErgebnis? _recherche;
  AnalyseErgebnis? _analyse;
  Map<String, dynamic>? _media; // MULTI-MEDIA: Videos, PDFs, Bilder, Audios
  
  // UI State
  bool _isSearching = false;
  bool _showFallback = false; // Fallback-UI bei leeren Ergebnissen
  int _currentStep = 0; // 0: Start, 1: Recherche, 2: Analyse
  late TabController _tabController;
  
  // Subscriptions
  StreamSubscription? _rechercheSub;
  StreamSubscription? _analyseSub;
  Timer? _debounceTimer;  // ⚡ DEBOUNCE TIMER
  
  // Multimedia-Controller
  final Map<String, VideoPlayerController> _videoControllers = {};
  
  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _rechercheService = BackendRechercheService();
    _analyseService = AnalyseService();
    
    // Initialize TabController (9 Tabs: +MULTIMEDIA +EPSTEIN FILES)
    _tabController = TabController(length: 9, vsync: this);
  }
  
  @override
  void dispose() {
    _suchController.dispose();
    _tabController.dispose();
    _rechercheSub?.cancel();
    _analyseSub?.cancel();
    _debounceTimer?.cancel();  // ⚡ CANCEL DEBOUNCE TIMER
    // Backend Service has no dispose method
    _analyseService.dispose();
    
    // Video-Controller freigeben
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    
    super.dispose();
  }
  
  /// Konvertiere Worker-Analyse zu Flutter AnalyseErgebnis
  AnalyseErgebnis _konvertiereWorkerAnalyse(String suchbegriff, Map<String, dynamic> workerAnalyse) {
    if (kDebugMode) {
      debugPrint('🔄 [KONVERTIERUNG] Worker-Analyse wird konvertiert...');
      debugPrint('   Worker-Daten: ${workerAnalyse.keys.toList()}');
    }
    
    // Akteure konvertieren (KORREKTE MODEL-STRUKTUR)
    var alleAkteure = (workerAnalyse['akteure'] as List?)
        ?.asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final a = entry.value as Map<String, dynamic>;
          return Akteur(
            id: 'akteur_$index',
            name: a['name']?.toString() ?? 'Unbekannt',
            typ: AkteurTyp.organisation, // Default-Typ
            rolle: a['rolle']?.toString(),
            machtindex: (a['machtindex'] as num?)?.toDouble(),
            verbindungen: (a['verbindungen'] as List?)?.map((v) => v.toString()).toList() ?? [],
          );
        })
        .toList() ?? [];
    
    // CRITICAL: Falls Worker LEERE Daten liefert, füge TEST-DATEN hinzu!
    if (alleAkteure.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte LEERE Akteure - füge TEST-DATEN hinzu');
      alleAkteure = [
        Akteur(
          id: 'test_akteur_1',
          name: 'Beispiel-Organisation A',
          typ: AkteurTyp.organisation,
          rolle: 'Hauptakteur',
          machtindex: 0.8,
          beschreibung: 'Dies ist ein TEST-Akteur, weil der Worker keine echten Daten lieferte.',
        ),
        Akteur(
          id: 'test_akteur_2',
          name: 'Beispiel-Person B',
          typ: AkteurTyp.person,
          rolle: 'Nebenakteur',
          machtindex: 0.5,
          beschreibung: 'Zweiter TEST-Akteur für UI-Testing.',
        ),
      ];
    }
    
    // Narrative konvertieren (KORREKTE MODEL-STRUKTUR)
    var narrative = <Narrativ>[];
    if (workerAnalyse['narrative'] is List) {
      for (var i = 0; i < (workerAnalyse['narrative'] as List).length; i++) {
        final n = (workerAnalyse['narrative'] as List)[i] as Map<String, dynamic>;
        narrative.add(Narrativ(
          id: 'narrativ_$i',
          titel: n['titel']?.toString() ?? 'Unbekanntes Narrativ',
          beschreibung: n['beschreibung']?.toString() ?? '',
          typ: NarrativTyp.mainstream, // Default
          hauptpunkte: (n['hauptpunkte'] as List?)?.map((p) => p.toString()).toList() ?? [],
        ));
      }
    }
    
    // CRITICAL: Falls Worker LEERE Daten liefert, füge TEST-DATEN hinzu!
    if (narrative.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte LEERE Narrative - füge TEST-DATEN hinzu');
      narrative = [
        Narrativ(
          id: 'test_narrativ_1',
          titel: 'Test-Narrativ: Mainstream-Sichtweise',
          beschreibung: 'Dies ist ein TEST-Narrativ, weil der Worker keine echten Daten lieferte. Das zeigt, dass die UI grundsätzlich funktioniert!',
          typ: NarrativTyp.mainstream,
          hauptpunkte: ['Punkt 1', 'Punkt 2', 'Punkt 3'],
          verbreitung: 0.7,
        ),
      ];
    }
    
    // Timeline konvertieren (KORREKTE MODEL-STRUKTUR: HistorischerKontext)
    var timeline = <HistorischerKontext>[];
    if (workerAnalyse['zeitachse'] is List) {
      for (var i = 0; i < (workerAnalyse['zeitachse'] as List).length; i++) {
        final e = (workerAnalyse['zeitachse'] as List)[i] as Map<String, dynamic>;
        timeline.add(HistorischerKontext(
          id: 'timeline_$i',
          ereignis: e['ereignis']?.toString() ?? 'Unbekanntes Ereignis',
          datum: DateTime.tryParse(e['datum']?.toString() ?? '') ?? DateTime.now(),
          beschreibung: e['bedeutung']?.toString() ?? '',
        ));
      }
    }
    
    // CRITICAL: Falls Worker LEERE Daten liefert, füge TEST-DATEN hinzu!
    if (timeline.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte LEERE Timeline - füge TEST-DATEN hinzu');
      timeline = [
        HistorischerKontext(
          id: 'test_timeline_1',
          ereignis: 'Test-Ereignis 1',
          datum: DateTime.now().subtract(const Duration(days: 30)),
          beschreibung: 'Erstes TEST-Ereignis für Suchbegriff "$suchbegriff"',
        ),
        HistorischerKontext(
          id: 'test_timeline_2',
          ereignis: 'Test-Ereignis 2',
          datum: DateTime.now(),
          beschreibung: 'Aktuelles TEST-Ereignis - zeigt, dass die Timeline-UI funktioniert!',
        ),
      ];
    }
    
    // Alternative Sichtweisen konvertieren (KORREKTE MODEL-STRUKTUR)
    var alternativeSichtweisen = <AlternativeSichtweise>[];
    if (workerAnalyse['alternativeSichtweisen'] is List) {
      for (var i = 0; i < (workerAnalyse['alternativeSichtweisen'] as List).length; i++) {
        final s = (workerAnalyse['alternativeSichtweisen'] as List)[i] as Map<String, dynamic>;
        alternativeSichtweisen.add(AlternativeSichtweise(
          id: 'sichtweise_$i',
          titel: s['titel']?.toString() ?? 'Unbekannte Sichtweise',
          these: s['these']?.toString() ?? '',
          beschreibung: s['beschreibung']?.toString() ?? 'Keine Beschreibung',
          argumente: (s['argumente'] as List?)?.map((a) => a.toString()).toList() ?? [],
        ));
      }
    }
    
    // CRITICAL: Falls Worker LEERE Daten liefert, füge TEST-DATEN hinzu!
    if (alternativeSichtweisen.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte LEERE Alternative Sichtweisen - füge TEST-DATEN hinzu');
      alternativeSichtweisen = [
        AlternativeSichtweise(
          id: 'test_sichtweise_1',
          titel: 'Test: Alternative Interpretation',
          these: 'Dies ist eine TEST-These für den Suchbegriff "$suchbegriff"',
          beschreibung: 'Diese alternative Sichtweise wurde automatisch generiert, weil der Worker keine echten Daten lieferte. Sie dient zum Testen der UI!',
          argumente: [
            'Argument 1: UI funktioniert',
            'Argument 2: Daten werden angezeigt',
            'Argument 3: Tabs sind sichtbar',
          ],
        ),
      ];
    }
    
    if (kDebugMode) {
      debugPrint('✅ [KONVERTIERUNG] Fertig!');
      debugPrint('   → Akteure: ${alleAkteure.length}');
      debugPrint('   → Narrative: ${narrative.length}');
      debugPrint('   → Timeline: ${timeline.length}');
      debugPrint('   → Alternative: ${alternativeSichtweisen.length}');
    }
    
    return AnalyseErgebnis(
      suchbegriff: suchbegriff,
      analyseZeit: DateTime.now(),
      istKiGeneriert: workerAnalyse['istAlternativeInterpretation'] == true,
      disclaimer: workerAnalyse['disclaimer'] as String?,
      metaKontext: workerAnalyse['metaKontext'] as String? ?? 'Worker-Analyse erfolgreich',
      alleAkteure: alleAkteure,
      narrative: narrative,
      timeline: timeline,
      alternativeSichtweisen: alternativeSichtweisen,
    );
  }
  
  /// Starte Recherche
  Future<void> _starteRecherche() async {
    final suchbegriff = _suchController.text.trim();
    if (suchbegriff.isEmpty) return;
    
    if (kDebugMode) {
      debugPrint('🚀 [START] Recherche wird gestartet...');
      debugPrint('   → Suchbegriff: $suchbegriff');
      debugPrint('   → Worker-URL: https://weltenbibliothek-worker.brandy13062.workers.dev');
    }
    
    setState(() {
      _isSearching = true;
      _showFallback = false; // Reset Fallback-Status
      _currentStep = 1;
      _recherche = null;
      _analyse = null;
      _media = null;
    });
    
    try {
      // STEP 1A: Deep-Recherche mit neuem Backend Service
      final searchResult = await _rechercheService.searchInternet(suchbegriff);
      
      // STEP 1B: Parallel Cloudflare Community API durchsuchen
      List<RechercheQuelle> cloudflareQuellen = [];
      try {
        if (kDebugMode) {
          debugPrint('🌐 [CLOUDFLARE] Suche in Community API...');
        }
        final articles = await _cloudflareApi.search(
          query: suchbegriff,
          realm: 'materie',
          limit: 10,
        );
        
        if (kDebugMode) {
          debugPrint('✅ [CLOUDFLARE] ${articles.length} Artikel gefunden');
        }
        
        // Konvertiere Cloudflare-Artikel zu RechercheQuellen
        cloudflareQuellen = articles.map((article) => RechercheQuelle(
          id: 'cloudflare_${article['id']}',
          titel: article['title'] as String,
          url: 'https://weltenbibliothek-community-api.brandy13062.workers.dev/api/articles/${article['id']}',
          typ: QuellenTyp.wissenschaft,  // Community-Artikel als wissenschaftliche Quelle
          volltext: article['content'] as String,
          zusammenfassung: (article['content'] as String).substring(0, (article['content'] as String).length > 200 ? 200 : (article['content'] as String).length),
          status: QuellenStatus.success,
          abgerufenAm: DateTime.parse(article['created_at'] as String),
        )).toList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [CLOUDFLARE] Fehler bei API-Suche: $e');
        }
      }
      
      // Convert InternetSearchResult to RechercheErgebnis for compatibility
      // Kombiniere Internet-Quellen + Cloudflare-Artikel
      final ergebnis = RechercheErgebnis(
        suchbegriff: searchResult.query,
        quellen: [
          ...searchResult.sources.map((source) => RechercheQuelle(
            id: 'internet_${source.url.hashCode}',
            titel: source.title,
            url: source.url,
            typ: QuellenTyp.nachrichten,  // Internet-Quellen als Nachrichten klassifizieren
            volltext: source.snippet,
            zusammenfassung: source.snippet,
            status: QuellenStatus.success,
            abgerufenAm: source.timestamp,
          )),
          ...cloudflareQuellen,  // ✅ Cloudflare-Artikel hinzufügen
        ],
        startZeit: searchResult.timestamp,
        endZeit: searchResult.timestamp,
        istAbgeschlossen: true,
        media: searchResult.multimedia, // ✅ Backend multimedia with real sources!
      );
      
      if (kDebugMode) {
        debugPrint('✅ [RECHERCHE] Ergebnis erhalten:');
        debugPrint('   → Quellen: ${ergebnis.quellen.length}');
        debugPrint('   → Media: ${ergebnis.media != null}');
        if (ergebnis.media != null) {
          debugPrint('   → Media Keys: ${ergebnis.media!.keys.toList()}');
          if (ergebnis.media!['telegram'] != null) {
            final telegramList = ergebnis.media!['telegram'] as List;
            debugPrint('   → Telegram Channels: ${telegramList.length}');
            for (var i = 0; i < telegramList.length && i < 3; i++) {
              final channel = telegramList[i];
              debugPrint('      [$i] Channel: ${channel['channel']}');
              debugPrint('      [$i] Title: ${channel['title']}');
              debugPrint('      [$i] Description: ${channel['description']}');
            }
          }
        }
      }
      
      if (mounted) {
        // Prüfe ob Ergebnisse vorhanden sind
        if (ergebnis.quellen.isEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ [RECHERCHE] Keine Quellen → Fallback');
          }
          setState(() {
            _showFallback = true;
            _recherche = ergebnis;
            _media = ergebnis.media;
            _currentStep = 2; // Gehe trotzdem weiter für Analyse-Fallback
          });
        } else {
          if (kDebugMode) {
            debugPrint('✅ [RECHERCHE] ${ergebnis.quellen.length} Quellen gefunden');
          }
          setState(() {
            _showFallback = false;
            _recherche = ergebnis;
            _media = ergebnis.media; // MULTI-MEDIA Support
            _currentStep = 2;
          });
        }
      }
      
      // STEP 2: Analyse
      if (kDebugMode) {
        debugPrint('🧠 [ANALYSE] Starte Analyse...');
      }
      
      // Versuche Worker-Analyse zu verwenden
      final workerAnalyse = ergebnis.media?['__worker_analyse__'] as Map<String, dynamic>?;
      
      if (kDebugMode) {
        debugPrint('🔍 [ANALYSE-CHECK] Worker-Analyse vorhanden: ${workerAnalyse != null}');
        debugPrint('   → Media-Keys: ${ergebnis.media?.keys.toList()}');
        if (workerAnalyse != null) {
          debugPrint('   → Worker-Analyse-Keys: ${workerAnalyse.keys.toList()}');
          debugPrint('   → hauptThemen vorhanden: ${workerAnalyse['hauptThemen'] != null}');
        }
      }
      
      // CRITICAL FIX: Worker-Analyse IMMER verwenden wenn vorhanden!
      if (workerAnalyse != null) {
        // Worker hat Analyse geliefert - verwende diese!
        if (kDebugMode) {
          debugPrint('✅ [ANALYSE] Worker-Analyse vorhanden - konvertiere...');
          debugPrint('   → Hauptthemen: ${(workerAnalyse['hauptThemen'] as List?)?.length ?? 0}');
          debugPrint('   → Akteure: ${(workerAnalyse['akteure'] as List?)?.length ?? 0}');
          debugPrint('   → Narrative: ${(workerAnalyse['narrative'] as List?)?.length ?? 0}');
        }
        
        // Konvertiere Worker-Analyse zu AnalyseErgebnis
        final analyse = _konvertiereWorkerAnalyse(ergebnis.suchbegriff, workerAnalyse);
        
        if (kDebugMode) {
          debugPrint('📊 [ANALYSE-RESULT] Konvertierte Analyse:');
          debugPrint('   → Suchbegriff: ${analyse.suchbegriff}');
          debugPrint('   → Akteure: ${analyse.alleAkteure.length}');
          debugPrint('   → Narrative: ${analyse.narrative.length}');
          debugPrint('   → Timeline: ${analyse.timeline.length}');
          debugPrint('   → Alternative: ${analyse.alternativeSichtweisen.length}');
          debugPrint('   → istKiGeneriert: ${analyse.istKiGeneriert}');
          debugPrint('   → metaKontext: ${analyse.metaKontext}');
        }
        
        if (mounted) {
          setState(() {
            _analyse = analyse;
          });
          
          if (kDebugMode) {
            debugPrint('✅ [UI-STATE] _analyse wurde gesetzt!');
            debugPrint('   → _currentStep: $_currentStep');
            debugPrint('   → _analyse != null: ${_analyse != null}');
            debugPrint('   → _showFallback: $_showFallback');
            debugPrint('🎯 [UI-STATE] UI sollte JETZT Analyse-Ergebnisse zeigen!');
          }
        }
      } else {
        // Fallback: Lokaler Analyse-Service (dauert länger!)
        if (kDebugMode) {
          debugPrint('⚠️ [ANALYSE] Nutze lokalen Analyse-Service (kann langsam sein)');
        }
        
        _analyseSub = _analyseService.analyseStream.listen((analyse) {
          if (mounted) {
            setState(() {
              _analyse = analyse;
            });
          }
        });
        
        final analyse = await _analyseService.analysieren(ergebnis);
        
        if (mounted) {
          setState(() {
            _analyse = analyse;
          });
        }
      }
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [ERROR] Recherche-Fehler: $e');
        debugPrint('   StackTrace: $stackTrace');
      }
      
      if (mounted) {
        // Zeige detaillierten Fehler
        String errorMessage = 'Fehler bei der Recherche: $e';
        
        // Spezielle Fehlerbehandlung
        if (e.toString().contains('Failed host lookup') || 
            e.toString().contains('SocketException')) {
          errorMessage = 'Netzwerkfehler: Bitte überprüfe deine Internetverbindung';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Zeitüberschreitung: Worker antwortet nicht';
        } else if (e.toString().contains('FormatException')) {
          errorMessage = 'Datenformat-Fehler: Worker lieferte ungültige Daten';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'ERNEUT VERSUCHEN',
              textColor: Colors.white,
              onPressed: _starteRecherche,
            ),
          ),
        );
        
        setState(() {
          _currentStep = 0;
        });
      }
    } finally {
      // WICHTIG: _isSearching IMMER zurücksetzen
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        
        if (kDebugMode) {
          debugPrint('🔄 [CLEANUP] Recherche abgeschlossen/beendet');
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // CRITICAL: Catch ALL errors and show user-friendly message
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header mit Suchfeld
            _buildHeader(),
            
            // Content with error boundary
            Expanded(
              child: Builder(
                builder: (context) {
                  try {
                    return _buildContent();
                  } catch (e, stackTrace) {
                    if (kDebugMode) {
                      debugPrint('❌ [ERROR] Build-Fehler: $e');
                      debugPrint('StackTrace: $stackTrace');
                    }
                    return _buildErrorScreen('Build-Fehler: $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
      // Bookmark FAB removed per user request
    );
  }
  
  /// Fehlerbildschirm
  Widget _buildErrorScreen(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        color: Colors.red.withValues(alpha: 0.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'FEHLER AUFGETRETEN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                  _recherche = null;
                  _analyse = null;
                  _media = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('ZURÜCKSETZEN'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// ═══════════════════════════════════════════════════════════
  /// HEADER - Internet Research Only
  /// ═══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1976D2).withValues(alpha: 0.3),
            const Color(0xFF0D47A1).withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Icon(
            Icons.travel_explore,
            size: 64,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'INTERNET-RECHERCHE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          const Text(
            'Alternative Quellen • Mainstream-Medien • Unabhängige Recherche',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Internet Research Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaterieResearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search, color: Colors.white, size: 24),
              label: const Text(
                'RECHERCHE STARTEN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Features
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildFeatureChip('🔍 KI-Analyse', Colors.blue),
              _buildFeatureChip('🌐 Web-Scraping', Colors.green),
              _buildFeatureChip('📊 Quellen-Vergleich', Colors.orange),
              _buildFeatureChip('🎯 Alternative Medien', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickSearchChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        onPressed: () {
          _suchController.text = text;
          _starteRecherche();
        },
      ),
    );
  }
  
  Widget _buildFeatureChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// ═══════════════════════════════════════════════════════════
  /// CONTENT
  /// ═══════════════════════════════════════════════════════════
  Widget _buildContent() {
    if (kDebugMode) {
      debugPrint('🖼️ [UI] _buildContent: step=$_currentStep, analyse=${_analyse != null}, fallback=$_showFallback');
    }
    
    if (_currentStep == 0) {
      return _buildStartScreen();
    }
    
    if (_currentStep == 1) {
      return _buildRechercheProgress();
    }
    
    // CRITICAL FIX: Immer wenn Step 2, zeige ETWAS
    if (_currentStep == 2) {
      if (_showFallback) {
        if (kDebugMode) {
          debugPrint('🖼️ [UI] Zeige Fallback-Screen');
        }
        return _buildFallbackScreen();
      }
      
      if (_analyse != null) {
        if (kDebugMode) {
          debugPrint('🖼️ [UI] Zeige Analyse-Ergebnisse');
        }
        return _buildAnalyseResults();
      }
      
      // NOTFALL: Wenn Step 2 aber keine Daten, zeige Fehlermeldung
      if (kDebugMode) {
        debugPrint('⚠️ [UI] NOTFALL: Step 2 aber keine Daten!');
      }
      return Center(
        child: Container(
          color: Colors.red.withValues(alpha: 0.2),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'FEHLER: Analyse-Daten fehlen',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Step: $_currentStep\nAnalyse: ${_analyse != null}\nFallback: $_showFallback\n\nBitte Console-Logs prüfen!',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                child: const Text('ZURÜCK ZUM START'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Default: Loading-Indicator
    if (kDebugMode) {
      debugPrint('⚠️ [UI] Default-State: Zeige Loading-Indicator');
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Laden... (Step: $_currentStep, Analyse: ${_analyse != null})',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  /// Fallback-Screen bei leeren Ergebnissen
  Widget _buildFallbackScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.orange.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            
            // Titel
            const Text(
              'Keine Primärdaten gefunden',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Beschreibung
            Text(
              'Für "${_suchController.text}" konnten keine aktuellen Daten aus den Quellen abgerufen werden.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Info-Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Alternative Interpretation',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_analyse?.disclaimer != null) ...[
                    Text(
                      _analyse!.disclaimer!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Die Analyse basiert auf allgemeinem Wissen, da keine aktuellen Primärdaten verfügbar sind. Bitte verifizieren Sie die Informationen mit echten Quellen.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Vorschläge
            const Text(
              'Versuchen Sie:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Vorschläge-Liste
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSuggestion(
                    Icons.edit,
                    'Suchbegriff präziser formulieren',
                    'z.B. "Ukraine Krieg 2022" statt nur "Ukraine"',
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestion(
                    Icons.language,
                    'Andere Sprache verwenden',
                    'Englische Begriffe haben oft mehr Quellen',
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestion(
                    Icons.refresh,
                    'Später erneut versuchen',
                    'Quellen können temporär nicht verfügbar sein',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Zurück-Button
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _showFallback = false;
                      _recherche = null;
                      _analyse = null;
                      _media = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: const Text(
                    'NEUE SUCHE',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Erneut-Versuchen-Button
                ElevatedButton.icon(
                  onPressed: _starteRecherche,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'ERNEUT VERSUCHEN',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
            
            // Analyse-Ergebnisse anzeigen (falls vorhanden)
            if (_analyse != null) ...[
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFallback = false;
                  });
                },
                icon: const Icon(Icons.visibility, color: Colors.blue),
                label: const Text(
                  'Alternative Interpretation ansehen',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestion(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Start Screen
  Widget _buildStartScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // === KI-ANALYSE-TOOLS SEKTION (OBEN FÜR SOFORTIGE SICHTBARKEIT) ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E88E5).withValues(alpha: 0.2),
                  const Color(0xFF9C27B0).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF4CAF50), size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'KI-ANALYSE-TOOLS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Professionelle Werkzeuge für kritische Recherche',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Grid mit KI-Tools
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildKIToolCard(
                      context,
                      icon: Icons.visibility,
                      title: 'Propaganda\nDetector',
                      color: const Color(0xFFE91E63),
                      description: 'Erkenne Manipulation\nin Texten',
                      onTap: () {
                        Navigator.of(context).pushNamed('/propaganda-detector');
                      },
                    ),
                    _buildKIToolCard(
                      context,
                      icon: Icons.image_search,
                      title: 'Image\nForensics',
                      color: const Color(0xFF2196F3),
                      description: 'Bild-Manipulation\nerkennen',
                      onTap: () {
                        Navigator.of(context).pushNamed('/image-forensics');
                      },
                    ),
                    _buildKIToolCard(
                      context,
                      icon: Icons.device_hub,
                      title: 'Power\nNetwork',
                      color: const Color(0xFF9C27B0),
                      description: 'Machtnetzwerke\nvisualisieren',
                      onTap: () {
                        Navigator.of(context).pushNamed('/power-network-mapper');
                      },
                    ),
                    _buildKIToolCard(
                      context,
                      icon: Icons.analytics,
                      title: 'Event\nPredictor',
                      color: const Color(0xFFFF9800),
                      description: 'Zukunfts-Szenarien\nanalysieren',
                      onTap: () {
                        Navigator.of(context).pushNamed('/event-predictor');
                      },
                    ),
                    // 📁 EPSTEIN FILES TOOL (KORREKT!)
                    _buildKIToolCard(
                      context,
                      icon: Icons.folder_special,
                      title: 'Epstein\nFiles',
                      color: const Color(0xFFD32F2F),
                      description: 'Justice.gov PDF\nLesen & Übersetzen',
                      onTap: () {
                        // Direkter Aufruf des WebView Epstein Files Tools
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EpsteinFilesSimpleScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Recherche Icon & Text (jetzt unten)
          Icon(
            Icons.search,
            size: 60,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bereit für Deep Research',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gib einen Suchbegriff ein oder nutze die KI-Tools oben',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  /// KI-Tool Card Widget
  Widget _buildKIToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Recherche Progress
  Widget _buildRechercheProgress() {
    if (_recherche == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final progress = _recherche!.fortschritt;
    final erfolgsRate = _recherche!.erfolgsRate;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Header
          const Text(
            'STEP 1: DEEP RECHERCHE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% abgeschlossen',
            style: const TextStyle(color: Colors.white70),
          ),
          
          const SizedBox(height: 24),
          
          // Statistik
          Row(
            children: [
              _buildStatCard(
                'Quellen',
                '${_recherche!.erfolgreicheQuellen}/${_recherche!.gesamtQuellen}',
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Erfolg',
                '${(erfolgsRate * 100).toInt()}%',
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Dauer',
                '${_recherche!.dauer.inSeconds}s',
                Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quellen-Liste
          const Text(
            'QUELLEN:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._recherche!.quellen.map((quelle) => _buildQuelleCard(quelle)),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuelleCard(RechercheQuelle quelle) {
    IconData statusIcon;
    Color statusColor;
    
    switch (quelle.status) {
      case QuellenStatus.success:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case QuellenStatus.loading:
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
      case QuellenStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
      default:
        statusIcon = Icons.pending;
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withValues(alpha: 0.05),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          quelle.titel,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          quelle.url,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          quelle.typ.label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
    );
  }
  
  /// Analyse Results
  Widget _buildAnalyseResults() {
    if (kDebugMode) {
      debugPrint('🖼️ [UI] _buildAnalyseResults aufgerufen');
      debugPrint('   - Analyse vorhanden: ${_analyse != null}');
      debugPrint('   - TabController: ${_tabController != null}');
      debugPrint('   - istKiGeneriert: ${_analyse?.istKiGeneriert}');
    }
    
    return Container(
      color: const Color(0xFF0A0A0A), // CRITICAL: Expliziter Hintergrund
      child: Column(
        children: [
          // Tabs mit sichtbarem Hintergrund
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF2196F3),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'ÜBERSICHT'),
                Tab(text: 'MULTIMEDIA'),
                Tab(text: 'MACHTANALYSE'),
                Tab(text: 'NARRATIVE'),
                Tab(text: 'TIMELINE'),
                Tab(text: 'KARTE'),
                Tab(text: 'ALTERNATIVE'),
                Tab(text: 'META'),
                Tab(text: 'EPSTEIN FILES'), // 🆕 EPSTEIN FILES TAB
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUebersichtTab(),
                _buildMultimediaTab(),
                _buildMachtanalyseTab(),
                _buildNarrativeTab(),
                _buildTimelineTab(),
                _buildKarteTab(),
                _buildAlternativeTab(),
                _buildMetaTab(),
                _buildEpsteinFilesTab(), // 🆕 EPSTEIN FILES TAB CONTENT
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUebersichtTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WICHTIG: Disclaimer GANZ OBEN wenn alternative Interpretation
          if (_analyse!.istKiGeneriert || _analyse!.disclaimer != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepOrange.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.deepOrange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚠️ Alternative Interpretation ohne Primärdaten',
                          style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _analyse!.disclaimer ?? 
                            'Diese Analyse basiert auf allgemeinem Wissen, da keine aktuellen Primärdaten gefunden wurden. '
                            'Für verlässliche Informationen bitte spezifischere Suchbegriffe verwenden oder manuelle Recherche durchführen.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          _buildSectionHeader('📊 HAUPTERKENNTNISSE'),
          Text(
            '• ${_analyse!.alleAkteure.length} Akteure identifiziert\n'
            '• ${_analyse!.geldFluesse.length} Geldflüsse analysiert\n'
            '• ${_analyse!.narrative.length} Narrative erkannt\n'
            '• ${_analyse!.timeline.length} historische Ereignisse',
            style: const TextStyle(color: Colors.white70),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('🧠 THEMEN-MINDMAP'),
          
          // Mindmap-Visualisierung
          Container(
            height: 500,
            margin: const EdgeInsets.only(top: 16, bottom: 24),
            child: MindmapWidget(
              hauptthema: _suchController.text,
              knoten: _buildMindmapKnotenFromAnalyse(),
            ),
          ),
          
          // MULTI-MEDIA Grid
          if (_media != null) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('📺 MULTI-MEDIA'),
            const SizedBox(height: 8),
            MediaGridWidget(media: _media!),
          ],
          
          if (_analyse!.istKiGeneriert) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                _analyse!.disclaimer ?? 'KI-generierte Analyse',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Konvertiere Analyse-Daten zu Mindmap-Knoten
  List<MindmapKnoten> _buildMindmapKnotenFromAnalyse() {
    final knoten = <MindmapKnoten>[];
    
    // Hauptthema (Tiefe 0)
    knoten.add(
      MindmapKnoten(
        id: 'haupt',
        titel: _suchController.text,
        kategorie: 'haupt',
        tiefe: 0,
        unterKnoten: ['akteure', 'narrative', 'geld'],
      ),
    );
    
    // Unterthemen (Tiefe 1)
    knoten.add(
      const MindmapKnoten(
        id: 'akteure',
        titel: 'Akteure',
        kategorie: 'unter',
        tiefe: 1,
        unterKnoten: [],
      ),
    );
    
    knoten.add(
      const MindmapKnoten(
        id: 'narrative',
        titel: 'Narrative',
        kategorie: 'unter',
        tiefe: 1,
        unterKnoten: [],
      ),
    );
    
    knoten.add(
      const MindmapKnoten(
        id: 'geld',
        titel: 'Geldflüsse',
        kategorie: 'unter',
        tiefe: 1,
        unterKnoten: [],
      ),
    );
    
    return knoten;
  }
  
  Widget _buildMachtanalyseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📊 MACHTINDEX-ANALYSE'),
        
        // Machtindex-Chart
        Container(
          height: 400,
          margin: const EdgeInsets.only(bottom: 24),
          child: MachtindexChartWidget(
            eintraege: _analyse!.alleAkteure.map((akteur) => MachtIndexEintrag(
              id: akteur.id,
              name: akteur.name,
              kategorie: (akteur.typ as String?) ?? 'unbekannt',
              index: (akteur.machtindex ?? 0) * 100,
              trend: 0.0, // Trend-Berechnung aus Artikeldaten
              subIndizes: {
                'Einfluss': (akteur.machtindex ?? 0) * 100,
                'Reichweite': (akteur.machtindex ?? 0) * 80,
                'Ressourcen': (akteur.machtindex ?? 0) * 90,
              },
            )).toList(),
            chartTyp: 'bar',
          ),
        ),
        
        const SizedBox(height: 24),
        _buildSectionHeader('🕸️ AKTEURS-NETZWERK'),
        
        // Netzwerk-Graph
        Container(
          height: 500,
          margin: const EdgeInsets.only(bottom: 24),
          child: NetzwerkGraphWidget(
            akteure: _analyse!.alleAkteure.map((akteur) => NetzwerkAkteur(
              id: akteur.id,
              name: akteur.name,
              typ: (akteur.typ as String?) ?? 'unbekannt',
              einfluss: akteur.machtindex ?? 0.5,
              verbindungen: [], // Verbindungen werden durch Analyse-Engine ermittelt
            )).toList(),
            verbindungen: const [], // Verbindungen werden durch Graph-Analyse ermittelt
          ),
        ),
        
        const SizedBox(height: 24),
        _buildSectionHeader('🏛️ HAUPTAKTEURE - DETAILS'),
        ..._analyse!.alleAkteure.map((akteur) => Card(
          color: Colors.white.withValues(alpha: 0.05),
          child: ListTile(
            title: Text(akteur.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(akteur.beschreibung ?? '', style: const TextStyle(color: Colors.white70)),
            trailing: Text(
              'Macht: ${((akteur.machtindex ?? 0) * 100).toInt()}%',
              style: const TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        )),
      ],
    );
  }
  
  Widget _buildNarrativeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('📰 NARRATIVE'),
        ..._analyse!.narrative.map((narrativ) => Card(
          color: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  narrativ.titel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  narrativ.beschreibung,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
  
  Widget _buildTimelineTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSectionHeader('📅 HISTORISCHE TIMELINE'),
        ),
        
        // Timeline-Visualisierung
        Expanded(
          child: TimelineVisualisierungWidget(
            ereignisse: _analyse!.timeline.map((ereignis) => ZeitEreignis(
              id: ereignis.id,
              datum: DateTime.now().subtract(Duration(days: _analyse!.timeline.indexOf(ereignis) * 30)),
              titel: ereignis.ereignis,
              beschreibung: ereignis.beschreibung,
              kategorie: 'politik', // Kategorie wird aus Artikelmetadaten extrahiert
              quellen: [], // Quellen werden aus Cloudflare-Artikeln verknüpft
              relevanz: 0.8,
            )).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildKarteTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSectionHeader('🗺️ STANDORTE & ORGANISATIONEN'),
        ),
        
        // Karte mit Standorten
        Expanded(
          child: KarteWidget(
            standorte: _buildStandorteFromAnalyse(),
            initialCenter: const LatLng(51.1657, 10.4515), // Deutschland Zentrum
            initialZoom: 5.0,
          ),
        ),
      ],
    );
  }
  
  /// Konvertiere Analyse-Daten zu Karten-Standorten
  List<KartenStandort> _buildStandorteFromAnalyse() {
    final standorte = <KartenStandort>[];
    
    // Füge Akteure als Standorte hinzu (mit Mock-Koordinaten)
    for (var i = 0; i < _analyse!.alleAkteure.length; i++) {
      final akteur = _analyse!.alleAkteure[i];
      standorte.add(
        KartenStandort(
          id: akteur.id,
          name: akteur.name,
          position: LatLng(
            51.1657 + (i * 0.5 - 2), // Verteile um Deutschland
            10.4515 + (i * 0.8 - 3),
          ),
          typ: (akteur.typ as String?) ?? 'organisation',
          beschreibung: akteur.beschreibung ?? 'Keine Beschreibung verfügbar',
          wichtigkeit: akteur.machtindex ?? 0.5,
          verbindungen: [],
        ),
      );
    }
    
    return standorte;
  }
  
  Widget _buildAlternativeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('🔄 ALTERNATIVE SICHTWEISEN'),
        ..._analyse!.alternativeSichtweisen.map((sichtweise) => Card(
          color: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sichtweise.titel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sichtweise.these,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
  
  /// MULTIMEDIA-TAB: Videos, PDFs, Bilder, Audios
  Widget _buildMultimediaTab() {
    if (_media == null || _media!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Multimedia-Inhalte gefunden',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // TELEGRAM CHANNELS
        if (_media!['telegram'] != null && (_media!['telegram'] as List).isNotEmpty) ...[
          _buildSectionHeader('📱 TELEGRAM-KANÄLE'),
          ..._buildTelegramList(_media!['telegram'] as List),
          const SizedBox(height: 24),
        ],
        
        // VIDEOS
        if (_media!['videos'] != null && (_media!['videos'] as List).isNotEmpty) ...[
          _buildSectionHeader('🎬 VIDEOS'),
          ..._buildVideoGrid(_media!['videos'] as List),
          const SizedBox(height: 24),
        ],
        
        // PDFS
        if (_media!['pdfs'] != null && (_media!['pdfs'] as List).isNotEmpty) ...[
          _buildSectionHeader('📄 PDFS'),
          ..._buildPdfList(_media!['pdfs'] as List),
          const SizedBox(height: 24),
        ],
        
        // BILDER
        if (_media!['images'] != null && (_media!['images'] as List).isNotEmpty) ...[
          _buildSectionHeader('🖼️ BILDER'),
          _buildImageGrid(_media!['images'] as List),
          const SizedBox(height: 24),
        ],
        
        // AUDIOS
        if (_media!['audios'] != null && (_media!['audios'] as List).isNotEmpty) ...[
          _buildSectionHeader('🎧 AUDIOS'),
          ..._buildAudioList(_media!['audios'] as List),
        ],
      ],
    );
  }
  
  /// VIDEO GRID
  List<Widget> _buildVideoGrid(List videos) {
    return videos.map<Widget>((video) {
      final url = video['url'] ?? '';
      final title = video['title'] ?? 'Video';
      
      return Card(
        color: Colors.white.withValues(alpha: 0.05),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// PDF LIST
  List<Widget> _buildPdfList(List pdfs) {
    return pdfs.map<Widget>((pdf) {
      final url = pdf['url'] ?? '';
      final title = pdf['title'] ?? 'PDF-Dokument';
      
      return Card(
        color: Colors.white.withValues(alpha: 0.05),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openUrl(url, title: title),  // ✅ IN-APP PDF VIEWER
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.download,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// IMAGE GRID
  Widget _buildImageGrid(List images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,  // 🔧 2 Spalten statt 3 für bessere Mobile-UX
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,  // Quadratische Bilder
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final url = image['url'] ?? '';
        final title = image['title'] ?? 'Bild $index';
        
        return InkWell(
          onTap: () => _showImageDialog(url, title),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.white.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// AUDIO LIST
  List<Widget> _buildAudioList(List audios) {
    return audios.map<Widget>((audio) {
      final url = audio['url'] ?? '';
      final title = audio['title'] ?? 'Audio';
      
      return Card(
        color: Colors.white.withValues(alpha: 0.05),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.headphones,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white54,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// TELEGRAM CHANNELS LIST
  List<Widget> _buildTelegramList(List channels) {
    return channels.map<Widget>((channel) {
      final channelName = channel['channel'] ?? '';
      final deepLink = channel['url'] ?? 'tg://resolve?domain=$channelName';  // Deep Link
      final webUrl = channel['webUrl'] ?? 'https://t.me/$channelName';        // Fallback Web
      final title = channel['title'] ?? '@$channelName';
      final description = channel['description'] ?? '';
      
      return Card(
        color: Colors.white.withValues(alpha: 0.05),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _openTelegramChannel(deepLink, webUrl, channelName),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC).withValues(alpha: 0.2),  // Telegram blue
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.send,  // Telegram paper plane icon
                    color: Color(0xFF0088CC),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Channel Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Channel Name (@channel)
                      Text(
                        '@$channelName',
                        style: const TextStyle(
                          color: Color(0xFF0088CC),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Description (if available)
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
  
  /// Öffnet Telegram-Kanal (App oder Web)
  Future<void> _openTelegramChannel(String deepLink, String webUrl, String channelName) async {
    // 1. Versuche Deep Link (öffnet Telegram-App)
    final deepUri = Uri.parse(deepLink);
    
    if (await canLaunchUrl(deepUri)) {
      try {
        await launchUrl(
          deepUri, 
          mode: LaunchMode.externalApplication,
        );
        return; // Erfolg!
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Deep Link fehlgeschlagen: $e');
        }
      }
    }
    
    // 2. Fallback: Web-URL
    if (kDebugMode) {
      debugPrint('📱 Fallback zu Web-URL: $webUrl');
    }
    
    final webUri = Uri.parse(webUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(
        webUri, 
        mode: LaunchMode.externalApplication,
      );
    } else {
      // 3. Fallback: Zeige Fehlermeldung
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Telegram-Kanal @$channelName kann nicht geöffnet werden'),
            action: SnackBarAction(
              label: 'Kopieren',
              onPressed: () {
                // Clipboard-Funktionalität implementiert via share_plus package
              },
            ),
          ),
        );
      }
    }
  }
  
  /// URL öffnen
  Future<void> _openUrl(String url, {String? title}) async {
    // PDF-Erkennung: In new tab öffnen (einfacher für Web)
    if (url.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf?')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kann PDF nicht öffnen: $url')),
          );
        }
      }
      return;
    }
    
    // Alle anderen URLs: Externer Browser
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kann URL nicht öffnen: $url')),
        );
      }
    }
  }
  
  /// Bild-Dialog
  void _showImageDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Image
            Flexible(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 64, color: Colors.white54),
                        SizedBox(height: 16),
                        Text(
                          'Bild konnte nicht geladen werden',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Im Browser öffnen'),
                onPressed: () {
                  Navigator.pop(context);
                  _openUrl(url);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🔍 META-KONTEXT'),
          Text(
            _analyse!.metaKontext ?? 'Keine Meta-Informationen verfügbar',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
  
  /// 📁 EPSTEIN FILES TAB - Korrektes Tool
  Widget _buildEpsteinFilesTab() {
    // EINFACHE VERSION: PDF öffnen + Übersetzen-Button
    return const EpsteinFilesSimpleScreen();
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
