/// 🎥 LIVEKIT GROUP CALL SCREEN — Komplett-Rebuild
///
/// Professionelle Vollbild-UI für LiveKit Audio-/Video-Gruppencalls.
/// Welt-spezifisches Design (Energie = Lila, Materie = Blau).
///
/// Architektur:
///   - `_ParticipantGrid` — responsive Kacheln für alle Teilnehmer
///   - `_ParticipantTile` — Einzelkachel mit Avatar, Mic-State, Sprech-Animation
///   - `_TopBar` — Glassmorphic Overlay: Raum, Timer, Teilnehmerzahl
///   - `_ControlBar` — 5 Aktionsbuttons + Auflegen
///   - `_StatusView` — Connecting / Error / Disconnected State
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../config/wb_design.dart';
import '../../providers/livekit_call_provider.dart';
import '../../services/audio_feedback_service.dart';
import '../../services/cowatch_service.dart';
import '../../services/incall_chat_service.dart';
import '../../services/livekit_call_service.dart';
import '../../services/live_caption_service.dart';
import '../../services/soundscape_service.dart';
import '../../widgets/cowatch_panel.dart';
import '../../widgets/incall_chat_panel.dart';
import '../../widgets/live_caption_overlay.dart';
import '../../widgets/livekit_mini_bar.dart';
import '../../widgets/livekit_reactions_overlay.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class LiveKitGroupCallScreen extends ConsumerStatefulWidget {
  final String roomName;
  final String world;
  final String displayName;
  final String? avatarUrl;
  // 🛋️ B5: kommt aus Pre-Join-Lobby.
  final bool audioOnly;
  // Wenn false → stumm beitreten (Zuhörer-Modus), User kann Mic später an/aus schalten.
  final bool initialMicEnabled;

  const LiveKitGroupCallScreen({
    super.key,
    required this.roomName,
    required this.world,
    required this.displayName,
    this.avatarUrl,
    this.audioOnly = false,
    this.initialMicEnabled = true,
  });

  @override
  ConsumerState<LiveKitGroupCallScreen> createState() =>
      _LiveKitGroupCallScreenState();
}

