import 'dart:math' show cos, sin, pi;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/mentor_session_model.dart';
import '../../services/mentor_personas.dart';
import '../../services/mentor_service.dart';

// =========================================================================
// MENTOR AVATAR SESSION SCREEN
//
// Immersive voice-first session with the world mentor:
//   - Animated 3D orbital avatar (CustomPainter)
//   - Voice input via speech_to_text
//   - Mentor voice output via flutter_tts
//   - Text input fallback
// =========================================================================

class MentorSessionScreen extends StatefulWidget {
  final MentorPersonality personality;
  final String world;

  const MentorSessionScreen({
    super.key,
    required this.personality,
    required this.world,
  });

  @override
  State<MentorSessionScreen> createState() => _MentorSessionScreenState();
}

class _MentorSessionScreenState extends State<MentorSessionScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _orbitCtrl;
  late final AnimationController _pulseCtrl;

  // Services
  final _mentorService = MentorService();
  final _speech = stt.SpeechToText();
  late final FlutterTts _tts;

  // State
  MentorAvatarState _avatarState = MentorAvatarState.idle;
  MentorSessionMode _sessionMode = MentorSessionMode.voice;
  bool _sttReady = false;
  bool _isProcessing = false;
  List<MentorChatMessage> _messages = [];
  String _liveTranscript = '';
  final TextEditingController _textCtrl = TextEditingController();

  // ── World theming ──────────────────────────────────────────────────────

  Color get _primaryColor {
    switch (widget.world) {
      case 'vorhang':
        return const Color(0xFFC9A84C);
      case 'ursprung':
        return const Color(0xFF00D4AA);
      case 'energie':
        return const Color(0xFFA855F7);
      case 'materie':
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Color get _bgColor {
    switch (widget.world) {
      case 'vorhang':
        return const Color(0xFF0D0B00);
      case 'ursprung':
        return const Color(0xFF050510);
      case 'energie':
        return const Color(0xFF0C0318);
      case 'materie':
      default:
        return const Color(0xFF040D1F);
    }
  }

  String get _mentorEmoji => MentorPersonas.avatarEmoji(widget.world);
  String get _mentorName => MentorPersonas.displayName(widget.world);

  double get _ttsPitch {
    switch (widget.personality) {
      case MentorPersonality.alchemist:
        return 0.85;
      case MentorPersonality.heiler:
        return 1.00;
      case MentorPersonality.forscher:
        return 1.05;
      case MentorPersonality.stratege:
        return 0.90;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Orbital rotation: 8 s per cycle
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    // Center-orb pulse: 2.5 s per cycle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _messages = _mentorService.loadHistory(widget.world);
    _initTts();
    _initStt();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(_ttsPitch);
    await _tts.setVolume(0.9);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _avatarState = MentorAvatarState.idle);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _avatarState = MentorAvatarState.idle);
    });
  }

  Future<void> _initStt() async {
    _sttReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if ((status == 'done' || status == 'notListening') &&
            _avatarState == MentorAvatarState.listening) {
          final text = _liveTranscript.trim();
          if (text.isNotEmpty) {
            _submitMessage(text);
          } else {
            setState(() {
              _avatarState = MentorAvatarState.idle;
              _liveTranscript = '';
            });
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _avatarState = MentorAvatarState.idle;
            _liveTranscript = '';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _tts.stop();
    _speech.stop();
    _textCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // INTERACTION LOGIC
  // =========================================================================

  Future<void> _toggleListening() async {
    // If currently speaking: stop TTS
    if (_avatarState == MentorAvatarState.speaking) {
      await _tts.stop();
      if (mounted) setState(() => _avatarState = MentorAvatarState.idle);
      return;
    }

    // If currently listening: stop and submit
    if (_avatarState == MentorAvatarState.listening) {
      await _speech.stop();
      final text = _liveTranscript.trim();
      if (text.isNotEmpty) {
        await _submitMessage(text);
      } else {
        if (mounted) {
          setState(() {
            _avatarState = MentorAvatarState.idle;
            _liveTranscript = '';
          });
        }
      }
      return;
    }

    if (!_sttReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon nicht verfügbar oder Berechtigung fehlt.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _avatarState = MentorAvatarState.listening;
      _liveTranscript = '';
    });

    await _speech.listen(
      localeId: 'de_DE',
      onResult: (result) {
        if (!mounted) return;
        setState(() => _liveTranscript = result.recognizedWords);
      },
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> _submitTextMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isProcessing) return;
    _textCtrl.clear();
    if (_avatarState == MentorAvatarState.speaking) {
      await _tts.stop();
    }
    await _submitMessage(text);
  }

  /// Central message handler: sends to AI, speaks the reply.
  Future<void> _submitMessage(String text) async {
    if (_isProcessing) return;

    setState(() {
      _avatarState = MentorAvatarState.thinking;
      _liveTranscript = '';
      _isProcessing = true;
      _messages.add(MentorChatMessage(role: 'user', content: text));
    });

    try {
      final response = await _mentorService.sendMessage(
        personality: widget.personality,
        message: text,
        history: _messages,
        world: widget.world,
      );

      if (!mounted) return;

      final assistantMsg = MentorChatMessage(
        role: 'assistant',
        content: response.reply,
      );
      setState(() {
        _messages.add(assistantMsg);
        _avatarState = MentorAvatarState.speaking;
        _isProcessing = false;
      });

      await _mentorService.saveHistory(widget.world, _messages);
      await _tts.speak(response.reply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _avatarState = MentorAvatarState.idle;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildAvatarSection()),
            _buildStateLabel(),
            _buildTranscriptArea(),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryColor.withValues(alpha: 0.12),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(_mentorEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mentorName,
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'AVATAR-SESSION',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Session beenden',
          ),
        ],
      ),
    );
  }

  // ── Avatar section ────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D orbital avatar
          AnimatedBuilder(
            animation: Listenable.merge([_orbitCtrl, _pulseCtrl]),
            builder: (ctx, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _MentorAvatarPainter(
                      orbitValue: _orbitCtrl.value,
                      pulseValue: _pulseCtrl.value,
                      primaryColor: _primaryColor,
                      avatarState: _avatarState,
                    ),
                  ),
                  // Emoji overlaid on center orb
                  Text(_mentorEmoji, style: const TextStyle(fontSize: 48)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _buildModeSwitch(),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeTab(MentorSessionMode.voice, Icons.mic_none_rounded, 'Sprache'),
          _modeTab(MentorSessionMode.text, Icons.keyboard_rounded, 'Text'),
        ],
      ),
    );
  }

  Widget _modeTab(MentorSessionMode mode, IconData icon, String label) {
    final active = _sessionMode == mode;
    return GestureDetector(
      onTap: () {
        if (_avatarState == MentorAvatarState.listening) _speech.stop();
        setState(() {
          _sessionMode = mode;
          _liveTranscript = '';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? _primaryColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: active
              ? Border.all(color: _primaryColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? _primaryColor : Colors.white30,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? _primaryColor : Colors.white30,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── State label ───────────────────────────────────────────────────────

  Widget _buildStateLabel() {
    String label = '';
    switch (_avatarState) {
      case MentorAvatarState.listening:
        if (_liveTranscript.isNotEmpty) {
          final t = _liveTranscript;
          label = '"${t.length > 44 ? '${t.substring(0, 44)}...' : t}"';
        } else {
          label = 'Hört zu...';
        }
        break;
      case MentorAvatarState.thinking:
        label = 'Denkt nach...';
        break;
      case MentorAvatarState.speaking:
        label = 'Spricht...';
        break;
      case MentorAvatarState.idle:
        label = '';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: label.isEmpty ? 0 : 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: label.isEmpty
          ? const SizedBox.shrink()
          : Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryColor.withValues(alpha: 0.85),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }

  // ── Transcript area ───────────────────────────────────────────────────

  Widget _buildTranscriptArea() {
    final lastAssistant = _messages.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => MentorChatMessage(role: 'assistant', content: ''),
    );

    if (lastAssistant.content.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Text(
          'Tippe auf den Mikrofon-Button und sprich mit deinem Mentor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      );
    }

    final text = lastAssistant.content;
    final preview = text.length > 240 ? '${text.substring(0, 240)}...' : text;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 130),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Text(
            preview,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── Input section ─────────────────────────────────────────────────────

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: _primaryColor.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
      ),
      child: _sessionMode == MentorSessionMode.voice
          ? _buildVoiceControls()
          : _buildTextControls(),
    );
  }

  Widget _buildVoiceControls() {
    final isListening = _avatarState == MentorAvatarState.listening;
    final isBusy = _isProcessing || _avatarState == MentorAvatarState.thinking;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isBusy ? null : _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening
                    ? Colors.red.withValues(alpha: 0.85)
                    : isBusy
                        ? Colors.white.withValues(alpha: 0.06)
                        : _primaryColor.withValues(alpha: 0.22),
                border: Border.all(
                  color: isListening
                      ? Colors.red
                      : isBusy
                          ? Colors.white12
                          : _primaryColor.withValues(alpha: 0.55),
                  width: 2.0,
                ),
                boxShadow: [
                  if (isListening)
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 4,
                    )
                  else if (!isBusy)
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isBusy
                  ? Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: _primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isListening
                ? 'Tippen zum Senden'
                : isBusy
                    ? ' '
                    : 'Tippen zum Sprechen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.32),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextControls() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Nachricht eingeben...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _submitTextMessage(),
            textInputAction: TextInputAction.send,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _isProcessing ? Colors.white10 : _primaryColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _isProcessing ? null : _submitTextMessage,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Icon(
                Icons.send_rounded,
                color: _isProcessing ? Colors.white24 : Colors.black87,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// 3D ORBITAL AVATAR PAINTER
//
// Three tilted orbital rings (CustomPainter) create the 3D illusion:
//   Ring 1 (outer, tilt=72 deg): very flat ellipse — horizontal orbit
//   Ring 2 (middle, tilt=45 deg): medium ellipse
//   Ring 3 (inner, tilt=18 deg): near-circular — vertical orbit
//
// Glowing particles orbit each ring with depth-based brightness.
// The avatar state drives rotation speed and glow intensity.
// =========================================================================

class _MentorAvatarPainter extends CustomPainter {
  final double orbitValue; // 0..1
  final double pulseValue; // 0..1
  final Color primaryColor;
  final MentorAvatarState avatarState;

  _MentorAvatarPainter({
    required this.orbitValue,
    required this.pulseValue,
    required this.primaryColor,
    required this.avatarState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.shortestSide * 0.44;

    double speedFactor;
    if (avatarState == MentorAvatarState.speaking) {
      speedFactor = 1.8;
    } else if (avatarState == MentorAvatarState.listening) {
      speedFactor = 1.35;
    } else {
      speedFactor = 1.0;
    }

    final angle = orbitValue * 2 * pi * speedFactor;
    // Smooth 0..1 pulse via sine
    final pulse = sin(pulseValue * 2 * pi) * 0.5 + 0.5;

    // Ambient background glow
    final glowR = maxR * 1.45;
    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.10 + 0.06 * pulse),
            primaryColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
    );

    // Ring 1: outer, near-horizontal (tilt=72 deg from face-on -> very flat)
    _drawRing(
      canvas,
      cx,
      cy,
      rx: maxR * 0.93,
      tiltDeg: 72.0,
      angle: angle,
      particleCount: 4,
      particleSize: 3.8,
      opacity: 0.30,
    );

    // Ring 2: middle tilt (45 deg)
    _drawRing(
      canvas,
      cx,
      cy,
      rx: maxR * 0.73,
      tiltDeg: 45.0,
      angle: angle * 0.65 + pi / 3,
      particleCount: 3,
      particleSize: 3.2,
      opacity: 0.45,
    );

    // Ring 3: inner, near-vertical (18 deg -> almost circular)
    _drawRing(
      canvas,
      cx,
      cy,
      rx: maxR * 0.53,
      tiltDeg: 18.0,
      angle: angle * 1.20 + pi / 5,
      particleCount: 2,
      particleSize: 2.5,
      opacity: 0.60,
    );

    // Center orb (drawn last: covers ring crossing points naturally)
    final orbR = maxR * 0.28 * (1 + 0.10 * pulse);
    _drawCenterOrb(canvas, Offset(cx, cy), orbR, pulse);
  }

  void _drawRing(
    Canvas canvas,
    double cx,
    double cy, {
    required double rx,
    required double tiltDeg,
    required double angle,
    required int particleCount,
    required double particleSize,
    required double opacity,
  }) {
    // ry = rx * cos(tiltDeg): how flat the ring appears
    final ry = rx * cos(tiltDeg * pi / 180);

    // Ellipse stroke
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      Paint()
        ..color = primaryColor.withValues(alpha: opacity * 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Particles: two passes for painter's algorithm (back then front)
    final step = 2 * pi / particleCount;
    for (int pass = 0; pass < 2; pass++) {
      for (int i = 0; i < particleCount; i++) {
        final phi = step * i + angle;
        // depth: -1 = back of orbit, +1 = front of orbit
        final depth = sin(phi);
        if (pass == 0 && depth >= 0) continue; // back pass
        if (pass == 1 && depth < 0) continue; // front pass

        final px = cx + rx * cos(phi);
        final py = cy + ry * sin(phi);
        final brightness = (depth + 1) / 2; // 0..1
        final r = particleSize * (0.45 + 0.55 * brightness);
        final a = opacity * (0.28 + 0.72 * brightness);

        // Soft glow around particle
        canvas.drawCircle(
          Offset(px, py),
          r * 2.2,
          Paint()
            ..color = primaryColor.withValues(alpha: a * 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
        );
        // Hard core
        canvas.drawCircle(
          Offset(px, py),
          r,
          Paint()..color = primaryColor.withValues(alpha: a.clamp(0.0, 1.0)),
        );
      }
    }
  }

  void _drawCenterOrb(
    Canvas canvas,
    Offset center,
    double radius,
    double pulse,
  ) {
    double glowBoost;
    if (avatarState == MentorAvatarState.speaking) {
      glowBoost = 0.50;
    } else if (avatarState == MentorAvatarState.listening) {
      glowBoost = 0.28;
    } else {
      glowBoost = 0.0;
    }

    // Multi-layer soft glow (outermost first)
    for (int i = 3; i >= 1; i--) {
      final layerR = radius * (1.0 + i * 0.45 + glowBoost * 0.15);
      final a = (0.12 - i * 0.025 + pulse * 0.02 + glowBoost * 0.04).clamp(
        0.0,
        1.0,
      );
      canvas.drawCircle(
        center,
        layerR,
        Paint()..color = primaryColor.withValues(alpha: a),
      );
    }

    // Radial-gradient core (emoji renders on top via Stack)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [
            primaryColor.withValues(alpha: 0.92),
            primaryColor.withValues(alpha: 0.45),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_MentorAvatarPainter old) {
    return old.orbitValue != orbitValue ||
        old.pulseValue != pulseValue ||
        old.avatarState != avatarState ||
        old.primaryColor != primaryColor;
  }
}
