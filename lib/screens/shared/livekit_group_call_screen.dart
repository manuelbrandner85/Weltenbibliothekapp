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

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/wb_design.dart';
import '../../providers/livekit_call_provider.dart';
import '../../services/livekit_call_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PUBLIC SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class LiveKitGroupCallScreen extends ConsumerStatefulWidget {
  final String roomName;
  final String world;
  final String displayName;
  final String? avatarUrl;

  const LiveKitGroupCallScreen({
    super.key,
    required this.roomName,
    required this.world,
    required this.displayName,
    this.avatarUrl,
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

    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  @override
  void dispose() {
    _bgController.dispose();
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
        body: AnimatedBuilder(
          animation: _bgAnimation,
          builder: (_, child) => Stack(
            fit: StackFit.expand,
            children: [
              // Animierter Hintergrund-Glow
              _AnimatedBackground(
                world: widget.world,
                animation: _bgAnimation,
                accent: accent,
              ),
              child!,
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  roomName: widget.roomName,
                  world: widget.world,
                  state: state,
                  callDurationSeconds: svc.callDurationSeconds,
                  participantCount: svc.totalParticipantCount,
                  onClose: () async {
                    if (await _confirmLeave()) await _leaveAndPop();
                  },
                ),
                Expanded(child: _buildBody(state, svc, accent)),
                _ControlBar(
                  world: widget.world,
                  service: svc,
                  onLeave: () async {
                    if (await _confirmLeave()) await _leaveAndPop();
                  },
                ),
              ],
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
          onRetry: () {
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
          onRetry: () {
            setState(() => _hasJoined = false);
            _join();
          },
        );
      case LiveKitConnectionState.connected:
        return _ParticipantGrid(
          world: widget.world,
          localName: widget.displayName,
          localAvatarUrl: widget.avatarUrl,
          remoteNames: svc.remoteParticipantNames,
          micEnabled: svc.micEnabled,
          cameraEnabled: svc.cameraEnabled,
          accent: accent,
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
// ANIMATED BACKGROUND
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedBackground extends StatelessWidget {
  final String world;
  final Animation<double> animation;
  final Color accent;

  const _AnimatedBackground({
    required this.world,
    required this.animation,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BgPainter(animation.value, accent),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  final Color accent;

  _BgPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // Subtile Glow-Orbe
    for (var i = 0; i < 3; i++) {
      final angle = (i * math.pi * 2 / 3) + t * math.pi * 0.5;
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.3;
      final y = size.height * 0.4 + math.sin(angle) * size.height * 0.2;
      final radius = size.width * (0.25 + t * 0.05);
      paint.shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.06 + t * 0.02),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String roomName;
  final String world;
  final LiveKitConnectionState state;
  final int callDurationSeconds;
  final int participantCount;
  final VoidCallback onClose;

  const _TopBar({
    required this.roomName,
    required this.world,
    required this.state,
    required this.callDurationSeconds,
    required this.participantCount,
    required this.onClose,
  });

  String _formatDuration(int s) {
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

  String _stateLabel() {
    switch (state) {
      case LiveKitConnectionState.connected:
        return _formatDuration(callDurationSeconds);
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

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(world);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: BoxDecoration(
            color: WbDesign.surface(world).withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: accent.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              // Status-Dot
              _PulsingDot(
                color: _dotColor(),
                pulse: state == LiveKitConnectionState.connecting ||
                    state == LiveKitConnectionState.reconnecting,
              ),
              const SizedBox(width: 10),
              // Raum-Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 2),
                    Text(
                      _stateLabel(),
                      style: TextStyle(
                        color: state == LiveKitConnectionState.connected
                            ? const Color(0xFF4CAF50)
                            : WbDesign.textTertiary,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w500,
                      ),
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
              // Schließen
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: 'Schließen',
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

// ═══════════════════════════════════════════════════════════════════════════
// PARTICIPANT GRID
// ═══════════════════════════════════════════════════════════════════════════

class _ParticipantGrid extends StatelessWidget {
  final String world;
  final String localName;
  final String? localAvatarUrl;
  final List<String> remoteNames;
  final bool micEnabled;
  final bool cameraEnabled;
  final Color accent;

  const _ParticipantGrid({
    required this.world,
    required this.localName,
    required this.localAvatarUrl,
    required this.remoteNames,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final allNames = [localName, ...remoteNames];
    final count = allNames.length;

    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _ParticipantTile(
          name: allNames[0],
          isLocal: true,
          micEnabled: micEnabled,
          world: world,
          accent: accent,
          isSolo: true,
        ),
      );
    }

    final crossCount = count <= 2 ? 2 : (count <= 4 ? 2 : 3);
    final tiles = List.generate(count, (i) {
      final isLocal = i == 0;
      return _ParticipantTile(
        name: allNames[i],
        isLocal: isLocal,
        micEnabled: isLocal ? micEnabled : true,
        world: world,
        accent: accent,
        isSolo: false,
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: GridView.count(
        crossAxisCount: crossCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
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

  const _ParticipantTile({
    required this.name,
    required this.isLocal,
    required this.micEnabled,
    required this.world,
    required this.accent,
    required this.isSolo,
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
    if (widget.micEnabled) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ParticipantTile old) {
    super.didUpdateWidget(old);
    if (widget.micEnabled && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.micEnabled && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.animateTo(0);
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

    return Container(
      decoration: BoxDecoration(
        color: WbDesign.surface(widget.world).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(WbDesign.radiusCard),
        border: Border.all(
          color: widget.micEnabled
              ? widget.accent.withValues(alpha: 0.35)
              : WbDesign.borderSubtle,
          width: widget.micEnabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar mit Sprech-Glow
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: widget.micEnabled ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow Ring
                if (widget.micEnabled)
                  Container(
                    width: avatarSize + 16,
                    height: avatarSize + 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                // Avatar
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: WbDesign.hero(widget.world),
                  ),
                  child: Center(
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.isLocal ? '${widget.name} (Du)' : widget.name,
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
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTROL BAR
// ═══════════════════════════════════════════════════════════════════════════

class _ControlBar extends StatelessWidget {
  final String world;
  final LiveKitCallService service;
  final VoidCallback onLeave;

  const _ControlBar({
    required this.world,
    required this.service,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = service.isConnected;
    final accent = WbDesign.accent(world);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: WbDesign.surfaceAlt(world).withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(color: WbDesign.borderMedium),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Mikrofon
                  _CtrlBtn(
                    icon: service.micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: service.micEnabled ? 'Mikrofon' : 'Stumm',
                    active: service.micEnabled,
                    activeColor: accent,
                    enabled: isConnected,
                    onTap: () => service.toggleMicrophone(),
                  ),
                  // Kamera
                  _CtrlBtn(
                    icon: service.cameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: service.cameraEnabled ? 'Kamera an' : 'Kamera aus',
                    active: service.cameraEnabled,
                    activeColor: accent,
                    enabled: isConnected,
                    onTap: () => service.toggleCamera(),
                  ),
                  // Bildschirm teilen
                  _CtrlBtn(
                    icon: service.screenShareEnabled
                        ? Icons.stop_screen_share_rounded
                        : Icons.present_to_all_rounded,
                    label: service.screenShareEnabled ? 'Stop' : 'Teilen',
                    active: service.screenShareEnabled,
                    activeColor: accent,
                    enabled: isConnected,
                    onTap: () => service.toggleScreenShare(),
                  ),
                  // Hand heben
                  _CtrlBtn(
                    icon: service.handRaised
                        ? Icons.front_hand_rounded
                        : Icons.front_hand_outlined,
                    label: service.handRaised ? 'Hand gesenkt' : 'Hand heben',
                    active: service.handRaised,
                    activeColor: const Color(0xFFFFB300),
                    enabled: isConnected,
                    onTap: () => service.toggleHandRaised(),
                  ),
                  // Auflegen
                  _CtrlBtn(
                    icon: Icons.call_end_rounded,
                    label: 'Auflegen',
                    active: false,
                    enabled: true,
                    isDanger: true,
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

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color? activeColor;
  final bool enabled;
  final bool isDanger;
  final VoidCallback? onTap;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    this.activeColor,
    this.isDanger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDanger
                      ? Colors.transparent
                      : (active && activeColor != null
                          ? activeColor!.withValues(alpha: 0.40)
                          : WbDesign.borderMedium),
                  width: 1.5,
                ),
                boxShadow: isDanger
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFFF1744).withValues(alpha: 0.40),
                          blurRadius: 16,
                          spreadRadius: 2,
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
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 9.5,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w400,
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