class _LiveKitGroupCallScreenState
    extends ConsumerState<LiveKitGroupCallScreen>
    with TickerProviderStateMixin {
  bool _hasJoined = false;
  bool _isLeaving = false;
  bool _captionsEnabled = false;
  // 🎵 B10.1/B10.2: Soundscape + Heilfrequenz
  bool _soundscapeEnabled = false;
  bool _heilEnabled = false;
  int _heilHz = 432;
  // 📺 B10.4: Co-Watch
  bool _coWatchVisible = false;
  String? _coWatchVideoId;
  StreamSubscription<CoWatchEvent>? _coWatchSub;
  // 💬 In-Call-Chat
  bool _chatVisible = false;
  // 🎨 B10.6: Raumstimmung (AudioFeedbackService hält den aktuellen Theme)
  // kein lokaler State — wir lesen direkt aus AudioFeedbackService.themeNotifier
  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _bgAnimation = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    // Mini-Bar wird ausgeblendet solange dieser Screen sichtbar ist
    LiveKitScreenVisibility.instance.setVisible(true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _join());

    // 📺 B10.4: CoWatch-Events vom Remote empfangen
    _coWatchSub = CoWatchService.instance.eventStream.listen((event) {
      if (!mounted) return;
      if (event.action == CoWatchAction.load && event.videoId != null) {
        setState(() {
          _coWatchVideoId = event.videoId;
          _coWatchVisible = true;
        });
      } else if (event.action == CoWatchAction.close) {
        setState(() {
          _coWatchVisible = false;
          _coWatchVideoId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _coWatchSub?.cancel();
    LiveKitScreenVisibility.instance.setVisible(false);
    _bgController.dispose();
    SoundscapeService.instance.stopAll();
    super.dispose();
  }

  Future<void> _join() async {
    if (_hasJoined) return;
    final svc = ref.read(livekitCallServiceProvider);
    try {
      await svc.joinRoom(
        roomName: widget.roomName,
        world: widget.world,
        displayName: widget.displayName,
        avatarUrl: widget.avatarUrl,
        audioOnly: widget.audioOnly,
        initialMicEnabled: widget.initialMicEnabled,
      );
      if (mounted) setState(() => _hasJoined = true);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _leaveAndPop() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    final svc = ref.read(livekitCallServiceProvider);
    await SoundscapeService.instance.stopAll();
    await svc.leaveRoom();
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    final accent = WbDesign.accent(widget.world);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: WbDesign.surface(widget.world),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
            side: BorderSide(color: WbDesign.borderMedium),
          ),
          title: const Text(
            'Anruf beenden?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          content: Text(
            'Möchtest du den laufenden Anruf wirklich verlassen?',
            style: TextStyle(color: WbDesign.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Abbrechen',
                  style: TextStyle(color: WbDesign.textTertiary)),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.call_end_rounded, size: 16),
              label: const Text('Verlassen'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF1744),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WbDesign.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(livekitCallProvider);
    final state = svc.connectionState;
    final accent = WbDesign.accent(widget.world);
    final bg = WbDesign.background(widget.world);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave()) await _leaveAndPop();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: ValueListenableBuilder<RoomTheme>(
          valueListenable: AudioFeedbackService.instance.themeNotifier,
          builder: (_, theme, __) => AnimatedBuilder(
            animation: _bgAnimation,
            builder: (_, child) => Stack(
              fit: StackFit.expand,
              children: [
                // 🎨 B10.6: Raumstimmung — Hintergrund wechselt je nach Theme
                _AnimatedBackground(
                  world: widget.world,
                  animation: _bgAnimation,
                  accent: accent,
                  theme: theme,
                ),
              child!,
              // 💖 Bundle 4: Floating-Reactions-Overlay liegt ÜBER allem
              // (Body + ControlBar) damit Emojis durchgängig nach oben
              // floaten können. IgnorePointer schützt Touch-Events.
              LiveKitReactionsOverlay(reactions: svc.reactionsStream),
              // 🎙️ B8: Caption-Overlay (liegt über allem, unter Reactions)
              if (_captionsEnabled)
                LiveCaptionOverlay(service: LiveCaptionService.instance),
              // 📺 B10.4: Co-Watch-Panel (schwebend, 55% Höhe)
              if (_coWatchVisible && _coWatchVideoId != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 100,
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: CoWatchPanel(
                    videoId: _coWatchVideoId!,
                    world: widget.world,
                    isHost: true,
                    service: CoWatchService.instance,
                    onClose: () => setState(() {
                      _coWatchVisible = false;
                    }),
                  ),
                ),
              // 💬 In-Call-Chat-Panel (schwebend über ControlBar)
              if (_chatVisible)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 100,
                  height: MediaQuery.of(context).size.height * 0.52,
                  child: InCallChatPanel(
                    world: widget.world,
                    service: InCallChatService.instance,
                    onClose: () => setState(() => _chatVisible = false),
                  ),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                  roomName: widget.roomName,
                  world: widget.world,
                  state: state,
                  // Bundle 4.5: Notifier statt Wert übergeben — TopBar
                  // rebuildet nur die Sekunden-Zelle, nicht den ganzen
                  // Screen pro Sekunde.
                  durationNotifier: svc.durationNotifier,
                  participantCount: svc.totalParticipantCount,
                  audioOnly: svc.audioOnlyMode,
                  onToggleAudioOnly: () => svc.toggleAudioOnlyMode(),
                  viewMode: svc.viewMode,
                  onToggleViewMode: () => svc.toggleViewMode(),
                  captionsEnabled: _captionsEnabled,
                  onToggleCaptions: () async {
                    final nowOn = await LiveCaptionService.instance.toggle();
                    if (mounted) setState(() => _captionsEnabled = nowOn);
                  },
                  // 🎵 B10.1: Soundscape-Atmosphäre
                  soundscapeEnabled: _soundscapeEnabled,
                  onToggleSoundscape: () async {
                    final nowOn = await SoundscapeService.instance
                        .toggleSoundscape(widget.world);
                    if (mounted) setState(() => _soundscapeEnabled = nowOn);
                  },
                  // 🎵 B10.2: Heilfrequenz (nur Energie)
                  heilEnabled: _heilEnabled,
                  heilHz: _heilHz,
                  onToggleHeil: () async {
                    final nowOn = await SoundscapeService.instance
                        .toggleHeilfrequenz();
                    if (mounted) setState(() => _heilEnabled = nowOn);
                  },
                  onSelectHeilHz: (hz) async {
                    setState(() => _heilHz = hz);
                    await SoundscapeService.instance.toggleHeilfrequenz(hz: hz);
                    if (mounted) setState(() => _heilEnabled = true);
                  },
                  onClose: () async {
                    if (await _confirmLeave()) await _leaveAndPop();
                  },
                ),
                Expanded(child: _buildBody(state, svc, accent)),
                _ControlBar(
                  world: widget.world,
                  service: svc,
                  onCoWatch: () async {
                    final url = await showCoWatchInputDialog(
                        context, widget.world);
                    if (url == null || !mounted) return;
                    await CoWatchService.instance.loadVideo(url);
                    setState(() {
                      _coWatchVideoId =
                          CoWatchService.instance.currentVideoId;
                      _coWatchVisible =
                          CoWatchService.instance.currentVideoId != null;
                    });
                  },
                  onToggleChat: () {
                    setState(() {
                      _chatVisible = !_chatVisible;
                      if (_chatVisible) {
                        InCallChatService.instance.markAllRead();
                      }
                    });
                  },
                  chatVisible: _chatVisible,
                  onLeave: () async {
                    if (await _confirmLeave()) await _leaveAndPop();
                  },
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    LiveKitConnectionState state,
    LiveKitCallService svc,
    Color accent,
  ) {
    switch (state) {
      case LiveKitConnectionState.connecting:
      case LiveKitConnectionState.reconnecting:
        return _StatusView(
          icon: Icons.cell_tower_rounded,
          title: state == LiveKitConnectionState.reconnecting
              ? 'Verbindung wird wiederhergestellt …'
              : 'Verbinde mit dem Anruf …',
          subtitle: 'Raum: ${_roomDisplayName(widget.roomName)}',
          accent: accent,
          showSpinner: true,
        );
      case LiveKitConnectionState.error:
        return _StatusView(
          icon: Icons.error_outline_rounded,
          title: 'Verbindung fehlgeschlagen',
          subtitle: svc.errorMessage ?? 'Unbekannter Fehler.',
          accent: const Color(0xFFFF1744),
          showRetry: true,
          onRetry: () async {
            // 🛑 Bundle 3.7: leaveRoom() vor _join() verhindert Doppel-
            // Connection (z.B. bei laufendem Reconnect-Versuch im Service).
            await svc.leaveRoom();
            if (!mounted) return;
            setState(() => _hasJoined = false);
            _join();
          },
        );
      case LiveKitConnectionState.disconnected:
        if (!_hasJoined) {
          return _StatusView(
            icon: Icons.cell_tower_rounded,
            title: 'Verbinde …',
            subtitle: 'Raum: ${_roomDisplayName(widget.roomName)}',
            accent: accent,
            showSpinner: true,
          );
        }
        return _StatusView(
          icon: Icons.call_end_rounded,
          title: 'Verbindung getrennt',
          subtitle: 'Der Anruf wurde beendet oder die Verbindung\nwurde unterbrochen.',
          accent: WbDesign.textTertiary,
          showRetry: true,
          onRetry: () async {
            await svc.leaveRoom();
            if (!mounted) return;
            setState(() => _hasJoined = false);
            _join();
          },
        );
      case LiveKitConnectionState.connected:
        // 🌌 Bundle 3: ValueListenableBuilder auf speakersNotifier.
        // 🔁 Bundle 6: viewMode entscheidet ob Gallery oder Speaker-View.
        return ValueListenableBuilder<Set<String>>(
          valueListenable: svc.speakersNotifier,
          builder: (_, speakers, __) {
            if (svc.viewMode == LiveKitViewMode.speaker) {
              return _SpeakerView(
                world: widget.world,
                localName: widget.displayName,
                localAvatarUrl: widget.avatarUrl,
                localIdentity: svc.room?.localParticipant?.identity,
                remoteNames: svc.remoteParticipantNames,
                micEnabled: svc.micEnabled,
                accent: accent,
                localVideoTrack: svc.localVideoTrack,
                remoteVideoTracks: svc.remoteVideoTracks,
                remoteMicActive: svc.isRemoteMicActive,
                localHandRaised: svc.handRaised,
                remoteHandRaised: svc.isRemoteHandRaised,
                remoteAvatarUrl: svc.remoteAvatarUrl,
                activeSpeakers: speakers,
                qualityFor: svc.connectionQualityFor,
                pinnedIdentity: svc.pinnedIdentity,
                onSpotlight: (id) => svc.sendSpotlight(id),
              );
            }
            return _ParticipantGrid(
              world: widget.world,
              localName: widget.displayName,
              localAvatarUrl: widget.avatarUrl,
              localIdentity: svc.room?.localParticipant?.identity,
              remoteNames: svc.remoteParticipantNames,
              micEnabled: svc.micEnabled,
              cameraEnabled: svc.cameraEnabled,
              accent: accent,
              localVideoTrack: svc.localVideoTrack,
              remoteVideoTracks: svc.remoteVideoTracks,
              remoteMicActive: svc.isRemoteMicActive,
              localHandRaised: svc.handRaised,
              remoteHandRaised: svc.isRemoteHandRaised,
              remoteAvatarUrl: svc.remoteAvatarUrl,
              activeSpeakers: speakers,
              qualityFor: svc.connectionQualityFor,
              onSpotlight: (id) => svc.sendSpotlight(id),
            );
          },
        );
    }
  }

  String _roomDisplayName(String r) {
    final parts = r.split('-');
    if (parts.length >= 3) {
      final last = parts.skip(2).join(' ');
      return last.isNotEmpty ? '${last[0].toUpperCase()}${last.substring(1)}' : r;
    }
    return r;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED BACKGROUND — Welt-spezifisches Pattern
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedBackground extends StatelessWidget {
  final String world;
  final Animation<double> animation;
  final Color accent;
  final RoomTheme theme;

  const _AnimatedBackground({
    required this.world,
    required this.animation,
    required this.accent,
    this.theme = RoomTheme.standard,
  });

  @override
  Widget build(BuildContext context) {
    final t = animation.value;
    CustomPainter painter;

    switch (theme) {
      case RoomTheme.netzwerk:
        painter = _NetzwerkPainter(t, accent);
      case RoomTheme.kosmos:
        painter = _KosmosPainter(t, accent);
      case RoomTheme.mandala:
        painter = _MandalaPainter(t, accent);
      case RoomTheme.kristall:
        painter = _KristallPainter(t, accent);
      case RoomTheme.standard:
        painter = world == 'materie'
            ? _MateriePainter(t, accent)
            : _EnergiePainter(t, accent);
    }

    return CustomPaint(painter: painter);
  }
}

/// Materie — strukturiertes Hexagon-Grid mit pulsierenden Knotenpunkten.
/// Symbolisiert die feste, strukturierte Natur der materiellen Welt.
class _MateriePainter extends CustomPainter {
  final double t;
  final Color accent;

  _MateriePainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.06);

    // Hexagon-Grid (subtil)
    const hexRadius = 60.0;
    final hexHeight = hexRadius * math.sqrt(3);
    final cols = (size.width / (hexRadius * 1.5)).ceil() + 1;
    final rows = (size.height / hexHeight).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * hexRadius * 1.5;
        final y = row * hexHeight + (col.isOdd ? hexHeight / 2 : 0);
        _drawHex(canvas, paint, Offset(x, y), hexRadius);
      }
    }

    // Pulsierende Glow-Punkte an Knotenpunkten
    final pulsePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * 0.2) % 1.0;
      final angle = i * math.pi * 2 / 5 + t * math.pi * 0.3;
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.35;
      final y = size.height * 0.45 + math.sin(angle) * size.height * 0.25;
      final radius = 80.0 + 40.0 * phase;
      pulsePaint.shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.10 * (1 - phase)),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      canvas.drawCircle(Offset(x, y), radius, pulsePaint);
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MateriePainter old) => old.t != t;
}

/// Energie — fließende Aurora-Wellen.
/// Symbolisiert die fließende, sich wandelnde Natur der Energie.
class _EnergiePainter extends CustomPainter {
  final double t;
  final Color accent;

  _EnergiePainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    // Mehrere überlagerte Sinus-Wellen erzeugen den Aurora-Effekt
    for (int wave = 0; wave < 4; wave++) {
      final path = Path();
      final waveY = size.height * (0.3 + wave * 0.15);
      final amplitude = 40.0 + wave * 15.0;
      final frequency = 0.005 + wave * 0.001;
      final phase = t * math.pi * 2 + wave * math.pi / 3;

      path.moveTo(0, waveY);
      for (double x = 0; x <= size.width; x += 4) {
        final y = waveY + math.sin(x * frequency + phase) * amplitude;
        path.lineTo(x, y);
      }

      // Aurora-Gradient: oben farbig, fließt nach unten aus
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 80.0 + wave * 20.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.04 + wave * 0.005),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, waveY - 60, size.width, 120));
      canvas.drawPath(path, paint);
    }

    // Schwebende Licht-Partikel (Aura-Effekt)
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 15; i++) {
      final seed = i * 0.137;
      final angle = (seed + t * 0.2) * math.pi * 2;
      final radiusPercent = 0.2 + ((i * 7) % 60) / 100;
      final x = size.width * 0.5 +
          math.cos(angle) * size.width * radiusPercent;
      final y = size.height * 0.5 +
          math.sin(angle * 1.3) * size.height * radiusPercent;
      final particleSize = 1.5 + math.sin(t * math.pi * 2 + i) * 0.8;
      particlePaint.color = accent.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
      // Glow
      particlePaint.color = accent.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(x, y), particleSize * 3, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnergiePainter old) => old.t != t;
}

