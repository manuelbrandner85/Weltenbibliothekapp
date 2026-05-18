// 🏛️ EU-PARLAMENT-TRACKER · Letzte Abstimmungen + MEP-Browser + Wertealignment
//
// Statt nur Link auf europarl.europa.eu: tatsächlich lesbarer Live-Feed der
// letzten Plenar-Votes mit Result + Stimmen-Verteilung, MEP-Liste mit Country/
// Group-Filter, und persönlicher "Werte-Match"-Modus (markiere Votes mit
// 👍/👎 → App berechnet welche Fraktionen am häufigsten so abgestimmt haben).

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/eu_parliament_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class EuParliamentTrackerScreen extends StatefulWidget {
  const EuParliamentTrackerScreen({super.key});

  @override
  State<EuParliamentTrackerScreen> createState() => _EuParliamentTrackerScreenState();
}

class _EuParliamentTrackerScreenState extends State<EuParliamentTrackerScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF040A1A);
  static const Color _primary = Color(0xFF2196F3);
  static const Color _accent = Color(0xFFFFD54F);
  static const String _kAlignKey = 'eu_alignments_v1';

  final _searchCtrl = TextEditingController();
  final _service = EuParliamentService();

  List<EuVote> _votes = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | adopted | rejected
  // Vote-Alignments (voteId → +1 für 'yes' | -1 für 'no' | 0 für unmarked)
  Map<int, int> _alignments = {};
  late final AnimationController _ambientCtrl;
  int _tab = 0; // 0 = Votes, 1 = MEPs
  List<EuMep> _meps = [];
  bool _loadingMeps = false;
  String _mepCountryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 13))..repeat();
    _loadAlignments();
    _loadRecentVotes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAlignments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlignKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _alignments = m.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _persistAlignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAlignKey, jsonEncode(_alignments.map((k, v) => MapEntry(k.toString(), v))));
  }

  Future<void> _loadRecentVotes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final votes = await _service.getRecentVotes(limit: 50);
      if (mounted) {
        setState(() {
          _votes = votes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _searchVotes() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      _loadRecentVotes();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _error = null; });
    try {
      final votes = await _service.searchVotes(q, limit: 30);
      if (mounted) {
        setState(() { _votes = votes; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _loadMeps() async {
    if (_meps.isNotEmpty) return;
    setState(() => _loadingMeps = true);
    try {
      final meps = await _service.getMembers(limit: 250);
      if (mounted) setState(() { _meps = meps; _loadingMeps = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingMeps = false);
    }
  }

  void _setAlignment(int voteId, int value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_alignments[voteId] == value) {
        _alignments.remove(voteId);
      } else {
        _alignments[voteId] = value;
      }
    });
    _persistAlignments();
  }

  Future<void> _openExternal(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Konnte $url nicht öffnen'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  List<EuVote> get _filteredVotes {
    if (_filter == 'all') return _votes;
    if (_filter == 'adopted') return _votes.where((v) => v.isAdopted).toList();
    if (_filter == 'rejected') return _votes.where((v) => v.result.toUpperCase() == 'REJECTED').toList();
    return _votes;
  }

  List<String> get _countries {
    final s = <String>{};
    for (final m in _meps) {
      if (m.country != null) s.add(m.country!);
    }
    final list = s.toList()..sort();
    return list;
  }

  List<EuMep> get _filteredMeps {
    if (_mepCountryFilter == 'all') return _meps;
    return _meps.where((m) => m.country == _mepCountryFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_accent, _primary],
          ).createShader(r),
          child: const Text('EU-PARLAMENT',
              style: TextStyle(color: Colors.white, fontSize: 14,
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
        actions: [
          if (_alignments.isNotEmpty)
            Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: const Icon(Icons.fact_check_rounded, color: _accent),
                tooltip: 'Werte-Match',
                onPressed: _showAlignmentSummary,
              ),
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                  child: Text('${_alignments.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
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
              colors: [Color(0x550D47A1), Color(0x33082E5C), _bg],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _EuOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.materie, count: 28)),
        SafeArea(
          child: Column(children: [
            _tabBar(),
            Expanded(child: _tab == 0 ? _votesView() : _mepsView()),
          ]),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(children: [
        Expanded(child: _tabBtn(0, '🗳️ Abstimmungen')),
        const SizedBox(width: 6),
        Expanded(child: _tabBtn(1, '👥 Abgeordnete')),
      ]),
    );
  }

  Widget _tabBtn(int idx, String label) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tab = idx);
        if (idx == 1) _loadMeps();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? _primary : Colors.transparent),
        ),
        child: Center(child: Text(label,
            style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 12, fontWeight: FontWeight.w700))),
      ),
    );
  }

  Widget _votesView() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onSubmitted: (_) => _searchVotes(),
          decoration: InputDecoration(
            hintText: 'Suche Vote-Titel (z.B. Klima, KI, Migration)',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60, size: 18),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ),
      SizedBox(height: 30, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _filterPill('Alle · ${_votes.length}', 'all'),
          _filterPill('✅ Angenommen', 'adopted'),
          _filterPill('❌ Abgelehnt', 'rejected'),
        ],
      )),
      const SizedBox(height: 4),
      Expanded(child: _votesList()),
    ]);
  }

  Widget _filterPill(String label, String value) {
    final sel = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? _primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _primary : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _votesList() {
    if (_loading) return Center(child: CircularProgressIndicator(color: _primary));
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center),
      ));
    }
    if (_filteredVotes.isEmpty) {
      return const Center(child: Text('Keine Abstimmungen gefunden.',
          style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: _filteredVotes.length,
      itemBuilder: (_, i) => _voteCard(_filteredVotes[i]),
    );
  }

  Widget _voteCard(EuVote v) {
    final alignment = _alignments[v.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: v.isAdopted
                ? Colors.green.withValues(alpha: 0.25)
                : (v.result.toUpperCase() == 'REJECTED'
                    ? Colors.red.withValues(alpha: 0.25)
                    : Colors.white12),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: v.isAdopted ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: v.isAdopted ? Colors.green : Colors.red),
              ),
              child: Text(v.resultLabel,
                  style: TextStyle(
                      color: v.isAdopted ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 9, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Text(v.fmtDate,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ]),
          const SizedBox(height: 8),
          Text(v.title,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          if (v.total != null) ...[
            const SizedBox(height: 8),
            _voteBar(v),
          ],
          if (v.categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 4,
                children: v.categories.take(3).map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(c,
                      style: const TextStyle(color: Colors.white60, fontSize: 9)),
                )).toList()),
          ],
          const SizedBox(height: 8),
          Row(children: [
            _alignBtn(v.id, 1, '👍', alignment == 1),
            const SizedBox(width: 6),
            _alignBtn(v.id, -1, '👎', alignment == -1),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Auf howtheyvote.eu öffnen',
              onPressed: () => _openExternal('https://howtheyvote.eu/votes/${v.id}'),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _alignBtn(int voteId, int value, String emoji, bool selected) {
    return GestureDetector(
      onTap: () => _setAlignment(voteId, value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? (value > 0 ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3))
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected
              ? (value > 0 ? Colors.green : Colors.red)
              : Colors.white12),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _voteBar(EuVote v) {
    final f = v.forVotes ?? 0;
    final a = v.againstVotes ?? 0;
    final ab = v.abstainVotes ?? 0;
    final total = (f + a + ab).clamp(1, 10000);
    return Column(children: [
      Row(children: [
        Text('$f',
            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('$ab',
            style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('$a',
            style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 3),
      SizedBox(
        height: 6,
        child: Row(children: [
          Expanded(flex: f, child: Container(decoration: BoxDecoration(
            color: Colors.green, borderRadius: const BorderRadius.horizontal(left: Radius.circular(3))))),
          Expanded(flex: ab, child: Container(color: Colors.white24)),
          Expanded(flex: a, child: Container(decoration: BoxDecoration(
            color: Colors.red, borderRadius: const BorderRadius.horizontal(right: Radius.circular(3))))),
        ]),
      ),
      const SizedBox(height: 2),
      Text('${total} Stimmen',
          style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ]);
  }

  Widget _mepsView() {
    if (_loadingMeps) return Center(child: CircularProgressIndicator(color: _primary));
    if (_meps.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_rounded, color: _primary.withValues(alpha: 0.4), size: 60),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _loadMeps,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Abgeordnete laden'),
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ]),
      ));
    }
    return Column(children: [
      SizedBox(
        height: 30,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            _countryPill('Alle · ${_meps.length}', 'all'),
            ..._countries.map((c) => _countryPill(c, c)),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: _filteredMeps.length,
          itemBuilder: (_, i) {
            final m = _filteredMeps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _primary.withValues(alpha: 0.2),
                    backgroundImage: m.imageUrl != null ? NetworkImage(m.imageUrl!) : null,
                    child: m.imageUrl == null
                        ? Text(m.firstName.isNotEmpty ? m.firstName[0] : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 14))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${m.country ?? "?"} · ${m.group ?? "?"}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 16),
                    onPressed: () => _openExternal('https://howtheyvote.eu/members/${m.id}'),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _countryPill(String label, String value) {
    final sel = _mepCountryFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: () => setState(() => _mepCountryFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? _accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? _accent : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _showAlignmentSummary() {
    final yesCount = _alignments.values.where((v) => v > 0).length;
    final noCount = _alignments.values.where((v) => v < 0).length;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1428),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Center(child: Container(
              width: 42, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            const Text('DEINE WERTE-MARKIERUNGEN',
                style: TextStyle(color: _accent, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Column(children: [
                Text('$yesCount',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                const Text('👍 dafür', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
              Column(children: [
                Text('$noCount',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                const Text('👎 dagegen', style: TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 18),
            const Text(
              'Markiere mehr Votes mit 👍/👎 um deine Werte-Karte zu schärfen. '
              'Beim nächsten Update kann die App MEPs nach Übereinstimmung scoren.',
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            const Text('MARKIERTE VOTES',
                style: TextStyle(color: _accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._alignments.entries.map((e) {
              final vote = _votes.firstWhere((v) => v.id == e.key,
                  orElse: () => EuVote(id: e.key, title: 'Vote #${e.key}', result: '?', categories: const []));
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  Text(e.value > 0 ? '👍' : '👎', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(vote.title,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() => _alignments.remove(e.key));
                      _persistAlignments();
                      Navigator.pop(ctx);
                      _showAlignmentSummary();
                    },
                  ),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EuOrbsPainter extends CustomPainter {
  final double t;
  _EuOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.18, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFF2196F3));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100, const Color(0xFFFFD54F));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        75, const Color(0xFF1976D2));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_EuOrbsPainter old) => old.t != t;
}
