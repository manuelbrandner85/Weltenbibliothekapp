/// 📞 LIVEKIT FLOATING BUTTON — Draggable "Zurück zum Live-Call"-FAB
///
/// Ersetzt die bisherige Mini-Bar am unteren Rand als primären Weg zurück in
/// einen minimierten LiveKit-Call. Erscheint als runder, frei verschiebbarer
/// FAB sobald ein Call verbunden ist UND der Vollbild-Call-Screen NICHT
/// sichtbar ist.
///
/// Interaktionen:
///   - Tap        → öffnet wieder den LiveKitGroupCallScreen (rootNavigator).
///   - Drag       → FAB verschieben; nach Loslassen snappt er zur nächsten
///                  Bildschirmkante (links/rechts) mit Animation.
///   - Long-Press → Aktions-Sheet (Mikrofon stumm/an, Auflegen).
///
/// Wird in main.dart als `Positioned.fill(child: LiveKitFloatingButton())`
/// in einen Stack über allen Screens gemountet. Reagiert auf den globalen
/// [LiveKitScreenVisibility]-Marker (aus livekit_mini_bar.dart) damit es sich
/// versteckt während der Vollbild-Screen offen ist.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/wb_design.dart';
import '../core/app_navigator_key.dart';
import '../providers/livekit_call_provider.dart';
import '../screens/shared/livekit_group_call_screen.dart';
import '../services/livekit_call_service.dart';
import 'livekit_mini_bar.dart' show LiveKitScreenVisibility;

class LiveKitFloatingButton extends ConsumerStatefulWidget {
  const LiveKitFloatingButton({super.key});

  @override
  ConsumerState<LiveKitFloatingButton> createState() =>
      _LiveKitFloatingButtonState();
}