// ─── B10.6: Raumstimmung-Painter ─────────────────────────────────────────────

/// Materie — dichtes Datennetz mit pulsierenden blauen Knotenpunkten.
class _NetzwerkPainter extends CustomPainter {
  final double t;
  final Color accent;
  _NetzwerkPainter(this.t, this.accent);

  static const _nodes = <Offset>[
    Offset(0.15, 0.12), Offset(0.45, 0.08), Offset(0.80, 0.18),
    Offset(0.10, 0.38), Offset(0.35, 0.35), Offset(0.65, 0.30),
    Offset(0.88, 0.42), Offset(0.20, 0.60), Offset(0.50, 0.58),
    Offset(0.75, 0.62), Offset(0.12, 0.80), Offset(0.40, 0.82),
    Offset(0.70, 0.88), Offset(0.90, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = accent.withValues(alpha: 0.12);

    // Verbindungslinien zwischen nahen Knoten
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final a = Offset(_nodes[i].dx * size.width, _nodes[i].dy * size.height);
        final b = Offset(_nodes[j].dx * size.width, _nodes[j].dy * size.height);
        final dist = (a - b).distance;
        if (dist < size.width * 0.38) {
          linePaint.color = accent.withValues(alpha: 0.09 * (1 - dist / (size.width * 0.38)));
          canvas.drawLine(a, b, linePaint);
        }
      }
    }

    // Pulsierende Knoten mit animiertem Glow
    for (int i = 0; i < _nodes.length; i++) {
      final cx = _nodes[i].dx * size.width;
      final cy = _nodes[i].dy * size.height;
      final phase = (t + i * 0.07) % 1.0;
      final glowR = 40.0 + 20.0 * phase;
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(colors: [
          accent.withValues(alpha: 0.18 * (1 - phase)),
          accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR));
      canvas.drawCircle(Offset(cx, cy), glowR, glowPaint);

      // Kern-Dot
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = accent.withValues(alpha: 0.55);
      canvas.drawCircle(Offset(cx, cy), 2.5, dotPaint);
    }

    // Datenstrom-Partikel entlang einer Linie
    final streamPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.65);
    for (int i = 0; i < 6; i++) {
      final frac = (t + i / 6.0) % 1.0;
      final startIdx = i % _nodes.length;
      final endIdx = (i + 3) % _nodes.length;
      final sx = _nodes[startIdx].dx * size.width;
      final sy = _nodes[startIdx].dy * size.height;
      final ex = _nodes[endIdx].dx * size.width;
      final ey = _nodes[endIdx].dy * size.height;
      final px = sx + (ex - sx) * frac;
      final py = sy + (ey - sy) * frac;
      canvas.drawCircle(Offset(px, py), 2.0, streamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetzwerkPainter old) => old.t != t;
}

/// Materie — tiefer Weltraum mit rotem Nebel und Sternfeld.
class _KosmosPainter extends CustomPainter {
  final double t;
  final Color accent;
  _KosmosPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    // Sternenfeld (statisch, seed-basiert)
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 80; i++) {
      final seed = i * 0.137;
      final x = ((seed * 137.7 + 0.5) % 1.0) * size.width;
      final y = ((seed * 97.3 + 0.3) % 1.0) * size.height;
      final brightness = 0.2 + ((i * 31) % 60) / 150.0;
      final twinkle = brightness + 0.15 * math.sin(t * math.pi * 2 + i);
      starPaint.color = Colors.white.withValues(alpha: twinkle.clamp(0.0, 0.9));
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.4, starPaint);
    }

    // Roter Nebel-Glow (2 überlagerte Wolken)
    for (int w = 0; w < 2; w++) {
      final cx = size.width * (0.3 + w * 0.4);
      final cy = size.height * (0.4 + w * 0.15);
      final r = size.width * (0.35 + w * 0.10);
      final phase = (t + w * 0.4) % 1.0;
      final nebulaPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(colors: [
          accent.withValues(alpha: 0.10 + 0.04 * math.sin(phase * math.pi * 2)),
          accent.withValues(alpha: 0.03),
          accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, nebulaPaint);
    }

    // Heller Kern (Zentralstern)
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(colors: [
        accent.withValues(alpha: 0.28),
        accent.withValues(alpha: 0),
      ]).createShader(
          Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.45),
              radius: size.width * 0.18));
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.45), size.width * 0.18, corePaint);
  }

  @override
  bool shouldRepaint(covariant _KosmosPainter old) => old.t != t;
}

/// Energie — rotierendes Mandala-Muster aus geometrischen Linien.
class _MandalaPainter extends CustomPainter {
  final double t;
  final Color accent;
  _MandalaPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width * 0.45;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 3 rotierende Ringe mit je 12 Speichen
    for (int ring = 0; ring < 3; ring++) {
      final r = maxR * (0.35 + ring * 0.22);
      final rotation = t * math.pi * (ring.isEven ? 0.4 : -0.3) + ring * math.pi / 6;
      final alpha = 0.08 + ring * 0.03;
      paint.color = accent.withValues(alpha: alpha);

      // Kreisbogen
      canvas.drawCircle(Offset(cx, cy), r, paint);

      // Speichen
      for (int spoke = 0; spoke < 12; spoke++) {
        final angle = rotation + spoke * math.pi * 2 / 12;
        final innerR = r * 0.35;
        canvas.drawLine(
          Offset(cx + math.cos(angle) * innerR, cy + math.sin(angle) * innerR),
          Offset(cx + math.cos(angle) * r, cy + math.sin(angle) * r),
          paint,
        );
      }
    }

    // Leuchtender Kern
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(colors: [
        accent.withValues(alpha: 0.22 + 0.08 * math.sin(t * math.pi * 2)),
        accent.withValues(alpha: 0),
      ]).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: maxR * 0.15));
    canvas.drawCircle(Offset(cx, cy), maxR * 0.15, corePaint);

    // Äußerer Glow-Ring
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(colors: [
        accent.withValues(alpha: 0),
        accent.withValues(alpha: 0.05),
        accent.withValues(alpha: 0),
      ], stops: const [0.6, 0.8, 1.0]).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: maxR));
    canvas.drawCircle(Offset(cx, cy), maxR, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter old) => old.t != t;
}

/// Energie — schwebende Licht-Kristall-Scherben mit Prisma-Effekt.
class _KristallPainter extends CustomPainter {
  final double t;
  final Color accent;
  _KristallPainter(this.t, this.accent);

  // 10 Kristall-Scherben mit festen Seed-Positionen
  static const _seeds = <(double, double, double)>[
    (0.15, 0.20, 0.0), (0.45, 0.12, 0.2), (0.78, 0.25, 0.4),
    (0.08, 0.55, 0.6), (0.35, 0.65, 0.8), (0.62, 0.50, 0.1),
    (0.88, 0.60, 0.3), (0.25, 0.82, 0.5), (0.58, 0.85, 0.7),
    (0.82, 0.88, 0.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int i = 0; i < _seeds.length; i++) {
      final (sx, sy, phase0) = _seeds[i];
      final phase = (t * 0.7 + phase0) % 1.0;
      final floatY = math.sin(phase * math.pi * 2) * 12;
      final cx = sx * size.width;
      final cy = sy * size.height + floatY;
      final scale = 12.0 + (i % 3) * 8.0;
      final rotation = t * math.pi * (i.isEven ? 0.15 : -0.10) + i;

      // Kristall-Hexagon
      final path = Path();
      for (int v = 0; v < 6; v++) {
        final angle = rotation + v * math.pi / 3;
        final px = cx + math.cos(angle) * scale;
        final py = cy + math.sin(angle) * scale;
        if (v == 0) path.moveTo(px, py); else path.lineTo(px, py);
      }
      path.close();

      final alpha = 0.05 + 0.04 * math.sin(phase * math.pi * 2 + i);
      paint.color = accent.withValues(alpha: alpha);
      canvas.drawPath(path, paint);

      strokePaint.color = accent.withValues(alpha: alpha * 3.5);
      canvas.drawPath(path, strokePaint);

      // Innerer Glanz-Punkt
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.30 * (1 - phase)),
          accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: scale));
      canvas.drawCircle(Offset(cx, cy), scale * 0.4, glowPaint);
    }

    // Sanfter Hintergrund-Glow in der Mitte
    final bgGlow = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(colors: [
        accent.withValues(alpha: 0.06),
        accent.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.55));
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.55, bgGlow);
  }

  @override
  bool shouldRepaint(covariant _KristallPainter old) => old.t != t;
}

