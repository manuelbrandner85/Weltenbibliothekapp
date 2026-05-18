// 📸 VOR/NACH-FOTO TRANSFORMATION · Cinematic + AI-Reflexion
//
// Datierte Foto-Einträge mit Body/Mind/Soul-Tags. Side-by-Side-Vergleich
// auf Zeitachse mit AI-Reflexion über die Transformation zwischen den
// beiden gewählten Snapshots. image_picker für Aufnahme.

import 'dart:convert';
import 'dart:io' if (dart.library.html) '../../../stubs/dart_io_stub.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';
import '../../../widgets/local_file_image.dart';

// Result-Klasse statt Named-Record (dart2js stolpert über Named Records).
class _BodyMindSoulTags {
  final String body;
  final String mind;
  final String soul;
  const _BodyMindSoulTags(this.body, this.mind, this.soul);
}

class PhotoProgressScreen extends StatefulWidget {
  const PhotoProgressScreen({super.key});

  @override
  State<PhotoProgressScreen> createState() => _PhotoProgressScreenState();
}

class _PhotoProgressScreenState extends State<PhotoProgressScreen>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A0F0A);
  static const _accent = Color(0xFFF57C00);
  static const _gold = Color(0xFFFFD54F);
  static const _kvKey = 'photo_progress_v1';

  List<_Snap> _snaps = [];
  bool _loading = true;
  int _compareIdxA = -1;
  int _compareIdxB = -1;
  String? _compareReflection;
  bool _loadingReflection = false;

  late final AnimationController _ambientCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _ambientCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kvKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _snaps = list.map((e) => _Snap.fromJson(e as Map<String, dynamic>)).toList();
        _snaps.sort((a, b) => b.date.compareTo(a.date));
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kvKey,
        jsonEncode(_snaps.map((s) => s.toJson()).toList()));
  }

  Future<void> _addPhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto-Aufnahme ist auf Web nicht verfügbar — bitte Mobile-App nutzen.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final filename = 'progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${dir.path}/$filename';
    await File(picked.path).copy(newPath);

    final tags = await _askTags();
    if (tags == null) return;

    setState(() {
      _snaps.insert(0, _Snap(
        path: newPath,
        date: DateTime.now(),
        bodyNote: tags.body,
        mindNote: tags.mind,
        soulNote: tags.soul,
      ));
    });
    await _save();
  }

  Future<_BodyMindSoulTags?> _askTags() async {
    final body = TextEditingController();
    final mind = TextEditingController();
    final soul = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Wie geht es dir heute?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('💪 Körper', body),
              const SizedBox(height: 10),
              _field('🧠 Geist', mind),
              const SizedBox(height: 10),
              _field('✨ Seele', soul),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result == true) {
      return _BodyMindSoulTags(body.text, mind.text, soul.text);
    }
    return null;
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _delete(int idx) async {
    final s = _snaps[idx];
    try {
      final f = File(s.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    setState(() => _snaps.removeAt(idx));
    await _save();
  }

  void _toggleCompare(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _compareReflection = null;
      if (_compareIdxA == idx) {
        _compareIdxA = -1;
      } else if (_compareIdxB == idx) {
        _compareIdxB = -1;
      } else if (_compareIdxA < 0) {
        _compareIdxA = idx;
      } else if (_compareIdxB < 0) {
        _compareIdxB = idx;
      } else {
        _compareIdxA = idx;
        _compareIdxB = -1;
      }
    });
  }

  Future<void> _requestAiReflection() async {
    if (_compareIdxA < 0 || _compareIdxB < 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _loadingReflection = true);
    final a = _snaps[_compareIdxA];
    final b = _snaps[_compareIdxB];
    final earlier = a.date.isBefore(b.date) ? a : b;
    final later = a.date.isBefore(b.date) ? b : a;
    final days = later.date.difference(earlier.date).inDays.abs();
    try {
      final prompt = StringBuffer()
        ..writeln('Reflektiere die Transformation einer Person über $days Tage')
        ..writeln('zwischen zwei Selbstbeobachtungs-Einträgen.')
        ..writeln('')
        ..writeln('VORHER (${_fmtDate(earlier.date)}):')
        ..writeln('  💪 Körper: ${earlier.bodyNote.isEmpty ? "—" : earlier.bodyNote}')
        ..writeln('  🧠 Geist: ${earlier.mindNote.isEmpty ? "—" : earlier.mindNote}')
        ..writeln('  ✨ Seele: ${earlier.soulNote.isEmpty ? "—" : earlier.soulNote}')
        ..writeln('')
        ..writeln('NACHHER (${_fmtDate(later.date)}):')
        ..writeln('  💪 Körper: ${later.bodyNote.isEmpty ? "—" : later.bodyNote}')
        ..writeln('  🧠 Geist: ${later.mindNote.isEmpty ? "—" : later.mindNote}')
        ..writeln('  ✨ Seele: ${later.soulNote.isEmpty ? "—" : later.soulNote}')
        ..writeln('')
        ..writeln('Gib eine 3-Absatz-Reflexion: 1) Welche Veränderung zeigt sich? '
            '2) Was darf gewürdigt werden? 3) Was ist als nächster Schritt sichtbar? '
            'Du-Form, warm aber direkt, ohne Esoterik-Klischees.');
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/mentor/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'personality': 'alchemist',
              'message': prompt.toString(),
              'world': 'energie',
              'conversationHistory': [],
            }),
          )
          .timeout(const Duration(seconds: 35));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final answer = ((data['answer'] ?? data['response'] ?? data['message'] ?? '') as String).trim();
        if (mounted) {
          setState(() {
            _compareReflection = answer;
            _loadingReflection = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _compareReflection = '⚠️ AI-Reflexion gerade nicht verfügbar (HTTP ${res.statusCode}).';
          _loadingReflection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _compareReflection = '⚠️ Netzwerk-Fehler: $e';
          _loadingReflection = false;
        });
      }
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_gold, _accent],
          ).createShader(r),
          child: const Text('TRANSFORMATIONS-CHRONIK',
              style: TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Neues Foto', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _addPhoto,
      ),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.5,
              colors: [Color(0x55BF360C), Color(0x33260C08), _bg],
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (_, __) => CustomPaint(
              painter: _PhotoOrbsPainter(_ambientCtrl.value),
              size: Size.infinite,
            ),
          ),
        ),
        const IgnorePointer(child: WBAmbientParticles(world: WBWorld.energie, count: 30)),
        SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _snaps.isEmpty
                  ? _buildEmpty()
                  : _compareIdxA >= 0 && _compareIdxB >= 0
                      ? _buildCompare()
                      : _buildList(),
        ),
        const IgnorePointer(child: WBVignette()),
      ]),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📸', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Noch keine Fotos',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'Tippe unten auf "Neues Foto" — Fotos bleiben rein lokal auf deinem Gerät.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: _snaps.length,
      itemBuilder: (_, i) {
        final s = _snaps[i];
        final isCompA = _compareIdxA == i;
        final isCompB = _compareIdxB == i;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isCompA || isCompB) ? _accent : _accent.withValues(alpha: 0.2),
              width: (isCompA || isCompB) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: localFileImage(
                    s.path,
                    errorWidget: Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${s.date.day}.${s.date.month}.${s.date.year}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isCompA || isCompB ? Icons.compare_arrows : Icons.add_box_outlined,
                            color: _accent,
                            size: 20,
                          ),
                          tooltip: 'Für Vergleich auswählen',
                          onPressed: () => _toggleCompare(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                          onPressed: () => _delete(i),
                        ),
                      ],
                    ),
                    if (s.bodyNote.isNotEmpty)
                      Text('💪 ${s.bodyNote}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (s.mindNote.isNotEmpty)
                      Text('🧠 ${s.mindNote}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (s.soulNote.isNotEmpty)
                      Text('✨ ${s.soulNote}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompare() {
    final a = _snaps[_compareIdxA];
    final b = _snaps[_compareIdxB];
    final earlier = a.date.isBefore(b.date) ? a : b;
    final later = a.date.isBefore(b.date) ? b : a;
    final daysDiff = later.date.difference(earlier.date).inDays.abs();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_accent.withValues(alpha: 0.3), _gold.withValues(alpha: 0.15)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  Text('VERGLEICH · $daysDiff TAGE',
                      style: const TextStyle(
                          color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${_fmtDate(earlier.date)} → ${_fmtDate(later.date)}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 320,
            child: Row(
              children: [
                Expanded(child: _compareSide(earlier, 'VORHER')),
                const SizedBox(width: 8),
                Expanded(child: _compareSide(later, 'NACHHER')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_compareReflection == null && !_loadingReflection)
            ElevatedButton.icon(
              onPressed: _requestAiReflection,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('AI-TRANSFORMATIONS-REFLEXION',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          else if (_loadingReflection)
            Column(children: [
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _accent.withValues(alpha: 0.5 + 0.3 * _glowCtrl.value),
                      Colors.transparent,
                    ]),
                  ),
                  child: const Center(child: Icon(Icons.auto_awesome, color: _gold, size: 36)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Der Alchemist liest deine Reise…',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])
          else if (_compareReflection != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.auto_awesome_rounded, color: _gold, size: 16),
                      const SizedBox(width: 6),
                      const Text('ALCHEMIST · TRANSFORMATION',
                          style: TextStyle(color: _gold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 10),
                    SelectableText(_compareReflection!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _compareIdxA = -1;
              _compareIdxB = -1;
              _compareReflection = null;
            }),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
            label: const Text('Zurück zur Galerie', style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _compareSide(_Snap s, String label) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: _accent,
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ClipRRect(
              child: localFileImage(
                s.path,
                errorWidget: Container(
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.broken_image, size: 64, color: Colors.white24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text('${s.date.day}.${s.date.month}.${s.date.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── PAINTER: Photo CineOrbs (warmes Orange-Gold) ─────────────────────────────
class _PhotoOrbsPainter extends CustomPainter {
  final double t;
  _PhotoOrbsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, Offset(size.width * 0.2, size.height * (0.3 + math.sin(t * 2 * math.pi) * 0.05)),
        100, const Color(0xFFF57C00));
    _draw(canvas, Offset(size.width * 0.85, size.height * (0.55 + math.cos(t * 2 * math.pi) * 0.04)),
        90, const Color(0xFFFFD54F));
    _draw(canvas, Offset(size.width * 0.5, size.height * (0.9 + math.sin(t * math.pi) * 0.03)),
        70, const Color(0xFFFF7043));
  }

  void _draw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
    canvas.drawCircle(c, r, p);
  }

  @override
  bool shouldRepaint(_PhotoOrbsPainter old) => old.t != t;
}

class _Snap {
  final String path;
  final DateTime date;
  final String bodyNote;
  final String mindNote;
  final String soulNote;
  const _Snap({
    required this.path,
    required this.date,
    required this.bodyNote,
    required this.mindNote,
    required this.soulNote,
  });
  Map<String, dynamic> toJson() => {
        'path': path,
        'date': date.toIso8601String(),
        'body': bodyNote,
        'mind': mindNote,
        'soul': soulNote,
      };
  factory _Snap.fromJson(Map<String, dynamic> j) => _Snap(
        path: j['path'] as String,
        date: DateTime.parse(j['date'] as String),
        bodyNote: j['body'] as String? ?? '',
        mindNote: j['mind'] as String? ?? '',
        soulNote: j['soul'] as String? ?? '',
      );
}
