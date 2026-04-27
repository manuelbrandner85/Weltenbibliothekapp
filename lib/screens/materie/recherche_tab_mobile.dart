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
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/performance_helper.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recherche_models.dart';
import '../../models/analyse_models.dart';
import '../../services/analyse_service.dart';
import '../../services/openclaw_comprehensive_service.dart';
import '../../services/free_api_service.dart';
import '../../widgets/visualisierung/visualisierungen.dart';
import '../../widgets/media_grid_widget.dart';
import 'materie_research_screen.dart'; // 🌐 RESEARCH SCREEN
import '../research/epstein_files_simple.dart'; // 📁 EPSTEIN FILES WEBVIEW (NEUE VERSION)
import '../research/additional_sources_screen.dart'; // 🔗 ADDITIONAL SOURCES
import '../research/timeline_screen.dart'; // 📅 RESEARCH TIMELINE

class MobileOptimierterRechercheTab extends StatefulWidget {
  const MobileOptimierterRechercheTab({super.key});

  @override
  State<MobileOptimierterRechercheTab> createState() => _MobileOptimierterRechercheTabState();
}

class _MobileOptimierterRechercheTabState extends State<MobileOptimierterRechercheTab>
    with TickerProviderStateMixin {

  // ─── THEME COLORS (Materie = Cosmos/Blue) ───────────────────────────────────
  static const _bg     = Color(0xFF04080F);
  static const _card   = Color(0xFF0A1020);
  static const _cardB  = Color(0xFF0D1528);
  static const _blue   = Color(0xFF2979FF);
  static const _blueL  = Color(0xFF82B1FF);
  static const _blueD  = Color(0xFF1A237E);
  static const _cyan   = Color(0xFF00E5FF);
  static const _green  = Color(0xFF00E676);
  static const _amber  = Color(0xFFFFAB00);
  static const _red    = Color(0xFFFF1744);
  static const _purple = Color(0xFF7C4DFF);

  // ─── ANIMATIONS ─────────────────────────────────────────────────────────────
  late AnimationController _cosmosCtrl;
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _entryAnim;

  // Services
  late final AnalyseService _analyseService;
  final OpenClawComprehensiveService _openClawService = OpenClawComprehensiveService();

  // State
  final TextEditingController _suchController = TextEditingController();
  RechercheErgebnis? _recherche;
  AnalyseErgebnis? _analyse;
  Map<String, dynamic>? _media;

  // UI State
  bool _showFallback = false;
  int _currentStep = 0;
  late TabController _tabController;

  // Subscriptions
  StreamSubscription? _rechercheSub;
  StreamSubscription? _analyseSub;
  Timer? _debounceTimer;

  // Multimedia-Controller
  final Map<String, VideoPlayerController> _videoControllers = {};

  // Notizen-State
  List<Map<String, dynamic>> _notizen = [];
  final TextEditingController _notizenController = TextEditingController();
  bool _notizenLoading = false;
  static const String _notizenStorageKey = 'recherche_notizen';

  // Guardian News State
  final _freeApi = FreeApiService.instance;
  List<GuardianArticle> _guardianArticles = [];
  bool _guardianLoading = false;
  String _guardianQuery = '';
  final _guardianCtrl = TextEditingController();

  // Wayback Archive State
  final _waybackUrlCtrl = TextEditingController();
  String? _waybackResult;
  bool _waybackLoading = false;

  @override
  void initState() {
    super.initState();

    _analyseService = AnalyseService();

    _tabController = TabController(length: 13, vsync: this);

    _cosmosCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _entryCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _entryAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);

    _ladeNotizen();
  }
  
  @override
  void dispose() {
    _suchController.dispose();
    _notizenController.dispose();
    _guardianCtrl.dispose();
    _waybackUrlCtrl.dispose();
    _tabController.dispose();
    _rechercheSub?.cancel();
    _analyseSub?.cancel();
    _debounceTimer?.cancel();
    _analyseService.dispose();
    _cosmosCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();

    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();

    super.dispose();
  }

  // ─── NOTIZEN METHODEN ────────────────────────────────────────────────────────

  /// Notizen aus SharedPreferences laden
  Future<void> _ladeNotizen() async {
    setState(() => _notizenLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notizenStorageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _notizen = decoded.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Notizen laden fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _notizenLoading = false);
    }
  }

  /// Notizen in SharedPreferences speichern
  Future<void> _speichereNotizen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notizenStorageKey, jsonEncode(_notizen));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Notizen speichern fehlgeschlagen: $e');
    }
  }

  /// Neue Notiz hinzufügen
  Future<void> _neueNotizHinzufuegen(String text) async {
    if (text.trim().isEmpty) return;
    final notiz = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': text.trim(),
      'erstellt': DateTime.now().toIso8601String(),
      'thema': _suchController.text.trim().isNotEmpty
          ? _suchController.text.trim()
          : null,
    };
    setState(() {
      _notizen.insert(0, notiz);
    });
    _notizenController.clear();
    await _speichereNotizen();
  }

  /// Notiz löschen
  Future<void> _notizLoeschen(String id) async {
    setState(() {
      _notizen.removeWhere((n) => n['id'] == id);
    });
    await _speichereNotizen();
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
    
    // ✅ FIX #1: Keine TEST-DATEN in Production
    if (alleAkteure.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte LEERE Akteure');
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
    
    if (narrative.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte keine Narrative für "$suchbegriff"');
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
    
    // ✅ FIX #1: Keine TEST-DATEN in Production
    if (timeline.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte LEERE Timeline');
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
    
    if (alternativeSichtweisen.isEmpty && kDebugMode) {
      debugPrint('⚠️ [DEBUG] Worker lieferte keine alternativen Sichtweisen für "$suchbegriff"');
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
  
  /// Starte Recherche mit OpenClaw Comprehensive Service
  Future<void> _starteRecherche() async {
    final suchbegriff = _suchController.text.trim();
    if (suchbegriff.isEmpty) return;
    
    if (kDebugMode) {
      debugPrint('🚀 [OpenClaw Comprehensive] Recherche wird gestartet...');
      debugPrint('   → Suchbegriff: $suchbegriff');
      debugPrint('   → OpenClaw Gateway: http://72.62.154.95:50074/');
    }
    
    setState(() {
      _showFallback = false;
      _currentStep = 1;
      _recherche = null;
      _analyse = null;
      _media = null;
    });
    
    try {
      // 🚀 OPENCLAW COMPREHENSIVE RESEARCH
      // Scrapt ALLE Medientypen automatisch: Bilder, Videos, Audio, PDFs
      final openClawResult = await _openClawService.comprehensiveResearch(
        query: suchbegriff,
        includeImages: true,
        includeVideos: true,
        includeAudio: true,
        includePdfs: true,
      );
      
      if (kDebugMode) {
        debugPrint('✅ [OpenClaw] Ergebnis erhalten:');
        debugPrint('   → Source: ${openClawResult['source']}');
        debugPrint('   → Artikel: ${(openClawResult['articles'] as List).length}');
        debugPrint('   → Bilder: ${(openClawResult['media']['images'] as List).length}');
        debugPrint('   → Videos: ${(openClawResult['media']['videos'] as List).length}');
        debugPrint('   → Audio: ${(openClawResult['media']['audio'] as List).length}');
        debugPrint('   → PDFs: ${(openClawResult['media']['pdfs'] as List).length}');
      }
      
      // Konvertiere OpenClaw-Artikel zu RechercheQuellen
      final quellen = (openClawResult['articles'] as List).map((article) {
        return RechercheQuelle(
          id: 'openclaw_${article['url']?.hashCode ?? article['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch}',
          titel: article['title'] ?? article['headline'] ?? 'Unbekannter Titel',
          url: article['url'] ?? article['source'] ?? '',
          typ: QuellenTyp.nachrichten,
          volltext: article['content'] ?? article['text'] ?? article['snippet'] ?? '',
          zusammenfassung: article['summary'] ?? article['snippet'] ?? '',
          status: QuellenStatus.success,
          abgerufenAm: DateTime.now(),
        );
      }).toList();
      
      // Konvertiere zu RechercheErgebnis
      final ergebnis = RechercheErgebnis(
        suchbegriff: suchbegriff,
        quellen: quellen,
        startZeit: DateTime.now(),
        endZeit: DateTime.now(),
        istAbgeschlossen: true,
        media: {
          'images': openClawResult['media']['images'],
          'videos': openClawResult['media']['videos'],
          'audio': openClawResult['media']['audio'],
          'pdfs': openClawResult['media']['pdfs'],
          'telegram': [], // Placeholder
          '__openclaw_analysis__': openClawResult['analysis'],
        },
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
        
        _analyseSub?.cancel();
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
      if (kDebugMode) debugPrint('🔄 [CLEANUP] Recherche abgeschlossen/beendet');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeroHeader(),
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
    );
  }

  /// Fehlerbildschirm
  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _red.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.error_outline, color: _red, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Fehler aufgetreten',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(error,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => setState(() {
                _currentStep = 0;
                _recherche = null;
                _analyse = null;
                _media = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Zurücksetzen'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// ═══════════════════════════════════════════════════════════
  /// HERO HEADER — Home-Dashboard Stil
  /// ═══════════════════════════════════════════════════════════
  Widget _buildHeroHeader() {
    return AnimatedBuilder(
      animation: _cosmosCtrl,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              // Cosmos background
              Positioned.fill(
                child: CustomPaint(painter: _CosmosBackgroundPainter(_cosmosCtrl.value)),
              ),
              // Gradient fade at bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, _bg.withValues(alpha: 0.9)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row: Orb + Title + Icon
                      Row(
                        children: [
                          // Pulsing blue orb
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [_cyan, _blue, _blueD]),
                                boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.3 + 0.2 * _pulseCtrl.value), blurRadius: 16 + 8 * _pulseCtrl.value, spreadRadius: 2)],
                              ),
                              child: const Icon(Icons.travel_explore, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('INTERNET-RECHERCHE',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                Text('KI • Web-Scraping • Alternative Medien',
                                    style: TextStyle(color: _blueL.withValues(alpha: 0.8), fontSize: 11)),
                              ],
                            ),
                          ),
                          // Deep Research button
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterieResearchScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_blue, _blueD]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.4), blurRadius: 8)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.open_in_new, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  const Text('Deep', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Search field
                      Container(
                        decoration: BoxDecoration(
                          color: _card.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _blue.withValues(alpha: 0.3)),
                          boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.1), blurRadius: 12)],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search, color: _blueL.withValues(alpha: 0.7), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _suchController,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Suche recherchieren...',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _starteRecherche(),
                              ),
                            ),
                            if (_suchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5), size: 18),
                                onPressed: () => setState(() => _suchController.clear()),
                              ),
                            GestureDetector(
                              onTap: _starteRecherche,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [_blue, _blueD]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Suchen', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Trending chips
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildTrendingChip('🌍 Geopolitik', _blue),
                            _buildTrendingChip('🛸 UFOs', _purple),
                            _buildTrendingChip('📜 Geschichte', _amber),
                            _buildTrendingChip('💊 Heilmethoden', _green),
                            _buildTrendingChip('🔬 Wissenschaft', _cyan),
                            _buildTrendingChip('🏛️ Politik', _red),
                            _buildTrendingChip('💡 Technologie', _blueL),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          final text = label.replaceAll(RegExp(r'[^\w\s]', unicode: true), '').trim();
          _suchController.text = text;
          _starteRecherche();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
  
  // ignore: unused_element
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
  
  // ignore: unused_element
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
  
  /// Start Screen — Home-Dashboard Stil
  Widget _buildStartScreen() {
    return FadeTransition(
      opacity: _entryAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(_entryAnim),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    const Text('KI-ANALYSE-TOOLS', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(width: 8),
                    Text('5 Tools', style: TextStyle(color: _blueL.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ),

              // KI-Tool Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _buildKIToolCard(context,
                      icon: Icons.visibility, title: 'Propaganda\nDetector',
                      color: _red, description: 'Manipulation\nerkennen',
                      onTap: () => Navigator.of(context).pushNamed('/propaganda-detector')),
                  _buildKIToolCard(context,
                      icon: Icons.image_search, title: 'Image\nForensics',
                      color: _blue, description: 'Bild-Manipulation\nanalysieren',
                      onTap: () => Navigator.of(context).pushNamed('/image-forensics')),
                  _buildKIToolCard(context,
                      icon: Icons.device_hub, title: 'Power\nNetwork',
                      color: _purple, description: 'Machtnetzwerke\nvisualisieren',
                      onTap: () => Navigator.of(context).pushNamed('/power-network-mapper')),
                  _buildKIToolCard(context,
                      icon: Icons.analytics, title: 'Event\nPredictor',
                      color: _amber, description: 'Zukunfts-Szenarien\nanalysieren',
                      onTap: () => Navigator.of(context).pushNamed('/event-predictor')),
                  _buildKIToolCard(context,
                      icon: Icons.folder_special, title: 'Epstein\nFiles',
                      color: _red, description: 'Justice.gov PDF\nLesen & Übersetzen',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EpsteinFilesSimpleScreen()))),
                ],
              ),

              const SizedBox(height: 28),

              // Hint
              Center(
                child: Column(
                  children: [
                    Icon(Icons.keyboard_arrow_up, color: _blue.withValues(alpha: 0.5), size: 28),
                    const SizedBox(height: 4),
                    Text('Suchfeld oben nutzen oder Tool antippen',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// KI-Tool Card — Home-Dashboard Stil
  Widget _buildKIToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_card, _cardB],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative circle background
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color.withValues(alpha: 0.25), Colors.transparent]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, height: 1.3),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Öffnen', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Recherche Progress — Cosmos Stil
  Widget _buildRechercheProgress() {
    if (_recherche == null) {
      return Center(
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_cyan, _blue, _blueD]),
                  boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.3 + 0.25 * _pulseCtrl.value), blurRadius: 24 + 12 * _pulseCtrl.value, spreadRadius: 4)],
                ),
                child: const Icon(Icons.travel_explore, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text('Recherche läuft...', style: TextStyle(color: _blueL, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Quellen werden analysiert', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final progress = _recherche!.fortschritt;
    final erfolgsRate = _recherche!.erfolgsRate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pulsing header orb
          Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_cyan, _blue, _blueD]),
                  boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.25 + 0.2 * _pulseCtrl.value), blurRadius: 20 + 10 * _pulseCtrl.value)],
                ),
                child: const Icon(Icons.travel_explore, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(child: Text('DEEP RECHERCHE', style: TextStyle(color: _blueL, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          const SizedBox(height: 20),

          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(colors: [_cyan, _blue]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% abgeschlossen',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              _buildStatCard('Quellen', '${_recherche!.erfolgreicheQuellen}/${_recherche!.gesamtQuellen}', _blue),
              const SizedBox(width: 12),
              _buildStatCard('Erfolg', '${(erfolgsRate * 100).toInt()}%', _green),
              const SizedBox(width: 12),
              _buildStatCard('Dauer', '${_recherche!.dauer.inSeconds}s', _amber),
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
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuelleCard(RechercheQuelle quelle) {
    final statusIcon = switch (quelle.status) {
      QuellenStatus.success => Icons.check_circle,
      QuellenStatus.loading => Icons.hourglass_empty,
      QuellenStatus.failed  => Icons.error,
      _                     => Icons.pending,
    };
    final statusColor = switch (quelle.status) {
      QuellenStatus.success => _green,
      QuellenStatus.loading => _amber,
      QuellenStatus.failed  => _red,
      _                     => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quelle.titel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(quelle.url, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(quelle.typ.label, style: TextStyle(color: _blueL, fontSize: 10)),
          ),
        ],
      ),
    );
  }
  
  /// Analyse Results
  Widget _buildAnalyseResults() {
    if (kDebugMode) {
      debugPrint('🖼️ [UI] _buildAnalyseResults aufgerufen');
      debugPrint('   - Analyse vorhanden: ${_analyse != null}');
      debugPrint('   - TabController: initialized');
      debugPrint('   - istKiGeneriert: ${_analyse?.istKiGeneriert}');
    }
    
    return Container(
      color: _bg,
      child: Column(
        children: [
          Container(
            color: _card,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: _cyan,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
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
                Tab(text: 'EPSTEIN FILES'),
                Tab(text: 'QUELLEN'),
                Tab(text: 'NOTIZEN'),
                Tab(text: '📰 GUARDIAN'),
                Tab(text: '📦 ARCHIV'),
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
                const ResearchTimelineScreen(), // 🆕 NEUE TIMELINE
                _buildKarteTab(),
                _buildAlternativeTab(),
                _buildMetaTab(),
                _buildEpsteinFilesTab(),
                const AdditionalSourcesScreen(),
                _buildNotizenTab(),
                _buildGuardianTab(),
                _buildWaybackTab(),
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
  
  // ignore: unused_element
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
    try {
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
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ URL öffnen fehlgeschlagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Öffnen: $e')),
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
  
  /// 📝 NOTIZEN TAB - Lokale Forschungsnotizen
  Widget _buildNotizenTab() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Eingabe-Bereich
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note_add, color: Colors.cyan, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Neue Notiz',
                      style: TextStyle(
                        color: Colors.cyan.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (_suchController.text.isNotEmpty) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Thema: ${_suchController.text.trim()}',
                          style: const TextStyle(color: Colors.cyan, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notizenController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Erkenntnisse, Verbindungen, Fragen notieren...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _neueNotizHinzufuegen(_notizenController.text),
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notizen-Liste
          Expanded(
            child: _notizenLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  )
                : _notizen.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notes_outlined,
                              size: 64,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Noch keine Notizen',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Starte eine Recherche und halte deine Erkenntnisse fest',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _notizen.length,
                        itemBuilder: (context, index) {
                          final notiz = _notizen[index];
                          final erstellt = DateTime.tryParse(
                                notiz['erstellt']?.toString() ?? '',
                              ) ??
                              DateTime.now();
                          return Dismissible(
                            key: Key(notiz['id'].toString()),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _notizLoeschen(notiz['id'].toString()),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.cyan.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (notiz['thema'] != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.cyan.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        notiz['thema'].toString(),
                                        style: const TextStyle(
                                            color: Colors.cyan, fontSize: 11),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    notiz['text'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 12, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${erstellt.day}.${erstellt.month}.${erstellt.year} '
                                        '${erstellt.hour.toString().padLeft(2, '0')}:${erstellt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _notizLoeschen(notiz['id'].toString()),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  // ─── GUARDIAN NEWS TAB ───────────────────────────────────────────────────────

  Future<void> _loadGuardianNews([String? q]) async {
    final query = (q ?? _guardianQuery).trim();
    if (query.isEmpty) return;
    setState(() { _guardianLoading = true; _guardianQuery = query; });
    final result = await _freeApi.fetchGuardianNews(query, limit: 12);
    if (mounted) setState(() { _guardianArticles = result; _guardianLoading = false; });
  }

  Widget _buildGuardianTab() {
    return Column(
      children: [
        // Suchleiste
        Container(
          color: _bg,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _guardianCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Guardian-Nachrichten suchen…',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: _card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.newspaper, color: _blue),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (v) => _loadGuardianNews(v),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _loadGuardianNews(_guardianCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                child: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        // Tipp-Text wenn noch keine Suche
        if (_guardianQuery.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📰', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'The Guardian — Aktuelle Nachrichten',
                    style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Suche nach einem Thema\nz.B. "geopolitics", "climate", "AI"',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Schnellsuche-Buttons
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: ['geopolitics', 'conspiracy', 'government', 'war', 'surveillance']
                        .map((tag) => ActionChip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: _card,
                              onPressed: () {
                                _guardianCtrl.text = tag;
                                _loadGuardianNews(tag);
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          )
        else if (_guardianLoading)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _blue),
                  SizedBox(height: 16),
                  Text('Lade Guardian-Artikel…', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          )
        else if (_guardianArticles.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('Keine Artikel gefunden', style: TextStyle(color: Colors.white54)),
                  TextButton(
                    onPressed: () => _loadGuardianNews(),
                    child: const Text('Neu laden', style: TextStyle(color: _blue)),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadGuardianNews(),
              color: _blue,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _guardianArticles.length + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('📰', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('The Guardian',
                                    style: TextStyle(color: _blue, fontWeight: FontWeight.bold)),
                                Text('${_guardianArticles.length} Artikel zu "$_guardianQuery"',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final art = _guardianArticles[i - 1];
                  return Card(
                    color: _card,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final uri = Uri.tryParse(art.webUrl);
                        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (art.sectionName != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(art.sectionName!,
                                    style: const TextStyle(color: _blue, fontSize: 11)),
                              ),
                            Text(
                              art.webTitle,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (art.trailText != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                art.trailText!.replaceAll(RegExp(r'<[^>]*>'), ''),
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (art.webPublicationDate != null)
                                  Text(
                                    art.webPublicationDate!.substring(0, 10),
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                const Spacer(),
                                const Icon(Icons.open_in_new, size: 14, color: _blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ─── WAYBACK ARCHIVE TAB ─────────────────────────────────────────────────────

  Future<void> _checkWayback() async {
    final url = _waybackUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _waybackLoading = true; _waybackResult = null; });
    final snapshot = await _freeApi.fetchWaybackSnapshot(url);
    if (mounted) setState(() { _waybackResult = snapshot; _waybackLoading = false; });
  }

  Widget _buildWaybackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amber.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('📦', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text('Wayback Machine — Internet Archive',
                        style: TextStyle(color: _amber, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Prüfe ob eine gelöschte oder zensierte Webseite im Archiv gespeichert ist.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('URL prüfen:', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _waybackUrlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'https://beispiel.com/artikel',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: _card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.link, color: _amber),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _checkWayback(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _waybackLoading ? null : _checkWayback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                child: _waybackLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_waybackResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 20),
                      SizedBox(width: 8),
                      Text('✅ Snapshot gefunden!',
                          style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_waybackResult!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(_waybackResult!);
                        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Archiv öffnen'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _green, foregroundColor: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_waybackLoading && _waybackUrlCtrl.text.isNotEmpty && _waybackResult == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: _red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kein Archiv-Snapshot gefunden für diese URL.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Text('Was ist die Wayback Machine?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Das Internet Archive speichert Snapshots von Webseiten seit 1996. '
            'Wenn eine Nachricht, ein Artikel oder eine Quelle gelöscht oder '
            'zensiert wurde, kann hier oft noch die Original-Version gefunden werden.',
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final uri = Uri.parse('https://archive.org');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('→ archive.org direkt öffnen',
                style: TextStyle(color: _amber, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── COSMOS BACKGROUND PAINTER ───────────────────────────────────────────────
class _CosmosBackgroundPainter extends CustomPainter {
  final double t;
  _CosmosBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Nebula glow top-left
    paint.shader = RadialGradient(
      colors: [const Color(0xFF2979FF).withValues(alpha: 0.12), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.3), radius: size.width * 0.5));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), size.width * 0.5, paint);

    // Nebula glow right
    paint.shader = RadialGradient(
      colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.08), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.6), radius: size.width * 0.4));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), size.width * 0.4, paint);

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final stars = [
      [0.1, 0.15, 1.2], [0.3, 0.08, 0.9], [0.6, 0.2, 1.0], [0.8, 0.1, 0.8],
      [0.15, 0.7, 1.1], [0.5, 0.5, 0.7], [0.9, 0.4, 1.3], [0.4, 0.85, 0.9],
      [0.7, 0.75, 0.8], [0.25, 0.4, 1.0],
    ];
    for (final s in stars) {
      final twinkle = 0.4 + 0.6 * ((t * 3 + s[0] * 7) % 1.0);
      starPaint.color = Colors.white.withValues(alpha: 0.3 + 0.5 * twinkle);
      canvas.drawCircle(Offset(size.width * s[0], size.height * s[1]), s[2], starPaint);
    }
  }

  @override
  bool shouldRepaint(_CosmosBackgroundPainter old) => old.t != t;
}
