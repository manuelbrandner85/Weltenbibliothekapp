/// 🌐 MENTOR SESSION SCREEN — 3D-Avatar + LiveKit-Modus
///
/// Immersive Vollbild-Erfahrung fuer Mentor-Sessions.
/// Zeigt einen perspektiv-projizierten 3D-Avatar ([MentorAvatar3d]) mit:
///   - idle: sanftes Pulsieren + langsame Gitter-Rotation
///   - listening: expandierende Ringe, schnellere Rotation
///   - thinking: orbitierende 3D-Partikel
///   - speaking: Schallwellen-Bands im Avatar-Orb
///
/// Technischer Stack:
///   - flutter_tts  fuer Text-to-Speech
///   - speech_to_text fuer Voice-Input (Classic-Modus)
///   - MentorLiveKitService fuer Audio-Verbindung (LiveKit-Modus)
///   - MentorService  fuer KI-Antworten + Session-Tracking
///   - MentorSessionModel  fuer Avatar-Zustand
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/mentor_session_model.dart';
import '../../services/mentor_livekit_service.dart';
import '../../services/mentor_service.dart';
import '../../widgets/mentor_avatar_3d.dart';

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
  late final MentorLiveKitService _liveKitService;

  // ── LiveKit / session state ──
  bool _liveKitModeEnabled = false;
  String? _sessionId;

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

  // Maps internal avatar state to the 3D widget enum.
  MentorAvatarState3d get _avatarState3d => switch (_session.avatarState) {
        MentorAvatarState.idle => MentorAvatarState3d.idle,
        MentorAvatarState.listening => MentorAvatarState3d.listening,
        MentorAvatarState.thinking => MentorAvatarState3d.thinking,
        MentorAvatarState.speaking => MentorAvatarState3d.speaking,
      };

  @override
  void initState() {
    super.initState();
    _session = MentorSessionModel(
      world: widget.world,
      personality: widget.personality,
    );
    _liveKitService = MentorLiveKitService();
    _liveKitService.addListener(_onLiveKitStateChanged);

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

  // ═══════════════════════════════════════════════════════════
  // LIVEKIT MODE
  // ═══════════════════════════════════════════════════════════

  void _onLiveKitStateChanged() {
    if (!mounted) return;
    setState(() {});
    if (_liveKitService.state == MentorLiveKitState.error) {
      final msg = _liveKitService.errorMessage ?? 'Verbindungsfehler';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('LiveKit: $msg')));
      setState(() => _liveKitModeEnabled = false);
    }
  }

  Future<void> _toggleLiveKitMode() async {
    if (_liveKitModeEnabled) {
      await _liveKitService.disconnect();
      if (_sessionId != null) {
        await _mentorService.endLiveSession(
          _sessionId!,
          messageCount: _messages.length,
        );
        _sessionId = null;
      }
      setState(() => _liveKitModeEnabled = false);
      return;
    }
    try {
      await _liveKitService.connect(widget.world);
      _sessionId = await _mentorService.startLiveSession(
        world: widget.world,
        personality: widget.personality,
        livekitRoom: _liveKitService.currentRoomName,
      );
      setState(() => _liveKitModeEnabled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live-Verbindung aktiv'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
    _liveKitService.removeListener(_onLiveKitStateChanged);
    _liveKitService.disconnect().ignore();
    _liveKitService.dispose();
    if (_sessionId != null) {
      _mentorService
          .endLiveSession(_sessionId!, messageCount: _messages.length)
          .ignore();
    }
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
    final lkColor =
        _liveKitModeEnabled ? _accent : Colors.white.withValues(alpha: 0.35);
    final lkIcon = switch (_liveKitService.state) {
      MentorLiveKitState.connecting => Icons.sync,
      MentorLiveKitState.connected => Icons.sensors,
      MentorLiveKitState.error => Icons.sensors_off,
      MentorLiveKitState.disconnected => Icons.sensors_off,
    };
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
          // LiveKit mode toggle
          IconButton(
            icon: Icon(lkIcon, color: lkColor, size: 22),
            onPressed: _liveKitService.state == MentorLiveKitState.connecting
                ? null
                : _toggleLiveKitMode,
            tooltip: _liveKitModeEnabled
                ? 'Live-Verbindung trennen'
                : 'Live-Verbindung starten',
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
        // Animated 3D avatar
        AnimatedBuilder(
          animation: Listenable.merge([
            _pulseCtrl,
            _ringsCtrl,
            _thinkCtrl,
            _wavesCtrl,
          ]),
          builder: (ctx, _) => MentorAvatar3d(
            personality: widget.personality,
            accentColor: _accent,
            state: _avatarState3d,
            pulseValue: _pulseAnim.value,
            ringsProgress: _ringsCtrl.value,
            thinkProgress: _thinkCtrl.value,
            wavesProgress: _wavesCtrl.value,
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
        // LiveKit connection indicator
        if (_liveKitModeEnabled) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _liveKitService.state == MentorLiveKitState.connected
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _liveKitService.state == MentorLiveKitState.connected
                    ? 'Live-Verbindung aktiv'
                    : 'Verbinde ...',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
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

// (Legacy _MentorAvatarPainter removed — replaced by MentorAvatar3d widget)
