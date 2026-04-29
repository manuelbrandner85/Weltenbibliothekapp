/// 🎥 LIVEKIT GROUP CALL SCREEN
///
/// Vollbild-Screen für LiveKit-Video-Gruppencalls — angelehnt an die
/// Mensaena LiveRoomModal UI, aber im Weltenbibliothek-Home-Stil mit
/// welt-spezifischen Akzenten (Energie = Lila, Materie = Blau).
///
/// **Aktueller Funktionsumfang (Phase 4 von 2 Live-Phasen):**
///   - Vollbild-Layout mit Top-Bar, Participant-Grid, Control-Bar
///   - Welt-aware Farben/Gradients (WbDesign-Tokens)
///   - Connection-State-Indicator (animiert pulsierend bei reconnecting)
///   - Call-Timer (live aus Service)
///   - Verlassen-Button mit Bestätigung
///   - Platzhalter für Mic/Cam/Screen/Hand/Reactions/Chat
///     (wird in Phase 5 mit echten LiveKit-Calls verdrahtet)
///
/// Das Screen ist bewusst defensiv — wenn LiveKit nicht konfiguriert ist
/// oder Verbindung scheitert, kommt der User mit klarer deutscher
/// Fehlermeldung zurück statt in einem leeren Screen festzustecken.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/wb_design.dart';
import '../../providers/livekit_call_provider.dart';
import '../../services/livekit_call_service.dart';

class LiveKitGroupCallScreen extends ConsumerStatefulWidget {
  /// Eindeutige Raum-ID (Konvention: `wb-<world>-<slug>`).
  final String roomName;

  /// `'energie'` oder `'materie'` — bestimmt Farbschema.
  final String world;

  /// Anzeigename des lokalen Teilnehmers.
  final String displayName;

