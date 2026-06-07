// 🕰️ VERSIONS-WÄCHTER · Internet Archive Wayback mit Diff-Visualisierung
//
// URL eingeben → Liste aller Snapshots (digest-dedupliziert) → 2 wählen →
// Text-Diff (Hinzufügungen grün, Löschungen rot).
// Watchlist mit URL + letztem-bekannten-digest, manueller Refresh zeigt
// ob neue Version vorliegt.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/version_watcher_service.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class VersionWatcherScreen extends StatefulWidget {
  const VersionWatcherScreen({super.key});

  @override
  State<VersionWatcherScreen> createState() => _VersionWatcherScreenState();
}

class _VersionWatcherScreenState extends State<VersionWatcherScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF0F0608);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFFFF7043);
  static const Color _accent = Color(0xFFFFD54F);
  static const Color _removed = Color(0xFFE53935);
  static const Color _added = Color(0xFF66BB6A);
  static const String _kWatchKey = 'version_watch_v1';

  final _urlCtrl = TextEditingController();
  final _service = VersionWatcherService();
  List<WaybackSnapshot> _snaps = [];
  WaybackSnapshot? _selectedA;
  WaybackSnapshot? _selectedB;
  List<DiffLine>? _diff;
  bool _loadingSnaps = false;
  bool _loadingDiff = false;
  String? _error;
  String _currentUrl = '';
  Map<String, String> _watchlist = {}; // url → lastKnownDigest

  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _loadWatchlist();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWatchKey);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _watchlist = m.map((k, v) => MapEntry(k, v.toString()));
      } catch (e) { if (kDebugMode) debugPrint('version_watcher_screen: silent catch -> $e'); }
    }
    if (mounted) setState(() {});
  }

  Future<void> _persistWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWatchKey, jsonEncode(_watchlist));
  }

  Future<void> _toggleWatch() async {
    HapticFeedback.selectionClick();
    if (_currentUrl.isEmpty) return;
    setState(() {
      if (_watchlist.containsKey(_currentUrl)) {
        _watchlist.remove(_currentUrl);
      } else {
        final latest = _snaps.isNotEmpty ? _snaps.first.digest : '';
        _watchlist[_currentUrl] = latest;
      }
    });
    await _persistWatchlist();
  }

  Future<void> _search() async {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    HapticFeedback.mediumImpact();
    setState(() {
      _loadingSnaps = true;
      _error = null;
      _snaps = [];
      _selectedA = null;
      _selectedB = null;
      _diff = null;
      _currentUrl = url;
    });
    try {
      final snaps = await _service.getSnapshots(url, limit: 100);
      if (mounted) {
        setState(() {
          _snaps = snaps;
          _loadingSnaps = false;
        });
        if (snaps.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Keine Snapshots für diese URL gefunden.'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loadingSnaps = false;
        });
      }
    }
  }

  void _toggleSelect(WaybackSnapshot s) {
    HapticFeedback.selectionClick();
    setState(() {
      _diff = null;
      if (_selectedA?.timestamp == s.timestamp) {
        _selectedA = null;
      } else if (_selectedB?.timestamp == s.timestamp) {
        _selectedB = null;
      } else if (_selectedA == null) {
        _selectedA = s;
      } else if (_selectedB == null) {
        _selectedB = s;
      } else {
        _selectedA = s;
        _selectedB = null;
      }
    });
  }

  Future<void> _runDiff() async {
    if (_selectedA == null || _selectedB == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _loadingDiff = true);
    try {
      // Sortiere: alt → neu
      final older = _selectedA!.timestamp.compareTo(_selectedB!.timestamp) < 0
          ? _selectedA!
          : _selectedB!;
      final newer = _selectedA!.timestamp.compareTo(_selectedB!.timestamp) < 0
          ? _selectedB!
          : _selectedA!;
      final results = await Future.wait([
        _service.getSnapshotText(older),
        _service.getSnapshotText(newer),
      ]);
      final oldText = results[0] ?? '';
      final newText = results[1] ?? '';
      if (oldText.isEmpty && newText.isEmpty) {
        if (mounted) {
          setState(() {
            _loadingDiff = false;
            _error = 'Konnte Snapshot-Inhalt nicht laden.';
          });
        }
        return;
      }
      final d = _service.diff(oldText, newText);
      if (mounted) {
        setState(() {
          _diff = d;
          _loadingDiff = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loadingDiff = false;
        });
      }
    }
  }

  Future<void> _openExternal(String url) async {
    final ok =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Konnte $url nicht öffnen'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWatched =
        _currentUrl.isNotEmpty && _watchlist.containsKey(_currentUrl);
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_accent, _primary],
          ).createShader(r),
          child: const Text('VERSIONS-WÄCHTER',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
        ),
        actions: [
          if (_currentUrl.isNotEmpty)
            IconButton(
              icon: Icon(
                  isWatched
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: isWatched ? _accent : Colors.white70),
              tooltip: isWatched ? 'Beobachtung aus' : 'URL beobachten',
              onPressed: _toggleWatch,
            ),
          if (_watchlist.isNotEmpty)
            Stack(clipBehavior: Clip.none, children: [
              IconButton(
                icon: const Icon(Icons.list_alt_rounded, color: _accent),
                tooltip: 'Watchlist',
                onPressed: _showWatchlist,
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                      color: _primary, borderRadius: BorderRadius.circular(8)),
                  child: Text('${_watchlist.length}',
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
              colors: [Color(0x55BF360C), Color(0x33260C08), _bgDark],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _VwOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.materie, count: 30)),
        SafeArea(
          child: Column(children: [
            _urlBar(),
            if (_selectedA != null || _selectedB != null) _selectionBar(),
            Expanded(child: _body()),
          ]),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _urlBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
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
                controller: _urlCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                keyboardType: TextInputType.url,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'URL eingeben (z.B. cdc.gov/covid)',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  prefixIcon:
                      const Icon(Icons.public_rounded, color: Colors.white60),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadingSnaps ? null : _search,
                  icon: _loadingSnaps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.history_rounded, size: 18),
                  label: Text(
                      _loadingSnaps
                          ? 'Lade Wayback-Snapshots…'
                          : 'WAYBACK-VERLAUF LADEN',
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

  Widget _selectionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedA != null ? 'A: ${_selectedA!.fmtDate}' : 'A: —',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
              Text(_selectedB != null ? 'B: ${_selectedB!.fmtDate}' : 'B: —',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
          if (_selectedA != null && _selectedB != null)
            ElevatedButton.icon(
              onPressed: _loadingDiff ? null : _runDiff,
              icon: _loadingDiff
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.compare_rounded, size: 16),
              label: Text(_loadingDiff ? 'Diff…' : 'DIFF',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ]),
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
    if (_diff != null) return _diffView();
    if (_snaps.isEmpty) return _emptyState();
    return _snapsList();
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_rounded,
              color: _primary.withValues(alpha: 0.4), size: 80),
          const SizedBox(height: 16),
          const Text('URL eingeben um Wayback-Verlauf zu sehen',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text(
              'Vergleicht beliebige zwei Snapshots zeigt was geändert/gelöscht wurde',
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
                'cdc.gov/coronavirus',
                'wikipedia.org/wiki/Klimawandel',
                'rki.de'
              ]
                  .map((s) => OutlinedButton(
                        onPressed: () {
                          _urlCtrl.text = s;
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

  Widget _snapsList() {
    // Group by year-month
    final byMonth = <String, List<WaybackSnapshot>>{};
    for (final s in _snaps) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(s);
    }
    final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(children: [
            Icon(Icons.archive_rounded, color: _accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text('${_snaps.length} unique Snapshots',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            if (_currentUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded,
                    color: Colors.white54, size: 16),
                tooltip: 'Live öffnen',
                onPressed: () => _openExternal(_currentUrl),
              ),
          ]),
        ),
        for (final k in keys) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(_monthLabel(k),
                style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
          ),
          ...byMonth[k]!.map(_snapTile),
        ],
      ],
    );
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez'
    ];
    final mi = int.tryParse(parts[1]);
    return mi != null && mi >= 1 && mi <= 12
        ? '${months[mi - 1]} ${parts[0]}'
        : key;
  }

  Widget _snapTile(WaybackSnapshot s) {
    final isA = _selectedA?.timestamp == s.timestamp;
    final isB = _selectedB?.timestamp == s.timestamp;
    final selected = isA || isB;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _toggleSelect(s),
          onLongPress: () => _openExternal(s.viewUrl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? _primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? _primary : Colors.white12),
            ),
            child: Row(children: [
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                      child: Text(isA ? 'A' : 'B',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))),
                ),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.fmtDate,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Text(
                          '${s.mimeType} · ${(s.length / 1024).toStringAsFixed(1)}KB · HTTP ${s.statusCode}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10)),
                    ]),
              ),
              Icon(Icons.open_in_new_rounded, color: Colors.white24, size: 14),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _diffView() {
    final removed = _diff!.where((d) => d.kind == -1).toList();
    final added = _diff!.where((d) => d.kind == 1).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(children: [
            Icon(Icons.compare_rounded, color: _accent, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    '${removed.length} entfernt · ${added.length} hinzugefügt',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white54, size: 16),
              onPressed: () => setState(() => _diff = null),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        if (removed.isNotEmpty) ...[
          const Text('🔴 ENTFERNT',
              style: TextStyle(
                  color: _removed,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...removed.take(50).map((d) => _diffLine(d, _removed)),
          if (removed.length > 50)
            Text('... +${removed.length - 50} weitere entfernte Zeilen',
                style: TextStyle(
                    color: _removed.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
          const SizedBox(height: 14),
        ],
        if (added.isNotEmpty) ...[
          const Text('🟢 HINZUGEFÜGT',
              style: TextStyle(
                  color: _added,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...added.take(50).map((d) => _diffLine(d, _added)),
          if (added.length > 50)
            Text('... +${added.length - 50} weitere hinzugefügte Zeilen',
                style: TextStyle(
                    color: _added.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _diffLine(DiffLine d, Color color) {
    final prefix = d.kind == -1 ? '−' : '+';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(prefix,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(d.text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, height: 1.4)),
          ),
        ]),
      ),
    );
  }

  void _showWatchlist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
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
            Text('WATCHLIST · ${_watchlist.length}',
                style: const TextStyle(
                    color: _accent,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ..._watchlist.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(e.key,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: _primary, size: 16),
                            tooltip: 'Prüfen',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _urlCtrl.text = e.key;
                              _search();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 16),
                            onPressed: () async {
                              setState(() => _watchlist.remove(e.key));
                              await _persistWatchlist();
                              Navigator.pop(ctx);
                              _showWatchlist();
                            },
                          ),
                        ]),
                        Text(
                            'Last digest: ${e.value.substring(0, math.min(12, e.value.length))}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9)),
                      ]),
                )),
          ],
        ),
      ),
    );
  }
}

class _VwOrbsPainter extends CustomPainter {
  final double t;
  _VwOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(
        canvas,
        Offset(size.width * 0.18,
            size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110,
        const Color(0xFFFF7043));
    _draw(
        canvas,
        Offset(size.width * 0.85,
            size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        100,
        const Color(0xFFFFD54F));
    _draw(
        canvas,
        Offset(size.width * 0.5,
            size.height * (0.92 + math.sin(t * math.pi) * 0.03)),
        75,
        const Color(0xFFE53935));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_VwOrbsPainter old) => old.t != t;
}
