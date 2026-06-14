import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../services/archive_video_service.dart'; // C3: kuratierte Modul-Videos
import '../../services/gamification_service.dart';
import '../../services/xp_retry_queue.dart';
import '../../services/module_rating_service.dart'; // ⭐ V-X5
import '../../services/storage_service.dart'; // 📝 I1
import '../../services/vorhang_lesson_notes_service.dart'; // 📝 I1
import '../../services/vorhang_service.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/wb_cached_image.dart';
import 'vorhang_page_route.dart';

/// 🎭 VORHANG Lesson Screen
///
/// 5-Tab Lesson UI für ein einzelnes Modul (V-XX).
/// Tabs: Theorie · Fallstudie · Übung · Test · Videos
///
/// Theorie und Fallstudie werden mit RichText (NICHT flutter_markdown!)
/// gerendert – einfache Heuristik für # Überschriften, **bold**, etc.
///
/// Tests: 5 Fragen normal / 15 Fragen für Boss-Module.
/// Bestehen ab 80% korrekt → XP-Award + Progress-Update auf Server.
class VorhangLessonScreen extends StatefulWidget {
  final String moduleCode;

  const VorhangLessonScreen({super.key, required this.moduleCode});

  @override
  State<VorhangLessonScreen> createState() => _VorhangLessonScreenState();
}

class _VorhangLessonScreenState extends State<VorhangLessonScreen> {
  static const _gold = Color(0xFFC9A84C);
  static const _bgBlack = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _module;
  Map<String, dynamic>? _progress;
  List<Map<String, dynamic>> _videos = [];
  bool _loadingVideos = false;

  // Quiz state
  final Map<int, int> _selectedAnswers = {};
  bool _quizSubmitted = false;
  int _correctCount = 0;
  bool _quizPassed = false;
  bool _submittingProgress = false;

