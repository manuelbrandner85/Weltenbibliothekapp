// 🔬 STUDIEN-ANALYST · PubMed + Semantic Scholar parallel + AI-TLDR + Quality
//
// Statt zwei separate Datenbank-Wrappers: eine Suche → 2 APIs parallel
// (PubMed E-Utilities + Semantic Scholar Graph), dedupliziert per DOI.
// Pro Paper: Study-Type-Detection (RCT/Meta/Review/etc), Quality-Score,
// AI-TLDR via Worker (wenn Paper keine eigene TLDR hat).

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/api_config.dart';
import '../../../services/study_analyst_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class StudyAnalystScreen extends StatefulWidget {
  const StudyAnalystScreen({super.key});

  @override
  State<StudyAnalystScreen> createState() => _StudyAnalystScreenState();
}

class _StudyAnalystScreenState extends State<StudyAnalystScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF030A14);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFF26C6DA);
  static const Color _accent = Color(0xFF66BB6A);
  static const Color _gold = Color(0xFFFFD54F);
  static const String _kBibKey = 'study_bibliography_v1';

  final _searchCtrl = TextEditingController();
  final _service = StudyAnalystService();

  List<StudyPaper> _results = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  Set<String> _bibliography = {};
  String _filterType = 'all';
  // AI-TLDR cache per paper-id
  final Map<String, String> _aiTldrCache = {};

  late final AnimationController _ambientCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _loadBib();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _ambientCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBib() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() =>
          _bibliography = (prefs.getStringList(_kBibKey) ?? const []).toSet());
  }

  Future<void> _persistBib() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kBibKey, _bibliography.toList());
  }

  Future<void> _toggleBib(StudyPaper p) async {
    HapticFeedback.selectionClick();
    final key = jsonEncode({
      'id': p.id,
      'title': p.title,
      'authors': p.authorsShort,
      'year': p.year,
      'url': p.url
    });
    setState(() {
      // Remove via id match
      final existing = _bibliography.firstWhere(
        (k) => k.contains('"id":"${p.id}"'),
        orElse: () => '',
      );
      if (existing.isNotEmpty) {
        _bibliography.remove(existing);
      } else {
        _bibliography.add(key);
      }
    });
    await _persistBib();
  }

  bool _isInBib(StudyPaper p) =>
      _bibliography.any((k) => k.contains('"id":"${p.id}"'));

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
      _query = q;
    });
    try {
      final hits = await _service.search(q, limit: 20);
      if (mounted) {
        setState(() {
          _results = hits;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  List<StudyPaper> get _filtered {
    if (_filterType == 'all') return _results;
    if (_filterType == 'high') {
      return _results.where((p) => p.qualityScore >= 0.6).toList();
    }
    return _results.where((p) => p.studyType == _filterType).toList();
  }

  Future<void> _requestAiTldr(StudyPaper p) async {
    if (_aiTldrCache[p.id] != null ||
        (p.abstractText == null && p.tldr == null)) return;
    HapticFeedback.lightImpact();
    setState(() => _aiTldrCache[p.id] = '__loading__');
    try {
      final prompt = StringBuffer()
        ..writeln(
            'Fasse diese wissenschaftliche Studie in 3 deutschen Sätzen zusammen:')
        ..writeln('1) Was wurde untersucht?')
        ..writeln('2) Was war das Ergebnis?')
        ..writeln('3) Wie verlässlich (Stichprobe, Methode)?')
        ..writeln('')
        ..writeln('Titel: ${p.title}')
        ..writeln('Studientyp: ${p.studyTypeLabel}')
        ..writeln('Jahr: ${p.year ?? "?"}')
        ..writeln('Abstract: ${p.abstractText ?? p.tldr ?? "—"}')
        ..writeln('')
        ..writeln('Knapp, sachlich, ohne Disclaimer.');
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'stratege',
              'message': prompt.toString(),
              'world': 'materie',
              'conversationHistory': [],
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final answer = ((data['reply'] ??
                data['answer'] ??
                data['response'] ??
                data['message'] ??
                '') as String)
            .trim();
        if (mounted) setState(() => _aiTldrCache[p.id] = answer);
      } else {
        if (mounted)
          setState(() => _aiTldrCache[p.id] = '⚠️ HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _aiTldrCache[p.id] = '⚠️ $e');
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Konnte $url nicht öffnen'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _showDetail(StudyPaper p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1422),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => StatefulBuilder(
          builder: (ctx, setSheet) {
            final tldr = _aiTldrCache[p.id];
            final isLoading = tldr == '__loading__';
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                Center(
                    child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 14),
                Row(children: [
                  _qualityBadge(p.qualityScore, big: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.studyTypeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: p.studyTypeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(p.studyTypeLabel,
                          style: TextStyle(
                              color: p.studyTypeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(p.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.4)),
                const SizedBox(height: 6),
                Text(
                    '${p.authorsShort} · ${p.year ?? "?"}${p.journal != null ? " · ${p.journal}" : ""}',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  _chip(p.sourceLabel, _primary),
                  if (p.citationCount != null && p.citationCount! > 0) ...[
                    const SizedBox(width: 6),
                    _chip('📊 ${p.citationCount} Zitate', Colors.cyan),
                  ],
                  if (p.influentialCitationCount != null &&
                      p.influentialCitationCount! > 0) ...[
                    const SizedBox(width: 6),
                    _chip(
                        '⭐ ${p.influentialCitationCount} einflussreich', _gold),
                  ],
                  if (p.sampleSize != null) ...[
                    const SizedBox(width: 6),
                    _chip('👥 N=${p.sampleSize}', Colors.greenAccent),
                  ],
                ]),
                if (p.fields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: p.fields
                          .take(5)
                          .map((f) => _chip(f, Colors.white24))
                          .toList()),
                ],
                const SizedBox(height: 16),
                if (p.tldr != null && p.tldr!.isNotEmpty) ...[
                  const Text('S2-TLDR · auto-generated',
                      style: TextStyle(
                          color: _gold,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(p.tldr!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, height: 1.5)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (p.abstractText != null && p.abstractText!.isNotEmpty) ...[
                  const Text('ABSTRACT',
                      style: TextStyle(
                          color: _gold,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  SelectableText(p.abstractText!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 14),
                ],
                if (tldr == null)
                  ElevatedButton.icon(
                    onPressed: (p.abstractText != null &&
                                p.abstractText!.isNotEmpty) ||
                            p.tldr != null
                        ? () {
                            _requestAiTldr(p);
                            setSheet(() {});
                          }
                        : null,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('AI-3-SATZ-ZUSAMMENFASSUNG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                else if (isLoading)
                  AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, __) => Row(children: [
                      Icon(Icons.auto_awesome,
                          color: _accent.withValues(
                              alpha: 0.5 + 0.3 * _glowCtrl.value),
                          size: 16),
                      const SizedBox(width: 6),
                      const Text('Stratege liest die Studie…',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accent.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: _accent, size: 14),
                            const SizedBox(width: 4),
                            const Text('STRATEGE · AI-TLDR',
                                style: TextStyle(
                                    color: _accent,
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 6),
                          SelectableText(tldr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.6)),
                        ]),
                  ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _toggleBib(p);
                        setSheet(() {});
                      },
                      icon: Icon(
                          _isInBib(p) ? Icons.bookmark : Icons.bookmark_outline,
                          color: _gold,
                          size: 16),
                      label: Text(_isInBib(p) ? 'In Bibliothek' : 'Speichern',
                          style: const TextStyle(color: _gold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (p.url != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(p.url),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Paper öffnen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _qualityBadge(double score, {bool big = false}) {
    final percent = (score * 100).round();
    final color = score >= 0.7
        ? Colors.greenAccent
        : score >= 0.4
            ? Colors.amber
            : Colors.orange;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: big ? 12 : 8, vertical: big ? 6 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(big ? 12 : 8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text('Q $percent%',
          style: TextStyle(
              color: color,
              fontSize: big ? 14 : 10,
              fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text('STUDIEN-ANALYST',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
        ),
        actions: [
          if (_bibliography.isNotEmpty)
            Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: const Icon(Icons.menu_book_rounded, color: _gold),
                tooltip: 'Bibliothek',
                onPressed: _showBibliography,
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: _accent, borderRadius: BorderRadius.circular(8)),
                  child: Text('${_bibliography.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [Color(0x55006064), Color(0x331A4D4D), _bgDark],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _StudyOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.materie, count: 30)),
        SafeArea(
          child: Column(children: [
            _searchBar(),
            if (_results.isNotEmpty) _filterRow(),
            Expanded(child: _body()),
          ]),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Thema oder Forschungsfrage…',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  prefixIcon:
                      const Icon(Icons.science_rounded, color: Colors.white60),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: Colors.white38),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _results = [];
                              _query = '';
                            });
                          },
                        ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.travel_explore_rounded, size: 18),
                  label: Text(
                      _loading
                          ? 'PubMed + Semantic Scholar…'
                          : 'PUBMED + SEMANTIC SCHOLAR',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _filterPill('Alle · ${_results.length}', 'all'),
            _filterPill('🏆 Top-Qualität', 'high'),
            _filterPill('🥇 RCT', 'rct'),
            _filterPill('🏆 Meta', 'meta'),
            _filterPill('📚 Review', 'review'),
            _filterPill('📊 Kohorte', 'cohort'),
            _filterPill('👁️ Beobachtung', 'observational'),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String label, String value) {
    final sel = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: () => setState(() => _filterType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel
                ? _primary.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _primary : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  color: sel ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center),
      ));
    }
    if (_results.isEmpty && _query.isEmpty) return _emptyState();
    if (_filtered.isEmpty) {
      return Center(
          child: Text('Keine Studien in diesem Filter.',
              style: const TextStyle(color: Colors.white54, fontSize: 13)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _paperCard(_filtered[i]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.science_rounded,
              color: _primary.withValues(alpha: 0.4), size: 80),
          const SizedBox(height: 16),
          const Text('Suche wissenschaftliche Studien',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
              'PubMed (35M Papers) + Semantic Scholar (200M Papers) parallel',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                'Vitamin D',
                'mRNA Vakzin',
                'Intermittent Fasting',
                'Meditation Gehirn'
              ]
                  .map((s) => OutlinedButton(
                        onPressed: () {
                          _searchCtrl.text = s;
                          _search();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                              color: _primary.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 11)),
                      ))
                  .toList()),
        ]),
      ),
    );
  }

  Widget _paperCard(StudyPaper p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetail(p),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: p.studyTypeColor.withValues(alpha: 0.25)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _qualityBadge(p.qualityScore),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.studyTypeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(p.studyTypeLabel,
                      style: TextStyle(
                          color: p.studyTypeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                if (_isInBib(p))
                  const Icon(Icons.bookmark_rounded, color: _gold, size: 14),
              ]),
              const SizedBox(height: 8),
              Text(p.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${p.authorsShort} · ${p.year ?? "?"}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              if ((p.citationCount ?? 0) > 0 || p.sampleSize != null) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: [
                  if ((p.citationCount ?? 0) > 0)
                    Text('📊 ${p.citationCount} Zitate',
                        style: TextStyle(
                            color: Colors.cyan.shade300, fontSize: 10)),
                  if (p.sampleSize != null)
                    Text(' · 👥 N=${p.sampleSize}',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 10)),
                ]),
              ],
              const SizedBox(height: 4),
              Text(p.sourceLabel,
                  style: TextStyle(
                      color: _primary.withValues(alpha: 0.8),
                      fontSize: 9,
                      letterSpacing: 1)),
            ]),
          ),
        ),
      ),
    );
  }

  void _showBibliography() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1422),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(
                child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text('BIBLIOTHEK · ${_bibliography.length}',
                style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ..._bibliography.map((k) {
              try {
                final m = jsonDecode(k) as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['title']?.toString() ?? '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Text('${m['authors'] ?? "?"} · ${m['year'] ?? "?"}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                          ]),
                    ),
                    if (m['url'] != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded,
                            color: _primary, size: 16),
                        onPressed: () => _openUrl(m['url'] as String?),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 16),
                      onPressed: () async {
                        setState(() => _bibliography.remove(k));
                        await _persistBib();
                        Navigator.pop(ctx);
                        _showBibliography();
                      },
                    ),
                  ]),
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
      ),
    );
  }
}

class _StudyOrbsPainter extends CustomPainter {
  final double t;
  _StudyOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(
        canvas,
        Offset(size.width * 0.18,
            size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110,
        const Color(0xFF26C6DA));
    _draw(
        canvas,
        Offset(size.width * 0.85,
            size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100,
        const Color(0xFF66BB6A));
    _draw(
        canvas,
        Offset(size.width * 0.5,
            size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        75,
        const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_StudyOrbsPainter old) => old.t != t;
}
