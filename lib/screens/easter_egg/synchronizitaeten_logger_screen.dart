// 🔮 SYNCHRONIZITAETEN-LOGGER - Log + AI-Muster-Erkennung
//
// User loggt taegliche Synchronicity-Erlebnisse (Zahl, Tier, Begegnung, Traum).
// Bei 5+ Eintraegen: AI analysiert Cluster (welche Themen wiederholen sich).

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class SynchronizitaetenLoggerScreen extends StatefulWidget {
  const SynchronizitaetenLoggerScreen({super.key});
  @override
  State<SynchronizitaetenLoggerScreen> createState() => _SynchronizitaetenLoggerScreenState();
}

class _SynchronizitaetenLoggerScreenState extends State<SynchronizitaetenLoggerScreen>
    with TickerProviderStateMixin {
  static const _kKey = 'synchronizitaeten_v1';
  static const Color _bg = Color(0xFF0A0512);
  static const Color _primary = Color(0xFFEC407A);
  static const Color _gold = Color(0xFFFFD700);

  static const _cats = [
    _SyncCat('numbers', '🔢 Zahlen-Muster', Color(0xFF26C6DA)),
    _SyncCat('animals', '🦅 Tier-Begegnung', Color(0xFF66BB6A)),
    _SyncCat('meeting', '👋 Begegnung', Color(0xFFFFA726)),
    _SyncCat('dream', '🌙 Traum→Realität', Color(0xFF7C4DFF)),
    _SyncCat('coincidence', '🎯 Zufall mit Sinn', Color(0xFFEC407A)),
    _SyncCat('sign', '🪧 Zeichen', Color(0xFFFFD700)),
  ];

  List<_SyncEntry> _entries = [];
  _SyncCat _selectedCat = _cats.first;
  final _noteCtrl = TextEditingController();
  String? _aiInsight;
  bool _loading = true, _loadingAi = false;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _load();
  }

  @override
  void dispose() { _noteCtrl.dispose(); _ambientCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _entries = (prefs.getStringList(_kKey) ?? const [])
        .map((s) { try { return _SyncEntry.fromJson(jsonDecode(s) as Map<String, dynamic>); } catch (_) { return null; } })
        .whereType<_SyncEntry>()
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    _entries.insert(0, _SyncEntry(
      category: _selectedCat.code,
      note: _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _entries.take(200).map((e) => jsonEncode(e.toJson())).toList());
    _noteCtrl.clear();
    setState(() {});
  }

  Future<void> _analyzePattern() async {
    if (_entries.length < 5) return;
    HapticFeedback.mediumImpact();
    setState(() => _loadingAi = true);
    try {
      final last30 = _entries.take(30).map((e) {
        final cat = _cats.firstWhere((c) => c.code == e.category, orElse: () => _cats.first);
        return '${e.createdAt.toIso8601String().substring(0,10)} ${cat.label}: ${e.note}';
      }).join('\n');
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
        headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'personality': 'alchemist',
          'message': 'Analysiere diese Synchronizitäten-Einträge auf Muster (Themen, '
              'wiederkehrende Symbole, Zeitpunkte). Was zeigt sich? Welche Botschaft? '
              '3-4 Absätze, du-Form.\n\n$last30',
          'world': 'energie',
          'conversationHistory': [],
        }),
      ).timeout(const Duration(seconds: 35));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final txt = ((d['reply'] ?? d['answer'] ?? d['response'] ?? d['message'] ?? '') as String).trim();
        if (mounted) setState(() { _aiInsight = txt; _loadingAi = false; });
      } else {
        if (mounted) setState(() { _aiInsight = '⚠️ AI HTTP ${res.statusCode}'; _loadingAi = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _aiInsight = '⚠️ $e'; _loadingAi = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: _bg, body: Center(child: CircularProgressIndicator(color: _primary)));
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_gold, _primary]).createShader(r),
          child: const Text('SYNCHRONIZITÄTEN',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(decoration: const BoxDecoration(gradient: RadialGradient(
          center: Alignment.center, radius: 1.5,
          colors: [Color(0x55880E4F), Color(0x33360A2E), _bg]))),
        IgnorePointer(child: AnimatedBuilder(animation: _ambientCtrl, builder: (_, __) =>
            CustomPaint(painter: _SyncOrbsPainter(_ambientCtrl.value), size: Size.infinite))),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 40)),
        SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 28), children: [
          // Composer
          ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NEUE SYNCHRONIZITÄT',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 5, runSpacing: 5, children: _cats.map((c) {
                  final sel = c.code == _selectedCat.code;
                  return GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCat = c); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? c.color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? c.color : Colors.transparent),
                      ),
                      child: Text(c.label, style: TextStyle(color: sel ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3, maxLength: 400,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Was war die Synchronizität?',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    counterStyle: const TextStyle(color: Colors.white24, fontSize: 9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('LOGGEN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                  ),
                ),
              ]),
            ),
          )),
          const SizedBox(height: 14),
          if (_entries.length >= 5) ...[
            ElevatedButton.icon(
              onPressed: _loadingAi ? null : _analyzePattern,
              icon: _loadingAi
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.insights_rounded),
              label: Text(_loadingAi ? 'Alchemist sucht Muster…' : 'MUSTER-ANALYSE (AI)',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            const SizedBox(height: 10),
            if (_aiInsight != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ALCHEMIST · MUSTER',
                      style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SelectableText(_aiInsight!, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
                ]),
              ),
            const SizedBox(height: 14),
          ],
          if (_entries.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('Noch keine Eintraege.', style: TextStyle(color: Colors.white54))))
          else ..._entries.take(30).map((e) {
            final c = _cats.firstWhere((x) => x.code == e.category, orElse: () => _cats.first);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.color.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.label, style: TextStyle(color: c.color, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_fmt(e.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ]),
                const SizedBox(height: 4),
                Text(e.note, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
              ]),
            );
          }),
        ])),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inHours < 1) return 'vor ${d.inMinutes}m';
    if (d.inDays < 1) return 'vor ${d.inHours}h';
    return '${dt.day}.${dt.month}.';
  }
}

class _SyncCat {
  final String code, label;
  final Color color;
  const _SyncCat(this.code, this.label, this.color);
}

class _SyncEntry {
  final String category, note;
  final DateTime createdAt;
  const _SyncEntry({required this.category, required this.note, required this.createdAt});
  Map<String, dynamic> toJson() => {'category': category, 'note': note, 'created': createdAt.toIso8601String()};
  factory _SyncEntry.fromJson(Map<String, dynamic> j) => _SyncEntry(
    category: j['category'] as String? ?? 'sign',
    note: j['note'] as String? ?? '',
    createdAt: DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
  );
}

class _SyncOrbsPainter extends CustomPainter {
  final double t;
  _SyncOrbsPainter(this.t);
  @override void paint(Canvas canvas, Size size) {
    _d(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)), 100, const Color(0xFFEC407A));
    _d(canvas, Offset(size.width * 0.85, size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)), 90, const Color(0xFFFFD700));
  }
  void _d(Canvas c, Offset o, double r, Color col) {
    c.drawCircle(o, r, Paint()..color = col.withValues(alpha: 0.1)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));
  }
  @override bool shouldRepaint(_SyncOrbsPainter o) => o.t != t;
}