  // Theory-Tab: Inhaltsverzeichnis ein-/ausgeklappt.
  bool _tocExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchModule();
  }

  Future<void> _fetchModule() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      // Direct-Supabase Pfad (Worker-Bypass) — funktioniert auch bei
      // Cloudflare-Worker-Quota-Outage.
      final data = await VorhangService.fetchModule(
        widget.moduleCode,
        userId: user?.id,
      );
      setState(() {
        _module = (data['module'] as Map?)?.cast<String, dynamic>();
        _progress = (data['progress'] as Map?)?.cast<String, dynamic>();
        _loading = false;
        // pre-fill if already passed
        if (_progress != null && _progress!['test_passed'] == true) {
          _quizPassed = true;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchVideos() async {
    if (_loadingVideos || _videos.isNotEmpty) return;
    setState(() => _loadingVideos = true);
    try {
      // C3: zuerst kuratierte (vom Admin zugeordnete) Videos laden.
      final curated = await ArchiveVideoService.instance.fetchByModule(
        world: 'vorhang',
        moduleCode: widget.moduleCode,
      );
      final curatedMapped = curated
          .map(
            (v) => <String, dynamic>{
              'videoId': v.youtubeVideoId,
              'title': v.title.isNotEmpty ? v.title : v.rawTitle,
              'thumbnail': v.effectiveThumbnail,
              'curated': true,
            },
          )
          .toList();

      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/vorhang/youtube/${Uri.encodeComponent(widget.moduleCode)}',
      );
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      final fetched = <Map<String, dynamic>>[];
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['videos'] as List?) ?? const [];
        fetched.addAll(
          list.whereType<Map>().map((e) => e.cast<String, dynamic>()),
        );
      }
      // Kuratierte zuerst, dann Suchergebnisse (ohne Duplikate).
      final seen = curatedMapped
          .map((e) => e['videoId'] as String?)
          .whereType<String>()
          .toSet();
      final merged = [
        ...curatedMapped,
        ...fetched.where((e) => !seen.contains(e['videoId'] as String?)),
      ];
      if (mounted) setState(() => _videos = merged);
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loadingVideos = false);
    }
  }

  Future<void> _submitQuiz() async {
    final questions = _testQuestions();
    if (questions.isEmpty) return;
    if (_selectedAnswers.length < questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte alle Fragen beantworten'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    int correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final correctIndex = (q['correct_index'] as num?)?.toInt() ?? 0;
      if (_selectedAnswers[i] == correctIndex) correct++;
    }
    final scorePercent = (correct / questions.length * 100).round();
    final passed = scorePercent >= 80;
    setState(() {
      _quizSubmitted = true;
      _correctCount = correct;
      _quizPassed = passed;
    });

    // Send to server
    await _submitProgress(scorePercent: scorePercent, passed: passed);
  }

  Future<void> _submitProgress({
    required int scorePercent,
    required bool passed,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _submittingProgress = true);
    try {
      final uri = Uri.parse('${ApiConfig.workerUrl}/api/vorhang/progress');
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'user_id': user.id,
              'module_code': widget.moduleCode,
              'test_score': scorePercent,
              'test_passed': passed,
              'completed': passed,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200 && passed) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final xpAwarded = (data['xp_awarded'] as num?)?.toInt() ?? 0;
        final alreadyCompleted = data['already_completed'] == true;
        if (xpAwarded > 0 && !alreadyCompleted) {
          // Mirror in local gamification service. Failure -> Retry-Queue.
          try {
            await GamificationService().addXp(
              'vorhang',
              xpAwarded,
              reason: 'vorhang_module:${widget.moduleCode}',
              syncServer: false,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint('vorhang_lesson_screen: XP-Sync fehlgeschlagen -> $e');
            }
            await XpRetryQueue.enqueue(
              world: 'vorhang',
              xp: xpAwarded,
              reason: 'vorhang_module:${widget.moduleCode}',
            );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🏆 +$xpAwarded XP – Modul abgeschlossen!'),
                backgroundColor: _gold,
              ),
            );
          }
        }
      }
    } catch (_) {
      // silent – user already sees quiz result
    } finally {
      if (mounted) setState(() => _submittingProgress = false);
    }
  }

  List<Map<String, dynamic>> _testQuestions() {
    final raw = _module?['test_questions'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('vorhang_lesson_screen: silent catch -> $e');
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _bgBlack,
        appBar: WBGlassAppBar(
          world: WBWorld.vorhang,
          title: _module != null
              ? '${_module!['module_code']} · ${_module!['title']}'
              : 'LEKTION',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _gold),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: _bgBlack.withValues(alpha: 0.7),
              child: const TabBar(
                isScrollable: true,
                indicatorColor: _gold,
                indicatorWeight: 2,
                labelColor: _gold,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Theorie'),
                  Tab(
                    icon: Icon(Icons.cases_outlined, size: 18),
                    text: 'Fallstudie',
                  ),
                  Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Übung'),
                  Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'Test'),
                  Tab(
                    icon: Icon(Icons.play_circle_outline, size: 18),
                    text: 'Videos',
                  ),
                  Tab(
                    icon: Icon(Icons.note_add_outlined, size: 18),
                    text: 'Notizen',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: _gold,
                    strokeWidth: 2,
                  ),
                )
              : _error != null
              ? _buildError()
              : _module == null
              ? const SizedBox.shrink()
              : TabBarView(
                  children: [
                    _buildTheoryTab(),
                    _buildCaseStudyTab(),
                    _buildExerciseTab(),
                    _buildTestTab(),
                    _buildVideosTab(),
                    _LessonNotesTab(moduleCode: widget.moduleCode),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: _gold.withValues(alpha: 0.7),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Modul konnte nicht geladen werden',
              style: TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _fetchModule,
              icon: const Icon(Icons.refresh, color: _gold),
              label: const Text(
                'Erneut versuchen',
                style: TextStyle(color: _gold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _gold.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Theory ─────────────────────────────────────────────
  Widget _buildTheoryTab() {
    final text = (_module?['theory_content'] as String?) ?? '';
    return _buildRichTextScroll(
      text,
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 32),
      showMeta: true,
    );
  }

  /// Estimates reading time in minutes from word count (~200 wpm, min 1).
  int _estimateReadingMinutes(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return (words.length / 200).ceil().clamp(1, 99);
  }

  /// Extracts `#`/`##` headings as (level, title) for the table of contents.
  List<MapEntry<int, String>> _extractHeadings(String text) {
    final result = <MapEntry<int, String>>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.startsWith('## ')) {
        result.add(MapEntry(2, line.substring(3).trim()));
      } else if (line.startsWith('# ')) {
        result.add(MapEntry(1, line.substring(2).trim()));
      }
    }
    return result;
  }

  /// Reading-time chip + collapsible table of contents for the Theory tab.
  Widget _buildTheoryMeta(String text) {
    final minutes = _estimateReadingMinutes(text);
    final headings = _extractHeadings(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading-time + section count row
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: _gold.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                '$minutes Min Lesezeit',
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (headings.isNotEmpty) ...[
                const SizedBox(width: 14),
                Icon(
                  Icons.list_alt,
                  size: 14,
                  color: _gold.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${headings.length} Abschnitte',
                  style: TextStyle(
                    color: _gold.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (headings.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Collapsible TOC
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _gold.withValues(alpha: 0.05),
                border: Border.all(color: _gold.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _tocExpanded = !_tocExpanded),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book, color: _gold, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'INHALTSVERZEICHNIS',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          Icon(
                            _tocExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: _gold.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_tocExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < headings.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 6,
                                left: headings[i].key == 2 ? 16.0 : 0.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${i + 1}.',
                                    style: TextStyle(
                                      color: _gold.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      headings[i].value,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 2: Case Study ─────────────────────────────────────────
  Widget _buildCaseStudyTab() {
    final text = (_module?['case_study'] as String?) ?? '';
    if (text.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 130, 20, 32),
        child: Text(
          'Keine Fallstudie verfügbar.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    return _buildRichTextScroll(
      text,
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 32),
    );
  }

  // ── Tab 3: Exercise ───────────────────────────────────────────
  Widget _buildExerciseTab() {
    final text = (_module?['exercise_description'] as String?) ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_surface, _gold.withValues(alpha: 0.06)],
            ),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: _gold, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'PRAKTISCHE ÜBUNG',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: _gold.withValues(alpha: 0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notiere deine Erkenntnisse in einem Journal. '
                        'Der wahre Test ist das gelebte Wissen.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
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
      ],
    );
  }

  // ── Tab 4: Test ───────────────────────────────────────────────
  Widget _buildTestTab() {
    final questions = _testQuestions();
    if (questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 130, 20, 32),
        child: Text(
          'Kein Test verfügbar.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    final isBoss = _module?['is_boss_module'] == true;
    final xp = (_module?['xp_reward'] as num?)?.toInt() ?? 50;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 32),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: _surface.withValues(alpha: 0.6),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isBoss ? Icons.military_tech : Icons.quiz_outlined,
                    color: _gold,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isBoss ? 'BOSS-PRÜFUNG' : 'WISSENS-TEST',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '+$xp XP',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${questions.length} Fragen · Bestehen ab 80% (${(questions.length * 0.8).ceil()} richtige Antworten)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              if (_quizSubmitted) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _quizPassed
                        ? const Color(0xFF1B5E20).withValues(alpha: 0.4)
                        : const Color(0xFF8B0000).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _quizPassed
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _quizPassed ? Icons.check_circle : Icons.cancel,
                        color: _quizPassed
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _quizPassed
                              ? 'Bestanden! $_correctCount / ${questions.length} richtig'
                              : 'Nicht bestanden: $_correctCount / ${questions.length} richtig. Versuche es erneut.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // V4: Quick-Review (Karteikarten-Modus) der Test-Fragen
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            VorhangPageRoute(
              builder: (_) => _QuickReviewScreen(
                questions: questions,
                accent: _gold,
                title: (_module?['title'] as String?) ?? 'Quick-Review',
              ),
            ),
          ),
          icon: const Icon(Icons.style_outlined, color: _gold, size: 18),
          label: const Text(
            'Quick-Review (Karteikarten)',
            style: TextStyle(color: _gold),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            side: BorderSide(color: _gold.withValues(alpha: 0.4)),
          ),
        ),
        const SizedBox(height: 16),

        // Questions
        for (var i = 0; i < questions.length; i++)
          _buildQuestionCard(i, questions[i]),

        const SizedBox(height: 16),

        // Submit / Retry button
        if (!_quizSubmitted)
          ElevatedButton.icon(
            onPressed: _submittingProgress ? null : _submitQuiz,
            icon: _submittingProgress
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.black),
            label: const Text(
              'TEST ABGEBEN',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          )
        else if (!_quizPassed)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _quizSubmitted = false;
                _correctCount = 0;
                _selectedAnswers.clear();
              });
            },
            icon: const Icon(Icons.refresh, color: _gold),
            label: const Text(
              'Erneut versuchen',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _gold.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

        // ⭐ V-X5: Modul-Bewertung nach bestandenem Test
        if (_quizSubmitted && _quizPassed) ...[
          const SizedBox(height: 16),
          _ModuleRatingCard(moduleCode: widget.moduleCode, accent: _gold),
        ],
      ],
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> q) {
    final question = (q['question'] as String?) ?? '';
    final options = (q['options'] as List?)?.cast<dynamic>() ?? const [];
    final correctIndex = (q['correct_index'] as num?)?.toInt() ?? 0;
    final explanation = (q['explanation'] as String?) ?? '';
    final selected = _selectedAnswers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _surface.withValues(alpha: 0.5),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < options.length; i++)
            _buildOption(
              index,
              i,
              options[i].toString(),
              selected,
              correctIndex,
            ),
          if (_quizSubmitted && explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _gold.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      explanation,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(
    int questionIndex,
    int optionIndex,
    String text,
    int? selected,
    int correctIndex,
  ) {
    final isSelected = selected == optionIndex;
    Color bgColor = Colors.transparent;
    Color borderColor = Colors.white.withValues(alpha: 0.15);
    IconData? iconAfter;
    Color? iconColor;

    if (_quizSubmitted) {
      if (optionIndex == correctIndex) {
        bgColor = Colors.green.withValues(alpha: 0.15);
        borderColor = Colors.greenAccent;
        iconAfter = Icons.check;
        iconColor = Colors.greenAccent;
      } else if (isSelected && optionIndex != correctIndex) {
        bgColor = Colors.red.withValues(alpha: 0.15);
        borderColor = Colors.redAccent;
        iconAfter = Icons.close;
        iconColor = Colors.redAccent;
      }
    } else if (isSelected) {
      bgColor = _gold.withValues(alpha: 0.12);
      borderColor = _gold;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _quizSubmitted
            ? null
            : () =>
                  setState(() => _selectedAnswers[questionIndex] = optionIndex),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                  color: isSelected
                      ? _gold.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.circle, color: _gold, size: 10)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (iconAfter != null) ...[
                const SizedBox(width: 8),
                Icon(iconAfter, color: iconColor, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 5: Videos ─────────────────────────────────────────────
  Widget _buildVideosTab() {
    // Lazy-load videos on first view
    if (_videos.isEmpty && !_loadingVideos) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchVideos());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, color: _gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                'VERTIEFUNG · VIDEOS',
                style: TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadingVideos
                    ? null
                    : () {
                        setState(() => _videos = []);
                        _fetchVideos();
                      },
                icon: const Icon(Icons.refresh, color: _gold, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingVideos)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
            ),
          )
        else if (_videos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  color: _gold.withValues(alpha: 0.4),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Keine Videos verfügbar.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          )
        else
          for (final v in _videos) _buildVideoCard(v),
      ],
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> v) {
    final title = (v['title'] as String?) ?? 'Video';
    final videoId = (v['videoId'] as String?) ?? '';
    final thumb =
        (v['thumbnail'] as String?) ??
        'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
    final channel = (v['channel'] as String?) ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (videoId.isEmpty) return;
          final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _surface.withValues(alpha: 0.5),
            border: Border.all(color: _gold.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // PERF (P11): Video-Thumbnails cachen.
                      WbCachedImage(
                        thumb,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: _surface,
                          child: Icon(
                            Icons.video_library,
                            color: _gold.withValues(alpha: 0.4),
                            size: 40,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: _gold,
                          size: 56,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (channel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        channel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Markdown-ish RichText renderer (NO flutter_markdown) ──────
  Widget _buildRichTextScroll(
    String text, {
    required EdgeInsets padding,
    bool showMeta = false,
  }) {
    final lines = text.split('\n');
    final spans = <Widget>[];
    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        spans.add(const SizedBox(height: 10));
        continue;
      }
      if (line.startsWith('# ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Text(
              line.substring(2),
              style: const TextStyle(
                color: _gold,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              line.substring(3),
              style: TextStyle(
                color: _gold.withValues(alpha: 0.9),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              line.substring(4),
              style: TextStyle(
                color: _gold.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        spans.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _gold, width: 3)),
              color: _gold.withValues(alpha: 0.05),
            ),
            child: _inlineRichText(
              line.substring(2),
              baseColor: Colors.white.withValues(alpha: 0.85),
              italic: true,
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        spans.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: _gold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _inlineRichText(
                    line.substring(2),
                    baseColor: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final m = RegExp(r'^(\d+)\. (.*)').firstMatch(line);
        if (m != null) {
          spans.add(
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${m.group(1)}.',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _inlineRichText(
                      m.group(2) ?? '',
                      baseColor: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        spans.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _inlineRichText(
              line,
              baseColor: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: padding,
      children: [
        // Subtitle / module header
        if (_module != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _gold.withValues(alpha: 0.06),
                border: Border.all(color: _gold.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_module!['module_code']} · ${_module!['branch']}',
                    style: TextStyle(
                      color: _gold.withValues(alpha: 0.85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (_module!['subtitle'] as String?) ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Theory-only: reading time + collapsible table of contents.
        if (showMeta) _buildTheoryMeta(text),
        ...spans,
      ],
    );
  }

  /// Inline rich-text mit **bold** / *italic* support.
  Widget _inlineRichText(
    String text, {
    required Color baseColor,
    bool italic = false,
  }) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        parts.add(TextSpan(text: text.substring(last, m.start)));
      }
      if (m.group(1) != null) {
        parts.add(
          TextSpan(
            text: m.group(1),
            style: TextStyle(color: _gold, fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(2) != null) {
        parts.add(
          TextSpan(
            text: m.group(2),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) {
      parts.add(TextSpan(text: text.substring(last)));
    }
    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          color: baseColor,
          fontSize: 14,
          height: 1.65,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        ),
        children: parts.isEmpty ? [TextSpan(text: text)] : parts,
      ),
    );
  }
}

// 📝 I1: Notizen-Tab pro Lektion (sync via VorhangLessonNotesService)
class _LessonNotesTab extends StatefulWidget {
  final String moduleCode;
  const _LessonNotesTab({required this.moduleCode});

  @override
  State<_LessonNotesTab> createState() => _LessonNotesTabState();
}

class _LessonNotesTabState extends State<_LessonNotesTab> {
  static const _gold = Color(0xFFC9A84C);
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  DateTime? _lastSavedAt;

  String _userId() {
    final s = StorageService();
    return s.getMaterieProfile()?.userId ??
        s.getEnergieProfile()?.userId ??
        'anon';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n = await VorhangLessonNotesService.instance.getFor(
      _userId(),
      widget.moduleCode,
    );
    if (mounted) {
      setState(() {
        _ctrl.text = n?.body ?? '';
        _lastSavedAt = n?.updatedAt;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await VorhangLessonNotesService.instance.save(
      userId: _userId(),
      moduleCode: widget.moduleCode,
      body: _ctrl.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _lastSavedAt = saved?.updatedAt ?? DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved != null ? '📝 Gespeichert' : '❌ Fehler'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportAll() async {
    final md = await VorhangLessonNotesService.instance.exportMarkdown(
      _userId(),
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D0B00),
        title: const Text(
          'Alle Notizen exportiert',
          style: TextStyle(color: _gold),
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              md,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.note_alt_outlined, color: _gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Deine Notizen zu dieser Lektion',
                style: TextStyle(color: _gold, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_lastSavedAt != null)
                Text(
                  'Zuletzt: ${_lastSavedAt!.hour.toString().padLeft(2, '0')}:${_lastSavedAt!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Was nimmst du aus dieser Lektion mit? '
                    'Schreibe deine Gedanken, Fragen, Erkenntnisse …',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _gold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Speichern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _exportAll,
                icon: const Icon(Icons.share_outlined, color: _gold, size: 16),
                label: const Text('Export', style: TextStyle(color: _gold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: BorderSide(color: _gold.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// V4: Karteikarten-Quick-Review der Test-Fragen.
///
/// Zeigt jede Frage einzeln; per Tap wird die richtige Antwort + Erklaerung
/// aufgedeckt. Kein Scoring -- reines Wiederholen zum Festigen.
class _QuickReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final Color accent;
  final String title;

  const _QuickReviewScreen({
    required this.questions,
    required this.accent,
    required this.title,
  });

  @override
  State<_QuickReviewScreen> createState() => _QuickReviewScreenState();
}

class _QuickReviewScreenState extends State<_QuickReviewScreen> {
  int _index = 0;
  bool _revealed = false;

  static const _bg = Color(0xFF000000);

  void _next() {
    if (_index < widget.questions.length - 1) {
      setState(() {
        _index++;
        _revealed = false;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final q = widget.questions[_index];
    final question = (q['question'] as String?) ?? '';
    final options = (q['options'] as List?)?.cast<dynamic>() ?? const [];
    final correctIndex = (q['correct_index'] as num?)?.toInt() ?? 0;
    final explanation = (q['explanation'] as String?) ?? '';
    final correctAnswer = (correctIndex >= 0 && correctIndex < options.length)
        ? options[correctIndex].toString()
        : '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: IconThemeData(color: accent),
        title: Text(
          'Quick-Review · ${_index + 1}/${widget.questions.length}',
          style: TextStyle(color: accent, fontSize: 14, letterSpacing: 1.0),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_index + 1) / widget.questions.length,
                  minHeight: 6,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _revealed = !_revealed),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FRAGE',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_revealed) ...[
                          Divider(color: accent.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ANTWORT',
                                style: TextStyle(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            correctAnswer,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              explanation,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ] else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                'Tippe, um die Antwort aufzudecken',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _index < widget.questions.length - 1
                        ? 'Nächste Karte'
                        : 'Fertig',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ⭐ V-X5: Modul-Bewertung (lokal, 1-5 Sterne)
class _ModuleRatingCard extends StatefulWidget {
  final String moduleCode;
  final Color accent;
  const _ModuleRatingCard({required this.moduleCode, required this.accent});

  @override
  State<_ModuleRatingCard> createState() => _ModuleRatingCardState();
}

class _ModuleRatingCardState extends State<_ModuleRatingCard> {
  int? _rating;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ModuleRatingService.instance.getRating(widget.moduleCode);
    if (mounted) {
      setState(() {
        _rating = r;
        _loaded = true;
      });
    }
  }

  Future<void> _set(int stars) async {
    setState(() => _rating = stars);
    await ModuleRatingService.instance.setRating(widget.moduleCode, stars);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Danke für deine Bewertung: $stars/5'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1A1230),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF160C24).withValues(alpha: 0.6),
        border: Border.all(color: widget.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _rating == null
                ? 'Wie hat dir dieses Modul gefallen?'
                : 'Deine Bewertung',
            style: TextStyle(
              color: widget.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    (_rating ?? 0) >= i
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: widget.accent,
                    size: 32,
                  ),
                  onPressed: () => _set(i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
