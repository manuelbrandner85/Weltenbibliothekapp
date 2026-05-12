import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 👁️ RV Trainer — Controlled Remote Viewing nach Ingo Swann
///
/// Stufen:
///   1. Ideogramm + Gestalt-Wörter
///   2. Sensorische Eindrücke (Farben, Texturen, Temperatur)
///   3. Sketch-Canvas (vereinfacht: Notizfeld + Reveal)
///   Reveal: zeigt echtes Target-Bild + Score (Match-Heuristik).
class RvTrainerScreen extends StatefulWidget {
  const RvTrainerScreen({super.key});

  @override
  State<RvTrainerScreen> createState() => _RvTrainerScreenState();
}

class _RvTrainerScreenState extends State<RvTrainerScreen> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _target;   // {id, target_number}
  Map<String, dynamic>? _revealed; // full target after reveal
  int _stage = 0; // 0=intro, 1=stage1, 2=stage2, 3=stage3, 4=reveal
  final _gestaltCtrl = TextEditingController();
  final _sensoryCtrl = TextEditingController();
  final _sketchCtrl = TextEditingController();
  int _score = 0;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  @override
  void dispose() {
    _gestaltCtrl.dispose();
    _sensoryCtrl.dispose();
    _sketchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTarget() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('rv_targets')
          .select('id,target_number')
          .limit(200);
      final list = (res as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) throw 'Keine RV-Targets in der Datenbank';
      list.shuffle();
      setState(() {
        _target = list.first;
        _stage = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _reveal() async {
    if (_target == null) return;
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('rv_targets')
          .select('*')
          .eq('id', _target!['id'])
          .limit(1);
      final list = (res as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) throw 'Target nicht gefunden';
      final t = list.first;

      // Simple match heuristic: count keyword overlap.
      final all = <String>{};
      for (final k
          in (t['gestalt_keywords'] as List? ?? const []).cast<String>()) {
        all.add(k.toLowerCase());
      }
      for (final k
          in (t['sensory_keywords'] as List? ?? const []).cast<String>()) {
        all.add(k.toLowerCase());
      }
      final response =
          ('${_gestaltCtrl.text} ${_sensoryCtrl.text} ${_sketchCtrl.text}')
              .toLowerCase();
      int hits = 0;
      for (final k in all) {
        if (k.length >= 3 && response.contains(k)) hits++;
      }
      final pct = all.isEmpty
          ? 0
          : ((hits / all.length) * 100).clamp(0, 100).round();

      setState(() {
        _revealed = t;
        _score = pct;
        _stage = 4;
        _loading = false;
      });

      try {
        final user = client.auth.currentUser;
        if (user != null && _target != null) {
          final secs = _startedAt == null
              ? null
              : DateTime.now().difference(_startedAt!).inSeconds;
          await client.from('rv_sessions').insert({
            'user_id': user.id,
            'target_id': _target!['id'],
            'stage1_response': {'gestalt': _gestaltCtrl.text.trim()},
            'stage2_response': {'sensory': _sensoryCtrl.text.trim()},
            'stage3_sketch_url': null, // text description only
            'score_percent': pct,
            'session_mode': 'training',
            'duration_seconds': secs,
          });
        }
      } catch (_) {/* non-fatal */}
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _next() {
    if (_stage == 0) {
      _startedAt = DateTime.now();
      setState(() => _stage = 1);
    } else if (_stage < 3) {
      setState(() => _stage++);
    } else {
      _reveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: const Text(
          'RV Trainer · CRV',
          style: TextStyle(color: _cyan, letterSpacing: 2.0, fontSize: 16),
        ),
        actions: [
          if (_stage == 4)
            IconButton(
              icon: const Icon(Icons.refresh, color: _cyan),
              onPressed: () {
                _gestaltCtrl.clear();
                _sensoryCtrl.clear();
                _sketchCtrl.clear();
                _revealed = null;
                _loadTarget();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : _buildStage(),
        ),
      ),
    );
  }

  Widget _buildStage() {
    if (_stage == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cyan.withValues(alpha: 0.30)),
              gradient: LinearGradient(
                colors: [
                  _cyan.withValues(alpha: 0.10),
                  _bgDeep,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TARGET',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.7),
                    letterSpacing: 4.0,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _target?['target_number']?.toString() ?? '????',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 8.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Blinde Zufalls-ID. Du weißt nichts über das Ziel. '
                  'Lass die Eindrücke kommen — nicht denken.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_red_eye,
                  size: 64,
                  color: _cyan.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Controlled Remote Viewing\n6-Stage-Protokoll · Ingo Swann',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: _bgDeep,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'SESSION STARTEN',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 3.0),
            ),
          ),
        ],
      );
    }

    if (_stage == 4) {
      final imageUrl = _revealed?['target_image_url'] as String?;
      final name = _revealed?['target_name'] as String? ?? '';
      final cat = _revealed?['target_category'] as String? ?? '';
      final desc = _revealed?['target_description'] as String? ?? '';
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cyan.withValues(alpha: 0.40)),
                gradient: LinearGradient(
                  colors: [
                    _cyan.withValues(alpha: 0.18),
                    _bgDeep,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'SCORE',
                    style: TextStyle(
                      color: _cyan.withValues(alpha: 0.7),
                      letterSpacing: 4.0,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_score%',
                    style: const TextStyle(
                      color: _cyan,
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.white.withValues(alpha: 0.05),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              cat,
              style: TextStyle(
                color: _cyan,
                fontSize: 12,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            _summary('Stufe 1 · Gestalt', _gestaltCtrl.text),
            _summary('Stufe 2 · Sensorisch', _sensoryCtrl.text),
            _summary('Stufe 3 · Skizze / Notiz', _sketchCtrl.text),
          ],
        ),
      );
    }

    final stageInfo = {
      1: const _StageInfo(
        'Stufe 1 · Ideogramm + Gestalt',
        'Erste spontane Eindrücke. Form, Größe, Material — kurze Worte.',
        'z.B. „groß, hart, vertikal, hell"',
      ),
      2: const _StageInfo(
        'Stufe 2 · Sensorisch',
        'Farben, Texturen, Temperatur, Geräusche, Gerüche.',
        'z.B. „warm, beige, sandig, leise, trocken"',
      ),
      3: const _StageInfo(
        'Stufe 3 · Skizze / Detail',
        'Beschreibe konkrete Details oder skizziere mit Worten.',
        'z.B. „dreieckige Form, drei in einer Reihe, Wüstenboden"',
      ),
    }[_stage]!;

    final ctrl = _stage == 1
        ? _gestaltCtrl
        : _stage == 2
            ? _sensoryCtrl
            : _sketchCtrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          stageInfo.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stageInfo.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(color: Colors.white, height: 1.5),
            decoration: InputDecoration(
              hintText: stageInfo.hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.30),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: _cyan.withValues(alpha: 0.20)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: _cyan.withValues(alpha: 0.20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _cyan.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyan,
            foregroundColor: _bgDeep,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _stage < 3 ? 'NÄCHSTE STUFE' : 'TARGET ENTHÜLLEN',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 3.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cyan.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _cyan.withValues(alpha: 0.7),
                fontSize: 10,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageInfo {
  final String title;
  final String description;
  final String hint;
  const _StageInfo(this.title, this.description, this.hint);
}
