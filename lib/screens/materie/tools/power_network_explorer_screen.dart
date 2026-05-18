// 🔗 POWER-NETWORK-EXPLORER · OpenSanctions + Aleph + ICIJ kombiniert
//
// Statt 3 separate WebView-Suchen: eine unified Suche über alle 3
// Datenbanken parallel. Risk-Score, Source-Badges, Detail-Sheet,
// Watch-List (lokal, alarmiert wenn Entity in neuer Liste auftaucht).

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/power_network_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class PowerNetworkExplorerScreen extends StatefulWidget {
  const PowerNetworkExplorerScreen({super.key});

  @override
  State<PowerNetworkExplorerScreen> createState() => _PowerNetworkExplorerScreenState();
}

class _PowerNetworkExplorerScreenState extends State<PowerNetworkExplorerScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0512);
  static const Color _primary = Color(0xFFE53935);
  static const Color _accent = Color(0xFF7C4DFF);
  static const Color _gold = Color(0xFFFFD54F);
  static const String _kWatchKey = 'power_network_watchlist_v1';

  final _searchCtrl = TextEditingController();
  final _service = PowerNetworkService();

  List<PowerNetworkHit> _results = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  Set<String> _watchlist = {};
  String _filterSource = 'all'; // all | opensanctions | aleph

  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _loadWatchlist();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kWatchKey) ?? const [];
    if (mounted) setState(() => _watchlist = raw.toSet());
  }

  Future<void> _persistWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kWatchKey, _watchlist.toList());
  }

  Future<void> _toggleWatch(PowerNetworkHit h) async {
    HapticFeedback.selectionClick();
    final key = '${h.id}|${h.name}';
    setState(() {
      if (_watchlist.contains(key)) {
        _watchlist.remove(key);
      } else {
        _watchlist.add(key);
      }
    });
    await _persistWatchlist();
  }

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
      final hits = await _service.search(q, limit: 25);
      if (mounted) {
        setState(() {
          _results = hits;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Suche fehlgeschlagen: $e';
          _loading = false;
        });
      }
    }
  }

  List<PowerNetworkHit> get _filtered {
    if (_filterSource == 'all') return _results;
    return _results.where((h) => h.source == _filterSource).toList();
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

  void _showDetail(PowerNetworkHit h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12081E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scroll) => _detailContent(h, scroll),
      ),
    );
  }

  Widget _detailContent(PowerNetworkHit h, ScrollController scroll) {
    final props = (h.raw['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
    final isWatched = _watchlist.contains('${h.id}|${h.name}');
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Center(
          child: Container(
            width: 42, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _riskBadge(h.riskScore, big: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(h.name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ]),
        if (h.alias != null) ...[
          const SizedBox(height: 4),
          Text('aka ${h.alias}',
              style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip(h.sourceLabel, _accent),
          if (h.schema != null) _chip(h.schema!, Colors.white24),
          if (h.country != null) _chip('🌍 ${h.country}', Colors.cyan),
          ...h.tags.map((t) => _chip(t, _primary)),
        ]),
        const SizedBox(height: 16),
        if (props.isNotEmpty) ...[
          const Text('DETAILS',
              style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...props.entries.where((e) {
            final v = e.value;
            return v != null &&
                !['id', 'caption', 'topics'].contains(e.key) &&
                (v is List ? v.isNotEmpty : v.toString().trim().isNotEmpty);
          }).take(20).map((e) {
            final v = e.value;
            final str = v is List ? v.join(', ') : v.toString();
            if (str.length > 200) return _kv(e.key, '${str.substring(0, 200)}…');
            return _kv(e.key, str);
          }),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _toggleWatch(h),
              icon: Icon(isWatched ? Icons.bookmark : Icons.bookmark_outline,
                  color: _gold, size: 18),
              label: Text(isWatched ? 'Aus Watchlist entfernen' : 'Beobachten',
                  style: const TextStyle(color: _gold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (h.sourceUrl != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openExternal(h.sourceUrl!),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Quelle öffnen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k.toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 1),
          SelectableText(v,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        ]),
      );

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _riskBadge(double risk, {bool big = false}) {
    final percent = (risk * 100).round();
    final color = risk >= 0.8 ? Colors.red : risk >= 0.5 ? Colors.orange : risk > 0.2 ? Colors.amber : Colors.greenAccent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 12 : 8, vertical: big ? 6 : 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(big ? 12 : 8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text('$percent%',
          style: TextStyle(color: color, fontSize: big ? 16 : 11, fontWeight: FontWeight.bold)),
    );
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
            colors: [_gold, _primary, _accent],
          ).createShader(r),
          child: const Text('POWER-NETWORK-EXPLORER',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        actions: [
          if (_watchlist.isNotEmpty)
            Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: const Icon(Icons.bookmark_rounded, color: _gold),
                tooltip: 'Watchlist',
                onPressed: _showWatchlist,
              ),
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${_watchlist.length}',
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
              colors: [Color(0x55B71C1C), Color(0x33420C0C), _bg],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _PnOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.materie, count: 30)),
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
                  hintText: 'Name einer Person oder Firma…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white38),
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
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.travel_explore_rounded, size: 18),
                  label: Text(_loading
                      ? 'Durchsuche 2 Datenbanken…'
                      : 'IN 2 DATENBANKEN SUCHEN',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'OpenSanctions · Aleph OCCRP (Panama/Pandora/FinCEN/LuxLeaks/Suisse)',
                style: TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    final all = _results.length;
    final os = _results.where((h) => h.source == 'opensanctions').length;
    final aleph = _results.where((h) => h.source == 'aleph').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _filterPill('Alle · $all', 'all'),
            _filterPill('🚨 Sanktionen · $os', 'opensanctions'),
            _filterPill('📂 Leaks · $aleph', 'aleph'),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String label, String value) {
    final sel = _filterSource == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filterSource = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: sel ? _accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? _accent : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center),
      ));
    }
    if (_results.isEmpty && _query.isEmpty) {
      return _emptyState();
    }
    if (_filtered.isEmpty) {
      return Center(child: Text(
          _query.isEmpty
              ? 'Suche nach einer Entität.'
              : 'Keine Treffer für "$_query" in dieser Quelle.',
          style: const TextStyle(color: Colors.white54, fontSize: 13)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _hitCard(_filtered[i]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_rounded, color: _accent.withValues(alpha: 0.4), size: 80),
          const SizedBox(height: 16),
          const Text('Suche eine Person oder Firma',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Alle Treffer aus OpenSanctions + 6 Leak-Datenbanken parallel',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
              children: ['Putin', 'BlackRock', 'Saudi-Arabien', 'Klaus Schwab']
                  .map((s) => OutlinedButton(
                        onPressed: () { _searchCtrl.text = s; _search(); },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: _accent.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 11)),
                      ))
                  .toList()),
        ]),
      ),
    );
  }

  Widget _hitCard(PowerNetworkHit h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetail(h),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: h.riskScore >= 0.8
                    ? _primary.withValues(alpha: 0.6)
                    : Colors.white12,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _riskBadge(h.riskScore),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.name,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (h.country != null || h.schema != null) ...[
                      const SizedBox(height: 2),
                      Text([h.schema, h.country].whereType<String>().join(' · '),
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ]),
                ),
                if (_watchlist.contains('${h.id}|${h.name}'))
                  const Icon(Icons.bookmark_rounded, color: _gold, size: 16),
              ]),
              if (h.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 4, runSpacing: 4,
                    children: h.tags.take(4).map((t) => _chip(t, _primary)).toList()),
              ],
              const SizedBox(height: 4),
              Text(h.sourceLabel,
                  style: TextStyle(color: _accent.withValues(alpha: 0.9), fontSize: 10, letterSpacing: 1)),
            ]),
          ),
        ),
      ),
    );
  }

  void _showWatchlist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12081E),
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
            const Text('WATCHLIST',
                style: TextStyle(color: _gold, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ..._watchlist.map((key) {
              final parts = key.split('|');
              final id = parts[0];
              final name = parts.length > 1 ? parts.sublist(1).join('|') : id;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  Icon(id.startsWith('os:') ? Icons.gavel : Icons.folder_zip,
                      color: _accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name,
                      style: const TextStyle(color: Colors.white, fontSize: 12))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      setState(() => _watchlist.remove(key));
                      await _persistWatchlist();
                      Navigator.pop(ctx);
                      _showWatchlist();
                    },
                  ),
                ]),
              );
            }),
            if (_watchlist.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Watchlist ist leer.\nTippe auf 🔖 in der Detail-Ansicht um Entitäten zu beobachten.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

class _PnOrbsPainter extends CustomPainter {
  final double t;
  _PnOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.18, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFFE53935));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100, const Color(0xFF7C4DFF));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        80, const Color(0xFFFFD54F));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_PnOrbsPainter old) => old.t != t;
}