  /// Avatar-URL (optional — fällt sonst auf Initialen zurück).
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
    extends ConsumerState<LiveKitGroupCallScreen> {
  bool _hasJoined = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
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
    } catch (e) {
      // Service hat den Fehler bereits in state.errorMessage geschrieben.
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
      builder: (ctx) => AlertDialog(
        backgroundColor: WbDesign.surface(widget.world),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WbDesign.radiusCard),
        ),
        title: const Text(
          'Call verlassen?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Möchtest du den Anruf wirklich beenden?',
          style: TextStyle(color: WbDesign.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: WbDesign.textTertiary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF1744),
            ),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(livekitCallProvider);
    final state = svc.connectionState;
    final accent = WbDesign.accent(widget.world);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave()) await _leaveAndPop();
      },
      child: Scaffold(
        backgroundColor: WbDesign.background(widget.world),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                roomName: widget.roomName,
                world: widget.world,
                state: state,
                callDurationSeconds: svc.callDurationSeconds,
                onClose: () async {
                  if (await _confirmLeave()) await _leaveAndPop();
                },
              ),
              Expanded(
                child: _buildBody(state, svc, accent),
              ),
              _ControlBar(
                world: widget.world,
                onLeave: () async {
                  if (await _confirmLeave()) await _leaveAndPop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LiveKitConnectionState state, LiveKitCallService svc,
      Color accent) {
    switch (state) {
      case LiveKitConnectionState.connecting:
      case LiveKitConnectionState.reconnecting:
        return _StatusView(
          icon: Icons.cloud_sync_rounded,
          title: state == LiveKitConnectionState.reconnecting
              ? 'Verbindung wird wiederhergestellt …'
              : 'Verbinde mit dem Call …',
          subtitle: 'Raum: ${widget.roomName}',
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
        return _StatusView(
          icon: Icons.call_end_rounded,
          title: 'Nicht verbunden',
          subtitle: 'Tippe unten auf das Plus um beizutreten.',
          accent: WbDesign.textTertiary,
        );
      case LiveKitConnectionState.connected:
        return _ConnectedPlaceholder(
          world: widget.world,
          displayName: widget.displayName,
          avatarUrl: widget.avatarUrl,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String roomName;
  final String world;
  final LiveKitConnectionState state;
  final int callDurationSeconds;
  final VoidCallback onClose;

  const _TopBar({
    required this.roomName,
    required this.world,
    required this.state,
    required this.callDurationSeconds,
    required this.onClose,
  });

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Color _stateColor() {
    switch (state) {
      case LiveKitConnectionState.connected:
        return const Color(0xFF66BB6A);
      case LiveKitConnectionState.reconnecting:
      case LiveKitConnectionState.connecting:
        return const Color(0xFFFFB300);
      case LiveKitConnectionState.error:
        return const Color(0xFFFF1744);
      case LiveKitConnectionState.disconnected:
        return WbDesign.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        WbDesign.space12,
        WbDesign.space8,
        WbDesign.space12,
        WbDesign.space12,
      ),
      decoration: BoxDecoration(
        color: WbDesign.surface(world),
        border: Border(
          bottom: BorderSide(color: WbDesign.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          // Status-Punkt (pulsiert wenn reconnecting/connecting)
          _PulsingDot(color: _stateColor(), pulse: state != LiveKitConnectionState.connected),
          const SizedBox(width: WbDesign.space8),
          // Raum-Name + Timer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayRoom(roomName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  state == LiveKitConnectionState.connected
                      ? _formatDuration(callDurationSeconds)
                      : _stateLabel(state),
                  style: TextStyle(
                    color: WbDesign.textTertiary,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          // Schließen
          IconButton(
            tooltip: 'Schließen',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  String _displayRoom(String r) {
    // 'wb-energie-meditation' → 'Meditation'
    final parts = r.split('-');
    if (parts.length >= 3) {
      final last = parts.skip(2).join(' ');
      return last.isNotEmpty
          ? '${last[0].toUpperCase()}${last.substring(1)}'
          : r;
    }
    return r;
  }

  String _stateLabel(LiveKitConnectionState s) {
    switch (s) {
      case LiveKitConnectionState.connecting:
        return 'Verbinde …';
      case LiveKitConnectionState.reconnecting:
        return 'Wiederverbinde …';
      case LiveKitConnectionState.error:
        return 'Fehler';
      case LiveKitConnectionState.disconnected:
        return 'Nicht verbunden';
      case LiveKitConnectionState.connected:
        return 'Verbunden';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTROL BAR (Mic/Cam/Screen/Hand/React/Chat/Leave)
// ═══════════════════════════════════════════════════════════════════════════

class _ControlBar extends StatelessWidget {
  final String world;
  final VoidCallback onLeave;

  const _ControlBar({required this.world, required this.onLeave});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kommt im nächsten Update.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WbDesign.space12,
        vertical: WbDesign.space12,
      ),
      decoration: BoxDecoration(
        color: WbDesign.surfaceAlt(world),
        border: Border(
          top: BorderSide(color: WbDesign.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CtrlButton(
              icon: Icons.mic_off_rounded,
              label: 'Mikro',
              onTap: () => _comingSoon(context, 'Mikrofon-Toggle'),
            ),
            _CtrlButton(
              icon: Icons.videocam_off_rounded,
              label: 'Video',
              onTap: () => _comingSoon(context, 'Kamera-Toggle'),
            ),
            _CtrlButton(
              icon: Icons.screen_share_rounded,
              label: 'Teilen',
              onTap: () => _comingSoon(context, 'Bildschirm-Teilen'),
            ),
            _CtrlButton(
              icon: Icons.front_hand_rounded,
              label: 'Hand',
              onTap: () => _comingSoon(context, 'Hand-Heben'),
            ),
            _CtrlButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () => _comingSoon(context, 'In-Call-Chat'),
            ),
            _CtrlButton(
              icon: Icons.call_end_rounded,
              label: 'Beenden',
              danger: true,
              onTap: onLeave,
            ),
          ],
        ),
      ),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _CtrlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = danger ? const Color(0xFFFF1744) : Colors.white.withValues(alpha: 0.10);
    final fg = Colors.white;
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: WbDesign.borderSubtle),
              ),
              child: Icon(icon, color: fg, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: WbDesign.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONNECTED PLACEHOLDER (echter Grid kommt in Folge-PR)
// ═══════════════════════════════════════════════════════════════════════════

class _ConnectedPlaceholder extends StatelessWidget {
  final String world;
  final String displayName;
  final String? avatarUrl;

  const _ConnectedPlaceholder({
    required this.world,
    required this.displayName,
    this.avatarUrl,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(world);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WbDesign.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar-Kreis
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: WbDesign.hero(world),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.30),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials(displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: WbDesign.space20),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WbDesign.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: WbDesign.space12,
                vertical: WbDesign.space8,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(WbDesign.radiusPill),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Text(
                'Verbunden — du bist im Call',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: WbDesign.space32),
            Text(
              'Weitere Teilnehmer werden hier erscheinen.\n'
              'Mikro, Kamera und Bildschirm-Teilen kommen im nächsten Update.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WbDesign.textTertiary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS VIEW (Connecting/Error/Disconnected)
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
        padding: const EdgeInsets.all(WbDesign.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Icon(icon, color: accent, size: 38),
            ),
            const SizedBox(height: WbDesign.space20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: WbDesign.space8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: WbDesign.textTertiary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (showSpinner) ...[
              const SizedBox(height: WbDesign.space20),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: WbDesign.space20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Erneut versuchen'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WbDesign.radiusMedium),
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingDot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    if (!widget.pulse && _ctrl.isAnimating) _ctrl.stop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 1.0 + (_ctrl.value * 0.6);
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.pulse)
                Container(
                  width: 16 * scale,
                  height: 16 * scale,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.25 * (1 - _ctrl.value)),
                    shape: BoxShape.circle,
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
      },
    );
  }
}
