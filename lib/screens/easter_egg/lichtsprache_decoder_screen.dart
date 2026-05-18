// 🔤 LICHTSPRACHE-DECODER - Heilige-Geometrie-Symbole sequenzieren, AI deutet
//
// User waehlt aus 12 Symbolen eine Sequenz (max 7), AI deutet via /api/mentor/chat.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../../widgets/cinematic/wb_ambient_particles.dart';
import '../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../widgets/cinematic/wb_vignette.dart';

class LichtspracheDecoderScreen extends StatefulWidget {
  const LichtspracheDecoderScreen({super.key});

  @override
  State<LichtspracheDecoderScreen> createState() => _LichtspracheDecoderScreenState();
}

class _LichtspracheDecoderScreenState extends State<LichtspracheDecoderScreen>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0A0414);
  static const Color _gold = Color(0xFFFFD700);
  static const Color _primary = Color(0xFF7C4DFF);

  static const _symbols = [
    _Symbol('🔯', 'Hexagramm', 'Vereinigung Himmel-Erde'),
    _Symbol('☉', 'Sonne', 'Bewusstsein · Selbst'),
    _Symbol('☽', 'Mond', 'Unbewusstes · Intuition'),
    _Symbol('✶', 'Vesica', 'Schnittfläche · Begegnung'),
    _Symbol('❀', 'Flower', 'Lebensblume · Matrix'),
    _Symbol('△', 'Triangle', 'Trinität · Aufstieg'),
    _Symbol('◯', 'Kreis', 'Ganzheit · ohne Anfang'),
    _Symbol('✦', 'Stern', 'Hoffnung · Wegweisung'),
    _Symbol('♾', 'Unendlich', 'ewiger Fluss'),
    _Symbol('☯', 'Tao', 'Polarität · Balance'),
    _Symbol('⚡', 'Blitz', 'Erkenntnis · Durchbruch'),
    _Symbol('✸', 'Sigil', 'Manifestation · Wille'),
  ];

  final List<_Symbol> _seq = [];
  String? _reading;
  bool _loading = false;
  late final AnimationController _ambientCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() { _ambientCtrl.dispose(); super.dispose(); }

  Future<void> _decode() async {
    if (_seq.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() { _loading = true; _reading = null; });
    try {
      final seqText = _seq.map((s) => '${s.glyph} ${s.name} (${s.meaning})').join(' → ');
      final prompt = 'Deute diese Lichtsprache-Sequenz spirituell:\n$seqText\n\n'
          'Was ist die Botschaft? 3-4 Sätze, du-Form, ohne Disclaimer.';
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http.post(
        Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
        headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
        body: jsonEncode({'personality': 'alchemist', 'message': prompt, 'world': 'energie', 'conversationHistory': []}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final txt = ((d['reply'] ?? d['answer'] ?? d['response'] ?? d['message'] ?? '') as String).trim();
        if (mounted) setState(() { _reading = txt; _loading = false; });
      } else {
        if (mounted) setState(() { _reading = '⚠️ AI HTTP ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _reading = '⚠️ $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.neutral,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [_gold, _primary]).createShader(r),
          child: const Text('LICHTSPRACHE',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3)),
        ),
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(decoration: const BoxDecoration(gradient: RadialGradient(
          center: Alignment.center, radius: 1.5,
          colors: [Color(0x553F1E8C), Color(0x331A0833), _bg]))),
        IgnorePointer(child: AnimatedBuilder(animation: _ambientCtrl, builder: (_, __) =>
            CustomPaint(painter: _LsOrbsPainter(_ambientCtrl.value), size: Size.infinite))),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.neutral, count: 50)),
        SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
          // Sequence
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              const Text('DEINE SEQUENZ (max 7)',
                  style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: _seq.isEmpty
                    ? const Center(child: Text('Tippe Symbole unten', style: TextStyle(color: Colors.white38)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: _seq.asMap().entries.map((e) => GestureDetector(
                          onTap: () { HapticFeedback.lightImpact(); setState(() => _seq.removeAt(e.key)); _reading = null; },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(e.value.glyph,
                                style: TextStyle(fontSize: 36, color: _gold, shadows: [
                                  Shadow(color: _gold.withValues(alpha: 0.5), blurRadius: 8)
                                ])),
                          ),
                        )).toList()),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          // Symbol picker
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.95),
            itemCount: _symbols.length,
            itemBuilder: (_, i) {
              final s = _symbols[i];
              return GestureDetector(
                onTap: _seq.length >= 7 ? null : () {
                  HapticFeedback.selectionClick();
                  setState(() { _seq.add(s); _reading = null; });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s.glyph, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 2),
                    Text(s.name, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                  ]),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if (_seq.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _loading ? null : _decode,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_loading ? 'Alchemist deutet...' : 'BOTSCHAFT DECODIEREN',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          if (_reading != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: 0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ALCHEMIST · BOTSCHAFT',
                    style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SelectableText(_reading!, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
              ]),
            ),
          ],
        ])),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }
}

class _Symbol {
  final String glyph;
  final String name;
  final String meaning;
  const _Symbol(this.glyph, this.name, this.meaning);
}

class _LsOrbsPainter extends CustomPainter {
  final double t;
  _LsOrbsPainter(this.t);
  @override void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        110, const Color(0xFFFFD700));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.6 + math.cos(t * 2 * math.pi) * 0.04)),
        100, const Color(0xFF7C4DFF));
  }
  void _draw(Canvas c, Offset o, double r, Color col) {
    c.drawCircle(o, r, Paint()..color = col.withValues(alpha: 0.1)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5));
  }
  @override bool shouldRepaint(_LsOrbsPainter o) => o.t != t;
}
