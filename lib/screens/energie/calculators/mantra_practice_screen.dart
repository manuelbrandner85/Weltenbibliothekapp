// 🕉️ MANTRA-PRAXIS · Audio-Aussprache + Mala-Counter + Tagesmantra
//
// Hyperrealistisch-cinematic: WBGlassAppBar mit ShaderMask-Titel, 6-Layer-BG
// (Radial-Nebula → 3 CineOrbs → 42 Ambient-Particles → Light-Beam → Vignette),
// BackdropFilter-glassmorphe Karten mit doppelten Shadows.
//
// Features:
// - 8 klassische Mantras (Sanskrit + Transliteration + deutsche Bedeutung)
// - TTS-Aussprache jedes Mantras (langsam, klar, mehrfach)
// - 108-Mala-Counter (gross-tap-area, Haptic-Feedback alle 9 Perlen)
// - Tagesmantra-Auswahl basierend auf Wochentag (klassische Hindu-Zuordnung)
// - Verbindung zu 21-Tage-Mantra-Lernreihe (vorhanden)

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_ambient_particles.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

class MantraPracticeScreen extends StatefulWidget {
  const MantraPracticeScreen({super.key});

  @override
  State<MantraPracticeScreen> createState() => _MantraPracticeScreenState();
}

class _MantraPracticeScreenState extends State<MantraPracticeScreen>
    with TickerProviderStateMixin {
  static const Color _bgDark = Color(0xFF0A0512);

  /// Theme-aware background. Light-Mode liefert helle `context.wb.bgVoid`,
  /// Dark-Mode behält den Original-Ton.
  Color _bg(BuildContext context) {
    final wb = Theme.of(context).extension<WBCinematic>();
    return wb?.bgVoid ?? _bgDark;
  }

  static const Color _primary = Color(0xFFFFB300); // amber
  static const Color _secondary = Color(0xFFFF6F00); // deep orange
  static const Color _accent = Color(0xFFD500F9); // magenta
  static const String _kvKey = 'mantra_counter_v1';

  late final FlutterTts _tts;
  late final AnimationController _bgCtrl;
  late final AnimationController _pulseCtrl;

  _Mantra? _selected;
  int _beadCount = 0;
  bool _speaking = false;

  static final List<_Mantra> _mantras = [
    _Mantra(
      id: 'om',
      sanskrit: 'ॐ',
      translit: 'OM',
      meaning:
          'Urklang des Universums · Brahman · Schöpfung-Erhaltung-Auflösung',
      day: 'Alle Tage',
      element: 'Äther',
      ttsText: 'Aaa-Uuu-Mmm',
    ),
    _Mantra(
      id: 'soham',
      sanskrit: 'सो ऽहम्',
      translit: 'So Ham',
      meaning: 'Ich bin Das · natürliches Atem-Mantra (Hamsa)',
      day: 'Montag (Mond · Stille)',
      element: 'Wasser',
      ttsText: 'So Ham',
    ),
    _Mantra(
      id: 'omnamahshivaya',
      sanskrit: 'ॐ नमः शिवाय',
      translit: 'Om Namah Shivaya',
      meaning: 'Verneigung vor Shiva · Bewusstsein selbst · Transformation',
      day: 'Montag (Shiva-Tag)',
      element: 'Äther',
      ttsText: 'Om Nah-mah Shi-vai-ah',
    ),
    _Mantra(
      id: 'manipadme',
      sanskrit: 'ॐ मणि पद्मे हूँ',
      translit: 'Om Mani Padme Hum',
      meaning: 'Das Juwel im Lotus · Mitgefühl (Avalokiteshvara)',
      day: 'Mittwoch (Bodhisattva-Praxis)',
      element: 'Wasser',
      ttsText: 'Om Mah-ni Pad-meh Hum',
    ),
    _Mantra(
      id: 'gayatri',
      sanskrit: 'ॐ भूर्भुवः स्वः',
      translit: 'Om Bhur Bhuvah Svaha',
      meaning: 'Erleuchte unseren Geist · Sonnen-Hymnus (Rigveda)',
      day: 'Sonntag (Sonne)',
      element: 'Feuer',
      ttsText:
          'Om Bhuur Bhuu-vah Sva-ha. Tat Sa-vee-tur Va-rein-yam. Bhar-go De-vas-ya Dhee-ma-hi. Dhee-yo Yo Nah Pra-cho-da-yaat',
    ),
    _Mantra(
      id: 'ganapati',
      sanskrit: 'ॐ गं गणपतये नमः',
      translit: 'Om Gam Ganapataye Namaha',
      meaning:
          'Anrufung Ganeshas · Beseitiger der Hindernisse · vor jedem Beginnen',
      day: 'Mittwoch (Merkur · neue Anfänge)',
      element: 'Erde',
      ttsText: 'Om Gam Ga-na-pa-tai-eh Na-ma-ha',
    ),
    _Mantra(
      id: 'shanti',
      sanskrit: 'ॐ शान्तिः शान्तिः शान्तिः',
      translit: 'Om Shanti Shanti Shanti',
      meaning: 'Friede × 3 · Körper · Geist · Seele',
      day: 'Freitag (Venus · Harmonie)',
      element: 'Luft',
      ttsText: 'Om Shaaan-ti Shaaan-ti Shaaan-ti',
    ),
    _Mantra(
      id: 'lokah',
      sanskrit: 'लोकाः समस्ताः सुखिनो भवन्तु',
      translit: 'Lokah Samastah Sukhino Bhavantu',
      meaning: 'Mögen alle Wesen glücklich sein · universelle Heilsformel',
      day: 'Donnerstag (Jupiter · Wohlwollen)',
      element: 'Äther',
      ttsText: 'Lo-kah Sa-mas-taah Sukh-ee-no Bha-van-tu',
    ),
  ];

  // Hindu-klassische Wochentag-Zuordnung
  static const Map<int, String> _dayMantraId = {
    DateTime.monday: 'omnamahshivaya',
    DateTime.tuesday: 'ganapati',
    DateTime.wednesday: 'ganapati',
    DateTime.thursday: 'lokah',
    DateTime.friday: 'shanti',
    DateTime.saturday: 'soham',
    DateTime.sunday: 'gayatri',
  };

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _setupTts();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _loadCounter();
    // Auto-Select Tagesmantra
    final id = _dayMantraId[DateTime.now().weekday] ?? 'om';
    _selected =
        _mantras.firstWhere((m) => m.id == id, orElse: () => _mantras.first);
  }

  Future<void> _setupTts() async {
    await _tts
        .setLanguage('en-IN'); // Indian English bessere Sanskrit-Annäherung
    await _tts.setSpeechRate(0.35);
    await _tts.setPitch(0.95);
    await _tts.setVolume(0.95);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _beadCount = prefs.getInt(_kvKey) ?? 0);
    }
  }

  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kvKey, _beadCount);
  }

  Future<void> _speak() async {
    if (_selected == null) return;
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await _tts.speak(_selected!.ttsText);
  }

  Future<void> _tapBead() async {
    setState(() => _beadCount++);
    // Haptik alle 9 (Mala-Sub-Cycle)
    if (_beadCount % 9 == 0)
      await HapticFeedback.mediumImpact();
    else
      await HapticFeedback.selectionClick();
    // Bei 108: vollständige Runde — kräftiges Feedback + Reset-Option
    if (_beadCount >= 108) {
      await HapticFeedback.heavyImpact();
    }
    await _saveCounter();
  }

  Future<void> _resetCounter() async {
    setState(() => _beadCount = 0);
    await _saveCounter();
  }

  @override
  void dispose() {
    _tts.stop();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      extendBodyBehindAppBar: true,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [_primary, _accent],
          ).createShader(rect),
          child: const Text(
            'MANTRA-PRAXIS',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Stack(
          children: [
            // Layer 1: Radial Nebula
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                        0.3 - _bgCtrl.value * 0.4, -0.5 + _bgCtrl.value * 0.3),
                    radius: 1.5,
                    colors: [
                      _primary.withValues(alpha: 0.18),
                      _accent.withValues(alpha: 0.08),
                      const Color(0xFF050310),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Layer 2: CineOrbs
            Positioned(
              top: -120 + _bgCtrl.value * 60,
              right: -80,
              child: _CineOrb(
                  color: _primary,
                  size: 380,
                  opacity: 0.16 + _bgCtrl.value * 0.06),
            ),
            Positioned(
              bottom: -130 + _bgCtrl.value * 50,
              left: -70,
              child: _CineOrb(color: _secondary, size: 320, opacity: 0.14),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              left: MediaQuery.of(context).size.width * 0.3,
              child: _CineOrb(
                  color: _accent,
                  size: 240,
                  opacity: 0.10 + _bgCtrl.value * 0.04),
            ),
            // Layer 3: Particles
            const Positioned.fill(
              child: IgnorePointer(
                child: WBAmbientParticles(world: WBWorld.energie, count: 38),
              ),
            ),
            // Layer 4: Light-Beam Sweep
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.22,
                  child: Align(
                    alignment: Alignment(0, -0.6 + _bgCtrl.value * 1.2),
                    child: Container(
                      height: 1.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          _primary.withValues(alpha: 0.5),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Layer 5: Vignette
            const Positioned.fill(child: IgnorePointer(child: WBVignette())),
            // Layer 6: Content
            child!,
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              children: [
                _buildTagesmantraHeader(),
                const SizedBox(height: 18),
                _buildSelectedCard(),
                const SizedBox(height: 18),
                _buildMalaCounter(),
                const SizedBox(height: 18),
                _buildMantraGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagesmantraHeader() {
    final day = DateTime.now().weekday;
    final dayMantra = _mantras.firstWhere(
      (m) => m.id == (_dayMantraId[day] ?? 'om'),
      orElse: () => _mantras.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _primary.withValues(alpha: 0.35),
          _accent.withValues(alpha: 0.15)
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🕉️', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TAGESMANTRA · ${_weekdayName(day)}',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                Text(dayMantra.translit,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => setState(() => _selected = dayMantra),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _primary.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Wählen',
                style: TextStyle(color: _primary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCard() {
    final m = _selected ?? _mantras.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primary.withValues(alpha: 0.25),
                _accent.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.6),
              ],
              stops: const [0, 0.6, 1],
            ),
            border:
                Border.all(color: _primary.withValues(alpha: 0.45), width: 1.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _accent.withValues(alpha: 0.15),
                blurRadius: 18,
                spreadRadius: -4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  colors: [_primary, _accent, _primary],
                ).createShader(r),
                child: Text(
                  m.sanskrit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                          color: Colors.black87,
                          blurRadius: 18,
                          offset: Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(m.translit,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(m.meaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12.5, height: 1.5)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _chip('🌗 ${m.day}'),
                const SizedBox(width: 6),
                _chip('${_elementEmoji(m.element)} ${m.element}'),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _speak,
                  icon: Icon(_speaking ? Icons.stop : Icons.volume_up),
                  label: Text(_speaking ? 'Stopp' : 'AUSSPRACHE HÖREN',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMalaCounter() {
    final rounds = _beadCount ~/ 108;
    final inRound = _beadCount % 108;
    final progress = inRound / 108.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: _accent.withValues(alpha: 0.2),
                  blurRadius: 22,
                  spreadRadius: -6,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('108-MALA-COUNTER',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.bold)),
                  if (_beadCount > 0)
                    GestureDetector(
                      onTap: _resetCounter,
                      child: Icon(Icons.refresh,
                          color: Colors.white.withValues(alpha: 0.6), size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => GestureDetector(
                  onTap: _tapBead,
                  child: Container(
                    width: 160,
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _primary.withValues(
                            alpha: 0.55 + _pulseCtrl.value * 0.15),
                        _accent.withValues(alpha: 0.25),
                        Colors.transparent,
                      ]),
                      border: Border.all(color: _primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(
                              alpha: 0.45 + _pulseCtrl.value * 0.2),
                          blurRadius: 28 + _pulseCtrl.value * 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$inRound',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 16)
                              ],
                            )),
                        const Text('/108',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('TAP',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                                letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(_primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                rounds == 0
                    ? 'Erste Runde aktiv'
                    : '$rounds vollständige Runde${rounds == 1 ? "" : "n"} abgeschlossen',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMantraGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ALLE 8 MANTRAS',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                letterSpacing: 2.5,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in _mantras)
              GestureDetector(
                onTap: () => setState(() => _selected = m),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selected?.id == m.id
                        ? _primary.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selected?.id == m.id
                          ? _primary
                          : Colors.white.withValues(alpha: 0.15),
                      width: _selected?.id == m.id ? 1.5 : 1,
                    ),
                  ),
                  child: Text(m.translit,
                      style: TextStyle(
                        color: _selected?.id == m.id
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
    );
  }

  String _weekdayName(int d) => switch (d) {
        DateTime.monday => 'Montag',
        DateTime.tuesday => 'Dienstag',
        DateTime.wednesday => 'Mittwoch',
        DateTime.thursday => 'Donnerstag',
        DateTime.friday => 'Freitag',
        DateTime.saturday => 'Samstag',
        _ => 'Sonntag',
      };

  String _elementEmoji(String e) => switch (e) {
        'Feuer' => '🔥',
        'Wasser' => '💧',
        'Erde' => '🌍',
        'Luft' => '🌬️',
        _ => '✨',
      };
}

class _Mantra {
  final String id;
  final String sanskrit;
  final String translit;
  final String meaning;
  final String day;
  final String element;
  final String ttsText;
  const _Mantra({
    required this.id,
    required this.sanskrit,
    required this.translit,
    required this.meaning,
    required this.day,
    required this.element,
    required this.ttsText,
  });
}

// Cinematic glowing orb
class _CineOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _CineOrb(
      {required this.color, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.4),
            color.withValues(alpha: 0),
          ]),
        ),
      ),
    );
  }
}
