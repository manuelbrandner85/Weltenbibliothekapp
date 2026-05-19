// Chakra-Verlaufs-Screen: Liest gespeicherte Scans aus SharedPrefs
// 'chakra_scans_v1' und zeigt Liste + Trend-Chart + Vergleichs-Modus.
// Bereich E2 -- erweitert chakra_scan_screen.dart.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';
import '../../theme/wb_cinematic_tokens.dart';

class _ChakraScanEntry {
  final DateTime ts;
  final Map<String, double> scores; // chakraName -> 0..1
  const _ChakraScanEntry({required this.ts, required this.scores});

  factory _ChakraScanEntry.fromJson(Map<String, dynamic> j) {
    final raw = (j['scores'] as Map?) ?? {};
    return _ChakraScanEntry(
      ts: DateTime.tryParse(j['ts'] as String? ?? '') ?? DateTime.now(),
      scores: raw.map(
          (k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.5)),
    );
  }
}

class ChakraHistoryScreen extends StatefulWidget {
  const ChakraHistoryScreen({super.key});

  @override
  State<ChakraHistoryScreen> createState() => _ChakraHistoryScreenState();
}

class _ChakraHistoryScreenState extends State<ChakraHistoryScreen> {
  List<_ChakraScanEntry> _scans = [];
  bool _loading = true;
  _ChakraScanEntry? _compareA;
  _ChakraScanEntry? _compareB;

  static const _chakraOrder = [
    'Wurzel-Chakra',
    'Sakral-Chakra',
    'Solarplexus-Chakra',
    'Herz-Chakra',
    'Hals-Chakra',
    'Stirn-Chakra',
    'Kronen-Chakra',
  ];

