// ⏳ TIME-CAPSULE - Nachricht an dich selbst in 1/3/6/12 Monaten
//
// Lokal in SharedPreferences. Bei jedem App-Start checkt der UpdateGate (zukuenftig)
// ob heute eine Capsule "reift" - dann erscheint sie als Popup.
// MVP: nur Liste der ausstehenden + gereiften Capsules.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key});
  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen>
    with TickerProviderStateMixin {
  static const _kKey = 'time_capsules_v1';
  static const Color _bgDark = Color(0xFF03081C);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFF42A5F5);
  static const Color _gold = Color(0xFFFFD700);

  List<_Capsule> _capsules = [];
  bool _loading = true;
  final _msgCtrl = TextEditingController();
  int _months = 3;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _capsules = (prefs.getStringList(_kKey) ?? const [])
        .map((s) {
          try {
            return _Capsule.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<_Capsule>()
        .toList()
      ..sort((a, b) => a.openAt.compareTo(b.openAt));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    _capsules.add(_Capsule(
      id: '${now.millisecondsSinceEpoch}',
      message: _msgCtrl.text.trim(),
      sealedAt: now,
      openAt: DateTime(now.year, now.month + _months, now.day, now.hour),
      opened: false,
    ));
    _capsules.sort((a, b) => a.openAt.compareTo(b.openAt));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kKey, _capsules.map((c) => jsonEncode(c.toJson())).toList());
    _msgCtrl.clear();
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('⏳ Versiegelt. Öffnet sich am ${_fmt(_capsules.last.openAt)}'),
      backgroundColor: _primary,
    ));
  }

  Future<void> _open(_Capsule c) async {
    if (DateTime.now().isBefore(c.openAt)) return;
    HapticFeedback.heavyImpact();
    final idx = _capsules.indexWhere((x) => x.id == c.id);
    if (idx < 0) return;
    _capsules[idx] = _Capsule(
      id: c.id,
      message: c.message,
      sealedAt: c.sealedAt,
      openAt: c.openAt,
      opened: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kKey, _capsules.map((x) => jsonEncode(x.toJson())).toList());
    setState(() {});
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF0F1E33),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.mark_email_read_rounded, color: _gold),
                SizedBox(width: 8),
                Text('NACHRICHT VON FRÜHER',
                    style: TextStyle(
                        color: _gold, fontSize: 13, letterSpacing: 2)),
              ]),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Versiegelt am ${_fmt(c.sealedAt)} (vor ${DateTime.now().difference(c.sealedAt).inDays}d)',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 14),
                    Text(c.message,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, height: 1.6)),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Schließen',
                        style: TextStyle(color: _primary)))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
          backgroundColor: _bg(context),
          body: Center(child: CircularProgressIndicator(color: _primary)));
    }
    final ripe = _capsules
        .where((c) => !c.opened && DateTime.now().isAfter(c.openAt))
        .toList();
    final pending = _capsules
        .where((c) => !c.opened && DateTime.now().isBefore(c.openAt))
        .toList();
    final opened = _capsules.where((c) => c.opened).toList();
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) =>
              const LinearGradient(colors: [_gold, _primary]).createShader(r),
          child: const Text('TIME-CAPSULE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
            decoration: const BoxDecoration(
                gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [Color(0x550D47A1), Color(0x33082E5C), _bgDark]))),
        IgnorePointer(
            child: AnimatedBuilder(
                animation: _ambientCtrl,
                builder: (_, __) => CustomPaint(
                    painter: _TcOrbsPainter(_ambientCtrl.value),
                    size: Size.infinite))),
        const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.neutral, count: 40)),
        SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                children: [
              // Composer
              ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: _primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NACHRICHT AN DICH SELBST',
                                style: TextStyle(
                                    color: _gold,
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _msgCtrl,
                              maxLines: 4,
                              maxLength: 1000,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText:
                                    'Was möchtest du deinem zukünftigen Selbst sagen?',
                                hintStyle:
                                    const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                counterStyle: const TextStyle(
                                    color: Colors.white24, fontSize: 9),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                              ),
                            ),
                            Row(children: [
                              const Text('Öffnen in:',
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 11)),
                              const SizedBox(width: 8),
                              ...[1, 3, 6, 12].map((m) {
                                final sel = m == _months;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _months = m);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? _primary.withValues(alpha: 0.3)
                                            : Colors.white
                                                .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: sel
                                                ? _primary
                                                : Colors.transparent),
                                      ),
                                      child: Text('${m}M',
                                          style: TextStyle(
                                              color: sel
                                                  ? Colors.white
                                                  : Colors.white60,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                );
                              }),
                            ]),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _create,
                                icon: const Icon(Icons.lock_clock_rounded,
                                    size: 16),
                                label: const Text('VERSIEGELN',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ]),
                    ),
                  )),
              if (ripe.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('🔓 BEREIT ZUM ÖFFNEN',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...ripe.map((c) => _capsuleCard(c, ripe: true)),
              ],
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('⏳ VERSIEGELT (${pending.length})',
                    style: TextStyle(
                        color: _primary.withValues(alpha: 0.8),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...pending.map((c) => _capsuleCard(c, ripe: false)),
              ],
              if (opened.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('📂 GEÖFFNET (${opened.length})',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...opened
                    .map((c) => _capsuleCard(c, ripe: false, opened: true)),
              ],
            ])),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _capsuleCard(_Capsule c, {required bool ripe, bool opened = false}) {
    final daysLeft = c.openAt.difference(DateTime.now()).inDays;
    final col = ripe ? _gold : (opened ? Colors.white24 : _primary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: ripe ? () => _open(c) : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: col.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(
                    ripe
                        ? Icons.mark_email_unread_rounded
                        : (opened ? Icons.drafts_rounded : Icons.lock_rounded),
                    color: col,
                    size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            opened
                                ? c.message
                                : (ripe
                                    ? 'BEREIT — Tippe zum Öffnen'
                                    : 'Versiegelte Nachricht'),
                            style: TextStyle(
                                color: opened ? Colors.white60 : col,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                            ripe
                                ? 'fällig: ${_fmt(c.openAt)}'
                                : opened
                                    ? 'geöffnet am ${_fmt(c.openAt)}'
                                    : 'öffnet in ${daysLeft}d (${_fmt(c.openAt)})',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                      ]),
                ),
              ]),
            ),
          )),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class _Capsule {
  final String id, message;
  final DateTime sealedAt, openAt;
  final bool opened;
  const _Capsule(
      {required this.id,
      required this.message,
      required this.sealedAt,
      required this.openAt,
      required this.opened});
  Map<String, dynamic> toJson() => {
        'id': id,
        'msg': message,
        'sealed': sealedAt.toIso8601String(),
        'open': openAt.toIso8601String(),
        'opened': opened
      };
  factory _Capsule.fromJson(Map<String, dynamic> j) => _Capsule(
        id: j['id'] as String? ?? '',
        message: j['msg'] as String? ?? '',
        sealedAt:
            DateTime.tryParse(j['sealed'] as String? ?? '') ?? DateTime.now(),
        openAt: DateTime.tryParse(j['open'] as String? ?? '') ?? DateTime.now(),
        opened: (j['opened'] as bool?) ?? false,
      );
}

class _TcOrbsPainter extends CustomPainter {
  final double t;
  _TcOrbsPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    _d(
        canvas,
        Offset(size.width * 0.2,
            size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100,
        const Color(0xFF42A5F5));
    _d(
        canvas,
        Offset(size.width * 0.85,
            size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)),
        90,
        const Color(0xFFFFD700));
  }

  void _d(Canvas c, Offset o, double r, Color col) {
    c.drawCircle(
        o,
        r,
        Paint()
          ..color = col.withValues(alpha: 0.1)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));
  }

  @override
  bool shouldRepaint(_TcOrbsPainter o) => o.t != t;
}