/// Globaler ValueNotifier für Spatial-Audio-Toggle (UI-State, kein setState im Screen).
class _SpatialNotifier extends ValueNotifier<bool> {
  _SpatialNotifier._() : super(AudioFeedbackService.instance.spatialEnabled);
  static final instance = _SpatialNotifier._();
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String roomName;
  final String world;
  final LiveKitConnectionState state;
  final ValueNotifier<int> durationNotifier;
  final int participantCount;
  final bool audioOnly;
  final VoidCallback onToggleAudioOnly;
  // 🔁 B6: Layout-Toggle (gallery / speaker-view)
  final LiveKitViewMode viewMode;
  final VoidCallback onToggleViewMode;
  // 🎙️ B8: Live-Untertitel
  final bool captionsEnabled;
  final VoidCallback onToggleCaptions;
  // 🎵 B10.1: Soundscape-Atmosphäre
  final bool soundscapeEnabled;
  final VoidCallback onToggleSoundscape;
  // 🎵 B10.2: Heilfrequenz (Energie-Welt)
  final bool heilEnabled;
  final int heilHz;
  final VoidCallback onToggleHeil;
  final void Function(int hz) onSelectHeilHz;
  final VoidCallback onClose;

  const _TopBar({
    required this.roomName,
    required this.world,
    required this.state,
    required this.durationNotifier,
    required this.participantCount,
    required this.audioOnly,
    required this.onToggleAudioOnly,
    required this.viewMode,
    required this.onToggleViewMode,
    required this.captionsEnabled,
    required this.onToggleCaptions,
    required this.soundscapeEnabled,
    required this.onToggleSoundscape,
    required this.heilEnabled,
    required this.heilHz,
    required this.onToggleHeil,
    required this.onSelectHeilHz,
    required this.onClose,
  });