class _LiveKitFloatingButtonState extends ConsumerState<LiveKitFloatingButton>
    with SingleTickerProviderStateMixin {
  /// Diameter of the circular FAB in logical pixels.
  static const double _size = 64;

  /// Horizontal margin used when snapping to the nearest screen edge.
  static const double _edgeMargin = 12;

  /// Current top-left position of the FAB. `null` until the first layout —
  /// then a sensible default (right side, ~65% down) is applied.
  Offset? _pos;

  /// True while a drag is in progress — used to distinguish a real drag from
  /// a stray pan emitted on tap, and to disable the snap-animation mid-drag.
  bool _dragging = false;

  /// Accumulated finger travel during the current pan. If it stays below
  /// [_tapSlop] the gesture is treated as a tap (return to call) rather than a
  /// drag — the pan recognizer can win the arena over the tap recognizer on
  /// the slightest movement, so a pan that barely moves must still act as a tap.
  double _panTravel = 0;
  static const double _tapSlop = 12;

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // Slow breathing pulse for the "live" glow ring.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  /// Reopen the full call screen.
  ///
  /// IMPORTANT: this FAB is mounted via `MaterialApp.builder` as a SIBLING of
  /// the app Navigator (Stack: [Navigator, FAB]). The Navigator is therefore a
  /// descendant — NOT an ancestor — of this widget's context, so
  /// `Navigator.of(context)` cannot find it and the push silently fails. We
  /// push through the global [appNavigatorKey] instead.
  void _expandToFull(LiveKitCallService svc) {
    if (LiveKitScreenVisibility.instance.visible) return;
    final world = svc.world ?? 'materie';
    final roomName = svc.roomName ?? '';
    if (roomName.isEmpty) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LiveKitGroupCallScreen(
          roomName: roomName,
          world: world,
          displayName: svc.localDisplayName ?? 'Mitglied',
          avatarUrl: svc.localAvatarUrl,
        ),
      ),
    );
  }

  /// Long-press action sheet: toggle mic + hang up. German labels.
  /// Uses the global navigator context (see [_expandToFull] for why the local
  /// context has no Navigator/Overlay ancestor).
  void _showActions(LiveKitCallService svc) {
    final world = svc.world ?? 'materie';
    final sheetRootContext = appNavigatorKey.currentContext;
    if (sheetRootContext == null) return;
    showModalBottomSheet<void>(
      context: sheetRootContext,
      backgroundColor: WbDesign.surface(world),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  svc.micEnabled ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
                title: Text(
                  svc.micEnabled ? 'Mikrofon stumm' : 'Mikrofon an',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  svc.toggleMicrophone();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.call_end_rounded,
                  color: Color(0xFFFF1744),
                ),
                title: const Text(
                  'Auflegen',
                  style: TextStyle(color: Color(0xFFFF1744)),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  svc.leaveRoom();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  /// Clamp a Y coordinate within sensible screen bounds.
  double _clampY(double y, BoxConstraints constraints, double topInset) {
    final minY = topInset + 80;
    final maxY = constraints.maxHeight - _size - 120;
    if (maxY < minY) return minY;
    return y.clamp(minY, maxY);
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(livekitCallProvider);
    final connected = svc.connectionState == LiveKitConnectionState.connected ||
        svc.connectionState == LiveKitConnectionState.reconnecting;

    return AnimatedBuilder(
      animation: LiveKitScreenVisibility.instance,
      builder: (context, _) {
        final shouldShow = connected &&
            !LiveKitScreenVisibility.instance.visible &&
            svc.roomName != null &&
            svc.world != null;

        // Hidden: render an empty, non-interactive box so it never blocks
        // touches on the screens below.
        if (!shouldShow) {
          return const IgnorePointer(child: SizedBox.shrink());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final topInset = MediaQuery.of(context).padding.top;

            // First layout: default to the right edge, ~65% down the screen.
            _pos ??= Offset(
              constraints.maxWidth - _size - _edgeMargin,
              constraints.maxHeight * 0.65,
            );

            // Keep it inside the bounds even after a rotation / resize.
            final clampedX = _pos!.dx.clamp(
              _edgeMargin,
              (constraints.maxWidth - _size - _edgeMargin)
                  .clamp(_edgeMargin, double.infinity),
            );
            final clampedY = _clampY(_pos!.dy, constraints, topInset);
            final pos = Offset(clampedX, clampedY);

            return Stack(
              children: [
                AnimatedPositioned(
                  // Animate the snap only when NOT actively dragging, so the
                  // FAB glides to the edge after the finger lifts.
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: pos.dx,
                  top: pos.dy,
                  width: _size,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _expandToFull(svc),
                    onLongPress: () => _showActions(svc),
                    onPanStart: (_) {
                      _panTravel = 0;
                      setState(() => _dragging = true);
                    },
                    onPanUpdate: (details) {
                      _panTravel += details.delta.distance;
                      setState(() {
                        _pos = Offset(
                          (_pos ?? pos).dx + details.delta.dx,
                          (_pos ?? pos).dy + details.delta.dy,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      // A pan that barely moved is really a tap → reopen call.
                      if (_panTravel < _tapSlop) {
                        setState(() => _dragging = false);
                        _expandToFull(svc);
                        return;
                      }
                      // Otherwise snap horizontally to the nearest edge.
                      final current = _pos ?? pos;
                      final centerX = current.dx + _size / 2;
                      final snapLeft = centerX < constraints.maxWidth / 2;
                      final targetX = snapLeft
                          ? _edgeMargin
                          : constraints.maxWidth - _size - _edgeMargin;
                      final targetY =
                          _clampY(current.dy, constraints, topInset);
                      setState(() {
                        _dragging = false;
                        _pos = Offset(targetX, targetY);
                      });
                    },
                    child: _FabVisual(
                      svc: svc,
                      pulse: _pulse,
                      durationLabel:
                          _formatDuration(svc.callDurationSeconds),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The circular FAB visual: accent gradient, pulsing live-ring, video icon,
/// participant badge, live-dot, and a small duration pill below.
class _FabVisual extends StatelessWidget {
  final LiveKitCallService svc;
  final Animation<double> pulse;
  final String durationLabel;

  const _FabVisual({
    required this.svc,
    required this.pulse,
    required this.durationLabel,
  });

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final world = svc.world ?? 'materie';
    final accent = WbDesign.accent(world);
    // Build a simple gradient from the accent towards a darker variant.
    final accentDark = Color.lerp(accent, Colors.black, 0.45) ?? accent;
    final count = svc.totalParticipantCount;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                final t = pulse.value; // 0..1
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Pulsing green "live" glow ring.
                    Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.35 + 0.35 * t),
                            blurRadius: 12 + 10 * t,
                            spreadRadius: 1 + 3 * t,
                          ),
                        ],
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Gradient circle with video icon.
                  Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, accentDark],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  // Live-dot (top-left) — pulses with the ring.
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  // Participant-count badge (top-right) when > 0.
                  if (count > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        constraints: const BoxConstraints(minWidth: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF1744),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Small duration pill: "Live · MM:SS".
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              'Live · $durationLabel',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
