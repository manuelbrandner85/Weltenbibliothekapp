/// 🌀 MENTOR SESSION SCREEN — 3D-Avatar-Modus
///
/// Immersive Vollbild-Erfahrung fuer Mentor-Sessions.
/// Zeigt einen animierten 3D-Avatar (CustomPainter) mit:
///   - idle: sanftes Pulsieren
///   - listening: expandierende Ringe (Mikrofon aktiv)
///   - thinking: rotierende Partikel (KI rechnet)
///   - speaking: Schallwellen-Bands (TTS liest vor)
///
/// Technischer Stack:
///   - flutter_tts  fuer Text-to-Speech (Mentor-Antwort vorlesen)
///   - speech_to_text fuer Voice-Input
///   - MentorService  fuer KI-Antworten (identisch zu MentorChatScreen)
///   - MentorSessionModel  fuer Avatar-Zustand
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/mentor_session_model.dart';
import '../../services/mentor_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

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
  // ── Session model ──
  late final MentorSessionModel _session;

  // ── Services ──
  final _mentorService = MentorService();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // ── UI state ──
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<MentorChatMessage> _messages = [];
  bool _isLoading = false;
  bool _speechReady = false;
  String _lastResponse = '';

  // ── Avatar animation controllers ──
  // Primary pulse (idle)
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  // Listening rings
  late final AnimationController _ringsCtrl;
  // Thinking particles
  late final AnimationController _thinkCtrl;
  // Speaking waves
  late final AnimationController _wavesCtrl;

  // ── Derived world color ──
  Color get _accent => Color(_session.accentArgb);
  Color get _bg => switch (widget.world) {
        'vorhang' => const Color(0xFF0D0B00),
        'ursprung' => const Color(0xFF050510),
        'energie' => const Color(0xFF0C0318),
        _ => const Color(0xFF040D1F),
      };

  @override
  void initState() {
    super.initState();
    _session = MentorSessionModel(
      world: widget.world,
      personality: widget.personality,
    );

    _messages = _mentorService.loadHistory(widget.world);

    // pulse: 0.95 -> 1.05, repeat
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.93,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // rings: 0 -> 1, repeat
    _ringsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // think: full rotation, repeat
    _thinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // waves: 0 -> 2*pi, repeat
    _wavesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted && _session.avatarState == MentorAvatarState.speaking) {
        _setAvatarState(MentorAvatarState.idle);
      }
    });
  }

  void _setAvatarState(MentorAvatarState state) {
    if (!mounted) return;
    setState(() => _session.avatarState = state);
    switch (state) {
      case MentorAvatarState.idle:
        _ringsCtrl.stop();
        _thinkCtrl.stop();
        _wavesCtrl.stop();
      case MentorAvatarState.listening:
        _ringsCtrl.repeat();
        _thinkCtrl.stop();
        _wavesCtrl.stop();
      case MentorAvatarState.thinking:
        _ringsCtrl.stop();
        _thinkCtrl.repeat();
        _wavesCtrl.stop();
      case MentorAvatarState.speaking:
        _ringsCtrl.stop();
        _thinkCtrl.stop();
        _wavesCtrl.repeat();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // VOICE INPUT
  // ═══════════════════════════════════════════════════════════

  Future<void> _toggleMic() async {
    if (_session.isMicActive) {
      await _speech.stop();
      setState(() => _session.isMicActive = false);
      _setAvatarState(MentorAvatarState.idle);
      return;
    }

    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() => _session.isMicActive = false);
            if (_session.avatarState == MentorAvatarState.listening) {
              _setAvatarState(MentorAvatarState.idle);
            }
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _session.isMicActive = false);
            _setAvatarState(MentorAvatarState.idle);
          }
        },
      );
    }

    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon nicht verfuegbar oder Berechtigung fehlt.'),
          ),
        );
      }
      return;
    }

    setState(() => _session.isMicActive = true);
    _setAvatarState(MentorAvatarState.listening);

    await _speech.listen(
      localeId: 'de_DE',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (!mounted) return;
        _textCtrl.text = result.recognizedWords;
        _textCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _textCtrl.text.length),
        );
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _session.isMicActive = false);
          _setAvatarState(MentorAvatarState.thinking);
          _sendMessage();
        }
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textCtrl.clear();
    final userMsg = MentorChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _setAvatarState(MentorAvatarState.thinking);
    _scrollToBottom();

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
        _lastResponse = response.reply;
        _isLoading = false;
      });
      await _mentorService.saveHistory(widget.world, _messages);
      _scrollToBottom();

      // TTS vorlesen wenn aktiviert
      if (_session.isTtsEnabled) {
        _setAvatarState(MentorAvatarState.speaking);
        await _tts.speak(response.reply);
      } else {
        _setAvatarState(MentorAvatarState.idle);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          MentorChatMessage(
            role: 'assistant',
            content: 'Fehler: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
        );
        _isLoading = false;
      });
      _setAvatarState(MentorAvatarState.idle);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleTts() async {
    if (_session.isTtsEnabled &&
        _session.avatarState == MentorAvatarState.speaking) {
      await _tts.stop();
      _setAvatarState(MentorAvatarState.idle);
    }
    setState(() => _session.isTtsEnabled = !_session.isTtsEnabled);
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    _pulseCtrl.dispose();
    _ringsCtrl.dispose();
    _thinkCtrl.dispose();
    _wavesCtrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            // Avatar (60% of remaining height)
            Expanded(flex: 6, child: _buildAvatarSection()),
            // Chat panel (40%)
            Expanded(flex: 4, child: _buildChatPanel()),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _session.mentorDisplayName,
              style: TextStyle(
                color: _accent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // TTS toggle
          IconButton(
            icon: Icon(
              _session.isTtsEnabled ? Icons.volume_up : Icons.volume_off,
              color: _session.isTtsEnabled
                  ? _accent
                  : Colors.white.withValues(alpha: 0.35),
              size: 22,
            ),
            onPressed: _toggleTts,
            tooltip: _session.isTtsEnabled ? 'Stimme aus' : 'Stimme ein',
          ),
        ],
      ),
    );
  }

  // ── Avatar Section ────────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated avatar orb
        AnimatedBuilder(
          animation: Listenable.merge([
            _pulseCtrl,
            _ringsCtrl,
            _thinkCtrl,
            _wavesCtrl,
          ]),
          builder: (ctx, _) => SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _MentorAvatarPainter(
                accentColor: _accent,
                state: _session.avatarState,
                pulseValue: _pulseAnim.value,
                ringsProgress: _ringsCtrl.value,
                thinkProgress: _thinkCtrl.value,
                wavesProgress: _wavesCtrl.value,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // State label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _session.stateLabel,
            key: ValueKey(_session.avatarState),
            style: TextStyle(
              color: _accent.withValues(alpha: 0.8),
              fontSize: 14,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Last response preview (max 2 lines)
        if (_lastResponse.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _lastResponse,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  // ── Chat Panel ────────────────────────────────────────────────────────────

  Widget _buildChatPanel() {
    return Column(
      children: [
        // Divider
        Container(height: 0.5, color: _accent.withValues(alpha: 0.2)),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyHint()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length && _isLoading) {
                      return _buildTypingDots();
                    }
                    final msg = _messages[i];
                    final isUser = msg.role == 'user';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          top: 3,
                          bottom: 3,
                          left: isUser ? 40 : 0,
                          right: isUser ? 0 : 40,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.08)
                              : _accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isUser ? 14 : 2),
                            bottomRight: Radius.circular(isUser ? 2 : 14),
                          ),
                          border: Border.all(
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.06)
                                : _accent.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input row
        _buildInputRow(),
      ],
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Text(
        'Sage etwas oder tippe eine Frage ...',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _thinkCtrl,
              builder: (_, __) {
                final phase = (_thinkCtrl.value + i / 3.0) % 1.0;
                final size = 6.0 + 3.0 * math.sin(phase * math.pi);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(color: _accent.withValues(alpha: 0.12), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _textCtrl,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Frage eingeben ...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 6),
          // Mic button
          _CircleButton(
            color: _session.isMicActive
                ? Colors.red.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.08),
            icon: _session.isMicActive ? Icons.mic : Icons.mic_none_outlined,
            iconColor: _session.isMicActive ? Colors.white : Colors.white60,
            onTap: _isLoading ? null : _toggleMic,
          ),
          const SizedBox(width: 6),
          // Send button
          _CircleButton(
            color: _accent,
            icon: Icons.send_rounded,
            iconColor: Colors.black87,
            onTap: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CIRCLE BUTTON HELPER
// ═══════════════════════════════════════════════════════════════════════════

class _CircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.color,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3D AVATAR PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _MentorAvatarPainter extends CustomPainter {
  final Color accentColor;
  final MentorAvatarState state;
  final double pulseValue; // 0.93..1.07
  final double ringsProgress; // 0..1 (repeat)
  final double thinkProgress; // 0..1 (full rotation)
  final double wavesProgress; // 0..1 (repeat)

  const _MentorAvatarPainter({
    required this.accentColor,
    required this.state,
    required this.pulseValue,
    required this.ringsProgress,
    required this.thinkProgress,
    required this.wavesProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final baseR = size.width * 0.36 * pulseValue;

    // Outer glow halo
    final haloPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(cx, cy), baseR * 1.55, haloPaint);

    // State-specific underlays
    switch (state) {
      case MentorAvatarState.listening:
        _drawListeningRings(canvas, cx, cy, baseR);
      case MentorAvatarState.thinking:
        _drawThinkingParticles(canvas, cx, cy, baseR);
      case MentorAvatarState.speaking:
        // waves drawn on top of sphere below
        break;
      case MentorAvatarState.idle:
        break;
    }

    // Shadow beneath sphere
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + baseR * 0.9),
        width: baseR * 1.6,
        height: baseR * 0.28,
      ),
      shadowPaint,
    );

    // Main sphere — radial gradient for pseudo-3D effect
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: [
          Color.alphaBlend(Colors.white.withValues(alpha: 0.55), accentColor),
          accentColor,
          Color.alphaBlend(Colors.black.withValues(alpha: 0.6), accentColor),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: baseR));
    canvas.drawCircle(Offset(cx, cy), baseR, spherePaint);

    // Specular highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(cx - baseR * 0.28, cy - baseR * 0.28),
      baseR * 0.22,
      highlightPaint,
    );

    // Speaking wave overlay
    if (state == MentorAvatarState.speaking) {
      _drawSpeakingWaves(canvas, cx, cy, baseR);
    }

    // Rim light (thin bright ring)
    final rimPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), baseR, rimPaint);
  }

  // ── Listening: expanding concentric rings ──

  void _drawListeningRings(Canvas canvas, double cx, double cy, double baseR) {
    for (int i = 0; i < 3; i++) {
      final phase = (ringsProgress + i / 3.0) % 1.0;
      final r = baseR * (1.1 + phase * 0.9);
      final alpha = (1.0 - phase) * 0.35;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = accentColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  // ── Thinking: rotating particle dots ──

  void _drawThinkingParticles(
    Canvas canvas,
    double cx,
    double cy,
    double baseR,
  ) {
    const count = 8;
    final orbitR = baseR * 1.28;
    for (int i = 0; i < count; i++) {
      final angle = thinkProgress * math.pi * 2 + (i / count) * math.pi * 2;
      final px = cx + orbitR * math.cos(angle);
      final py = cy + orbitR * math.sin(angle);
      final phase = (i / count + thinkProgress) % 1.0;
      final dotR = 3.5 + 2.5 * math.sin(phase * math.pi);
      canvas.drawCircle(
        Offset(px, py),
        dotR,
        Paint()
          ..color = accentColor.withValues(alpha: 0.55 + 0.3 * (1 - phase)),
      );
    }
  }

  // ── Speaking: horizontal sine-wave bands ──

  void _drawSpeakingWaves(Canvas canvas, double cx, double cy, double baseR) {
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: baseR - 1));
    canvas.save();
    canvas.clipPath(clipPath);

    const bands = 5;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (int b = 0; b < bands; b++) {
      final yOffset = cy - baseR * 0.5 + b * (baseR * 1.0 / (bands - 1));
      final path = Path();
      final phaseShift = wavesProgress * math.pi * 2 + b * math.pi / bands;
      for (double x = cx - baseR; x <= cx + baseR; x += 2) {
        final t = (x - (cx - baseR)) / (2 * baseR);
        final amplitude = baseR * 0.06 * math.sin(t * math.pi);
        final y = yOffset + amplitude * math.sin(t * math.pi * 5 + phaseShift);
        if (x == cx - baseR) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MentorAvatarPainter old) =>
      old.state != state ||
      old.pulseValue != pulseValue ||
      old.ringsProgress != ringsProgress ||
      old.thinkProgress != thinkProgress ||
      old.wavesProgress != wavesProgress ||
      old.accentColor != accentColor;
}