  static String _formatDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600 ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$sec' : '$m:$sec';
  }

  Color _dotColor() {
    switch (state) {
      case LiveKitConnectionState.connected:
        return const Color(0xFF4CAF50);
      case LiveKitConnectionState.reconnecting:
      case LiveKitConnectionState.connecting:
        return const Color(0xFFFFB300);
      case LiveKitConnectionState.error:
        return const Color(0xFFFF1744);
      case LiveKitConnectionState.disconnected:
        return WbDesign.textTertiary;
    }
  }

  /// Liefert das nicht-zeit-abhängige State-Label oder null wenn der
  /// Caller eine Live-Sekunden-Anzeige rendern soll.
  String? _staticStateLabel() {
    switch (state) {
      case LiveKitConnectionState.connected:
        return null; // wird via ValueListenableBuilder gerendert
      case LiveKitConnectionState.connecting:
        return 'Verbinde …';
      case LiveKitConnectionState.reconnecting:
        return 'Wiederverbinde …';
      case LiveKitConnectionState.error:
        return 'Fehler';
      case LiveKitConnectionState.disconnected:
        return 'Nicht verbunden';
    }
  }

  String _roomDisplayName(String r) {
    final parts = r.split('-');
    if (parts.length >= 3) {
      final last = parts.skip(2).join(' ');
      return last.isNotEmpty ? '${last[0].toUpperCase()}${last.substring(1)}' : r;
    }
    return r;
  }

  void _showMoreOptions(BuildContext context) {
    final accent = WbDesign.accent(world);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: WbDesign.surface(world).withValues(alpha: 0.96),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                    color: accent.withValues(alpha: 0.25), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WbDesign.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, color: accent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Weitere Optionen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Atmosphäre (Hintergrund-Sound)
                _MoreOptionTile(
                  icon: soundscapeEnabled
                      ? Icons.graphic_eq_rounded
                      : Icons.music_note_rounded,
                  title: 'Atmosphäre',
                  subtitle: soundscapeEnabled
                      ? 'Hintergrund-Sound läuft — Tippen zum Stoppen'
                      : 'Beruhigender Hintergrund-Sound für den Call',
                  active: soundscapeEnabled,
                  accent: accent,
                  onTap: () {
                    Navigator.pop(ctx);
                    onToggleSoundscape();
                  },
                ),
                // Heilfrequenz (nur Energie-Welt)
                if (world == 'energie')
                  _MoreOptionTile(
                    icon: Icons.self_improvement_rounded,
                    title: heilEnabled
                        ? 'Heilfrequenz: $heilHz Hz'
                        : 'Heilfrequenz',
                    subtitle: heilEnabled
                        ? 'Frequenz läuft — Tippen zum Wechseln oder Stoppen'
                        : 'Solfeggio-Frequenzen (174–963 Hz) zur Stimmung',
                    active: heilEnabled,
                    accent: accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showHeilfrequenzPicker(context);
                    },
                  ),
                // Audio-Only-Modus
                _MoreOptionTile(
                  icon:
                      audioOnly ? Icons.headset_rounded : Icons.headset_outlined,
                  title: 'Nur Audio',
                  subtitle: audioOnly
                      ? 'Kamera deaktiviert — spart Akku und Daten'
                      : 'Kamera ausschalten für mehr Akku-Laufzeit',
                  active: audioOnly,
                  accent: accent,
                  onTap: () {
                    Navigator.pop(ctx);
                    onToggleAudioOnly();
                  },
                ),
                // 🎨 B10.6: Raumstimmung
                Builder(builder: (ctx2) {
                  final theme = AudioFeedbackService.instance.currentTheme;
                  return _MoreOptionTile(
                    icon: theme.icon,
                    title: 'Raumstimmung: ${theme.label}',
                    subtitle: 'Hintergrund-Atmosphäre des Anrufs anpassen',
                    active: theme != RoomTheme.standard,
                    accent: accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRaumstimmungPicker(context);
                    },
                  );
                }),
                // 🔊 B10.8: Spatial Audio (Sprecher-Ducking)
                ValueListenableBuilder<bool>(
                  valueListenable: _SpatialNotifier.instance,
                  builder: (_, spatialOn, __) => _MoreOptionTile(
                    icon: spatialOn
                        ? Icons.surround_sound_rounded
                        : Icons.surround_sound_outlined,
                    title: 'Spatial Audio',
                    subtitle: spatialOn
                        ? 'Aktiv — Sprecher im Fokus, andere leiser'
                        : 'Aktiver Sprecher wird hervorgehoben',
                    active: spatialOn,
                    accent: accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      AudioFeedbackService.instance.toggleSpatial();
                      _SpatialNotifier.instance.value =
                          AudioFeedbackService.instance.spatialEnabled;
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRaumstimmungPicker(BuildContext context) {
    final accent = WbDesign.accent(world);
    final themes = RoomTheme.values
        .where((th) => th.availableFor(world))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: WbDesign.surface(world).withValues(alpha: 0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                      color: accent.withValues(alpha: 0.25), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: WbDesign.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.palette_outlined, color: accent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Raumstimmung',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...themes.map((theme) {
                    final isCurrent =
                        AudioFeedbackService.instance.currentTheme == theme;
                    return InkWell(
                      onTap: () {
                        AudioFeedbackService.instance.setTheme(theme);
                        setModalState(() {});
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? accent.withValues(alpha: 0.40)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? accent.withValues(alpha: 0.20)
                                    : Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(theme.icon,
                                  color: isCurrent ? accent : WbDesign.textTertiary,
                                  size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.label,
                                    style: TextStyle(
                                      color: isCurrent ? accent : Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    theme.description,
                                    style: TextStyle(
                                      color: WbDesign.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Icon(Icons.check_circle_rounded,
                                  color: accent, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHeilfrequenzPicker(BuildContext context) {
    final accent = WbDesign.accent(world);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: WbDesign.surface(world).withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.25), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WbDesign.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.self_improvement_rounded,
                          color: accent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Heilfrequenz wählen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (heilEnabled)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onToggleHeil();
                          },
                          child: Text('Aus',
                              style: TextStyle(
                                  color: WbDesign.textTertiary, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: kHeilfrequenzen.length,
                    itemBuilder: (_, i) {
                      final entry = kHeilfrequenzen[i];
                      final isSelected =
                          heilEnabled && entry.hz == heilHz;
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelectHeilHz(entry.hz);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.40)
                                  : WbDesign.borderMedium
                                      .withValues(alpha: 0.0),
                              width: isSelected ? 1 : 0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  entry.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? accent
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.description,
                                  style: TextStyle(
                                    color: WbDesign.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.volume_up_rounded,
                                    color: accent, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(ctx).padding.bottom + 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(world);
    final isMaterie = world == 'materie';
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            // Welt-spezifischer Top-Gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WbDesign.surface(world).withValues(alpha: 0.92),
                WbDesign.surface(world).withValues(alpha: 0.78),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: accent.withValues(alpha: 0.20),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Welt-Icon mit Aura
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: WbDesign.hero(world),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isMaterie
                        ? Icons.hexagon_rounded
                        : Icons.auto_awesome_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Raum-Info — mit Welt-Branding
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _roomDisplayName(roomName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        // Status-Dot direkt am Raumnamen
                        _PulsingDot(
                          color: _dotColor(),
                          pulse: state ==
                                  LiveKitConnectionState.connecting ||
                              state ==
                                  LiveKitConnectionState.reconnecting,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    // Welt-Branding-Zeile
                    Row(
                      children: [
                        Text(
                          isMaterie
                              ? 'Weltenbibliothek · Materie'
                              : 'Weltenbibliothek · Energie',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: WbDesign.textTertiary
                                .withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Builder(builder: (_) {
                          final staticLabel = _staticStateLabel();
                          final labelStyle = TextStyle(
                            color: state ==
                                    LiveKitConnectionState.connected
                                ? const Color(0xFF4CAF50)
                                : WbDesign.textTertiary,
                            fontSize: 10,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                            fontWeight: FontWeight.w600,
                          );
                          if (staticLabel != null) {
                            return Text(staticLabel, style: labelStyle);
                          }
                          // Bundle 4.5: NUR die Sekundenanzeige rebuildet
                          // pro Tick, nicht der ganze Screen.
                          return ValueListenableBuilder<int>(
                            valueListenable: durationNotifier,
                            builder: (_, secs, __) =>
                                Text(_formatDuration(secs), style: labelStyle),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              // Teilnehmer-Badge
              if (participantCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(WbDesign.radiusPill),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded,
                          size: 13, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        '$participantCount',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // 🔁 B6: Ansicht wechseln (Gallery ↔ Speaker)
              _TopBarBtn(
                icon: viewMode == LiveKitViewMode.speaker
                    ? Icons.grid_view_rounded
                    : Icons.account_box_rounded,
                label: 'Ansicht',
                active: viewMode == LiveKitViewMode.speaker,
                accent: accent,
                onTap: onToggleViewMode,
              ),
              // 🎙️ B8: Untertitel
              _TopBarBtn(
                icon: Icons.closed_caption_rounded,
                label: 'Untertitel',
                active: captionsEnabled,
                accent: accent,
                onTap: onToggleCaptions,
              ),
              // ⋮ Mehr Optionen (Atmosphäre, Heilfrequenz, Audio-Only)
              Builder(builder: (ctx) => _TopBarBtn(
                icon: Icons.more_vert_rounded,
                label: 'Mehr',
                active: soundscapeEnabled || heilEnabled || audioOnly,
                accent: accent,
                onTap: () => _showMoreOptions(ctx),
              )),
              // Schließen
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: 'Anruf beenden',
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close_rounded,
                    color: WbDesign.textTertiary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TopBar-Hilfselemente ────────────────────────────────────────────────────

/// Kleiner Icon-Button mit sichtbarem Text-Label darunter für die TopBar.
class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _TopBarBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: active ? accent : WbDesign.textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: active ? accent : WbDesign.textTertiary,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zeile in der "Mehr Optionen"-BottomSheet mit Icon, Titel, Beschreibung.
class _MoreOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _MoreOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active
                    ? accent.withValues(alpha: 0.18)
                    : WbDesign.borderMedium.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 22, color: active ? accent : WbDesign.textTertiary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: active ? accent : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: WbDesign.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICIPANT GRID
// ═══════════════════════════════════════════════════════════════════════════

class _ParticipantGrid extends StatelessWidget {
  final String world;
  final String localName;
  final String? localAvatarUrl;
  final String? localIdentity;
  final List<String> remoteNames;
  final bool micEnabled;
  final bool cameraEnabled;
  final Color accent;
  final lk.VideoTrack? localVideoTrack;
  final Map<String, lk.VideoTrack?> remoteVideoTracks;
  final bool Function(String) remoteMicActive;
  final bool localHandRaised;
  final bool Function(String) remoteHandRaised;
  final String? Function(String) remoteAvatarUrl;
  // 📶 B2: Verbindungs-Qualität-Callback
  final LiveKitParticipantQuality Function(String) qualityFor;
  // 🌌 B3: aktive Sprecher (Identities-Set) für Aura-Glow
  final Set<String> activeSpeakers;
  // 🔦 B11: Spotlight-Callback (identity → für alle pinnen)
  final void Function(String identity)? onSpotlight;

  const _ParticipantGrid({
    required this.world,
    required this.localName,
    required this.localAvatarUrl,
    this.localIdentity,
    required this.remoteNames,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.accent,
    required this.localVideoTrack,
    required this.remoteVideoTracks,
    required this.remoteMicActive,
    required this.localHandRaised,
    required this.remoteHandRaised,
    required this.remoteAvatarUrl,
    required this.qualityFor,
    this.activeSpeakers = const <String>{},
    this.onSpotlight,
  });

  /// Map: index → (videoTrack, micActive, handRaised, avatarUrl)
  /// index 0 = local, 1+ = remote
  ({lk.VideoTrack? video, bool mic, bool hand, String? avatar})
      _trackInfoFor(int index) {
    if (index == 0) {
      return (
        video: localVideoTrack,
        mic: micEnabled,
        hand: localHandRaised,
        avatar: localAvatarUrl,
      );
    }
    final identities = remoteVideoTracks.keys.toList();
    final i = index - 1;
    if (i >= identities.length) {
      return (video: null, mic: false, hand: false, avatar: null);
    }
    final id = identities[i];
    return (
      video: remoteVideoTracks[id],
      mic: remoteMicActive(id),
      hand: remoteHandRaised(id),
      avatar: remoteAvatarUrl(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allNames = [localName, ...remoteNames];
    final count = allNames.length;

    if (count == 1) {
      final info = _trackInfoFor(0);
      final id = localIdentity ?? '';
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _ParticipantTile(
          name: allNames[0],
          isLocal: true,
          micEnabled: info.mic,
          world: world,
          accent: accent,
          isSolo: true,
          videoTrack: info.video,
          handRaised: info.hand,
          avatarUrl: info.avatar,
          isActiveSpeaker: id.isNotEmpty && activeSpeakers.contains(id),
          quality: id.isEmpty
              ? LiveKitParticipantQuality.unknown
              : qualityFor(id),
        ),
      );
    }

    final crossCount = count <= 2 ? 2 : (count <= 4 ? 2 : 3);
    // Identity-Lookup für Quality + Active-Speaker-Check
    final identitiesSorted = remoteVideoTracks.keys.toList();
    final tiles = List.generate(count, (i) {
      final isLocal = i == 0;
      final info = _trackInfoFor(i);
      final id = isLocal
          ? (localIdentity ?? '')
          : (i - 1 < identitiesSorted.length ? identitiesSorted[i - 1] : '');
      final name = allNames[i];
      // 🔦 B11: Long-Press nur für Remote-Teilnehmer (lokaler pinnt sich nicht selbst)
      final spotlight = (!isLocal && id.isNotEmpty && onSpotlight != null)
          ? () => _showSpotlightSheet(context, name, id, accent, onSpotlight!)
          : null;
      return _ParticipantTile(
        name: name,
        isLocal: isLocal,
        micEnabled: info.mic,
        world: world,
        accent: accent,
        isSolo: false,
        videoTrack: info.video,
        handRaised: info.hand,
        avatarUrl: info.avatar,
        isActiveSpeaker: id.isNotEmpty && activeSpeakers.contains(id),
        quality: id.isEmpty
            ? LiveKitParticipantQuality.unknown
            : qualityFor(id),
        onLongPress: spotlight,
      );
    });

    // Bundle 5.3: childAspectRatio explizit + scrollbar wenn mehr als
    // crossCount × 3 Tiles. Vorher: NeverScrollable + shrinkWrap → bei
    // ≥6 Teilnehmern Overflow-Stripes, kein Scroll.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: GridView.count(
        crossAxisCount: crossCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85, // ~140px hoch bei ~165px Breite
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        children: tiles,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICIPANT TILE
// ═══════════════════════════════════════════════════════════════════════════

class _ParticipantTile extends StatefulWidget {
  final String name;
  final bool isLocal;
  final bool micEnabled;
  final String world;
  final Color accent;
  final bool isSolo;
  final lk.VideoTrack? videoTrack;
  final bool handRaised;
  final String? avatarUrl;
  // 📶 B2: Verbindungs-Qualität (für farbigen Punkt oben rechts)
  final LiveKitParticipantQuality quality;
  // 🌌 B3: aktiver Sprecher → animierte Aura um's Tile
  final bool isActiveSpeaker;
  // 🔦 B11: Long-Press → Spotlight-Aktion
  final VoidCallback? onLongPress;

  const _ParticipantTile({
    required this.name,
    required this.isLocal,
    required this.micEnabled,
    required this.world,
    required this.accent,
    required this.isSolo,
    this.videoTrack,
    this.handRaised = false,
    this.avatarUrl,
    this.quality = LiveKitParticipantQuality.unknown,
    this.isActiveSpeaker = false,
    this.onLongPress,
  });

  @override
  State<_ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<_ParticipantTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.micEnabled || widget.isActiveSpeaker) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ParticipantTile old) {
    super.didUpdateWidget(old);
    // 🌌 Bundle 3: Animation läuft wenn micEnabled ODER isActiveSpeaker
    // (Aura-Glow nutzt _pulseAnim auch).
    final shouldAnimate = widget.micEnabled || widget.isActiveSpeaker;
    if (shouldAnimate && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!shouldAnimate && _pulseCtrl.isAnimating) {
      // Bundle 5.9: animateTo(0) macht 1-Frame-Animation, flackert bei
      // schnellem Mic-Toggle. Sofort auf 0 setzen via .value.
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(widget.name);
    final avatarSize = widget.isSolo ? 110.0 : 64.0;
    final fontSize = widget.isSolo ? 40.0 : 24.0;
    final isMaterie = widget.world == 'materie';
    final hasVideo = widget.videoTrack != null;

    final tileBody = _buildTileBody(context, initials, avatarSize, fontSize, isMaterie, hasVideo);

    // 📶 B2: Quality-Punkt overlay oben rechts auf das Tile
    final tileWithQuality = Stack(
      children: [
        tileBody,
        if (widget.quality != LiveKitParticipantQuality.unknown)
          Positioned(
            top: 8,
            right: 8,
            child: _QualityDot(quality: widget.quality),
          ),
      ],
    );

    // 🌌 B3: Aktive-Sprecher-Aura — pulsierender Welt-farbiger Ring
    // umschließt das Tile wenn die Person grade redet.
    Widget result;
    if (!widget.isActiveSpeaker) {
      result = tileWithQuality;
    } else {
      result = AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) {
          final t = _pulseAnim.value; // 0.95..1.05
          final c1 = isMaterie
              ? const Color(0xFFE53935) // materie rot
              : const Color(0xFF7C4DFF); // energie lila
          final c2 = isMaterie
              ? const Color(0xFF2979FF) // materie blau
              : const Color(0xFF00E5FF); // energie cyan
          final auraColor = Color.lerp(c1, c2, t) ?? widget.accent;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WbDesign.radiusCard + 4),
              boxShadow: [
                BoxShadow(
                  color: auraColor.withValues(alpha: 0.55),
                  blurRadius: 16 + (t * 8),
                  spreadRadius: 2 + (t * 2),
                ),
                BoxShadow(
                  color: auraColor.withValues(alpha: 0.18),
                  blurRadius: 32 + (t * 16),
                  spreadRadius: 6 + (t * 4),
                ),
              ],
            ),
            child: tileWithQuality,
          );
        },
      );
    }

    // 🔦 B11: Long-Press wrappen wenn Callback vorhanden
    if (widget.onLongPress != null) {
      return GestureDetector(onLongPress: widget.onLongPress, child: result);
    }
    return result;
  }

  Widget _buildTileBody(BuildContext context, String initials, double avatarSize,
      double fontSize, bool isMaterie, bool hasVideo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WbDesign.surface(widget.world).withValues(alpha: 0.78),
            WbDesign.surface(widget.world).withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(WbDesign.radiusCard),
        border: Border.all(
          color: widget.micEnabled
              ? widget.accent.withValues(alpha: 0.40)
              : WbDesign.borderSubtle,
          width: widget.micEnabled ? 1.5 : 1,
        ),
        boxShadow: widget.micEnabled
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.10),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: hasVideo
          ? _buildVideoView()
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar mit Sprech-Glow — welt-spezifisch
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: widget.micEnabled ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Welt-spezifischer Glow-Ring (Hexagon für Materie, mehrlagiger Halo für Energie)
                if (widget.micEnabled)
                  isMaterie
                      ? CustomPaint(
                          size: Size(avatarSize + 24, avatarSize + 24),
                          painter: _MaterieAvatarGlow(widget.accent),
                        )
                      : SizedBox(
                          width: avatarSize + 28,
                          height: avatarSize + 28,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Doppelter Halo für Energie-Aura-Effekt
                              Container(
                                width: avatarSize + 24,
                                height: avatarSize + 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accent
                                          .withValues(alpha: 0.45),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: avatarSize + 12,
                                height: avatarSize + 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.accent
                                          .withValues(alpha: 0.30),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                // Avatar — Profilbild bevorzugt, Initialen als Fallback
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: WbDesign.hero(widget.world),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (widget.avatarUrl != null &&
                          widget.avatarUrl!.isNotEmpty)
                      ? Image.network(
                          widget.avatarUrl!,
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
                // Hand-Raised-Badge oben rechts
                if (widget.handRaised)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB300),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FFB300),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('✋', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              () {
                final n = widget.name.trim();
                if (widget.isLocal) {
                  return n.isEmpty ? 'Du' : '$n (Du)';
                }
                return n.isEmpty ? 'Mitglied' : n;
              }(),
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.isSolo ? 16 : 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          // Mic-Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.micEnabled
                  ? widget.accent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(WbDesign.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                  size: 11,
                  color: widget.micEnabled
                      ? widget.accent
                      : WbDesign.textTertiary,
                ),
                const SizedBox(width: 3),
                Text(
                  widget.micEnabled ? 'Mikrofon an' : 'Stummgeschaltet',
                  style: TextStyle(
                    color: widget.micEnabled
                        ? widget.accent
                        : WbDesign.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Video-View Layout — Vollformat-Video mit Name + Mic-Status overlay.
  Widget _buildVideoView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WbDesign.radiusCard),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video-Renderer
          lk.VideoTrackRenderer(
            widget.videoTrack!,
            fit: lk.VideoViewFit.cover,
          ),
          // Bottom overlay: Name + Mic-Status
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    size: 14,
                    color: widget.micEnabled
                        ? widget.accent
                        : Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      () {
                        final n = widget.name.trim();
                        if (widget.isLocal) {
                          return n.isEmpty ? 'Du' : '$n (Du)';
                        }
                        return n.isEmpty ? 'Mitglied' : n;
                      }(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTROL BAR
// ═══════════════════════════════════════════════════════════════════════════

class _ControlBar extends StatelessWidget {
  final String world;
  final LiveKitCallService service;
  final VoidCallback onCoWatch;
  final VoidCallback onToggleChat;
  final bool chatVisible;
  final VoidCallback onLeave;

  const _ControlBar({
    required this.world,
    required this.service,
    required this.onCoWatch,
    required this.onToggleChat,
    required this.chatVisible,
    required this.onLeave,
  });

  /// Öffnet das "Mehr Aktionen"-Sheet mit sekundären Call-Funktionen.
  void _showMoreActions(BuildContext context) {
    final accent = WbDesign.accent(world);
    final isConnected = service.isConnected;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: WbDesign.surface(world).withValues(alpha: 0.96),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                        color: accent.withValues(alpha: 0.30), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WbDesign.textTertiary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: WbDesign.hero(world),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.more_horiz_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Weitere Aktionen',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chat
                    ValueListenableBuilder<int>(
                      valueListenable: InCallChatService.instance.unreadNotifier,
                      builder: (_, unread, __) => _MoreActionTile(
                        icon: chatVisible
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        title: 'Chat',
                        subtitle: chatVisible
                            ? 'Chat schließen'
                            : (unread > 0
                                ? '$unread neue Nachricht${unread == 1 ? '' : 'en'}'
                                : 'Nachrichten im Anruf schreiben'),
                        active: chatVisible,
                        accent: accent,
                        badgeCount: (!chatVisible && unread > 0) ? unread : 0,
                        enabled: isConnected,
                        onTap: () {
                          Navigator.pop(ctx);
                          onToggleChat();
                        },
                      ),
                    ),
                    // Reaktion senden
                    _MoreActionTile(
                      icon: Icons.emoji_emotions_outlined,
                      title: 'Reaktion',
                      subtitle: 'Emoji-Reaktion an alle senden',
                      active: false,
                      accent: accent,
                      enabled: isConnected,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showReactionsPicker(context, world, service);
                      },
                    ),
                    // Hand heben
                    _MoreActionTile(
                      icon: service.handRaised
                          ? Icons.front_hand_rounded
                          : Icons.front_hand_outlined,
                      title: service.handRaised ? 'Hand senken' : 'Hand heben',
                      subtitle: service.handRaised
                          ? 'Meldung zurückziehen'
                          : 'Allen zeigen dass du etwas sagen möchtest',
                      active: service.handRaised,
                      accent: const Color(0xFFFFB300),
                      enabled: isConnected,
                      onTap: () {
                        Navigator.pop(ctx);
                        service.toggleHandRaised();
                      },
                    ),
                    // Bildschirm teilen
                    _MoreActionTile(
                      icon: service.screenShareEnabled
                          ? Icons.stop_screen_share_rounded
                          : Icons.present_to_all_rounded,
                      title: service.screenShareEnabled
                          ? 'Teilen stoppen'
                          : 'Bildschirm teilen',
                      subtitle: service.screenShareEnabled
                          ? 'Bildschirmübertragung beenden'
                          : 'Deinen Bildschirm für alle sichtbar machen',
                      active: service.screenShareEnabled,
                      accent: accent,
                      enabled: isConnected,
                      onTap: () {
                        Navigator.pop(ctx);
                        service.toggleScreenShare();
                      },
                    ),
                    // Kamera drehen (nur wenn Kamera an)
                    if (service.cameraEnabled)
                      _MoreActionTile(
                        icon: Icons.cameraswitch_rounded,
                        title: 'Kamera drehen',
                        subtitle: 'Zwischen Vorder- und Rückkamera wechseln',
                        active: false,
                        accent: accent,
                        enabled: isConnected,
                        onTap: () {
                          Navigator.pop(ctx);
                          service.switchCamera();
                        },
                      ),
                    // Co-Watch
                    _MoreActionTile(
                      icon: Icons.tv_rounded,
                      title: 'Co-Watch',
                      subtitle: CoWatchService.instance.active
                          ? 'YouTube-Video läuft — Tippen zum Verwalten'
                          : 'YouTube-Video gemeinsam anschauen',
                      active: CoWatchService.instance.active,
                      accent: accent,
                      enabled: isConnected,
                      onTap: () {
                        Navigator.pop(ctx);
                        onCoWatch();
                      },
                    ),
                    SizedBox(
                        height: MediaQuery.of(ctx).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = service.isConnected;
    final accent = WbDesign.accent(world);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: WbDesign.surfaceAlt(world).withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.15), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Mikrofon (Tap = Toggle, Long-Press = PTT) ──
                  _CtrlBtn(
                    icon: service.micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: service.pttActive
                        ? 'Sprechtaste'
                        : (service.micEnabled ? 'Mikrofon' : 'Stumm'),
                    active: service.micEnabled || service.pttActive,
                    activeColor: service.pttActive
                        ? const Color(0xFF00E676)
                        : accent,
                    enabled: isConnected,
                    onTap: () => service.toggleMicrophone(),
                    onLongPressStart: () => service.pttPress(),
                    onLongPressEnd: () => service.pttRelease(),
                  ),
                  // ── Kamera ──
                  _CtrlBtn(
                    icon: service.cameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: service.cameraEnabled ? 'Kamera' : 'Kamera aus',
                    active: service.cameraEnabled,
                    activeColor: accent,
                    enabled: isConnected,
                    onTap: () => service.toggleCamera(),
                  ),
                  // ── Mehr (sekundäre Aktionen) ──
                  Builder(
                    builder: (ctx) {
                      final hasUnread = InCallChatService
                              .instance.unreadNotifier.value >
                          0;
                      final hasActive = chatVisible ||
                          service.handRaised ||
                          service.screenShareEnabled ||
                          CoWatchService.instance.active;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _CtrlBtn(
                            icon: Icons.more_horiz_rounded,
                            label: 'Mehr',
                            active: hasActive,
                            activeColor: accent,
                            enabled: true,
                            onTap: () => _showMoreActions(ctx),
                          ),
                          if (hasUnread && !chatVisible)
                            Positioned(
                              top: 0,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF1744),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  // ── Auflegen (immer sichtbar, prominent) ──
                  _CtrlBtn(
                    icon: Icons.call_end_rounded,
                    label: 'Auflegen',
                    active: false,
                    enabled: true,
                    isDanger: true,
                    isLarge: true,
                    onTap: onLeave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Zeile im "Mehr Aktionen"-Sheet.
class _MoreActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final Color accent;
  final bool enabled;
  final int badgeCount;
  final VoidCallback onTap;

  const _MoreActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.accent,
    required this.enabled,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: active
                        ? accent.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? accent.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: !enabled
                        ? Colors.white.withValues(alpha: 0.25)
                        : (active ? accent : Colors.white),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: !enabled
                          ? WbDesign.textDisabled
                          : (active ? accent : Colors.white),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: !enabled
                          ? WbDesign.textDisabled
                          : WbDesign.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              )
            else if (!enabled)
              Icon(Icons.lock_outline_rounded,
                  color: WbDesign.textDisabled, size: 16),
          ],
        ),
      ),
    );
  }
}

/// 💖 Bundle 4: Reactions-Picker als Bottom-Sheet — pro Welt eigener
/// Emoji-Set (Energie eher esoterisch, Materie eher kraftvoll).
void _showReactionsPicker(BuildContext context, String world,
    LiveKitCallService service) {
  final emojis = world == 'energie' ? kEnergieReactions : kMaterieReactions;
  final accent = WbDesign.accent(world);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: WbDesign.surface(world).withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.3), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag-Handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: WbDesign.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Reaktion senden',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final e in emojis)
                    _ReactionEmojiBtn(
                      emoji: e,
                      accent: accent,
                      onTap: () {
                        service.sendReaction(e);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReactionEmojiBtn extends StatelessWidget {
  final String emoji;
  final Color accent;
  final VoidCallback onTap;
  const _ReactionEmojiBtn({
    required this.emoji,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final bool enabled;
  final bool isDanger;
  /// Wenn true → größeres Auflegen-Format (64×64 px, größeres Icon).
  final bool isLarge;
  final VoidCallback? onTap;
  // 🎙️ B12: Push-to-Talk Long-Press
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    this.activeColor,
    this.isDanger = false,
    this.isLarge = false,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    final double btnSize = isLarge ? 64 : 54;
    final double iconSize = isLarge ? 26 : 22;

    final Color bg = isDanger
        ? const Color(0xFFFF1744)
        : (active && activeColor != null
            ? activeColor!.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08));
    final Color iconColor = !enabled
        ? Colors.white.withValues(alpha: 0.25)
        : isDanger
            ? Colors.white
            : (active && activeColor != null ? activeColor! : Colors.white);
    final Color labelColor = !enabled
        ? WbDesign.textDisabled
        : (active && activeColor != null
            ? activeColor!
            : WbDesign.textTertiary);

    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        onLongPressStart: (enabled && onLongPressStart != null)
            ? (_) => onLongPressStart!()
            : null,
        onLongPressEnd: (enabled && onLongPressEnd != null)
            ? (_) => onLongPressEnd!()
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: btnSize,
              height: btnSize,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isDanger
                    ? null
                    : Border.all(
                        color: active && activeColor != null
                            ? activeColor!.withValues(alpha: 0.40)
                            : WbDesign.borderMedium,
                        width: 1.5,
                      ),
                boxShadow: isDanger
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withValues(alpha: 0.50),
                          blurRadius: isLarge ? 24 : 16,
                          spreadRadius: isLarge ? 4 : 2,
                        ),
                      ]
                    : (active && activeColor != null
                        ? [
                            BoxShadow(
                              color: activeColor!.withValues(alpha: 0.25),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null),
              ),
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isDanger
                    ? const Color(0xFFFF6B6B)
                    : labelColor,
                fontSize: 9.5,
                fontWeight: (active || isDanger)
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS VIEW (Connecting / Error / Disconnected)
// ═══════════════════════════════════════════════════════════════════════════

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool showSpinner;
  final bool showRetry;
  final VoidCallback? onRetry;

  const _StatusView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.showSpinner = false,
    this.showRetry = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon-Kreis
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: accent, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WbDesign.textTertiary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Erneut versuchen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WbDesign.radiusMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PULSING DOT
// ═══════════════════════════════════════════════════════════════════════════

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool pulse;

  const _PulsingDot({required this.color, required this.pulse});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    if (widget.pulse) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) _ctrl.repeat();
    if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Container(
                width: 16 * (0.5 + _anim.value),
                height: 16 * (0.5 + _anim.value),
                decoration: BoxDecoration(
                  color:
                      widget.color.withValues(alpha: 0.35 * (1 - _anim.value)),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MATERIE AVATAR GLOW — Hexagon-Outline mit Glow
// ═══════════════════════════════════════════════════════════════════════════

class _MaterieAvatarGlow extends CustomPainter {
  final Color accent;

  _MaterieAvatarGlow(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Hexagon-Pfad
    final path = Path();
    for (int i = 0; i < 6; i++) {
      // -π/2 damit ein Eck oben ist
      final angle = -math.pi / 2 + math.pi / 3 * i;
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    // Outer Glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = accent.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Crisp Outline
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.85);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MaterieAvatarGlow old) =>
      old.accent != accent;
}

/// 📶 Bundle 2: kleiner farbiger Punkt am Tile (oben rechts) der die
/// Verbindungs-Qualität des Teilnehmers anzeigt — wie bei Discord.
class _QualityDot extends StatelessWidget {
  final LiveKitParticipantQuality quality;
  const _QualityDot({required this.quality});

  Color get _color {
    switch (quality) {
      case LiveKitParticipantQuality.excellent:
        return const Color(0xFF4CAF50); // grün
      case LiveKitParticipantQuality.good:
        return const Color(0xFF8BC34A); // hellgrün
      case LiveKitParticipantQuality.poor:
        return const Color(0xFFFF9800); // orange
      case LiveKitParticipantQuality.lost:
        return const Color(0xFFFF1744); // rot
      case LiveKitParticipantQuality.unknown:
        return Colors.grey;
    }
  }

  String get _tooltip {
    switch (quality) {
      case LiveKitParticipantQuality.excellent:
        return 'Verbindung: ausgezeichnet';
      case LiveKitParticipantQuality.good:
        return 'Verbindung: gut';
      case LiveKitParticipantQuality.poor:
        return 'Verbindung: schlecht';
      case LiveKitParticipantQuality.lost:
        return 'Verbindung verloren';
      case LiveKitParticipantQuality.unknown:
        return 'Verbindung: unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: _color.withValues(alpha: 0.6),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔁 BUNDLE 6: SPEAKER VIEW LAYOUT
// Aktiver/gepinnter Sprecher GROSS oben, andere als kleiner Strip unten.
// ═══════════════════════════════════════════════════════════════════════════

// 🔦 B11: Spotlight-Bottom-Sheet — zeigt "Für alle pinnen" Option
void _showSpotlightSheet(
  BuildContext context,
  String name,
  String identity,
  Color accent,
  void Function(String) onSpotlight,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0D0D1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Icon(Icons.push_pin_rounded, color: accent),
            ),
            title: Text(
              'Für alle pinnen',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$name wird für alle Teilnehmer hervorgehoben',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
            onTap: () {
              Navigator.pop(context);
              onSpotlight(identity);
            },
          ),
        ],
      ),
    ),
  );
}

class _SpeakerView extends StatelessWidget {
  final String world;
  final String localName;
  final String? localAvatarUrl;
  final String? localIdentity;
  final List<String> remoteNames;
  final bool micEnabled;
  final Color accent;
  final lk.VideoTrack? localVideoTrack;
  final Map<String, lk.VideoTrack?> remoteVideoTracks;
  final bool Function(String) remoteMicActive;
  final bool localHandRaised;
  final bool Function(String) remoteHandRaised;
  final String? Function(String) remoteAvatarUrl;
  final Set<String> activeSpeakers;
  final LiveKitParticipantQuality Function(String) qualityFor;
  final String? pinnedIdentity;
  // 🔦 B11: Spotlight-Callback
  final void Function(String identity)? onSpotlight;

  const _SpeakerView({
    required this.world,
    required this.localName,
    required this.localAvatarUrl,
    required this.localIdentity,
    required this.remoteNames,
    required this.micEnabled,
    required this.accent,
    required this.localVideoTrack,
    required this.remoteVideoTracks,
    required this.remoteMicActive,
    required this.localHandRaised,
    required this.remoteHandRaised,
    required this.remoteAvatarUrl,
    required this.activeSpeakers,
    required this.qualityFor,
    required this.pinnedIdentity,
    this.onSpotlight,
  });

  @override
  Widget build(BuildContext context) {
    final remoteIds = remoteVideoTracks.keys.toList();
    String mainId = pinnedIdentity ?? '';
    bool mainIsLocal = mainId == (localIdentity ?? '');
    if (mainId.isEmpty || (!mainIsLocal && !remoteIds.contains(mainId))) {
      if (remoteIds.isNotEmpty) {
        mainId = remoteIds.first;
        mainIsLocal = false;
      } else {
        mainId = localIdentity ?? '';
        mainIsLocal = true;
      }
    }

    final stripIds = <({String id, bool local})>[];
    if (!mainIsLocal && (localIdentity?.isNotEmpty ?? false)) {
      stripIds.add((id: localIdentity!, local: true));
    }
    for (final id in remoteIds) {
      if (id != mainId) stripIds.add((id: id, local: false));
    }

    String mainName;
    bool mainMic;
    bool mainHand;
    String? mainAvatar;
    lk.VideoTrack? mainVideo;
    if (mainIsLocal) {
      mainName = localName;
      mainMic = micEnabled;
      mainHand = localHandRaised;
      mainAvatar = localAvatarUrl;
      mainVideo = localVideoTrack;
    } else {
      final idx = remoteIds.indexOf(mainId);
      mainName = (idx >= 0 && idx < remoteNames.length) ? remoteNames[idx] : mainId;
      mainMic = remoteMicActive(mainId);
      mainHand = remoteHandRaised(mainId);
      mainAvatar = remoteAvatarUrl(mainId);
      mainVideo = remoteVideoTracks[mainId];
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: _ParticipantTile(
              name: mainName,
              isLocal: mainIsLocal,
              micEnabled: mainMic,
              world: world,
              accent: accent,
              isSolo: true,
              videoTrack: mainVideo,
              handRaised: mainHand,
              avatarUrl: mainAvatar,
              isActiveSpeaker:
                  mainId.isNotEmpty && activeSpeakers.contains(mainId),
              quality: mainId.isEmpty
                  ? LiveKitParticipantQuality.unknown
                  : qualityFor(mainId),
            ),
          ),
          if (stripIds.isNotEmpty) const SizedBox(height: 10),
          if (stripIds.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stripIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final entry = stripIds[i];
                  final id = entry.id;
                  final isLocal = entry.local;
                  String name;
                  bool mic;
                  bool hand;
                  String? avatar;
                  lk.VideoTrack? video;
                  if (isLocal) {
                    name = localName;
                    mic = micEnabled;
                    hand = localHandRaised;
                    avatar = localAvatarUrl;
                    video = localVideoTrack;
                  } else {
                    final idx = remoteIds.indexOf(id);
                    name = (idx >= 0 && idx < remoteNames.length)
                        ? remoteNames[idx]
                        : id;
                    mic = remoteMicActive(id);
                    hand = remoteHandRaised(id);
                    avatar = remoteAvatarUrl(id);
                    video = remoteVideoTracks[id];
                  }
                  final spotlight = (!isLocal && id.isNotEmpty && onSpotlight != null)
                      ? () => _showSpotlightSheet(context, name, id, accent, onSpotlight!)
                      : null;
                  return SizedBox(
                    width: 95,
                    child: _ParticipantTile(
                      name: name,
                      isLocal: isLocal,
                      micEnabled: mic,
                      world: world,
                      accent: accent,
                      isSolo: false,
                      videoTrack: video,
                      handRaised: hand,
                      avatarUrl: avatar,
                      isActiveSpeaker:
                          id.isNotEmpty && activeSpeakers.contains(id),
                      quality: id.isEmpty
                          ? LiveKitParticipantQuality.unknown
                          : qualityFor(id),
                      onLongPress: spotlight,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