  static const _chakraColors = {
    'Wurzel-Chakra': Color(0xFFE53935),
    'Sakral-Chakra': Color(0xFFFF6D00),
    'Solarplexus-Chakra': Color(0xFFFFD600),
    'Herz-Chakra': Color(0xFF43A047),
    'Hals-Chakra': Color(0xFF1E88E5),
    'Stirn-Chakra': Color(0xFF5E35B1),
    'Kronen-Chakra': Color(0xFF8E24AA),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('chakra_scans_v1') ?? <String>[];
      final entries = list
          .map((s) {
            try {
              return _ChakraScanEntry.fromJson(
                  jsonDecode(s) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<_ChakraScanEntry>()
          .toList();
      if (!mounted) return;
      setState(() {
        _scans = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06040F),
      extendBodyBehindAppBar: true,
      appBar: const WBGlassAppBar(
        title: 'Chakra-Verlauf',
        world: WBWorld.energie,
      ),
      body: Stack(
        children: [
          const IgnorePointer(
            child: WBAmbientParticles(world: WBWorld.energie, count: 22),
          ),
          const WBVignette(),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _scans.isEmpty
                    ? _emptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
                        children: [
                          _statsHeader(),
                          const SizedBox(height: 14),
                          _trendChart(),
                          const SizedBox(height: 14),
                          if (_compareA != null && _compareB != null) ...[
                            _compareCard(),
                            const SizedBox(height: 14),
                          ],
                          _scanList(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded,
                size: 80, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 18),
            const Text(
              'Noch keine Chakra-Scans.\nMache deinen ersten Scan!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(children: [
              Text('${_scans.length}',
                  style: const TextStyle(
                      color: Color(0xFFCE93D8),
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              const Text('Scans',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          Expanded(
            child: Column(children: [
              Text(_avgScoreText(),
                  style: const TextStyle(
                      color: Color(0xFFCE93D8),
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              const Text('Durchschnitt',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          Expanded(
            child: Column(children: [
              Text(_strongestChakra(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFCE93D8),
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const Text('Staerkstes',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }

  String _avgScoreText() {
    if (_scans.isEmpty) return '-';
    double total = 0;
    int count = 0;
    for (final s in _scans) {
      for (final v in s.scores.values) {
        total += v;
        count++;
      }
    }
    if (count == 0) return '-';
    return '${((total / count) * 100).toStringAsFixed(0)}%';
  }

  String _strongestChakra() {
    if (_scans.isEmpty) return '-';
    final avg = <String, double>{};
    final cnt = <String, int>{};
    for (final s in _scans) {
      s.scores.forEach((k, v) {
        avg[k] = (avg[k] ?? 0) + v;
        cnt[k] = (cnt[k] ?? 0) + 1;
      });
    }
    String best = '';
    double bestVal = -1;
    avg.forEach((k, total) {
      final n = cnt[k] ?? 1;
      final v = total / n;
      if (v > bestVal) {
        bestVal = v;
        best = k;
      }
    });
    return best.split('-').first;
  }

  Widget _trendChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TREND (letzte Scans)',
              style: TextStyle(
                  color: Color(0xFFCE93D8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TrendChartPainter(
                scans: _scans.reversed.take(20).toList().reversed.toList(),
                chakraOrder: _chakraOrder,
                colors: _chakraColors,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _chakraOrder
                .map((c) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _chakraColors[c],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(c.split('-').first,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 9)),
                        const SizedBox(width: 4),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _compareCard() {
    final a = _compareA!;
    final b = _compareB!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('VERGLEICH',
                style: TextStyle(
                    color: Color(0xFFCE93D8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white60, size: 18),
              onPressed: () => setState(() {
                _compareA = null;
                _compareB = null;
              }),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 8),
          Text('${_fmt(a.ts)}  vs.  ${_fmt(b.ts)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          ..._chakraOrder.map((c) {
            final va = a.scores[c] ?? 0.0;
            final vb = b.scores[c] ?? 0.0;
            final diff = vb - va;
            IconData icon;
            Color iconCol;
            if (diff > 0.05) {
              icon = Icons.arrow_upward_rounded;
              iconCol = Colors.greenAccent;
            } else if (diff < -0.05) {
              icon = Icons.arrow_downward_rounded;
              iconCol = Colors.redAccent;
            } else {
              icon = Icons.remove_rounded;
              iconCol = Colors.white54;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _chakraColors[c],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.split('-').first,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                Text('${(va * 100).toInt()}%',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(width: 8),
                Icon(icon, color: iconCol, size: 14),
                const SizedBox(width: 8),
                Text('${(vb * 100).toInt()}%',
                    style: TextStyle(
                        color: iconCol,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _scanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ALLE SCANS',
            style: TextStyle(
                color: Color(0xFFCE93D8),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2)),
        const SizedBox(height: 8),
        ..._scans.map((s) {
          final isA = _compareA == s;
          final isB = _compareB == s;
          final selected = isA || isB;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _toggleCompare(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF7C4DFF).withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected
                          ? const Color(0xFFCE93D8)
                          : Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(children: [
                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFCE93D8),
                      ),
                      child: Text(isA ? 'A' : 'B',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmt(s.ts),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Row(
                            children: _chakraOrder.map((c) {
                          final v = s.scores[c] ?? 0.0;
                          return Expanded(
                            child: Container(
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: (_chakraColors[c] ?? Colors.white)
                                    .withValues(alpha: v.clamp(0.15, 1.0)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }).toList()),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _toggleCompare(_ChakraScanEntry s) {
    setState(() {
      if (_compareA == s) {
        _compareA = null;
      } else if (_compareB == s) {
        _compareB = null;
      } else if (_compareA == null) {
        _compareA = s;
      } else if (_compareB == null) {
        _compareB = s;
      } else {
        _compareA = s;
        _compareB = null;
      }
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _TrendChartPainter extends CustomPainter {
  final List<_ChakraScanEntry> scans;
  final List<String> chakraOrder;
  final Map<String, Color> colors;

  _TrendChartPainter({
    required this.scans,
    required this.chakraOrder,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scans.length < 2) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Mindestens 2 Scans noetig.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }
    // Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.6;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Lines per Chakra
    final dx = scans.length > 1 ? size.width / (scans.length - 1) : 0.0;
    for (final c in chakraOrder) {
      final color = colors[c] ?? Colors.white;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.9)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      final path = Path();
      for (int i = 0; i < scans.length; i++) {
        final v = scans[i].scores[c] ?? 0.5;
        final x = i * dx;
        final y = size.height * (1.0 - v.clamp(0.0, 1.0));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        // Dot
        canvas.drawCircle(
          Offset(x, y),
          1.8,
          Paint()..color = color,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter old) =>
      old.scans.length != scans.length;
}
